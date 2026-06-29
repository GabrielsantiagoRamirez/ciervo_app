# CIERVO Club - Smoke E2E production (MVP mobile certification)
# Usage:
#   $env:CIERVO_QA_EMAIL = "cliente@ciervoclub.test"
#   $env:CIERVO_QA_PASS  = "<from backend scripts/.qa-pass>"
#   powershell -ExecutionPolicy Bypass -File scripts/smoke_e2e_prod.ps1

param(
  [string]$BaseUrl = $(if ($env:CIERVO_API_BASE_URL) { $env:CIERVO_API_BASE_URL } else { "https://ciervo-backend-613568140358.southamerica-east1.run.app" }),
  [string]$Email = $env:CIERVO_QA_EMAIL,
  [string]$Password = $env:CIERVO_QA_PASS
)

$ErrorActionPreference = "Stop"
$script:Results = @()

if ([string]::IsNullOrWhiteSpace($Email) -or [string]::IsNullOrWhiteSpace($Password)) {
  Write-Error "Set CIERVO_QA_EMAIL and CIERVO_QA_PASS before running."
}

$script:Session = @{
  AccessToken  = $null
  RefreshToken = $null
}

function Add-Result {
  param([string]$Flow, [string]$Result, [string]$Detail)
  $script:Results += [pscustomobject]@{ Flow = $Flow; Result = $Result; Detail = $Detail }
  $tag = if ($Result -eq "PASS") { "[PASS]" } else { "[FAIL]" }
  Write-Host "$tag $Flow :: $Detail"
}

function Get-AuthHeaders {
  if ([string]::IsNullOrWhiteSpace($script:Session.AccessToken)) {
    throw "AccessToken empty - login not executed or token not propagated."
  }
  return @{
    Authorization = "Bearer $($script:Session.AccessToken)"
    Accept        = "application/json"
  }
}

function Invoke-Api {
  param(
    [string]$Method = "GET",
    [string]$Path,
    [object]$Body = $null,
    [switch]$SkipAuth
  )
  $uri = "$BaseUrl$Path"
  $params = @{
    Uri         = $uri
    Method      = $Method
    ContentType = "application/json"
  }
  if (-not $SkipAuth) {
    $params.Headers = Get-AuthHeaders
  }
  if ($null -ne $Body) {
    $params.Body = ($Body | ConvertTo-Json -Depth 6 -Compress)
  }
  return Invoke-RestMethod @params
}

function Assert-Envelope {
  param($Response, [string]$Context)
  if ($null -eq $Response) { throw "$Context - null response" }
  if ($Response.PSObject.Properties.Name -contains "status") {
    if (-not $Response.status) {
      $msg = if ($Response.msg) { $Response.msg } else { "status=false" }
      throw "$Context - $msg"
    }
  }
  return $Response
}

function Test-Step {
  param([string]$Flow, [scriptblock]$Action)
  try {
    $detail = & $Action
    Add-Result -Flow $Flow -Result "PASS" -Detail ([string]$detail)
    return $true
  } catch {
    $msg = if ($_.ErrorDetails.Message) { $_.ErrorDetails.Message } else { $_.Exception.Message }
    Add-Result -Flow $Flow -Result "FAIL" -Detail $msg
    return $false
  }
}

Write-Host "=== CIERVO Smoke E2E - $BaseUrl ==="

Test-Step "Login" {
  $login = Invoke-Api -Method POST -Path "/api/auth/user/login" -SkipAuth -Body @{
    email    = $Email
    password = $Password
  }
  Assert-Envelope $login "Login"
  $value = $login.value
  if (-not $value) { throw "Login missing value" }
  $access = $value.accessToken
  if ([string]::IsNullOrWhiteSpace($access)) { $access = $value.token }
  if ([string]::IsNullOrWhiteSpace($access)) { throw "Login missing accessToken" }
  $refresh = $value.refreshToken
  if ([string]::IsNullOrWhiteSpace($refresh)) { throw "Login missing refreshToken" }
  $script:Session.AccessToken = $access
  $script:Session.RefreshToken = $refresh
  return "accessToken + refreshToken obtained"
} | Out-Null

