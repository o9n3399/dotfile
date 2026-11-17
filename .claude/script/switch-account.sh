#!/usr/bin/env bash
set -euo pipefail

claude_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
store="$claude_dir/account"
cred="$claude_dir/.credentials.json"
cfg="$HOME/.claude.json"
current_file="$store/current"
usage_url="https://api.anthropic.com/api/oauth/usage"
token_url="${CLAUDE_OAUTH_TOKEN_URL:-https://platform.claude.com/v1/oauth/token}"
client_id="9d1c250a-e61b-44d9-88ed-5944d1962f5e"

umask 077

usage() {
  cat <<EOF
Switch Claude Code between saved accounts without logging in again.
Accounts are named by their email.

Usage:
  switch-account.sh -w, --switch [email]
                                    switch to an account, or to the next saved one
                                    with a working login when no email is given;
                                    any unique part of the email works, e.g. "viet" or "vti"
  switch-account.sh [email]         same as --switch
  switch-account.sh -S, --save      save the currently logged-in account
  switch-account.sh -s, --status    list saved accounts with their plan usage,
                                    * marks the active one
  switch-account.sh -h, --help      show this help

First-time setup:
  1. Log in with account 1, then:  switch-account.sh --save
  2. /login with account 2, then:  switch-account.sh --save

Notes:
  - Quit all running claude sessions before switching, then resume with: claude -c
  - Only the Claude login (claudeAiOauth) is swapped; MCP OAuth tokens stay shared.
  - Never copy saved accounts to another machine: each machine needs its own /login,
    a shared refresh token gets invalidated as soon as one machine refreshes it.
  - Switching to an account whose access token expired refreshes it first; a revoked
    login is skipped (or refused when named) and must be redone with /login + --save.
  - Usage is shown only while an account's access token is still valid (~8h after
    last use); --status never refreshes tokens.
  - Saved accounts live in $store/
EOF
}

die() { echo "error: $*" >&2; exit 1; }
warn() { echo "warning: $*" >&2; }

list_accounts() {
  find "$store" -maxdepth 1 -name '*.credentials.json' -printf '%f\n' \
    | sed 's/\.credentials\.json$//' | sort
}

current() { [[ -f $current_file ]] && cat "$current_file" || true; }

# Claude Code blanks the tokens after a failed refresh; such a login must never be saved.
active_is_valid() { jq -e '(.claudeAiOauth.refreshToken // "") != ""' "$cred" > /dev/null 2>&1; }
saved_is_valid() { jq -e '(.refreshToken // "") != ""' "$store/$1.credentials.json" > /dev/null 2>&1; }
saved_is_fresh() {
  jq -e --argjson now "$(date +%s)" '(.expiresAt // 0) / 1000 > $now + 60' \
    "$store/$1.credentials.json" > /dev/null 2>&1
}

