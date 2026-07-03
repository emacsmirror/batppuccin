# Screenshot tooling

Regenerates the per-flavor screenshots in [`../screenshots/`](../screenshots)
that the main README links to.

```console
$ tools/generate.sh
```

For each flavor it launches a throwaway `emacs -Q`, loads the theme, renders
[`sample.el`](sample.el) in a fixed-size frame (hidden cursor, line numbers, a
title bar that matches the flavor's brightness), and captures just that window.
The capture is verified against the theme's background color and retried if
another window got in the way, so it is safe to run while you keep using the
machine.

Pass a different sample file as the first argument to show your own code:

```console
$ tools/generate.sh path/to/other.el
```

Environment overrides:

- `EMACS` -- Emacs binary to use (default `emacs`)
- `SHOT_FONT` -- font family (default: the first available of FiraCode Nerd
  Font, Fira Code, JetBrains Mono, Menlo)

## Requirements

- macOS (uses `screencapture` and the `ns-*` title-bar frame parameters)
- [ImageMagick](https://imagemagick.org) (`magick`) for the capture check