Test-Step "Refresh Token" {
  $old = $script:Session.AccessToken
  $ref = Invoke-Api -Method POST -Path "/api/auth/refresh-token" -SkipAuth -Body @{
    refreshToken = $script:Session.RefreshToken
  }
  Assert-Envelope $ref "Refresh"
  $newAccess = $ref.value.accessToken
  if ([string]::IsNullOrWhiteSpace($newAccess)) { $newAccess = $ref.value.token }
  if ([string]::IsNullOrWhiteSpace($newAccess)) { throw "Refresh missing accessToken" }
  $script:Session.AccessToken = $newAccess
  if ($ref.value.refreshToken) { $script:Session.RefreshToken = $ref.value.refreshToken }
  $probe = Invoke-Api -Path "/api/wallet/cards"
  Assert-Envelope $probe "Post-refresh wallet probe"
  return "token renewed and reused (changed=$($old -ne $newAccess))"
} | Out-Null

Test-Step "Perfil" {
  try {
    $p = Invoke-Api -Path "/api/clients/me"
    Assert-Envelope $p "Perfil clients/me"
    return "clients/me email=$($p.value.email)"
  } catch {
    $p = Invoke-Api -Path "/api/users/me"
    Assert-Envelope $p "Perfil users/me"
    return "fallback users/me email=$($p.value.email)"
  }
} | Out-Null

Test-Step "Wallet" {
  $w = Invoke-Api -Path "/api/wallet/cards"
  Assert-Envelope $w "Wallet"
  $cards = @($w.value)
  $avail = ($cards | ForEach-Object { [double]$_.availableBalance } | Measure-Object -Sum).Sum
  return "cards=$($cards.Count) available=$avail"
} | Out-Null

Test-Step "Mercado Pago" {
  $mp = Invoke-Api -Path "/api/wallet/mercadopago/config"
  Assert-Envelope $mp "MP config"
  return "config ok"
} | Out-Null

Test-Step "Recharge Intent" {
  $cards = @( (Invoke-Api -Path "/api/wallet/cards").value )
  if ($cards.Count -lt 1) { throw "no wallet cards" }
  $cardId = $cards[0].id
  $key = "smoke-rch-$([Guid]::NewGuid().ToString('N'))"
  $r = Invoke-Api -Method POST -Path "/api/wallet/cards/$cardId/recharge-intents" -Body @{
    amount         = 1000
    currency       = "COP"
    idempotencyKey = $key
  }
  Assert-Envelope $r "Recharge intent"
  if (-not ($r.value.checkoutUrl -or $r.value.initPoint)) { throw "missing checkoutUrl" }
  $intentId = $r.value.id
  if ($intentId) {
    $poll = Invoke-Api -Path "/api/wallet/recharge-intents/$intentId"
    Assert-Envelope $poll "Recharge poll"
  }
  return "intent created id=$intentId"
} | Out-Null

Test-Step "PIN" {
  $p = Invoke-Api -Path "/api/pins/me?activeOnly=true"
  Assert-Envelope $p "PIN"
  return "active=$(@($p.value).Count)"
} | Out-Null

Test-Step "Delivery" {
  $d = Invoke-Api -Path "/api/delivery/orders"
  Assert-Envelope $d "Delivery orders"
  $list = $d.value
  if ($null -eq $list) { $list = @() }
  $count = if ($list -is [array]) { $list.Count } elseif ($list.items) { @($list.items).Count } else { 0 }
  return "status=true count=$count client-ok"
} | Out-Null

$script:KidId = $null
$script:BizId = $null
$script:CardId = $null

