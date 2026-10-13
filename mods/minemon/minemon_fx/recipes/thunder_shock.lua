-- Thunder Shock (M2.1 wave 2, group B, power 40, paralysis 10%): one short jagged bolt, not a storm. The muzzle gives
-- one zig-zag bolt; the orb is a small yellow-white point with a few sparks; the victim takes a single bolt and a
-- quick crackle. Weak: small and quick. Thunder and Thunderbolt keep the big versions of this look.
-- Budget at "high": launch ~12, projectile ~16, impact ~18.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	bolt = "minemon_fx_bolt_anim.png",
	spark = "minemon_fx_spark.png",
	glow = "minemon_fx_glow.png",
}
local BOLT_ANIM = { type = "vertical_frames", aspect_w = 48, aspect_h = 48, length = 0.12 }
local ZERO = { x = 0, y = 0, z = 0 }
local TINY_JIT = { min = { x = -0.3, y = -0.3, z = -0.3 }, max = { x = 0.3, y = 0.3, z = 0.3 } }

local function bolt(F, colour)
	local t = F.tex(F.tint(TEX.bolt, colour), { blend = "add" })
	t.animation = BOLT_ANIM
	return t
end

-- The shot: a single bolt at the muzzle, then a few sparks thrown forward.
function R.launch(F, c)
	F.emit({
		amount = 1, time = 0.02, pos = c.from, vel = ZERO, exptime = 0.14, size = 0.75,
		texture = bolt(F, c.palette.core), glow = 14,
	})
	F.emit({
		amount = 5, time = 0.03, pos = c.from, jitter = TINY_JIT,
		vel = { min = vector.multiply(c.dir, 4), max = vector.multiply(c.dir, 6) },
		exptime = { min = 0.08, max = 0.14 }, size = { min = 0.1, max = 0.14 },
		texture = F.tex(F.tint(TEX.spark, c.palette.main), { blend = "add", fade = true }), glow = 14,
	})
	F.sound("lightning_thunder", { pos = c.from, gain = 0.25, pitch = 2.2 })
end

-- The orb: a small hot point and a thin wake of sparks that die at once.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.glow, c.palette.core) }, visual_size = { x = 0.4, y = 0.4 },
		glow = 14 })
	F.on(c.obj, {
		amount = 12, time = 1.5, pos = ZERO, vel = ZERO, jitter = TINY_JIT,
		exptime = { min = 0.06, max = 0.12 }, size = { min = 0.1, max = 0.14 },
		texture = F.tex(F.tint(TEX.spark, c.palette.main), { blend = "add" }), glow = 14,
	})
	return true
end

-- The hit: one bolt on the victim, a white catch light and a short crackle of sparks.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 0.9, life = 0.1 })
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.14, size = 1.2,
		texture = bolt(F, c.palette.core), glow = 14,
	})
	F.emit({
		amount = 6, time = 0.05, pos = at, jitter = TINY_JIT, vel = ZERO,
		exptime = { min = 0.08, max = 0.16 }, size = { min = 0.1, max = 0.14 },
		texture = F.tex(F.tint(TEX.spark, c.palette.main), { blend = "add" }), glow = 14,
	})
	F.sound("lightning_thunder", { pos = at, gain = 0.4, pitch = 1.9 })
end

minemon.fx.register_move("thunder_shock", R)
