-- Cross Chop (M2.1, T-FX-b, fighting, melee, 100 power): the signature of fighting. Two crescent slashes cross ahead of
-- the user with a star where they meet and speed lines swept through; the impact is an X of two slashes on the victim,
-- a big star, a ring and a 0.12 s hit stop. Budget: melee ~70 particles, impact ~70.
-- luacheck: read_globals core vector minemon

local R = {}

local STAR = "minemon_fx_impact_star.png"
local SPEED = "minemon_fx_speedline.png"
local SLASH = "minemon_fx_slash.png"
local ZERO = { x = 0, y = 0, z = 0 }

function R.melee(F, c)
	local at = vector.add(c.centre, vector.multiply(c.fwd, 0.45))
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.2, size = 2.6,
		texture = F.tex(F.tint(SLASH, c.palette.core), { blend = "add", fade = true, grow = { 0.9, 1.2 } }), glow = 14,
	})
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.2, size = 2.6,
		texture = F.tex(F.tint(SLASH .. "^[transformR90", c.palette.main), { blend = "add", fade = true,
			grow = { 0.9, 1.2 } }), glow = 14,
	})
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.18, size = 1.6,
		texture = F.tex(F.tint(STAR, c.palette.core), { blend = "add", fade = true, grow = { 0.6, 1.0 } }), glow = 14,
	})
	F.emit({
		amount = 24, time = 0.12, pos = at, radius = { min = 0.2, max = 0.5, bias = 0 },
		vel = { min = vector.multiply(c.fwd, 4), max = vector.multiply(c.fwd, 7) },
		exptime = { min = 0.15, max = 0.3 }, size = { min = 0.35, max = 0.5 },
		texture = F.tex(F.tint(SPEED, c.palette.main), { blend = "add", fade = true }), glow = 14,
	})
	F.sound("default_dig_oddly_breakable_by_hand", { pos = at, gain = 0.8, pitch = 0.7 })
end

function R.impact(F, c)
	local at = c.pos
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.24, size = 2.4,
		texture = F.tex(F.tint(STAR, c.palette.core), { blend = "add", fade = true, grow = { 0.6, 1.1 } }), glow = 14,
	})
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.2, size = 2.2,
		texture = F.tex(F.tint(SLASH, c.palette.core), { blend = "add", fade = true, grow = { 0.8, 1.1 } }), glow = 14,
	})
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.2, size = 2.2,
		texture = F.tex(F.tint(SLASH .. "^[transformR90", c.palette.core), { blend = "add", fade = true,
			grow = { 0.8, 1.1 } }), glow = 14,
	})
	F.emit({
		amount = 26, time = 0.06, pos = at, radius = { min = 0.1, max = 0.3, bias = 0 },
		attract = { kind = "point", origin = at, strength = { min = -16, max = -26 }, die_on_contact = false },
		vel = ZERO, exptime = { min = 0.25, max = 0.45 }, size = { min = 0.35, max = 0.5 },
		texture = F.tex(F.tint(SPEED, c.palette.main), { blend = "add", fade = true }), glow = 14,
	})
	F.ring({ pos = at, colour = c.palette.edge, size = 0.6, grow = 3.4, life = 0.35 })
	F.burst({ pos = at, tex = F.TEX.dust, colour = c.palette.smoke, blend = "alpha", amount = 10, speed = 2,
		life = { 0.4, 0.7 }, size = { 0.4, 0.6 }, gravity = -0.3, glow = 0 })
	if c.victim and c.user then
		F.hitstop({ c.victim, c.user }, 0.12)
	end
	F.sound("mcl_bows_hit_other", { pos = at, gain = 1.0, pitch = 0.8 })
end

minemon.fx.register_move("cross_chop", R)
