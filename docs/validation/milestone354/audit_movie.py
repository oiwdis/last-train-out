"""Inspect every decoded frame for large single-frame luminance excursions."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

import numpy as np


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('movie', type=Path)
    parser.add_argument('report', type=Path)
    args = parser.parse_args()
    command = ['ffmpeg', '-nostdin', '-v', 'error', '-i', str(args.movie), '-map', '0:v:0',
               '-vf', 'scale=160:90:flags=area', '-pix_fmt', 'gray', '-f', 'rawvideo', '-']
    older = previous = None
    frame_count = 0
    pulses, black = [], []
    with subprocess.Popen(command, stdout=subprocess.PIPE) as decoder:
        while data := decoder.stdout.read(160 * 90):
            if len(data) != 160 * 90:
                raise ValueError('Partial decoded frame')
            current = np.frombuffer(data, dtype=np.uint8).astype(np.int16)
            if current.max() <= 2:
                black.append(frame_count)
            if older is not None:
                before = np.abs(previous - older).mean()
                after = np.abs(current - previous).mean()
                recovered = np.abs(current - older).mean()
                if min(before, after) > 22 and recovered < 8:
                    pulses.append({'frame': frame_count - 1, 'before': round(before, 2),
                                   'after': round(after, 2), 'outer_difference': round(recovered, 2)})
            older, previous = previous, current
            frame_count += 1
        if decoder.wait():
            raise ValueError('The video failed to decode')
    report = {'movie_sha256': hashlib.sha256(args.movie.read_bytes()).hexdigest(),
              'frames': frame_count, 'decoded_gray_size': [160, 90], 'frame_index': 'zero-based',
              'pulse_definition': 'Central frame differs from both neighbors by >22 mean absolute 8-bit levels; neighbors differ by <8.',
              'pulses': pulses, 'black_definition': 'All downsampled pixel values <=2.', 'black_frames': black}
    args.report.write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
