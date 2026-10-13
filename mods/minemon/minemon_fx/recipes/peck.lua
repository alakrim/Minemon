-- Peck (M2.1, T-FX2-a): a pinprick. A quick beak jab: three tiny darts of light go from the beak to the victim in
-- one blink, a small white point marks the hit, and two feathers are flicked off it and float away. The smallest
-- look in the group, on purpose (power 35). Budget: cast 8, melee 6, impact 16 particles.
-- luacheck: read_globals core vector minemon

local R = {}

local STREAK = "minemon_fx_streak.png"
local FEATHER = "minemon_fx_feather.png"

-- Wind-up: two wind streaks are drawn in at the shoulders, and a glint shows at the beak.
function R.cast(F, c)
	local beak = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not beak then
		return false
	end
	local t = math.max(0.15, c.time or 0.3)
	F.inhale({ pos = beak, tex = STREAK, colour = c.palette.main, radius = 0.9, amount = 10, time = t,
		size = { 0.08, 0.14 } })
	F.emit({
		amount = 1, time = t, pos = beak, vel = { x = 0, y = 0, z = 0 }, exptime = 0.18, size = 0.35,
		texture = F.tex(F.tint(F.TEX.flare, c.palette.core), { blend = "add", fade = true, grow = { 0.5, 1.0 } }),
		glow = 10,
	})
end

-- The jab: three tiny darts leave the beak, one behind the other, straight at the victim.
function R.melee(F, c)
	local beak = F.anchor(c.user, "mouth", 0.75, 0.6) or c.centre
	for i = 0, 2 do
		F.emit({
			amount = 1, time = 0.02, pos = vector.subtract(beak, vector.multiply(c.fwd, 0.15 * i)),
			vel = vector.multiply(c.fwd, 14), exptime = 0.1, size = 0.12,
			texture = F.tex(F.tint(F.TEX.spark, c.palette.core), { blend = "add", fade = true }), glow = 10,
		})
	end
end

-- The prick: a small white point, and two feathers flicked off the hit that drift down slowly.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 0.6, life = 0.08 })
	for i = 1, 2 do
		F.emit({
			amount = 1, time = 0.02, pos = at,
			vel = { x = (i == 1 and 1 or -1) * 0.8, y = 1.6, z = 0.4 * (i == 1 and 1 or -1) },
			acc = { x = 0, y = -1.2, z = 0 }, drag = { x = 0.8, y = 0.8, z = 0.8 },
			exptime = 0.7, size = 0.18,
			texture = F.tex(F.tint(FEATHER, c.palette.core), { blend = "alpha", fade = true }), glow = 0,
		})
	end
	F.sound("default_dig_oddly_breakable_by_hand", { pos = at, gain = 0.4, pitch = 2.2 })
end

minemon.fx.register_move("peck", R)
