#!/usr/bin/env bash
# Print the exact run's unexpired standalone game ZIP ID, when it is still retained.
set -eu
run="${1:?supply a GitHub Actions run ID}"
case "$run" in *[!0-9]*) exit 2 ;; esac
gh api --paginate "repos/${GITHUB_REPOSITORY:?}/actions/artifacts?name=LastTrainOut-macos-universal.zip&per_page=100" \
  --jq ".artifacts[] | select(.workflow_run.id == $run and .expired == false) | .id"
