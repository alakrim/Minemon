-- Mega Punch (M2.1, T-FX2-a): a wave. The blow lands as three concentric ripples that run out over the victim one
-- after another, like a sound wave in water, with a hard white star at the centre. Wind-up: a ring closes in on the
-- fist. Strong (power 80): big and slow. Budget: cast 12, melee 10, impact 24 particles and three rings.
-- luacheck: read_globals core vector minemon

local R = {}

local STAR = "minemon_fx_impact_star.png"

-- Wind-up: a ring draws in on the fist (it shrinks from wide to tight) and the chest glows.
function R.cast(F, c)
	local at = F.anchor(c.user, "middle", 0.6, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.emit({
		amount = 1, time = t, pos = at, vel = { x = 0, y = 0, z = 0 }, exptime = t, size = 1.6,
		texture = F.tex(F.tint(F.TEX.ring, c.palette.core), { blend = "add", fade = true, grow = { 1.6, 0.5 } }),
		glow = 10,
	})
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = { x = 0, y = 0, z = 0 }, exptime = t + 0.05, size = 0.7,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add", grow = { 0.3, 1.0 }, alpha = 0.7 }),
		glow = 10,
	})
end

-- The fist: a bright glow travels at the victim with a short trail of white sparks.
function R.melee(F, c)
	F.emit({
		amount = 1, time = 0.02, pos = c.centre, vel = vector.multiply(c.fwd, 6), exptime = 0.16, size = 0.9,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add", fade = true, grow = { 1, 0.6 } }),
		glow = 10,
	})
end

-- The blow: a star, then three ripples out of the hit, each a little later and wider than the one before.
function R.impact(F, c)
	local at = c.pos
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = { x = 0, y = 0, z = 0 }, exptime = 0.24, size = 1.7,
		texture = F.tex(F.tint(STAR, c.palette.core), { blend = "add", fade = true, grow = { 0.6, 1.1 } }), glow = 10,
	})
	F.flare({ pos = at, colour = c.palette.core, size = 1.2, life = 0.12 })
	local ripples = {
		{ delay = 0.0, colour = c.palette.core, size = 0.5, grow = 2.6 },
		{ delay = 0.08, colour = c.palette.main, size = 0.5, grow = 3.2 },
		{ delay = 0.16, colour = c.palette.edge, size = 0.5, grow = 3.8 },
	}
	for _, r in ipairs(ripples) do
		core.after(r.delay, function()
			F.ring({ pos = at, colour = r.colour, size = r.size, grow = r.grow, life = 0.4 })
		end)
	end
	F.sound("mcl_criticals_hit.1", { pos = at, gain = 0.8, pitch = 0.85 })
end

minemon.fx.register_move("mega_punch", R)
