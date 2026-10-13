-- Fire Punch (M2.1 wave 2, group B, power 75, burn 10%): a burning fist. The muzzle puffs a small flame; the orb is a
-- hot glow with tongues of flame that stream backwards off it, like a fist on fire; the hit is a flame star: six
-- tongues flung out radially from the victim's body, with an orange punch flash. Medium-strong. The fire type is a
-- rising column and a comet; this one is a star that bursts outward.
-- Budget at "high": launch ~25, projectile ~50/s, impact ~70.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	glow = "minemon_fx_glow.png",
	star = "minemon_fx_impact_star.png",
}
local ZERO = { x = 0, y = 0, z = 0 }
local ORIGIN = { x = 0, y = 0, z = 0 }

-- The puff: a small flame from the muzzle and a flash.
function R.launch(F, c)
	F.flames({ pos = c.from, amount = 10, size = { 0.3, 0.45 }, life = { 0.2, 0.35 }, spread = 0.05, rise = 0.4,
		time = 0.05 })
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9, life = 0.14 })
	F.sound("fire_fire", { pos = c.from, gain = 0.5, pitch = 1.5 })
end

-- The fist: a hot orange glow with flame tongues streaming behind it, and a few embers thrown off.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.glow, c.palette.main) }, visual_size = { x = 0.55, y = 0.55 },
		glow = 14 })
	F.on(c.obj, {
		amount = 30, time = 1.5, pos = { min = { x = -0.1, y = -0.1, z = -0.1 }, max = { x = 0.1, y = 0.1, z = 0.1 } },
		vel = { min = { x = -0.2, y = 0.1, z = -0.2 }, max = { x = 0.2, y = 0.5, z = 0.2 } },
		exptime = { min = 0.2, max = 0.34 }, size = { min = 0.3, max = 0.42 },
		texture = F.tex(F.TEX.flame, { blend = "add", anim = "flame", grow = { 1, 0.5 } }), vertical = false, glow = 14,
	})
	F.on(c.obj, {
		amount = 8, time = 1.5, pos = ORIGIN,
		vel = { min = { x = -0.5, y = 0.4, z = -0.5 }, max = { x = 0.5, y = 1.0, z = 0.5 } },
		acc = { x = 0, y = 2, z = 0 }, exptime = { min = 0.3, max = 0.5 }, size = { min = 0.06, max = 0.1 },
		texture = F.tex(F.TEX.ember, { blend = "add", fade = { 1, 0.6 } }), glow = 14,
	})
	return true
end

-- The flame star: an orange star on the victim, six flame tongues flung out from the body and a flash.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.3, life = 0.12 })
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.24, size = 1.9,
		texture = F.tex(F.tint(TEX.star, c.palette.main), { blend = "add", fade = true, grow = { 0.6, 1.2 } }),
		glow = 14,
	})
	for i = 0, 5 do
		local a = i / 6 * 2 * math.pi + 0.3
		local out = { x = math.cos(a), y = 0.3 + math.sin(a) * 0.4, z = math.sin(a) * 0.2 }
		F.emit({
			amount = 3, time = 0.04, pos = at,
			vel = vector.multiply(out, 3.2), acc = { x = 0, y = 1.2, z = 0 },
			exptime = { min = 0.22, max = 0.36 }, size = { min = 0.34, max = 0.46 },
			texture = F.tex(F.TEX.flame, { blend = "add", anim = "flame", grow = { 1, 0.5 } }), vertical = false,
			glow = 14,
		})
	end
	F.embers({ pos = at, amount = 10, speed = 2.5, up = 2 })
	F.sound("fire_fire", { pos = at, gain = 0.7, pitch = 1.1 })
end

minemon.fx.register_move("fire_punch", R)
