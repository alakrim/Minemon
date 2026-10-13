-- Vine Whip (M2.1 wave 2, group B, power 35, grass): a lash. The orb is a green vine tip, a tall thin tendril that
-- stands upright and whips through the air with a few leaves shed behind it; on the hit a crescent slash cracks across
-- the victim and a handful of leaves snap off it. Weak: small and quick. Razor Leaf is a storm of leaves; this is one
-- tendril and one snap.
-- Budget at "high": launch ~12, projectile ~25/s, impact ~25.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	tendril = "minemon_fx_tendril.png",
	slash = "minemon_fx_slash.png",
	leaf = "minemon_fx_leaf_spin_anim.png",
}
local LEAF_ANIM = { type = "vertical_frames", aspect_w = 32, aspect_h = 32, length = -1 }
local ZERO = { x = 0, y = 0, z = 0 }

local function leaf(F, colour, o)
	local t = F.tex(F.tint(TEX.leaf, colour), o)
	t.animation = LEAF_ANIM
	return t
end

-- The flick: a crescent at the muzzle and a couple of leaves.
function R.launch(F, c)
	F.emit({
		amount = 1, time = 0.02, pos = c.from, vel = ZERO, exptime = 0.12, size = 0.9,
		texture = F.tex(F.tint(TEX.slash, c.palette.core), { blend = "add", fade = true, grow = { 0.6, 1.0 } }),
		glow = 14,
	})
	F.emit({
		amount = 3, time = 0.03, pos = c.from,
		vel = { min = vector.multiply(c.dir, 2), max = vector.multiply(c.dir, 4) },
		exptime = { min = 0.2, max = 0.3 }, size = { min = 0.12, max = 0.16 },
		texture = leaf(F, c.palette.main, { blend = "alpha", fade = { 1, 0.5 } }), glow = 4,
	})
	F.sound("default_dig_snappy", { pos = c.from, gain = 0.5, pitch = 2.0 })
end

-- The tip: an upright vine tendril (the body) and a few leaves shed behind it.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.tendril, c.palette.main) }, visual_size = { x = 0.42, y = 1.0 },
		glow = 4 })
	F.on(c.obj, {
		amount = 10, time = 1.5, pos = { min = { x = -0.05, y = -0.1, z = -0.05 }, max = { x = 0.05, y = 0.1, z = 0.05 } },
		vel = { min = { x = -0.3, y = -0.2, z = -0.3 }, max = { x = 0.3, y = 0.3, z = 0.3 } },
		drag = { x = 1.0, y = 0.6, z = 1.0 }, exptime = { min = 0.2, max = 0.35 }, size = { min = 0.12, max = 0.16 },
		texture = leaf(F, c.palette.main, { blend = "alpha", fade = { 1, 0.4 } }), glow = 4,
	})
	return true
end

-- The snap: a green crescent cracks across the victim, and six leaves snap off it in a fan.
function R.impact(F, c)
	local at = c.pos
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.16, size = 1.4,
		texture = F.tex(F.tint(TEX.slash, c.palette.main), { blend = "add", fade = true, grow = { 0.6, 1.0 } }),
		glow = 14,
	})
	F.emit({
		amount = 6, time = 0.04, pos = at,
		vel = { min = { x = -2.0, y = 0.5, z = -1.0 }, max = { x = 2.0, y = 2.0, z = 1.0 } },
		acc = { x = 0, y = -4, z = 0 }, exptime = { min = 0.4, max = 0.7 }, size = { min = 0.13, max = 0.18 },
		texture = leaf(F, c.palette.main, { blend = "alpha", fade = { 1, 0.5 } }), glow = 4,
	})
	F.flare({ pos = at, colour = c.palette.core, size = 0.9, life = 0.1 })
	F.sound("default_dig_snappy", { pos = at, gain = 0.7, pitch = 1.7 })
end

minemon.fx.register_move("vine_whip", R)
