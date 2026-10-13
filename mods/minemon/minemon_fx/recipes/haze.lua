-- Haze (M2.1 T-FX2-C, status, ice, no effect of its own): the mist that clears every stat change. A cold breath leaves
-- the user's mouth as a few frost glints, then a pale mist sinks from above the target over the cloud's life while
-- frost glints rise out of the ground through it: everything comes down, everything clears. The two directions are the
-- look. Budget: cloud 160; smoke at most 0.7 per particle.
-- luacheck: read_globals core vector minemon

local R = {}

local FROST = "minemon_fx_frost.png"
local MIST = "#dff6ff"
local ZERO = { x = 0, y = 0, z = 0 }

-- Cast: a cold breath, a few frost glints that scatter from the mouth.
function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.inhale({ pos = at, tex = FROST, colour = "#a8f0ff", radius = 0.7, amount = 10, time = t, size = { 0.1, 0.16 } })
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t + 0.05, size = 0.6,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add", grow = { 0.3, 1.0 }, alpha = 0.6 }),
		glow = 8,
	})
	F.sound("default_glass_footstep", { pos = at, gain = 0.2, pitch = 1.5 })
end

-- Cloud: pale mist sinks from above the target while frost glints rise through it from the ground.
function R.cloud(F, c)
	local at = c.centre
	local t = c.time or 3
	local r = (c.radius or 2.5) * 0.8
	F.emit({
		amount = 16, time = t,
		pos = { min = { x = at.x - r, y = at.y + 2.0, z = at.z - r }, max = { x = at.x + r, y = at.y + 2.6, z = at.z + r } },
		vel = { min = { x = -0.1, y = -0.7, z = -0.1 }, max = { x = 0.1, y = -0.5, z = 0.1 } },
		exptime = { min = 2.2, max = 2.8 }, size = { min = 0.5, max = 0.68 },
		texture = F.tex(F.tint(F.TEX.smoke, MIST), { blend = "alpha", alpha = 0.45, anim = "smoke", grow = { 0.8, 1.2 } }),
		glow = 0,
	})
	F.emit({
		amount = 8, time = t,
		pos = { min = { x = at.x - r * 0.8, y = at.y - 0.2, z = at.z - r * 0.8 },
			max = { x = at.x + r * 0.8, y = at.y + 0.4, z = at.z + r * 0.8 } },
		vel = { min = { x = -0.05, y = 0.3, z = -0.05 }, max = { x = 0.05, y = 0.6, z = 0.05 } },
		exptime = { min = 1.2, max = 1.8 }, size = { min = 0.14, max = 0.2 },
		texture = F.tex(F.tint(FROST, "#a8f0ff"), { blend = "add", fade = true }), glow = 10,
	})
end

minemon.fx.register_move("haze", R)
