local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.color_scheme = "Catppuccin Mocha"

config.window_background_opacity = 0.8

config.audible_bell = "Disabled"

config.enable_kitty_graphics = true

local function adjust_opacity(window, delta)
	local overrides = window:get_config_overrides() or {}
	local current = overrides.window_background_opacity or config.window_background_opacity
	local new_opacity = current + delta
	if new_opacity > 1.0 then
		new_opacity = 1.0
	elseif new_opacity < 0.0 then
		new_opacity = 0.0
	end
	overrides.window_background_opacity = new_opacity
	window:set_config_overrides(overrides)
end

local function set_opacity(window, opacity)
	local overrides = window:get_config_overrides() or {}
	overrides.window_background_opacity = opacity
	window:set_config_overrides(overrides)
end

config.keys = {
	{
		key = "=",
		mods = "CTRL|ALT",
		action = wezterm.action_callback(function(window, _pane)
			adjust_opacity(window, 0.05)
		end),
	},
	{
		key = "-",
		mods = "CTRL|ALT",
		action = wezterm.action_callback(function(window, _pane)
			adjust_opacity(window, -0.05)
		end),
	},
	{
		key = "0",
		mods = "CTRL|ALT",
		action = wezterm.action_callback(function(window, _pane)
			set_opacity(window, 1.0)
		end),
	},
}

config.font = wezterm.font_with_fallback({
	"JetBrainsMono Nerd Font Mono",
	"Noto Sans CJK JP",
})
config.font_size = 11.0

return config
