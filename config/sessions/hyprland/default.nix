{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hypridle.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    extraConfig = ''
      dofile(os.getenv("HOME") .. "/.config/hypr/config/hyprland.lua")
    '';
  };

  home.packages = with pkgs; [
    rofi
    pavucontrol
    fortune
    wl-screenrec
    alsa-utils
    awww
    networkmanager_dmenu
    wl-clipboard
    fd
    qt6.qtmultimedia
    qt6.qt5compat
    qt6.qtwebsockets
    qt6.qtwebengine
    ripgrep
    gtk3
    cava
    cliphist
    tree
    jq
    socat
    pamixer
    brightnessctl
    acpi
    iw
    bluez
    libnotify
    networkmanager
    lm_sensors
    bc
    pulseaudio
    ladspaPlugins
    ladspa-sdk
    imagemagick
  ];

  home.sessionVariables.NIXOS_OZONE_WL = "1";

  home.file.".config/hypr/scripts".source = ./scripts;
  home.activation.copyHyprConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.rsync}/bin/rsync -a --no-owner --no-group ${./config}/ $HOME/.config/hypr/config/
    chmod -R u+w $HOME/.config/hypr/config
  '';
  home.activation.copyHyprTemplates = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.rsync}/bin/rsync -a --no-owner --no-group ${./templates}/ $HOME/.config/hypr/templates/
    chmod -R u+w $HOME/.config/hypr/templates
  '';
}
