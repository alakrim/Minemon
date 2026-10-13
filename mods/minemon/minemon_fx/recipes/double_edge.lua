-- Double-Edge (M2.1, T-FX2-a): the rebound. The user is wrapped in a gold glow as it charges (a ring of gold
-- travels with it), the victim takes a gold flash and a shock ring, and the sparks do not all fly away from the
-- blow: a crowd of them comes back at the user, the recoil the move is named for. Strongest of the group (power
-- 120): big and gold. Budget: cast 16, melee 14, impact 60 particles.
-- luacheck: read_globals core vector minemon

local R = {}

local GOLD = "#ffd27a"
local GOLD_CORE = "#fff3c8"

local function middle_of(F, obj)
	return F.anchor(obj, "middle", 0.55) or vector.add(obj:get_pos(), { x = 0, y = 0.5, z = 0 })
end

-- Wind-up: a gold glow swells round the body and motes are drawn into the chest.
function R.cast(F, c)
	local at = F.anchor(c.user, "middle", 0.5, 0.0)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.emit({
		amount = 1, time = t, pos = at, vel = { x = 0, y = 0, z = 0 }, exptime = t + 0.05, size = 1.4,
		texture = F.tex(F.tint(F.TEX.glow, GOLD), { blend = "add", grow = { 0.4, 1.2 }, alpha = 0.8 }), glow = 12,
	})
	F.inhale({ pos = at, tex = F.TEX.mote, colour = GOLD, radius = 1.2, amount = 18, time = t, size = { 0.08, 0.14 } })
end

-- The charge: a gold ring leaves the chest with the body, and a second, smaller one follows it.
function R.melee(F, c)
	F.emit({
		amount = 1, time = 0.02, pos = c.centre, vel = vector.multiply(c.fwd, 5), exptime = 0.2, size = 1.3,
		texture = F.tex(F.tint(F.TEX.ring, GOLD), { blend = "add", fade = true, grow = { 0.8, 1.3 } }), glow = 12,
	})
	F.emit({
		amount = 1, time = 0.02, pos = vector.subtract(c.centre, vector.multiply(c.fwd, 0.3)),
		vel = vector.multiply(c.fwd, 5), exptime = 0.16, size = 0.9,
		texture = F.tex(F.tint(F.TEX.ring, GOLD_CORE), { blend = "add", fade = true, grow = { 0.8, 1.2 } }), glow = 12,
	})
end

-- The blow: a gold flash, a shock ring, sparks thrown out from the victim, and sparks that come back at the user.
function R.impact(F, c)
	local at = c.pos
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = { x = 0, y = 0, z = 0 }, exptime = 0.2, size = 2.0,
		texture = F.tex(F.tint(F.TEX.flare, GOLD_CORE), { blend = "add", fade = true, grow = { 0.8, 1.2 } }), glow = 12,
	})
	F.ring({ pos = at, colour = GOLD, size = 0.6, grow = 3.5, life = 0.34 })
	F.burst({ pos = at, colour = GOLD, amount = 14, speed = 4, life = { 0.25, 0.5 }, size = { 0.1, 0.18 },
		gravity = 3, glow = 12 })
	-- The recoil: sparks that come back at the user from the blow.
	local user_mid = middle_of(F, c.user)
	local back = vector.normalize(vector.subtract(user_mid, at))
	F.emit({
		amount = 12, time = 0.05, pos = at, radius = { min = 0.05, max = 0.2, bias = 0 },
		vel = { min = vector.add(vector.multiply(back, 3), { x = -0.6, y = 0.2, z = -0.6 }),
			max = vector.add(vector.multiply(back, 5), { x = 0.6, y = 1.2, z = 0.6 }) },
		acc = { x = 0, y = -5, z = 0 }, collisiondetection = true, bounce = { min = 0.1, max = 0.3 },
		exptime = { min = 0.35, max = 0.6 }, size = { min = 0.08, max = 0.14 },
		texture = F.tex(F.tint(F.TEX.spark, GOLD), { blend = "add", fade = true }), glow = 12,
	})
	F.sound("mcl_criticals_hit.2", { pos = at, gain = 0.9, pitch = 0.75 })
end

minemon.fx.register_move("double_edge", R)
