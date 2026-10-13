-- Octazooka (M2.1 wave 2, group B, power 65, accuracy 85): an ink cannon. The muzzle coughs a dark navy cloud and a
-- lump of ink; the orb is a solid ink blob that trails a dark spatter and soot. On the hit the ink splats: a dark
-- puddle that stays on the ground, and blobs that burst out and fall. Its look is the dark ink, not water: no bright
-- droplets, no foam crown.
-- Budget at "high": launch ~30, projectile ~50, impact ~60, plus one decal.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	goo = "minemon_fx_goo.png",
	puddle = "minemon_fx_puddle.png",
	foam = "minemon_fx_foam.png",
	smoke = "minemon_fx_smoke_anim.png",
}
local ZERO = { x = 0, y = 0, z = 0 }
local INK = "#1d3566"
local INK_DARK = "#0e1a36"

-- The shot: a dark cloud coughs out of the muzzle and a fat lump of ink flies off with it.
function R.launch(F, c)
	F.smoke({ pos = c.from, colour = INK_DARK, amount = 6, size = { 0.35, 0.5 }, life = { 0.4, 0.6 }, rise = 0.3,
		spread = 0.08, alpha = 0.6, time = 0.05 })
	F.emit({
		amount = 9, time = 0.05, pos = c.from,
		vel = { min = vector.multiply(c.dir, 5), max = vector.multiply(c.dir, 7) },
		acc = { x = 0, y = -4, z = 0 }, exptime = { min = 0.3, max = 0.5 }, size = { min = 0.16, max = 0.26 },
		texture = F.tex(F.tint(TEX.goo, INK), { blend = "alpha", fade = true }), glow = 0,
	})
	F.sound("watersplash", { pos = c.from, gain = 0.6, pitch = 0.7 })
end

-- The orb: a solid navy blob (the goo texture is solid at its centre), with an ink spatter and soot behind it.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.goo, INK) }, visual_size = { x = 0.6, y = 0.6 }, glow = 0 })
	F.on(c.obj, {
		amount = 26, time = 1.5, pos = { min = { x = -0.08, y = -0.08, z = -0.08 }, max = { x = 0.08, y = 0.08, z = 0.08 } },
		vel = { min = { x = -0.3, y = -0.2, z = -0.3 }, max = { x = 0.3, y = 0.3, z = 0.3 } },
		acc = { x = 0, y = -6, z = 0 }, exptime = { min = 0.35, max = 0.6 }, size = { min = 0.1, max = 0.18 },
		texture = F.tex(F.tint(TEX.goo, INK), { blend = "alpha", fade = true }), collisiondetection = true,
		bounce = { min = 0.1, max = 0.2 },
	})
	F.on(c.obj, {
		amount = 10, time = 1.5, pos = ZERO, vel = { x = 0, y = 0.2, z = 0 },
		exptime = { min = 0.5, max = 0.8 }, size = { min = 0.28, max = 0.4 },
		texture = F.tex(F.tint(TEX.smoke, INK_DARK), { blend = "alpha", alpha = 0.4, anim = "smoke" }),
	})
	return true
end

-- The splat: a navy puddle that stays on the ground, blobs that burst out and drop, and a dark ring of ink.
function R.impact(F, c)
	local at = c.pos
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.4, size = 1.1,
		texture = F.tex(F.tint(TEX.foam, INK), { blend = "alpha", fade = true, grow = { 0.4, 1.8 } }), glow = 0,
	})
	F.burst({ pos = at, tex = TEX.goo, colour = INK, amount = 16, speed = 4, radius = 0.15, life = { 0.35, 0.7 },
		size = { 0.14, 0.24 }, gravity = 9.8, collide = true, bounce = 0.25, blend = "alpha", glow = 0 })
	F.smoke({ pos = at, colour = INK_DARK, amount = 5, size = { 0.45, 0.7 }, life = { 0.7, 1.0 }, rise = 0.5,
		alpha = 0.5, time = 0.2 })
	F.decal({ pos = at, tex = F.tint(TEX.puddle, INK), size = 1.5, life = 6 })
	F.sound("watersplash", { pos = at, gain = 0.9, pitch = 0.6 })
end

minemon.fx.register_move("octazooka", R)
