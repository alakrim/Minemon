-- Smog (M2.1 wave 2, group B, power 20, poison 40%, accuracy 70, beam): a fog bank. Dark purple smoke rolls out of
-- the user and slides along the line to the victim, slowly, billowing as it goes; on the hit the smoke swells round
-- the victim's middle and hangs there. Weak and slow to cross: the smoke is the look. Sludge is the thick goo rope.
-- Budget at "high": beam ~60, impact ~30.
-- luacheck: read_globals core vector minemon

local R = {}

local ZERO = { x = 0, y = 0, z = 0 }

-- The fog: smoke puffs drift from the user to the stop point at a walking pace, and fade out on the way.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 4
	local dir = vector.multiply(d, 1 / len)
	F.emit({
		amount = 22, time = 0.6, pos = c.from, vel = vector.multiply(dir, speed), drag = { x = 0.3, y = 0.2, z = 0.3 },
		exptime = { min = 0.9, max = 1.4 }, size = { min = 0.38, max = 0.56 },
		jitter = { min = { x = -0.15, y = -0.15, z = -0.15 }, max = { x = 0.15, y = 0.15, z = 0.15 } },
		texture = F.tex(F.tint(F.TEX.smoke, c.palette.smoke), { blend = "alpha", alpha = 0.5, anim = "smoke",
			grow = { 0.7, 1.3 } }),
		glow = 0,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.smoke, size = 0.5, life = 0.1 })
end

-- The billow: smoke swells round the victim's middle, hangs there and lifts off slowly.
function R.impact(F, c)
	local at = c.pos
	F.smoke({ pos = at, colour = c.palette.smoke, amount = 8, size = { 0.4, 0.62 }, life = { 0.9, 1.4 }, rise = 0.5,
		spread = 0.35, alpha = 0.55, time = 0.25 })
	F.emit({
		amount = 6, time = 0.2, pos = { min = vector.subtract(at, { x = 0.3, y = 0.2, z = 0.3 }),
			max = vector.add(at, { x = 0.3, y = 0.4, z = 0.3 }) },
		vel = ZERO, exptime = { min = 0.5, max = 0.8 }, size = { min = 0.2, max = 0.3 },
		texture = F.tex(F.tint(F.TEX.mote, c.palette.core), { blend = "add", fade = true }), glow = 8,
	})
	F.sound("fire_fire", { pos = at, gain = 0.2, pitch = 0.5 })
end

minemon.fx.register_move("smog", R)
