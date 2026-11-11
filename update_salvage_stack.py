#!/usr/bin/env python3
"""Update the project folder containing this script (Python 3.9+).

Keep this script beside project.godot in your local Salvage Stack folder.
Close Godot and stop editing the project before updating.

  python3 update_salvage_stack.py
  python3 update_salvage_stack.py "/anywhere/update.zip"
  python3 update_salvage_stack.py "/anywhere/extracted-update" --dry-run

With no source argument, paste or drag the ZIP/extracted folder into Terminal
when prompted. No Downloads location is assumed. An extracted wrapper folder
containing one Salvage Stack project is also accepted.

The destination defaults to this script's folder, regardless of Terminal's
current directory. An explicit destination remains available as a second
argument for initial installation or updating from a separate script location.

Replaced files are backed up inside the destination's .salvage-update-backups
folder. Existing extra files, saves, Git, caches and signing credentials are
retained. Local edits to files supplied by the update are replaced and backed
up. Failed replacements trigger rollback. No old project files are deleted.
This does not install the Android APK. Keep backups out of Git.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import shlex
import stat
import sys
import tempfile
import unicodedata
import uuid
from datetime import datetime, timezone
from zipfile import ZipFile, BadZipFile, ZIP_DEFLATED

BACKUPS = '.salvage-update-backups'
PROTECTED_DIRS = {'.git', '.godot', BACKUPS, '.aws', '.codex', '.agents',
                  'saves', 'app_userdata', '__macosx'}
PROTECTED_FILES = {'export_credentials.cfg', '.ds_store', '.env'}
PROJECT_NAME = re.compile(r'^\s*config/name\s*=\s*"Salvage Stack"\s*$', re.MULTILINE)


def protected(path):
    return (any(p.casefold() in PROTECTED_DIRS for p in path.parts)
            or path.name.casefold() in PROTECTED_FILES
            or path.name.casefold().startswith(('salvage-save.json', '.env.'))
            or path.suffix.casefold() in {'.keystore', '.jks', '.p12', '.pfx', '.p8', '.key', '.pem', '.mobileprovision'})


def destination(root, relative):
    """Reject symlinks and conflicting directories before writing anything."""
    path = root
    for i, part in enumerate(relative.parts):
        path = path / part
        if path.is_symlink():
            raise ValueError('Refusing a symlink in destination: ' + str(path))
        if path.exists() and i < len(relative.parts)-1 and not path.is_dir():
            raise ValueError('A file blocks a destination directory: ' + str(path))
    if path.exists() and not path.is_file():
        raise ValueError('Destination is not a regular file: ' + str(path))
    return path


def digest(stream):
    result = hashlib.sha256()
    for chunk in iter(lambda: stream.read(1024 * 1024), b''):
        result.update(chunk)
    return result.digest()


def archive_files(archive):
    files = []
    if len(archive.infolist()) > 20000 or sum(i.file_size for i in archive.infolist()) > 512*1024*1024:
        raise ValueError('ZIP exceeds the updater limit (20,000 entries / 512 MiB uncompressed).')
    for info in archive.infolist():
        name = info.filename
        parts = name.rstrip('/').split('/')
        if '\\' in name or ':' in name or any(p in ('', '.', '..') for p in parts) or name.startswith('/'):
            raise ValueError('Unsafe ZIP path: ' + repr(name))
        mode = info.external_attr >> 16
        if stat.S_ISLNK(mode) or (stat.S_IFMT(mode) not in (0, stat.S_IFREG, stat.S_IFDIR)):
            raise ValueError('ZIP contains a link or special file: ' + name)
        if not info.is_dir() and parts[0].casefold() != '__macosx':
            files.append((info, PurePosixPath(name)))
    markers = [(info, p) for info, p in files if p.name == 'project.godot']
    if len(markers) != 1:
        raise ValueError('ZIP must contain exactly one project.godot.')
    marker, marker_path = markers[0]
    if not PROJECT_NAME.search(archive.read(marker).decode('utf-8-sig')):
        raise ValueError('ZIP is not a Salvage Stack project.')
    prefix = marker_path.parent
    seen = set()
    selected = []
    for info, path in files:
        try:
            relative = path.relative_to(prefix)
        except ValueError:
            continue
        if protected(relative):
            continue
        key = unicodedata.normalize('NFC', str(relative)).casefold()
        if key in seen:
            raise ValueError('Duplicate or case-conflicting ZIP path: ' + str(relative))
        seen.add(key)
        selected.append((info, relative))
    return selected


def update(zip_path, project, dry_run=False, source_label=None):
    zip_path = Path(zip_path).expanduser().resolve()
    project = Path(project).expanduser().resolve()
    if project.exists() and not project.is_dir():
        raise ValueError('Project path is not a folder.')
    marker = destination(project, PurePosixPath('project.godot'))
    if marker.exists():
        if not PROJECT_NAME.search(marker.read_text(encoding='utf-8-sig')):
            raise ValueError('Destination contains a different Godot project. No files changed.')
    elif project.exists() and any(project.iterdir()):
        raise ValueError('Destination is not empty and has no project.godot. Select the game folder itself.')
    with ZipFile(zip_path) as archive:
        plan = []
        for info, relative in archive_files(archive):
            target = destination(project, relative)
            with archive.open(info) as incoming:
                incoming_hash = digest(incoming)  # Reading also verifies the ZIP entry CRC.
            if target.exists():
                with target.open('rb') as existing:
                    if digest(existing) == incoming_hash:
                        continue
            plan.append((info, relative, target, target.exists()))
        for _, relative, _, existed in plan:
            print(('UPDATE ' if existed else 'ADD    ') + str(relative))
        if dry_run or not plan:
            print(('Dry run: ' if dry_run else '') + str(len(plan)) + ' file(s) to change. No files changed.')
            return
        project.mkdir(parents=True, exist_ok=True)
        backup_dir = project / BACKUPS
        if backup_dir.is_symlink() or (backup_dir.exists() and not backup_dir.is_dir()):
            raise ValueError('Backup location is not a safe directory.')
        # Stage every incoming file first; a damaged ZIP cannot partially update the game.
        with tempfile.TemporaryDirectory(prefix='.salvage-update-', dir=str(project)) as staging:
            staging = Path(staging)
            for info, relative, _, _ in plan:
                staged = staging / str(relative)
                staged.parent.mkdir(parents=True, exist_ok=True)
                with archive.open(info) as source, staged.open('wb') as output:
                    shutil.copyfileobj(source, output)
            backup_dir.mkdir(exist_ok=True)
            stamp = datetime.now(timezone.utc).strftime('%Y%m%d-%H%M%S')
            backup = backup_dir / (stamp + '-' + uuid.uuid4().hex[:8] + '.zip')
            with ZipFile(backup, 'x', compression=ZIP_DEFLATED) as previous:
                for _, relative, target, existed in plan:
                    if existed:
                        previous.write(target, 'files/' + str(relative))
                previous.writestr('manifest.json', json.dumps({
                    'project': str(project), 'source': str(source_label or zip_path),
                    'replaced_files': [str(r) for _, r, _, old in plan if old],
                    'added_files': [str(r) for _, r, _, old in plan if not old],
                }, indent=2))
            touched = []
            try:
                for _, relative, target, existed in plan:
                    destination(project, relative)
                    target.parent.mkdir(parents=True, exist_ok=True)
                    if existed:
                        shutil.copymode(target, staging / str(relative))
                    touched.append((relative, target, existed))
                    os.replace(staging / str(relative), target)
            except BaseException:
                try:
                    with ZipFile(backup) as previous:
                        for relative, target, existed in reversed(touched):
                            if existed:
                                restored = staging / 'rollback.tmp'
                                with previous.open('files/' + str(relative)) as source, restored.open('wb') as out:
                                    shutil.copyfileobj(source, out)
                                os.replace(restored, target)
                            else:
                                target.unlink(missing_ok=True)
                except BaseException as rollback_error:
                    raise RuntimeError('Update failed and rollback was incomplete. Restore backup: ' + str(backup)) from rollback_error
                print('Update interrupted or failed; changed files were rolled back.', file=sys.stderr)
                raise
            print('Updated ' + str(len(plan)) + ' file(s) in ' + str(project))
            print('Backup: ' + str(backup))
            print('Open project.godot in Godot and let changed assets import.')


def apply_source(source, project, dry_run=False):
    source = Path(source).expanduser().resolve()
    project = Path(project).expanduser().resolve()
    if not source.is_dir():
        return update(source, project, dry_run)
    if not (source / 'project.godot').is_file():
        candidates = [p for p in source.iterdir() if p.is_dir()
                      and (p / 'project.godot').is_file() and not protected(PurePosixPath(p.name))]
        if len(candidates) != 1:
            raise ValueError('Choose the extracted project folder, or a wrapper containing exactly one project.')
        source = candidates[0].resolve()
    if source == project or source in project.parents:
        raise ValueError('Source and destination must be separate project folders.')
    if not PROJECT_NAME.search((source / 'project.godot').read_text(encoding='utf-8-sig')):
        raise ValueError('Source folder is not a Salvage Stack project.')
    # Reuse the same validated, backed-up merge for ZIPs and extracted folders.
    with tempfile.TemporaryDirectory(prefix='salvage-folder-source-') as temporary:
        packed = Path(temporary) / 'source.zip'
        with ZipFile(packed, 'w') as archive:
            for directory, dirs, files in os.walk(source, followlinks=False):
                relative_dir = Path(directory).relative_to(source)
                dirs[:] = sorted(d for d in dirs if not protected(PurePosixPath(relative_dir / d)))
                for name in dirs + sorted(files):
                    path = Path(directory) / name
                    relative = PurePosixPath(path.relative_to(source))
                    if protected(relative):
                        continue
                    if path.is_symlink():
                        raise ValueError('Source folder contains a symlink: ' + str(path))
                    if name in files:
                        if not path.is_file():
                            raise ValueError('Source contains a special file: ' + str(path))
                        archive.write(path, 'salvage-stack/' + str(relative))
        return update(packed, project, dry_run, source_label=source)


def pasted_path(value):
    value = value.strip()
    # Also accept Terminal's quoted/backslash-escaped drag-and-drop paths.
    if Path(value).expanduser().exists():
        return value
    parts = shlex.split(value)
    if len(parts) == 1:
        return parts[0]
    raise ValueError('Provide one ZIP or folder path. Drag it into Terminal or wrap it in quotes.')


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('source', nargs='?', help='Update ZIP or extracted project folder, anywhere on your Mac')
    parser.add_argument('project', nargs='?', default=str(Path(__file__).resolve().parent),
                        help='Destination project; defaults to the folder containing this script')
    parser.add_argument('--dry-run', action='store_true', help='List changes without modifying the project')
    args = parser.parse_args()
    try:
        source = args.source
        if not source:
            print('Destination: ' + args.project)
            source = input('Drag or paste the update ZIP/folder here, then press Enter: ')
            if not source.strip():
                print('Cancelled. No files changed.')
                return 0
        apply_source(pasted_path(source), args.project, args.dry_run)
    except (OSError, ValueError, BadZipFile, RuntimeError, EOFError) as error:
        print('Update failed: ' + str(error), file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print('Cancelled.', file=sys.stderr)
        return 130
    return 0


if __name__ == '__main__':
    sys.exit(main())
