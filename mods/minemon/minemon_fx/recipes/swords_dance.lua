-- Swords Dance (M2.1 T-FX2-C, aura, normal, attack +2): blades of light orbit the user, two at a time on opposite
-- sides, and then two of them come in from either side of the user, cross in front of it, and flash. The orbit is the
-- look: a ring of cut-light blades turning round the body, not a column. Budget: docs/ART_GUIDE.md 4 (aura 120).
-- luacheck: read_globals core vector minemon

local R = {}

local SLASH = "minemon_fx_slash.png" -- a crescent blade (tools/gen_fx_textures.py)
local SHARD = "minemon_fx_shard.png"

-- The user's forward and side vectors from its yaw (yaw 0 faces +z, as minemon_combat's forward).
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
	-- Orbit: eight steps round the body, each step two blades placed on opposite sides and moving on tangentially.
	for i = 0, 7 do
		core.after(i * 0.06, function()
			local a = i * 0.55
			for j = 0, 1 do
				local b = a + j * math.pi
				local p = { x = centre.x + math.cos(b) * 0.95, y = centre.y, z = centre.z + math.sin(b) * 0.95 }
				F.emit({
					amount = 1, time = 0.02, pos = p, vel = { x = -math.sin(b) * 1.2, y = 0, z = math.cos(b) * 1.2 },
					exptime = 0.45, size = 1.3,
					texture = F.tex(F.tint(SLASH, c.palette.core), { blend = "add", fade = true, grow = { 0.8, 1.0 } }),
					glow = 14,
				})
			end
		end)
	end
	-- Cross: two blades come in from either side of the user and pass through each other in front of it.
	core.after(0.55, function()
		local front = vector.add(centre, vector.multiply(fwd, 0.7))
		for _, s in ipairs({ -1, 1 }) do
			local from = vector.add(front, vector.multiply(side, 0.9 * s))
			F.emit({
				amount = 1, time = 0.02, pos = from, vel = vector.multiply(side, -2.4 * s), exptime = 0.42, size = 1.2,
				texture = F.tex(F.tint(SHARD, c.palette.main), { blend = "add", fade = { 1, 0.4 } }), glow = 14,
			})
		end
		F.flare({ pos = front, colour = c.palette.core, size = 1.4, life = 0.2 })
		F.ring({ pos = front, colour = c.palette.main, size = 0.3, grow = 2.2, life = 0.3 })
	end)
	F.sound("mcl_criticals_hit.0", { pos = centre, gain = 0.25, pitch = 1.7 })
end

minemon.fx.register_move("swords_dance", R)
