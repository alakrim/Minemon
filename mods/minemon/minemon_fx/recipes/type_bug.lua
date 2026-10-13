-- Bug type (M2.1, T-FX-b): every bug move without a recipe of its own. A buzzing swarm of dots that jitter, and chitin
-- shards that spin. Five beats: the swarm is drawn into the mouth; shards flick out of the muzzle; the projectile is a
-- humming core with a jittering trail; the impact throws spinning shards with gravity and a swarm round the victim; the
-- aftermath is the default cloud and aura. Budget (docs/ART_GUIDE.md): cast 80, launch 60, projectile 90/s, impact
-- 160, area 200, beam 160.
-- luacheck: read_globals core vector minemon

local R = {}

local SHARD = "minemon_fx_shard_spin_anim.png" -- 4 frames of 16 px: a chitin shard, spinning in the picture plane
local SPEED = "minemon_fx_speedline.png" -- a tapered horizontal streak, for the needles of a beam
local ZERO = { x = 0, y = 0, z = 0 }
local JITTER = { min = { x = -1.5, y = -1.5, z = -1.5 }, max = { x = 1.5, y = 1.5, z = 1.5 } }

-- A spinning shard particle, tinted with the type's main colour.
local function shard(F, colour, o)
	local t = F.tex(F.tint(SHARD, colour), o)
	t.animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = -1 }
	return t
end

-- A radial spray (particles thrown out of pos, as F.burst, with optional jitter and gravity). o: amount, speed (m/s),
-- life {min, max}, size {min, max}, texture (F.tex or shard), time, gravity, jitter, collide, bounce, glow.
local function spray(F, pos, o)
	local speed = o.speed or 4
	return F.emit({
		amount = o.amount, time = o.time or 0.05, pos = pos, radius = { min = 0.1, max = 0.25, bias = 0 },
		attract = { kind = "point", origin = pos, strength = { min = -speed / 0.25 * 0.6, max = -speed / 0.25 },
			die_on_contact = false },
		vel = ZERO, jitter = o.jitter, acc = { x = 0, y = -(o.gravity or 0), z = 0 },
		exptime = { min = o.life[1], max = o.life[2] }, size = { min = o.size[1], max = o.size[2] },
		collisiondetection = o.collide == true, bounce = o.bounce and { min = o.bounce * 0.6, max = o.bounce } or nil,
		texture = o.texture, glow = o.glow or 0,
	})
end

-- Wind-up: the swarm is drawn into the mouth, buzzing; a glow swells there.
function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.emit({
		amount = 24, time = t, pos = at, radius = { min = 0.7, max = 1.2, bias = 0 },
		attract = { kind = "point", origin = at, strength = { min = 2.5, max = 3.5 }, die_on_contact = true },
		vel = ZERO, jitter = JITTER, exptime = { min = 0.25, max = 0.45 }, size = { min = 0.14, max = 0.2 },
		texture = F.tex(F.tint(F.TEX.spark, c.palette.main), { blend = "add", fade = true }), glow = 14,
	})
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t + 0.05, size = 0.7,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add", grow = { 0.2, 1.0 }, alpha = 0.8 }),
		glow = 14,
	})
	F.sound("default_dig_choppy", { pos = at, gain = 0.3, pitch = 1.9 })
end

-- Launch: a white flash, shards flicked out along the shot and a few dots.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9, life = 0.15 })
	F.emit({
		amount = 12, time = 0.05, pos = c.from,
		vel = { min = vector.add(vector.multiply(c.dir, 3), { x = -1, y = -0.5, z = -1 }),
			max = vector.add(vector.multiply(c.dir, 6), { x = 1, y = 1, z = 1 }) },
		acc = { x = 0, y = -6, z = 0 }, exptime = { min = 0.4, max = 0.7 }, size = { min = 0.34, max = 0.46 },
		texture = shard(F, c.palette.main, { blend = "alpha", fade = { 1, 0.5 } }), glow = 0,
	})
	spray(F, c.from, { amount = 12, speed = 3, life = { 0.2, 0.4 }, size = { 0.08, 0.14 }, jitter = JITTER,
		texture = F.tex(F.tint(F.TEX.spark, c.palette.core), { blend = "add", fade = true }), glow = 14 })
	F.sound("mcl_throwing_throw", { pos = c.from, gain = 0.5, pitch = 1.5 })
end

-- The orb: a humming core with a trail of jittering dots and a few shards that spin away.
-- Returns true: decorated.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(F.TEX.glow, c.palette.main) }, visual_size = { x = 0.5, y = 0.5 } })
	F.on(c.obj, {
		amount = 30, time = 1.5, pos = { x = 0, y = 0, z = 0 },
		vel = { min = { x = -0.5, y = -0.5, z = -0.5 }, max = { x = 0.5, y = 0.5, z = 0.5 } }, jitter = JITTER,
		exptime = { min = 0.2, max = 0.35 }, size = { min = 0.1, max = 0.16 },
		texture = F.tex(F.tint(F.TEX.spark, c.palette.core), { blend = "add", fade = true }), glow = 14,
	})
	F.on(c.obj, {
		amount = 14, time = 1.5, pos = { x = 0, y = 0, z = 0 },
		vel = { min = { x = -0.3, y = -0.3, z = -0.3 }, max = { x = 0.3, y = 0.3, z = 0.3 } },
		exptime = { min = 0.4, max = 0.7 }, size = { min = 0.2, max = 0.32 },
		texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add", fade = true, grow = { 1, 0.3 } }),
		glow = 14,
	})
	F.on(c.obj, {
		amount = 6, time = 1.5, pos = { x = 0, y = 0, z = 0 },
		vel = { min = { x = -0.4, y = -0.4, z = -0.4 }, max = { x = 0.4, y = 0.4, z = 0.4 } },
		acc = { x = 0, y = -4, z = 0 }, exptime = { min = 0.5, max = 0.8 }, size = { min = 0.15, max = 0.22 },
		texture = shard(F, c.palette.main, { blend = "alpha", fade = { 1, 0.6 } }), glow = 0,
	})
	return true
