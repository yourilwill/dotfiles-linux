#!/usr/bin/env bash
# fcitx5's Alt-key IME on/off relies on an XWayland X11 key grab that goes
# stale after suspend/resume, leaving fcitx5 running but unresponsive to the
# trigger key until it's restarted (`fcitx5 -r`). Watch logind's
# PrepareForSleep signal and restart fcitx5 right after resume so this
# doesn't need to be done by hand from the tray menu every time.
set -euo pipefail

gdbus monitor --system --dest org.freedesktop.login1 --object-path /org/freedesktop/login1 2>/dev/null |
while read -r line; do
	case "$line" in
	*PrepareForSleep*false*)
		sleep 2
		fcitx5 -r
		;;
	esac
done
