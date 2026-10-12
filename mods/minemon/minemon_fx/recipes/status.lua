-- Status looks (M2.1): what a creature with a primary status shows, re-sent every second by init.lua as a short
-- spawner attached to it. Each look gets (F, obj, seconds). Keep each under ~30 particles per second (budget).
-- luacheck: read_globals core vector minemon

local looks = {}

-- The body box of a creature relative to its position: { half width, height }.
local function body(obj)
	local cb = obj:get_properties().collisionbox or { -0.25, 0, -0.25, 0.25, 0.5, 0.25 }
	return (cb[4] - cb[1]) / 2, cb[5] - cb[2], cb[2]
end

-- Burn: tongues of flame lick up the body; a thread of smoke.
looks.burn = function(F, obj, s)
	local hw, h, y0 = body(obj)
	F.on(obj, {
		amount = 8, time = s,
		pos = { min = { x = -hw * 0.8, y = y0 + h * 0.1, z = -hw * 0.8 },
			max = { x = hw * 0.8, y = y0 + h * 0.7, z = hw * 0.8 } },
		vel = { min = { x = 0, y = 0.5, z = 0 }, max = { x = 0, y = 1.0, z = 0 } },
		exptime = { min = 0.25, max = 0.45 }, size = { min = 0.24, max = 0.39 },
		texture = F.tex(F.TEX.flame, { blend = "add", anim = "flame" }), vertical = true, glow = 14,
	})
	F.on(obj, {
		amount = 3, time = s, pos = { x = 0, y = y0 + h, z = 0 },
		vel = { min = { x = -0.1, y = 0.5, z = -0.1 }, max = { x = 0.1, y = 0.8, z = 0.1 } },
		exptime = { min = 0.8, max = 1.2 }, size = { min = 0.36, max = 0.54 },
		texture = F.tex(F.tint(F.TEX.smoke, "#3b2b25"), { blend = "alpha", alpha = 0.5, anim = "smoke" }),
	})
end

-- Poison: sickly bubbles rise and pop.
looks.poison = function(F, obj, s)
	local hw, h, y0 = body(obj)
	F.on(obj, {
		amount = 7, time = s,
		pos = { min = { x = -hw, y = y0 + h * 0.3, z = -hw }, max = { x = hw, y = y0 + h * 0.9, z = hw } },
		vel = { min = { x = -0.1, y = 0.3, z = -0.1 }, max = { x = 0.1, y = 0.6, z = 0.1 } },
		exptime = { min = 0.5, max = 0.9 }, size = { min = 0.18, max = 0.33 },
		texture = F.tex(F.tint(F.TEX.ring, "#c45ae6"), { blend = "alpha", fade = { 0.9, 0 }, grow = { 0.6, 1.2 } }),
		glow = 6,
	})
end

-- Paralysis: electric sparks crackle and jitter over the body.
looks.paralysis = function(F, obj, s)
	local hw, h, y0 = body(obj)
	F.on(obj, {
		amount = 10, time = s,
		pos = { min = { x = -hw, y = y0 + h * 0.2, z = -hw }, max = { x = hw, y = y0 + h, z = hw } },
		vel = { x = 0, y = 0, z = 0 }, jitter = { min = { x = -3, y = -3, z = -3 }, max = { x = 3, y = 3, z = 3 } },
		exptime = { min = 0.08, max = 0.18 }, size = { min = 0.24, max = 0.42 },
		texture = F.tex(F.tint(F.TEX.flare, "#ffe640"), { blend = "add" }), glow = 14,
	})
end

-- Sleep: slow motes drift up from the head.
looks.sleep = function(F, obj, s)
	local top = F.anchor(obj, "head", 1.0) or obj:get_pos()
	F.emit({
		amount = 2, time = s, pos = top,
		vel = { min = { x = 0.1, y = 0.3, z = -0.05 }, max = { x = 0.25, y = 0.5, z = 0.05 } },
		exptime = { min = 1.2, max = 1.6 }, size = { min = 0.3, max = 0.48 },
		texture = F.tex(F.tint(F.TEX.mote, "#bcd8ff"), { blend = "add", fade = { 0, 1 }, grow = { 0.5, 1.3 } }),
		glow = 10,
	})
end

-- Freeze: frost glints and cold breath around the body.
looks.freeze = function(F, obj, s)
	local hw, h, y0 = body(obj)
	F.on(obj, {
		amount = 8, time = s,
		pos = { min = { x = -hw, y = y0, z = -hw }, max = { x = hw, y = y0 + h, z = hw } },
		vel = { min = { x = -0.05, y = -0.2, z = -0.05 }, max = { x = 0.05, y = 0, z = 0.05 } },
		exptime = { min = 0.4, max = 0.8 }, size = { min = 0.15, max = 0.3 },
		texture = F.tex(F.tint(F.TEX.mote, "#a8f0ff"), { blend = "add", fade = { 0, 1 } }), glow = 12,
	})
end

for kind, look in pairs(looks) do
	minemon.fx.register_status(kind, look)
end
