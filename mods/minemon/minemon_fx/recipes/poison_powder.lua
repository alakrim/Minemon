-- Poison Powder (M2.1 T-FX2-C, status, poison): purple powder poured from above. A pinch of it gathers over the user's
-- head, then a thin column of grains falls onto the target and bursts into a purple ring where it lands, twice. The
-- only move whose powder comes down fast in a column: the other powders float or sink. Budget: cast 80, cloud 160.
-- luacheck: read_globals core vector minemon

local R = {}

local MOTE = "minemon_fx_mote.png"
local ZERO = { x = 0, y = 0, z = 0 }

-- Cast: a pinch of purple motes gathers above the head and is tipped over.
function R.cast(F, c)
	local head = F.anchor(c.user, "head", 1.0)
	if not head then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.inhale({ pos = vector.add(head, { x = 0, y = 0.5, z = 0 }), tex = MOTE, colour = c.palette.main, radius = 0.7,
		amount = 16, time = t, size = { 0.08, 0.14 } })
	F.emit({
		amount = 1, time = 0.02, pos = head, vel = ZERO, exptime = t + 0.05, size = 0.6,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add", grow = { 0.4, 1.0 }, alpha = 0.7 }),
		glow = 10,
	})
	F.sound("default_dig_snappy", { pos = head, gain = 0.3, pitch = 0.9 })
end

-- Cloud: a column of grains pours down from high above the target and splashes into purple rings at its feet.
function R.cloud(F, c)
	local at = c.centre
	local t = c.time or 3
	local column = { min = { x = at.x - 0.25, y = at.y + 2.4, z = at.z - 0.25 },
		max = { x = at.x + 0.25, y = at.y + 2.9, z = at.z + 0.25 } }
	F.emit({
		amount = 34, time = t, pos = column,
		vel = { min = { x = -0.1, y = -2.4, z = -0.1 }, max = { x = 0.1, y = -1.8, z = 0.1 } },
		exptime = { min = 1.0, max = 1.3 }, size = { min = 0.1, max = 0.16 },
		texture = F.tex(F.tint(MOTE, c.palette.main), { blend = "alpha", fade = { 1, 0.5 } }), glow = 6,
	})
	F.emit({
		amount = 8, time = t, pos = column,
		vel = { min = { x = -0.1, y = -2.4, z = -0.1 }, max = { x = 0.1, y = -1.8, z = 0.1 } },
		exptime = { min = 1.0, max = 1.3 }, size = { min = 0.06, max = 0.09 },
		texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add", fade = true }), glow = 10,
	})
	local floor_at = vector.add(at, { x = 0, y = -0.15, z = 0 })
	for _, when in ipairs({ 0.0, 1.4 }) do
		core.after(when, function()
			F.ring({ pos = floor_at, colour = c.palette.main, size = 0.3, grow = 2.6, life = 0.45 })
			F.burst({ pos = vector.add(at, { x = 0, y = -0.5, z = 0 }), colour = c.palette.main, amount = 14, speed = 1.6,
				radius = 0.2, life = { 0.3, 0.6 }, size = { 0.1, 0.16 }, gravity = 2.0, glow = 8 })
		end)
	end
end

minemon.fx.register_move("poison_powder", R)
