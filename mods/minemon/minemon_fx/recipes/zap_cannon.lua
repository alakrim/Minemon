-- Zap Cannon (M2.1 wave 2, group B, power 100, accuracy 50, paralysis): a charged plasma sphere. The cast gathers a
-- ring that collapses into the mouth; the muzzle fires a big white flash and a ring; the orb is a large bright core
-- with a pulsing halo and a crackle that circles it; the hit is the signature: six bolts fork out of the victim in a
-- crown around its body, with a big flash. Strong: big, loud, and it misses half the time (the orb simply passes).
-- Budget at "high": cast ~40, launch ~50, projectile ~60/s, impact ~110.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	bolt = "minemon_fx_bolt_anim.png",
	spark = "minemon_fx_spark.png",
	glow = "minemon_fx_glow.png",
	ring = "minemon_fx_ring.png",
}
local BOLT_ANIM = { type = "vertical_frames", aspect_w = 48, aspect_h = 48, length = 0.15 }
local ZERO = { x = 0, y = 0, z = 0 }
local CRACKLE = { min = { x = -1.2, y = -1.2, z = -1.2 }, max = { x = 1.2, y = 1.2, z = 1.2 } }
local CROWN_R = 0.7

local function bolt(F, colour)
	local t = F.tex(F.tint(TEX.bolt, colour), { blend = "add" })
	t.animation = BOLT_ANIM
	return t
end

-- Wind-up: a ring that collapses into the mouth as the charge builds, and a glow that swells there.
function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.2, c.time or 0.6)
	F.emit({
		amount = 1, time = t, pos = at, vel = ZERO, exptime = t, size = 2.2,
		texture = F.tex(F.tint(TEX.ring, c.palette.core), { blend = "add", fade = { 0.8, 0.8 }, grow = { 1.6, 0.2 } }),
		glow = 14,
	})
	F.inhale({ pos = at, tex = TEX.spark, colour = c.palette.main, radius = 1.2, amount = 26, time = t,
		size = { 0.1, 0.16 } })
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t + 0.05, size = 0.9,
		texture = F.tex(F.tint(TEX.glow, c.palette.core), { blend = "add", grow = { 0.3, 1.2 }, alpha = 0.9 }),
		glow = 14,
	})
	F.sound("lightning_thunder", { pos = at, gain = 0.3, pitch = 1.2 })
end

-- The muzzle: a big white flash, a ring that rushes out and a fan of sparks.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 2.0, life = 0.2 })
	F.ring({ pos = c.from, colour = c.palette.core, size = 0.5, grow = 3.4, life = 0.3 })
	F.burst({ pos = c.from, tex = TEX.spark, colour = c.palette.main, amount = 22, speed = 4, radius = 0.2,
		life = { 0.2, 0.4 }, size = { 0.14, 0.22 }, glow = 14 })
	F.sound("lightning_thunder", { pos = c.from, gain = 0.8, pitch = 0.9 })
end

-- The orb: a large bright core, a halo that swells and fades, and a crackle of sparks that circles it.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.glow, c.palette.core) }, visual_size = { x = 1.1, y = 1.1 },
		glow = 14 })
	F.on(c.obj, {
		amount = 12, time = 1.5, pos = ZERO, vel = ZERO,
		exptime = { min = 0.2, max = 0.3 }, size = { min = 0.9, max = 1.2 },
		texture = F.tex(F.tint(TEX.glow, c.palette.main), { blend = "add", fade = true, grow = { 0.8, 1.3 } }),
		glow = 14,
	})
	F.on(c.obj, {
		amount = 40, time = 1.5, pos = { min = { x = -0.15, y = -0.15, z = -0.15 }, max = { x = 0.15, y = 0.15, z = 0.15 } },
		vel = ZERO, jitter = CRACKLE, exptime = { min = 0.1, max = 0.2 }, size = { min = 0.14, max = 0.22 },
		texture = F.tex(F.tint(TEX.spark, c.palette.main), { blend = "add" }), glow = 14,
	})
	return true
end

-- The hit: a big flash, six bolts forking out round the victim in a crown, a ring and a burst of sparks.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 2.2, life = 0.18 })
	F.ring({ pos = at, colour = c.palette.main, size = 0.5, grow = 4.0, life = 0.35 })
	for i = 0, 5 do
		local a = i / 6 * 2 * math.pi
		local p = vector.add(at, { x = math.cos(a) * CROWN_R, y = math.sin(a) * 0.35, z = 0 })
		F.emit({
			amount = 1, time = 0.02, pos = p, vel = ZERO, exptime = 0.22, size = 1.6,
			texture = bolt(F, c.palette.core), glow = 14,
		})
	end
	F.burst({ pos = at, tex = TEX.spark, colour = c.palette.main, amount = 34, speed = 5, radius = 0.2,
		life = { 0.15, 0.4 }, size = { 0.14, 0.24 }, glow = 14, collide = true, bounce = 0.2 })
	F.sound("lightning_thunder", { pos = at, gain = 0.9, pitch = 0.8 })
end

minemon.fx.register_move("zap_cannon", R)
