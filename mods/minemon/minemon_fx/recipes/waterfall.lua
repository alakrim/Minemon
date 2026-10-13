-- Waterfall (M2.1, T-FX-a, signature water move): water climbs out of the ground around the user in a spiral, then
-- the orb carries it forward as a falling curtain of droplets, and it lands in a splash that rolls outward. Budget:
-- cast ~60, projectile ~60/s, impact ~120. Launch, beam, melee and area come from type:water.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	droplet = "minemon_fx_droplet.png",
	bubble = "minemon_fx_bubble.png",
	foam = "minemon_fx_foam.png",
	puddle = "minemon_fx_puddle.png",
	glow = "minemon_fx_glow.png",
}
local ZERO = { x = 0, y = 0, z = 0 }
local GRAVITY = { x = 0, y = -9.8, z = 0 }

-- The climb: droplets rise from the ground around the user and gather into the mouth.
function R.cast(F, c)
	local feet = c.user:get_pos()
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not feet or not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.5)
	F.emit({
		amount = 40, time = t, pos = { min = { x = feet.x - 0.9, y = feet.y, z = feet.z - 0.9 },
			max = { x = feet.x + 0.9, y = feet.y + 0.3, z = feet.z + 0.9 } },
		vel = { min = { x = -0.2, y = 1.6, z = -0.2 }, max = { x = 0.2, y = 2.6, z = 0.2 } },
		exptime = { min = 0.3, max = 0.5 }, size = { min = 0.1, max = 0.16 },
		texture = F.tex(F.tint(TEX.droplet, c.palette.main), { blend = "alpha", fade = true }), glow = 8,
	}, at)
	F.inhale({ pos = at, tex = TEX.droplet, colour = c.palette.main, radius = 1.2, amount = 20, time = t,
		size = { 0.08, 0.12 } })
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t + 0.05, size = 0.8,
		texture = F.tex(F.tint(TEX.glow, c.palette.main), { blend = "add", grow = { 0.2, 1.0 }, alpha = 0.7 }),
		glow = 10,
	})
	F.sound("watersplash", { pos = at, gain = 0.4, pitch = 1.1 })
end

-- The orb: a glowing bead that spills a falling curtain of droplets, wide at the top and gathering below.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.glow, c.palette.main) }, visual_size = { x = 0.7, y = 0.7 } })
	F.on(c.obj, {
		amount = 44, time = 1.5, pos = { min = { x = -0.3, y = -0.1, z = -0.3 }, max = { x = 0.3, y = 0.1, z = 0.3 } },
		vel = { min = { x = -0.3, y = -1.0, z = -0.3 }, max = { x = 0.3, y = -0.4, z = 0.3 } }, acc = GRAVITY,
		exptime = { min = 0.4, max = 0.8 }, size = { min = 0.1, max = 0.18 },
		texture = F.tex(F.tint(TEX.droplet, c.palette.main), { blend = "alpha", fade = true }),
		collisiondetection = true, bounce = { min = 0.2, max = 0.3 }, glow = 8,
	})
	F.on(c.obj, {
		amount = 12, time = 1.5, pos = { x = 0, y = 0, z = 0 },
		vel = { min = { x = -0.2, y = 0.1, z = -0.2 }, max = { x = 0.2, y = 0.5, z = 0.2 } },
		exptime = { min = 0.5, max = 0.9 }, size = { min = 0.12, max = 0.2 },
		texture = F.tex(F.tint(TEX.bubble, c.palette.core), { blend = "alpha", alpha = 0.7, fade = true }), glow = 6,
	})
	return true
end

-- The landing: droplets that splash out and fall, a foam ring that rolls outward, a puddle that stays.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.2 })
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.9, size = 0.6,
		texture = F.tex(F.tint(TEX.foam, c.palette.core), { blend = "alpha", fade = true, grow = { 0.5, 3.4 } }),
		glow = 4,
	})
	F.burst({ pos = at, tex = TEX.droplet, colour = c.palette.main, amount = 46, speed = 4.5, radius = 0.2,
		life = { 0.5, 0.9 }, size = { 0.1, 0.18 }, gravity = 9.8, collide = true, bounce = 0.3, blend = "alpha",
		glow = 8 })
	F.smoke({ pos = at, colour = c.palette.smoke, amount = 6, size = { 0.5, 0.8 }, life = { 0.8, 1.2 }, alpha = 0.3,
		time = 0.3, rise = 0.5 })
	F.decal({ pos = at, tex = F.tint(TEX.puddle, c.palette.main), size = 2.0, life = 5 })
	F.sound("watersplash", { pos = at, gain = 0.9, pitch = 0.9 })
end

minemon.fx.register_move("waterfall", R)
