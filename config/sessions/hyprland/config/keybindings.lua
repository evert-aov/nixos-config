-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  ◈ KEYBINDINGS & GESTURES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local var = require("config.variables")

-- ───────── Mouse & Gestures ─────────
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.bind(var.mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(var.mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ───────── Window Management ─────────
hl.bind(var.mainMod .. " + SHIFT + left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind(var.mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })
hl.bind(var.mainMod .. " + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(var.mainMod .. " + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })


hl.bind(var.mainMod .. " + CTRL + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(var.mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(var.mainMod .. " + CTRL + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(var.mainMod .. " + CTRL + down", hl.dsp.window.move({ direction = "down" }))


hl.bind(var.mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(var.mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(var.mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(var.mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

hl.bind(var.mainMod .. " + Q", hl.dsp.window.kill())
hl.bind("ALT + F4", hl.dsp.window.kill())
hl.bind(var.mainMod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(var.mainMod .. " + F11", hl.dsp.window.fullscreen())

-- ───────── System & Hardware ─────────
hl.bind("Caps_Lock", hl.dsp.exec_cmd("sleep 0.1 && swayosd-client --caps-lock"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness raise"), { locked = true })

hl.bind("Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh"), { locked = true })
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh --edit"), { locked = true })
hl.bind(var.mainMod .. " + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh --full"), { locked = true })
hl.bind(var.mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh --full --edit"),
  { locked = true })

hl.bind("XF86PowerOff", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/lock.sh"), { locked = true })
hl.bind(var.mainMod .. " + L", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/lock.sh"),
  { repeating = true, locked = true })

-- ───────── Media & Audio ─────────
hl.bind(var.mainMod .. " + SPACE", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("xf86AudioMicMute", hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"), { locked = true })
hl.bind("xf86audiomute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })

hl.bind("xf86audiolowervolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"),
  { repeating = true, locked = true })
hl.bind("xf86audioraisevolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"),
  { repeating = true, locked = true })

-- ───────── Applications & Launchers ─────────
hl.bind(var.mainMod .. " + B", hl.dsp.exec_cmd("vivaldi"))
hl.bind(var.mainMod .. " + E", hl.dsp.exec_cmd("kitty yazi"))
-- hl.bind(var.mainMod .. " + T", hl.dsp.exec_cmd("kitty"))
hl.bind(var.mainMod .. " + I", hl.dsp.exec_cmd("bash $HOME/.local/share/JetBrains/Toolbox/scripts/idea"))
hl.bind(var.mainMod .. " + D", hl.dsp.exec_cmd("bash $HOME/.local/share/JetBrains/Toolbox/scripts/datagrip"))
hl.bind(var.mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("bash $HOME/.local/share/JetBrains/Toolbox/scripts/pycharm"))
hl.bind(var.mainMod .. " + O", hl.dsp.exec_cmd("onlyoffice-desktopeditors"))
hl.bind(var.mainMod .. " + RETURN", hl.dsp.exec_cmd(var.terminal))
hl.bind(var.mainMod .. " + A", hl.dsp.exec_cmd("~/.config/hypr/scripts/qs_manager.sh toggle applauncher"))
hl.bind(var.mainMod .. "+ C", hl.dsp.exec_cmd("code"))
hl.bind(var.mainMod .. "+ T", hl.dsp.exec_cmd("TRILIUM_PORT=8080 nix run"))

-- ───────── Quickshell Controls ─────────
hl.bind(var.mainMod .. " + M", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle monitors"))
hl.bind(var.mainMod .. " + R", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/reload.sh"))
hl.bind(var.mainMod .. " + SHIFT  + C", hl.dsp.exec_cmd("~/.config/hypr/scripts/qs_manager.sh toggle clipboard"))
hl.bind(var.mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle settings"))
hl.bind(var.mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle music"))
hl.bind(var.mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle battery"))
hl.bind(var.mainMod .. " + W", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle wallpaper"))
hl.bind(var.mainMod .. " + S", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle calendar"))
hl.bind(var.mainMod .. " + N", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle network"))
hl.bind(var.mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle focustime"))
hl.bind(var.mainMod .. " + V", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle volume"))
hl.bind(var.mainMod .. " + H", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle guide"))

-- ───────── Workspaces (Optimizado con Bucle) ─────────
-- Mapea del 1 al 9, y luego el 0 como el espacio 10
for i = 0, 9 do
  local key = tostring(i)
  local ws_num = (i == 0) and 10 or i

  -- Atajo para cambiar al espacio de trabajo
  hl.bind(var.mainMod .. " + " .. key, hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh " .. ws_num))

  -- Atajo para mover la ventana al espacio de trabajo
  hl.bind(var.mainMod .. " + SHIFT + " .. key,
    hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh " .. ws_num .. " move"))
end
