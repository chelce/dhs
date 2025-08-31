#!/usr/bin/env bash
set -euo pipefail

# Files to sync (whitelist)
SYNC_FILES=("class-calendar.html")
TARGET_REPO="${DHS_REPO:-chelce/dhs}"
TARGET_BRANCH="main"
WORKDIR="$(pwd)"
TMP_DIR="/tmp/dhs-repo"

echo "Sync target: $TARGET_REPO ($TARGET_BRANCH)"

echo "Cloning target repo..."
rm -rf "$TMP_DIR"
 git clone --depth 1 "https://x-access-token:${DHS_PAT}@github.com/${TARGET_REPO}.git" "$TMP_DIR"
cd "$TMP_DIR"

CHANGED=0
for f in "${SYNC_FILES[@]}"; do
  if [ -f "${WORKDIR}/${f}" ]; then
    echo "Copying $f"
    cp -f "${WORKDIR}/${f}" "${TMP_DIR}/${f}"
    if ! git diff --quiet -- "${f}"; then
      echo "Detected change in ${f}"
      git add "${f}"
      CHANGED=1
    fi
  else
    echo "Warning: source file ${f} missing in SCHOOL repo" >&2
  fi
done

if [ "$CHANGED" -eq 1 ]; then
  COMMIT_MSG="Sync calendar assets from SCHOOL: ${GITHUB_SHA:0:7}"
  git config user.email "actions@users.noreply.github.com"
  git config user.name "calendar-sync-bot"
  git commit -m "$COMMIT_MSG"
  echo "Pushing changes..."
  git push origin "$TARGET_BRANCH"
  echo "Sync complete."
else
  echo "No calendar asset changes to sync."
fi
