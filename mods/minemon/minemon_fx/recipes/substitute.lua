-- Substitute (M2.1 T-FX2-C, aura, normal, a decoy): a poof and a stand-in. A grey puff of smoke bursts round the user,
-- and a decoy, a spinning chitin-like shard, takes shape in front of it and spins in place for over a second before it
-- settles and fades. The spin is the look: the user is hidden behind a figure that turns, not a shape that stands
-- still. Budget: docs/ART_GUIDE.md 4 (aura 120).
-- luacheck: read_globals core vector minemon

local R = {}

local SPIN = "minemon_fx_shard_spin_anim.png" -- 4 frames of 16 px: a shard, spinning (tools/gen_fx_textures.py)
local ZERO = { x = 0, y = 0, z = 0 }

local function facing(obj)
	local yaw = obj:get_yaw() or 0
	return { x = -math.sin(yaw), y = 0, z = math.cos(yaw) }
end

function R.aura(F, c)
	local user = c.user
	if not (user and user:get_pos()) then
		return
	end
	local centre = c.centre
	local fwd = facing(user)
	-- The poof: a puff of smoke bursts round the user and a flash cuts through it.
	F.burst({ pos = centre, tex = F.TEX.smoke, anim = "smoke", colour = c.palette.smoke, blend = "alpha", amount = 10,
		speed = 1.0, radius = 0.3, life = { 0.6, 1.0 }, size = { 0.4, 0.6 }, glow = 0 })
	F.flare({ pos = centre, colour = c.palette.core, size = 1.2, life = 0.18 })
	-- The decoy: a spinning shard in front of the user, shown for 1.4 s, sparkling as it settles.
	core.after(0.25, function()
		local p = vector.add(centre, vector.multiply(fwd, 1.0))
		local t = F.tex(F.tint(SPIN, c.palette.core), { blend = "alpha", fade = { 1, 0.5 }, grow = { 0.5, 1.0 } })
		t.animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = -1 }
		F.emit({ amount = 1, time = 0.02, pos = p, vel = ZERO, exptime = 1.6, size = 0.8, texture = t, glow = 8 })
		F.emit({
			amount = 6, time = 0.2, pos = p, vel = { min = { x = -0.4, y = 0.2, z = -0.4 },
				max = { x = 0.4, y = 0.6, z = 0.4 } },
			exptime = { min = 0.4, max = 0.7 }, size = { min = 0.1, max = 0.14 },
			texture = F.tex(F.tint(F.TEX.spark, c.palette.core), { blend = "add", fade = true }), glow = 10,
		})
	end)
end

minemon.fx.register_move("substitute", R)
