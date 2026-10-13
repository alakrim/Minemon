-- Ice Punch (M2.1 wave 2, group B, power 75, freeze 10%): a frozen fist. The orb is a pale crystal glow with spinning
-- shards that peel off it; on the hit a big frost crystal (a snowflake) stamps onto the victim's body and fades, and
-- the shards shatter outward and fall. Medium-strong. The ice type is a shard storm and a frost patch; this move is the
-- one crystal, stamped on the body.
-- Budget at "high": launch ~25, projectile ~45/s, impact ~80.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	frost = "minemon_fx_frost.png",
	shard = "minemon_fx_shard_spin_anim.png",
	glow = "minemon_fx_glow.png",
	flare = "minemon_fx_flare.png",
}
local SHARD_ANIM = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = -1 }
local ZERO = { x = 0, y = 0, z = 0 }
local GRAV = { x = 0, y = -9.8, z = 0 }

local function shard(F, colour, o)
	local t = F.tex(F.tint(TEX.shard, colour), o)
	t.animation = SHARD_ANIM
	return t
end

-- The shot: a crystal flash at the muzzle and three shards thrown forward.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9, life = 0.12 })
	F.emit({
		amount = 6, time = 0.04, pos = c.from,
		vel = { min = vector.multiply(c.dir, 4), max = vector.multiply(c.dir, 6) },
		acc = GRAV, exptime = { min = 0.3, max = 0.5 }, size = { min = 0.2, max = 0.28 },
		texture = shard(F, c.palette.main, { blend = "alpha", fade = { 1, 0.6 } }), glow = 4,
	})
	F.sound("default_glass_footstep", { pos = c.from, gain = 0.6, pitch = 0.7 })
end

-- The orb: a pale crystal glow; shards peel off it, spin and fall.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.glow, c.palette.main) }, visual_size = { x = 0.6, y = 0.6 },
		glow = 10 })
	F.on(c.obj, {
		amount = 16, time = 1.5, pos = { min = { x = -0.1, y = -0.1, z = -0.1 }, max = { x = 0.1, y = 0.1, z = 0.1 } },
		vel = { min = { x = -0.5, y = -0.3, z = -0.5 }, max = { x = 0.5, y = 0.5, z = 0.5 } },
		acc = GRAV, exptime = { min = 0.4, max = 0.7 }, size = { min = 0.2, max = 0.3 },
		texture = shard(F, c.palette.main, { blend = "alpha", fade = { 1, 0.6 } }), glow = 4,
	})
	F.on(c.obj, {
		amount = 8, time = 1.5, pos = ZERO, vel = ZERO,
		exptime = { min = 0.2, max = 0.3 }, size = { min = 0.6, max = 0.8 },
		texture = F.tex(F.tint(TEX.glow, c.palette.core), { blend = "add", fade = true }), glow = 10,
	})
	return true
end

-- The stamp: a frost crystal on the victim that grows and fades, a white glint, and shards that shatter outward.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.0, life = 0.12 })
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.7, size = 1.6,
		texture = F.tex(F.tint(TEX.frost, c.palette.main), { blend = "alpha", fade = true, grow = { 0.6, 1.1 } }),
		glow = 6,
	})
	F.burst({ pos = at, tex = TEX.glow, colour = c.palette.core, amount = 8, speed = 3, radius = 0.15,
		life = { 0.2, 0.35 }, size = { 0.1, 0.16 }, glow = 10 })
	F.emit({
		amount = 14, time = 0.05, pos = at,
		vel = { min = { x = -2.2, y = 0.4, z = -2.2 }, max = { x = 2.2, y = 2.2, z = 2.2 } },
		acc = GRAV, exptime = { min = 0.4, max = 0.7 }, size = { min = 0.22, max = 0.34 },
		collisiondetection = true, bounce = { min = 0.2, max = 0.3 },
		texture = shard(F, c.palette.main, { blend = "alpha", fade = { 1, 0.5 } }), glow = 4,
	})
	F.sound("default_glass_footstep", { pos = at, gain = 0.8, pitch = 0.6 })
end

minemon.fx.register_move("ice_punch", R)
