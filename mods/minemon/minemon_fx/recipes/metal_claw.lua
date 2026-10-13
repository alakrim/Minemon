-- Metal Claw (M2.1, T-FX-a, signature steel move): three claw marks of bright sparks that bounce off the ground,
-- steel chips flung along the swipe and a ringing white flash on the hit. Budget: melee ~90, impact ~110. Cast,
-- launch, projectile, beam and area come from type:steel.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	spark = "minemon_fx_spark.png",
	chip = "minemon_fx_chip.png",
	glow = "minemon_fx_glow.png",
}
local GRAVITY = { x = 0, y = -9.8, z = 0 }

-- Three slashes, one above the other, each a line of sparks that falls and bounces.
function R.melee(F, c)
	local side = vector.new(-c.fwd.z, 0, c.fwd.x)
	for i = -1, 1 do
		local p = vector.add(c.centre, vector.add(vector.multiply(side, i * 0.22), { x = 0, y = -i * 0.12, z = 0 }))
		F.emit({
			amount = 14, time = 0.12, pos = p,
			vel = { min = vector.multiply(c.fwd, 2.5), max = vector.multiply(c.fwd, 4.5) }, acc = GRAVITY,
			exptime = { min = 0.3, max = 0.6 }, size = { min = 0.08, max = 0.14 },
			texture = F.tex(F.tint(TEX.spark, c.palette.core), { blend = "add" }),
			collisiondetection = true, bounce = { min = 0.3, max = 0.5 }, glow = 14,
		})
	end
	F.emit({
		amount = 10, time = 0.12, pos = c.centre,
		vel = { min = vector.multiply(c.fwd, 2), max = vector.multiply(c.fwd, 4) }, acc = GRAVITY,
		exptime = { min = 0.5, max = 0.8 }, size = { min = 0.12, max = 0.2 },
		texture = F.tex(F.tint(TEX.chip, c.palette.main), { blend = "alpha", fade = true }),
		collisiondetection = true, bounce = { min = 0.2, max = 0.3 }, glow = 6,
	})
	F.flare({ pos = c.centre, colour = c.palette.core, size = 1.4, life = 0.15 })
	F.sound("default_dig_metal", { pos = c.centre, gain = 0.7, pitch = 1.3 })
end

-- The hit: three bright sparks in claw lines at the victim, a chime, and chips that bounce.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.6, life = 0.14 })
	for i = -1, 1 do
		local p = vector.add(at, { x = i * 0.18, y = -i * 0.1, z = 0 })
		F.burst({ pos = p, tex = TEX.spark, colour = c.palette.core, amount = 14, speed = 3, radius = 0.1,
			life = { 0.2, 0.45 }, size = { 0.08, 0.14 }, gravity = 9.8, collide = true, bounce = 0.4, glow = 14 })
	end
	F.burst({ pos = at, tex = TEX.chip, colour = c.palette.main, amount = 12, speed = 3, radius = 0.15,
		life = { 0.5, 0.9 }, size = { 0.12, 0.2 }, gravity = 9.8, collide = true, bounce = 0.35, blend = "alpha",
		glow = 6 })
	F.ring({ pos = at, colour = c.palette.main, size = 0.3, grow = 2.4, life = 0.25 })
	F.sound("mesecons_noteblock_xylophone_metal", { pos = at, gain = 0.5, pitch = 1.5 })
end

minemon.fx.register_move("metal_claw", R)
