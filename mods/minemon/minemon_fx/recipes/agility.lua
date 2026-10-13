-- Agility (M2.1 T-FX2-C, aura, psychic, speed +2): the user streaks. Pink speed lines fly backwards off its body in
-- pairs at three heights, and two faint afterimages hang behind it for a moment. Lines flow away from the user, so the
-- look is direction and speed, not a flash. (Quick Attack is the white afterimage of a dash; this one is psychic pink
-- and goes backwards, not forwards.) Budget: docs/ART_GUIDE.md 4 (aura 120).
-- luacheck: read_globals core vector minemon

local R = {}

local SPEED = "minemon_fx_speedline.png"
local ZERO = { x = 0, y = 0, z = 0 }

local function facing(obj)
	local yaw = obj:get_yaw() or 0
	local fwd = { x = -math.sin(yaw), y = 0, z = math.cos(yaw) }
	return fwd, { x = -fwd.z, y = 0, z = fwd.x }
end

function R.aura(F, c)
	local user = c.user
	if not (user and user:get_pos()) then
		return
	end
	local centre = c.centre
	local fwd, side = facing(user)
	-- Five streaks, alternating sides and three heights, each one thrown backwards off the body.
	for k = 0, 4 do
		core.after(k * 0.07, function()
			local s = (k % 2 == 0) and -1 or 1
			local y = ((k % 3) - 1) * 0.3
			local p = vector.add(vector.add(centre, vector.multiply(side, 0.3 * s)), { x = 0, y = y, z = 0 })
			F.emit({
				amount = 3, time = 0.05, pos = p, vel = vector.multiply(fwd, -7),
				exptime = { min = 0.3, max = 0.45 }, size = { min = 0.6, max = 0.8 },
				texture = F.tex(F.tint(SPEED, c.palette.main), { blend = "add", fade = true }), glow = 14,
			})
		end)
	end
	-- Two afterimages of the body glow behind it and fade.
	for k = 1, 2 do
		F.emit({
			amount = 1, time = 0.02, pos = vector.add(centre, vector.multiply(fwd, -0.45 * k)), vel = ZERO,
			exptime = 0.45, size = 1.0,
			texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add", fade = true, alpha = 0.5 }), glow = 8,
		})
	end
	F.flare({ pos = centre, colour = c.palette.core, size = 0.8, life = 0.15 })
end

minemon.fx.register_move("agility", R)
