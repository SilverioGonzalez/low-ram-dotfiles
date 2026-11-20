-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

hl.on("hyprland.start", function()
	-- 1. Standard graphical environment utilities
	hl.exec_cmd("waybar")
	hl.exec_cmd("systemctl --user start hyprpolkitagent")
	hl.exec_cmd('bash -c "sleep 1 && hyprpaper"')
	hl.exec_cmd('bash -c "sleep 1 && hypridle"')
	-- 2. Clipboard tracking daemons
	hl.exec_cmd('bash -c "wl-paste --type text --watch cliphist store"')
	hl.exec_cmd('bash -c "wl-paste --type image --watch cliphist store"')
  hl.exec_cmd(launcher .. " -d")
end)
