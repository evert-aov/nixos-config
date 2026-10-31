{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "bash ~/.config/hypr/scripts/lock.sh";
        before_sleep_cmd = "loginctl lock-session";
        # Esperar la confirmación de bloqueo Wayland, también con Quickshell.
        inhibit_sleep = 3;
        after_sleep_cmd = "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'";
      };

      listener = [
        {
          timeout = 300; 
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 600;
          on-timeout = "hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })'";
          on-resume = "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'";
        }
        {
          timeout = 900; 
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
