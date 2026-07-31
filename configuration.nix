{ config, pkgs, lib, ... }:

let
  # vivaldi-ffmpeg-codecs de nixpkgs está pinnado a Chromium 123 (123075), pero Vivaldi 8.1
  # es Chromium 150 y crashea con "undefined symbol: av_dynamic_hdr_smpte2094_app5_to_t35".
  # Usamos el libffmpeg.so oficial para Vivaldi 8.1 (8.1-150-S-20260618, el snap que instala update-ffmpeg).
  vivaldi-ffmpeg-codecs = pkgs.stdenv.mkDerivation {
    pname = "vivaldi-ffmpeg-codecs";
    version = "8.1-150-S-20260618";
    src = pkgs.fetchurl {
      url = "https://api.snapcraft.io/api/v1/snaps/download/XXzVIXswXKHqlUATPqGCj2w2l7BxosS8_117.snap";
      hash = "sha256-YEE7oF8NLGDCQ3gpY5z6B+7xDxcOumjOzwUztJUM+/s=";
    };
    nativeBuildInputs = [ pkgs.squashfsTools ];
    unpackPhase = ''
      unsquashfs -dest . $src
    '';
    installPhase = ''
      install -vD chromium-ffmpeg-git-2026-05-18/chromium-ffmpeg/libffmpeg.so $out/lib/libffmpeg.so
    '';
  };
