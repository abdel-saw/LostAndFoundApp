"""Run Flutter's Chrome integration test with disposable local credentials."""
import json
import subprocess
from pathlib import Path

config = json.loads(subprocess.check_output(
    ["supabase", "status", "-o", "json"], text=True))
url = config["API_URL"]
if not url.startswith(("http://127.0.0.1:", "http://localhost:")):
    raise RuntimeError("Browser integration tests require local Supabase")
subprocess.run([
    "flutter", "drive", "--driver=test_driver/integration_test.dart",
    "--target=integration_test/browser_flow_test.dart", "-d", "web-server",
    "--browser-name=chrome", "--headless", "--web-port=3000",
    "--dart-define=SUPABASE_URL=" + url,
    "--dart-define=SUPABASE_ANON_KEY=" + config["ANON_KEY"],
], cwd=Path(__file__).resolve().parents[1] / "lost_and_found_app", check=True)
