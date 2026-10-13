-- Steel (M2.1, T-FX-a): the type recipe. Bright metal sparks that fall and bounce off the ground, steel chips that
-- tumble, a ringing white flash and a ring of light that rings out. Budget at "high" (docs/ART_GUIDE.md section 4):
-- cast ~40, launch ~40, projectile ~60/s, impact ~120, area ~160.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	spark = "minemon_fx_spark.png",
	chip = "minemon_fx_chip.png",
	streak = "minemon_fx_streak.png",
	glow = "minemon_fx_glow.png",
	ring = "minemon_fx_ring.png",
}
local ZERO = { x = 0, y = 0, z = 0 }
local ORIGIN = { x = 0, y = 0, z = 0 }
local GRAVITY = { x = 0, y = -9.8, z = 0 }

local function box(p, r)
	return { min = { x = p.x - r, y = p.y - r, z = p.z - r }, max = { x = p.x + r, y = p.y + r, z = p.z + r } }
end

-- A metal spark: a hot dot that falls and bounces where it lands.
local function sparks(F, pos, colour, amount, speed, size, life)
	return F.burst({ pos = pos, tex = TEX.spark, colour = colour, amount = amount, speed = speed, radius = 0.2,
		life = life, size = size, gravity = 9.8, collide = true, bounce = 0.5, blend = "add", glow = 14 })
end

-- Wind-up: bright sparks are drawn into the mouth and a steel chip spins in with them.
function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.5)
	F.inhale({ pos = at, tex = TEX.spark, colour = c.palette.core, radius = 1.0, amount = 18, time = t,
		size = { 0.06, 0.1 } })
	F.inhale({ pos = at, tex = TEX.chip, colour = c.palette.main, radius = 1.1, amount = 6, time = t,
		size = { 0.12, 0.18 } })
	F.emit({
		amount = 1, time = t, pos = at, vel = ZERO, exptime = t + 0.05, size = 0.7,
		texture = F.tex(F.tint(TEX.glow, c.palette.core), { blend = "add", grow = { 0.2, 1.0 }, alpha = 0.8 }),
		glow = 14,
	})
	F.sound("default_place_node_metal.1", { pos = at, gain = 0.3, pitch = 1.6 })
end

-- Launch: a ringing white flash and metal sparks thrown forward that bounce.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 1.0 })
	F.emit({
		amount = 14, time = 0.05, pos = c.from,
		vel = { min = vector.multiply(c.dir, 3), max = vector.add(vector.multiply(c.dir, 7), { x = 0, y = 1, z = 0 }) },
		acc = GRAVITY, exptime = { min = 0.3, max = 0.6 }, size = { min = 0.08, max = 0.14 },
		texture = F.tex(F.tint(TEX.spark, c.palette.core), { blend = "add" }),
		collisiondetection = true, bounce = { min = 0.4, max = 0.6 }, glow = 14,
	})
	F.sound("default_dig_metal", { pos = c.from, gain = 0.5, pitch = 1.6 })
end

-- The orb: a steel chip that glows, a trail of sparks that fall and bounce, and chips tumbling after it.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.chip, c.palette.main) }, visual_size = { x = 0.7, y = 0.7 },
		glow = 10 })
	F.on(c.obj, {
		amount = 30, time = 1.5, pos = box(ORIGIN, 0.06),
		vel = { min = { x = -0.5, y = -0.2, z = -0.5 }, max = { x = 0.5, y = 0.5, z = 0.5 } }, acc = GRAVITY,
		exptime = { min = 0.4, max = 0.7 }, size = { min = 0.08, max = 0.14 },
		texture = F.tex(F.tint(TEX.spark, c.palette.core), { blend = "add" }),
		collisiondetection = true, bounce = { min = 0.4, max = 0.6 }, glow = 14,
	})
	F.on(c.obj, {
		amount = 8, time = 1.5, pos = ORIGIN, vel = { min = { x = -0.3, y = 0, z = -0.3 },
			max = { x = 0.3, y = 0.6, z = 0.3 } },
		acc = GRAVITY, exptime = { min = 0.6, max = 1.0 }, size = { min = 0.12, max = 0.2 },
		texture = F.tex(F.tint(TEX.chip, c.palette.main), { blend = "alpha", fade = true }),
		collisiondetection = true, bounce = { min = 0.2, max = 0.3 }, glow = 6,
	})
	return true
end

