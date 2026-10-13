-- Electric (M2.1, T-FX-a): the type recipe. Jagged bolt flashes (a 4-frame flipbook, redrawn every frame), crackling
-- sparks with jitter and a blue-white core. Budget at "high" (docs/ART_GUIDE.md section 4): cast ~45, launch ~40,
-- projectile ~70/s, impact ~120, area ~170.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	bolt = "minemon_fx_bolt_anim.png",
	spark = "minemon_fx_spark.png",
	glow = "minemon_fx_glow.png",
	ring = "minemon_fx_ring.png",
}
local ZERO = { x = 0, y = 0, z = 0 }
local ORIGIN = { x = 0, y = 0, z = 0 }
local CRACKLE = { min = { x = -1.5, y = -1.5, z = -1.5 }, max = { x = 1.5, y = 1.5, z = 1.5 } }
local BOLT_FRAMES = 4
local BOLT_ANIM = { type = "vertical_frames", aspect_w = 48, aspect_h = 48, length = 0.2 }

local function box(p, r)
	return { min = { x = p.x - r, y = p.y - r, z = p.z - r }, max = { x = p.x + r, y = p.y + r, z = p.z + r } }
end

-- A bolt flipbook texture for particles (the frames play over 0.2 s, looping). The colour is tinted in.
local function bolt(F, colour, fade)
	local t = F.tex(F.tint(TEX.bolt, colour), { blend = "add", fade = fade == true })
	t.animation = BOLT_ANIM
	return t
end

-- Wind-up: sparks are drawn into the mouth and crackle around it.
function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.5)
	F.inhale({ pos = at, tex = TEX.spark, colour = c.palette.main, radius = 1.0, amount = 22, time = t,
		size = { 0.06, 0.12 } })
	F.emit({
		amount = 12, time = t, pos = box(at, 0.2), vel = ZERO, jitter = CRACKLE,
		exptime = { min = 0.08, max = 0.16 }, size = { min = 0.12, max = 0.2 },
		texture = F.tex(F.tint(TEX.spark, c.palette.core), { blend = "add" }), glow = 14,
	})
	F.emit({
		amount = 1, time = t, pos = at, vel = ZERO, exptime = 0.2, size = 0.7,
		texture = bolt(F, c.palette.core), glow = 14,
	})
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t + 0.05, size = 0.7,
		texture = F.tex(F.tint(TEX.glow, c.palette.core), { blend = "add", grow = { 0.2, 1.0 }, alpha = 0.8 }),
		glow = 14,
	})
	F.sound("lightning_thunder", { pos = at, gain = 0.25, pitch = 1.6 })
end

-- Launch: a bolt flashes at the muzzle, sparks fly forward and crackle.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9, life = 0.15 })
	F.emit({
		amount = 1, time = 0.02, pos = c.from, vel = ZERO, exptime = 0.2, size = 1.0,
		texture = bolt(F, c.palette.core), glow = 14,
	})
	F.emit({
		amount = 12, time = 0.05, pos = c.from, jitter = CRACKLE,
		vel = { min = vector.multiply(c.dir, 4), max = vector.multiply(c.dir, 8) },
		exptime = { min = 0.15, max = 0.3 }, size = { min = 0.14, max = 0.22 },
		texture = F.tex(F.tint(TEX.spark, c.palette.main), { blend = "add", fade = true }), glow = 14,
	})
	F.sound("lightning_thunder", { pos = c.from, gain = 0.35, pitch = 1.8 })
end

-- The orb: a bolt flipbook that is the body itself (the frames flicker), with a crackling trail of sparks.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.bolt, c.palette.core) }, spritediv = { x = 1, y = BOLT_FRAMES },
		visual_size = { x = 0.9, y = 0.9 }, glow = 14 })
	c.obj:set_sprite({ x = 0, y = 0 }, BOLT_FRAMES, 0.05, false)
	F.on(c.obj, {
		amount = 30, time = 1.5, pos = box(ORIGIN, 0.05), vel = ZERO, jitter = CRACKLE,
		exptime = { min = 0.1, max = 0.2 }, size = { min = 0.14, max = 0.24 },
		texture = F.tex(F.tint(TEX.spark, c.palette.main), { blend = "add" }), glow = 14,
	})
	F.on(c.obj, {
		amount = 12, time = 1.5, pos = ORIGIN, vel = ZERO,
		exptime = { min = 0.3, max = 0.5 }, size = { min = 0.6, max = 0.8 },
		texture = F.tex(F.tint(TEX.glow, c.palette.main), { blend = "add", fade = true }), glow = 14,
	})
	return true
end

