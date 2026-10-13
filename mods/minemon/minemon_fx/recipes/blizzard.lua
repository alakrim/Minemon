-- Blizzard (M2.1, T-FX-a, signature ice move): a storm of snow over the whole area. Flakes and shards whirl down
-- through the radius, a frost ring rolls out, and a frost patch and a cold mist stay where it fell. Budget: area
-- ~190. Cast, launch, projectile, beam, melee and impact come from type:ice.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	frost = "minemon_fx_frost.png",
	shard = "minemon_fx_shard.png",
	mote = "minemon_fx_mote.png",
	frost_decal = "minemon_fx_frost_decal.png",
	smoke = "minemon_fx_smoke_anim.png",
	ring = "minemon_fx_ring.png",
}
local ZERO = { x = 0, y = 0, z = 0 }

function R.area(F, c)
	local r = c.radius
	-- The snow: flakes fall from above the area and whirl sideways as they come down.
	F.emit({
		amount = 80, time = 1.4,
		pos = { min = { x = c.centre.x - r, y = c.centre.y + 1.5, z = c.centre.z - r },
			max = { x = c.centre.x + r, y = c.centre.y + 3.0, z = c.centre.z + r } },
		vel = { min = { x = -1.5, y = -2.5, z = -1.5 }, max = { x = 1.5, y = -1.0, z = 1.5 } },
		jitter = { min = { x = -0.8, y = 0, z = -0.8 }, max = { x = 0.8, y = 0, z = 0.8 } },
		exptime = { min = 1.2, max = 1.8 }, size = { min = 0.12, max = 0.24 },
		texture = F.tex(F.tint(TEX.frost, c.palette.core), { blend = "alpha", fade = true }), glow = 8,
	})
	-- Shards whirl down among them and bounce on the ground.
	F.emit({
		amount = 26, time = 1.2,
		pos = { min = { x = c.centre.x - r * 0.8, y = c.centre.y + 1.0, z = c.centre.z - r * 0.8 },
			max = { x = c.centre.x + r * 0.8, y = c.centre.y + 2.5, z = c.centre.z + r * 0.8 } },
		vel = { min = { x = -1, y = -1.5, z = -1 }, max = { x = 1, y = 0, z = 1 } }, acc = { x = 0, y = -9.8, z = 0 },
		jitter = { min = { x = -1.2, y = 0, z = -1.2 }, max = { x = 1.2, y = 0, z = 1.2 } },
		collisiondetection = true, bounce = { min = 0.2, max = 0.3 },
		exptime = { min = 1.0, max = 1.6 }, size = { min = 0.14, max = 0.22 },
		texture = F.tex(F.tint(TEX.shard, c.palette.main), { blend = "alpha", fade = true }), glow = 6,
	})
	-- A frost ring rolls outward at the start, and the glints hang in the cold air.
	F.ring({ pos = c.centre, colour = c.palette.core, size = 0.6, grow = r * 1.6, life = 0.6 })
	F.emit({
		amount = 24, time = 1.4, pos = { min = { x = c.centre.x - r, y = c.centre.y, z = c.centre.z - r },
			max = { x = c.centre.x + r, y = c.centre.y + 2.0, z = c.centre.z + r } },
		vel = ZERO, jitter = { min = { x = -0.6, y = -0.6, z = -0.6 }, max = { x = 0.6, y = 0.6, z = 0.6 } },
		exptime = { min = 0.4, max = 0.8 }, size = { min = 0.1, max = 0.18 },
		texture = F.tex(F.tint(TEX.mote, c.palette.core), { blend = "add", fade = true }), glow = 10,
	})
	-- The mist and the frost that stays, where the storm landed.
	F.emit({
		amount = 8, time = 1.4, pos = { min = { x = c.centre.x - r * 0.7, y = c.centre.y - 0.2, z = c.centre.z - r * 0.7 },
			max = { x = c.centre.x + r * 0.7, y = c.centre.y + 0.4, z = c.centre.z + r * 0.7 } },
		vel = { min = { x = -0.1, y = 0.1, z = -0.1 }, max = { x = 0.1, y = 0.3, z = 0.1 } },
		exptime = { min = 1.5, max = 2.2 }, size = { min = 0.9, max = 1.4 },
		texture = F.tex(F.tint(TEX.smoke, c.palette.smoke), { blend = "alpha", alpha = 0.3, anim = "smoke" }),
	})
	F.decal({ pos = c.centre, tex = F.tint(TEX.frost_decal, c.palette.main), size = r * 1.8, life = 8 })
	F.sound("default_break_glass", { pos = c.centre, gain = 0.5, pitch = 0.6 })
end

minemon.fx.register_move("blizzard", R)
