-- Sweet Scent (M2.1 T-FX2-C, status, normal, evasion -2): a sweet wind. Pink petals lift off the user's head and drift
-- across to the target on a gentle breeze, a soft pink glow hangs round the target, and the petals drift past it
-- sideways, turning and fading. Petals move with the wind, not against gravity: the only move with a sideways drift.
-- Budget: leaves and petals at most 0.2 (docs/ART_GUIDE.md and the M2.1 review); cloud 160.
-- luacheck: read_globals core vector minemon

local R = {}

local PETAL = "minemon_fx_blossom.png" -- a pointed petal with a centre vein (tools/gen_fx_textures_c2.py)
local PINK = "#ffc8e0"
local ZERO = { x = 0, y = 0, z = 0 }

-- Cast: a puff of petals breathes out of the head.
function R.cast(F, c)
	if not (c.user and c.user:get_pos() and c.target and c.target:get_pos()) then
		return false
	end
	local head = F.anchor(c.user, "head", 1.0) or c.user:get_pos()
	local dir = vector.normalize(vector.subtract(c.target:get_pos(), head))
	local t = math.max(0.2, c.time or 0.4)
	F.emit({
		amount = 8, time = t, pos = head,
		vel = { min = vector.add(vector.multiply(dir, 0.8), { x = -0.3, y = 0.2, z = -0.3 }),
			max = vector.add(vector.multiply(dir, 1.4), { x = 0.3, y = 0.6, z = 0.3 }) },
		drag = { x = 0.8, y = 0.8, z = 0.8 }, exptime = { min = 1.0, max = 1.4 }, size = { min = 0.14, max = 0.19 },
		texture = F.tex(F.tint(PETAL, PINK), { blend = "alpha", fade = true }),
	})
	F.flare({ pos = head, colour = PINK, size = 0.6, life = 0.14 })
	F.sound("default_grass_footstep", { pos = head, gain = 0.2, pitch = 1.8 })
end

-- Cloud: petals drift across the target on a sideways breeze; a soft pink glow hangs over its head.
function R.cloud(F, c)
	local at = c.centre
	local t = c.time or 3
	local r = (c.radius or 2.5) * 0.7
	local box = { min = { x = at.x - r, y = at.y + 0.6, z = at.z - r },
		max = { x = at.x + r, y = at.y + 2.2, z = at.z + r } }
	F.emit({
		amount = 22, time = t, pos = box,
		vel = { min = { x = 0.2, y = -0.05, z = -0.1 }, max = { x = 0.6, y = 0.15, z = 0.1 } },
		exptime = { min = 2.2, max = 2.8 }, size = { min = 0.14, max = 0.2 },
		texture = F.tex(F.tint(PETAL, PINK), { blend = "alpha", fade = { 1, 0.3 }, grow = { 1, 0.9 } }), glow = 0,
	})
	F.emit({
		amount = 1, time = 0.02, pos = vector.add(at, { x = 0, y = 0.9, z = 0 }), vel = ZERO, exptime = t, size = 1.5,
		texture = F.tex(F.tint(F.TEX.glow, PINK), { blend = "add", grow = { 0.6, 1.0 }, alpha = 0.2 }), glow = 6,
	})
end

minemon.fx.register_move("sweet_scent", R)
