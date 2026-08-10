-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  ◈ SETTINGS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local var = require("config.variables")

-- 1. Configuraciones Estáticas Globales
hl.config({
  general = {
    border_size = 2,
    gaps_in = 4,
    gaps_out = 4,
    float_gaps = 6,
    resize_on_border = true,
    extend_border_grab_area = 30,
    col = {
      active_border = var.active_border,
      inactive_border = var.inactive_border,
    }
  },

  decoration = {
    rounding = 6,
    active_opacity = 0.92,
    inactive_opacity = 0.85,
    fullscreen_opacity = 1.0,
    blur = {
      enabled = true,
      size = 8,
      passes = 2,
      new_optimizations = true,
    },
    shadow = {
      enabled = true,
      range = 12,
      render_power = 3,
      color = "rgba(00000033)",
    },
  },

  input = {
    kb_layout = "us,latam", -- Corregido: Múltiples layouts van en el mismo string
    kb_options = "grp:alt_shift_toggle",
    kb_variant = "",
    kb_model = "",
    kb_rules = "",
    accel_profile = "flat",

    touchpad = {
      natural_scroll = true,
    },
  },

  misc = {
    focus_on_activate = true,
    font_family = "JetBrains Mono",
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
  },

  xwayland = {
    force_zero_scaling = true,
  },

  animations = {
    enabled = true
  }
})

-- Declaración de la curva Bezier (reemplaza a la sintaxis vieja)
hl.curve("myBezier", {
    type = "bezier",
    points = {
        { 0.05, 0.9 },
        { 0.1, 1.05 }
    }
})

-- 2. Procesamiento Dinámico de las Animaciones (FUERA de hl.config)
local animations = {
  {
    { "windows", "windowsOut" }, "popin 80%"
  },
  {
    { "layers", "layersIn", "layersOut", "specialWorkspaceIn", "specialWorkspaceOut" },
    "fade"
  },
  {
    { "workspaces" }, "slide"
  },
  {
    { "fade" }, nil
  }
}

for _, group in ipairs(animations) do
  local leaves = group[1]
  local style = group[2]

  for _, leaf_name in ipairs(leaves) do
    -- Usamos la función nativa hl.animation para registrar cada una
    hl.animation({
      leaf = leaf_name,
      enabled = true,
      bezier = "myBezier",
      speed = 5,
      style = style
    })
  end
end
