#!/usr/bin/env python3
"""Fetch only the pinned CC0 sources used by the M2.6 environment continuation."""
import argparse
import json
import os
from pathlib import Path

from fetch_sources import fetch

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--out", type=Path, default=Path(os.environ.get("LTO_ENV_SOURCE", "/tmp/lto27-sources")))
args = parser.parse_args()
for asset in json.loads((ROOT / "assets/environment/sources.json").read_text()):
    assert asset["license"] == "CC0-1.0"
    for file in asset["files"]:
        destination = args.out / asset["id"] / file["file"]
        assert destination.resolve().is_relative_to(args.out.resolve())
        fetch(file["url"], destination, file["sha256"])
    print("Verified", asset["id"], asset["resolution"], asset["license"])
