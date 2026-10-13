-- Thunder Punch (M2.1 wave 2, group B, power 75, paralysis 10%): a punch made of lightning. The muzzle flashes a
-- four-ray punch star; the orb is a bolt flicker dragging yellow speed lines behind it, so it reads as a fist moving
-- fast; the hit is a big yellow-white punch star with three bolts forking out of it. Medium-strong: the star is the
-- signature (Thunder Shock and Spark have no star).
-- Budget at "high": launch ~25, projectile ~50/s, impact ~80.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	bolt = "minemon_fx_bolt_anim.png",
	star = "minemon_fx_impact_star.png",
	speedline = "minemon_fx_speedline.png",
	spark = "minemon_fx_spark.png",
}
local BOLT_FRAMES = 4
local BOLT_ANIM = { type = "vertical_frames", aspect_w = 48, aspect_h = 48, length = 0.15 }
local ZERO = { x = 0, y = 0, z = 0 }
local ORIGIN = { x = 0, y = 0, z = 0 }

local function bolt(F, colour)
	local t = F.tex(F.tint(TEX.bolt, colour), { blend = "add" })
	t.animation = BOLT_ANIM
	return t
end

-- The punch: a star flashes at the muzzle and the air jumps forward.
function R.launch(F, c)
	F.emit({
		amount = 1, time = 0.02, pos = c.from, vel = ZERO, exptime = 0.16, size = 1.4,
		texture = F.tex(F.tint(TEX.star, c.palette.core), { blend = "add", fade = true, grow = { 0.6, 1.1 } }),
		glow = 14,
	})
	F.emit({
		amount = 8, time = 0.04, pos = c.from,
		vel = { min = vector.multiply(c.dir, 6), max = vector.multiply(c.dir, 9) },
		exptime = { min = 0.12, max = 0.2 }, size = { min = 0.16, max = 0.24 },
		texture = F.tex(F.tint(TEX.speedline, c.palette.main), { blend = "add", fade = true }),
		vertical = false, glow = 14,
	})
	F.sound("lightning_thunder", { pos = c.from, gain = 0.4, pitch = 1.5 })
end

-- The fist: a bolt flicker at the head of the orb and yellow speed lines streaming behind it.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.bolt, c.palette.core) }, spritediv = { x = 1, y = BOLT_FRAMES },
		visual_size = { x = 0.8, y = 0.8 }, glow = 14 })
	c.obj:set_sprite({ x = 0, y = 0 }, BOLT_FRAMES, 0.05, false)
	F.on(c.obj, {
		amount = 16, time = 1.5, pos = ORIGIN, vel = { x = 0, y = 0, z = 0 },
		exptime = { min = 0.12, max = 0.22 }, size = { min = 0.3, max = 0.42 },
		texture = F.tex(F.tint(TEX.speedline, c.palette.main), { blend = "add", fade = true }),
		vertical = false, glow = 14,
	})
	F.on(c.obj, {
		amount = 10, time = 1.5, pos = { min = { x = -0.08, y = -0.08, z = -0.08 }, max = { x = 0.08, y = 0.08, z = 0.08 } },
		vel = ZERO, exptime = { min = 0.08, max = 0.14 }, size = { min = 0.12, max = 0.18 },
		texture = F.tex(F.tint(TEX.spark, c.palette.core), { blend = "add" }), glow = 14,
	})
	return true
end

-- The hit: a yellow-white punch star on the victim, three bolts forking out of it and a flash.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.2, life = 0.12 })
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.24, size = 2.0,
		texture = F.tex(F.tint(TEX.star, c.palette.core), { blend = "add", fade = true, grow = { 0.7, 1.2 } }),
		glow = 14,
	})
	local forks = { { x = -0.5, y = 0.5 }, { x = 0.5, y = 0.5 }, { x = 0, y = -0.6 } }
	for _, f in ipairs(forks) do
		F.emit({
			amount = 1, time = 0.02, pos = vector.add(at, { x = f.x * 0.45, y = f.y * 0.45, z = 0 }), vel = ZERO,
			exptime = 0.2, size = 1.1, texture = bolt(F, c.palette.main), glow = 14,
		})
	end
	F.ring({ pos = at, colour = c.palette.main, size = 0.3, grow = 2.6, life = 0.2 })
	F.sound("lightning_thunder", { pos = at, gain = 0.7, pitch = 1.3 })
end

minemon.fx.register_move("thunder_punch", R)
