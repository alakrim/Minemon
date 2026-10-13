-- Water Gun (M2.1 wave 2, group B, power 40): a pressurised jet. The shot is a thin, straight, fast line of droplets
-- with no gravity (the water type's droplets fall), the orb is a solid drop with a fine spray behind it, and the hit
-- is a foam crown: a ring that spreads round the victim's feet and a few droplets thrown up. Weak: small and quick.
-- Cast, beam, melee and area come from type:water.
-- Budget at "high": launch ~20, projectile ~45, impact ~60.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	droplet = "minemon_fx_droplet.png",
	foam = "minemon_fx_foam.png",
}
local JET = { min = { x = -0.04, y = -0.04, z = -0.04 }, max = { x = 0.04, y = 0.04, z = 0.04 } }
local ZERO = { x = 0, y = 0, z = 0 }

-- The shot: a jet of droplets in a line at 15 m/s, and a small flash at the muzzle.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.6, life = 0.1 })
	F.emit({
		amount = 18, time = 0.04, pos = c.from, jitter = JET,
		vel = { min = vector.multiply(c.dir, 15), max = vector.multiply(c.dir, 17) },
		exptime = { min = 0.12, max = 0.2 }, size = { min = 0.07, max = 0.1 },
		texture = F.tex(F.tint(TEX.droplet, c.palette.main), { blend = "alpha", fade = true }), glow = 8,
	})
	F.sound("watersplash", { pos = c.from, gain = 0.4, pitch = 1.5 })
end

-- The orb: a solid drop of the type's colour; a thin spray of fine drops streams off it, straight back, no gravity.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.droplet, c.palette.main) }, visual_size = { x = 0.45, y = 0.45 },
		glow = 8 })
	F.on(c.obj, {
		amount = 30, time = 1.5, pos = { min = { x = -0.03, y = -0.03, z = -0.03 }, max = { x = 0.03, y = 0.03, z = 0.03 } },
		vel = { min = { x = -0.15, y = -0.15, z = -0.15 }, max = { x = 0.15, y = 0.15, z = 0.15 } },
		exptime = { min = 0.12, max = 0.22 }, size = { min = 0.05, max = 0.08 },
		texture = F.tex(F.tint(TEX.droplet, c.palette.core), { blend = "alpha", fade = true }), glow = 8,
	})
	return true
end

-- The hit: a flat foam crown at the feet, four droplets thrown up in a fan, and a white catch light.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 0.7, life = 0.1 })
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.45, size = 0.5,
		texture = F.tex(F.tint(TEX.foam, c.palette.core), { blend = "alpha", fade = true, grow = { 0.4, 1.6 } }),
		glow = 4,
	})
	F.burst({ pos = at, tex = TEX.droplet, colour = c.palette.main, amount = 8, speed = 3.5, radius = 0.1,
		life = { 0.3, 0.5 }, size = { 0.07, 0.1 }, gravity = 9.8, collide = true, bounce = 0.2, blend = "alpha",
		glow = 8 })
	F.sound("watersplash", { pos = at, gain = 0.5, pitch = 1.4 })
end

minemon.fx.register_move("water_gun", R)
