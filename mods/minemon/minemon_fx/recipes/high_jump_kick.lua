-- High Jump Kick (M2.1, T-FX-b, fighting, melee, 85 power): the kick signature. A low, wide sweep of speed
-- lines and a kicked-up cloud of dust along the ground; the impact is a shock ring that spreads flat on the
-- ground, a dust burst and a 0.12 s hit stop. Budget: melee ~80 particles, impact ~70.
-- luacheck: read_globals core vector minemon

local R = {}

local STAR = "minemon_fx_impact_star.png"
local SPEED = "minemon_fx_speedline.png"
local SLASH = "minemon_fx_slash.png"
local ZERO = { x = 0, y = 0, z = 0 }

-- The kick's line: knee-high, a little in front of the user.
local function low(c)
	local feet = c.user:get_pos()
	return vector.add(feet, vector.add(vector.multiply(c.fwd, 0.6), { x = 0, y = 0.35, z = 0 }))
end

function R.melee(F, c)
	if not c.user:get_pos() then
		return
	end
	local at = low(c)
	F.emit({
		amount = 18, time = 0.15, pos = at, radius = { min = 0.3, max = 0.8, bias = 0 },
		vel = { min = vector.multiply(c.fwd, 4), max = vector.multiply(c.fwd, 6) },
		exptime = { min = 0.2, max = 0.35 }, size = { min = 0.35, max = 0.55 },
		texture = F.tex(F.tint(SPEED, c.palette.main), { blend = "add", fade = true }), glow = 14,
	})
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.2, size = 2.2,
		texture = F.tex(F.tint(SLASH .. "^[transformR90", c.palette.core), { blend = "add", fade = true,
			grow = { 0.8, 1.2 } }), glow = 14,
	})
	F.emit({
		amount = 20, time = 0.15, pos = at, radius = { min = 0.2, max = 0.6, bias = 0 },
		vel = { min = vector.add(vector.multiply(c.fwd, 1.5), { x = -0.5, y = 1, z = -0.5 }),
			max = vector.add(vector.multiply(c.fwd, 3), { x = 0.5, y = 2, z = 0.5 }) },
		acc = { x = 0, y = -6, z = 0 }, exptime = { min = 0.5, max = 0.8 }, size = { min = 0.5, max = 0.8 },
		texture = F.tex(F.tint(F.TEX.dust, c.palette.smoke), { blend = "alpha", alpha = 0.6, grow = { 0.6, 1.3 } }),
		glow = 0,
	})
	F.sound("default_dig_choppy", { pos = at, gain = 0.7, pitch = 1.3 })
end

-- The shock: a ring that spreads flat along the ground, a star where the foot lands, speed lines and dust.
function R.impact(F, c)
	local at = c.pos
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.2, size = 1.6,
		texture = F.tex(F.tint(STAR, c.palette.core), { blend = "add", fade = true, grow = { 0.5, 1.1 } }), glow = 14,
	})
	F.ring({ pos = at, colour = c.palette.main, size = 0.5, grow = 4.5, life = 0.4 })
	F.emit({
		amount = 16, time = 0.05, pos = at, radius = { min = 0.1, max = 0.3, bias = 0 },
		attract = { kind = "point", origin = at, strength = { min = -12, max = -20 }, die_on_contact = false },
		vel = ZERO, exptime = { min = 0.25, max = 0.4 }, size = { min = 0.35, max = 0.5 },
		texture = F.tex(F.tint(SPEED, c.palette.main), { blend = "add", fade = true }), glow = 14,
	})
	F.burst({ pos = at, tex = F.TEX.dust, colour = c.palette.smoke, blend = "alpha", amount = 18, speed = 3,
		life = { 0.6, 1.0 }, size = { 0.6, 0.9 }, gravity = -0.4, glow = 0 })
	if c.victim and c.user then
		F.hitstop({ c.victim, c.user }, 0.12)
	end
	F.sound("mcl_bows_hit_other", { pos = at, gain = 0.9, pitch = 0.9 })
end

minemon.fx.register_move("high_jump_kick", R)
