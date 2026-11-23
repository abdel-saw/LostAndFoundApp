"""Validate public hosted config and compile the GitHub Pages frontend."""
import base64
import json
import os
from pathlib import Path
import subprocess
import tempfile
from urllib.parse import urlsplit


def validate(url, key):
    parsed = urlsplit(url)
    if (parsed.scheme != "https" or not parsed.hostname
            or parsed.username or parsed.password
            or parsed.path not in ("", "/") or parsed.query or parsed.fragment):
        raise ValueError("SUPABASE_URL must be an HTTPS project origin.")
    try:
        payload = key.split(".")[1]
        decoded = json.loads(base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4)))
    except (ValueError, IndexError, UnicodeError) as error:
        raise ValueError("Use the project's public legacy anon key, not a secret key.") from error
    if decoded.get("role") != "anon":
        raise ValueError("Only a public anon key may be compiled into the client.")


def main():
    url = os.environ.get("SUPABASE_URL", "").strip()
    key = os.environ.get("SUPABASE_ANON_KEY", "").strip()
    validate(url, key)
    app = Path(__file__).resolve().parents[1] / "lost_and_found_app"
    with tempfile.TemporaryDirectory() as directory:
        config = Path(directory) / "public-config.json"
        config.write_text(json.dumps({"SUPABASE_URL": url, "SUPABASE_ANON_KEY": key}))
        subprocess.run([
            "flutter", "build", "web", "--release",
            "--base-href=/LostAndFoundApp/", "--pwa-strategy=none",
            "--dart-define-from-file=" + str(config),
        ], cwd=app, check=True)
    (app / "build" / "web" / ".nojekyll").touch()


if __name__ == "__main__":
    main()
