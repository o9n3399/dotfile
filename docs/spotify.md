# Spotify + Spicetify

Not tracked in this repo — this is a reference note for a machine-level setup living at `~/.config/spicetify` and `~/.config/hypr/custom.lua`. Environment: Arch Linux, Hyprland (ML4W dotfiles).

## Install

```sh
yay -S spotify spicetify-cli
```

## Grant Spicetify write access to the client

The AUR `spotify` package installs to `/opt/spotify`, owned by root. Spicetify needs to patch files there:

```sh
sudo chmod -R a+wr /opt/spotify
```

## Initialize + apply base patch

Spotify must be launched at least once (creates `~/.config/spotify/prefs`) before Spicetify can back it up:

```sh
spotify        # launch, let it load, then fully quit
spicetify backup apply
```

## Theme

Using the `text` theme with the `Monochrome` color scheme, sourced from [43PR/dotfiles](https://github.com/43PR/dotfiles) (`.config/spicetify/Themes/text/`) — it's what produces the ASCII-art-style playlist covers and black/white UI.

Files placed at `~/.config/spicetify/Themes/text/{color.ini,user.css}` (pulled via `raw.githubusercontent.com`, git clone of the full repo timed out).

```sh
spicetify config current_theme text
spicetify config color_scheme Monochrome
spicetify apply
```

**Gotcha:** a currently-running Spotify instance keeps the old UI bundle loaded in memory. After every `spicetify apply`, fully kill and relaunch:

```sh
pkill -9 -x spotify
```

## Not yet done

- Spicetify Marketplace custom app (referenced in the 43PR dotfiles as `custom_apps = marketplace`, lets you browse/install themes from inside Spotify) — not installed here.

## Hyprland window transparency

This machine runs Hyprland's native Lua config (ML4W dotfiles, `hyprctl version` reports `0.56.2`), not a classic `hyprland.conf`. That means the old `hyprctl keyword windowrulev2 "opacity ...,class:^(spotify)$"` syntax is rejected (`keyword can't work with non-legacy parsers`). Use `hyprctl eval` to test a rule live before persisting it:

```sh
hyprctl eval 'hl.window_rule({name="spotify-opacity-test", match={class="Spotify"}, opacity="0.85 0.80"})'
```

The `opacity` field takes a **string** (`"active inactive"`), not a table — `opacity={0.85,0.80}` errors with `field 'opacity': string type requires a string`.

Spotify's window class under XWayland is `Spotify` (capitalized) — check with `hyprctl clients -j | jq '.[].class'`.

Once confirmed visually, persisted to `~/.config/hypr/custom.lua` (ML4W's user-override file, loaded last, survives dotfiles updates):

```lua
hl.window_rule({
	name = "spotify-opacity",
	match = { class = "Spotify" },
	opacity = "0.85 0.80",
})
```

Note: this machine's `custom.lua` also globally disables blur (`decoration.blur.size = 0, passes = 0`), so the effect is plain transparency, not the blurred/frosted look — blur would need to be re-enabled (globally or scoped to this window rule) to get closer to that.
