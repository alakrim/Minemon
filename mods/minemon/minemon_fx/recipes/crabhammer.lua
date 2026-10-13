-- Crabhammer (M2.1 wave 2, group B, power 90, cast 0.6): a heavy water blow. The muzzle shoves a mass of water forward
-- (big, heavy drops that fall); the orb is a big solid drop that drags a sheet of heavy drops behind it; on the hit a
-- water column (a geyser) climbs out of the victim's feet, with a broad foam ring and a puddle that stays. Strong: big
-- and slow to read, the column is the signature (no other water move throws a column up).
-- Budget at "high": launch ~40, projectile ~60, impact ~80, plus one decal.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	droplet = "minemon_fx_droplet.png",
	foam = "minemon_fx_foam.png",
	puddle = "minemon_fx_puddle.png",
}
local ZERO = { x = 0, y = 0, z = 0 }
local GRAV = { x = 0, y = -9.8, z = 0 }

-- The shove: a heave of heavy water drops at the muzzle, slow, that fall at once.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 1.0, life = 0.14 })
	F.emit({
		amount = 14, time = 0.06, pos = c.from,
		vel = { min = vector.add(vector.multiply(c.dir, 2), { x = 0, y = 0.8, z = 0 }),
			max = vector.add(vector.multiply(c.dir, 4), { x = 0, y = 1.6, z = 0 }) },
		acc = GRAV, exptime = { min = 0.4, max = 0.7 }, size = { min = 0.2, max = 0.3 },
		texture = F.tex(F.tint(TEX.droplet, c.palette.main), { blend = "alpha", fade = { 1, 0.6 } }),
		collisiondetection = true, bounce = { min = 0.15, max = 0.3 }, glow = 8,
	})
	F.sound("watersplash", { pos = c.from, gain = 0.8, pitch = 0.7 })
end

-- The orb: a big solid drop (slow to the eye, it is the heaviest thing on the screen), and a sheet of heavy drops
-- that fall off its back.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.droplet, c.palette.main) }, visual_size = { x = 1.0, y = 1.0 },
		glow = 8 })
	F.on(c.obj, {
		amount = 40, time = 1.5, pos = { min = { x = -0.12, y = -0.12, z = -0.12 }, max = { x = 0.12, y = 0.12, z = 0.12 } },
		vel = { min = { x = -0.4, y = -0.6, z = -0.4 }, max = { x = 0.4, y = 0.2, z = 0.4 } },
		acc = GRAV, exptime = { min = 0.3, max = 0.5 }, size = { min = 0.18, max = 0.26 },
		texture = F.tex(F.tint(TEX.droplet, c.palette.core), { blend = "alpha", fade = { 1, 0.5 } }),
		collisiondetection = true, bounce = { min = 0.2, max = 0.3 }, glow = 8,
	})
	return true
end

-- The geyser: a column of water shoots up out of the victim's feet and falls back in a ring; a broad foam ring spreads
-- at the foot and a puddle stays for five seconds.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.2, life = 0.12 })
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.5, size = 2.2,
		texture = F.tex(F.tint(TEX.foam, c.palette.core), { blend = "alpha", fade = true, grow = { 0.5, 1.6 } }),
		glow = 4,
	})
	F.emit({
		amount = 30, time = 0.2, pos = { min = vector.add(at, { x = -0.15, y = -0.3, z = -0.15 }),
			max = vector.add(at, { x = 0.15, y = -0.1, z = 0.15 }) },
		vel = { min = { x = -0.3, y = 5, z = -0.3 }, max = { x = 0.3, y = 8, z = 0.3 } },
		acc = GRAV, exptime = { min = 0.7, max = 1.1 }, size = { min = 0.14, max = 0.22 },
		texture = F.tex(F.tint(TEX.droplet, c.palette.main), { blend = "alpha", fade = true }),
		collisiondetection = true, bounce = { min = 0.2, max = 0.3 }, glow = 8,
	})
	F.burst({ pos = at, tex = TEX.droplet, colour = c.palette.core, amount = 12, speed = 3, radius = 0.2,
		life = { 0.4, 0.7 }, size = { 0.1, 0.16 }, gravity = 9.8, collide = true, bounce = 0.2, blend = "alpha",
		glow = 8 })
	F.decal({ pos = at, tex = F.tint(TEX.puddle, c.palette.main), size = 2.0, life = 5 })
	F.sound("watersplash", { pos = at, gain = 1.0, pitch = 0.6 })
end

minemon.fx.register_move("crabhammer", R)
