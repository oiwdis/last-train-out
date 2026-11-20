#!/usr/bin/env python3
"""Run a one-factor shadow experiment or a backend comparison on the original exported pack."""
import argparse
import json
from pathlib import Path
import plistlib
import platform
import shutil
import subprocess
import tempfile
import time
import uuid
from stress_release import digest

PACK_SHA = '7950f615a9ec2a91e0a3e2ba0fd71b76732a4d8b1b5346a663494b8acd656703'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('group', choices=['shadows','packaged-backends'])
    parser.add_argument('out', type=Path)
    args = parser.parse_args()
    app, out = args.app.resolve(), args.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    start = time.time()
    info = plistlib.loads((app/'Contents/Info.plist').read_bytes())
    binary = app/'Contents/MacOS'/info['CFBundleExecutable']
    original, = (app/'Contents/Resources').glob('*.pck')
    rows = []
    meta = {'bundle':info, 'os':platform.platform(), 'group':args.group, 'pack_sha256':digest(original),
            'runs':rows, 'complete':False, 'deadline_minutes':40}
    if meta['pack_sha256'] != PACK_SHA:
        raise SystemExit('Use the exact 6038bfcd development pack for this historical experiment.')
    token = 'LTO-353-export-ab-' + uuid.uuid4().hex
    schedule = []
    if args.group == 'shadows':
        # Rotate first position across the four treatments.
        options = ['control','directional','local','both']
        for n in range(4):
            for treatment in options[n:]+options[:n]:
                schedule.append((f'{treatment}-{n+1}',treatment,'forward_plus',True))
    else:
        options = ['forward_plus','mobile','gl_compatibility']
        for n in range(3):
            for method in options[n:]+options[:n]:
                for cold in [True,False]:
                    schedule.append((f'{method}-{n+1}', 'control', method, cold))
    with tempfile.TemporaryDirectory(prefix='lto353-pack-') as td:
        directory = Path(td)
        pack = directory/original.name
        shutil.copyfile(original,pack)
        assert digest(pack) == PACK_SHA
        for cache, treatment, method, cold in schedule:
            name = cache + ('-cold' if cold else '-warm')
            user_name = token + '-' + cache
            (directory/'override.cfg').write_text('[application]\nconfig/use_custom_user_dir=true\n'
                                                  'config/custom_user_dir_name="'+user_name+'"\n')
            report = out/(name+'.json')
            driver = 'opengl3' if method=='gl_compatibility' else 'vulkan'
            cmd = [str(binary),'--main-pack',str(pack),'--verbose','--audio-driver','Dummy',
                   '--resolution','960x540','--position','32,64','--rendering-method',method,
                   '--rendering-driver',driver,'--script',str(Path(__file__).with_name('exported_shadow_probe.gd').resolve()),
                   '--','--graphics=high','--profile-phases','--out='+str(report),'--treatment='+treatment]
            elapsed = time.monotonic()
            deadline = min(180, start+2400-time.time())
            row = {'name':name,'method':method,'driver':driver,'cold':cold,'treatment':treatment,'command':cmd}
            log = out/(name+'.log')
            if deadline <= 0:
                row.update(skipped='series deadline', code=None, passed=False)
            else:
                peak = 0
                with log.open('w') as f:
                    proc = subprocess.Popen(cmd,stdout=f,stderr=subprocess.STDOUT)
                    try:
                        while proc.poll() is None:
                            if time.monotonic()-elapsed >= deadline:
                                row['timeout'] = True
                                proc.kill()
                                break
                            rss = subprocess.run(['ps','-o','rss=','-p',str(proc.pid)],capture_output=True,text=True)
                            if rss.stdout.strip().isdigit(): peak = max(peak,int(rss.stdout.strip())*1024)
                            time.sleep(.5)
                    finally:
                        if proc.poll() is None: proc.kill()
                        proc.wait()
                row.update(code=proc.returncode,seconds=time.monotonic()-elapsed,peak_rss=peak)
                lines = log.read_text(errors='replace').splitlines()
                row['diagnostics']=[l for l in lines if l.startswith(('ERROR:', 'SCRIPT ERROR:', 'WARNING:','[mvk-error]'))]
                row['device_loss']=any('device was lost' in l.lower() or 'kIOGPUCommandBufferCallbackErrorTimeout' in l for l in lines)
                row['cache_events']=[l for l in lines if 'PSO cache' in l]
                data = {}
                if report.exists():
                    try: data=json.loads(report.read_text())
                    except ValueError as error: row['invalid_report']=str(error)
                row['actual']=[data.get('renderer'),data.get('driver')]
                row['ready_ms']=next((e['ticks_ms'] for e in data.get('events',[]) if e['phase']=='mission_ready'),None)
                journal = Path(str(report)+'.shadow.jsonl')
                row['shadow_phases']=[json.loads(l)['phase'] for l in journal.read_text().splitlines()] if journal.exists() else []
                row['passed']=(not proc.returncode and not row['device_loss'] and data.get('mission_ready') is True
                               and row['actual']==[method,driver] and row['shadow_phases']==['begin','restored']
                               and not any(l.startswith(('ERROR:', 'SCRIPT ERROR:')) for l in row['diagnostics']))
                if data and Path(data.get('user_data_directory','')).name != user_name:
                    raise RuntimeError('Export did not use its private test directory')
            rows.append(row)
            (out/'series.json').write_text(json.dumps(meta,indent=2))
            print(name,row['code'],row['passed'],row.get('ready_ms'),flush=True)
    for path in (Path.home()/'Library/Logs/DiagnosticReports').glob('*.ips'):
        if path.stat().st_mtime >= start and 'last train out' in path.name.lower():
            (out/'crash-reports').mkdir(exist_ok=True)
            shutil.copy2(path,out/'crash-reports'/path.name)
    meta['complete']=True
    (out/'series.json').write_text(json.dumps(meta,indent=2))
    return int(any(not r['passed'] for r in rows))


if __name__=='__main__':
    raise SystemExit(main())
