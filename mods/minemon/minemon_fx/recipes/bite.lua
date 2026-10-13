-- Bite (signature, M2.1 T-FX-c): a quick snap. The shot is a fast dark streak with a fine trail of red glints, and the
-- impact is a bright red snap: two flashes, a red shock ring, a burst of glints and a short scatter of strands
-- off the victim. No stain: the bite is gone as fast as it came. Wind-up and launch: recipes/type_dark.lua.
-- Totals at "high": projectile ~45/s, impact ~50.
-- luacheck: read_globals core vector minemon

local R = {}

local ZERO = { x = 0, y = 0, z = 0 }
local TENDRIL = "minemon_fx_tendril.png"
local SHADE = "#2a1a30"
local GLINT = "#ff3030"

-- A fast orb: a small dark body, a fine trail of red glints thrown backwards and short strands that snap off it.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(F.TEX.glow, "#4a3a5a") }, visual_size = { x = 0.45, y = 0.45 } })
	F.on(c.obj, {
		amount = 30, time = 1.5, pos = ZERO,
		vel = { min = { x = -0.4, y = -0.4, z = -0.4 }, max = { x = 0.4, y = 0.4, z = 0.4 } },
		exptime = { min = 0.15, max = 0.3 }, size = { min = 0.07, max = 0.12 },
		texture = F.tex(F.tint(F.TEX.spark, GLINT), { blend = "add", fade = true }), glow = 14,
	})
	F.on(c.obj, {
		amount = 12, time = 1.5, pos = { min = { x = -0.1, y = -0.1, z = -0.1 }, max = { x = 0.1, y = 0.1, z = 0.1 } },
		vel = { min = { x = -0.2, y = 0, z = -0.2 }, max = { x = 0.2, y = 0.3, z = 0.2 } },
		exptime = { min = 0.3, max = 0.5 }, size = { min = 0.4, max = 0.6 }, vertical = true, glow = 0,
		texture = F.tex(F.tint(TENDRIL, SHADE), { blend = "alpha", fade = true }),
	})
	return true
end

-- Impact: a red flash, two rings of glints (the second is the snap) and a scatter of strands off the victim.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = GLINT, size = 1.5, life = 0.1 })
	F.flare({ pos = at, colour = "#ffffff", size = 0.7, life = 0.08 })
	F.burst({ pos = at, tex = F.TEX.spark, colour = GLINT, amount = 22, speed = 5, radius = 0.25,
		life = { 0.15, 0.3 }, size = { 0.08, 0.14 } })
	F.burst({ pos = at, tex = TENDRIL, colour = SHADE, blend = "alpha", amount = 10, speed = 3.5,
		life = { 0.25, 0.4 }, size = { 0.5, 0.8 }, glow = 0 })
	F.ring({ pos = at, colour = GLINT, size = 0.4, grow = 3.0, life = 0.22 })
	if c.victim and c.victim:get_pos() then
		F.emit({
			amount = 12, time = 0.15, pos = F.anchor(c.victim, "middle", 0.55) or at,
			vel = { min = { x = -2, y = -1, z = -2 }, max = { x = 2, y = 1, z = 2 } },
			exptime = { min = 0.2, max = 0.35 }, size = { min = 0.07, max = 0.12 },
			texture = F.tex(F.tint(F.TEX.spark, GLINT), { blend = "add", fade = true }), glow = 14,
		})
	end
	F.sound("mobs_mc_wolf_hurt.3", { pos = at, gain = 0.8, pitch = 1.1 })
end

minemon.fx.register_move("bite", R)
