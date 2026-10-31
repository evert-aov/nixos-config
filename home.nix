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
    freerdp
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
        src = pkgs.requireFile {
          name = "CiscoPacketTracer_901_Ubuntu_64bit.deb";
          hashMode = "recursive";
          hash = "sha256-biYiu0gukHHLRvwXiOSK3jblrslvwqwXMCHG7og6JpY=";
          message = ''
            Se necesita el instalador original de Cisco Packet Tracer 9.0.1.
            Ejecuta ./deploy.sh para registrar la copia local o importa el archivo:
            nix-store --add-fixed --recursive sha256 /ruta/CiscoPacketTracer_901_Ubuntu_64bit.deb
          '';
        };
        nativeBuildInputs = [ pkgs.dpkg ];
        installPhase = ''
          runHook preInstall
          cp opt/pt/packettracer.AppImage $out
          runHook postInstall
        '';
      };
      extraPkgs = _: [ pkgs.libpng pkgs.libxkbfile ];
      extraBwrapArgs = [ 
        "--setenv QT_QPA_PLATFORM xcb" 
        "--unshare-net" 
      ];
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
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "ArcMidnight-Cursors";
    size = 24;
    # Copia exacta del tema actual, con fuentes y licencia; no depende de main.zip.
    package = pkgs.runCommand "arcmidnight-cursors" { } ''
      mkdir -p $out/share/icons/ArcMidnight-Cursors $out/share/doc/arcmidnight-cursors
      tar -xzf ${./assets/arcmidnight-cursors.tar.gz}
      cp -a source/dist/. $out/share/icons/ArcMidnight-Cursors/
      cp source/LICENSE $out/share/doc/arcmidnight-cursors/
    '';
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.opencode/bin"
  ];

  home.sessionVariables = {
    TERMINAL = "kitty";
  };

  services.easyeffects.enable = true;

  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "auto";
  };
  gtk = {
    enable = true;

    # IMPORT DYNAMIC MATUGEN COLORS
    gtk3.extraCss = ''@import url("file:///home/evert/.cache/matugen/colors-gtk.css");'';
    gtk4.extraCss = ''@import url("file:///home/evert/.cache/matugen/colors-gtk.css");'';

    # Matugen selects the GTK preference dynamically through GSettings.

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
      "application/pdf" = "vivaldi-stable.desktop";
      "inode/directory" = "org.gnome.Nautilus.desktop";
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
