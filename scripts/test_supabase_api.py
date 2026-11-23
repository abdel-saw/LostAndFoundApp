"""Integration smoke test against the LOCAL disposable Supabase stack only."""
import json
import subprocess
import urllib.error
import urllib.request
import uuid

config = json.loads(subprocess.check_output(
    ["supabase", "status", "-o", "json"], text=True))
base = config["API_URL"].rstrip("/")
key = config["ANON_KEY"]
if not base.startswith(("http://127.0.0.1:", "http://localhost:")):
    raise RuntimeError("This test only accepts a local disposable Supabase stack")


def request(path, method="GET", data=None, token=None, binary=False):
    headers = {"apikey": key}
    if token:
        headers["Authorization"] = "Bearer " + token
    if data is not None:
        headers["Content-Type"] = "image/jpeg" if binary else "application/json"
        body = data if binary else json.dumps(data).encode()
    else:
        body = None
    req = urllib.request.Request(base + path, body, headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            payload = response.read()
            if binary:
                return response.status, payload
            return response.status, json.loads(payload) if payload else None
    except urllib.error.HTTPError as error:
        return error.code, error.read().decode()


def check(condition, description):
    if not condition:
        raise AssertionError(description)
    print("PASS:", description)


def signup(label):
    status, result = request("/auth/v1/signup", "POST", {
        "email": label + "-" + uuid.uuid4().hex + "@example.test",
        "password": "local-fixture-password-2026",
    })
    check(status == 200 and "access_token" in result, label + " signs up locally")
    return result["access_token"], result["user"]["id"]


alice, alice_id = signup("alice")
bob, bob_id = signup("bob")
status, _ = request("/rest/v1/items")
check(status in (401, 403), "anonymous item access is denied")

status, item_id = request("/rest/v1/rpc/report_item", "POST", {"payload": {
    "type": "lost", "name": "Fictional blue keys", "category": "Personal",
    "user_id": bob_id, "timestamp": "2000-01-01T00:00:00Z",
}}, alice)
check(status == 200 and isinstance(item_id, int), "atomic RPC creates an item")
status, items = request("/rest/v1/items?id=eq." + str(item_id), token=bob)
check(status == 200 and len(items) == 1 and items[0]["user_id"] == alice_id,
      "signed-in browsing works and RPC prevents spoofed ownership")
status, reports = request("/rest/v1/user_reports?item_id=eq." + str(item_id), token=alice)
check(status == 200 and len(reports) == 1, "exactly one linked report exists")
status, reports = request("/rest/v1/user_reports?item_id=eq." + str(item_id), token=bob)
check(status == 200 and reports == [], "another user cannot read private reports")
status, _ = request("/rest/v1/items", "POST", {
    "type": "lost", "name": "Bypass", "user_id": alice_id}, alice)
check(status in (401, 403), "direct item insert cannot bypass the RPC")
status, _ = request("/rest/v1/comments", "POST", {
    "item_id": item_id, "user_id": alice_id, "text": "Spoofed"}, bob)
check(status in (401, 403), "comment identity spoofing is denied")
status, _ = request("/rest/v1/comments", "POST", {
    "item_id": item_id, "user_id": bob_id, "text": "Fictional comment"}, bob)
check(status == 201, "authenticated comment insert succeeds")
status, comments = request("/rest/v1/comments?item_id=eq." + str(item_id), token=alice)
check(status == 200 and len(comments) == 1, "comments can be read by another user")

# Minimal JPEG markers: tests Storage transport/policies, not image decoding.
photo = bytes.fromhex("ffd8ffe000104a46494600010100000100010000ffd9")
path = alice_id + "/fixture-" + uuid.uuid4().hex + ".jpg"
status, _ = request("/storage/v1/object/items/" + path, "POST", photo, alice, True)
check(status in (200, 201), "owner can upload photo bytes")
status, image = request("/storage/v1/object/public/items/" + path, binary=True)
check(status == 200 and image == photo, "public photo URL returns the uploaded bytes")
status, _ = request("/storage/v1/object/items/" + alice_id + "/spoof.jpg",
                    "POST", photo, bob, True)
check(status in (400, 401, 403), "foreign-folder photo upload is denied")
print("Local Supabase API smoke test passed.")