# A saved refresh token can be revoked server-side (rotated by another session or machine),
# which no local field shows, so an expired login is proven by refreshing it.
# Refreshing rotates the token, so the new pair is written back immediately.
# Returns 0 usable, 1 dead (refresh token rejected), 2 could not verify.
ensure_live() {
  local file="$store/$1.credentials.json" body code tmp
  saved_is_valid "$1" || return 1
  saved_is_fresh "$1" && return 0
  body=$(mktemp "$store/.refresh.XXXXXX")
  # The request goes through stdin so the refresh token never shows up in the process list.
  code=$(jq -c --arg cid "$client_id" '
      {grant_type: "refresh_token", refresh_token: .refreshToken, client_id: $cid}
      + (if (.scopes | type) == "array" and (.scopes | length) > 0
         then {scope: (.scopes | join(" "))} else {} end)' "$file" \
    | curl -s --max-time 30 -o "$body" -w '%{http_code}' \
        -H 'Content-Type: application/json' --data-binary @- "$token_url") || code=000
  if [[ $code == 200 ]] && jq -e '(.access_token // "") != "" and (.expires_in | type) == "number"' "$body" > /dev/null 2>&1; then
    tmp=$(mktemp "$file.XXXXXX")
    jq --slurpfile r "$body" --argjson now "$(date +%s%3N)" '
      $r[0] as $r
      | .accessToken = $r.access_token
      | .refreshToken = ($r.refresh_token // .refreshToken)
      | .expiresAt = ($now + $r.expires_in * 1000)
      | if ($r.refresh_token_expires_in | type) == "number"
        then .refreshTokenExpiresAt = ($now + $r.refresh_token_expires_in * 1000) else . end' \
      "$file" > "$tmp"
    mv "$tmp" "$file"
    rm -f "$body"
    return 0
  fi
  if [[ $code == 400 || $code == 401 ]] && jq -e '.error == "invalid_grant"' "$body" > /dev/null 2>&1; then
    tmp=$(mktemp "$file.XXXXXX")
    jq '.accessToken = "" | .refreshToken = ""' "$file" > "$tmp"
    mv "$tmp" "$file"
    rm -f "$body"
    return 1
  fi
  rm -f "$body"
  return 2
}

active_uuid() { jq -r '.oauthAccount.accountUuid // empty' "$cfg" 2>/dev/null || true; }
active_email() { jq -r '.oauthAccount.emailAddress // empty' "$cfg" 2>/dev/null || true; }

accounts_with_uuid() {
  local uuid=$1 a
  [[ -n $uuid ]] || return 0
  for a in $(list_accounts); do
    if [[ $(jq -r '.accountUuid // empty' "$store/$a.profile.json" 2>/dev/null) == "$uuid" ]]; then
      echo "$a"
    fi
  done
}

# The `current` marker goes stale after a /login or a write from another claude session,
# so the active login is resolved by its accountUuid; the marker is only a fallback.
resolve_active() {
  local uuid owners
  active_name=$(current)
  active_is_valid || return 0
  uuid=$(active_uuid)
  [[ -n $uuid ]] || return 0
  mapfile -t owners < <(accounts_with_uuid "$uuid")
  case ${#owners[@]} in
    0) die "active login ($(active_email)) is not saved, run --save first so it is not lost" ;;
    1) active_name=${owners[0]} ;;
    *) die "'${owners[*]}' hold the same login ($(active_email)), run --save to merge them" ;;
  esac
}

# Saves the active login under its email and drops any other entry of the same account,
# e.g. one saved under a different name by an older version of this script.
save() {
  local name uuid other
  active_is_valid || die "no valid Claude login in $cred, run /login first"
  name=$(active_email)
  [[ -n $name ]] || die "no email in $cfg, start claude once after /login"
  uuid=$(active_uuid)
  for other in $(accounts_with_uuid "$uuid"); do
    if [[ $other != "$name" ]]; then
      rm -f "$store/$other.credentials.json" "$store/$other.profile.json"
      warn "removed '$other': same login as $name"
    fi
  done
  jq '.claudeAiOauth' "$cred" > "$store/$name.credentials.json"
  jq '.oauthAccount' "$cfg" > "$store/$name.profile.json"
  echo "$name" > "$current_file"
  saved_name=$name
}

load() {
  local name=$1 tmp
  tmp=$(mktemp "$cred.XXXXXX")
  jq --slurpfile o "$store/$name.credentials.json" '.claudeAiOauth = $o[0]' "$cred" > "$tmp"
  mv "$tmp" "$cred"
  if [[ -f $store/$name.profile.json ]]; then
    tmp=$(mktemp "$cfg.XXXXXX")
    jq --slurpfile p "$store/$name.profile.json" '.oauthAccount = $p[0]' "$cfg" > "$tmp"
    mv "$tmp" "$cfg"
  fi
  echo "$name" > "$current_file"
}

match_account() {
  local query=$1 a matches=()
  for a in "${accounts[@]}"; do
    [[ $a == "$query" ]] && { echo "$a"; return; }
    [[ $a == *"$query"* ]] && matches+=("$a")
  done
  case ${#matches[@]} in
    0) die "no saved account matches '$query'" ;;
    1) echo "${matches[0]}" ;;
    *) die "'$query' matches several accounts: ${matches[*]}" ;;
  esac
}

