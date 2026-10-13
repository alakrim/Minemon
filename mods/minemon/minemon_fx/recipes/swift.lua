-- Swift (M2.1 wave 2, group B, power 60, never misses, area): a shower of stars. From the target a burst of small
-- star sprites flies out in every direction across the area, and each star that reaches a victim sparks there; each
-- victim gets a four-point star flash and a few trailing sparkles. Its look is the stars, cream-white, the normal
-- type's colour: no ring, no dust.
-- Budget at "high": area ~110, impact ~40.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	star = "minemon_fx_star.png",
	impact_star = "minemon_fx_impact_star.png",
	spark = "minemon_fx_spark.png",
}
local ZERO = { x = 0, y = 0, z = 0 }

-- The shower: small stars fly out from the centre over the whole radius, and a few spin off at higher speed.
function R.area(F, c)
	local r = c.radius
	local ctr = c.centre
	F.burst({ pos = ctr, tex = TEX.star, colour = c.palette.core, amount = 30, speed = r * 1.6, radius = 0.25,
		life = { 0.45, 0.85 }, size = { 0.16, 0.24 }, glow = 14 })
	F.burst({ pos = ctr, tex = TEX.spark, colour = c.palette.main, amount = 14, speed = r * 2.4, radius = 0.2,
		life = { 0.3, 0.55 }, size = { 0.1, 0.14 }, glow = 14 })
	F.flare({ pos = ctr, colour = c.palette.core, size = 1.0, life = 0.14 })
	F.sound("mcl_enchanting_enchant", { pos = ctr, gain = 0.5, pitch = 1.8 })
end

-- The hit: a four-point star flashes on the victim and a few sparkles trail off it.
function R.impact(F, c)
	local at = c.pos
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.22, size = 1.3,
		texture = F.tex(F.tint(TEX.impact_star, c.palette.core), { blend = "add", fade = true, grow = { 0.6, 1.1 } }),
		glow = 14,
	})
	F.burst({ pos = at, tex = TEX.spark, colour = c.palette.core, amount = 8, speed = 3, radius = 0.15,
		life = { 0.2, 0.4 }, size = { 0.1, 0.14 }, glow = 14 })
	F.sound("mcl_enchanting_enchant", { pos = at, gain = 0.4, pitch = 2.0 })
end

minemon.fx.register_move("swift", R)
