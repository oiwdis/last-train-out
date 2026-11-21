#!/usr/bin/env bash
# An archived PCK must contain the project's resources at its own build revision.
set -euo pipefail
app=$1
receipt=$2
revision=$(jq -er .bundle_commit "$receipt")
[[ $(/usr/libexec/PlistBuddy -c 'Print :LTOBuildCommit' "$app/Contents/Info.plist") == "$revision" ]]
if ! git cat-file -e "$revision^{commit}" 2>/dev/null; then
  git fetch --no-tags --depth=1 origin "$revision"
fi
source_dir=$(mktemp -d)
trap 'git worktree remove --force "$source_dir"' EXIT
git worktree add --quiet --detach "$source_dir" "$revision"
python3 "$source_dir/tools/macos/verify_app.py" "$app" --expect-signature adhoc