Test-Step "Kids" {
  $kids = Invoke-Api -Path "/api/guardians/children"
  Assert-Envelope $kids "Kids list"
  $kidList = @($kids.value)
  if ($kidList.Count -lt 1) { throw "no children" }
  $script:KidId = $kidList[0].id

  $ab = Invoke-Api -Path "/api/kids/$($script:KidId)/allowed-businesses"
  Assert-Envelope $ab "Kids allowed businesses"
  $abList = @($ab.value)
  if ($abList.Count -lt 1) { throw "no allowed businesses" }
  $biz = $abList[0]
  $script:BizId = if ($biz.businessId) { $biz.businessId } else { $biz.id }

  $cards = Invoke-Api -Path "/api/guardians/children/$($script:KidId)/wallet/cards"
  Assert-Envelope $cards "Kids wallet cards"
  $cardList = @($cards.value)
  if ($cardList.Count -lt 1) { throw "no kids cards" }
  $c = $cardList[0]
  $script:CardId = $c.id
  if ($null -ne $c.availableBalance) {
    $bal = [double]$c.availableBalance
  } else {
    $bal = [double]$c.balance
  }
  if ($bal -lt 100) { throw "insufficient kids balance: $bal" }

  $key = "smoke-kids-$([Guid]::NewGuid().ToString('N'))"
  $pay = Invoke-Api -Method POST -Path "/api/kids/payments/business" -Body @{
    childId           = [int]$script:KidId
    businessId        = [int]$script:BizId
    amount            = 100
    currency          = "COP"
    idempotencyKey    = $key
    childWalletCardId = [int]$script:CardId
  }
  Assert-Envelope $pay "Kids payment"
  $receipt = $pay.value.receiptId
  if (-not $receipt) { $receipt = $pay.value.publicReceiptUrl }
  return "kid=$($script:KidId) balance=$bal paid=100 receipt=$receipt"
} | Out-Null

Test-Step "Membership" {
  $plans = Invoke-Api -Path "/api/memberships/plans" -SkipAuth
  Assert-Envelope $plans "Membership plans"
  $planCount = @($plans.value).Count

  $sub = Invoke-Api -Method POST -Path "/api/memberships/subscribe" -Body @{
    planId   = 2
    planCode = "silver"
  }
  Assert-Envelope $sub "Membership subscribe"

  $me = Invoke-Api -Path "/api/memberships/me"
  Assert-Envelope $me "Membership me"

  $benefits = Invoke-Api -Path "/api/memberships/benefits"
  Assert-Envelope $benefits "Membership benefits"

  $invoices = Invoke-Api -Path "/api/memberships/invoices"
  Assert-Envelope $invoices "Membership invoices"
  $invCount = @($invoices.value).Count

  return "plans=$planCount plan=$($me.value.planCode) invoices=$invCount"
} | Out-Null

Test-Step "Receipts" {
  $r = Invoke-Api -Path "/api/receipts"
  Assert-Envelope $r "Receipts"
  return "count=$(@($r.value).Count)"
} | Out-Null

Test-Step "Notifications" {
  $n = Invoke-Api -Path "/api/notifications"
  Assert-Envelope $n "Notifications"
  return "ok"
} | Out-Null

Test-Step "Financial History" {
  $f = Invoke-Api -Path "/api/financial-history"
  Assert-Envelope $f "Financial history"
  return "ok"
} | Out-Null

Test-Step "Rewards" {
  $rw = Invoke-Api -Path "/api/rewards/me/points"
  Assert-Envelope $rw "Rewards"
  return "balance=$($rw.value.balance)"
} | Out-Null

Write-Host ""
Write-Host "=== SUMMARY ==="
$script:Results | Format-Table -AutoSize
$pass = @($script:Results | Where-Object { $_.Result -eq "PASS" }).Count
$fail = @($script:Results | Where-Object { $_.Result -eq "FAIL" }).Count
Write-Host "PASS: $pass  FAIL: $fail"
if ($fail -gt 0) { exit 1 }
exit 0
