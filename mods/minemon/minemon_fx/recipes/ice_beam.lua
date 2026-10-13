-- Ice Beam (M2.1, T-FX-a, signature ice move): a frost crystal flies from the mouth and leaves a trail of pale
-- glints and shards that tumble down. On a hit it shatters into shards and freezes the ground under it. Budget:
-- launch ~30, projectile ~40/s, impact ~120. Cast, beam, melee and area come from type:ice.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	frost = "minemon_fx_frost.png",
	shard = "minemon_fx_shard.png",
	mote = "minemon_fx_mote.png",
	frost_decal = "minemon_fx_frost_decal.png",
	glow = "minemon_fx_glow.png",
}
local ZERO = { x = 0, y = 0, z = 0 }
local GRAVITY = { x = 0, y = -9.8, z = 0 }

-- A crystal flash at the muzzle: a fan of shards thrown forward.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 1.0 })
	F.emit({
		amount = 14, time = 0.05, pos = c.from,
		vel = { min = vector.add(vector.multiply(c.dir, 4), { x = -1, y = 0, z = -1 }),
			max = vector.add(vector.multiply(c.dir, 7), { x = 1, y = 0.8, z = 1 }) },
		acc = GRAVITY, exptime = { min = 0.3, max = 0.6 }, size = { min = 0.16, max = 0.26 },
		texture = F.tex(F.tint(TEX.shard, c.palette.main), { blend = "alpha", fade = true }),
		collisiondetection = true, bounce = { min = 0.2, max = 0.4 }, glow = 6,
	})
	F.sound("default_ice_dig", { pos = c.from, gain = 0.6, pitch = 1.2 })
end

-- The orb: a frost crystal with a pale glow; a trail of glints and tumbling shards; a faint cold wake.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.frost, c.palette.core) }, visual_size = { x = 0.9, y = 0.9 },
		glow = 10 })
	F.on(c.obj, {
		amount = 26, time = 1.5, pos = { min = { x = -0.1, y = -0.1, z = -0.1 }, max = { x = 0.1, y = 0.1, z = 0.1 } },
		vel = { min = { x = -0.3, y = -0.2, z = -0.3 }, max = { x = 0.3, y = 0.3, z = 0.3 } },
		exptime = { min = 0.4, max = 0.7 }, size = { min = 0.12, max = 0.2 },
		texture = F.tex(F.tint(TEX.mote, c.palette.core), { blend = "add", fade = true }), glow = 10,
	})
	F.on(c.obj, {
		amount = 12, time = 1.5, pos = { x = 0, y = 0, z = 0 },
		vel = { min = { x = -0.4, y = 0, z = -0.4 }, max = { x = 0.4, y = 0.4, z = 0.4 } }, acc = { x = 0, y = -5, z = 0 },
		exptime = { min = 0.6, max = 1.0 }, size = { min = 0.18, max = 0.26 },
		texture = F.tex(F.tint(TEX.shard, c.palette.main), { blend = "alpha", fade = true }), glow = 6,
	})
	F.on(c.obj, {
		amount = 6, time = 1.5, pos = { x = 0, y = 0, z = 0 }, vel = ZERO,
		exptime = { min = 0.9, max = 1.2 }, size = { min = 0.4, max = 0.6 },
		texture = F.tex(F.tint(TEX.glow, c.palette.smoke), { blend = "alpha", alpha = 0.25, fade = true }), glow = 4,
	})
	return true
end

-- The hit: the crystal shatters into shards that bounce, a glint flash, a frost patch that stays on the ground.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.3 })
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.35, size = 1.2,
		texture = F.tex(F.tint(TEX.frost, c.palette.core), { blend = "add", fade = true, grow = { 0.8, 1.3 } }),
		glow = 10,
	})
	F.burst({ pos = at, tex = TEX.shard, colour = c.palette.main, amount = 32, speed = 5, radius = 0.15,
		life = { 0.4, 0.8 }, size = { 0.16, 0.26 }, gravity = 9.8, collide = true, bounce = 0.35, blend = "alpha",
		glow = 6 })
	F.burst({ pos = at, tex = TEX.mote, colour = c.palette.core, amount = 18, speed = 3, life = { 0.3, 0.6 },
		size = { 0.12, 0.2 }, glow = 10 })
	F.decal({ pos = at, tex = F.tint(TEX.frost_decal, c.palette.main), size = 1.8, life = 7 })
	F.sound("default_break_glass", { pos = at, gain = 0.8, pitch = 1.1 })
end

minemon.fx.register_move("ice_beam", R)
