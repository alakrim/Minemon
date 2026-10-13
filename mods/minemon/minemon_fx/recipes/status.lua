-- Status looks (M2.1, polished by T-FX-c): what a creature with a primary status shows, re-sent every second by
-- init.lua as a short spawner attached to it. Each look gets (F, obj, seconds). Each stays under the budget of
-- ~30 particles per second (docs/ART_GUIDE.md 4). Every look reads from its silhouette as well as its colour: burn
-- climbs, poison rises and drips, paralysis jumps, sleep drifts up, freeze glitters and hangs.
-- luacheck: read_globals core vector minemon

local looks = {}

-- The body box of a creature relative to its position: { half width, height, bottom y }.
local function body(obj)
	local cb = obj:get_properties().collisionbox or { -0.25, 0, -0.25, 0.25, 0.5, 0.25 }
	return (cb[4] - cb[1]) / 2, cb[5] - cb[2], cb[2]
end

-- Burn (~16/s): tongues of flame lick up the body, embers flick off the tips and rise, and a thread of smoke trails.
looks.burn = function(F, obj, s)
	local hw, h, y0 = body(obj)
	F.on(obj, {
		amount = 9, time = s,
		pos = { min = { x = -hw * 0.8, y = y0 + h * 0.1, z = -hw * 0.8 },
			max = { x = hw * 0.8, y = y0 + h * 0.7, z = hw * 0.8 } },
		vel = { min = { x = 0, y = 0.5, z = 0 }, max = { x = 0, y = 1.0, z = 0 } },
		exptime = { min = 0.25, max = 0.45 }, size = { min = 0.24, max = 0.39 },
		texture = F.tex(F.TEX.flame, { blend = "add", anim = "flame" }), vertical = true, glow = 14,
	})
	F.on(obj, {
		amount = 4, time = s,
		pos = { min = { x = -hw * 0.6, y = y0 + h * 0.5, z = -hw * 0.6 },
			max = { x = hw * 0.6, y = y0 + h * 0.9, z = hw * 0.6 } },
		vel = { min = { x = -0.2, y = 0.4, z = -0.2 }, max = { x = 0.2, y = 0.9, z = 0.2 } },
		acc = { x = 0, y = 0.6, z = 0 }, exptime = { min = 0.5, max = 0.8 }, size = { min = 0.05, max = 0.09 },
		texture = F.tex(F.TEX.ember, { blend = "add", fade = { 1, 0.5 } }), glow = 14,
	})
	F.on(obj, {
		amount = 3, time = s, pos = { x = 0, y = y0 + h, z = 0 },
		vel = { min = { x = -0.1, y = 0.5, z = -0.1 }, max = { x = 0.1, y = 0.8, z = 0.1 } },
		exptime = { min = 0.8, max = 1.2 }, size = { min = 0.36, max = 0.54 },
		texture = F.tex(F.tint(F.TEX.smoke, "#3b2b25"), { blend = "alpha", alpha = 0.5, anim = "smoke" }),
	})
end

-- Poison (~12/s): sickly bubbles rise and pop, a few drops fall off the body, and a thin purple mist hangs over it.
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
	F.on(obj, {
		amount = 3, time = s, pos = { min = { x = -hw * 0.7, y = y0 + h * 0.8, z = -hw * 0.7 },
			max = { x = hw * 0.7, y = y0 + h * 0.85, z = hw * 0.7 } },
		vel = { x = 0, y = -0.2, z = 0 }, acc = { x = 0, y = -6, z = 0 }, collisiondetection = true,
		exptime = { min = 0.4, max = 0.7 }, size = { min = 0.07, max = 0.11 },
		texture = F.tex(F.tint(F.TEX.glow, "#b060e0"), { blend = "add", fade = true }), glow = 6,
	})
	F.on(obj, {
		amount = 2, time = s, pos = { x = 0, y = y0 + h * 0.5, z = 0 },
		vel = { min = { x = -0.05, y = 0, z = -0.05 }, max = { x = 0.05, y = 0.1, z = 0.05 } },
		exptime = { min = 1.0, max = 1.4 }, size = { min = 0.6, max = 0.9 },
		texture = F.tex(F.tint(F.TEX.smoke, "#5a3a6a"), { blend = "alpha", alpha = 0.3, anim = "smoke" }),
	})
