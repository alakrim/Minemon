-- Tackle (M2.1, T-FX2-a): one ball of dust. Dust gathers at the feet while the body braces; the ball rolls out of
-- the chest as one soft tan puff and, when it reaches the victim, bursts flat along the ground. Weak (power 35):
-- small and quick. The burst waits 0.14 s for the ball to arrive. Budget: cast 14, melee 8, impact 30 particles.
-- luacheck: read_globals core vector minemon

local R = {}

local DUST = "minemon_fx_dust.png"
local ZERO = { x = 0, y = 0, z = 0 }

-- Wind-up: dust is drawn in around the feet.
function R.cast(F, c)
	local feet = c.user:get_pos()
	if not feet then
		return false
	end
	local t = math.max(0.15, c.time or 0.3)
	F.inhale({ pos = vector.add(feet, { x = 0, y = 0.15, z = 0 }), tex = DUST, colour = c.palette.smoke, radius = 0.7,
		amount = 14, time = t, size = { 0.2, 0.34 } })
end

-- The ball leaves the chest and rolls at the victim, with two small specks trailing behind it.
function R.melee(F, c)
	local from = vector.add(c.centre, { x = 0, y = -0.2, z = 0 })
	F.emit({
		amount = 1, time = 0.02, pos = from, vel = vector.multiply(c.fwd, 9), exptime = 0.24, size = 0.7,
		texture = F.tex(F.tint(DUST, c.palette.smoke), { blend = "alpha", alpha = 0.85, grow = { 0.7, 1.1 } }),
		glow = 0,
	})
	F.emit({
		amount = 4, time = 0.1, pos = vector.subtract(from, vector.multiply(c.fwd, 0.25)),
		vel = { min = vector.multiply(c.fwd, 3), max = vector.multiply(c.fwd, 5) },
		exptime = { min = 0.2, max = 0.34 }, size = { min = 0.2, max = 0.34 },
		texture = F.tex(F.tint(DUST, c.palette.smoke), { blend = "alpha", alpha = 0.6, fade = true }), glow = 0,
	})
end

-- The ball bursts at the victim's feet: a flat spray of dust with almost no lift, and one white catch light.
function R.impact(F, c)
	local victim = c.victim
	if not (victim and victim:get_pos()) then
		return
	end
	local feet = vector.add(victim:get_pos(), { x = 0, y = 0.15, z = 0 })
	F.flare({ pos = c.pos, colour = c.palette.core, size = 0.8, life = 0.1 })
	core.after(0.14, function()
		if not victim:get_pos() then
			return
		end
		F.emit({
			amount = 9, time = 0.04, pos = { min = vector.add(feet, { x = -0.2, y = 0, z = -0.2 }),
				max = vector.add(feet, { x = 0.2, y = 0.1, z = 0.2 }) },
			vel = { min = { x = -1.6, y = 0, z = -1.6 }, max = { x = 1.6, y = 0.3, z = 1.6 } },
			acc = ZERO, drag = { x = 0.8, y = 0.4, z = 0.8 },
			exptime = { min = 0.45, max = 0.8 }, size = { min = 0.35, max = 0.6 },
			texture = F.tex(F.tint(DUST, c.palette.smoke), { blend = "alpha", alpha = 0.7, fade = true,
				grow = { 0.8, 1.6 } }),
			glow = 0,
		})
		F.sound("default_dirt_footstep", { pos = feet, gain = 0.8, pitch = 0.8 })
	end)
end

minemon.fx.register_move("tackle", R)
