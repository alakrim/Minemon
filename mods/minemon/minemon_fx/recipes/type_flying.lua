-- Flying (M2.1, T-FX-a): the type recipe. Wind streaks (streak texture, vertical = false), feathers that drift and
-- float, pressure rings that expand in the air. Budget at "high" (docs/ART_GUIDE.md section 4): cast ~45, launch
-- ~35, projectile ~50/s, impact ~110, beam ~150, area ~180.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	streak = "minemon_fx_streak.png",
	feather = "minemon_fx_feather.png",
	glow = "minemon_fx_glow.png",
	mote = "minemon_fx_mote.png",
}
local ZERO = { x = 0, y = 0, z = 0 }
local ORIGIN = { x = 0, y = 0, z = 0 }
local FLOAT = { x = 0, y = 0.6, z = 0 }

local function box(p, r)
	return { min = { x = p.x - r, y = p.y - r, z = p.z - r }, max = { x = p.x + r, y = p.y + r, z = p.z + r } }
end

-- Wind-up: wind streaks and feathers are pulled into the mouth from the air around the user.
function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.5)
	F.inhale({ pos = at, tex = TEX.streak, colour = c.palette.main, radius = 1.2, amount = 22, time = t,
		size = { 0.1, 0.2 } })
	F.inhale({ pos = at, tex = TEX.feather, colour = c.palette.main, radius = 1.0, amount = 8, time = t,
		size = { 0.25, 0.35 } })
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t + 0.05, size = 0.7,
		texture = F.tex(F.tint(TEX.glow, c.palette.core), { blend = "add", grow = { 0.2, 1.0 }, alpha = 0.8 }),
		glow = 8,
	})
	F.sound("mcl_throwing_throw", { pos = at, gain = 0.3, pitch = 0.7 })
end

-- Launch: a flash at the muzzle, a pressure ring and a gust of streaks forward.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.8, life = 0.15 })
	F.ring({ pos = c.from, colour = c.palette.main, size = 0.4, grow = 2.2, life = 0.25 })
	F.emit({
		amount = 14, time = 0.05, pos = c.from,
		vel = { min = vector.multiply(c.dir, 10), max = vector.multiply(c.dir, 14) },
		exptime = { min = 0.15, max = 0.3 }, size = { min = 0.12, max = 0.22 },
		texture = F.tex(F.tint(TEX.streak, c.palette.core), { blend = "add", fade = true }), vertical = false,
		glow = 8,
	})
	F.sound("mcl_throwing_throw", { pos = c.from, gain = 0.6, pitch = 0.8 })
end

-- The orb: a pale air ball with streaks and feathers drifting off it.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(F.TEX.glow, c.palette.main) }, visual_size = { x = 0.6, y = 0.6 } })
	F.on(c.obj, {
		amount = 30, time = 1.5, pos = box(ORIGIN, 0.1), vel = { min = { x = -0.3, y = -0.3, z = -0.3 },
			max = { x = 0.3, y = 0.3, z = 0.3 } },
		exptime = { min = 0.3, max = 0.5 }, size = { min = 0.15, max = 0.25 },
		texture = F.tex(F.tint(TEX.streak, c.palette.core), { blend = "add", fade = true }), vertical = false,
		glow = 8,
	})
	F.on(c.obj, {
		amount = 10, time = 1.5, pos = ORIGIN, vel = { min = { x = -0.4, y = 0, z = -0.4 },
			max = { x = 0.4, y = 0.4, z = 0.4 } },
		drag = { x = 0.8, y = 0.8, z = 0.8 }, acc = { x = 0, y = -1.2, z = 0 },
		exptime = { min = 0.6, max = 1.0 }, size = { min = 0.25, max = 0.4 },
		texture = F.tex(F.tint(TEX.feather, c.palette.main), { blend = "alpha", fade = true }), glow = 4,
	})
	return true
end

-- Beam: a column of wind along the line, feathers swirling inside it and a pressure ring where it stops.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 30
	local dir = vector.multiply(d, 1 / len)
	F.emit({
		amount = 60, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		jitter = { min = { x = -0.5, y = -0.5, z = -0.5 }, max = { x = 0.5, y = 0.5, z = 0.5 } },
		size = { min = 0.25, max = 0.35 },
		texture = F.tex(F.tint(TEX.streak, c.palette.main), { blend = "alpha", fade = true }), vertical = false,
		glow = 4,
	}, c.from)
	F.emit({
		amount = 14, time = 0.45, pos = c.from, vel = vector.multiply(dir, 8), exptime = len / 8,
		jitter = { min = { x = -1.2, y = -1.2, z = -1.2 }, max = { x = 1.2, y = 1.2, z = 1.2 } },
		size = { min = 0.25, max = 0.4 },
		texture = F.tex(F.tint(TEX.feather, c.palette.core), { blend = "alpha", fade = true }), glow = 4,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9 })
	F.ring({ pos = c.to, colour = c.palette.main, size = 0.5, grow = 2.8, life = 0.35 })