print_usage() {
  local oauth=$1 now token body
  now=$(date +%s)
  if ! jq -e '(.refreshToken // "") != ""' <<< "$oauth" > /dev/null; then
    echo "    login invalid, run /login then --save"
    return
  fi
  if ! jq -e --argjson now "$now" '(.expiresAt // 0) / 1000 > $now + 60' <<< "$oauth" > /dev/null; then
    echo "    token expired, switch to this account to view usage"
    return
  fi
  token=$(jq -r '.accessToken' <<< "$oauth")
  # Headers are read from a file descriptor so the token never shows up in the process list.
  if ! body=$(curl -sf --max-time 10 \
      -H @<(printf 'Authorization: Bearer %s\nanthropic-beta: oauth-2025-04-20\n' "$token") \
      "$usage_url"); then
    echo "    usage unavailable"
    return
  fi
  jq -r '
    def reset: try (sub("\\.[0-9]+"; "") | sub("[+-]00:00$"; "Z") | fromdateiso8601
                    | strflocaltime("%m-%d %H:%M")) catch .;
    to_entries[]
    | select((.value | type) == "object" and (.value.utilization != null))
    | "    \(.key): \(.value.utilization | floor)%"
      + (if .value.resets_at then " (reset \(.value.resets_at | reset))" else "" end)
  ' <<< "$body"
}

status() {
  local cur email oauth uuid owners
  cur=$(current)
  if active_is_valid; then
    uuid=$(active_uuid)
    mapfile -t owners < <(accounts_with_uuid "$uuid")
    (( ${#owners[@]} == 1 )) && cur=${owners[0]}
  fi
  for a in $(list_accounts); do
    email=$(jq -r '.emailAddress // "?"' "$store/$a.profile.json" 2>/dev/null || echo "?")
    [[ $email == "$a" ]] && label=$a || label="$a ($email)"
    if [[ $a == "$cur" ]]; then
      echo "* $label"
      oauth=$(jq -c '.claudeAiOauth // {}' "$cred")
    else
      echo "  $label"
      oauth=$(jq -c '.' "$store/$a.credentials.json")
    fi
    print_usage "$oauth"
  done
}

switch_to() {
  local query=${1:-} target="" marker cur n start i candidate
  marker=$(current)
  resolve_active
  cur=$active_name
  [[ -n $cur ]] || die "no active account recorded, run: switch-account.sh --save"
  [[ $cur == "$marker" ]] || warn "active login is '$cur', not '$marker' as last recorded"
  mapfile -t accounts < <(list_accounts)
  (( ${#accounts[@]} >= 2 )) || die "need at least 2 saved accounts"

  if [[ -n $query ]]; then
    target=$(match_account "$query")
  else
    n=${#accounts[@]}
    start=0
    for i in "${!accounts[@]}"; do
      [[ ${accounts[$i]} == "$cur" ]] && start=$i
    done
    for (( i = 1; i < n; i++ )); do
      candidate=${accounts[$(( (start + i) % n ))]}
      ensure_live "$candidate" && { target=$candidate; break; }
      case $? in
        1) warn "skipping '$candidate': login revoked, /login with it and run --save" ;;
        *) warn "skipping '$candidate': could not refresh its token (network?)" ;;
      esac
    done
    [[ -n $target ]] || die "no other account has a working login, /login and run --save"
  fi
  [[ $target != "$cur" ]] || { echo "Already on '$cur'"; exit 0; }
  if [[ -n $query ]]; then
    ensure_live "$target" || case $? in
      1) die "account '$target' login is revoked, /login with it and run --save" ;;
      *) die "could not refresh the token of '$target' (network?), try again" ;;
    esac
  fi

  # Persist the current account first: its refresh token may have rotated since the last save.
  if active_is_valid; then
    save
    cur=$saved_name
  else
    warn "active login for '$cur' is invalid, keeping its previously saved copy"
  fi
  load "$target"
  echo "Switched: $cur -> $target"
  echo "Restart claude, then run: claude -c"
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

mkdir -p "$store"

case "${1:-}" in
  -S|--save)
    [[ -z ${2:-} ]] || die "--save takes no name, accounts are named by their email"
    save
    echo "Saved current login as '$saved_name'"
    ;;
  -s|--status) status ;;
  -w|--switch)
    [[ -z ${3:-} ]] || die "--switch takes at most one email"
    switch_to "${2:-}"
    ;;
  -*) echo "error: unknown option '$1'" >&2; usage >&2; exit 1 ;;
  *) switch_to "${1:-}" ;;
esac
