import base64
import json
import unittest
from build_pages import validate


def key(role):
    payload = base64.urlsafe_b64encode(json.dumps({"role": role}).encode()).decode().rstrip("=")
    return "fixture." + payload + ".fixture"


class HostedConfigTests(unittest.TestCase):
    def test_public_anon_key(self):
        validate("https://fixture.supabase.co", key("anon"))

    def test_privileged_key_is_rejected(self):
        with self.assertRaises(ValueError):
            validate("https://fixture.supabase.co", key("service_role"))

    def test_missing_or_secret_key_is_rejected(self):
        for value in ("", "sb_secret_fixture", "not-a-key"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                validate("https://fixture.supabase.co", value)

    def test_local_or_embedded_credentials_are_rejected(self):
        for url in ("http://localhost:54321", "https://user:pass@example.test",
                    "https://example.test/path", "https://example.test?secret=value"):
            with self.subTest(url=url), self.assertRaises(ValueError):
                validate(url, key("anon"))


if __name__ == "__main__":
    unittest.main()
