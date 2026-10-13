-- Sleep Powder (M2.1 T-FX2-C, status, grass): slow blue-white pollen that sinks. A little is shaken off the user's
-- head and carried across; the cloud over the target is a soft veil that settles down onto it, with glints that wink
-- as they fall. Nothing rises: the whole look goes down. Budget: docs/ART_GUIDE.md 4 (cast 80, cloud 160).
-- luacheck: read_globals core vector minemon

local R = {}

local MOTE = "minemon_fx_mote.png"
local STAR = "minemon_fx_star.png"
local POLLEN = "#e6f2ff"
local ZERO = { x = 0, y = 0, z = 0 }

-- Cast: pollen trickles off the head and drifts toward the target.
function R.cast(F, c)
	if not (c.user and c.user:get_pos() and c.target and c.target:get_pos()) then
		return false
	end
	local head = F.anchor(c.user, "head", 1.0) or c.user:get_pos()
	local dir = vector.normalize(vector.subtract(c.target:get_pos(), head))
	local t = math.max(0.2, c.time or 0.4)
	F.emit({
		amount = 16, time = t, pos = head,
		vel = { min = vector.add(vector.multiply(dir, 0.8), { x = -0.3, y = 0.1, z = -0.3 }),
			max = vector.add(vector.multiply(dir, 1.6), { x = 0.3, y = 0.5, z = 0.3 }) },
		acc = { x = 0, y = -0.6, z = 0 }, drag = { x = 0.8, y = 0.6, z = 0.8 },
		exptime = { min = 0.7, max = 1.1 }, size = { min = 0.12, max = 0.18 },
		texture = F.tex(F.tint(MOTE, POLLEN), { blend = "alpha", fade = true }),
	})
	F.emit({
		amount = 1, time = 0.02, pos = head, vel = ZERO, exptime = t + 0.05, size = 0.7,
		texture = F.tex(F.tint(F.TEX.glow, POLLEN), { blend = "add", grow = { 0.3, 1.0 }, alpha = 0.6 }), glow = 8,
	})
	F.sound("default_dig_snappy", { pos = head, gain = 0.25, pitch = 1.8 })
end

-- Cloud: a veil of pollen high over the target, sinking slowly, with a few glints and a faint blue hush at its heart.
function R.cloud(F, c)
	local at = c.centre
	local t = c.time or 3
	local r = (c.radius or 2.5) * 0.8
	local high = { min = { x = at.x - r, y = at.y + 1.4, z = at.z - r },
		max = { x = at.x + r, y = at.y + 2.4, z = at.z + r } }
	local sink = { min = { x = -0.1, y = -0.4, z = -0.1 }, max = { x = 0.1, y = -0.2, z = 0.1 } }
	F.emit({
		amount = 34, time = t, pos = high, vel = sink, drag = { x = 0.5, y = 0.3, z = 0.5 },
		exptime = { min = 1.8, max = 2.4 }, size = { min = 0.12, max = 0.18 },
		texture = F.tex(F.tint(MOTE, POLLEN), { blend = "alpha", fade = true }), glow = 0,
	})
	F.emit({
		amount = 10, time = t, pos = high, vel = sink, drag = { x = 0.5, y = 0.3, z = 0.5 },
		exptime = { min = 0.8, max = 1.4 }, size = { min = 0.06, max = 0.1 },
		texture = F.tex(F.tint(STAR, "#ffffff"), { blend = "add", fade = true }), glow = 10,
	})
	F.emit({
		amount = 1, time = 0.02, pos = vector.add(at, { x = 0, y = 0.6, z = 0 }), vel = ZERO, exptime = t, size = 1.6,
		texture = F.tex(F.tint(F.TEX.glow, "#8fb8ff"), { blend = "add", grow = { 0.6, 1.0 }, alpha = 0.22 }), glow = 6,
	})
end

minemon.fx.register_move("sleep_powder", R)
