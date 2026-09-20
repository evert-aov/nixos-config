-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ◈ MODULAR CONFIGURATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- define submap passthru
hl.define_submap("passthru", function()
  hl.bind("SUPER + Escape", hl.dsp.submap("reset"))
end)

-- --------------

require("config.monitors")
require("config.env")
require("config.autostart")
require("config.variables")
require("config.settings")
require("config.rules")
require("config.keybindings")
