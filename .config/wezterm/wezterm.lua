local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.color_scheme = "Dracula (Gogh)"

config.font = wezterm.font_with_fallback({
	"JetBrainsMono Nerd Font Mono",
	"Noto Sans CJK JP",
})

return config
