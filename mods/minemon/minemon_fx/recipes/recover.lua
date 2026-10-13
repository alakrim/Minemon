-- Recover (M2.1 T-FX2-C, aura, normal, heal): green-white motes rise from the feet up through the body with a soft
-- glow round it, and a ring of light spreads out from the feet when the body is mended. The motes rise, never fall.
-- Budget: docs/ART_GUIDE.md 4 (aura 120).
-- luacheck: read_globals core vector minemon

local R = {}

local MOTE = "minemon_fx_mote.png"
local GREEN_WHITE = "#d8ffd0"
local ZERO = { x = 0, y = 0, z = 0 }

function R.aura(F, c)
	local user = c.user
	if not (user and user:get_pos()) then
		return
	end
	local feet = user:get_pos()
	local centre = c.centre
	-- The motes rise from a column round the feet, up past the head.
	F.emit({
		amount = 24, time = 1.0,
		pos = { min = { x = feet.x - 0.35, y = feet.y + 0.05, z = feet.z - 0.35 },
			max = { x = feet.x + 0.35, y = feet.y + 0.5, z = feet.z + 0.35 } },
		vel = { min = { x = -0.05, y = 0.8, z = -0.05 }, max = { x = 0.05, y = 1.4, z = 0.05 } },
		exptime = { min = 1.0, max = 1.3 }, size = { min = 0.14, max = 0.2 },
		texture = F.tex(F.tint(MOTE, GREEN_WHITE), { blend = "add", fade = true }), glow = 14,
	})
	-- A soft glow in the body that swells, and a ring at the feet a moment later.
	F.emit({
		amount = 1, time = 1.0, pos = centre, vel = ZERO, exptime = 1.1, size = 1.8,
		texture = F.tex(F.tint(F.TEX.glow, "#c8ffc0"), { blend = "add", grow = { 0.7, 1.2 }, alpha = 0.3 }), glow = 10,
	})
	core.after(0.3, function()
		F.ring({ pos = vector.add(feet, { x = 0, y = 0.05, z = 0 }), colour = "#c8ffc0", size = 0.4, grow = 2.0,
			life = 0.5 })
	end)
	F.sound("default_dig_snappy", { pos = feet, gain = 0.2, pitch = 2.0 })
end

minemon.fx.register_move("recover", R)
