#!/usr/bin/env python3
"""Uninterrupted real-control journey, including the actual Save/Continue buttons.
Movie Maker's fixed capture rate is NOT a performance measurement.
"""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

godot, destination = sys.argv[1:]
root = Path(__file__).resolve().parents[2]
out = Path(destination).resolve()
out.mkdir(parents=True, exist_ok=True)
movie = out / 'milestone35-full-journey.mp4'
with tempfile.TemporaryDirectory(prefix='lto-integration-movie-') as temporary:
    raw = Path(temporary) / 'journey.avi'
    command = [godot, '--path', str(root), '--audio-driver', 'Dummy',
               '--resolution', '960x540', '--position', '32,64', '--fixed-fps', '12',
               '--write-movie', str(raw), 'tools/validate_journey.tscn', '--',
               '--quality=1', '--graphics=medium', '--integration-tour', '--late-escape',
               '--out=' + str(out)]
    with (out / 'full-journey.log').open('w') as stream:
        subprocess.run(command, stdout=stream, stderr=subprocess.STDOUT, check=True, timeout=1200)
    report = json.loads((out / 'continuous-journey.json').read_text())
    assert not report['failed'] and report['teleports'] == 0
    assert report['results']['status'] == 'escaped'
    assert any(row['check'] == 'Continue restores actual Blackwater stop' and row['passed'] for row in report['checks'])
    diagnostics = [line for line in (out / 'full-journey.log').read_text().splitlines()
                   if line.startswith(('ERROR:', 'SCRIPT ERROR:', 'WARNING:',
                                       'Leaked instance:', 'Resource still in use:'))]
    assert not diagnostics, 'Recording emitted errors/warnings: ' + '\n'.join(diagnostics)
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
    'sha256': hashlib.sha256(movie.read_bytes()).hexdigest(), 'media': media,
    'editing': 'one continuous engine recording; actual Save/Continue scene reload included; no cuts or time acceleration'
}, indent=2))
print('Recorded and decoded the full journey including Save/Continue and final results.', flush=True)
