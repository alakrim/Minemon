-- Scratch (M2.1, T-FX2-a): three parallel claw cuts, drawn the same way across the victim. Three thin diagonal
-- streaks fly out of the chest (melee), and at the victim they stay for a moment as three cuts with sparks falling
-- off them. Shape only: no fan, no crescent (Slash is the fan). Budget: cast 9, melee 15, impact 30 particles.
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


local CLAW = "minemon_fx_claw.png"
local SPARK = "minemon_fx_spark.png"
local SPACING = 0.22

-- The three claws sit side by side across the body: offset k along the right-hand vector of the facing.
local function across(fwd, k)
	return { x = -fwd.z * k * SPACING, y = 0, z = fwd.x * k * SPACING }
end

-- Wind-up: three glints appear in front of the chest, one per claw.
function R.cast(F, c)
	c = with_fwd(c)
	local at = F.anchor(c.user, "middle", 0.6, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.3)
	for k = -1, 1 do
		F.emit({
			amount = 1, time = t, pos = vector.add(at, across(c.fwd, k)), vel = { x = 0, y = 0, z = 0 },
			exptime = 0.2, size = 0.45,
			texture = F.tex(F.tint(F.TEX.flare, c.palette.core), { blend = "add", fade = true,
				grow = { 0.5, 1.0 } }),
			glow = 10,
		})
	end
end

-- Three thin claws fly out of the chest, straight at the victim.
function R.melee(F, c)
	for k = -1, 1 do
		F.emit({
			amount = 1, time = 0.02, pos = vector.add(c.centre, across(c.fwd, k)),
			vel = vector.multiply(c.fwd, 7), exptime = 0.2, size = 0.95,
			texture = F.tex(F.tint(CLAW, c.palette.core), { blend = "add", fade = true }), glow = 10,
		})
	end
end

-- Three cuts stay on the victim for a moment; sparks drop off each cut as it lands.
function R.impact(F, c)
	c = with_fwd(c)
	local at = c.pos
	for k = -1, 1 do
		local p = vector.add(at, across(c.fwd, k))
		F.emit({
			amount = 1, time = 0.02, pos = p, vel = { x = 0, y = 0, z = 0 }, exptime = 0.3, size = 1.1,
			texture = F.tex(F.tint(CLAW, c.palette.core), { blend = "add", fade = true, grow = { 0.85, 1.1 } }),
			glow = 10,
		})
		F.emit({
			amount = 3, time = 0.05, pos = p,
			vel = { min = { x = -0.6, y = -1.2, z = -0.2 }, max = { x = 0.6, y = -0.2, z = 0.2 } },
			acc = { x = 0, y = -8, z = 0 }, exptime = { min = 0.2, max = 0.35 }, size = { min = 0.07, max = 0.11 },
			texture = F.tex(F.tint(SPARK, c.palette.core), { blend = "add", fade = true }), glow = 10,
		})
	end
	F.flare({ pos = at, colour = c.palette.core, size = 0.9, life = 0.1 })
	F.sound("default_dig_choppy", { pos = at, gain = 0.6, pitch = 1.5 })
end

minemon.fx.register_move("scratch", R)
