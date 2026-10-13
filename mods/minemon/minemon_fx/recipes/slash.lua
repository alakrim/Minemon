-- Slash (M2.1, T-FX2-a): three thin crescents in a fan. Three blades of light leave the chest, one tilted left, one
-- upright, one tilted right, stacked from top left to bottom right (the fan), and they meet the victim together.
-- The fan is the idea: nothing else in the move is curved. Strong (power 70): big, with a longer hold. Budget: cast
-- 16, melee 24, impact 40 particles.
-- luacheck: read_globals core vector minemon

local R = {}

-- The cast, melee and impact contexts differ: the cast and impact have no facing. The direction is the horizontal line
-- from the user to its target (cast) or victim (impact).
local function with_fwd(c)
	if c.fwd then
		return c
	end
	local other = c.victim or c.target
	local u, v = c.user:get_pos(), other and other:get_pos()
	local dx, dz = v and (v.x - u.x) or 1, v and (v.z - u.z) or 0
	local len = math.sqrt(dx * dx + dz * dz)
	local t = {}
	for k, val in pairs(c) do
		t[k] = val
	end
	t.fwd = len > 0.01 and { x = dx / len, y = 0, z = dz / len } or { x = 1, y = 0, z = 0 }
	return t
end


local BLADE = { "minemon_fx_slash_l.png", "minemon_fx_slash.png", "minemon_fx_slash_r.png" }
local SPARK = "minemon_fx_spark.png"

-- The blades' positions: a fan across the body (right-hand offset) and up it (height offset), in nodes.
local FAN = { { k = -1, h = 0.22 }, { k = 0, h = 0 }, { k = 1, h = -0.22 } }

local function fan_point(base, fwd, f, scale)
	return vector.add(base, { x = -fwd.z * f.k * 0.3 * scale, y = f.h * scale, z = fwd.x * f.k * 0.3 * scale })
end

-- Wind-up: a glint of light is drawn into the chest, and the sparks that will be the blades gather there.
function R.cast(F, c)
	c = with_fwd(c)
	local at = F.anchor(c.user, "middle", 0.6, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.inhale({ pos = at, tex = SPARK, colour = c.palette.core, radius = 0.8, amount = 16, time = t,
		size = { 0.06, 0.1 } })
	F.emit({
		amount = 1, time = t, pos = at, vel = { x = 0, y = 0, z = 0 }, exptime = 0.2, size = 0.8,
		texture = F.tex(F.tint(BLADE[2], c.palette.core), { blend = "add", fade = true, grow = { 0.6, 1.0 } }),
		glow = 10,
	})
end

-- Three blades leave the chest together, travelling at the victim.
function R.melee(F, c)
	for i, f in ipairs(FAN) do
		F.emit({
			amount = 1, time = 0.02, pos = fan_point(c.centre, c.fwd, f, 1), vel = vector.multiply(c.fwd, 5),
			exptime = 0.22, size = 1.3,
			texture = F.tex(F.tint(BLADE[i], c.palette.core), { blend = "add", fade = true, grow = { 0.9, 1.1 } }),
			glow = 10,
		})
	end
end

-- The fan lands on the victim: three bright blades, a white catch light, and sparks thrown off the cut edges.
function R.impact(F, c)
	c = with_fwd(c)
	local at = c.pos
	for i, f in ipairs(FAN) do
		local p = fan_point(at, c.fwd, f, 1.2)
		F.emit({
			amount = 1, time = 0.02, pos = p, vel = { x = 0, y = 0, z = 0 }, exptime = 0.34, size = 2.0,
			texture = F.tex(F.tint(BLADE[i], "#ffffff"), { blend = "add", fade = true, grow = { 0.85, 1.15 } }),
			glow = 10,
		})
		F.emit({
			amount = 5, time = 0.05, pos = p,
			vel = { min = vector.multiply(c.fwd, 1.5), max = vector.multiply(c.fwd, 3.5) },
			acc = { x = 0, y = -4, z = 0 }, exptime = { min = 0.2, max = 0.4 }, size = { min = 0.08, max = 0.13 },
			texture = F.tex(F.tint(SPARK, c.palette.core), { blend = "add", fade = true }), glow = 10,
		})
	end
	F.flare({ pos = at, colour = c.palette.core, size = 1.0, life = 0.12 })
	F.sound("default_dig_choppy", { pos = at, gain = 0.7, pitch = 1.1 })
end

minemon.fx.register_move("slash", R)
