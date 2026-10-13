-- Dragon Rage (signature, M2.1 T-FX-c): a roaring orb. The muzzle throws two shock rings at once, the orb is bigger
-- than the type's and drags a halo of violet glow with gold sparks that flare like sparks off a grinding wheel, and
-- the impact is the heaviest of the dragon moves: a double shock, a white crown of sparks and a gold burst that rains
-- down. Wind-up: recipes/type_dragon.lua. Budgets: docs/ART_GUIDE.md 4.
-- Totals at "high": launch ~40, projectile ~50/s, impact ~120.
-- luacheck: read_globals core vector minemon

local R = {}

local ZERO = { x = 0, y = 0, z = 0 }
local GOLD = "#ffd040"

local function gold(F)
	return F.tex(F.tint(F.TEX.spark, GOLD), { blend = "add", fade = true })
end

function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 1.4, life = 0.18 })
	F.ring({ pos = c.from, colour = c.palette.main, size = 0.45, grow = 3.6, life = 0.32 })
	F.after(0.08, function()
		F.ring({ pos = c.from, colour = c.palette.edge, size = 0.45, grow = 3.2, life = 0.36 })
	end)
	F.emit({
		amount = 24, time = 0.05, pos = c.from,
		vel = { min = vector.add(vector.multiply(c.dir, 3), { x = -0.8, y = 0, z = -0.8 }),
			max = vector.add(vector.multiply(c.dir, 8), { x = 0.8, y = 1.2, z = 0.8 }) },
		exptime = { min = 0.25, max = 0.45 }, size = { min = 0.1, max = 0.16 }, texture = gold(F), glow = 14,
	})
	F.sound("mobs_mc_ender_dragon_shoot", { pos = c.from, gain = 0.8, pitch = 0.9 })
end

-- A bigger orb: a wide violet halo, gold sparks that flare and die, and a shock ring left every quarter second.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(F.TEX.glow, c.palette.main) }, visual_size = { x = 0.95, y = 0.95 },
		glow = 14 })
	F.on(c.obj, {
		amount = 40, time = 1.5, pos = { min = { x = -0.1, y = -0.1, z = -0.1 }, max = { x = 0.1, y = 0.1, z = 0.1 } },
		vel = ZERO, exptime = { min = 0.3, max = 0.45 }, size = { min = 0.5, max = 0.7 },
		texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add", fade = true, grow = { 1, 0.4 } }),
		glow = 14,
	})
	F.on(c.obj, {
		amount = 30, time = 1.5, pos = { min = { x = -0.5, y = -0.5, z = -0.5 }, max = { x = 0.5, y = 0.5, z = 0.5 } },
		vel = { min = { x = -0.8, y = -0.8, z = -0.8 }, max = { x = 0.8, y = 0.8, z = 0.8 } },
		exptime = { min = 0.15, max = 0.35 }, size = { min = 0.08, max = 0.14 }, texture = gold(F), glow = 14,
	})
	F.on(c.obj, {
		amount = 6, time = 1.5, pos = ZERO, vel = ZERO, exptime = { min = 0.3, max = 0.4 },
		size = { min = 0.55, max = 0.75 },
		texture = F.tex(F.tint(F.TEX.ring, c.palette.main), { blend = "add", fade = true, grow = { 0.5, 1.8 } }),
		glow = 14,
	})
	return true
end

-- Impact: a double shock, a bright crown of sparks, a violet burst and a gold rain that bounces off the ground.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = "#ffffff", size = 2.0, life = 0.14 })
	F.ring({ pos = at, colour = c.palette.core, size = 0.5, grow = 4.6, life = 0.4 })
	F.after(0.06, function()
		F.ring({ pos = at, colour = c.palette.main, size = 0.5, grow = 5.4, life = 0.5 })
	end)
	F.burst({ pos = at, tex = F.TEX.glow, colour = c.palette.main, amount = 28, speed = 5, life = { 0.3, 0.7 },
		size = { 0.2, 0.34 } })
	F.burst({ pos = at, tex = F.TEX.spark, colour = c.palette.core, amount = 22, speed = 6, life = { 0.2, 0.45 },
		size = { 0.08, 0.13 }, glow = 14 })
	F.burst({ pos = at, tex = F.TEX.spark, colour = GOLD, amount = 30, speed = 4, life = { 0.4, 0.8 },
		size = { 0.08, 0.13 }, gravity = 7, collide = true, bounce = 0.35 })
	F.smoke({ pos = at, colour = c.palette.smoke, amount = 8, size = { 0.6, 1.0 }, life = { 1.0, 1.5 }, alpha = 0.5,
		rise = 0.7, spread = 0.4 })
	if c.victim and c.victim:get_pos() then
		F.on(c.victim, {
			amount = 18, time = 0.8, pos = { min = { x = -0.35, y = 0.2, z = -0.35 }, max = { x = 0.35, y = 1.1, z = 0.35 } },
			vel = { min = { x = -0.6, y = -0.6, z = -0.6 }, max = { x = 0.6, y = 0.6, z = 0.6 } },
			exptime = { min = 0.35, max = 0.6 }, size = { min = 0.1, max = 0.15 }, texture = gold(F), glow = 14,
		})
	end
	F.decal({ pos = at, tex = F.tint(F.TEX.ring, c.palette.edge), size = 3.0, life = 6 })
	F.sound("mobs_mc_ender_dragon_attack", { pos = at, gain = 1.0, pitch = 0.9 })
end

minemon.fx.register_move("dragon_rage", R)
