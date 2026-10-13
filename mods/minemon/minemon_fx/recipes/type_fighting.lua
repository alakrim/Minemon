-- Fighting type (M2.1, T-FX-b): every fighting move without a recipe of its own. Impact stars, speed lines and crescent
-- slashes, with a short heavy hit stop. Five beats: speed lines are drawn into the chest and the fists glow; a burst of
-- speed lines leaves the muzzle; the projectile is a small star-shaped blow with a speed-line trail; the impact is a
-- star with speed lines thrown out and a slash on the victim, then a 0.12 s hit stop; the aftermath is the default
-- cloud and aura. Budget (docs/ART_GUIDE.md): cast 80, launch 60, projectile 90/s, impact 160, area 200, beam 160.
-- luacheck: read_globals core vector minemon

local R = {}

local STAR = "minemon_fx_impact_star.png" -- a four-ray impact star with a hot core
local SPEED = "minemon_fx_speedline.png" -- a tapered horizontal speed streak
local SLASH = "minemon_fx_slash.png" -- a crescent melee arc
local ZERO = { x = 0, y = 0, z = 0 }

-- A radial burst of speed lines out of pos (attraction negative, as F.burst). speed in m/s.
local function radial(F, pos, speed, amount, colour, life, size)
	F.emit({
		amount = amount, time = 0.06, pos = pos, radius = { min = 0.1, max = 0.3, bias = 0 },
		attract = { kind = "point", origin = pos, strength = { min = -speed / 0.3 * 0.6, max = -speed / 0.3 },
			die_on_contact = false },
		vel = ZERO, exptime = { min = life[1], max = life[2] }, size = { min = size[1], max = size[2] },
		texture = F.tex(F.tint(SPEED, colour), { blend = "add", fade = true }), glow = 14,
	})
end

-- One still frame of a sprite (a star or a slash), short-lived and growing: a flash that stays for a moment.
local function still(F, tex, colour, pos, size, life, grow)
	return F.emit({
		amount = 1, time = 0.02, pos = pos, vel = ZERO, exptime = life, size = size,
		texture = F.tex(F.tint(tex, colour), { blend = "add", fade = true, grow = grow }), glow = 14,
	})
end

-- Wind-up: speed lines are drawn into the chest, a ring closes in on it, and a glow swells.
function R.cast(F, c)
	local at = F.anchor(c.user, "middle", 0.6, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.inhale({ pos = at, tex = SPEED, colour = c.palette.main, radius = 1.2, amount = 20, time = t,
		size = { 0.3, 0.45 } })
	still(F, F.TEX.ring, c.palette.main, at, 2.0, t, { 1, 0.2 })
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t + 0.05, size = 0.7,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add", grow = { 0.2, 1.0 }, alpha = 0.7 }),
		glow = 14,
	})
	F.sound("default_dig_oddly_breakable_by_hand", { pos = at, gain = 0.3, pitch = 1.8 })
end

-- Launch: a star flash at the muzzle and speed lines thrown along the shot.
function R.launch(F, c)
	still(F, STAR, c.palette.core, c.from, 1.1, 0.2, { 0.6, 1.2 })
	F.emit({
		amount = 14, time = 0.05, pos = c.from,
		vel = { min = vector.multiply(c.dir, 6), max = vector.multiply(c.dir, 9) },
		exptime = { min = 0.15, max = 0.3 }, size = { min = 0.35, max = 0.5 },
		texture = F.tex(F.tint(SPEED, c.palette.main), { blend = "add", fade = true }), glow = 14,
	})
	F.sound("default_dig_oddly_breakable_by_hand", { pos = c.from, gain = 0.5, pitch = 1.6 })
end

-- The orb: a small star-shaped blow with a trail of speed lines and sparks. Returns true: decorated.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(STAR, c.palette.core) }, visual_size = { x = 0.55, y = 0.55 },
		glow = 14 })
	F.on(c.obj, {
		amount = 24, time = 1.5, pos = { min = { x = -0.05, y = -0.05, z = -0.05 }, max = { x = 0.05, y = 0.05, z = 0.05 } },
		vel = { min = { x = -0.2, y = -0.2, z = -0.2 }, max = { x = 0.2, y = 0.2, z = 0.2 } },
		exptime = { min = 0.12, max = 0.22 }, size = { min = 0.3, max = 0.42 },
		texture = F.tex(F.tint(SPEED, c.palette.main), { blend = "add", fade = true }), glow = 14,
	})
	F.on(c.obj, {
		amount = 10, time = 1.5, pos = { x = 0, y = 0, z = 0 },
		vel = { min = { x = -0.6, y = -0.6, z = -0.6 }, max = { x = 0.6, y = 0.6, z = 0.6 } },
		exptime = { min = 0.2, max = 0.35 }, size = { min = 0.12, max = 0.2 },
		texture = F.tex(F.tint(F.TEX.spark, c.palette.core), { blend = "add", fade = true }), glow = 14,
	})
	return true
