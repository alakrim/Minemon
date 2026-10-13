-- Reflect (M2.1 T-FX2-C, aura, psychic, defence +2 against physical moves): a mirror arc. Seven glints sit on an arc
-- in front of the user, one after another from left to right, and stay there as a curved wall that shines and fades.
-- The arc is the look: a wall you can see the curve of, not a dome round the body (that is Protect) and not a screen
-- of bars (that is Light Screen). Budget: docs/ART_GUIDE.md 4 (aura 120).
-- luacheck: read_globals core vector minemon

local R = {}

local GLINT = "minemon_fx_flare.png"
local ZERO = { x = 0, y = 0, z = 0 }
local GLINTS = 7
local ARC = 1.0 -- radians either side of the facing

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
	for k = 0, GLINTS - 1 do
		core.after(k * 0.05, function()
			local a = -ARC + k * (2 * ARC / (GLINTS - 1))
			local p = vector.add(centre, vector.add(vector.multiply(fwd, math.cos(a) * 0.95),
				vector.multiply(side, math.sin(a) * 0.95)))
			F.emit({
				amount = 1, time = 0.02, pos = p, vel = ZERO, exptime = 1.1, size = 0.5,
				texture = F.tex(F.tint(GLINT, c.palette.core), { blend = "add", fade = { 1, 0.3 }, grow = { 1, 0.7 } }),
				glow = 14,
			})
		end)
	end
	F.flare({ pos = centre, colour = c.palette.core, size = 0.9, life = 0.18 })
end

minemon.fx.register_move("reflect", R)
