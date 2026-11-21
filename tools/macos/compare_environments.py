"""Measure fixed environment views from verified macOS packs with one external fixture."""
import argparse
import hashlib
import json
import platform
import plistlib
import shutil
import tempfile
from pathlib import Path

from benchmark_release import measure
from compare_player_startup import run_player

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / 'scripts/diagnostics/integration_benchmark.gd'
VIEWS = 16
PHOTO_VIEWS = VIEWS + 3


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def select_user(project, token):
    (project / 'override.cfg').write_text('[application]\nconfig/use_custom_user_dir=true\n'
                                          f'config/custom_user_dir_name="{token}"\n')
    return Path.home() / 'Library/Application Support' / token


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('reference', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--candidate', type=Path)
    args = parser.parse_args()
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=False)
    manifest = {'host': platform.platform(), 'fixture_sha256': digest(FIXTURE), 'packs': {}, 'attempts': [], 'player_launches': []}
    report = out / 'comparison.json'
    apps = {'reference': args.reference.resolve()}
    if args.candidate:
        apps['candidate'] = args.candidate.resolve()
    with tempfile.TemporaryDirectory(prefix='lto-world-') as tmp:
        contexts = {}
        for version, app in apps.items():
            project = Path(tmp) / version
            project.mkdir()
            pack, = (app / 'Contents/Resources').glob('*.pck')
            token = Path(tmp).name + '-' + version
            user = select_user(project, token)
            target = project / pack.name
            shutil.copyfile(pack, target)
            info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
            manifest['packs'][version] = {'sha256': digest(target), 'build': info['LTOBuildCommit']}
            contexts[version] = (app / 'Contents/MacOS/choose-renderer', project, target, user)
        if args.candidate:
            for i, preset in enumerate(('low', 'medium', 'high')):
                for state in ('cold', 'warm'):
                    order = list(apps) if (i + int(state == 'warm')) % 2 == 0 else list(reversed(apps))
                    for version in order:
                        chooser, project, pack, matrix_user = contexts[version]
                        user = select_user(project, matrix_user.name + '-player-' + preset)
                        dest = out / (version + '-player')
                        dest.mkdir(exist_ok=True)
                        launch = run_player(chooser, pack, dest, 'metal', preset, state, user)
                        manifest['player_launches'].append(dict(version=version, **launch))
                        report.write_text(json.dumps(manifest, indent=2))
            for _, project, _, user in contexts.values():
                select_user(project, user.name)
        schedules = [(v, 'first') for v in apps] + [(v, 'repeat') for v in reversed(apps)] if args.candidate else []
        schedules += [(v, 'images') for v in apps]
        poses = {}
        for version, stage in schedules:
            name = version + '-' + stage
            chooser, project, pack, user = contexts[version]
            flags = ['--suite=environment', '--warmup=48', '--samples=180']
            if stage == 'images':
                flags = ['--suite=environment', '--warmup=24', '--samples=24', '--shots=' + str(out / name)]
            run = measure(str(chooser), project, out, name, str(FIXTURE), flags, 1200,
                          ['metal', '--main-pack', str(pack)], user / 'shader_cache')
            raw = out / (name + '.json')
            data = json.loads(raw.read_text()) if raw.exists() else {}
            camera = data.get('camera_poses', [])
            kind = 'images' if stage == 'images' else 'timing'
            expected_poses = poses.setdefault(kind, camera) if camera else []
            checks = data.get('field_checks', [])
            if stage == 'images':
                run['daylit_field_checks'] = checks
            visual_ok = (len(checks) == 6 and all(row['near_black_fraction'] < .01 for row in checks)
                         and len(list((out / name).glob('*.png'))) == PHOTO_VIEWS * 3) if stage == 'images' else True
            run['passed'] = bool(not run['returncode'] and not run['timed_out'] and not run['engine_diagnostics']
                                 and data.get('driver') == 'metal' and data.get('renderer') == 'forward_plus'
                                 and data.get('runtime_binary') == 'LastTrainOutMetal' and data.get('resolution') == '(960, 540)'
                                 and len(data.get('results', [])) == VIEWS * 3 * 2
                                 and len(camera) == (PHOTO_VIEWS if stage == 'images' else VIEWS) * 3
                                 and expected_poses == camera and visual_ok)
            manifest['attempts'].append(run)
            report.write_text(json.dumps(manifest, indent=2))
    return int(any(not run['passed'] for run in manifest['attempts'] + manifest['player_launches']))


if __name__ == '__main__':
    raise SystemExit(main())
