-- Ember: THE REFERENCE RECIPE (M2.1, hand-made by the orchestrator). docs/ART_GUIDE.md walks through it; copy its
-- structure for every signature move: a readable wind-up, a launch with a muzzle flash, a projectile with a body and
-- a trail, and an impact in layers (flash, blast, debris, smoke, a mark that stays).
--
-- Timeline (cast_s 0.5): 0.0 Charmander draws embers into its mouth, its tail flame flares (art/charmander.lua);
-- 0.5 a burst of flame leaves the mouth; the fireball flies with a flame trail, dripping embers and soot;
-- impact: a white catch light, two overlapping fire blasts, a shock ring, embers that bounce on the ground, rising
-- smoke, flames licking the victim for half a second, a scorch mark that fades over 8 s, and the crackle of fire.
-- Budget at "high": cast 45, launch 30, projectile ~120 over its flight, impact ~110 particles, 1 decal.
-- luacheck: read_globals core vector minemon

local R = {}

function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.5)
	F.inhale({ pos = at, tex = F.TEX.ember, radius = 1.0, amount = 30, time = t, size = { 0.08, 0.14 } })
	-- The mouth glow swells over the cast.
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = { x = 0, y = 0, z = 0 }, exptime = t + 0.05, size = 0.8,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add", grow = { 0.15, 1.0 }, alpha = 0.9 }),
		glow = 14,
	})
	-- Heat licks out of the mouth in the last part of the cast.
	F.flames({ pos = at, amount = 8, size = { 0.15, 0.24 }, life = { 0.2, 0.3 }, spread = 0.05, rise = 0.6, time = t })
	F.sound("fire_flint_and_steel", { pos = at, gain = 0.5, pitch = 1.3 })
end

function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9, life = 0.15 })
	F.blast({ pos = c.from, size = 0.8, life = 0.3 })
	F.emit({
		amount = 16, time = 0.05, pos = c.from,
		vel = { min = vector.add(vector.multiply(c.dir, 3), { x = -1, y = -0.5, z = -1 }),
			max = vector.add(vector.multiply(c.dir, 7), { x = 1, y = 1.5, z = 1 }) },
		acc = { x = 0, y = -6, z = 0 },
		exptime = { min = 0.25, max = 0.5 }, size = { min = 0.07, max = 0.13 },
		texture = F.tex(F.TEX.ember, { blend = "add", fade = { 1, 0.6 } }), glow = 14,
	})
	F.sound("mobs_fireball", { pos = c.from, gain = 0.6, pitch = 1.25 })
end

function R.projectile(F, c)
	local obj = c.obj
	obj:set_properties({
		textures = { F.TEX.fireball },
		spritediv = { x = 1, y = F.FRAMES.fireball },
		visual_size = { x = 0.7, y = 0.7 },
		glow = 14,
	})
	obj:set_sprite({ x = 0, y = 0 }, F.FRAMES.fireball, 0.06, false)
	local life = 1.5
	-- The flame trail: tongues that stay where they were born, shrink and die.
	F.on(obj, {
		amount = 75, time = life, pos = { min = { x = -0.06, y = -0.06, z = -0.06 }, max = { x = 0.06, y = 0.06, z = 0.06 } },
		vel = { min = { x = -0.2, y = 0.2, z = -0.2 }, max = { x = 0.2, y = 0.7, z = 0.2 } },
		exptime = { min = 0.18, max = 0.32 }, size = { min = 0.4, max = 0.6 },
		texture = F.tex(F.TEX.flame, { blend = "add", anim = "flame", grow = { 1, 0.3 } }),
		vertical = true, glow = 14,
	})
	-- Embers that drip from it and fall.
	F.on(obj, {
		amount = 24, time = life, pos = { x = 0, y = 0, z = 0 },
		vel = { min = { x = -0.8, y = -0.2, z = -0.8 }, max = { x = 0.8, y = 0.8, z = 0.8 } },
		acc = { x = 0, y = -7, z = 0 },
		exptime = { min = 0.4, max = 0.8 }, size = { min = 0.06, max = 0.11 },
		collisiondetection = true, bounce = { min = 0.2, max = 0.4 },
		texture = F.tex(F.TEX.ember, { blend = "add", fade = { 1, 0.7 } }), glow = 14,
	})
	-- A thin soot wake.
	F.on(obj, {
		amount = 14, time = life, pos = { x = 0, y = 0, z = 0 },
		vel = { min = { x = -0.1, y = 0.3, z = -0.1 }, max = { x = 0.1, y = 0.6, z = 0.1 } },
		exptime = { min = 0.6, max = 0.9 }, size = { min = 0.3, max = 0.48 },
		texture = F.tex(F.tint(F.TEX.smoke, c.palette.smoke), { blend = "alpha", alpha = 0.45, anim = "smoke" }),
	})
	return true
end

function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = "#ffffff", size = 1.5, life = 0.12 })
	F.blast({ pos = at, size = 1.8, life = 0.5 })
	F.blast({ pos = vector.add(at, { x = 0, y = 0.3, z = 0 }), size = 1.1, life = 0.4, spread = 0.3 })
	F.ring({ pos = at, colour = c.palette.main, size = 0.5, grow = 3.5, life = 0.3 })
	F.embers({ pos = at, amount = 26, speed = 3, up = 2.5 })
	F.smoke({ pos = vector.add(at, { x = 0, y = 0.3, z = 0 }), colour = c.palette.smoke, amount = 8,
		size = { 0.6, 0.96 }, life = { 1.0, 1.6 }, rise = 1.0, time = 0.3 })
	if c.victim and c.victim:get_pos() then
		F.on(c.victim, {
			amount = 10, time = 0.6, pos = { min = { x = -0.25, y = 0.1, z = -0.25 }, max = { x = 0.25, y = 0.6, z = 0.25 } },
			vel = { min = { x = 0, y = 0.6, z = 0 }, max = { x = 0, y = 1.2, z = 0 } },
			exptime = { min = 0.25, max = 0.4 }, size = { min = 0.27, max = 0.42 },
			texture = F.tex(F.TEX.flame, { blend = "add", anim = "flame" }), vertical = true, glow = 14,
		})
	end
	F.decal({ pos = at, tex = F.TEX.scorch, size = 1.4, life = 8 })
	F.sound("fire_fire", { pos = at, gain = 0.8 })
end

minemon.fx.register_move("ember", R)
