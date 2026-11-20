"""Identify Godot diagnostics even when unbuffered stderr interrupts buffered stdout."""
import re

ENGINE_DIAGNOSTIC = re.compile(
    r'SCRIPT ERROR:|ERROR:|WARNING:|Leaked instance:|Resources? still in use:|'
    r'ObjectDB instances leaked at exit|resources still in use at exit'
)


def engine_diagnostics(lines):
    messages = []
    for line in lines:
        match = ENGINE_DIAGNOSTIC.search(line)
        if match:
            messages.append(line[match.start():])
    return messages


if __name__ == '__main__':
    import argparse
    from pathlib import Path

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('log', type=Path)
    options = parser.parse_args()
    found = engine_diagnostics(options.log.read_text(errors='replace').splitlines())
    if found:
        print('\n'.join(found))
    raise SystemExit(1 if found else 0)
