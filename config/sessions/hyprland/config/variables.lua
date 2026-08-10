-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  ◈ CORE VARIABLES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Native Lua Custom Variables
local M = {
  mainMod = "SUPER",
  terminal = "kitty",
  active_border = "rgba(cba6f7ff)",
  inactive_border = "rgba(585b70ff)"
}

-- Global apareance Settings (Borders)
hl.config({
  general = {
    ["col.active_border"] = M.active_border,
    ["col.inactive_border"] = M.inactive_border,
  }
})

return M
