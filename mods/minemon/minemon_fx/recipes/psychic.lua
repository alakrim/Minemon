-- Psychic (signature, M2.1 T-FX-c): the big psychic blast. A heavier pink orb with wide halos, a double ring at the
-- muzzle and an impact that draws a large sigil under the victim, with white sparks rising out of it. Its wind-up and
-- cast come from the type recipe (recipes/type_psychic.lua). Budgets: docs/ART_GUIDE.md 4.
-- Totals at "high": launch ~40, projectile ~40/s, impact ~90.
-- luacheck: read_globals core vector minemon

local R = {}

local ZERO = { x = 0, y = 0, z = 0 }
local RUNE = "minemon_fx_rune.png"

function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 1.3, life = 0.2 })
	F.ring({ pos = c.from, colour = c.palette.main, size = 0.45, grow = 3.4, life = 0.32 })
	core.after(0.09, function()
		F.ring({ pos = c.from, colour = c.palette.edge, size = 0.4, grow = 3.0, life = 0.3 })
	end)
	F.emit({
		amount = 22, time = 0.05, pos = c.from,
		vel = { min = vector.multiply(c.dir, 2), max = vector.multiply(c.dir, 6) },
		exptime = { min = 0.35, max = 0.6 }, size = { min = 0.14, max = 0.24 },
		texture = F.tex(F.tint(RUNE, c.palette.main), { blend = "add", fade = true }), glow = 14,
	})
	F.sound("mcl_enchanting_enchant", { pos = c.from, gain = 0.7, pitch = 1.1 })
end

-- A larger orb: a wide pink halo, rings that swell to twice their size, runes and a white core.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(F.TEX.glow, c.palette.main) }, visual_size = { x = 0.9, y = 0.9 },
		glow = 14 })
	F.on(c.obj, {
		amount = 40, time = 1.5, pos = { min = { x = -0.1, y = -0.1, z = -0.1 }, max = { x = 0.1, y = 0.1, z = 0.1 } },
		vel = ZERO, exptime = { min = 0.3, max = 0.45 }, size = { min = 0.6, max = 0.9 },
		texture = F.tex(F.tint(F.TEX.ring, c.palette.main), { blend = "add", fade = true, grow = { 0.5, 2.2 } }),
		glow = 14,
	})
	F.on(c.obj, {
		amount = 10, time = 1.5, pos = { min = { x = -0.35, y = -0.35, z = -0.35 }, max = { x = 0.35, y = 0.35, z = 0.35 } },
		vel = { min = { x = -0.3, y = 0.1, z = -0.3 }, max = { x = 0.3, y = 0.6, z = 0.3 } },
		exptime = { min = 0.6, max = 1.0 }, size = { min = 0.18, max = 0.28 },
		texture = F.tex(F.tint(RUNE, c.palette.main), { blend = "add", fade = true }), glow = 10,
	})
	F.on(c.obj, {
		amount = 16, time = 1.5, pos = ZERO,
		vel = { min = { x = -0.6, y = -0.6, z = -0.6 }, max = { x = 0.6, y = 0.6, z = 0.6 } },
		exptime = { min = 0.25, max = 0.4 }, size = { min = 0.16, max = 0.26 },
		texture = F.tex(F.tint(F.TEX.spark, c.palette.core), { blend = "add", fade = true }), glow = 14,
	})
	return true
end

-- Impact: a flash, three rings in turn, a sigil that stays on the ground for 6 s and white sparks that rise from it.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.8, life = 0.16 })
	F.ring({ pos = at, colour = c.palette.core, size = 0.35, grow = 3.4, life = 0.32 })
	core.after(0.14, function()
		F.ring({ pos = at, colour = c.palette.main, size = 0.35, grow = 4.6, life = 0.45 })
	end)
	core.after(0.3, function()
		F.ring({ pos = at, colour = c.palette.edge, size = 0.35, grow = 5.4, life = 0.5 })
	end)
	F.burst({ pos = at, tex = RUNE, colour = c.palette.main, amount = 30, speed = 4.5, life = { 0.6, 1.1 },
		size = { 0.16, 0.26 }, gravity = -0.8 })
	F.burst({ pos = at, colour = c.palette.core, amount = 20, speed = 5, life = { 0.25, 0.5 },
		size = { 0.1, 0.16 }, gravity = -1.5, glow = 14 })
	F.smoke({ pos = at, colour = c.palette.smoke, amount = 5, size = { 0.5, 0.8 }, life = { 0.8, 1.2 },
		alpha = 0.4, rise = 0.5 })
	if c.victim and c.victim:get_pos() then
		F.on(c.victim, {
			amount = 18, time = 1.0,
			pos = { min = { x = -0.35, y = 0.2, z = -0.35 }, max = { x = 0.35, y = 1.1, z = 0.35 } },
			vel = { min = { x = -0.05, y = 0.5, z = -0.05 }, max = { x = 0.05, y = 1.0, z = 0.05 } },
			exptime = { min = 0.7, max = 1.1 }, size = { min = 0.16, max = 0.26 },
			texture = F.tex(F.tint(RUNE, c.palette.main), { blend = "add", fade = true }), glow = 10,
		})
	end
	F.decal({ pos = at, tex = F.tint(RUNE, c.palette.main), size = 3.0, life = 6 })
	F.sound("mcl_enchanting_enchant", { pos = at, gain = 0.85, pitch = 0.7 })
end

minemon.fx.register_move("psychic", R)
