import os
import unittest
from unittest.mock import patch

from diagnosticsd.__main__ import ensure_unprivileged
from diagnosticsd.api import DiagnosticsServer


class BoundaryTests(unittest.TestCase):
    def test_daemon_refuses_root(self):
        with patch.object(os, "geteuid", return_value=0):
            with self.assertRaises(SystemExit):
                ensure_unprivileged()

    def test_api_rejects_non_local_bind(self):
        with self.assertRaisesRegex(ValueError, "localhost"):
            DiagnosticsServer(("0.0.0.0", 0), object())


if __name__ == "__main__":
    unittest.main()
