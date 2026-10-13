-- Water (M2.1, T-FX-a): the type recipe. Droplets with gravity and bounce, foam rings that spread on the ground,
-- bubbles that rise, a puddle that stays for a few seconds. Every water move without a recipe of its own looks like
-- this. Budget at "high" (docs/ART_GUIDE.md section 4): cast ~35, launch ~20, projectile ~35/s, impact ~110, area
-- ~150.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	droplet = "minemon_fx_droplet.png",
	bubble = "minemon_fx_bubble.png",
	foam = "minemon_fx_foam.png",
	puddle = "minemon_fx_puddle.png",
	streak = "minemon_fx_streak.png",
}
local ZERO = { x = 0, y = 0, z = 0 }
local ORIGIN = { x = 0, y = 0, z = 0 }

local function box(p, r)
	return { min = { x = p.x - r, y = p.y - r, z = p.z - r }, max = { x = p.x + r, y = p.y + r, z = p.z + r } }
end

-- A foam ring spreading flat on the ground around pos (alpha blend, grows over life seconds).
local function foam_ring(F, pos, colour, size, grow, life)
	return F.emit({
		amount = 1, time = 0.02, pos = pos, vel = ZERO, exptime = life, size = size,
		texture = F.tex(F.tint(TEX.foam, colour), { blend = "alpha", fade = true, grow = { 0.5, grow } }),
		glow = 4,
	})
end

-- Wind-up: droplets are drawn into the mouth, bubbles rise from it.
function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.5)
	F.inhale({ pos = at, tex = TEX.droplet, colour = c.palette.main, radius = 0.9, amount = 24, time = t,
		size = { 0.07, 0.12 } })
	F.emit({
		amount = 10, time = t, pos = box(at, 0.12),
		vel = { min = { x = -0.1, y = 0.4, z = -0.1 }, max = { x = 0.1, y = 0.9, z = 0.1 } },
		exptime = { min = 0.5, max = 0.9 }, size = { min = 0.1, max = 0.18 },
		texture = F.tex(F.tint(TEX.bubble, c.palette.main), { blend = "alpha", alpha = 0.8 }), glow = 8,
	})
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t + 0.05, size = 0.7,
		texture = F.tex(F.tint("minemon_fx_glow.png", c.palette.main), { blend = "add", grow = { 0.2, 1.0 },
			alpha = 0.7 }),
		glow = 10,
	})
end

-- Launch: a flash at the muzzle and a jet of droplets that falls back after the shot.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9 })
	F.emit({
		amount = 16, time = 0.05, pos = c.from,
		vel = { min = vector.multiply(c.dir, 3), max = vector.add(vector.multiply(c.dir, 6), { x = 0, y = 1.2, z = 0 }) },
		acc = { x = 0, y = -9.8, z = 0 }, exptime = { min = 0.35, max = 0.7 }, size = { min = 0.07, max = 0.14 },
		texture = F.tex(F.tint(TEX.droplet, c.palette.main), { blend = "alpha", fade = true }),
		collisiondetection = true, bounce = { min = 0.2, max = 0.4 }, glow = 8,
	})
	F.sound("watersplash", { pos = c.from, gain = 0.5, pitch = 1.3 })
end

-- The orb: a glowing bead of the type's colour that drips droplets (gravity, bounce) and leaves bubbles behind.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(F.TEX.glow, c.palette.main) }, visual_size = { x = 0.6, y = 0.6 } })
	F.on(c.obj, {
		amount = 30, time = 1.5, pos = box(ORIGIN, 0.08), vel = { min = { x = -0.3, y = -0.3, z = -0.3 },
			max = { x = 0.3, y = 0.3, z = 0.3 } },
		acc = { x = 0, y = -9.8, z = 0 }, exptime = { min = 0.45, max = 0.8 }, size = { min = 0.08, max = 0.14 },
		texture = F.tex(F.tint(TEX.droplet, c.palette.main), { blend = "alpha", fade = true }),
		collisiondetection = true, bounce = { min = 0.2, max = 0.35 }, glow = 8,
	})
	F.on(c.obj, {
		amount = 14, time = 1.5, pos = ORIGIN, vel = { min = { x = -0.2, y = 0.2, z = -0.2 },
			max = { x = 0.2, y = 0.6, z = 0.2 } },
		exptime = { min = 0.5, max = 0.9 }, size = { min = 0.1, max = 0.2 },
		texture = F.tex(F.tint(TEX.bubble, c.palette.main), { blend = "alpha", alpha = 0.7, fade = true }), glow = 6,
	})
	return true
end

