#!/usr/bin/env bash
# Prints detected verification commands for the project in the current directory.
# Output format: "<stage>: <command>" per line.

set -u

pm="npm"
[ -f pnpm-lock.yaml ] && pm="pnpm"
[ -f yarn.lock ] && pm="yarn"
[ -f bun.lockb ] || [ -f bun.lock ] && pm="bun"

found=0
emit() { echo "$1: $2"; found=1; }

if [ -f package.json ] && command -v node >/dev/null 2>&1; then
  scripts=$(node -e 'const s=require("./package.json").scripts||{};console.log(Object.keys(s).join(" "))' 2>/dev/null)
  lint_fixes=$(node -e 'console.log(/--fix\b/.test((require("./package.json").scripts||{}).lint||"")?1:0)' 2>/dev/null)
  for s in lint typecheck type-check tsc test test:unit test:e2e; do
    case " $scripts " in
      *" $s "*)
        case "$s" in
          lint)
            if [ "$lint_fixes" = 1 ]; then
              emit lint "npx eslint <changed .ts/.js files>  (lint script has --fix: never run it)"
            else
              emit lint "$pm run lint"
            fi ;;
          typecheck|type-check|tsc) emit typecheck "$pm run $s" ;;
          *) emit test "CI=true $pm run $s" ;;
        esac ;;
    esac
  done
  if [ -f tsconfig.json ] && ! echo " $scripts " | grep -qE ' (typecheck|type-check|tsc) '; then
    emit typecheck "npx tsc --noEmit"
  fi
fi

if [ -f pyproject.toml ] || [ -f setup.py ] || [ -f requirements.txt ]; then
  command -v ruff >/dev/null 2>&1 && emit lint "ruff check ."
  command -v mypy >/dev/null 2>&1 && emit typecheck "mypy ."
  emit test "pytest -q"
fi

if [ -f go.mod ]; then
  emit lint "go vet ./..."
  emit test "go test ./..."
fi

if [ -f Cargo.toml ]; then
  emit lint "cargo clippy --all-targets"
  emit test "cargo test"
fi

if [ -f pom.xml ]; then
  emit test "mvn -q test"
elif [ -f gradlew ]; then
  emit test "./gradlew test"
fi

if [ -f Makefile ]; then
  for t in lint test check; do
    grep -qE "^$t:" Makefile && emit make "make $t"
  done
fi

if [ "$found" -eq 1 ] && command -v docker >/dev/null 2>&1; then
  for c in $(docker ps --format '{{.Names}}' 2>/dev/null); do
    dest=$(docker inspect --format '{{range .Mounts}}{{if eq .Source "'"$PWD"'"}}{{.Destination}}{{end}}{{end}}' "$c" 2>/dev/null)
    if [ -n "$dest" ]; then
      echo "container: $c (repo mounted at $dest; run every command as: docker exec -u $(id -u):$(id -g) -w $dest $c <cmd>)"
      break
    fi
  done
fi

[ "$found" -eq 0 ] && echo "NO_TESTS_DETECTED"
exit 0
