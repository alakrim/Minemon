-- Thunder (M2.1, T-FX-a, signature electric move): a storm orb that crackles on its way in, and on a hit a bolt
-- drops out of the sky onto the victim. Budget: projectile ~70/s, impact ~110. Cast, beam, melee and area come from
-- type:electric; the launch comes from type:electric too.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	bolt = "minemon_fx_bolt_anim.png",
	spark = "minemon_fx_spark.png",
	glow = "minemon_fx_glow.png",
}
local BOLT_FRAMES = 4
local BOLT_ANIM = { type = "vertical_frames", aspect_w = 48, aspect_h = 48, length = 0.2 }
local ZERO = { x = 0, y = 0, z = 0 }
local ORIGIN = { x = 0, y = 0, z = 0 }
local CRACKLE = { min = { x = -1.2, y = -1.2, z = -1.2 }, max = { x = 1.2, y = 1.2, z = 1.2 } }

-- A bolt flipbook texture for particles (the frames loop every 0.2 s).
local function bolt(F, colour)
	local t = F.tex(F.tint(TEX.bolt, colour), { blend = "add" })
	t.animation = BOLT_ANIM
	return t
end

-- The orb: its body is the bolt flipbook (the frames flicker), a fat crackling halo and sparks that jump off it.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.bolt, c.palette.core) }, spritediv = { x = 1, y = BOLT_FRAMES },
		visual_size = { x = 1.2, y = 1.2 }, glow = 14 })
	c.obj:set_sprite({ x = 0, y = 0 }, BOLT_FRAMES, 0.06, false)
	F.on(c.obj, {
		amount = 40, time = 1.5, pos = { min = { x = -0.1, y = -0.1, z = -0.1 }, max = { x = 0.1, y = 0.1, z = 0.1 } },
		vel = ZERO, jitter = CRACKLE, exptime = { min = 0.1, max = 0.2 }, size = { min = 0.16, max = 0.26 },
		texture = F.tex(F.tint(TEX.spark, c.palette.main), { blend = "add" }), glow = 14,
	})
	F.on(c.obj, {
		amount = 12, time = 1.5, pos = ORIGIN, vel = ZERO,
		exptime = { min = 0.3, max = 0.5 }, size = { min = 0.8, max = 1.0 },
		texture = F.tex(F.tint(TEX.glow, c.palette.core), { blend = "add", fade = true }), glow = 14,
	})
	return true
end

-- The strike: a bolt drops from above the victim in one flash, then the sparks it throws and a ring of light.
function R.impact(F, c)
	local at = c.pos
	local sky = { x = at.x, y = at.y + 1.3, z = at.z }
	F.flare({ pos = at, colour = c.palette.core, size = 1.6 })
	local tex = bolt(F, c.palette.core)
	F.emit({
		amount = 1, time = 0.02, pos = sky, vel = ZERO, exptime = 0.25, size = 2.6, vertical = true,
		texture = tex, glow = 14,
	})
	F.burst({ pos = at, tex = TEX.spark, colour = c.palette.main, amount = 30, speed = 5, radius = 0.2,
		life = { 0.2, 0.45 }, size = { 0.14, 0.24 }, glow = 14, collide = true, bounce = 0.25 })
	F.ring({ pos = at, colour = c.palette.core, size = 0.5, grow = 3.2, life = 0.3 })
	if c.victim and c.victim:get_pos() then
		F.on(c.victim, {
			amount = 16, time = 0.5,
			pos = { min = { x = -0.3, y = 0.1, z = -0.3 }, max = { x = 0.3, y = 1.0, z = 0.3 } },
			vel = ZERO, jitter = CRACKLE, exptime = { min = 0.1, max = 0.2 }, size = { min = 0.12, max = 0.2 },
			texture = F.tex(F.tint(TEX.spark, c.palette.main), { blend = "add" }), glow = 14,
		})
	end
	F.sound("lightning_thunder", { pos = at, gain = 0.9, pitch = 0.9 })
end

minemon.fx.register_move("thunder", R)
