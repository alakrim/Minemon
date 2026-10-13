-- Stun Spore (M2.1 T-FX2-C, status, grass, paralysis): yellow-orange grains that fizz. They are flicked from the
-- user's mouth in a quick spray, and over the cloud's life they jitter in place round the target, popping into small
-- flashes. Nothing drifts: the energy is all in the jitter, unlike the slow sinking of Sleep Powder. Budget: cast 80,
-- cloud 160.
-- luacheck: read_globals core vector minemon

local R = {}

local SPORE = "#ffd840"
local ZERO = { x = 0, y = 0, z = 0 }

-- Cast: a quick spray of grains flicked from the mouth at the target.
function R.cast(F, c)
	if not (c.user and c.user:get_pos() and c.target and c.target:get_pos()) then
		return false
	end
	local at = F.anchor(c.user, "mouth", 0.75, 0.6) or c.user:get_pos()
	local dir = vector.normalize(vector.subtract(c.target:get_pos(), at))
	local t = math.max(0.15, c.time or 0.4)
	F.emit({
		amount = 14, time = t, pos = at,
		vel = { min = vector.multiply(dir, 3), max = vector.multiply(dir, 5) },
		jitter = { min = { x = -0.5, y = -0.5, z = -0.5 }, max = { x = 0.5, y = 0.5, z = 0.5 } },
		exptime = { min = 0.2, max = 0.4 }, size = { min = 0.1, max = 0.15 },
		texture = F.tex(F.tint(F.TEX.spark, SPORE), { blend = "add", fade = true }), glow = 12,
	})
	F.flare({ pos = at, colour = SPORE, size = 0.7, life = 0.12 })
	F.sound("default_dig_snappy", { pos = at, gain = 0.3, pitch = 2.0 })
end

-- Cloud: grains fizz in a loose ball round the target: fast jitter, bright pops and a thin yellow haze.
function R.cloud(F, c)
	local at = c.centre
	local t = c.time or 3
	local r = (c.radius or 2.5) * 0.7
	local ball = { min = { x = at.x - r, y = at.y + 0.2, z = at.z - r },
		max = { x = at.x + r, y = at.y + 1.6, z = at.z + r } }
	F.emit({
		amount = 36, time = t, pos = ball, vel = ZERO,
		jitter = { min = { x = -2.0, y = -2.0, z = -2.0 }, max = { x = 2.0, y = 2.0, z = 2.0 } },
		exptime = { min = 0.25, max = 0.5 }, size = { min = 0.08, max = 0.12 },
		texture = F.tex(F.tint(F.TEX.spark, SPORE), { blend = "add", fade = true }), glow = 14,
	})
	F.emit({
		amount = 4, time = t, pos = ball, vel = ZERO,
		exptime = { min = 0.15, max = 0.25 }, size = { min = 0.3, max = 0.4 },
		texture = F.tex(F.tint(F.TEX.flare, "#fff0a0"), { blend = "add", fade = true }), glow = 14,
	})
	F.emit({
		amount = 4, time = t, pos = at, vel = { x = 0, y = 0.1, z = 0 },
		exptime = { min = 1.2, max = 1.6 }, size = { min = 0.5, max = 0.6 },
		texture = F.tex(F.tint(F.TEX.smoke, "#c8b43a"), { blend = "alpha", alpha = 0.3, anim = "smoke" }),
	})
end

minemon.fx.register_move("stun_spore", R)
