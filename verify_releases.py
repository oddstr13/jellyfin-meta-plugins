#!/usr/bin/env python3
import os
from typing import Dict, Optional, Tuple
import json
import subprocess

import requests
import yaml

REPO_URL = "https://repo.jellyfin.org/master/releases/plugin/manifest-stable.json"

BLACKLIST = [
    "jellyfin-plugin-template",  # Shouldn't be published
]


def str2ver(s: str) -> Optional[Tuple[int, int, int, int]]:
    try:
        ver = tuple([int(x) for x in s.lstrip("v").split(".")])
    except ValueError:
        return None

    return ver + (0,) * (4 - len(ver))


def ver2str(v: Optional[Tuple[int, int, int, int]]) -> str:
    if v is None:
        return "None"
    return f"{v[0]}.{v[1]}.{v[2]}.{v[3]}"


def get_version(path: str) -> Optional[Tuple[int, int, int, int]]:
    # git describe --abbrev=0
    proc = subprocess.run(
        ["git", "describe", "--tags", "--abbrev=0"],
        cwd=path,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        encoding="utf-8",
    )

    return str2ver(proc.stdout)


def read_manifest(path: str) -> Optional[Dict]:
    try:
        with open(os.path.join(path, "build.yaml")) as fh:
            return yaml.safe_load(fh)
    except OSError:
        return None


published = requests.get(REPO_URL).json()

for directory in os.listdir("."):
    if not os.path.isdir(directory):
        continue

    if not directory.startswith("jellyfin-plugin-"):
        continue

    if directory in BLACKLIST:
        continue

    manifest = read_manifest(directory)

    if manifest is None:
        continue

    name = manifest.get("name")

    if name is None:
        continue

    manifest_version = str2ver(manifest.get("version", ""))
    if not manifest_version > (0, 0, 0, 0):
        print(f"WARNING: No version specified in build.yaml {directory} ({name}).")

    git_version = get_version(directory)

    if git_version is None:
        print(f"ERROR: No git tag locally {directory} ({name})")
    elif git_version > manifest_version:
        print(
            f"ERROR: Git tag has higher version than build.yaml {directory} ({name})."
        )

    _repo_plugin = list(filter(lambda obj: obj.get("name") == name, published))

    if not _repo_plugin:
        print(f"WARNING: {directory} ({name}) is not published.")
        continue

    repo_plugin = _repo_plugin[0]

    repo_versions = [str2ver(x.get("version")) for x in repo_plugin.get("versions", [])]

    if not repo_versions:
        print(f"ERROR: {directory} ({name}) does not have any published versions.")
        continue

    repo_version = sorted(repo_versions, reverse=True)[0]

    # print(f"{directory} ({name}) git={ver2str(git_version)}, yaml={ver2str(manifest_version)}, repo={ver2str(repo_version)}")
    if repo_version == git_version:
        if manifest_version != repo_version:
            print(f"INFO: {directory} ({name}) v{ver2str(repo_version)} is published, v{ver2str(manifest_version)} is pending.")
        else:
            print(f"OK: {directory} ({name}) v{ver2str(repo_version)} is published!")
    elif repo_version == manifest_version:
        print(
            f"WARNING: {directory} ({name}) is published v{ver2str(repo_version)}, but there is no corresponding git tag (locally, at v{ver2str(git_version)})."
        )
    else:
        print(
            f"ERROR: {directory} ({name}) is not published, repo at v{ver2str(repo_version)}, git tag at v{ver2str(git_version)} and yaml at v{ver2str(manifest_version)}!"
        )
