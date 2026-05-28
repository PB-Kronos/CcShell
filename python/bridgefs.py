from __future__ import annotations

import shutil
import urllib.request
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
GITHUB_RAW_BASE = "https://raw.githubusercontent.com/PB-Kronos/CcShell-runtime/main"


def _normalize(path: str) -> str:
    return path.replace("\\", "/")


def resolve_path(path: str) -> Path:
    raw = _normalize(path)
    if not raw:
        return REPO_ROOT.resolve()

    p = Path(raw)
    if p.is_absolute():
        return p

    return (REPO_ROOT / raw).resolve()


def read_text(path: str, encoding: str = "utf-8") -> str:
    return resolve_path(path).read_text(encoding=encoding)


def write_text(path: str, data: str, encoding: str = "utf-8") -> None:
    target = resolve_path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(data, encoding=encoding)


def exists(path: str) -> bool:
    return resolve_path(path).exists()


def is_dir(path: str) -> bool:
    return resolve_path(path).is_dir()


def list_dir(path: str) -> list[str]:
    target = resolve_path(path)
    return sorted(item.name for item in target.iterdir())


def make_dir(path: str) -> None:
    resolve_path(path).mkdir(parents=True, exist_ok=True)


def delete(path: str) -> None:
    target = resolve_path(path)
    if target.is_dir():
        shutil.rmtree(target)
    elif target.exists():
        target.unlink()


def copy(src: str, dst: str) -> None:
    source = resolve_path(src)
    target = resolve_path(dst)
    target.parent.mkdir(parents=True, exist_ok=True)
    if source.is_dir():
        shutil.copytree(source, target, dirs_exist_ok=True)
    else:
        shutil.copy2(source, target)


def move(src: str, dst: str) -> None:
    source = resolve_path(src)
    target = resolve_path(dst)
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(str(source), str(target))


def download(src: str, dst: str) -> None:
    """
    Download a file from the repo or a full URL into the host filesystem.

    - If src starts with http:// or https://, it is fetched directly.
    - Otherwise src is treated as a path inside the GitHub repo.
    """

    url = src if src.startswith(("http://", "https://")) else f"{GITHUB_RAW_BASE}/{src.lstrip('/')}"
    target = resolve_path(dst)
    target.parent.mkdir(parents=True, exist_ok=True)

    with urllib.request.urlopen(url) as response:
        target.write_bytes(response.read())
