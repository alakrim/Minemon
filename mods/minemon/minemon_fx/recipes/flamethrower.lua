-- Flamethrower (signature, M2.1 T-FX-c): a jet of fire, not a ball. The shot is a stream of flame tongues that leave
-- the mouth in a line and keep their shape where they were born, so the flight reads as a jet. The impact sets the
-- victim alight for a second. Wind-up: recipes/type_fire.lua. Budgets: docs/ART_GUIDE.md 4.
-- Totals at "high": launch ~40, projectile ~70/s (the jet), impact ~60.
-- luacheck: read_globals core vector minemon

local R = {}

local ZERO = { x = 0, y = 0, z = 0 }

-- Launch: a fan of flame tongues thrown along the line of fire, with a short flash at the mouth.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 1.0, life = 0.12 })
	F.emit({
		amount = 20, time = 0.05, pos = c.from,
		vel = { min = vector.add(vector.multiply(c.dir, 6), { x = -0.5, y = 0, z = -0.5 }),
			max = vector.add(vector.multiply(c.dir, 9), { x = 0.5, y = 0.5, z = 0.5 }) },
		exptime = { min = 0.25, max = 0.4 }, size = { min = 0.35, max = 0.5 },
		texture = F.tex(F.TEX.flame, { blend = "add", anim = "flame", grow = { 1, 0.5 } }), glow = 14,
	})
	F.sound("fire_fire", { pos = c.from, gain = 0.6, pitch = 0.8 })
end

-- The jet: the orb itself is hidden; flame tongues are left in its wake, thick and tall, and sooty smoke rises off
-- the stream. Returns true: decorated.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.TEX.blank }, visual_size = { x = 0.1, y = 0.1 }, glow = 0 })
	F.on(c.obj, {
		amount = 110, time = 1.5,
		pos = { min = { x = -0.1, y = -0.1, z = -0.1 }, max = { x = 0.1, y = 0.1, z = 0.1 } },
		vel = { min = { x = -0.25, y = 0, z = -0.25 }, max = { x = 0.25, y = 0.35, z = 0.25 } },
		exptime = { min = 0.2, max = 0.35 }, size = { min = 0.4, max = 0.6 },
		texture = F.tex(F.TEX.flame, { blend = "add", anim = "flame", grow = { 1, 0.3 } }), vertical = false, glow = 14,
	})
	F.on(c.obj, {
		amount = 10, time = 1.5, pos = ZERO,
		vel = { min = { x = -0.2, y = 0.3, z = -0.2 }, max = { x = 0.2, y = 0.7, z = 0.2 } },
		exptime = { min = 0.6, max = 1.0 }, size = { min = 0.35, max = 0.5 },
		texture = F.tex(F.tint(F.TEX.smoke, c.palette.smoke), { blend = "alpha", alpha = 0.35, anim = "smoke" }),
	})
	return true
end

-- Impact: the victim catches fire. Flames climb round its body for a second, a short blast at the hit and a scorch.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = "#ffffff", size = 1.0, life = 0.1 })
	F.blast({ pos = at, size = 0.9, life = 0.35 })
	if c.victim and c.victim:get_pos() then
		F.on(c.victim, {
			amount = 24, time = 1.0,
			pos = { min = { x = -0.3, y = 0.1, z = -0.3 }, max = { x = 0.3, y = 1.0, z = 0.3 } },
			vel = { min = { x = 0, y = 0.6, z = 0 }, max = { x = 0, y = 1.4, z = 0 } },
			exptime = { min = 0.35, max = 0.55 }, size = { min = 0.4, max = 0.6 },
			texture = F.tex(F.TEX.flame, { blend = "add", anim = "flame" }), vertical = true, glow = 14,
		})
	end
	F.decal({ pos = at, tex = F.TEX.scorch, size = 1.5, life = 8 })
	F.sound("fire_fire", { pos = at, gain = 0.7, pitch = 1.0 })
end

minemon.fx.register_move("flamethrower", R)
