-- Extreme Speed (M2.1, T-FX2-a): a white lance. The user flashes white as it gathers, then a single continuous bar
-- of light runs from its chest to the victim in a fraction of a second, and the victim is hit by a clean white
-- cross of light with a thin ring. Nothing is curved and nothing lingers: it is the straightest look in the group.
-- Strong (power 80), with a long cooldown: the lance is long and bright. Budget: cast 14, melee 16, impact 20
-- particles.
-- luacheck: read_globals core vector minemon

local R = {}

local SPEED = "minemon_fx_speedline.png"
local LANCE_SPEED = 28 -- nodes per second: the bar is drawn in about a tenth of a second

local function middle_of(F, obj)
	return F.anchor(obj, "middle", 0.55) or vector.add(obj:get_pos(), { x = 0, y = 0.5, z = 0 })
end

-- Wind-up: a white flash in the chest, and speed lines are drawn into it from all round.
function R.cast(F, c)
	local at = F.anchor(c.user, "middle", 0.55, 0.0)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.inhale({ pos = at, tex = SPEED, colour = c.palette.core, radius = 1.0, amount = 16, time = t,
		size = { 0.14, 0.22 } })
	F.emit({
		amount = 1, time = t, pos = at, vel = { x = 0, y = 0, z = 0 }, exptime = 0.2, size = 0.9,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add", fade = true, grow = { 0.4, 1.1 } }),
		glow = 14,
	})
end

-- The lance: one bar of light from the chest to the victim, drawn in one burst of fast streaks.
function R.melee(F, c)
	local from = c.centre
	local to = middle_of(F, c.target)
	local d = vector.subtract(to, from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local dir = vector.multiply(d, 1 / len)
	F.emit({
		amount = 14, time = 0.06, pos = from, vel = vector.multiply(dir, LANCE_SPEED),
		exptime = len / LANCE_SPEED, size = { min = 0.3, max = 0.45 },
		texture = F.tex(F.tint(SPEED, c.palette.core), { blend = "add", fade = true }), glow = 14,
	}, from)
	F.emit({
		amount = 1, time = 0.02, pos = from, vel = vector.multiply(dir, LANCE_SPEED), exptime = len / LANCE_SPEED,
		size = 0.8,
		texture = F.tex(F.tint(F.TEX.glow, "#ffffff"), { blend = "add", grow = { 1, 0.8 } }), glow = 14,
	}, from)
end

-- The hit: a white cross of light on the victim, a thin ring, and a fan of sparks.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = "#ffffff", size = 1.8, life = 0.14 })
	F.ring({ pos = at, colour = c.palette.core, size = 0.4, grow = 2.2, life = 0.18 })
	F.burst({ pos = at, colour = c.palette.core, amount = 8, speed = 4, life = { 0.15, 0.3 }, size = { 0.08, 0.14 },
		glow = 14 })
	F.sound("mcl_criticals_hit.0", { pos = at, gain = 0.6, pitch = 1.8 })
end

minemon.fx.register_move("extreme_speed", R)