end

-- Beam: a line of needles and jittering dots, and a spray of shards where it stops.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 36
	local dir = vector.multiply(d, 1 / len)
	F.emit({
		amount = 40, time = 0.3, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = { min = 0.35, max = 0.55 },
		texture = F.tex(F.tint(SPEED, c.palette.core), { blend = "add", fade = true }), glow = 14,
	}, c.from)
	F.emit({
		amount = 24, time = 0.3, pos = c.from, radius = { min = 0.1, max = 0.3, bias = 0 },
		vel = vector.multiply(dir, speed * 0.9), jitter = JITTER, exptime = len / speed,
		size = { min = 0.1, max = 0.16 },
		texture = F.tex(F.tint(F.TEX.spark, c.palette.main), { blend = "add", fade = true }), glow = 14,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.8 })
	F.flare({ pos = c.to, colour = c.palette.core, size = 1.0, life = 0.25 })
	spray(F, c.to, { amount = 14, speed = 3, life = { 0.3, 0.5 }, size = { 0.1, 0.18 }, jitter = JITTER,
		texture = F.tex(F.tint(F.TEX.spark, c.palette.main), { blend = "add", fade = true }), glow = 14 })
	spray(F, c.to, { amount = 6, speed = 2.5, life = { 0.4, 0.7 }, size = { 0.14, 0.2 }, gravity = 6,
		texture = shard(F, c.palette.main, { blend = "alpha", fade = { 1, 0.5 } }) })
end

-- Melee: a horn of shards swept in front of the user, a swarm of dots round the arc.
function R.melee(F, c)
	for i = -2, 2 do
		local bulge = 0.45 - 0.08 * math.abs(i)
		local p = vector.add(c.centre, { x = c.fwd.x * bulge, y = i * 0.22, z = c.fwd.z * bulge })
		F.emit({
			amount = 4, time = 0.1, pos = p,
			vel = { min = vector.multiply(c.fwd, 2), max = vector.multiply(c.fwd, 3.5) },
			exptime = { min = 0.25, max = 0.4 }, size = { min = 0.36, max = 0.5 },
			texture = shard(F, c.palette.main, { blend = "alpha", fade = { 1, 0.5 } }), glow = 0,
		})
	end
	F.emit({
		amount = 10, time = 0.15, pos = c.centre, radius = { min = 0.3, max = 0.6, bias = 0 }, vel = ZERO,
		jitter = JITTER, exptime = { min = 0.2, max = 0.4 }, size = { min = 0.1, max = 0.16 },
		texture = F.tex(F.tint(F.TEX.spark, c.palette.core), { blend = "add", fade = true }), glow = 14,
	})
end

-- Area: a buzzing burst of dots that spread out with jitter, a ring and shards thrown wide.
function R.area(F, c)
	F.flare({ pos = c.centre, colour = c.palette.core, size = 1.2, life = 0.2 })
	F.ring({ pos = c.centre, colour = c.palette.edge, size = 0.5, grow = c.radius * 1.5, life = 0.4 })
	spray(F, c.centre, { amount = 50, speed = c.radius * 2, life = { 0.4, 0.8 }, size = { 0.1, 0.18 },
		jitter = JITTER, time = 0.1, texture = F.tex(F.tint(F.TEX.spark, c.palette.main),
			{ blend = "add", fade = true }), glow = 14 })
	spray(F, c.centre, { amount = 14, speed = c.radius * 1.4, life = { 0.5, 0.9 }, size = { 0.2, 0.3 },
		gravity = 4, texture = shard(F, c.palette.main, { blend = "alpha", fade = { 1, 0.5 } }) })
end

-- Impact: a flash, shards spun out with gravity and bounce, a swarm of dots round the victim and a ring.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.0, life = 0.12 })
	spray(F, at, { amount = 16, speed = 4, life = { 0.5, 0.9 }, size = { 0.32, 0.46 }, gravity = 8, collide = true,
		bounce = 0.3, texture = shard(F, c.palette.main, { blend = "alpha", fade = { 1, 0.4 } }) })
	spray(F, at, { amount = 20, speed = 2.5, time = 0.2, life = { 0.3, 0.5 }, size = { 0.14, 0.2 },
		jitter = JITTER, texture = F.tex(F.tint(F.TEX.spark, c.palette.core), { blend = "add", fade = true }),
		glow = 14 })
	F.ring({ pos = at, colour = c.palette.edge, size = 0.3, grow = 2.6, life = 0.3 })
	F.sound("default_dig_choppy", { pos = at, gain = 0.7, pitch = 1.4 })
end

minemon.fx.register_move("type:bug", R)
