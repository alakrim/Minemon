-- Harden (M2.1 T-FX2-C, aura, normal, defence +1): the skin turns to stone. Grey chips of rock appear all over the
-- body, cling for a second, and fade; a steel flash rings out as they lock on. The chips are the look: they sit on the
-- body and do not move, so the move reads as armour, not a blast. Budget: docs/ART_GUIDE.md 4 (aura 120).
-- luacheck: read_globals core vector minemon

local R = {}

local CHIP = "minemon_fx_chip.png" -- a grey rock chip (tools/gen_fx_textures.py)
local ZERO = { x = 0, y = 0, z = 0 }

function R.aura(F, c)
	local user = c.user
	if not (user and user:get_pos()) then
		return
	end
	local centre = c.centre
	-- The flash of the change, then the plates.
	F.flare({ pos = centre, colour = "#e8f0f8", size = 1.2, life = 0.2 })
	F.on(user, {
		amount = 12, time = 1.0,
		pos = { min = { x = -0.38, y = 0.25, z = -0.38 }, max = { x = 0.38, y = 1.15, z = 0.38 } },
		vel = ZERO,
		exptime = { min = 0.9, max = 1.2 }, size = { min = 0.3, max = 0.44 },
		texture = F.tex(F.tint(CHIP, "#6f7880"), { blend = "alpha", fade = { 1, 0.6 } }), glow = 0,
	})
	core.after(0.35, function()
		F.ring({ pos = centre, colour = "#d8e4f4", size = 0.3, grow = 2.0, life = 0.35 })
	end)
	F.sound("default_dig_cracky", { pos = centre, gain = 0.3, pitch = 1.3 })
end

minemon.fx.register_move("harden", R)
