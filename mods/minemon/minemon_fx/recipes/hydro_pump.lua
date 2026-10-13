-- Hydro Pump (M2.1, T-FX-a, signature water move): a torrent. A heavy jet leaves the mouth, the orb is a column of
-- water that pours off it, and the impact is a splash crown with a puddle that stays. Budget: launch 40, projectile
-- ~60/s, impact ~150. Cast, beam, melee and area come from type:water.
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

-- A jet of water from the muzzle: heavy droplets that keep their line and fall once they slow down.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 1.3 })
	F.emit({
		amount = 30, time = 0.06, pos = c.from,
		vel = { min = vector.multiply(c.dir, 8), max = vector.multiply(c.dir, 12) }, acc = GRAVITY,
		exptime = { min = 0.4, max = 0.8 }, size = { min = 0.12, max = 0.22 },
		texture = F.tex(F.tint(TEX.droplet, c.palette.main), { blend = "alpha", fade = true }),
		collisiondetection = true, bounce = { min = 0.2, max = 0.4 }, glow = 8,
	})
	F.sound("watersplash", { pos = c.from, gain = 0.9, pitch = 0.8 })
end

-- The orb: a glowing core that pours a column of droplets and foam behind it as it travels.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.glow, c.palette.core) }, visual_size = { x = 1.0, y = 1.0 } })
	F.on(c.obj, {
		amount = 40, time = 1.5, pos = { min = { x = -0.15, y = -0.15, z = -0.15 }, max = { x = 0.15, y = 0.15, z = 0.15 } },
		vel = { min = { x = -0.5, y = -0.5, z = -0.5 }, max = { x = 0.5, y = 0.5, z = 0.5 } }, acc = GRAVITY,
		exptime = { min = 0.4, max = 0.7 }, size = { min = 0.14, max = 0.24 },
		texture = F.tex(F.tint(TEX.droplet, c.palette.main), { blend = "alpha", fade = true }),
		collisiondetection = true, bounce = { min = 0.2, max = 0.35 }, glow = 8,
	})
	F.on(c.obj, {
		amount = 16, time = 1.5, pos = { x = 0, y = 0, z = 0 },
		vel = { min = { x = -0.3, y = 0, z = -0.3 }, max = { x = 0.3, y = 0.5, z = 0.3 } },
		exptime = { min = 0.6, max = 1.0 }, size = { min = 0.3, max = 0.45 },
		texture = F.tex(F.tint(TEX.foam, c.palette.smoke), { blend = "alpha", alpha = 0.6, fade = true }), glow = 4,
	})
	return true
end

-- The splash crown: two foam rings, a burst of droplets that bounce, bubbles, wet drips from the victim and a puddle
-- that stays on the ground.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.5 })
	for _, grow in ipairs({ 3.5, 2.2 }) do
		F.emit({
			amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.5 + grow * 0.05, size = 0.6,
			texture = F.tex(F.tint(TEX.foam, c.palette.core), { blend = "alpha", fade = true, grow = { 0.5, grow } }),
			glow = 4,
		})
	end
	F.burst({ pos = at, tex = TEX.droplet, colour = c.palette.main, amount = 60, speed = 5, radius = 0.2,
		life = { 0.5, 1.0 }, size = { 0.12, 0.2 }, gravity = 9.8, collide = true, bounce = 0.35, blend = "alpha",
		glow = 8 })
	F.emit({
		amount = 20, time = 0.3, pos = { min = { x = at.x - 0.3, y = at.y - 0.2, z = at.z - 0.3 },
			max = { x = at.x + 0.3, y = at.y + 0.2, z = at.z + 0.3 } },
		vel = { min = { x = -0.2, y = 0.6, z = -0.2 }, max = { x = 0.2, y = 1.6, z = 0.2 } },
		exptime = { min = 0.7, max = 1.1 }, size = { min = 0.14, max = 0.26 },
		texture = F.tex(F.tint(TEX.bubble, c.palette.main), { blend = "alpha", alpha = 0.8, fade = true }), glow = 6,
	})
	if c.victim and c.victim:get_pos() then
		F.on(c.victim, {
			amount = 14, time = 0.7,
			pos = { min = { x = -0.3, y = 0.2, z = -0.3 }, max = { x = 0.3, y = 0.9, z = 0.3 } },
			vel = { x = 0, y = -0.5, z = 0 }, acc = GRAVITY, exptime = { min = 0.3, max = 0.5 },
			size = { min = 0.08, max = 0.14 },
			texture = F.tex(F.tint(TEX.droplet, c.palette.main), { blend = "alpha", fade = true }), glow = 8,
		})
	end
	F.decal({ pos = at, tex = F.tint(TEX.puddle, c.palette.main), size = 2.4, life = 6 })
	F.sound("watersplash", { pos = at, gain = 1.0, pitch = 0.75 })
end

minemon.fx.register_move("hydro_pump", R)
