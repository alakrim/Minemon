-- Moonlight (M2.1 T-FX2-C, aura, normal, heal): a crescent moon. A pale silver crescent hangs over the user's head
-- with a soft halo, and silver dust sifts slowly down onto the body from it for a second. The crescent is the shape
-- nothing else in the set uses; the dust falls slowly and is small. Budget: docs/ART_GUIDE.md 4 (aura 120).
-- luacheck: read_globals core vector minemon

local R = {}

local CRESCENT = "minemon_fx_slash.png" -- a curved blade, read here as the moon's crescent
local SILVER = "#e8f0ff"
local ZERO = { x = 0, y = 0, z = 0 }

function R.aura(F, c)
	local user = c.user
	if not (user and user:get_pos()) then
		return
	end
	local top = F.anchor(user, "head", 1.0) or c.centre
	local moon = vector.add(top, { x = 0, y = 0.7, z = 0 })
	F.emit({
		amount = 1, time = 0.02, pos = moon, vel = ZERO, exptime = 1.6, size = 2.0,
		texture = F.tex(F.tint(F.TEX.glow, "#dfe8ff"), { blend = "add", grow = { 0.6, 1.0 }, alpha = 0.3 }), glow = 10,
	})
	F.emit({
		amount = 1, time = 0.02, pos = moon, vel = ZERO, exptime = 1.6, size = 1.1,
		texture = F.tex(F.tint(CRESCENT, SILVER), { blend = "add", fade = { 0.2, 1 }, grow = { 0.8, 1.0 } }), glow = 12,
	})
	F.emit({
		amount = 14, time = 1.2,
		pos = { min = { x = moon.x - 0.8, y = moon.y - 0.6, z = moon.z - 0.8 },
			max = { x = moon.x + 0.8, y = moon.y + 0.1, z = moon.z + 0.8 } },
		vel = { min = { x = -0.05, y = -0.5, z = -0.05 }, max = { x = 0.05, y = -0.3, z = 0.05 } },
		exptime = { min = 1.2, max = 1.6 }, size = { min = 0.1, max = 0.14 },
		texture = F.tex(F.tint(F.TEX.mote, SILVER), { blend = "add", fade = true }), glow = 10,
	})
	F.sound("mobs_mc_vex_hurt", { pos = moon, gain = 0.15, pitch = 2.4 })
end

minemon.fx.register_move("moonlight", R)
