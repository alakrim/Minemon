-- Quick Attack (M2.1, T-FX2-a): afterimages. The user blurs: faint copies of its glow are left behind it (wind-up),
-- then a row of white streaks is drawn along the dash, each a moment behind the last (melee), and the victim takes
-- a sharp white star (impact). Priority move: the whole look is short. Budget: cast 12, melee 14, impact 14
-- particles.
-- luacheck: read_globals core vector minemon

local R = {}

local STREAK = "minemon_fx_streak.png^[transformR90" -- turned: a horizontal white streak
local STAR = "minemon_fx_impact_star.png"

local function middle_of(F, obj)
	return F.anchor(obj, "middle", 0.55) or vector.add(obj:get_pos(), { x = 0, y = 0.5, z = 0 })
end

-- Wind-up: three faint copies of the user's glow trail behind it, each a little further back.
function R.cast(F, c)
	local at = F.anchor(c.user, "middle", 0.6, 0.4)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.3)
	for k = 1, 3 do
		F.emit({
			amount = 1, time = t, pos = vector.subtract(at, vector.multiply(c.fwd, 0.25 * k)),
			vel = { x = 0, y = 0, z = 0 }, exptime = 0.22, size = 0.7,
			texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add", fade = { 0.6, 0 },
				grow = { 0.8, 1.1 } }),
			glow = 10,
		})
	end
end

-- The dash: three white streaks laid along the path, one after another, each a little shorter and fainter.
function R.melee(F, c)
	local from = c.centre
	local to = middle_of(F, c.target)
	local span = vector.subtract(to, from)
	for k = 1, 3 do
		local p = vector.add(from, vector.multiply(span, 0.2 + 0.25 * (k - 1)))
		F.emit({
			amount = 1, time = 0.02, pos = p, vel = { x = 0, y = 0, z = 0 }, exptime = 0.12 + 0.05 * k,
			size = 1.0 - 0.12 * (k - 1),
			texture = F.tex(F.tint(STREAK, c.palette.core), { blend = "add", fade = { 0.9, 0 }, grow = { 1, 0.4 } }),
			glow = 10,
		})
	end
end

-- A sharp white star on the victim, two tiny flicks off it, and a click.
function R.impact(F, c)
	local at = c.pos
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = { x = 0, y = 0, z = 0 }, exptime = 0.22, size = 1.4,
		texture = F.tex(F.tint(STAR, "#ffffff"), { blend = "add", fade = true, grow = { 0.6, 1.1 } }), glow = 10,
	})
	F.emit({
		amount = 2, time = 0.03, pos = at,
		vel = { min = { x = -2.5, y = 0.5, z = -2.5 }, max = { x = 2.5, y = 1.5, z = 2.5 } },
		exptime = { min = 0.12, max = 0.2 }, size = { min = 0.1, max = 0.16 },
		texture = F.tex(F.tint(F.TEX.spark, c.palette.core), { blend = "add", fade = true }), glow = 10,
	})
	F.sound("default_dig_oddly_breakable_by_hand", { pos = at, gain = 0.5, pitch = 1.9 })
end

minemon.fx.register_move("quick_attack", R)
