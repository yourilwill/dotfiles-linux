#!/usr/bin/env bash
# fcitx5's Alt-key IME on/off relies on an XWayland X11 key grab that goes
# stale after suspend/resume, leaving fcitx5 running but unresponsive to the
# trigger key until it's restarted. Watch logind's PrepareForSleep signal and
# restart fcitx5 right after resume so this doesn't need to be done by hand
# from the tray menu every time.
set -euo pipefail

gdbus monitor --system --dest org.freedesktop.login1 --object-path /org/freedesktop/login1 2>/dev/null |
while read -r line; do
	case "$line" in
	*PrepareForSleep*false*)
		sleep 2
		# Resolve fresh each time instead of relying on the environment this
		# service inherited at activation: the systemd --user manager's
		# DISPLAY/XAUTHORITY snapshot can go stale, and the XWayland auth
		# cookie file's random suffix can change across resumes, which is
		# what caused "Authorization required" and a silently broken X11
		# key grab even though fcitx5 itself appeared to restart fine.
		export DISPLAY=:0
		export XAUTHORITY="$(ls -t /run/user/"$(id -u)"/.mutter-Xwaylandauth.* 2>/dev/null | head -1)"
		# `fcitx5 -r` asks the *running* process to re-exec itself over
		# D-Bus, so it re-execs with its own original environment, not the
		# fresh DISPLAY/XAUTHORITY exported above -- the new process kept
		# hitting the same stale-auth error. Kill it and launch a brand new
		# process with the current environment instead.
		pkill -u "$(id -u)" -x fcitx5 || true
		sleep 1
		setsid fcitx5 -d >/dev/null 2>&1 &
		disown
		;;
	esac
done
