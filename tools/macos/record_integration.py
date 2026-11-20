#!/usr/bin/env python3
"""Uninterrupted real-control journey, including the actual Save/Continue buttons.
Movie Maker's fixed capture rate is NOT a performance measurement.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import shutil
import tempfile
import uuid
import zipfile

from renderer_diagnostics import engine_diagnostics
from stress_release import digest

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('runtime', help='Godot editor, or the exported .app with --exported-native-metal')
parser.add_argument('destination')
parser.add_argument('--exported-native-metal', action='store_true')
options = parser.parse_args()
root = Path(__file__).resolve().parents[2]
out = Path(options.destination).resolve()
out.mkdir(parents=True, exist_ok=True)
movie = out / 'milestone35-full-journey.mp4'
with tempfile.TemporaryDirectory(prefix='lto-integration-movie-') as temporary:
    raw = Path(temporary) / 'journey.avi'
    command = [options.runtime, '--path', str(root)]
    entry = ['tools/validate_journey.tscn', '--']
    provenance = {}
    if options.exported_native_metal:
        app = Path(options.runtime).resolve()
        original, = (app / 'Contents/Resources').glob('*.pck')
        pack = Path(temporary) / original.name
        shutil.copyfile(original, pack)
        pack_sha = digest(original)
        assert digest(pack) == pack_sha
        user = 'LTO-353-exported-journey-' + uuid.uuid4().hex
        (pack.parent / 'override.cfg').write_text(
            '[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="' + user + '"\n')
        inputs = out / 'journey-inputs.zip'
        with zipfile.ZipFile(inputs, 'w', zipfile.ZIP_DEFLATED) as archive:
            for filename in ['tools/validate_journey.gd', 'tests/framework/route_bot.gd']:
                archive.write(root / filename, filename)
        command = [str(root / 'tools/macos/launch_native_metal.sh'), str(app), '--main-pack', str(pack)]
        entry = ['--script', str(root / 'tools/macos/exported_journey.gd'), '--', '--journey-inputs=' + str(inputs)]
        provenance = {'exported_pack_sha256': pack_sha, 'external_input_driver_sha256': digest(inputs)}
    command += ['--audio-driver', 'Dummy', '--resolution', '960x540', '--position', '32,64',
               '--fixed-fps', '12', '--write-movie', str(raw), *entry,
               '--quality=1', '--graphics=medium', '--integration-tour', '--late-escape',
               '--out=' + str(out)]
    with (out / 'full-journey.log').open('w') as stream:
        subprocess.run(command, stdout=stream, stderr=subprocess.STDOUT, check=True, timeout=1200)
    report = json.loads((out / 'continuous-journey.json').read_text())
    assert not report['failed'] and report['teleports'] == 0
    if options.exported_native_metal:
        assert not report['editor'] and Path(report['user_directory']).name == user
        assert (report['renderer'], report['driver']) == ('forward_plus', 'metal')
        assert len(report['checks']) == 167 and report['save_restore_repositions'] == 1
    assert report['results']['status'] == 'escaped'
    assert any(row['check'] == 'Continue restores actual Blackwater stop' and row['passed'] for row in report['checks'])
    diagnostics = engine_diagnostics((out / 'full-journey.log').read_text(errors='replace').splitlines())
    subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', str(raw),
                    '-c:v', 'libx264', '-crf', '29', '-preset', 'medium', '-pix_fmt', 'yuv420p',
                    '-c:a', 'aac', '-b:a', '64k', '-movflags', '+faststart', str(movie)],
                   check=True, timeout=600)
subprocess.run(['ffmpeg', '-v', 'error', '-i', str(movie), '-f', 'null', '-'], check=True, timeout=180)
media = json.loads(subprocess.check_output(['ffprobe', '-v', 'error', '-show_format', '-show_streams', '-of', 'json', str(movie)]))
video = next(row for row in media['streams'] if row['codec_type'] == 'video')
assert (video['width'], video['height']) == (960, 540)
assert video['r_frame_rate'] == '12/1' and float(media['format']['duration']) > 1200
(out / 'media.json').write_text(json.dumps({
    'commit': os.environ.get('SOURCE_SHA', os.environ.get('GITHUB_SHA', '')),
    'capture_fps': 12, 'realtime_benchmark': False, 'preset': 'Medium',
    **provenance, 'engine_diagnostics': diagnostics,
    'sha256': hashlib.sha256(movie.read_bytes()).hexdigest(), 'media': media,
    'editing': 'one continuous engine recording; actual Save/Continue scene reload included; no cuts or time acceleration'
}, indent=2))
print('Recorded and decoded the full journey including Save/Continue and final results.', flush=True)
if diagnostics:
    raise SystemExit('Recording retained with engine diagnostics:\n' + '\n'.join(diagnostics))
