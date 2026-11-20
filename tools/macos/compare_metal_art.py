"""Compare the shipped character, hands and locomotive at the same authored camera poses."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import shutil
import uuid
import zipfile

from renderer_diagnostics import engine_diagnostics

root = Path(__file__).resolve().parents[2]
app, out = (Path(arg).resolve() for arg in sys.argv[1:])
out.mkdir(parents=True, exist_ok=False)
inputs = out / 'visual-inputs.zip'
with zipfile.ZipFile(inputs, 'w', zipfile.ZIP_DEFLATED) as z:
    for name in ('tools/capture_milestone26.gd', 'tools/capture_finalization.gd'):
        z.write(root / name, name)
attempts = []
with tempfile.TemporaryDirectory() as tmp:
    directory = Path(tmp)
    original, = (app / 'Contents/Resources').glob('*.pck')
    target = directory / original.name
    shutil.copy2(original, target)
    for driver in ('metal', 'vulkan'):
        user = 'LTO-354-art-' + uuid.uuid4().hex
        (directory / 'override.cfg').write_text('[application]\nconfig/use_custom_user_dir=true\n'
                                                f'config/custom_user_dir_name="{user}"\n')
        part = out / driver
        part.mkdir()
        cmd = [str(app / 'Contents/MacOS/choose-renderer'), driver, '--main-pack', str(target),
               '--resolution', '960x540', '--audio-driver', 'Dummy', '--fixed-fps', '60', '--script',
               str(root / 'tools/macos/exported_visuals.gd'), '--', '--graphics=high', '--integrated-art',
               '--visual-inputs=' + str(inputs), '--out=' + str(part)]
        with (part / 'raw.log').open('w') as stream:
            try:
                code = subprocess.run(cmd, stdout=stream, stderr=subprocess.STDOUT, timeout=420).returncode
            except subprocess.TimeoutExpired:
                code = 124
        pose_file = part / 'camera_poses.json'
        poses = json.loads(pose_file.read_text()) if pose_file.exists() else {}
        diag = engine_diagnostics((part / 'raw.log').read_text(errors='replace').splitlines())
        attempts.append({'driver':driver, 'returncode':code, 'diagnostics':diag, 'passed':
            code == 0 and not diag and poses.get('driver') == driver and len(poses.get('poses', [])) == 17
            and len(list(part.glob('*.png'))) == 17})
        (out / 'attempts.json').write_text(json.dumps(attempts, indent=2))
sys.exit(int(any(not row['passed'] for row in attempts)))