end

-- Melee: a wing sweep: feathers flung forward on the arc and a streak behind them.
function R.melee(F, c)
	for i = -2, 2 do
		local bulge = 0.45 - 0.08 * math.abs(i)
		local p = vector.add(c.centre, { x = c.fwd.x * bulge, y = i * 0.22, z = c.fwd.z * bulge })
		F.emit({
			amount = 4, time = 0.12, pos = p,
			vel = { min = vector.multiply(c.fwd, 2), max = vector.multiply(c.fwd, 3.5) },
			drag = { x = 0.5, y = 0.5, z = 0.5 }, exptime = { min = 0.3, max = 0.5 }, size = { min = 0.25, max = 0.38 },
			texture = F.tex(F.tint(TEX.feather, c.palette.main), { blend = "alpha", fade = true }), glow = 4,
		})
	end
	F.emit({
		amount = 6, time = 0.12, pos = c.centre, vel = { min = vector.multiply(c.fwd, 3), max = vector.multiply(c.fwd, 5) },
		exptime = { min = 0.15, max = 0.25 }, size = { min = 0.15, max = 0.25 },
		texture = F.tex(F.tint(TEX.streak, c.palette.core), { blend = "add", fade = true }), vertical = false, glow = 8,
	})
end

-- Area: a gust ring rolls out over the ground, streaks blow outward and feathers hang in the air.
function R.area(F, c)
	F.ring({ pos = c.centre, colour = c.palette.main, size = 0.6, grow = c.radius * 1.5, life = 0.5 })
	F.burst({ pos = c.centre, tex = TEX.streak, colour = c.palette.main, blend = "alpha", amount = 36,
		speed = c.radius * 2, radius = 0.3, life = { 0.4, 0.9 }, size = { 0.2, 0.35 }, glow = 4 })
	F.emit({
		amount = 16, time = 0.4, pos = box(c.centre, c.radius * 0.6), vel = { min = FLOAT, max = { x = 0, y = 1, z = 0 } },
		drag = { x = 0.6, y = 0.3, z = 0.6 }, exptime = { min = 1.0, max = 1.8 }, size = { min = 0.25, max = 0.4 },
		texture = F.tex(F.tint(TEX.feather, c.palette.smoke), { blend = "alpha", alpha = 0.8, fade = true }), glow = 0,
	})
end

-- Impact in layers: a catch light, two pressure rings, streaks and feathers flung out of the hit, feathers that
-- float up from the victim.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.0 })
	F.ring({ pos = at, colour = c.palette.main, size = 0.3, grow = 3.2, life = 0.35 })
	F.ring({ pos = at, colour = c.palette.edge, size = 0.5, grow = 2.2, life = 0.3 })
	F.burst({ pos = at, tex = TEX.streak, colour = c.palette.core, amount = 14, speed = 6, radius = 0.15,
		life = { 0.2, 0.4 }, size = { 0.14, 0.22 }, glow = 8 })
	F.burst({ pos = at, tex = TEX.feather, colour = c.palette.main, amount = 16, speed = 3, life = { 0.8, 1.4 },
		size = { 0.22, 0.34 }, gravity = -0.6, drag = 0.6, blend = "alpha", glow = 4 })
	F.smoke({ pos = at, colour = c.palette.smoke, amount = 4, size = { 0.4, 0.6 }, life = { 0.6, 0.9 }, alpha = 0.3,
		time = 0.25, rise = 0.4 })
	if c.victim and c.victim:get_pos() then
		F.on(c.victim, {
			amount = 10, time = 0.5, pos = { min = { x = -0.25, y = 0.2, z = -0.25 }, max = { x = 0.25, y = 1.0, z = 0.25 } },
			vel = { min = FLOAT, max = { x = 0, y = 1.0, z = 0 } }, drag = { x = 0.5, y = 0.2, z = 0.5 },
			exptime = { min = 0.6, max = 1.0 }, size = { min = 0.2, max = 0.32 },
			texture = F.tex(F.tint(TEX.feather, c.palette.core), { blend = "alpha", fade = true }), glow = 4,
		})
	end
	F.sound("mcl_throwing_throw", { pos = at, gain = 0.7, pitch = 0.6 })
end

minemon.fx.register_move("type:flying", R)
