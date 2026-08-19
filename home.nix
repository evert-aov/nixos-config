{ config
, pkgs
, lib
, ...
}:

let
  # 1. Define the path to your programs directory
  programsDir = ./config/programs;

  # 2. Get the content of the directory
  files = builtins.readDir programsDir;

  # 3. Filter for directories only (ignoring regular files like .DS_Store or READMEs)
  directories = builtins.filter (name: files.${name} == "directory") (builtins.attrNames files);

  # 4. Map the directory names to import paths
  programImports = map (name: programsDir + "/${name}") directories;

  # --- Dynamic Scripts Deployment ---
  scriptsDir = ./scripts;
  scriptFiles = if builtins.pathExists scriptsDir then builtins.readDir scriptsDir else { };
  scriptFileNames = builtins.filter (name: scriptFiles.${name} == "regular") (
    builtins.attrNames scriptFiles
  );
  scriptHomeFiles = builtins.listToAttrs (
    map
      (name: {
        name = ".local/bin/${lib.removeSuffix ".sh" (lib.removeSuffix ".py" name)}";
        value = {
          source = scriptsDir + "/${name}";
          executable = true;
        };
      })
      scriptFileNames
  );
in
{
  imports = [
    # sessions
    ./config/sessions/hyprland/default.nix
  ]
  ++ programImports;

  home.username = "evert";
  home.homeDirectory = "/home/evert";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    adwaita-icon-theme
    adw-gtk3
    libsForQt5.qt5ct
    qt6Packages.qt6ct
    libsForQt5.qtstyleplugin-kvantum
    kdePackages.qtstyleplugin-kvantum
    glow # preview de markdown en la terminal (yazi)
    (pkgs.appimageTools.wrapType2 rec {
      pname = "cisco-packet-tracer";
      version = "9.0.1";
      src = pkgs.stdenvNoCC.mkDerivation {
        pname = "cisco-packet-tracer-appimage";
        version = "9.0.1";
        src = /home/evert/Downloads/CiscoPacketTracer_901_Ubuntu_64bit.deb;
        nativeBuildInputs = [ pkgs.dpkg ];
        installPhase = ''
          runHook preInstall
          cp opt/pt/packettracer.AppImage $out
          runHook postInstall
        '';
      };
      extraPkgs = _: [ pkgs.libpng pkgs.libxkbfile ];
      extraBwrapArgs = [ "--setenv QT_QPA_PLATFORM xcb" ];
      extraInstallCommands = let
        contents = pkgs.appimageTools.extract { inherit pname version src; };
      in ''
        mv $out/bin/${pname} $out/bin/packettracer9
        install -Dm444 ${contents}/CiscoPacketTracer-9.0.1.desktop $out/share/applications/cisco-packet-tracer-9.desktop
        substituteInPlace $out/share/applications/* \
          --replace-fail "Exec=@EXEC_PATH@" "Exec=packettracer9" \
          --replace-fail "Icon=app" "Icon=cisco-packet-tracer-9"
        install -Dm444 ${contents}/usr/share/icons/hicolor/48x48/apps/app.png $out/share/icons/hicolor/48x48/apps/cisco-packet-tracer-9.png
        cp -r ${contents}/usr/share/icons/gnome/48x48/mimetypes $out/share/icons/hicolor/48x48/
      '';
    })
  ];

  # set cursor
  home.pointerCursor =
    let
      getFrom = url: hash: name: {
        gtk.enable = true;
        x11.enable = true;
        name = name;
        size = 24;
        package = pkgs.runCommand "moveUp" { } ''
          mkdir -p $out/share/icons
          ln -s ${
            pkgs.fetchzip {
              url = url;
              hash = hash;
            }
          }/dist $out/share/icons/${name}
        '';
      };
    in
    getFrom "https://github.com/yeyushengfan258/ArcMidnight-Cursors/archive/refs/heads/main.zip"
      "sha256-VgOpt0rukW0+rSkLFoF9O0xO/qgwieAchAev1vjaqPE="
      "ArcMidnight-Cursors";

  # Force the dark color scheme and explicitly set GTK3 theme in dconf
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
    };
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.opencode/bin"
  ];

  home.sessionVariables = {
    TERMINAL = "kitty";
  };

  services.easyeffects.enable = true;

  gtk = {
    enable = true;

    # IMPORT DYNAMIC MATUGEN COLORS
    gtk3.extraCss = ''@import url("file:///home/evert/.cache/matugen/colors-gtk.css");'';
    gtk4.extraCss = ''@import url("file:///home/evert/.cache/matugen/colors-gtk.css");'';

    # Target GTK3 specifically
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-theme-name = "adw-gtk3-dark";
    };

    # Keep GTK4 native but ensure it requests the dark preference
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "qt6ct";
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    config.common.default = "*";
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/plain" = "code.desktop";
      "text/x-python" = "code.desktop";
      "text/javascript" = "code.desktop";
      "text/html" = "code.desktop";
      "text/x-java" = "code.desktop";
      "text/x-kotlin" = "code.desktop";
      "text/x-rust" = "code.desktop";
      "text/x-c" = "code.desktop";
      "text/x-c++" = "code.desktop";
      "text/x-markdown" = "code.desktop";
      "text/css" = "code.desktop";
      "text/x-json" = "code.desktop";
      "text/x-yaml" = "code.desktop";
      "text/x-toml" = "code.desktop";
      "text/x-nix" = "code.desktop";
      "text/xml" = "code.desktop";
      "application/json" = "code.desktop";
      "inode/directory" = "dolphin.desktop";
    };
  };

  programs.home-manager.enable = true;

  fonts.fontconfig.enable = true;

  home.file = {
    ".local/share/fonts/" = {
      source = config/fonts;
      recursive = true;
    };
    ".local/bin/opencode" = {
      executable = true;
      text = ''
        #!${pkgs.bash}/bin/bash
        exec ${pkgs.steam-run}/bin/steam-run "$HOME/.opencode/bin/opencode" "$@"
      '';
    };
    ".config/dolphinrc" = {
      text = ''
        [General]
        RememberOpenedTabs=false

        [KFileDialog Settings]
        Recent Files=
        Recent URLs=

        [PreviewSettings]
        Plugins=

        [Version]
        version=200

        [KDE]
        TerminalApplication=kitty
        TerminalService=kitty.desktop
      '';
    };
  }
  // scriptHomeFiles;
}