end

-- Paralysis (~14/s): electric sparks crackle and jitter over the body, and thin bolts snap off it.
looks.paralysis = function(F, obj, s)
	local hw, h, y0 = body(obj)
	F.on(obj, {
		amount = 10, time = s,
		pos = { min = { x = -hw, y = y0 + h * 0.2, z = -hw }, max = { x = hw, y = y0 + h, z = hw } },
		vel = { x = 0, y = 0, z = 0 }, jitter = { min = { x = -3, y = -3, z = -3 }, max = { x = 3, y = 3, z = 3 } },
		exptime = { min = 0.08, max = 0.18 }, size = { min = 0.24, max = 0.42 },
		texture = F.tex(F.tint(F.TEX.flare, "#ffe640"), { blend = "add" }), glow = 14,
	})
	F.on(obj, {
		amount = 4, time = s,
		pos = { min = { x = -hw, y = y0 + h * 0.3, z = -hw }, max = { x = hw, y = y0 + h * 0.9, z = hw } },
		vel = { min = { x = -0.6, y = -0.3, z = -0.6 }, max = { x = 0.6, y = 0.3, z = 0.6 } },
		exptime = { min = 0.1, max = 0.2 }, size = { min = 0.2, max = 0.3 }, vertical = true,
		texture = F.tex(F.tint(F.TEX.streak, "#fff4a0"), { blend = "add" }), glow = 14,
	})
end

-- Sleep (~3/s): slow motes drift up from the head, pale and soft, and a faint blue halo rests over it.
looks.sleep = function(F, obj, s)
	local top = F.anchor(obj, "head", 1.0) or obj:get_pos()
	F.emit({
		amount = 2, time = s, pos = top,
		vel = { min = { x = 0.1, y = 0.3, z = -0.05 }, max = { x = 0.25, y = 0.5, z = 0.05 } },
		exptime = { min = 1.2, max = 1.6 }, size = { min = 0.3, max = 0.48 },
		texture = F.tex(F.tint(F.TEX.mote, "#bcd8ff"), { blend = "add", fade = { 0, 1 }, grow = { 0.5, 1.3 } }),
		glow = 10,
	})
	F.emit({
		amount = 1, time = s, pos = top,
		vel = { x = 0, y = 0, z = 0 }, exptime = s + 0.2, size = 0.7,
		texture = F.tex(F.tint(F.TEX.glow, "#8fb8ff"), { blend = "add", alpha = 0.25 }), glow = 8,
	})
end

-- Freeze (~10/s): frost glints hang round the body and fall slowly, and a cold breath of mist rises off it.
looks.freeze = function(F, obj, s)
	local hw, h, y0 = body(obj)
	F.on(obj, {
		amount = 7, time = s,
		pos = { min = { x = -hw, y = y0, z = -hw }, max = { x = hw, y = y0 + h, z = hw } },
		vel = { min = { x = -0.05, y = -0.2, z = -0.05 }, max = { x = 0.05, y = 0, z = 0.05 } },
		exptime = { min = 0.4, max = 0.8 }, size = { min = 0.15, max = 0.3 },
		texture = F.tex(F.tint(F.TEX.mote, "#a8f0ff"), { blend = "add", fade = { 0, 1 } }), glow = 12,
	})
	F.on(obj, {
		amount = 3, time = s, pos = { min = { x = -hw * 0.6, y = y0 + h * 0.7, z = -hw * 0.6 },
			max = { x = hw * 0.6, y = y0 + h, z = hw * 0.6 } },
		vel = { min = { x = -0.05, y = 0.2, z = -0.05 }, max = { x = 0.05, y = 0.5, z = 0.05 } },
		exptime = { min = 0.8, max = 1.2 }, size = { min = 0.4, max = 0.6 },
		texture = F.tex(F.tint(F.TEX.smoke, "#dff6ff"), { blend = "alpha", alpha = 0.3, anim = "smoke" }),
	})
end

for kind, look in pairs(looks) do
	minemon.fx.register_status(kind, look)
end
