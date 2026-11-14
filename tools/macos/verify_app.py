#!/usr/bin/env python3
"""Checks an exported "Last Train Out.app" bundle and, optionally, the ZIP made from it.

    python3 tools/macos/verify_app.py "build/macos/Last Train Out.app"
    python3 tools/macos/verify_app.py "build/macos/Last Train Out.app" --expect-signature adhoc
    python3 tools/macos/verify_app.py "build/macos/Last Train Out.app" --zip LastTrainOut-macos-universal.zip

What is checked:
  * the bundle layout, Info.plist and the executable (present, executable, Apple Silicon + Intel);
  * the game data pack: every scene, script and resource of the project is inside it, and
    nothing from tests/, tools/ or docs/ is;
  * on macOS, the code signature (ad-hoc for development builds, Developer ID for signed ones);
  * with --zip, that the archive holds exactly this bundle, file for file, and keeps the
    executable bit.

Uses only the Python standard library. The file-level checks run on any system; the
signature checks need macOS. Exit code 0 means every check passed.
"""
from __future__ import annotations

import argparse
import hashlib
import os
import plistlib
import shutil
import stat
import struct
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BUNDLE_IDENTIFIER = "com.lasttrainout.game"
# Project folders whose contents must be in the exported game, and those that must not be.
GAME_DIRECTORIES = ("scenes", "scripts", "systems", "resources")
EXCLUDED_DIRECTORIES = ("tests/", "tools/", "docs/")
CPU_NAMES = {0x01000007: "x86_64", 0x0100000C: "arm64"}

results: list[tuple[bool, str, str]] = []


def check(ok: bool, name: str, detail: str = "") -> bool:
    results.append((bool(ok), name, detail))
    print(f"{'ok  ' if ok else 'FAIL'}  {name}{f'  ({detail})' if detail else ''}")
    return bool(ok)


def note(name: str, detail: str) -> None:
    print(f"info  {name}  ({detail})")


def macho_architectures(path: Path) -> list[str]:
    """CPU architectures of a Mach-O file (universal or single-architecture)."""
    with open(path, "rb") as handle:
        head = handle.read(8)
        if len(head) < 8:
            return []
        magic = struct.unpack(">I", head[:4])[0]
        if magic in (0xCAFEBABE, 0xCAFEBABF):  # universal ("fat") binary
            count = struct.unpack(">I", head[4:8])[0]
            entry = 32 if magic == 0xCAFEBABF else 20
            names = []
            for _ in range(count):
                cpu = struct.unpack(">I", handle.read(entry)[:4])[0]
                names.append(CPU_NAMES.get(cpu, hex(cpu)))
            return names
        if struct.unpack("<I", head[:4])[0] == 0xFEEDFACF:  # 64-bit, single architecture
            return [CPU_NAMES.get(struct.unpack("<I", head[4:8])[0], "unknown")]
    return []


def pck_paths(path: Path) -> list[str]:
    """File paths stored in a Godot 4 data pack."""
    with open(path, "rb") as handle:
        if handle.read(4) != b"GDPC":
            raise ValueError("not a Godot data pack")
        version, _major, _minor, _patch, _flags = struct.unpack("<5I", handle.read(20))
        handle.read(8)  # offset of the file data
        if version >= 3:
            handle.seek(struct.unpack("<Q", handle.read(8))[0])
        else:
            handle.read(16 * 4)
        count = struct.unpack("<I", handle.read(4))[0]
        paths = []
        for _ in range(count):
            length = struct.unpack("<I", handle.read(4))[0]
            paths.append(handle.read(length).rstrip(b"\0").decode("utf-8").removeprefix("res://"))
            handle.read(8 + 8 + 16 + 4)  # offset, size, md5, flags
        return paths


def project_setting(key: str) -> str:
    for line in (ROOT / "project.godot").read_text(encoding="utf-8").splitlines():
        if line.startswith(key + "="):
            return line.split("=", 1)[1].strip().strip('"')
    return ""


def expected_game_files() -> list[str]:
    files = []
    for directory in GAME_DIRECTORIES:
        for path in sorted((ROOT / directory).rglob("*")):
            if path.suffix in (".tscn", ".tres", ".gd"):
                files.append(path.relative_to(ROOT).as_posix())
    return files


def in_pack(source: str, packed: set[str]) -> bool:
    """Godot stores scenes/resources behind a .remap entry and scripts as compiled .gdc files."""
    if source in packed or source + ".remap" in packed:
        return True
    return source.endswith(".gd") and source[:-3] + ".gdc" in packed


def file_digest(path: Path) -> str:
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def run(command: list[str]) -> tuple[int, str]:
    done = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    return done.returncode, done.stdout.strip()


# --- Bundle ------------------------------------------------------------------

