-- Ice (M2.1, T-FX-a): the type recipe. Sharp shards that tumble and bounce, frost crystals and motes that drift, a
-- cold mist, and a frost patch on the ground that stays. Budget at "high" (docs/ART_GUIDE.md section 4): cast ~40,
-- launch ~30, projectile ~35/s, impact ~110, area ~170.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	shard = "minemon_fx_shard.png",
	frost = "minemon_fx_frost.png",
	frost_decal = "minemon_fx_frost_decal.png",
	mote = "minemon_fx_mote.png",
	glow = "minemon_fx_glow.png",
	smoke = "minemon_fx_smoke_anim.png",
}
local ZERO = { x = 0, y = 0, z = 0 }
local ORIGIN = { x = 0, y = 0, z = 0 }
local GRAVITY = { x = 0, y = -9.8, z = 0 }

local function box(p, r)
	return { min = { x = p.x - r, y = p.y - r, z = p.z - r }, max = { x = p.x + r, y = p.y + r, z = p.z + r } }
end

-- A ring of cold mist on the ground (alpha blend, flipbook smoke tinted pale blue).
local function mist(F, pos, colour, amount, life)
	F.smoke({ pos = pos, colour = colour, amount = amount, size = { 0.5, 0.8 }, life = { life * 0.8, life },
		rise = 0.25, alpha = 0.35, time = 0.3 })
end

-- Wind-up: frost motes are drawn into the mouth and a cold breath drifts out of it.
function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.5)
	F.inhale({ pos = at, tex = TEX.frost, colour = c.palette.main, radius = 1.0, amount = 20, time = t,
		size = { 0.1, 0.16 } })
	F.emit({
		amount = 12, time = t, pos = box(at, 0.15),
		vel = { min = { x = -0.15, y = 0.1, z = -0.15 }, max = { x = 0.15, y = 0.4, z = 0.15 } },
		exptime = { min = 0.4, max = 0.7 }, size = { min = 0.12, max = 0.2 },
		texture = F.tex(F.tint(TEX.mote, c.palette.core), { blend = "add", fade = true }), glow = 10,
	})
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t + 0.05, size = 0.7,
		texture = F.tex(F.tint(TEX.glow, c.palette.main), { blend = "add", grow = { 0.2, 1.0 }, alpha = 0.7 }),
		glow = 10,
	})
	F.smoke({ pos = at, colour = c.palette.smoke, amount = 5, size = { 0.2, 0.36 }, life = { 0.5, 0.8 }, rise = 0.3,
		alpha = 0.4, time = t })
end

-- Launch: a pale flash and shards thrown forward that tumble down.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.8 })
	F.emit({
		amount = 8, time = 0.05, pos = c.from,
		vel = { min = vector.add(vector.multiply(c.dir, 3), { x = -0.5, y = 0, z = -0.5 }),
			max = vector.add(vector.multiply(c.dir, 6), { x = 0.5, y = 1, z = 0.5 }) },
		acc = GRAVITY, exptime = { min = 0.3, max = 0.6 }, size = { min = 0.15, max = 0.24 },
		texture = F.tex(F.tint(TEX.shard, c.palette.main), { blend = "alpha", fade = true }),
		collisiondetection = true, bounce = { min = 0.2, max = 0.4 }, glow = 6,
	})
	F.sound("default_ice_dig", { pos = c.from, gain = 0.5, pitch = 1.4 })
end

-- The orb: a frost crystal that glints, a cold trail of drifting motes and shards that tumble after it.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.frost, c.palette.main) }, visual_size = { x = 0.7, y = 0.7 } })
	F.on(c.obj, {
		amount = 30, time = 1.5, pos = box(ORIGIN, 0.1),
		vel = { min = { x = -0.2, y = -0.1, z = -0.2 }, max = { x = 0.2, y = 0.3, z = 0.2 } },
		exptime = { min = 0.4, max = 0.7 }, size = { min = 0.12, max = 0.2 },
		texture = F.tex(F.tint(TEX.mote, c.palette.core), { blend = "add", fade = true }), glow = 10,
	})
	F.on(c.obj, {
		amount = 10, time = 1.5, pos = ORIGIN, vel = { min = { x = -0.3, y = 0, z = -0.3 },
			max = { x = 0.3, y = 0.3, z = 0.3 } },
		acc = { x = 0, y = -4, z = 0 }, exptime = { min = 0.4, max = 0.8 }, size = { min = 0.15, max = 0.22 },
		texture = F.tex(F.tint(TEX.shard, c.palette.main), { blend = "alpha", fade = true }), glow = 6,
	})
	F.on(c.obj, {
		amount = 6, time = 1.5, pos = ORIGIN, vel = { x = 0, y = 0.1, z = 0 }, exptime = { min = 0.9, max = 1.3 },
		size = { min = 0.6, max = 0.9 },
		texture = F.tex(F.tint(TEX.smoke, c.palette.smoke), { blend = "alpha", alpha = 0.3, anim = "smoke" }),
	})
	return true
