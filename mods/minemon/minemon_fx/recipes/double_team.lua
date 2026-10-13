-- Double Team (M2.1 T-FX2-C, aura, normal, evasion +1): copies of the user. Two faint white afterimages step out to
-- either side of it and flicker, one pair after another, each leaving a few glints behind as it fades: the image of
-- the user seen twice. The copies sit beside the user, not on top of it, so the body stays readable. Budget: aura 120.
-- luacheck: read_globals core vector minemon

local R = {}

local SPARK = "minemon_fx_spark.png"
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
	local _, side = facing(user)
	for k = 0, 2 do
		F.after(k * 0.3, function()
			for _, s in ipairs({ -1, 1 }) do
				local p = vector.add(centre, vector.multiply(side, 0.9 * s))
				F.emit({
					amount = 1, time = 0.02, pos = p, vel = ZERO, exptime = 0.55, size = 1.3,
					texture = F.tex(F.tint(F.TEX.glow, "#fff8f0"), { blend = "alpha", fade = { 0.6, 0 }, alpha = 0.45,
						grow = { 1.0, 1.1 } }),
					glow = 4,
				})
				F.emit({
					amount = 4, time = 0.1,
					pos = { min = vector.add(p, { x = -0.4, y = -0.5, z = -0.4 }),
						max = vector.add(p, { x = 0.4, y = 0.6, z = 0.4 }) },
					vel = ZERO, exptime = { min = 0.3, max = 0.5 }, size = { min = 0.08, max = 0.12 },
					texture = F.tex(F.tint(SPARK, c.palette.core), { blend = "add", fade = true }), glow = 10,
				})
			end
		end)
	end
	F.flare({ pos = centre, colour = c.palette.core, size = 0.7, life = 0.14 })
end

minemon.fx.register_move("double_team", R)
