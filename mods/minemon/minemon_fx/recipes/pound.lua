-- Pound (M2.1, T-FX2-a): a blunt thump. The idea is a ring that PRESSES in: a fat shock ring is drawn onto the
-- victim and shrinks as it lands, like a flat palm pushing a wall, with a dull puff of dust. Wind-up: a glow is
-- coiled back at the chest and shrinks as the blow is readied. Budget: cast 10, melee 8, impact 26 particles.
-- luacheck: read_globals core vector minemon

local R = {}

local DUST = "minemon_fx_dust.png"

-- Wind-up: the glow at the chest tightens (it shrinks from wide to small: the blow is coiled).
function R.cast(F, c)
	local at = F.anchor(c.user, "middle", 0.65, 0.5)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.3)
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = { x = 0, y = 0, z = 0 }, exptime = t, size = 0.9,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add", grow = { 1.0, 0.4 }, alpha = 0.85 }),
		glow = 10,
	})
end

-- The blow goes out as a short, fat bar of light at fist height.
function R.melee(F, c)
	F.emit({
		amount = 1, time = 0.02, pos = c.centre, vel = vector.multiply(c.fwd, 6), exptime = 0.16, size = 0.8,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add", fade = true, grow = { 1, 0.6 } }),
		glow = 10,
	})
end

-- A ring that shrinks onto the victim (grow 1.9 -> 0.7), a white flash, and a dull dust pop at the feet.
function R.impact(F, c)
	local at = c.pos
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = { x = 0, y = 0, z = 0 }, exptime = 0.26, size = 1.5,
		texture = F.tex(F.tint(F.TEX.ring, c.palette.core), { blend = "add", fade = true, grow = { 1.9, 0.7 } }),
		glow = 10,
	})
	F.flare({ pos = at, colour = c.palette.core, size = 1.0, life = 0.1 })
	F.emit({
		amount = 6, time = 0.04, pos = at, radius = { min = 0.1, max = 0.25, bias = 0 },
		vel = { min = { x = -1, y = -0.2, z = -1 }, max = { x = 1, y = 0.4, z = 1 } },
		exptime = { min = 0.35, max = 0.6 }, size = { min = 0.4, max = 0.6 },
		texture = F.tex(F.tint(DUST, c.palette.smoke), { blend = "alpha", alpha = 0.6, fade = true, grow = { 0.7, 1.4 } }),
		glow = 0,
	})
	F.sound("mcl_criticals_hit.0", { pos = at, gain = 0.7, pitch = 0.7 })
end

minemon.fx.register_move("pound", R)