end

-- Beam: a line of speed lines from the user to the stop point, and a star where the blow lands.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 40
	local dir = vector.multiply(d, 1 / len)
	F.emit({
		amount = 50, time = 0.2, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = { min = 0.4, max = 0.6 },
		texture = F.tex(F.tint(SPEED, c.palette.main), { blend = "add", fade = true }), glow = 14,
	}, c.from)
	F.emit({
		amount = 30, time = 0.2, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = { min = 0.2, max = 0.3 },
		texture = F.tex(F.tint(SPEED, c.palette.core), { blend = "add", fade = true }), glow = 14,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.8 })
	still(F, STAR, c.palette.core, c.to, 1.6, 0.25, { 0.6, 1.2 })
	radial(F, c.to, 5, 16, c.palette.main, { 0.2, 0.4 }, { 0.3, 0.45 })
end

-- Melee: two crescent slashes crossing in front of the user, a star at their meeting point and speed lines swept along.
function R.melee(F, c)
	local at = vector.add(c.centre, vector.multiply(c.fwd, 0.4))
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.22, size = 2.0,
		texture = F.tex(F.tint(SLASH, c.palette.core), { blend = "add", fade = true, grow = { 0.8, 1.2 } }),
		glow = 14,
	})
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.22, size = 2.0,
		texture = F.tex(F.tint(SLASH .. "^[transformR90", c.palette.main), { blend = "add", fade = true,
			grow = { 0.8, 1.2 } }),
		glow = 14,
	})
	still(F, STAR, c.palette.core, at, 1.0, 0.18, { 0.6, 1.0 })
	F.emit({
		amount = 20, time = 0.12, pos = at, radius = { min = 0.2, max = 0.5, bias = 0 },
		vel = { min = vector.multiply(c.fwd, 3), max = vector.multiply(c.fwd, 6) },
		exptime = { min = 0.15, max = 0.3 }, size = { min = 0.3, max = 0.45 },
		texture = F.tex(F.tint(SPEED, c.palette.main), { blend = "add", fade = true }), glow = 14,
	})
end

-- Area: a shock ring, speed lines and a puff of dust thrown out from the centre.
function R.area(F, c)
	F.flare({ pos = c.centre, colour = c.palette.core, size = 1.2, life = 0.2 })
	F.ring({ pos = c.centre, colour = c.palette.edge, size = 0.6, grow = c.radius * 1.5, life = 0.4 })
	radial(F, c.centre, c.radius * 2, 30, c.palette.main, { 0.3, 0.5 }, { 0.35, 0.5 })
	F.burst({ pos = c.centre, tex = F.TEX.dust, colour = c.palette.smoke, blend = "alpha", amount = 16,
		speed = c.radius, life = { 0.6, 1.0 }, size = { 0.6, 0.9 }, gravity = -0.5, glow = 0 })
end

-- Impact: an impact star, speed lines thrown out, a slash on the victim, a ring, and a hit stop of 0.12 s.
function R.impact(F, c)
	local at = c.pos
	still(F, STAR, c.palette.core, at, 1.9, 0.2, { 0.5, 1.1 })
	radial(F, at, 5, 18, c.palette.main, { 0.25, 0.45 }, { 0.35, 0.5 })
	local mirror = math.random() < 0.5 and "" or "^[transformFX"
	still(F, SLASH .. mirror, c.palette.core, at, 1.5, 0.18, { 0.7, 1.1 })
	F.burst({ pos = at, tex = F.TEX.dust, colour = c.palette.smoke, blend = "alpha", amount = 8, speed = 2,
		life = { 0.4, 0.7 }, size = { 0.4, 0.6 }, gravity = -0.3, glow = 0 })
	F.ring({ pos = at, colour = c.palette.edge, size = 0.4, grow = 2.6, life = 0.28 })
	if c.victim and c.user then
		F.hitstop({ c.victim, c.user }, 0.12)
	end
	F.sound("mcl_bows_hit_other", { pos = at, gain = 0.8, pitch = 1.1 })
end

minemon.fx.register_move("type:fighting", R)
