-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  ◈ WINDOW & LAYER RULES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ─────────────────────────────
-- Layer rules (OSD / overlays)
-- ─────────────────────────────

-- ─────────────────────────────
-- Window rules
-- ─────────────────────────────

-- ───────── CS2 ─────────
-- immediate and keepaspectratio are not available in the new windowrule syntax

-- ───────── App Launcher ─────────
-- windowrule = float on, center on, size 1200 600, match:title ^(app-launcher)$
hl.window_rule({ match = { title = "^(app-launcher)$" }, float = true })
hl.window_rule({ match = { title = "^(app-launcher)$" }, center = true })
hl.window_rule({ match = { title = "^(app-launcher)$" }, size = "1200 600" })

--  ───────── MASTER QUICKSHELL CONTAINER ─────────
-- All widgets now live inside this single, shape-shifting window.
-- windowrulev2 = float, title:^(qs-master)$
-- windowrulev2 = noshadow, title:^(qs-master)$
-- windowrulev2 = noborder, title:^(qs-master)$
-- windowrulev2 = noinitialfocus, title:^(qs-master)$
