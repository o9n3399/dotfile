#!/usr/bin/env bash
# Print one service directory per line: top-level dirs (and one level under apps/, services/, packages/)
# that hold a build manifest. Prints "." when the repo root itself is the only service.
manifests='package.json pom.xml build.gradle build.gradle.kts go.mod pyproject.toml Cargo.toml composer.json'
is_service() { for m in $manifests; do [ -f "$1/$m" ] && return 0; done; return 1; }

found=0
for d in */ apps/*/ services/*/ packages/*/; do
  d=${d%/}
  [ -d "$d" ] || continue
  case "$d" in node_modules|vendor|dist|build|target|.*) continue ;; esac
  is_service "$d" && { echo "$d"; found=1; }
done
[ "$found" = 0 ] && is_service . && echo "."
exit 0
