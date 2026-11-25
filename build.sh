#!/usr/bin/env bash
# Builds one unpacked Chrome extension per Google service into dist/<keyword>/.
# Chrome allows a single omnibox keyword per extension, hence one per service.
# To add a service, add an entry to SERVICES below and load dist/<keyword>/.
set -euo pipefail
cd "$(dirname "$0")"

python3 - <<'PY'
import json, os, shutil
from PIL import Image, ImageDraw, ImageFont

SERVICES = {
    "gmail": {
        "label": "Gmail",
        "url": "https://mail.google.com/mail/u/{index}/",
        "emailUrl": "https://mail.google.com/mail/?authuser={email}",
        "color": "#EA4335", "letter": "M",
    },
    "drive": {
        "label": "Google Drive",
        "url": "https://drive.google.com/drive/u/{index}/my-drive",
        "emailUrl": "https://drive.google.com/drive/?authuser={email}",
        "color": "#1E8E3E", "letter": "D",
    },
}

FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
VERSION = "1.0.0"

def icon(path, size, color, letter):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse((0, 0, size - 1, size - 1), fill=color)
    font = ImageFont.truetype(FONT, int(size * 0.6)) if os.path.exists(FONT) else ImageFont.load_default()
    d.text((size / 2, size / 2), letter, fill="white", font=font, anchor="mm")
    img.save(path)

for keyword, s in SERVICES.items():
    out = f"dist/{keyword}"
    shutil.rmtree(out, ignore_errors=True)
    os.makedirs(out)
    for f in ("background.js", "content.js"):
        shutil.copy(f"src/{f}", out)
    service = {k: s[k] for k in ("label", "url", "emailUrl")}
    with open(f"{out}/service.js", "w") as fh:
        fh.write(f"export const SERVICE = {json.dumps(service, indent=2)};\n")
    for size in (16, 32, 48, 128):
        icon(f"{out}/icon{size}.png", size, s["color"], s["letter"])
    manifest = {
        "manifest_version": 3,
        "name": f"{s['label']} account picker",
        "description": f"Type '{keyword}' + Tab in the address bar to open {s['label']} in any signed-in Google account.",
        "version": VERSION,
        "omnibox": {"keyword": keyword},
        "background": {"service_worker": "background.js", "type": "module"},
        "permissions": ["storage"],
        "host_permissions": [
            "https://accounts.google.com/*",
            "https://mail.google.com/*",
            "https://drive.google.com/*",
        ],
        "content_scripts": [{
            "matches": ["https://mail.google.com/*", "https://drive.google.com/*"],
            "js": ["content.js"],
            "run_at": "document_idle",
        }],
        "icons": {str(n): f"icon{n}.png" for n in (16, 32, 48, 128)},
    }
    with open(f"{out}/manifest.json", "w") as fh:
        json.dump(manifest, fh, indent=2)
    print("built", out)
PY
