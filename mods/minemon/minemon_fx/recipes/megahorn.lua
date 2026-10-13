-- Megahorn (M2.1, T-FX-b, bug, melee, 120 power): the signature of bug. A long horn-shaped slash swept forward with a
-- row of chitin shards; the impact throws a heavy spray of shards, a white crack of light and a shock ring, and a
-- humming swarm round the victim. Budget: melee ~90 particles, impact ~150.
-- luacheck: read_globals core vector minemon

local R = {}

local SHARD = "minemon_fx_shard_spin_anim.png" -- 4 frames of 16 px: a chitin shard, spinning
local SLASH = "minemon_fx_slash.png" -- a crescent melee arc
local ZERO = { x = 0, y = 0, z = 0 }
local JITTER = { min = { x = -1.5, y = -1.5, z = -1.5 }, max = { x = 1.5, y = 1.5, z = 1.5 } }

local function shard(F, colour, o)
	local t = F.tex(F.tint(SHARD, colour), o)
	t.animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = -1 }
	return t
end

-- Shards thrown radially out of pos with gravity and bounce.
local function shards(F, pos, o)
	local speed = o.speed
	F.emit({
		amount = o.amount, time = o.time or 0.05, pos = pos, radius = { min = 0.1, max = 0.3, bias = 0 },
		attract = { kind = "point", origin = pos, strength = { min = -speed / 0.25 * 0.6, max = -speed / 0.25 },
			die_on_contact = false },
		vel = ZERO, acc = { x = 0, y = -(o.gravity or 0), z = 0 },
		exptime = { min = o.life[1], max = o.life[2] }, size = { min = o.size[1], max = o.size[2] },
		collisiondetection = o.collide == true, bounce = o.bounce and { min = o.bounce * 0.6, max = o.bounce } or nil,
		texture = shard(F, o.colour, { blend = "alpha", fade = { 1, 0.5 } }), glow = 0,
	})
end

-- The horn: a long slash swept forward, a row of shards flicked off the arc and a flash at its heart.
function R.melee(F, c)
	local at = vector.add(c.centre, vector.multiply(c.fwd, 0.5))
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.3, size = 2.4,
		texture = F.tex(F.tint(SLASH, c.palette.core), { blend = "add", fade = true, grow = { 0.8, 1.3 } }), glow = 14,
	})
	for i = -2, 2 do
		local bulge = 0.45 - 0.08 * math.abs(i)
		local p = vector.add(c.centre, { x = c.fwd.x * bulge, y = i * 0.22, z = c.fwd.z * bulge })
		F.emit({
			amount = 4, time = 0.1, pos = p, vel = { min = vector.multiply(c.fwd, 3), max = vector.multiply(c.fwd, 5) },
			acc = { x = 0, y = -6, z = 0 }, exptime = { min = 0.3, max = 0.5 }, size = { min = 0.3, max = 0.42 },
			texture = shard(F, c.palette.main, { blend = "alpha", fade = { 1, 0.5 } }), glow = 0,
		})
	end
	F.sound("default_dig_choppy", { pos = c.centre, gain = 0.9, pitch = 0.7 })
end

-- The impact: a white crack of light, a heavy burst of shards with gravity and bounce, a shock ring, and a swarm.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = "#ffffff", size = 2.4, life = 0.16 })
	shards(F, at, { amount = 26, speed = 6, life = { 0.6, 1.0 }, size = { 0.3, 0.5 }, gravity = 9, collide = true,
		bounce = 0.35, colour = c.palette.main })
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.22, size = 2.2,
		texture = F.tex(F.tint(SLASH, c.palette.core), { blend = "add", fade = true, grow = { 0.8, 1.2 } }), glow = 14,
	})
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.22, size = 1.8,
		texture = F.tex(F.tint(SLASH .. "^[transformFX", c.palette.main), { blend = "add", fade = true,
			grow = { 0.8, 1.2 } }), glow = 14,
	})
	F.ring({ pos = at, colour = c.palette.edge, size = 0.6, grow = 4.2, life = 0.4 })
	F.emit({
		amount = 22, time = 0.2, pos = at, radius = { min = 0.2, max = 0.5, bias = 0 },
		vel = ZERO, jitter = JITTER, exptime = { min = 0.4, max = 0.7 }, size = { min = 0.1, max = 0.16 },
		texture = F.tex(F.tint(F.TEX.spark, c.palette.core), { blend = "add", fade = true }), glow = 14,
	})
	F.sound("default_dig_choppy", { pos = at, gain = 1.0, pitch = 0.8 })
end

minemon.fx.register_move("megahorn", R)
