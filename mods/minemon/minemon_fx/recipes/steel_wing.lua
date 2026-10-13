-- Steel Wing (M2.1, T-FX-a, signature steel move): a bright, flat wing of light sweeps across the target, glints
-- hang in the air after it and a ring rings out at the hit. Budget: melee ~90, impact ~100. Cast, launch,
-- projectile, beam and area come from type:steel.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	streak = "minemon_fx_streak.png",
	spark = "minemon_fx_spark.png",
	glow = "minemon_fx_glow.png",
	ring = "minemon_fx_ring.png",
}
local ZERO = { x = 0, y = 0, z = 0 }

-- A bright wing of light: streaks laid along the arc of the sweep, then glints that hang in the air.
function R.melee(F, c)
	for i = -2, 2 do
		local bulge = 0.5 - 0.07 * math.abs(i)
		local p = vector.add(c.centre, { x = c.fwd.x * bulge, y = i * 0.24, z = c.fwd.z * bulge })
		F.emit({
			amount = 6, time = 0.12, pos = p, vel = vector.multiply(c.fwd, 1.2), exptime = { min = 0.15, max = 0.28 },
			size = { min = 0.34, max = 0.5 },
			texture = F.tex(F.tint(TEX.streak, c.palette.core), { blend = "add", fade = true }), vertical = false,
			glow = 14,
		})
	end
	F.emit({
		amount = 16, time = 0.25, pos = { min = vector.add(c.centre, { x = -0.5, y = -0.4, z = -0.5 }),
			max = vector.add(c.centre, { x = 0.5, y = 0.4, z = 0.5 }) },
		vel = ZERO, jitter = { min = { x = -0.8, y = -0.8, z = -0.8 }, max = { x = 0.8, y = 0.8, z = 0.8 } },
		exptime = { min = 0.2, max = 0.4 }, size = { min = 0.1, max = 0.16 },
		texture = F.tex(F.tint(TEX.spark, c.palette.core), { blend = "add", fade = true }), glow = 14,
	})
	F.flare({ pos = c.centre, colour = c.palette.core, size = 1.5, life = 0.15 })
	F.sound("mesecons_noteblock_xylophone_metal", { pos = c.centre, gain = 0.4, pitch = 1.8 })
end

-- The hit: a flat white flash, a ring that rings out and bright glints that float away.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.8, life = 0.16 })
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.3, size = 1.4,
		texture = F.tex(F.tint(TEX.ring, c.palette.core), { blend = "add", fade = true, grow = { 0.3, 2.6 } }),
		glow = 14,
	})
	F.ring({ pos = at, colour = c.palette.edge, size = 0.5, grow = 3.0, life = 0.35 })
	F.burst({ pos = at, tex = TEX.glow, colour = c.palette.core, amount = 16, speed = 2.5, radius = 0.2,
		life = { 0.4, 0.8 }, size = { 0.12, 0.2 }, glow = 14, drag = 0.4 })
	F.burst({ pos = at, tex = TEX.spark, colour = c.palette.main, amount = 20, speed = 4, radius = 0.15,
		life = { 0.2, 0.45 }, size = { 0.1, 0.16 }, glow = 14, collide = true, bounce = 0.4 })
	F.sound("mesecons_noteblock_xylophone_metal", { pos = at, gain = 0.6, pitch = 1.7 })
	F.sound("mcl_bells_bell_stroke", { pos = at, gain = 0.3, pitch = 1.3 })
end

minemon.fx.register_move("steel_wing", R)