-- Beam: a bright silver streak with sparks along it and a burst of sparks where it stops.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 40
	local dir = vector.multiply(d, 1 / len)
	F.emit({
		amount = 30, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = { min = 0.25, max = 0.35 },
		texture = F.tex(F.tint(TEX.streak, c.palette.core), { blend = "add" }), vertical = false, glow = 14,
	}, c.from)
	F.emit({
		amount = 40, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		jitter = { min = { x = -0.3, y = -0.3, z = -0.3 }, max = { x = 0.3, y = 0.3, z = 0.3 } },
		size = { min = 0.1, max = 0.16 },
		texture = F.tex(F.tint(TEX.spark, c.palette.main), { blend = "add" }), glow = 14,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9 })
	F.flare({ pos = c.to, colour = c.palette.core, size = 1.2, life = 0.3 })
	sparks(F, c.to, c.palette.main, 20, 4, { 0.08, 0.14 }, { 0.3, 0.6 })
end

-- Melee: three claw slashes of bright sparks, chips flung forward and a white flash at the centre.
function R.melee(F, c)
	for i = -1, 1 do
		local side = vector.new(-c.fwd.z, 0, c.fwd.x)
		local p = vector.add(c.centre, vector.add(vector.multiply(side, i * 0.25), { x = 0, y = -i * 0.12, z = 0 }))
		F.emit({
			amount = 8, time = 0.12, pos = p,
			vel = { min = vector.multiply(c.fwd, 2), max = vector.multiply(c.fwd, 4) }, acc = GRAVITY,
			exptime = { min = 0.3, max = 0.5 }, size = { min = 0.08, max = 0.14 },
			texture = F.tex(F.tint(TEX.spark, c.palette.core), { blend = "add" }),
			collisiondetection = true, bounce = { min = 0.3, max = 0.5 }, glow = 14,
		})
	end
	F.emit({
		amount = 6, time = 0.12, pos = c.centre, vel = { min = vector.multiply(c.fwd, 1.5),
			max = vector.multiply(c.fwd, 3) }, acc = GRAVITY, exptime = { min = 0.4, max = 0.7 },
		size = { min = 0.12, max = 0.2 }, texture = F.tex(F.tint(TEX.chip, c.palette.main), { blend = "alpha",
			fade = true }), collisiondetection = true, bounce = { min = 0.2, max = 0.3 }, glow = 6,
	})
	F.flare({ pos = c.centre, colour = c.palette.core, size = 1.2, life = 0.15 })
end

-- Area: a ringing shock ring, sparks thrown out in every direction, bouncing across the ground, and chips.
function R.area(F, c)
	F.flare({ pos = c.centre, colour = c.palette.core, size = 1.6, life = 0.2 })
	F.ring({ pos = c.centre, colour = c.palette.core, size = 0.6, grow = c.radius * 1.5, life = 0.4 })
	F.ring({ pos = c.centre, colour = c.palette.edge, size = 0.5, grow = c.radius * 1.8, life = 0.6 })
	sparks(F, c.centre, c.palette.core, 36, c.radius * 1.6, { 0.08, 0.16 }, { 0.4, 0.9 })
	F.burst({ pos = c.centre, tex = TEX.chip, colour = c.palette.main, amount = 10, speed = c.radius, radius = 0.3,
		life = { 0.6, 1.0 }, size = { 0.12, 0.2 }, gravity = 9.8, collide = true, bounce = 0.3, blend = "alpha",
		glow = 6 })
	F.sound("mesecons_noteblock_xylophone_metal", { pos = c.centre, gain = 0.4, pitch = 1.2 })
end

-- Impact in layers: a ringing white flash, a burst of bouncing sparks, steel chips, a ring of the type's colour and
-- a bright chime.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 2.0, life = 0.15 })
	F.flare({ pos = at, colour = c.palette.main, size = 1.2, life = 0.3 })
	sparks(F, at, c.palette.core, 28, 4, { 0.08, 0.15 }, { 0.3, 0.6 })
	F.burst({ pos = at, tex = TEX.chip, colour = c.palette.main, amount = 10, speed = 3, radius = 0.15,
		life = { 0.5, 0.9 }, size = { 0.12, 0.2 }, gravity = 9.8, collide = true, bounce = 0.4, blend = "alpha",
		glow = 6 })
	F.ring({ pos = at, colour = c.palette.main, size = 0.4, grow = 2.5, life = 0.3 })
	F.sound("mesecons_noteblock_xylophone_metal", { pos = at, gain = 0.6, pitch = 1.4 })
end

minemon.fx.register_move("type:steel", R)
