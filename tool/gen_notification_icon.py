from PIL import Image
from pathlib import Path

root = Path(__file__).resolve().parents[1]
# Prefer launcher foreground (deer artwork without heavy text)
candidates = [
    root
    / "android"
    / "app"
    / "src"
    / "main"
    / "res"
    / "drawable-xxxhdpi"
    / "ic_launcher_foreground.png",
    root
    / "android"
    / "app"
    / "src"
    / "main"
    / "res"
    / "drawable-xxhdpi"
    / "ic_launcher_foreground.png",
    root / "assets" / "notifications" / "ciervo_logo_gold.png",
]
src_path = next(p for p in candidates if p.exists())
print("source:", src_path)

src = Image.open(src_path).convert("RGBA")
bbox = src.getbbox()
if bbox:
    src = src.crop(bbox)

out = Image.new("RGBA", src.size, (0, 0, 0, 0))
sp = src.load()
op = out.load()
for y in range(src.height):
    for x in range(src.width):
        r, g, b, a = sp[x, y]
        if a < 25:
            continue
        luminance = 0.299 * r + 0.587 * g + 0.114 * b
        # Keep non-dark ink. Adaptive icons often have transparent bg already.
        if luminance < 35 and a < 200:
            continue
        # Pure white; alpha from source, boosted for visibility in status bar.
        alpha = min(255, max(a, int(luminance)))
        if luminance >= 35 or a >= 120:
            op[x, y] = (255, 255, 255, alpha)

bbox = out.getbbox()
if bbox is None:
    raise SystemExit("No opaque pixels after conversion")
out = out.crop(bbox)

# Square padded canvas (transparent)
side = max(out.size)
pad = int(side * 0.12)
canvas = Image.new("RGBA", (side + 2 * pad, side + 2 * pad), (0, 0, 0, 0))
canvas.paste(
    out,
    ((canvas.width - out.width) // 2, (canvas.height - out.height) // 2),
    out,
)

sizes = {
    "drawable-mdpi": 24,
    "drawable-hdpi": 36,
    "drawable-xhdpi": 48,
    "drawable-xxhdpi": 72,
    "drawable-xxxhdpi": 96,
}
res = root / "android" / "app" / "src" / "main" / "res"
for folder, size in sizes.items():
    dest_dir = res / folder
    dest_dir.mkdir(parents=True, exist_ok=True)
    fitted = canvas.copy()
    fitted.thumbnail((size, size), Image.Resampling.LANCZOS)
    square = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    square.paste(
        fitted,
        ((size - fitted.width) // 2, (size - fitted.height) // 2),
        fitted,
    )
    # Force remaining gray anti-alias to pure white alpha mask
    px = square.load()
    for y in range(size):
        for x in range(size):
            r, g, b, a = px[x, y]
            if a > 0:
                px[x, y] = (255, 255, 255, a)
    dest = dest_dir / "ic_stat_ciervo.png"
    square.save(dest)
    opaque = sum(1 for p in square.getdata() if p[3] > 0)
    print("wrote", dest.name, size, "opaque", opaque)

print("done")
