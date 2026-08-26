-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  ◈ AUTOSTART
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
hl.on("hyprland.start", function()
  -- Matar procesos residuales de Wine de sesiones anteriores (evita que ArcMap reaparezca)
  hl.exec_cmd("wineserver -k")

  -- Daemons y herramientas de portapapeles/multimedia
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("hypridle")
  hl.exec_cmd("playerctld")
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")

  -- Servicios de usuario y scripts locales de escucha
  hl.exec_cmd("systemctl --user enable --now easyeffects")
  hl.exec_cmd("~/.config/hypr/scripts/settings_watcher.sh")
  hl.exec_cmd("~/.config/hypr/scripts/volume_listener.sh")

  -- Configuración de apariencia de GNOME / GTK (Cursores)
  hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'ArcMidnight-Cursors'")
  hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 24")

  -- Interfaces y daemons personalizados
  hl.exec_cmd("quickshell -p ~/.config/hypr/scripts/quickshell/Shell.qml")
  hl.exec_cmd("python3 ~/.config/hypr/scripts/quickshell/focustime/focus_daemon.py")
end)
