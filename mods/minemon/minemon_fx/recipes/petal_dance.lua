-- Petal Dance (M2.1 wave 2, group B, power 70, cast 0.6, grass): a dance of petals. During the cast, petals whirl up
-- round the user in a column; the launch throws a flurry of petals forward; the orb is a petal with a flutter of
-- petals that drift and turn behind it; on the hit the petals burst out of the victim in a flat ring and float down
-- slowly. Medium-strong and light on the eye: the petals drift, they do not fly hard. The petal is its own texture.
-- Budget at "high": cast ~30, launch ~30, projectile ~45/s, impact ~60.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	petal = "minemon_fx_petal.png",
	glow = "minemon_fx_glow.png",
}
local ZERO = { x = 0, y = 0, z = 0 }
local PETAL_TINT = "#f2ffd0"

local function petal(F, colour, o)
	return F.tex(F.tint(TEX.petal, colour), o)
end

-- Wind-up: petals whirl up in a column round the user, lifting off the ground.
function R.cast(F, c)
	local at = F.anchor(c.user, "middle", 0.5) or F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.2, c.time or 0.6)
	F.emit({
		amount = 22, time = t,
		pos = { min = vector.subtract(at, { x = 0.7, y = 0.5, z = 0.7 }),
			max = vector.add(at, { x = 0.7, y = 0.4, z = 0.7 }) },
		vel = { min = { x = -0.3, y = 0.8, z = -0.3 }, max = { x = 0.3, y = 1.4, z = 0.3 } },
		drag = { x = 0.8, y = 0.4, z = 0.8 }, exptime = { min = 0.6, max = 0.9 }, size = { min = 0.2, max = 0.3 },
		texture = petal(F, c.palette.main, { blend = "alpha", fade = { 1, 0.5 } }), glow = 4,
	})
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t + 0.05, size = 0.7,
		texture = F.tex(F.tint(TEX.glow, c.palette.core), { blend = "add", grow = { 0.2, 1.0 }, alpha = 0.7 }),
		glow = 14,
	})
end

-- The launch: a flurry of petals thrown forward, drifting and turning.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.8, life = 0.12 })
	F.emit({
		amount = 16, time = 0.08, pos = c.from,
		vel = { min = vector.multiply(c.dir, 1.6), max = vector.multiply(c.dir, 3.2) },
		drag = { x = 1.2, y = 0.6, z = 1.2 }, acc = { x = 0, y = -1.0, z = 0 },
		exptime = { min = 0.5, max = 0.8 }, size = { min = 0.2, max = 0.3 },
		texture = petal(F, c.palette.main, { blend = "alpha", fade = { 1, 0.5 } }), glow = 4,
	})
end

-- The orb: a petal (the body) with a flutter of petals that drift and turn behind it.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.petal, PETAL_TINT) }, visual_size = { x = 0.8, y = 0.8 }, glow = 4 })
	F.on(c.obj, {
		amount = 30, time = 1.5, pos = { min = { x = -0.25, y = -0.25, z = -0.25 }, max = { x = 0.25, y = 0.25, z = 0.25 } },
		vel = { min = { x = -0.4, y = -0.2, z = -0.4 }, max = { x = 0.4, y = 0.4, z = 0.4 } },
		drag = { x = 1.4, y = 0.8, z = 1.4 }, exptime = { min = 0.5, max = 0.8 }, size = { min = 0.2, max = 0.3 },
		texture = petal(F, c.palette.main, { blend = "alpha", fade = { 1, 0.5 } }), glow = 4,
	})
	return true
end

-- The burst: petals fly out of the victim in a flat ring and float down slowly, a few turning in the air.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.1, life = 0.12 })
	F.emit({
		amount = 22, time = 0.05, pos = at,
		vel = { min = { x = -2.6, y = 0.6, z = -2.6 }, max = { x = 2.6, y = 1.4, z = 2.6 } },
		drag = { x = 1.6, y = 1.0, z = 1.6 }, acc = { x = 0, y = -1.2, z = 0 },
		exptime = { min = 0.8, max = 1.3 }, size = { min = 0.2, max = 0.32 },
		texture = petal(F, c.palette.main, { blend = "alpha", fade = { 1, 0.4 } }), glow = 4,
	})
	F.sound("default_grass_footstep", { pos = at, gain = 0.5, pitch = 1.4 })
end

minemon.fx.register_move("petal_dance", R)
