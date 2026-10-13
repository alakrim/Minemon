-- Hypnosis (signature, M2.1 T-FX-c): a hypnotic cloud. Six pink rings pulse out of the target over its life, and runes
-- hang in the air around it and fade. Silhouette: a swaying pulse, not a puff. Budget: docs/ART_GUIDE.md 4 (cloud 160).
-- Totals at "high": cloud ~120 over 3 s, plus six rings.
-- luacheck: read_globals core vector minemon

local R = {}

local ZERO_VEC = { x = 0, y = 0, z = 0 }
local RUNE = "minemon_fx_rune.png"
local PULSES = 6

function R.cloud(F, c)
	local at = c.centre
	local t = c.time or 3
	local radius = c.radius or 2.5
	for i = 0, PULSES - 1 do
		core.after(i * t / PULSES, function()
			F.ring({ pos = at, colour = c.palette.main, size = 0.4, grow = radius * 2 / 0.4, life = 0.6 })
		end)
	end
	F.emit({
		amount = 20, time = t, pos = { min = vector.subtract(at, { x = radius * 0.7, y = 0, z = radius * 0.7 }),
			max = vector.add(at, { x = radius * 0.7, y = 1.2, z = radius * 0.7 }) },
		vel = { min = { x = -0.2, y = 0, z = -0.2 }, max = { x = 0.2, y = 0.4, z = 0.2 } },
		exptime = { min = 0.8, max = 1.4 }, size = { min = 0.14, max = 0.22 },
		texture = F.tex(F.tint(RUNE, c.palette.main), { blend = "add", fade = { 0, 1 } }), glow = 10,
	})
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO_VEC, exptime = t, size = 1.0,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add", grow = { 0.5, 1.2 }, alpha = 0.5 }),
		glow = 14,
	})
	F.sound("mesecons_noteblock_chime", { pos = at, gain = 0.4, pitch = 0.6 })
end

minemon.fx.register_move("hypnosis", R)
