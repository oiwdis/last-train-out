"""Capture Godot 4.5.1's native Metal shader and pipeline signposts on macOS."""
from contextlib import contextmanager
import signal
import subprocess
import time


@contextmanager
def metal_signposts(directory):
    with (directory / 'signposts.ndjson').open('w') as stream, (directory / 'collector.log').open('w') as errors:
        proc = subprocess.Popen(['/usr/bin/log', 'stream', '--signpost', '--level', 'debug', '--style', 'ndjson',
                                 '--predicate', 'subsystem == "org.godotengine.godot.metal"'],
                                stdout=stream, stderr=errors)
        try:
            time.sleep(1)
            yield proc
        finally:
            if proc.poll() is None:
                proc.send_signal(signal.SIGINT)
            try:
                proc.wait(timeout=10)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
