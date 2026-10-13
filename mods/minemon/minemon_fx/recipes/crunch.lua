-- Crunch (signature, M2.1 T-FX-c): a heavy jaw of shadow. The orb is a dark mass with strands that whip off it, and
-- where it lands three claw slashes tear down the victim, with a black stain on the ground. Launch and the wind-up
-- come from recipes/type_dark.lua. Budgets: docs/ART_GUIDE.md 4.
-- Totals at "high": projectile ~40/s, impact ~90 (three slashes of 8 each, plus the rest).
-- luacheck: read_globals core vector minemon

local R = {}

local ZERO = { x = 0, y = 0, z = 0 }
local TENDRIL = "minemon_fx_tendril.png"
local SHADE = "#2a1a30"
local GLINT = "#ff3030"

-- A slash: a sheet of strands that streaks down the victim at a slant.
local function slash(F, victim, x, lean)
	F.on(victim, {
		amount = 8, time = 0.25,
		pos = { min = { x = x - 0.05, y = 0.9, z = -0.2 }, max = { x = x + 0.05, y = 1.5, z = 0.2 } },
		vel = { min = { x = lean - 0.2, y = -3.0, z = 0 }, max = { x = lean + 0.2, y = -2.2, z = 0 } },
		exptime = { min = 0.25, max = 0.4 }, size = { min = 0.7, max = 1.0 }, vertical = true, glow = 0,
		texture = F.tex(F.tint(TENDRIL, SHADE), { blend = "alpha", fade = { 1, 0 } }),
	})
end

-- The orb: a dark mass (bigger than the type's), strands that whip off it, a sub-blend shadow and red glints.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(F.TEX.glow, "#4a3a5a") }, visual_size = { x = 0.9, y = 0.9 } })
	F.on(c.obj, {
		amount = 22, time = 1.5, pos = { min = { x = -0.15, y = -0.15, z = -0.15 }, max = { x = 0.15, y = 0.15, z = 0.15 } },
		vel = { min = { x = -0.3, y = 0, z = -0.3 }, max = { x = 0.3, y = 0.5, z = 0.3 } },
		exptime = { min = 0.4, max = 0.8 }, size = { min = 0.6, max = 1.0 }, vertical = true, glow = 0,
		texture = F.tex(F.tint(TENDRIL, SHADE), { blend = "alpha", fade = true }),
	})
	F.on(c.obj, {
		amount = 12, time = 1.5, pos = { min = { x = -0.2, y = -0.2, z = -0.2 }, max = { x = 0.2, y = 0.2, z = 0.2 } },
		vel = ZERO, exptime = { min = 0.6, max = 1.0 }, size = { min = 0.8, max = 1.1 },
		texture = F.tex(F.tint(F.TEX.smoke, "#6a5a78"), { blend = "sub", alpha = 0.5, anim = "smoke" }),
	})
	F.on(c.obj, {
		amount = 16, time = 1.5, pos = ZERO,
		vel = { min = { x = -0.8, y = -0.8, z = -0.8 }, max = { x = 0.8, y = 0.8, z = 0.8 } },
		exptime = { min = 0.2, max = 0.4 }, size = { min = 0.07, max = 0.12 },
		texture = F.tex(F.tint(F.TEX.spark, GLINT), { blend = "add", fade = true }), glow = 14,
	})
	return true
end

-- Impact: three claw slashes down the victim, a red flash, black smoke and a bite-shaped stain on the ground.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = GLINT, size = 1.4, life = 0.12 })
	F.smoke({ pos = at, colour = c.palette.smoke, amount = 8, size = { 0.7, 1.0 }, life = { 1.0, 1.5 }, alpha = 0.85,
		rise = 0.8, time = 0.3 })
	if c.victim and c.victim:get_pos() then
		slash(F, c.victim, -0.3, 0.3)
		slash(F, c.victim, 0, 0.2)
		slash(F, c.victim, 0.3, 0.1)
		F.emit({
			amount = 14, time = 0.2, pos = F.anchor(c.victim, "middle", 0.55) or at,
			vel = { min = { x = -2, y = -1, z = -2 }, max = { x = 2, y = 1, z = 2 } },
			exptime = { min = 0.2, max = 0.4 }, size = { min = 0.07, max = 0.12 },
			texture = F.tex(F.tint(F.TEX.spark, GLINT), { blend = "add", fade = true }), glow = 14,
		})
	end
	F.decal({ pos = at, tex = F.tint(F.TEX.dust, c.palette.smoke), size = 2.2, life = 6 })
	F.sound("mobs_mc_wolf_hurt.2", { pos = at, gain = 0.9, pitch = 0.5 })
end

minemon.fx.register_move("crunch", R)