-- Beam: a line of bolt flashes and sparks along the path, a hot core and a flash where it lands.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local dir = vector.multiply(d, 1 / len)
	F.emit({
		amount = 14, time = 0.4, pos = { min = c.from, max = c.to }, vel = ZERO, jitter = CRACKLE,
		exptime = { min = 0.12, max = 0.2 }, size = { min = 0.8, max = 1.1 },
		texture = bolt(F, c.palette.core), glow = 14,
	})
	F.emit({
		amount = 40, time = 0.4, pos = c.from, vel = vector.multiply(dir, len / 0.4),
		jitter = { min = { x = -0.6, y = -0.6, z = -0.6 }, max = { x = 0.6, y = 0.6, z = 0.6 } },
		exptime = { min = 0.4, max = 0.4 }, size = { min = 0.12, max = 0.2 },
		texture = F.tex(F.tint(TEX.spark, c.palette.main), { blend = "add" }), glow = 14,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9 })
	F.flare({ pos = c.to, colour = c.palette.core, size = 1.2, life = 0.3 })
end

-- Melee: an arc of crackling sparks in front of the user.
function R.melee(F, c)
	for i = -2, 2 do
		local bulge = 0.45 - 0.08 * math.abs(i)
		local p = vector.add(c.centre, { x = c.fwd.x * bulge, y = i * 0.22, z = c.fwd.z * bulge })
		F.emit({
			amount = 5, time = 0.12, pos = p, vel = ZERO, jitter = CRACKLE,
			exptime = { min = 0.1, max = 0.2 }, size = { min = 0.2, max = 0.32 },
			texture = F.tex(F.tint(TEX.spark, c.palette.main), { blend = "add" }), glow = 14,
		})
	end
	F.emit({
		amount = 1, time = 0.1, pos = c.centre, vel = ZERO, exptime = 0.2, size = 1.1,
		texture = bolt(F, c.palette.core), glow = 14,
	})
end

-- Area: bolts strike the ground all around the centre, a blue-white ring and sparks that jump outward.
function R.area(F, c)
	local r = c.radius * 0.8
	F.emit({
		amount = 8, time = 0.35, pos = { min = vector.subtract(c.centre, { x = r, y = 0.2, z = r }),
			max = vector.add(c.centre, { x = r, y = 0.8, z = r }) },
		vel = ZERO, exptime = { min = 0.12, max = 0.22 }, size = { min = 0.9, max = 1.3 },
		texture = bolt(F, c.palette.core), glow = 14,
	})
	F.flare({ pos = c.centre, colour = c.palette.core, size = 1.4, life = 0.25 })
	F.ring({ pos = c.centre, colour = c.palette.core, size = 0.6, grow = c.radius * 1.4, life = 0.4 })
	F.burst({ pos = c.centre, tex = TEX.spark, colour = c.palette.main, amount = 36, speed = c.radius * 2,
		radius = 0.3, life = { 0.2, 0.45 }, size = { 0.14, 0.22 }, glow = 14, collide = true, bounce = 0.2 })
	F.sound("lightning_thunder", { pos = c.centre, gain = 0.5 })
end

-- Impact in layers: a white catch light, two bolt flashes on the victim, a jump of sparks, a blue-white ring and
-- a short crackle on the victim.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.4 })
	for i = 1, 2 do
		F.emit({
			amount = 1, time = 0.02, pos = vector.add(at, { x = (i - 1.5) * 0.3, y = 0, z = 0 }), vel = ZERO,
			exptime = 0.25, size = 1.4 + 0.2 * i, texture = bolt(F, c.palette.core), glow = 14,
		})
	end
	F.burst({ pos = at, tex = TEX.spark, colour = c.palette.main, amount = 32, speed = 4, radius = 0.2,
		life = { 0.15, 0.4 }, size = { 0.14, 0.24 }, glow = 14, collide = true, bounce = 0.25 })
	F.ring({ pos = at, colour = c.palette.core, size = 0.4, grow = 3, life = 0.25 })
	if c.victim and c.victim:get_pos() then
		F.on(c.victim, {
			amount = 14, time = 0.4, pos = { min = { x = -0.3, y = 0.1, z = -0.3 }, max = { x = 0.3, y = 1.0, z = 0.3 } },
			vel = ZERO, jitter = CRACKLE, exptime = { min = 0.08, max = 0.16 }, size = { min = 0.12, max = 0.2 },
			texture = F.tex(F.tint(TEX.spark, c.palette.main), { blend = "add" }), glow = 14,
		})
	end
	F.sound("lightning_thunder", { pos = at, gain = 0.6, pitch = 1.2 })
end

minemon.fx.register_move("type:electric", R)
