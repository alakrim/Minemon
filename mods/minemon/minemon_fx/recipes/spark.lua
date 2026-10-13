-- Spark (M2.1 wave 2, group B, power 65, paralysis 30%): a fizzing ball. The orb is a round yellow point that spits
-- round sparks in every direction (no bolts: that is Thunderbolt's look). On the hit it pops like a firecracker: a ring
-- of sparks is flung out from the victim and a sparkle clings to its body for half a second. Cast and beam come from
-- type:electric.
-- Budget at "high": launch ~30, projectile ~50/s, impact ~60.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	spark = "minemon_fx_spark.png",
	glow = "minemon_fx_glow.png",
}
local ZERO = { x = 0, y = 0, z = 0 }
local FIZZ = { min = { x = -1.0, y = -1.0, z = -1.0 }, max = { x = 1.0, y = 1.0, z = 1.0 } }
local CLING = { min = { x = -0.2, y = -0.2, z = -0.2 }, max = { x = 0.2, y = 0.2, z = 0.2 } }

-- The shot: a ring of sparks flicks out of the muzzle in every direction at once, then the shot goes forward.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9, life = 0.14 })
	F.burst({ pos = c.from, tex = TEX.spark, colour = c.palette.main, amount = 14, speed = 5, radius = 0.1,
		life = { 0.15, 0.3 }, size = { 0.1, 0.16 }, glow = 14 })
	F.emit({
		amount = 10, time = 0.05, pos = c.from, jitter = FIZZ,
		vel = { min = vector.multiply(c.dir, 3), max = vector.multiply(c.dir, 5) },
		exptime = { min = 0.15, max = 0.28 }, size = { min = 0.1, max = 0.15 },
		texture = F.tex(F.tint(TEX.spark, c.palette.main), { blend = "add", fade = true }), glow = 14,
	})
	F.sound("lightning_thunder", { pos = c.from, gain = 0.3, pitch = 2.0 })
end

-- The orb: a bright yellow point with a soft halo, and a round fizz of sparks that spit out of it at all angles.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.glow, c.palette.core) }, visual_size = { x = 0.9, y = 0.9 },
		glow = 14 })
	F.on(c.obj, {
		amount = 34, time = 1.5, pos = ZERO, vel = ZERO, jitter = FIZZ,
		exptime = { min = 0.15, max = 0.3 }, size = { min = 0.16, max = 0.24 },
		texture = F.tex(F.tint(TEX.spark, c.palette.main), { blend = "add", fade = true }), glow = 14,
	})
	F.on(c.obj, {
		amount = 8, time = 1.5, pos = ZERO, vel = ZERO,
		exptime = { min = 0.2, max = 0.3 }, size = { min = 0.9, max = 1.2 },
		texture = F.tex(F.tint(TEX.glow, c.palette.main), { blend = "add", fade = true }), glow = 14,
	})
	return true
end

-- The pop: a flash, a ring of sparks flung out, and a sparkle that clings to the victim and fades.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.3, life = 0.14 })
	F.burst({ pos = at, tex = TEX.spark, colour = c.palette.main, amount = 26, speed = 6, radius = 0.15,
		life = { 0.2, 0.4 }, size = { 0.18, 0.28 }, glow = 14 })
	F.ring({ pos = at, colour = c.palette.main, size = 0.3, grow = 2.2, life = 0.2 })
	if c.victim and c.victim:get_pos() then
		F.on(c.victim, {
			amount = 10, time = 0.5,
			pos = { min = { x = -0.25, y = 0.2, z = -0.25 }, max = { x = 0.25, y = 1.0, z = 0.25 } },
			vel = ZERO, jitter = CLING, exptime = { min = 0.12, max = 0.22 }, size = { min = 0.16, max = 0.24 },
			texture = F.tex(F.tint(TEX.spark, c.palette.core), { blend = "add", fade = true }), glow = 14,
		})
	end
	F.sound("lightning_thunder", { pos = at, gain = 0.5, pitch = 1.6 })
end

minemon.fx.register_move("spark", R)
