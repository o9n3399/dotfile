#!/usr/bin/env bash
# Status line: dir, git branch (dirty/ahead/behind), model, context used %, session cost.
input=$(cat)
IFS=$'\t' read -r dir model remaining cost < <(printf '%s' "$input" | jq -r '[
  (.workspace.current_dir // .cwd),
  .model.display_name,
  (.context_window.remaining_percentage // ""),
  (.cost.total_cost_usd // "")
] | map(tostring) | map(if . == "" then "-" else . end) | join("\t")')
short=${dir/#$HOME/\~}

git_info=''
if branch=$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null); then
  dirty=''
  { git -C "$dir" diff --quiet --ignore-submodules HEAD && git -C "$dir" diff --cached --quiet; } 2>/dev/null || dirty='*'
  ab=''
  if counts=$(git -C "$dir" rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null); then
    read -r behind ahead <<<"$counts"
    [ "$behind" -gt 0 ] && ab="${ab}⇣"
    [ "$ahead" -gt 0 ] && ab="${ab}⇡"
  fi
  git_info=$(printf ' \033[90m %s%s \033[36m%s\033[0m' "$branch" "$dirty" "$ab")
fi

ctx=''
if [ "$remaining" != "-" ]; then
  used=$(( 100 - ${remaining%.*} ))
  color=32
  [ "$used" -ge 70 ] && color=33
  [ "$used" -ge 85 ] && color=31
  ctx=$(printf ' \033[%sm%s%%\033[0m' "$color" "$used")
fi

cost_info=''
[ "$cost" != "-" ] && cost_info=$(printf ' \033[90m$%.2f\033[0m' "$cost")

printf '\033[34m%s\033[0m%s \033[35m%s\033[0m%s%s' "$short" "$git_info" "$model" "$ctx" "$cost_info"