end

-- Beam: a cold ray: a pale core with glints drifting along it and shards at the stop point.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 40
	local dir = vector.multiply(d, 1 / len)
	F.emit({
		amount = 50, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = { min = 0.2, max = 0.3 },
		texture = F.tex(F.tint(TEX.glow, c.palette.main), { blend = "add" }), glow = 10,
	}, c.from)
	F.emit({
		amount = 30, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		jitter = { min = { x = -0.3, y = -0.3, z = -0.3 }, max = { x = 0.3, y = 0.3, z = 0.3 } },
		size = { min = 0.1, max = 0.18 },
		texture = F.tex(F.tint(TEX.mote, c.palette.core), { blend = "add", fade = true }), glow = 10,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9 })
	F.flare({ pos = c.to, colour = c.palette.core, size = 1.1, life = 0.3 })
	F.burst({ pos = c.to, tex = TEX.shard, colour = c.palette.main, amount = 12, speed = 4, life = { 0.3, 0.6 },
		size = { 0.12, 0.2 }, gravity = 9.8, collide = true, bounce = 0.3, blend = "alpha", glow = 6 })
end

-- Melee: a glittering arc of frost, shards flung forward.
function R.melee(F, c)
	for i = -2, 2 do
		local bulge = 0.45 - 0.08 * math.abs(i)
		local p = vector.add(c.centre, { x = c.fwd.x * bulge, y = i * 0.22, z = c.fwd.z * bulge })
		F.emit({
			amount = 4, time = 0.12, pos = p,
			vel = { min = vector.multiply(c.fwd, 1.2), max = vector.multiply(c.fwd, 2.5) },
			acc = GRAVITY, exptime = { min = 0.25, max = 0.45 }, size = { min = 0.14, max = 0.22 },
			texture = F.tex(F.tint(TEX.shard, c.palette.main), { blend = "alpha", fade = true }), glow = 6,
		})
	end
	F.emit({
		amount = 6, time = 0.15, pos = box(c.centre, 0.4), vel = ZERO, exptime = { min = 0.3, max = 0.5 },
		size = { min = 0.1, max = 0.18 },
		texture = F.tex(F.tint(TEX.mote, c.palette.core), { blend = "add", fade = true }), glow = 10,
	})
end

-- Area: a frost ring spreads over the ground, shards burst out and a cold mist hangs where it landed.
function R.area(F, c)
	F.ring({ pos = c.centre, colour = c.palette.core, size = 0.5, grow = c.radius * 1.5, life = 0.45 })
	F.burst({ pos = c.centre, tex = TEX.shard, colour = c.palette.main, amount = 30, speed = c.radius * 1.6,
		radius = 0.3, life = { 0.4, 0.8 }, size = { 0.14, 0.24 }, gravity = 9.8, collide = true, bounce = 0.3,
		blend = "alpha", glow = 6 })
	F.decal({ pos = c.centre, tex = F.tint(TEX.frost_decal, c.palette.main), size = c.radius * 1.4, life = 6 })
	mist(F, c.centre, c.palette.smoke, 6, 2.0)
end

-- Impact in layers: a pale catch light, a burst of shards that bounce, a frost crystal flash, a mist and a frost
-- patch that stays on the ground.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.05 })
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.35, size = 1.0,
		texture = F.tex(F.tint(TEX.frost, c.palette.core), { blend = "add", fade = true, grow = { 0.8, 1.3 } }),
		glow = 10,
	})
	F.burst({ pos = at, tex = TEX.shard, colour = c.palette.main, amount = 24, speed = 4, life = { 0.3, 0.7 },
		size = { 0.14, 0.24 }, gravity = 9.8, collide = true, bounce = 0.3, blend = "alpha", glow = 6 })
	F.burst({ pos = at, tex = TEX.mote, colour = c.palette.core, amount = 16, speed = 3, life = { 0.3, 0.6 },
		size = { 0.12, 0.2 }, glow = 10 })
	F.ring({ pos = at, colour = c.palette.edge, size = 0.3, grow = 2.5, life = 0.3 })
	mist(F, at, c.palette.smoke, 5, 1.5)
	F.decal({ pos = at, tex = F.tint(TEX.frost_decal, c.palette.main), size = 1.6, life = 7 })
	F.sound("default_break_glass", { pos = at, gain = 0.7 })
end

minemon.fx.register_move("type:ice", R)