in
{
  # ============================================================================
  # IMPORTS
  # ============================================================================
  imports = [
    ./hardware-configuration.nix
  ];

  # ============================================================================
  # BOOT & KERNEL
  # ============================================================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.cpu.amd.updateMicrocode = true;

  boot.kernelModules = [ "tcp_bbr" ];
  boot.kernel.sysctl = {
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "fq";
    "net.core.wmem_max" = 1073741824;
    "net.core.rmem_max" = 1073741824;
    "net.ipv4.tcp_rmem" = "4096 87380 1073741824";
    "net.ipv4.tcp_wmem" = "4096 87380 1073741824";
  };

  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "quiet"
    "splash"
    "boot.shell_on_fail"
    "loglevel=3"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
    "amd_pstate=active"
    "tsc=reliable"
  ];

  boot.plymouth = {
    enable = true;
    theme = "simple";
    themePackages = [
      (pkgs.stdenv.mkDerivation {
        pname = "plymouth-theme-simple";
        version = "1.0";
        src = ./config/programs/plymouth/simple;
        installPhase = ''
          mkdir -p $out/share/plymouth/themes/simple
          cp -r * $out/share/plymouth/themes/simple/
          substituteInPlace $out/share/plymouth/themes/simple/simple.plymouth \
            --replace "@out@" "$out"
        '';
      })
    ];
  };

  # ============================================================================
  # NETWORKING
  # ============================================================================
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = false;

  # ============================================================================
  # TIME ZONE & LOCALE
  # ============================================================================
  time.timeZone = "America/La_Paz";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS     = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY    = "en_US.UTF-8";
    LC_NAME        = "en_US.UTF-8";
    LC_NUMERIC     = "en_US.UTF-8";
    LC_PAPER       = "en_US.UTF-8";
    LC_TELEPHONE   = "en_US.UTF-8";
    LC_TIME        = "en_US.UTF-8";
  };

  # ============================================================================
  # GRAPHICS & DISPLAY
  # ============================================================================
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;

  programs.hyprland.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  services.libinput.enable = true;
  services.udisks2.enable = true;

  # ============================================================================
  # AUDIO (PipeWire)
  # ============================================================================
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ============================================================================
  # BLUETOOTH
  # ============================================================================
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # ============================================================================
  # INPUT (Keyboard)
  # ============================================================================
  services.xserver.xkb = {
    layout = "us,es";
    variant = "";
    options = "grp:alt_shift_toggle";
  };

  # ============================================================================
  # SERVICES
  # ============================================================================
  services.printing.enable = true;
  services.openssh.enable = true;
  services.flatpak.enable = true;
  services.power-profiles-daemon.enable = true;

  programs.firefox.enable = true;
  programs.vscode.enable = true;
  programs.dconf.enable = true;

  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
  };

  # ============================================================================
  # GAMING
  # ============================================================================
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  programs.gamemode.enable = true;

  # ============================================================================
  # SHELL (ZSH)
  # ============================================================================
  programs.zsh.enable = true;

  # ============================================================================
  # USER ACCOUNT
  # ============================================================================
  users.users.evert = {
    isNormalUser = true;
    description = "evert";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "video" "adbusers" "libvirtd" ];
  };

  users.defaultUserShell = pkgs.zsh;
  system.userActivationScripts.zshrc = "touch .zshrc";

  security.sudo.extraRules = [
    {
      users = [ "evert" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # ============================================================================
  # NIX CONFIGURATION
  # ============================================================================
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 14d";
  };

  # ============================================================================
  # NIX-LD (For running generic Linux binaries)
  # ============================================================================
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    libX11 libXext libXi libXrender libXrandr libXcursor
    libXinerama libXtst libXScrnSaver libxkbcommon
    fontconfig freetype gtk3 glib zlib alsa-lib mesa
    stdenv.cc.cc.lib
  ];

  # ============================================================================
  # VIRTUALIZATION
  # ============================================================================
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  virtualisation.docker.enable = true;

  # ============================================================================
  # FONTS
  # ============================================================================
  fonts.packages = with pkgs; [
    udev-gothic-nf
    noto-fonts
    liberation_ttf
    nerd-fonts.jetbrains-mono
    nerd-fonts.caskaydia-cove
    corefonts
  ];

  fonts.fontconfig = {
    enable = true;
    hinting.style = "slight";
    subpixel.rgba = "rgb";
  };

  environment.pathsToLink = [ "/share/gsettings-schemas" ];

  # ============================================================================
  # POWER MANAGEMENT
  # ============================================================================
  powerManagement.cpuFreqGovernor = "performance";

  # ============================================================================
  # SYSTEM PACKAGES
  # ============================================================================
  environment.systemPackages = with pkgs; [

    # ---- Base & Essentials ----
    wget
    git
    killall
    fastfetch
    jq
    yq-go
    p7zip
    neovim
    fzf
    fd
    ripgrep
    tree
    zenity
    file
    ffmpeg
    mpv

    # ---- Terminal & Apps ----
    kitty
    (wrapFirefox (pkgs.firefox-unwrapped.override { pipewireSupport = true; }) {})
    (vivaldi.override { proprietaryCodecs = true; enableWidevine = true; inherit vivaldi-ffmpeg-codecs; })
    telegram-desktop
    obsidian
    qbittorrent
    (bottles.override { removeWarningPopup = true; })

    # ---- Development ----
    python3
    nodejs_latest
    vite
    typescript
    typescript-language-server
    eslint
    prettier
    jdk25
    maven
    gradle_9
    flutter
    dart
    dart-sass
    android-tools
    dotnet-sdk
    jetbrains-toolbox
    jetbrains.idea
    vscode
    postgresql
    postman
    insomnia

    # ---- Desktop ----
    quickshell
    awww
    mpvpaper
    matugen
    eww
    grim
    slurp
    satty
    swappy
    playerctl
    wl-clipboard
    cliphist
    gpu-screen-recorder
    kdePackages.dolphin
    yazi

    # ---- Customization ----
    pipes
    glaxnimate
    clock-rs
    cbonsai
    lavat
    taskwarrior3
    inotify-tools
    direnv
    zbar
    hunspell
    hunspellDicts.ru_RU
    hunspellDicts.en_US
    obs-studio
    inkscape
    #  rofi
    networkmanagerapplet
    xdg-desktop-portal-gtk

    # ---- GTK/Qt Theming ----
    gtk3
    libsForQt5.qt5ct
    qt6Packages.qt6ct
    libsForQt5.qtstyleplugin-kvantum
    kdePackages.qtstyleplugin-kvantum
    nwg-look

    # ---- Gaming ----
    steam-run

    # ---- Cross-compilation ----
    pkgsCross.mingwW64.stdenv.cc
    power-profiles-daemon
    wmctrl
  ];

  # ============================================================================
  # FILESYSTEMS (Mounts)
  # ============================================================================
  fileSystems."/mnt/datos" = {
    device = "/dev/disk/by-uuid/bfcecd32-0eef-43df-afe9-3adb96680981";
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  # ============================================================================
  # DATABASES
  # ============================================================================
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "evert" ];
    ensureUsers = [
      {
        name = "evert";
        ensureDBOwnership = true;
      }
    ];
  };

  # ============================================================================
  # SYSTEM STATE VERSION
  # ============================================================================
  system.stateVersion = "25.11";
}
