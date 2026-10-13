-- Normal (M2.1, T-FX-a): the type recipe. Clean white: crisp impact stars, a shock ring, bright sparks that fade
-- fast and little smoke. Budget at "high" (docs/ART_GUIDE.md section 4): cast ~35, launch ~30, projectile ~45/s,
-- impact ~100, area ~140.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	star = "minemon_fx_star.png",
	spark = "minemon_fx_spark.png",
	mote = "minemon_fx_mote.png",
	glow = "minemon_fx_glow.png",
	dust = "minemon_fx_dust.png",
}
local ZERO = { x = 0, y = 0, z = 0 }
local ORIGIN = { x = 0, y = 0, z = 0 }

local function box(p, r)
	return { min = { x = p.x - r, y = p.y - r, z = p.z - r }, max = { x = p.x + r, y = p.y + r, z = p.z + r } }
end

-- Wind-up: white motes gather at the mouth, a star winks on as the cast completes.
function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.5)
	F.inhale({ pos = at, tex = TEX.mote, colour = c.palette.main, radius = 0.9, amount = 20, time = t,
		size = { 0.08, 0.14 } })
	F.emit({
		amount = 1, time = t, pos = at, vel = ZERO, exptime = 0.25, size = 0.7,
		texture = F.tex(F.tint(TEX.star, c.palette.core), { blend = "add", fade = true, grow = { 0.4, 1.0 } }),
		glow = 10,
	})
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t + 0.05, size = 0.6,
		texture = F.tex(F.tint(TEX.glow, c.palette.core), { blend = "add", grow = { 0.2, 1.0 }, alpha = 0.7 }),
		glow = 10,
	})
end

-- Launch: a white flash with a star at the muzzle and a few sparks that fade quickly.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9 })
	F.emit({
		amount = 1, time = 0.02, pos = c.from, vel = ZERO, exptime = 0.2, size = 0.9,
		texture = F.tex(F.tint(TEX.star, c.palette.core), { blend = "add", fade = true, grow = { 0.6, 1.2 } }),
		glow = 10,
	})
	F.emit({
		amount = 10, time = 0.05, pos = c.from,
		vel = { min = vector.multiply(c.dir, 4), max = vector.multiply(c.dir, 7) },
		exptime = { min = 0.12, max = 0.22 }, size = { min = 0.12, max = 0.2 },
		texture = F.tex(F.tint(TEX.spark, c.palette.core), { blend = "add", fade = true }), glow = 10,
	})
	F.sound("mcl_criticals_hit.0", { pos = c.from, gain = 0.3, pitch = 1.6 })
end

-- The orb: a clean white bead with a sharp core, leaving a thin line of short-lived sparks behind it.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.glow, c.palette.core) }, visual_size = { x = 0.55, y = 0.55 } })
	F.on(c.obj, {
		amount = 24, time = 1.5, pos = box(ORIGIN, 0.05), vel = ZERO,
		exptime = { min = 0.15, max = 0.3 }, size = { min = 0.12, max = 0.2 },
		texture = F.tex(F.tint(TEX.spark, c.palette.core), { blend = "add", fade = true }), glow = 10,
	})
	F.on(c.obj, {
		amount = 6, time = 1.5, pos = ORIGIN, vel = ZERO,
		exptime = { min = 0.25, max = 0.35 }, size = { min = 0.3, max = 0.4 },
		texture = F.tex(F.tint(TEX.star, c.palette.main), { blend = "add", fade = true }), glow = 10,
	})
	return true
end

-- Beam: a clean white ray with a bright core and a star where it stops.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 40
	local dir = vector.multiply(d, 1 / len)
	for _, layer in ipairs({ { col = c.palette.main, size = { 0.3, 0.4 }, n = 50 },
			{ col = c.palette.core, size = { 0.12, 0.18 }, n = 50 } }) do
		F.emit({
			amount = layer.n, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
			size = { min = layer.size[1], max = layer.size[2] },
			texture = F.tex(F.tint(TEX.glow, layer.col), { blend = "add" }), glow = 10,
		}, c.from)
	end
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9 })
	F.emit({
		amount = 1, time = 0.02, pos = c.to, vel = ZERO, exptime = 0.35, size = 1.0,
		texture = F.tex(F.tint(TEX.star, c.palette.core), { blend = "add", fade = true, grow = { 0.6, 1.2 } }),
		glow = 10,
	})
end

-- Melee: a crisp white slash: sparks along a curved arc and a star at its centre.
function R.melee(F, c)
	for i = -2, 2 do
		local bulge = 0.45 - 0.08 * math.abs(i)
		local p = vector.add(c.centre, { x = c.fwd.x * bulge, y = i * 0.22, z = c.fwd.z * bulge })
		F.emit({
			amount = 5, time = 0.12, pos = p,
			vel = { min = vector.multiply(c.fwd, 2), max = vector.multiply(c.fwd, 3.5) },
			exptime = { min = 0.12, max = 0.22 }, size = { min = 0.2, max = 0.3 },
			texture = F.tex(F.tint(TEX.spark, c.palette.core), { blend = "add", fade = true }), glow = 10,
		})
	end
	F.emit({
		amount = 1, time = 0.02, pos = c.centre, vel = ZERO, exptime = 0.2, size = 1.0,
		texture = F.tex(F.tint(TEX.star, c.palette.core), { blend = "add", fade = true, grow = { 0.6, 1.1 } }),
		glow = 10,
	})
end

-- Area: a white shock ring with a second, slower ring of the type's colour, a burst of stars and a little dust.
function R.area(F, c)
	F.flare({ pos = c.centre, colour = c.palette.core, size = 1.4, life = 0.25 })
	F.ring({ pos = c.centre, colour = c.palette.core, size = 0.6, grow = c.radius * 1.5, life = 0.4 })
	F.ring({ pos = c.centre, colour = c.palette.main, size = 0.6, grow = c.radius * 1.9, life = 0.6 })
	F.burst({ pos = c.centre, tex = TEX.star, colour = c.palette.core, amount = 18, speed = c.radius * 1.5,
		radius = 0.3, life = { 0.4, 0.7 }, size = { 0.5, 0.8 }, glow = 10 })
	F.burst({ pos = c.centre, tex = TEX.dust, colour = c.palette.smoke, blend = "alpha", amount = 12,
		speed = c.radius, life = { 0.6, 1.0 }, size = { 0.6, 0.9 }, gravity = -0.5, glow = 0 })
end

-- Impact in layers: a white star at the hit, a flash, a ring, a few sparks and a short soft smoke.
function R.impact(F, c)
	local at = c.pos
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.25, size = 1.8,
		texture = F.tex(F.tint(TEX.star, c.palette.core), { blend = "add", fade = true, grow = { 0.5, 1.0 } }),
		glow = 10,
	})
	F.flare({ pos = at, colour = c.palette.core, size = 1.1 })
	F.ring({ pos = at, colour = c.palette.edge, size = 0.4, grow = 2.5, life = 0.3 })
	F.burst({ pos = at, tex = TEX.spark, colour = c.palette.core, amount = 18, speed = 4, life = { 0.2, 0.45 },
		size = { 0.1, 0.2 }, glow = 10 })
	F.smoke({ pos = at, colour = c.palette.smoke, amount = 4, size = { 0.36, 0.6 }, life = { 0.5, 0.8 }, alpha = 0.4,
		time = 0.2 })
	F.sound("mcl_criticals_hit.0", { pos = at, gain = 0.5 })
end

minemon.fx.register_move("type:normal", R)