-- Beam: a jet of droplets along the line, a bright core of spray and a splash at the stop point.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 24
	local dir = vector.multiply(d, 1 / len)
	F.emit({
		amount = 60, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		jitter = { min = { x = -0.4, y = -0.4, z = -0.4 }, max = { x = 0.4, y = 0.4, z = 0.4 } },
		size = { min = 0.1, max = 0.18 },
		texture = F.tex(F.tint(TEX.droplet, c.palette.main), { blend = "alpha", fade = true }), glow = 8,
	}, c.from)
	F.emit({
		amount = 30, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = { min = 0.2, max = 0.3 },
		texture = F.tex(F.tint(TEX.streak, c.palette.core), { blend = "add" }), vertical = false, glow = 10,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9 })
	foam_ring(F, c.to, c.palette.core, 0.7, 2.2, 0.4)
end

-- Melee: a curved whip of spray in front of the user, droplets flung forward and down.
function R.melee(F, c)
	for i = -2, 2 do
		local bulge = 0.45 - 0.08 * math.abs(i)
		local p = vector.add(c.centre, { x = c.fwd.x * bulge, y = i * 0.22, z = c.fwd.z * bulge })
		F.emit({
			amount = 5, time = 0.12, pos = p,
			vel = { min = vector.multiply(c.fwd, 1.5), max = vector.multiply(c.fwd, 3) },
			acc = { x = 0, y = -9.8, z = 0 }, exptime = { min = 0.3, max = 0.5 }, size = { min = 0.1, max = 0.16 },
			texture = F.tex(F.tint(TEX.droplet, c.palette.main), { blend = "alpha", fade = true }), glow = 8,
		})
	end
end

-- Area: a wave that spreads over the ground: a foam ring, droplets that splash down and a puddle that stays.
function R.area(F, c)
	foam_ring(F, c.centre, c.palette.core, 0.6, c.radius * 2, 0.7)
	F.burst({ pos = c.centre, tex = TEX.droplet, colour = c.palette.main, amount = 36, speed = c.radius * 1.8,
		radius = 0.3, life = { 0.4, 0.8 }, size = { 0.1, 0.18 }, gravity = 9.8, collide = true, bounce = 0.3,
		blend = "alpha", glow = 8 })
	F.decal({ pos = c.centre, tex = F.tint(TEX.puddle, c.palette.main), size = c.radius * 1.6, life = 4 })
	F.sound("watersplash", { pos = c.centre, gain = 0.8 })
end

-- Impact in layers: a catch light, a splash crown of droplets that bounce, foam rings, bubbles, drips from the
-- victim, a mist and a small puddle that stays.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.05 })
	F.burst({ pos = at, tex = TEX.droplet, colour = c.palette.main, amount = 40, speed = 4, radius = 0.15,
		life = { 0.4, 0.8 }, size = { 0.09, 0.16 }, gravity = 9.8, collide = true, bounce = 0.3, blend = "alpha",
		glow = 8 })
	foam_ring(F, at, c.palette.core, 0.5, 3.0, 0.45)
	F.emit({
		amount = 14, time = 0.25, pos = box(at, 0.2),
		vel = { min = { x = -0.2, y = 0.6, z = -0.2 }, max = { x = 0.2, y = 1.4, z = 0.2 } },
		exptime = { min = 0.6, max = 1.0 }, size = { min = 0.12, max = 0.22 },
		texture = F.tex(F.tint(TEX.bubble, c.palette.main), { blend = "alpha", alpha = 0.8, fade = true }), glow = 6,
	})
	F.smoke({ pos = at, colour = c.palette.smoke, amount = 6, size = { 0.5, 0.8 }, life = { 0.8, 1.2 }, rise = 0.6,
		alpha = 0.35, time = 0.3 })
	if c.victim and c.victim:get_pos() then
		F.on(c.victim, {
			amount = 10, time = 0.6,
			pos = { min = { x = -0.25, y = 0.2, z = -0.25 }, max = { x = 0.25, y = 0.8, z = 0.25 } },
			vel = { x = 0, y = -0.5, z = 0 }, acc = { x = 0, y = -9.8, z = 0 },
			exptime = { min = 0.3, max = 0.5 }, size = { min = 0.07, max = 0.12 },
			texture = F.tex(F.tint(TEX.droplet, c.palette.main), { blend = "alpha", fade = true }), glow = 8,
		})
	end
	F.decal({ pos = at, tex = F.tint(TEX.puddle, c.palette.main), size = 1.4, life = 5 })
	F.sound("watersplash", { pos = at, gain = 0.8 })
end

minemon.fx.register_move("type:water", R)
