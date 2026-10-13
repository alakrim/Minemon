-- Acid (M2.1, T-FX-b, poison, area, 40 power): the signature of poison clouds. Acid is flung out in a spray, then falls
-- back as a rain of drops over the area; bubbles fizz up from it and a toxic puddle stays under the centre.
-- Budget: area ~180 particles, 1 puddle.
-- luacheck: read_globals core vector minemon

local R = {}

local GOO = "minemon_fx_goo.png"
local DROP = "minemon_fx_drop.png"
local PUDDLE = "minemon_fx_toxic_puddle.png"
local ZERO = { x = 0, y = 0, z = 0 }

function R.area(F, c)
	local r = c.radius
	local ctr = c.centre
	F.flare({ pos = ctr, colour = c.palette.core, size = 1.0, life = 0.15 })
	F.ring({ pos = ctr, colour = c.palette.main, size = 0.5, grow = r * 1.3, life = 0.4 })
	-- The spray: goo flung out and up, and falling back with gravity.
	F.emit({
		amount = 40, time = 0.1, pos = ctr, radius = { min = 0.1, max = 0.3, bias = 0 },
		attract = { kind = "point", origin = ctr, strength = { min = -r * 1.4 / 0.25 * 0.6, max = -r * 1.4 / 0.25 },
			die_on_contact = false },
		vel = ZERO, acc = { x = 0, y = -10, z = 0 }, collisiondetection = true, bounce = { min = 0.1, max = 0.2 },
		exptime = { min = 0.5, max = 0.9 }, size = { min = 0.14, max = 0.22 },
		texture = F.tex(F.tint(GOO, c.palette.main), { blend = "alpha", fade = { 1, 0.6 } }), glow = 0,
	})
	-- The rain: drops fall from above the area, each landing as a little splash.
	F.emit({
		amount = 36, time = 0.6,
		pos = { min = vector.add(ctr, { x = -r, y = 2.8, z = -r }), max = vector.add(ctr, { x = r, y = 3.4, z = r }) },
		vel = { min = { x = 0, y = -2, z = 0 }, max = { x = 0, y = -4, z = 0 } }, acc = { x = 0, y = -4, z = 0 },
		vertical = true, collisiondetection = true, exptime = { min = 0.5, max = 0.8 },
		size = { min = 0.14, max = 0.2 }, texture = F.tex(F.tint(DROP, c.palette.main), { blend = "alpha" }), glow = 0,
	})
	-- Bubbles fizz up through the cloud.
	F.emit({
		amount = 20, time = 0.6, pos = ctr, radius = { min = r * 0.4, max = r * 0.9, bias = 0 },
		vel = { min = { x = -0.2, y = 0.6, z = -0.2 }, max = { x = 0.2, y = 1.2, z = 0.2 } },
		exptime = { min = 0.6, max = 1.1 }, size = { min = 0.12, max = 0.22 },
		texture = F.tex(F.tint(F.TEX.ring, c.palette.core), { blend = "alpha", fade = true, grow = { 0.6, 1.2 } }),
		glow = 6,
	})
	F.decal({ pos = ctr, tex = F.tint(PUDDLE, c.palette.main) .. "^[opacity:200", size = r * 1.4, life = 8 })
	F.sound("fire_extinguish_flame", { pos = ctr, gain = 0.6, pitch = 1.8 })
end

minemon.fx.register_move("acid", R)