def verify_bundle(app: Path, expect_signature: str) -> None:
    print(f"\n== Bundle: {app}")
    if not check(app.is_dir() and app.suffix == ".app", "the .app bundle exists"):
        return
    contents = app / "Contents"
    info_path = contents / "Info.plist"
    if not check(info_path.is_file(), "Info.plist exists"):
        return
    try:
        with open(info_path, "rb") as handle:
            info = plistlib.load(handle)
    except Exception as error:  # noqa: BLE001 - any parse error is a failed check
        check(False, "Info.plist is a valid property list", str(error))
        return
    check(True, "Info.plist is a valid property list")
    if shutil.which("plutil"):
        code, output = run(["plutil", "-lint", str(info_path)])
        check(code == 0, "plutil accepts Info.plist", output.splitlines()[-1] if output else "")

    executable_name = info.get("CFBundleExecutable", "")
    check(bool(executable_name), "Info.plist names the executable", executable_name)
    check(info.get("CFBundleIdentifier") == BUNDLE_IDENTIFIER, "bundle identifier", str(info.get("CFBundleIdentifier")))
    check(info.get("CFBundlePackageType") == "APPL", "bundle is an application")
    version = project_setting("config/version")
    check(info.get("CFBundleShortVersionString") == version, "version matches the project", f"{info.get('CFBundleShortVersionString')}")
    check(str(info.get("CFBundleVersion", "")).isdigit(), "build number is set", str(info.get("CFBundleVersion")))
    minimums = info.get("LSMinimumSystemVersionByArchitecture", {})
    check("arm64" in minimums and "x86_64" in minimums, "minimum macOS is declared for both architectures",
          ", ".join(f"{arch} {minimums[arch]}" for arch in sorted(minimums)))
    check(bool(info.get("NSHighResolutionCapable")), "Retina rendering is enabled")
    note("build", f"number {info.get('LTOBuildNumber', '?')}, commit {info.get('LTOBuildCommit', '?')}, "
                  f"kind {info.get('LTOBuildKind', '?')}")

    executable = contents / "MacOS" / executable_name
    if check(executable.is_file(), "the executable exists inside the bundle", f"Contents/MacOS/{executable_name}"):
        check(os.access(executable, os.X_OK), "the executable is marked executable")
        architectures = macho_architectures(executable)
        check("arm64" in architectures and "x86_64" in architectures,
              "the executable is universal: Apple Silicon (arm64) and Intel (x86_64)", ", ".join(architectures) or "not a Mach-O file")
        note("executable size", f"{executable.stat().st_size / 1_000_000:.0f} MB (the Godot runtime; no Godot install is needed to play)")
        if shutil.which("lipo"):
            code, output = run(["lipo", "-archs", str(executable)])
            check(code == 0 and {"arm64", "x86_64"} <= set(output.split()), "lipo confirms both architectures", output)

    check((contents / "Resources" / str(info.get("CFBundleIconFile", "icon.icns"))).is_file(), "the app icon exists")

    packs = sorted((contents / "Resources").glob("*.pck"))
    if check(len(packs) == 1, "the game data pack exists", packs[0].name if packs else "no .pck in Contents/Resources"):
        verify_pack(packs[0])

    verify_signature(app, expect_signature)


def verify_pack(pack: Path) -> None:
    try:
        packed = set(pck_paths(pack))
    except Exception as error:  # noqa: BLE001
        check(False, "the game data pack can be read", str(error))
        return
    check(len(packed) > 50, "the game data pack can be read", f"{len(packed)} files, {pack.stat().st_size / 1000:.0f} kB")
    check("project.binary" in packed, "project settings are in the pack")
    main_scene = project_setting("run/main_scene").removeprefix("res://")
    check(bool(main_scene) and in_pack(main_scene, packed), "the main scene is in the pack", main_scene)
    expected = expected_game_files()
    missing = [source for source in expected if not in_pack(source, packed)]
    check(not missing, "every scene, script and resource of the game is in the pack",
          f"{len(expected)} project files" if not missing else "missing: " + ", ".join(missing[:8]))
    unwanted = sorted(path for path in packed if path.startswith(EXCLUDED_DIRECTORIES))
    check(not unwanted, "tests, tools and docs are left out of the game", ", ".join(unwanted[:5]))


def verify_signature(app: Path, expect_signature: str) -> None:
    check((app / "Contents" / "_CodeSignature" / "CodeResources").is_file(), "the bundle carries a code signature")
    if not shutil.which("codesign"):
        note("code signature", "codesign is not available on this system, so the signature was not validated")
        if expect_signature:
            check(False, f"signature is {expect_signature}", "cannot be checked without macOS")
        return
    code, output = run(["codesign", "--verify", "--deep", "--strict", "--verbose=2", str(app)])
    check(code == 0, "codesign verifies the signature", output.splitlines()[-1] if output else "")
    _code, description = run(["codesign", "-dv", "--verbose=4", str(app)])
    adhoc = "Signature=adhoc" in description
    authorities = [line.split("=", 1)[1] for line in description.splitlines() if line.startswith("Authority=")]
    hardened = any("runtime" in line for line in description.splitlines() if line.startswith("CodeDirectory") or "flags=" in line)
    note("signature", "ad-hoc" if adhoc else ("; ".join(authorities) or "unknown"))
    if expect_signature == "adhoc":
        check(adhoc, "signature is ad-hoc (development build)")
    elif expect_signature == "developer-id":
        check(any(a.startswith("Developer ID Application") for a in authorities), "signed with a Developer ID Application certificate",
              authorities[0] if authorities else "no signing authority")
        check(hardened, "the hardened runtime is enabled")
        check("Timestamp=" in description, "the signature has a secure timestamp")


