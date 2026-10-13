-- Bubble Beam (M2.1 wave 2, group B, power 65): a chain of bubbles. The orb is one large soap bubble (a ring with a
-- solid tint) that is drawn out of the mouth, and it leaves a string of bubbles behind it that rise and sway. On the
-- hit the big bubble bursts in two rings and a splash of droplets. Medium: bigger and slower than Bubble, but the look
-- is the chain of bubbles, not a spray.
-- Budget at "high": launch ~22, projectile ~50, impact ~50.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	bubble = "minemon_fx_bubble.png",
	droplet = "minemon_fx_droplet.png",
	ring = "minemon_fx_ring.png",
}
local ZERO = { x = 0, y = 0, z = 0 }
local ORIGIN = { x = 0, y = 0, z = 0 }

-- The shot: bubbles are pushed out of the mouth in a row, each a little behind the last.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.8, life = 0.14 })
	F.emit({
		amount = 7, time = 0.25, pos = c.from,
		vel = { min = vector.multiply(c.dir, 3.5), max = vector.multiply(c.dir, 5) },
		exptime = { min = 0.5, max = 0.8 }, size = { min = 0.24, max = 0.36 },
		texture = F.tex(F.tint(TEX.bubble, c.palette.core), { blend = "alpha", alpha = 0.9, fade = { 0.9, 0.2 } }),
		glow = 6,
	})
	F.sound("watersplash", { pos = c.from, gain = 0.5, pitch = 1.1 })
end

-- The orb: a big bubble ring with a solid tint, and a chain of bubbles that rises from it, each one a little
-- smaller and fainter than the last (the chain is a single trail, so it reads as one beam of bubbles).
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.glow, c.palette.main) }, visual_size = { x = 0.9, y = 0.9 },
		glow = 6 })
	F.on(c.obj, {
		amount = 26, time = 1.5, pos = { min = { x = -0.1, y = -0.1, z = -0.1 }, max = { x = 0.1, y = 0.1, z = 0.1 } },
		vel = { min = { x = -0.15, y = 0.4, z = -0.15 }, max = { x = 0.15, y = 0.9, z = 0.15 } },
		drag = { x = 0.5, y = 0.3, z = 0.5 },
		exptime = { min = 0.6, max = 1.0 }, size = { min = 0.2, max = 0.34 },
		texture = F.tex(F.tint(TEX.bubble, c.palette.core), { blend = "alpha", alpha = 0.85, fade = { 0.85, 0 } }),
		glow = 6,
	})
	F.on(c.obj, {
		amount = 8, time = 1.5, pos = ORIGIN, vel = { x = 0, y = 0.2, z = 0 },
		exptime = { min = 0.3, max = 0.5 }, size = { min = 0.06, max = 0.09 },
		texture = F.tex(F.tint(TEX.droplet, c.palette.main), { blend = "alpha", fade = true }), glow = 6,
	})
	return true
end

-- The burst: the bubble pops in two rings (the second a beat later) and throws out a spray of droplets that fall.
function R.impact(F, c)
	local at = c.pos
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.35, size = 1.0,
		texture = F.tex(F.tint(TEX.bubble, c.palette.core), { blend = "alpha", fade = true, grow = { 0.5, 1.7 } }),
		glow = 6,
	})
	F.ring({ pos = at, colour = c.palette.core, size = 0.35, grow = 2.6, life = 0.25 })
	F.after(0.1, function()
		F.ring({ pos = at, colour = c.palette.main, size = 0.3, grow = 3.4, life = 0.3 })
	end)
	F.burst({ pos = at, tex = TEX.droplet, colour = c.palette.main, amount = 14, speed = 4, radius = 0.15,
		life = { 0.35, 0.65 }, size = { 0.08, 0.13 }, gravity = 9.8, collide = true, bounce = 0.25, blend = "alpha",
		glow = 6 })
	F.sound("watersplash", { pos = at, gain = 0.7, pitch = 1.2 })
end

minemon.fx.register_move("bubble_beam", R)
