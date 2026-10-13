-- Thunderbolt (M2.1, T-FX-a, signature electric move): a tight, fast bolt. A blue-white spark line leaves the
-- muzzle, the orb is a small hard core that flicks bolts as it flies, and it hits with a single flash and a crackle.
-- Budget: launch ~45, projectile ~60/s, impact ~100. Cast, beam, melee and area come from type:electric.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	bolt = "minemon_fx_bolt_anim.png",
	spark = "minemon_fx_spark.png",
	glow = "minemon_fx_glow.png",
	ring = "minemon_fx_ring.png",
}
local BOLT_FRAMES = 4
local BOLT_ANIM = { type = "vertical_frames", aspect_w = 48, aspect_h = 48, length = 0.15 }
local ZERO = { x = 0, y = 0, z = 0 }
local ORIGIN = { x = 0, y = 0, z = 0 }
local CRACKLE = { min = { x = -0.8, y = -0.8, z = -0.8 }, max = { x = 0.8, y = 0.8, z = 0.8 } }

-- A bolt flipbook texture for particles (the frames loop every 0.15 s).
local function bolt(F, colour)
	local t = F.tex(F.tint(TEX.bolt, colour), { blend = "add" })
	t.animation = BOLT_ANIM
	return t
end

-- The shot: a line of spark that streaks out of the muzzle, a hard flash and a short, fierce crackle.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 1.2, life = 0.12 })
	F.emit({
		amount = 22, time = 0.04, pos = c.from,
		vel = { min = vector.multiply(c.dir, 12), max = vector.multiply(c.dir, 14) },
		jitter = { min = { x = -0.2, y = -0.2, z = -0.2 }, max = { x = 0.2, y = 0.2, z = 0.2 } },
		exptime = { min = 0.1, max = 0.18 }, size = { min = 0.14, max = 0.2 },
		texture = F.tex(F.tint(TEX.spark, c.palette.core), { blend = "add", fade = true }), glow = 14,
	})
	F.emit({
		amount = 1, time = 0.02, pos = c.from, vel = ZERO, exptime = 0.15, size = 1.1,
		texture = bolt(F, c.palette.core), glow = 14,
	})
	F.sound("lightning_thunder", { pos = c.from, gain = 0.4, pitch = 2.0 })
end

-- The orb: a small hard core, sharp bolt flicks that stay where they were born and a dense spark wake.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.bolt, c.palette.core) }, spritediv = { x = 1, y = BOLT_FRAMES },
		visual_size = { x = 0.7, y = 0.7 }, glow = 14 })
	c.obj:set_sprite({ x = 0, y = 0 }, BOLT_FRAMES, 0.04, false)
	F.on(c.obj, {
		amount = 36, time = 1.5, pos = ORIGIN, vel = ZERO, jitter = CRACKLE,
		exptime = { min = 0.08, max = 0.14 }, size = { min = 0.14, max = 0.22 },
		texture = F.tex(F.tint(TEX.spark, c.palette.main), { blend = "add" }), glow = 14,
	})
	F.on(c.obj, {
		amount = 10, time = 1.5, pos = { min = { x = -0.2, y = -0.2, z = -0.2 }, max = { x = 0.2, y = 0.2, z = 0.2 } },
		vel = ZERO, exptime = { min = 0.12, max = 0.2 }, size = { min = 0.7, max = 0.9 },
		texture = bolt(F, c.palette.core), glow = 14,
	})
	return true
end

-- The hit: one flash and a bolt in it, a tight spray of sparks and a small ring; a short crackle stays on the victim.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.8, life = 0.14 })
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.18, size = 1.6,
		texture = bolt(F, c.palette.core), glow = 14,
	})
	F.burst({ pos = at, tex = TEX.spark, colour = c.palette.main, amount = 30, speed = 6, radius = 0.15,
		life = { 0.12, 0.3 }, size = { 0.14, 0.22 }, glow = 14, collide = true, bounce = 0.2 })
	F.ring({ pos = at, colour = c.palette.core, size = 0.35, grow = 2.6, life = 0.2 })
	if c.victim and c.victim:get_pos() then
		F.on(c.victim, {
			amount = 12, time = 0.35,
			pos = { min = { x = -0.3, y = 0.1, z = -0.3 }, max = { x = 0.3, y = 1.0, z = 0.3 } },
			vel = ZERO, jitter = CRACKLE, exptime = { min = 0.08, max = 0.14 }, size = { min = 0.12, max = 0.18 },
			texture = F.tex(F.tint(TEX.spark, c.palette.core), { blend = "add" }), glow = 14,
		})
	end
	F.sound("lightning_thunder", { pos = at, gain = 0.6, pitch = 1.5 })
end

minemon.fx.register_move("thunderbolt", R)
