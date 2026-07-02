/// Flujo de autenticación resuelto tras `account-lookup`.
enum AuthFlow {
  registerNew,
  firebaseLogin,
  legacyMigration,
}
