"""The export may install only library groups matching the current source and device."""
import hashlib
import json
from pathlib import Path
import plistlib
import tempfile
import unittest
from zipfile import ZipFile

from prepare import install_compatible_groups, PACKAGED, PROFILE_KEYS


class TestSignedLibraryInventory(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory()
        self.addCleanup(self.scratch.cleanup)
        self.out = Path(self.scratch.name)
        with ZipFile(PACKAGED) as archive:
            self.manifest = json.loads(archive.read('manifest.json'))
        self.profile = {k:self.manifest[k] for k in PROFILE_KEYS}
        self.profile['files'] = {k:v['source_sha256'] for k,v in self.manifest['groups'].items()}

    def test_matching_inputs_install_verified_output(self):
        installed = install_compatible_groups(self.out, self.profile)
        path = self.out / 'MetalLibraries'
        self.assertTrue(installed)
        self.assertEqual(set(installed), set(self.profile['files']))
        self.assertEqual(plistlib.loads((path / 'Profile.plist').read_bytes())['files'], installed)
        for key, value in installed.items():
            self.assertEqual(hashlib.sha256((path / key).read_bytes()).hexdigest(), value)
            self.assertNotEqual(value, self.profile['files'][key])

    def test_changed_shader_uses_source(self):
        changed = next(iter(self.profile['files']))
        self.profile['files'][changed] = 'changed'
        installed = install_compatible_groups(self.out, self.profile)
        self.assertEqual(set(installed), set(self.profile['files']) - {changed})
        self.assertFalse((self.out / 'MetalLibraries' / changed).exists())

    def test_other_profile_uses_source(self):
        for key in PROFILE_KEYS:
            with self.subTest(key=key):
                self.assertEqual(install_compatible_groups(self.out, dict(self.profile, **{key:0})), {})
                self.assertFalse((self.out / 'MetalLibraries').exists())


if __name__ == '__main__':
    unittest.main()
