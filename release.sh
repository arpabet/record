#!/usr/bin/env bash
#
# Copyright (c) 2026 Zander Schwid & Co. LLC.
# SPDX-License-Identifier: Apache-2.0
#
# Coordinated release for the go.arpabet.com/record multi-module monorepo.
#
# One shared version moves every module (recordpb, recordbase, recordmod) — a
# proto/interface change in recordpb ripples into the others, so they share a
# version. A module carrying an extra change takes a higher patch within the same
# major via a per-module override:
#
#     ./release.sh v1.1.0 recordbase=v1.1.1
#
# Modules are discovered automatically (every dir with a go.mod) and tagged with
# the multi-module convention "<subdir>/vX.Y.Z" (e.g. recordpb/v1.1.0). Before
# tagging, internal `require go.arpabet.com/record/X` lines are pinned to the
# release version and the local-dev `replace go.arpabet.com/record/X => ../X`
# bootstrap directives are stripped (consumers ignore replaces anyway; this keeps
# published go.mods clean). go.work covers local dev post-release.
#
# Usage: ./release.sh [--dry-run] [--no-push] <version> [module=version ...]
#
#     --dry-run   print the plan + go.mod diff and exit, change nothing
#     --no-push   create the commit and tags locally but do not push
#
# Compatible with the bash 3.2 that ships on macOS (no associative arrays/mapfile).
#
set -euo pipefail

PREFIX="go.arpabet.com/record"
REMOTE="origin"
DRY_RUN=0; NO_PUSH=0
VERSION=""; OVERRIDES=""

die() { echo "error: $*" >&2; exit 1; }
semver_ok() { case "$1" in v[0-9]*.[0-9]*.[0-9]*) return 0;; *) return 1;; esac; }

for a in "$@"; do
	case "$a" in
		--dry-run) DRY_RUN=1 ;;
		--no-push) NO_PUSH=1 ;;
		-h|--help) sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
		*=v*)      OVERRIDES="$OVERRIDES $a" ;;
		v*)        VERSION="$a" ;;
		*)         die "unrecognized arg: $a" ;;
	esac
done
[ -n "$VERSION" ] || die "usage: ./release.sh [--dry-run] [--no-push] <version> [module=version ...]"
semver_ok "$VERSION" || die "'$VERSION' is not vMAJOR.MINOR.PATCH"

# reject 4-component versions up front (Go requires 3-component semver)
case "$VERSION" in v[0-9]*.[0-9]*.[0-9]*.[0-9]*) die "'$VERSION' has four numbers; Go requires vX.Y.Z. Use a higher patch override for the module that changed.";; esac
for tok in $OVERRIDES; do
	v="${tok#*=}"; semver_ok "$v" || die "override '$tok' version is not vMAJOR.MINOR.PATCH"
done

ver_for() {
	local tok
	for tok in $OVERRIDES; do
		case "$tok" in "$1="*) echo "${tok#*=}"; return;; esac
	done
	echo "$VERSION"
}

cd "$(dirname "$0")"
[ -d .git ] || die "must run from the repository root (no .git here)."
[ -f go.work ] || echo "warning: no go.work at repo root."
[ -z "$(git status --porcelain)" ] || die "working tree is dirty; commit or stash first."

branch="$(git rev-parse --abbrev-ref HEAD)"
[ "$branch" = "main" ] || echo "warning: on branch '$branch', not 'main'."

MODULES="$(find . -name go.mod -not -path './.*' | sed 's#/go.mod$##; s#^\./##' | sort)"
[ -n "$MODULES" ] || die "no modules found"

echo "Release plan (shared $VERSION):"
for m in $MODULES; do printf "  %-12s -> %s/%s\n" "$m" "$m" "$(ver_for "$m")"; done
echo

# refuse to clobber existing tags
for m in $MODULES; do
	t="$m/$(ver_for "$m")"
	if git rev-parse -q --verify "refs/tags/$t" >/dev/null 2>&1; then
		die "tag '$t' already exists."
	fi
done

# rewrite go.mod: strip bootstrap replaces, pin internal requires to the release version
for m in $MODULES; do
	gm="$m/go.mod"
	perl -i -ne "print unless m{^replace \Q$PREFIX\E/}" "$gm"
	for dep in $MODULES; do
		dv="$(ver_for "$dep")"
		perl -i -pe "s{(\Q$PREFIX/$dep\E)\s+v\S+}{\$1 $dv}g" "$gm"
	done
done

if [ "$DRY_RUN" -eq 1 ]; then
	echo "--- dry run: go.mod changes below, nothing committed ---"
	git --no-pager diff -- '*go.mod' || true
	git checkout -- . 2>/dev/null || true
	exit 0
fi

git add -A
git commit -m "release $VERSION"

TAGS=""
for m in $MODULES; do t="$m/$(ver_for "$m")"; git tag -a "$t" -m "$t"; TAGS="$TAGS $t"; echo "tagged $t"; done

if [ "$NO_PUSH" -eq 1 ]; then
	echo "--no-push: created commit + tags locally; not pushed."
	echo "  git push $REMOTE $branch && git push $REMOTE$TAGS"
	exit 0
fi
git push "$REMOTE" "$branch"
git push "$REMOTE"$TAGS
echo "released $VERSION"
