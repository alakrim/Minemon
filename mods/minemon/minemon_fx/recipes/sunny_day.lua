-- Sunny Day (M2.1 T-FX2-C, weather, fire, status cloud): a sun over the field. The user raises its head and a little
-- heat shimmers off it; then a sun glow with a starburst hangs high over the target, three bursts of rays flick out of
-- it, and heat motes rise off the ground under it for the whole cloud. The sun is high and far: nothing comes near the
-- camera. Budget: docs/ART_GUIDE.md 4 (cast 80, cloud 160).
-- luacheck: read_globals core vector minemon

local R = {}

local SUN = "#fff6c8"
local HEAT = "#ffd080"
local ZERO = { x = 0, y = 0, z = 0 }

-- Cast: heat shimmers off the user's head.
function R.cast(F, c)
	local head = F.anchor(c.user, "head", 1.0)
	if not head then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.emit({
		amount = 1, time = 0.02, pos = head, vel = ZERO, exptime = t + 0.05, size = 0.8,
		texture = F.tex(F.tint(F.TEX.glow, SUN), { blend = "add", grow = { 0.3, 1.0 }, alpha = 0.6 }), glow = 12,
	})
	F.emit({
		amount = 8, time = t, pos = head, vel = { min = { x = -0.1, y = 0.5, z = -0.1 },
			max = { x = 0.1, y = 0.9, z = 0.1 } },
		exptime = { min = 0.5, max = 0.7 }, size = { min = 0.1, max = 0.14 },
		texture = F.tex(F.tint(F.TEX.mote, HEAT), { blend = "add", fade = true }), glow = 10,
	})
	F.sound("fire_fire", { pos = head, gain = 0.2, pitch = 1.8 })
end

-- Cloud: the sun hangs high over the target; its rays flick out in three bursts and heat rises off the ground below.
function R.cloud(F, c)
	local at = c.centre
	local t = c.time or 3
	local sun = vector.add(at, { x = 0, y = 2.8, z = 0 })
	F.emit({
		amount = 1, time = 0.02, pos = sun, vel = ZERO, exptime = t, size = 2.4,
		texture = F.tex(F.tint(F.TEX.glow, SUN), { blend = "add", grow = { 0.7, 1.1 }, alpha = 0.55 }), glow = 14,
	})
	F.emit({
		amount = 1, time = 0.02, pos = sun, vel = ZERO, exptime = t, size = 2.6,
		texture = F.tex(F.tint(F.TEX.flare, SUN), { blend = "add", fade = { 0.8, 0.4 }, grow = { 0.9, 1.1 } }), glow = 14,
	})
	for k = 0, 2 do
		core.after(k * 0.9, function()
			F.burst({ pos = sun, colour = c.palette.core, amount = 14, speed = 1.3, radius = 0.4, life = { 1.0, 1.6 },
				size = { 0.1, 0.16 }, glow = 14 })
		end)
	end
	F.emit({
		amount = 18, time = t,
		pos = { min = { x = at.x - 1.6, y = at.y - 0.1, z = at.z - 1.6 },
			max = { x = at.x + 1.6, y = at.y + 0.4, z = at.z + 1.6 } },
		vel = { min = { x = -0.1, y = 0.8, z = -0.1 }, max = { x = 0.1, y = 1.3, z = 0.1 } },
		exptime = { min = 1.0, max = 1.4 }, size = { min = 0.12, max = 0.18 },
		texture = F.tex(F.tint(F.TEX.mote, HEAT), { blend = "add", fade = true }), glow = 10,
	})
end

minemon.fx.register_move("sunny_day", R)
