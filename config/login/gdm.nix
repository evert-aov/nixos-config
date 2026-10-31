{ lib, pkgs, ... }:
let
  wallpaperSync = pkgs.writeShellApplication {
    name = "sync-gdm-wallpaper";
    runtimeInputs = [ pkgs.coreutils pkgs.file pkgs.python3 ];
    text = ''
      source_image=/home/evert/.cache/quickshell/wallpaper_picker/current_wallpaper.png
      target_dir=/run/gdm-wallpaper
      target_image="$target_dir/current.png"
      fallback=${../../wallpapers/gdm-login.jpg}

      mkdir -p "$target_dir"
      image="$fallback"
      if [[ -s "$source_image" && ! -L "$source_image" ]]; then
        mime_type=$(file --brief --mime-type -- "$source_image")
        case "$mime_type" in
          image/png|image/jpeg|image/webp) image="$source_image" ;;
        esac
      fi

      install -m 0644 -- "$image" "$target_image.new"
      mv -f -- "$target_image.new" "$target_image"

      python3 - '${theme}' "$target_dir/theme" /home/evert/.cache/matugen-gdm-colors.json <<'PY'
      import json
      import re
      import sys
      from pathlib import Path

      source, destination, palette_path = map(Path, sys.argv[1:])
      defaults = {
          "base": "#1e1e2e", "mantle": "#181825", "crust": "#11111b",
          "text": "#cdd6f4", "subtext0": "#a6adc8", "blue": "#89b4fa",
          "sapphire": "#74c7ec", "mauve": "#cba6f7",
      }
      if palette_path.is_file() and not palette_path.is_symlink():
          try:
              saved = json.loads(palette_path.read_text())
              if not isinstance(saved, dict):
                  raise ValueError("Palette must be a JSON object")
              for name in defaults:
                  color = saved.get(name)
                  if isinstance(color, str) and re.fullmatch(r"#[0-9a-fA-F]{6}", color):
                      defaults[name] = color
          except (OSError, ValueError, TypeError):
              pass

      def rgba(name, alpha):
          rgb = defaults[name].lstrip("#")
          channels = ", ".join(str(int(rgb[index:index + 2], 16)) for index in (0, 2, 4))
          return f"rgba({channels}, {alpha})"

      substitutions = {
          "@wallpaper@": "/run/gdm-wallpaper/current.png",
          "@crust@": defaults["crust"], "@text@": defaults["text"],
          "@primary@": defaults["mauve"], "@primary_container@": defaults["sapphire"],
          "@subtext@": defaults["subtext0"], "@veil@": rgba("crust", 0.48),
          "@mantle@": rgba("base", 0.72), "@surface@": rgba("mantle", 0.90),
          "@raised@": rgba("mauve", 0.36), "@border@": rgba("sapphire", 0.48),
          "@entry@": rgba("crust", 0.84), "@focus@": rgba("mauve", 0.72),
      }
      stylesheet = (source / "custom.css").read_text()
      for token, color in substitutions.items():
          stylesheet = stylesheet.replace(token, color)
      if re.search(r"@[a-z_]+@", stylesheet):
          raise SystemExit("GDM stylesheet has unresolved color tokens")

      destination.mkdir(mode=0o755, parents=True, exist_ok=True)
      # Use the matching stock theme for all GDM controls, regardless of the
      # greeter's initial GSettings preference.
      base_rgb = defaults["base"].lstrip("#")
      brightness = sum(int(base_rgb[i:i + 2], 16) * weight
                       for i, weight in zip((0, 2, 4), (0.2126, 0.7152, 0.0722))) / 255
      selected_variant = "light" if brightness >= 0.55 else "dark"
      for variant in ("dark", "light"):
          original = (source / f"gnome-shell-{selected_variant}.css").read_text()
          target = destination / f"gnome-shell-{variant}.css"
          temporary = target.with_suffix(".css.new")
          temporary.write_text(original + "\n" + stylesheet)
          temporary.chmod(0o644)
          temporary.replace(target)
      PY
    '';
  };

  # Keep the installed GNOME theme and append only our greeter styles.
  # GLib resource overlays avoid rebuilding or modifying GNOME Shell itself.
  theme = pkgs.runCommand "evert-gdm-theme" {
    nativeBuildInputs = [ pkgs.glib.dev ];
  } ''
    mkdir -p "$out"
    substitute ${./gdm.css} custom.css \
      --replace-fail '@wallpaper@' '/run/gdm-wallpaper/current.png'
    for variant in dark light; do
      gresource extract \
        ${pkgs.gnome-shell}/share/gnome-shell/gnome-shell-theme.gresource \
        /org/gnome/shell/theme/gnome-shell-$variant.css \
        > "$out/gnome-shell-$variant.css"
    done
    cp custom.css "$out/custom.css"
  '';
in
{
  services.displayManager.gdm = {
    enable = true;
    banner = "Welcome, Evert";
  };

  systemd.tmpfiles.rules = [
    "d /run/gdm-wallpaper 0755 root root -"
  ];
  systemd.services.gdm-wallpaper = {
    description = "Select the current Quickshell wallpaper for GDM";
    before = [ "display-manager.service" ];
    wantedBy = [ "display-manager.service" ];
    restartIfChanged = false;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${wallpaperSync}/bin/sync-gdm-wallpaper";
      UMask = "0022";
    };
  };
  systemd.services.display-manager.wants = [ "gdm-wallpaper.service" ];
  systemd.services.display-manager.after = [ "gdm-wallpaper.service" ];

  # GNOME 50 launches the greeter as org.gnome.Shell@gdm, through this template.
  # An instance drop-in preserves its original ExecStart, dependencies and PAM.
  systemd.user.services."org.gnome.Shell@gdm" = {
    overrideStrategy = "asDropin";
    restartIfChanged = false;
    serviceConfig.Environment = [
      "G_RESOURCE_OVERLAYS=/org/gnome/shell/theme=/run/gdm-wallpaper/theme"
    ];
  };

  programs.dconf.profiles.gdm.databases = lib.mkAfter [
    {
      settings = {
        "org/gnome/login-screen" = {
          logo = "${./evert-logo.svg}";
          fallback-logo = "${./evert-logo.svg}";
        };
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          accent-color = "purple";
          clock-format = "24h";
          clock-show-weekday = true;
          show-battery-percentage = true;
        };
      };
    }
  ];
}
