#!/usr/bin/env python3
"""Guard test identity, not just a floor: every source test must still exist and pass."""
import json
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / 'docs/validation/milestone35/baselines/source-test-manifest.json').read_text())
required = {tuple(item) for item in manifest['distinct_tests']}
discovered = {(str(path.relative_to(root)), name)
              for path in (root / 'tests').glob('*/test_*.gd')
              for name in re.findall(r'^func (test_\w+)\(', path.read_text(), re.M)}
assert required <= discovered, f'Source tests removed: {required - discovered}'
report = json.loads(Path(sys.argv[1]).read_text())
passed = {(row['suite'], row['test']) for row in report['results'] if row['passed']}
missing = {(Path(path).name, name) for path, name in discovered} - passed
assert not missing, f'Tests absent or failing in report: {missing}'
assert report['failed'] == 0
print(f'All {len(required)} distinct source tests preserved; {len(discovered)} discovered tests passed.')
