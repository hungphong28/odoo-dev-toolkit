#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C GIT_TERMINAL_PROMPT=0

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOL="$HERE/bin/max-workspace"

TMP="$(mktemp -d /tmp/max-toolkit-e2e.XXXXXXXX)"

cleanup() {
    rm -rf -- "$TMP"
}
trap cleanup EXIT

export MAX_DISCOVERY_ROOT="$TMP/scan"
export MAX_WORKSPACE_ROOT="$TMP/workspaces"

mkdir -p "$MAX_DISCOVERY_ROOT"

echo "===== E2E: SETUP TWO PROJECTS ====="

for project in clover quatest3; do
    bare="$TMP/$project.git"
    seed="$TMP/$project-seed"
    runtime="$MAX_DISCOVERY_ROOT/$project-dev/source"

    git init -q --bare -b main "$bare"
    git init -q -b main "$seed"

    git -C "$seed" config user.name "Toolkit Test"
    git -C "$seed" config user.email "test@example.invalid"

    printf '%s\n' "$project" > "$seed/README.md"

    git -C "$seed" add README.md
    git -C "$seed" commit -qm "test: initial $project"
    git -C "$seed" remote add origin "$bare"
    git -C "$seed" push -q origin main

    mkdir -p "$(dirname "$runtime")"
    git clone -q -b main "$bare" "$runtime"

    git -C "$runtime" rev-parse HEAD > "$TMP/$project.sha"
done

echo "===== E2E: DISCOVER ====="

"$TOOL" discover > "$TMP/discovered.txt"

test "$(wc -l < "$TMP/discovered.txt")" -eq 2

grep -Fx "$MAX_DISCOVERY_ROOT/clover-dev/source" \
    "$TMP/discovered.txt" >/dev/null

grep -Fx "$MAX_DISCOVERY_ROOT/quatest3-dev/source" \
    "$TMP/discovered.txt" >/dev/null

echo "DISCOVER_TWO_PROJECTS=PASS"

echo "===== E2E: INIT-ALL ====="

"$TOOL" init-all

for project in clover quatest3; do
    runtime="$MAX_DISCOVERY_ROOT/$project-dev/source"
    local_repo="$MAX_WORKSPACE_ROOT/$project/$project"

    test -d "$local_repo"

    test "$(git -C "$local_repo" rev-parse HEAD)" = \
         "$(cat "$TMP/$project.sha")"

    test -z "$(git -C "$local_repo" branch --show-current)"
    test -z "$(git -C "$local_repo" status --porcelain)"

    test "$(git -C "$runtime" rev-parse HEAD)" = \
         "$(cat "$TMP/$project.sha")"

    test "$(git -C "$runtime" branch --show-current)" = main
    test -z "$(git -C "$runtime" status --porcelain)"
done

echo "INIT_ALL_TWO_PROJECTS=PASS"
echo "RUNTIME_INTEGRITY=PASS"

echo "===== E2E: REPEAT INIT-ALL ====="

"$TOOL" init-all > "$TMP/repeat.txt"

test "$(grep -c '^SKIP: existing LOCAL:' "$TMP/repeat.txt")" -eq 2

echo "INIT_ALL_IDEMPOTENCY=PASS"

echo "===== E2E: TASK NO UPSTREAM ====="

LOCAL="$MAX_WORKSPACE_ROOT/clover/clover"

"$TOOL" task "$LOCAL" task/e2e-no-track

test "$(git -C "$LOCAL" branch --show-current)" = \
     "task/e2e-no-track"

test "$(git -C "$LOCAL" rev-parse HEAD)" = \
     "$(git -C "$LOCAL" rev-parse origin/main)"

if git -C "$LOCAL" rev-parse \
    --abbrev-ref --symbolic-full-name '@{upstream}' \
    >/dev/null 2>&1; then
    echo "FAIL: task unexpectedly tracks another branch"
    exit 1
fi

echo "TASK_NO_UPSTREAM=PASS"

echo "===== E2E: DIRTY WORKTREE BLOCK ====="

printf 'uncommitted\n' > "$LOCAL/uncommitted.txt"

if "$TOOL" task "$LOCAL" task/should-not-exist \
    > "$TMP/blocked.log" 2>&1; then
    echo "FAIL: dirty LOCAL was accepted"
    exit 1
fi

if git -C "$LOCAL" show-ref --verify --quiet \
    refs/heads/task/should-not-exist; then
    echo "FAIL: blocked task was created"
    exit 1
fi

echo "DIRTY_WORKTREE_BLOCK=PASS"

echo "===== E2E: CHECK ====="

"$TOOL" check > "$TMP/check.log"

grep -F "$MAX_WORKSPACE_ROOT/clover/clover" \
    "$TMP/check.log" >/dev/null

grep -F "$MAX_WORKSPACE_ROOT/quatest3/quatest3" \
    "$TMP/check.log" >/dev/null

echo "MULTI_PROJECT_CHECK=PASS"

echo "======================================"
echo "TOOLKIT_MULTIPROJECT_E2E=PASS"
echo "======================================"
