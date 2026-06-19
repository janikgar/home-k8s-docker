#!/usr/bin/env bash
set -euo pipefail

for pr in $(gh pr list --json number -q '.[].number' | sort)
do
  gh pr merge $pr -r
done
