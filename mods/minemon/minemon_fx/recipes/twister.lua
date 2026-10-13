-- Twister (signature, M2.1 T-FX-c): a whirlwind. Eight spawners in a ring throw indigo streaks along the tangent of
-- the circle, so the streaks sweep round in a column of spinning arcs; gold sparks rise through the middle and a dust
-- ring sweeps the ground. Silhouette: a spinning column that climbs, not an expanding ball. Budget: docs/ART_GUIDE.md 4
-- (area 200).
-- Totals at "high": area ~150 over 1 s, plus the ring and the flare.
-- luacheck: read_globals core vector minemon

local R = {}

local GOLD = "#ffd040"
local SPOKES = 8

function R.area(F, c)
	local r = c.radius or 6
	local centre = c.centre
	local r0 = r * 0.45
	local speed = r * 0.35
	F.flare({ pos = centre, colour = c.palette.core, size = 1.4, life = 0.2 })
	F.ring({ pos = centre, colour = c.palette.main, size = 0.6, grow = r * 2 / 0.6, life = 0.6 })
	for k = 0, SPOKES - 1 do
		local a = k * math.pi * 2 / SPOKES
		local cx, cz = math.cos(a), math.sin(a)
		local p = { x = centre.x + cx * r0, y = centre.y, z = centre.z + cz * r0 }
		-- The tangent of the circle (the spin) plus a lift: the streak sweeps round as it rises.
		local tx, tz = -cz * speed, cx * speed
		F.emit({
			amount = 12, time = 1.0, pos = { min = vector.subtract(p, { x = 0.4, y = 0, z = 0.4 }),
				max = vector.add(p, { x = 0.4, y = 0.6, z = 0.4 }) },
			vel = { min = { x = tx * 0.8, y = 1.5, z = tz * 0.8 }, max = { x = tx * 1.2, y = 2.5, z = tz * 1.2 } },
			exptime = { min = 0.6, max = 1.0 }, size = { min = 0.5, max = 0.8 }, vertical = true, glow = 14,
			texture = F.tex(F.tint(F.TEX.streak, c.palette.main), { blend = "add", fade = true }),
		})
	end
	-- Gold sparks thrown up through the column, and their fall back down on the way out.
	F.emit({
		amount = 24, time = 1.0, pos = { min = vector.subtract(centre, { x = r0, y = 0, z = r0 }),
			max = vector.add(centre, { x = r0, y = 0.5, z = r0 }) },
		vel = { min = { x = -0.5, y = 2.5, z = -0.5 }, max = { x = 0.5, y = 4.5, z = 0.5 } },
		acc = { x = 0, y = -4, z = 0 }, exptime = { min = 0.5, max = 0.9 }, size = { min = 0.07, max = 0.12 },
		texture = F.tex(F.tint(F.TEX.spark, GOLD), { blend = "add", fade = true }), glow = 14,
	})
	F.burst({ pos = centre, tex = F.TEX.dust, colour = c.palette.smoke, blend = "alpha", amount = 16, speed = r * 0.8,
		life = { 0.6, 1.0 }, size = { 0.6, 0.9 }, gravity = -0.5, glow = 0 })
	F.sound("mobs_mc_ender_dragon_shoot", { pos = centre, gain = 0.5, pitch = 0.7 })
end

minemon.fx.register_move("twister", R)
