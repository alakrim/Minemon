-- Leech Seed (M2.1 T-FX2-C, status, grass, a volatile status): a green seed flies from the user to the target and is
-- planted there. Green vines then coil up round the target's body for the cloud's life, and a green root ring sits
-- under its feet. The look is a parasite that grows on the victim. Budget: cast 80, cloud 160, decal 1.
-- luacheck: read_globals core vector minemon

local R = {}

local SEED = "minemon_fx_seed.png" -- an oval seed with a stripe (tools/gen_fx_textures_c2.py)
local VINE = "minemon_fx_tendril.png"
local ZERO = { x = 0, y = 0, z = 0 }

-- Cast: a seed flies from the mouth to the target, spinning.
function R.cast(F, c)
	if not (c.user and c.user:get_pos() and c.target and c.target:get_pos()) then
		return false
	end
	local at = F.anchor(c.user, "mouth", 0.75, 0.6) or c.user:get_pos()
	local to = F.anchor(c.target, "middle", 0.6) or c.target:get_pos()
	local t = math.max(0.15, c.time or 0.4)
	F.emit({
		amount = 3, time = 0.1, pos = at, vel = vector.multiply(vector.subtract(to, at), 1 / math.max(0.2, t)),
		exptime = { min = t * 0.9, max = t }, size = { min = 0.22, max = 0.28 },
		texture = F.tex(F.tint(SEED, c.palette.main), { blend = "alpha" }), glow = 0,
	})
	F.flare({ pos = at, colour = c.palette.core, size = 0.7, life = 0.12 })
	F.sound("default_grass_footstep", { pos = at, gain = 0.3, pitch = 1.4 })
end

-- Cloud: the seed lands with a small green flash, a root ring spreads under the target and vines coil up its body.
function R.cloud(F, c)
	local t = c.time or 3
	local target = c.target
	if not (target and target:get_pos()) then
		return
	end
	local mid = F.anchor(target, "middle", 0.55) or c.centre
	F.flare({ pos = mid, colour = c.palette.core, size = 1.0, life = 0.2 })
	F.ring({ pos = vector.add(c.centre, { x = 0, y = -0.1, z = 0 }), colour = c.palette.main, size = 0.5, grow = 3.0,
		life = 0.5 })
	F.decal({ pos = c.centre, tex = F.tint(F.TEX.ring, c.palette.edge), size = 1.8, life = t, glow = 0 })
	F.on(target, {
		amount = 14, time = t,
		pos = { min = { x = -0.3, y = 0.1, z = -0.3 }, max = { x = 0.3, y = 1.0, z = 0.3 } },
		vel = { min = { x = -0.05, y = 0.3, z = -0.05 }, max = { x = 0.05, y = 0.7, z = 0.05 } },
		exptime = { min = 0.7, max = 1.0 }, size = { min = 0.2, max = 0.3 }, vertical = true,
		texture = F.tex(F.tint(VINE, c.palette.main), { blend = "alpha", fade = { 1, 0.6 } }), glow = 0,
	})
	F.on(target, {
		amount = 6, time = t,
		pos = { min = { x = -0.25, y = 0.0, z = -0.25 }, max = { x = 0.25, y = 0.6, z = 0.25 } },
		vel = ZERO, exptime = { min = 0.4, max = 0.7 }, size = { min = 0.1, max = 0.16 },
		texture = F.tex(F.tint(F.TEX.spark, c.palette.core), { blend = "add", fade = true }), glow = 10,
	})
end

minemon.fx.register_move("leech_seed", R)
