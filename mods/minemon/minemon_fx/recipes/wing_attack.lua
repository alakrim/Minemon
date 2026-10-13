-- Wing Attack (M2.1, T-FX2-a): a sweep of feathers. The wind-up draws feathers in to the shoulders. In the blow, a
-- fan of feathers travels across the front of the user on an arc, from one wing to the other, and on the victim the
-- same fan is thrown outward, with two wide bars of pale blue wind crossing the chest. Shape: an arc of feathers,
-- not a crescent of light (Slash is that). Strong-ish (power 60). Budget: cast 12, melee 10, impact 28 particles.
-- luacheck: read_globals core vector minemon

local R = {}

local FEATHER = "minemon_fx_feather.png"
local SPEED = "minemon_fx_speedline.png"
local FEATHERS = 8
local ARC_R = 0.9
local SWEEP = math.rad(70)

-- Wind-up: feathers are drawn in to the shoulders from the air round the user.
function R.cast(F, c)
	local at = F.anchor(c.user, "middle", 0.7, 0.0)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.3)
	F.inhale({ pos = at, tex = FEATHER, colour = c.palette.core, radius = 1.1, amount = 14, time = t,
		size = { 0.14, 0.2 } })
end

-- The sweep: eight feathers on an arc in front of the user, each moving across it, from the one side to the other.
function R.melee(F, c)
	local centre = c.centre
	for i = 0, FEATHERS - 1 do
		local f = i / (FEATHERS - 1)
		local a = -SWEEP + 2 * SWEEP * f
		local dir = { x = c.fwd.x * math.cos(a) - c.fwd.z * math.sin(a), y = 0,
			z = c.fwd.z * math.cos(a) + c.fwd.x * math.sin(a) }
		local p = vector.add(centre, vector.multiply(dir, ARC_R * 0.6))
		local side = (f < 0.5) and 1 or -1
		F.emit({
			amount = 1, time = 0.02, pos = p,
			vel = vector.add(vector.multiply(c.fwd, 3.5), vector.multiply({ x = -c.fwd.z, y = 0, z = c.fwd.x }, side * 2)),
			drag = { x = 0.4, y = 0.4, z = 0.4 }, exptime = { min = 0.2, max = 0.3 }, size = 0.2,
			texture = F.tex(F.tint(FEATHER, c.palette.core), { blend = "alpha", fade = true }), glow = 0,
		})
	end
end

-- The hit: two wide bars of wind across the chest, and the feather fan thrown outward from it.
function R.impact(F, c)
	local at = c.pos
	for _, dy in ipairs({ 0.12, -0.14 }) do
		F.emit({
			amount = 1, time = 0.02, pos = vector.add(at, { x = 0, y = dy, z = 0 }), vel = { x = 0, y = 0, z = 0 },
			exptime = 0.26, size = 1.3,
			texture = F.tex(F.tint(SPEED, c.palette.main), { blend = "add", fade = true, grow = { 0.7, 1.2 } }),
			glow = 10,
		})
	end
	local across = { x = -c.fwd.z, y = 0, z = c.fwd.x }
	for i = 0, FEATHERS - 1 do
		local f = i / (FEATHERS - 1)
		local a = -SWEEP + 2 * SWEEP * f
		local out = { x = math.cos(a) * c.fwd.x + math.sin(a) * across.x, y = 0.3 + 0.4 * math.sin(a),
			z = math.cos(a) * c.fwd.z + math.sin(a) * across.z }
		F.emit({
			amount = 1, time = 0.02, pos = at,
			vel = vector.multiply(out, 2.6), drag = { x = 0.8, y = 0.8, z = 0.8 },
			acc = { x = 0, y = -1.5, z = 0 }, exptime = { min = 0.45, max = 0.7 }, size = 0.2,
			texture = F.tex(F.tint(FEATHER, c.palette.core), { blend = "alpha", fade = true }), glow = 0,
		})
	end
	F.flare({ pos = at, colour = c.palette.core, size = 0.9, life = 0.1 })
	F.sound("default_dig_oddly_breakable_by_hand", { pos = at, gain = 0.5, pitch = 0.9 })
end

minemon.fx.register_move("wing_attack", R)
