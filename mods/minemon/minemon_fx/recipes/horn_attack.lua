-- Horn Attack (M2.1, T-FX2-a): one spike. The head lowers in the wind-up and a pale spike of light grows from the
-- brow (the horn); in the blow it is a single straight jab from the head to the victim, a point of light where it
-- lands, and three shards left in the air where the tip went in. One spike, one point: nothing spreads. Budget:
-- cast 9, melee 8, impact 22 particles.
-- luacheck: read_globals core vector minemon

local R = {}

local SPIKE = "minemon_fx_shard.png^[transformR90" -- turned: a horizontal, pointed spike
local SHARD = "minemon_fx_shard.png"

local function brow(F, c)
	return F.anchor(c.user, "head", 1.0, 0.6)
end

-- Wind-up: the horn is drawn up at the brow: a spike grows out of the head, and motes gather at its tip.
function R.cast(F, c)
	local at = brow(F, c)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.3)
	F.emit({
		amount = 1, time = t, pos = at, vel = { x = 0, y = 0, z = 0 }, exptime = t + 0.05, size = 0.9,
		texture = F.tex(F.tint(SPIKE, c.palette.core), { blend = "add", fade = true, grow = { 0.3, 1.0 } }), glow = 10,
	})
	F.inhale({ pos = at, tex = F.TEX.mote, colour = c.palette.core, radius = 0.6, amount = 6, time = t,
		size = { 0.07, 0.1 } })
end

-- The jab: the spike goes out from the brow, straight at the victim.
function R.melee(F, c)
	local at = brow(F, c) or c.centre
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = vector.multiply(c.fwd, 12), exptime = 0.14, size = 1.1,
		texture = F.tex(F.tint(SPIKE, c.palette.core), { blend = "add", fade = true }), glow = 10,
	})
end

-- The stab: a point of light where the tip lands, and three shards left hanging in the air at the wound.
function R.impact(F, c)
	local at = c.pos
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = { x = 0, y = 0, z = 0 }, exptime = 0.2, size = 1.2,
		texture = F.tex(F.tint("minemon_fx_impact_star.png", c.palette.core), { blend = "add", fade = true,
			grow = { 0.6, 1.0 } }), glow = 10,
	})
	local splinters = {
		{ x = 0.5, y = 0.3, z = 0.4 }, { x = -0.4, y = 0.5, z = -0.3 }, { x = 0.1, y = -0.4, z = 0.6 },
	}
	for _, v in ipairs(splinters) do
		F.emit({
			amount = 1, time = 0.02, pos = vector.add(at, vector.multiply(v, 0.12)),
			vel = vector.multiply(v, 2.2), drag = { x = 1.4, y = 1.4, z = 1.4 },
			exptime = { min = 0.25, max = 0.4 }, size = 0.45,
			texture = F.tex(F.tint(SHARD, c.palette.main), { blend = "add", fade = true }), glow = 10,
		})
	end
	F.sound("default_dig_cracky", { pos = at, gain = 0.6, pitch = 1.4 })
end

minemon.fx.register_move("horn_attack", R)