# --- ZIP ---------------------------------------------------------------------

def verify_zip(archive_path: Path, app: Path | None) -> None:
    print(f"\n== ZIP: {archive_path}")
    if not check(archive_path.is_file(), "the ZIP exists"):
        return
    try:
        archive = zipfile.ZipFile(archive_path)
        broken = archive.testzip()
    except Exception as error:  # noqa: BLE001
        check(False, "the ZIP can be read", str(error))
        return
    check(broken is None, "the ZIP is intact", broken or f"{archive_path.stat().st_size / 1_000_000:.1f} MB")
    note("ZIP sha256", file_digest(archive_path))

    # macOS stores extended attributes under __MACOSX/; they are not part of the bundle.
    entries = [entry for entry in archive.infolist() if not entry.filename.startswith("__MACOSX/")]
    top_level = sorted({entry.filename.split("/", 1)[0] for entry in entries})
    if not check(len(top_level) == 1 and top_level[0].endswith(".app"), "the ZIP holds exactly one .app at its top level", ", ".join(top_level)):
        return
    bundle_name = top_level[0]
    files = {entry.filename[len(bundle_name) + 1:]: entry for entry in entries if not entry.is_dir()}
    check("Contents/Info.plist" in files, "the ZIP contains Info.plist")
    try:
        info = plistlib.loads(archive.read(files["Contents/Info.plist"]))
        executable = f"Contents/MacOS/{info['CFBundleExecutable']}"
    except Exception:  # noqa: BLE001
        executable = ""
    if check(executable in files, "the ZIP contains the executable", executable):
        mode = files[executable].external_attr >> 16
        check(bool(mode & stat.S_IXUSR), "the executable keeps its executable permission in the ZIP", oct(mode & 0o777))
    check(any(name.startswith("Contents/Resources/") and name.endswith(".pck") for name in files), "the ZIP contains the game data pack")
    check("Contents/_CodeSignature/CodeResources" in files, "the ZIP contains the code signature")

    if app is None:
        return
    check(bundle_name == app.name, "the bundle in the ZIP has the expected name", bundle_name)
    on_disk = {path.relative_to(app).as_posix(): path for path in sorted(app.rglob("*")) if path.is_file() and not path.is_symlink()}
    check(set(files) == set(on_disk), "the ZIP holds every file of the bundle and nothing else",
          f"{len(files)} files" if set(files) == set(on_disk) else
          f"only in ZIP: {sorted(set(files) - set(on_disk))[:4]}, only in bundle: {sorted(set(on_disk) - set(files))[:4]}")
    different = [name for name in sorted(set(files) & set(on_disk))
                 if hashlib.sha256(archive.read(files[name])).hexdigest() != file_digest(on_disk[name])]
    check(not different, "every file in the ZIP is identical to the bundle", ", ".join(different[:4]))


def write_summary(title: str) -> None:
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if not summary:
        return
    failed = [r for r in results if not r[0]]
    with open(summary, "a", encoding="utf-8") as handle:
        handle.write(f"### {title}: {len(results) - len(failed)} of {len(results)} checks passed\n\n")
        for _ok, name, detail in failed:
            handle.write(f"- :x: {name}{f' ({detail})' if detail else ''}\n")
        handle.write("\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("app", nargs="?", help="path to the .app bundle")
    parser.add_argument("--zip", dest="archive", help="also check this ZIP (against the bundle, when one is given)")
    parser.add_argument("--expect-signature", choices=["adhoc", "developer-id"], default="",
                        help="require this kind of code signature (needs macOS)")
    parser.add_argument("--title", default="Bundle check", help="heading used in the GitHub job summary")
    args = parser.parse_args()
    if not args.app and not args.archive:
        parser.error("give a .app bundle, a --zip, or both")

    app = Path(args.app) if args.app else None
    if app is not None and not args.archive:
        verify_bundle(app, args.expect_signature)
    elif app is not None:
        verify_zip(Path(args.archive), app)
    else:
        verify_zip(Path(args.archive), None)

    failed = [r for r in results if not r[0]]
    print(f"\n{len(results) - len(failed)} of {len(results)} checks passed")
    write_summary(args.title)
    return 1 if failed or not results else 0


if __name__ == "__main__":
    sys.exit(main())
