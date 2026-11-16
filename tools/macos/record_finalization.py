#!/usr/bin/env python3
"""Capture real scripted gameplay on the hosted Mac after performance sampling."""
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
movie = out / 'milestone26_finalization_tour.mp4'
with tempfile.TemporaryDirectory(prefix='lto-movie-') as temporary:
    raw = Path(temporary) / 'tour.avi'
    command = [godot, '--path', str(root), '--audio-driver', 'Dummy',
               '--resolution', '854x480', '--position', '32,64', '--fixed-fps', '24',
               '--write-movie', str(raw), 'tools/record_finalization.tscn', '--', '--quality=1']
    log = out / 'tour.log'
    with log.open('w') as stream:
        subprocess.run(command, stdout=stream, stderr=subprocess.STDOUT, check=True, timeout=300)
    text = log.read_text()
    assert '[tour-final] complete:' in text and text.count('[tour-final] PASS') == 11
    assert 'ERROR:' not in text and '[tour-final] FAIL' not in text, text
    subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', str(raw),
                    '-c:v', 'libx264', '-crf', '19', '-preset', 'medium', '-pix_fmt', 'yuv420p',
                    '-c:a', 'aac', '-b:a', '128k', '-movflags', '+faststart', str(movie)],
                   check=True, timeout=180)
subprocess.run(['ffmpeg', '-v', 'error', '-i', str(movie), '-f', 'null', '-'], check=True, timeout=90)
media = json.loads(subprocess.check_output(['ffprobe', '-v', 'error', '-show_format',
                                          '-show_streams', '-of', 'json', str(movie)]))
video = next(stream for stream in media['streams'] if stream['codec_type'] == 'video')
assert (video['width'], video['height']) == (854, 480)
assert video['r_frame_rate'] == '24/1' and float(media['format']['duration']) > 45
report = {'commit': os.environ.get('GITHUB_SHA', ''), 'preset': 'Medium',
          'capture_fps': 24, 'realtime_benchmark': False, 'gameplay_assertions': 11,
          'sha256': hashlib.sha256(movie.read_bytes()).hexdigest(), 'media': media}
(out / 'tour-media.json').write_text(json.dumps(report, indent=2) + '\n')
print('Recorded and decoded the complete gameplay tour; eleven interaction checks passed.')
