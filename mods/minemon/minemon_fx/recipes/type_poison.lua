-- Poison type (M2.1, T-FX-b): every poison move without a recipe of its own. Bubbling purple goo: globs that splash and
-- fall with gravity, drips, rising bubbles and a toxic puddle that stays on the ground for a few seconds. Five beats:
-- bubbles rise from the mouth while goo gathers; a splash of goo leaves the muzzle; the projectile is a glob that drips
-- as it flies; the impact splashes goo with gravity and bounce, and leaves a puddle; the aftermath is the default
-- cloud and aura. Budget (docs/ART_GUIDE.md): cast 80, launch 60, projectile 90/s, impact 160, area 200, beam 160.
-- luacheck: read_globals core vector minemon

local R = {}

local GOO = "minemon_fx_goo.png" -- a glossy blob: globs and the orb
local DROP = "minemon_fx_drop.png" -- a teardrop, pointed up: drips that fall
local PUDDLE = "minemon_fx_toxic_puddle.png" -- a toxic pool decal
local ZERO = { x = 0, y = 0, z = 0 }

local function goo(F, colour, o)
	return F.tex(F.tint(GOO, colour), o)
end

local function drop(F, colour, o)
	return F.tex(F.tint(DROP, colour), o)
end

-- A radial spray (particles thrown out of pos, as F.burst; any texture). o: amount, speed (m/s), life {min, max},
-- size {min, max}, texture, time, gravity, collide, bounce, glow.
local function spray(F, pos, o)
	local speed = o.speed or 4
	return F.emit({
		amount = o.amount, time = o.time or 0.05, pos = pos, radius = { min = 0.1, max = 0.25, bias = 0 },
		attract = { kind = "point", origin = pos, strength = { min = -speed / 0.25 * 0.6, max = -speed / 0.25 },
			die_on_contact = false },
		vel = ZERO, acc = { x = 0, y = -(o.gravity or 0), z = 0 },
		exptime = { min = o.life[1], max = o.life[2] }, size = { min = o.size[1], max = o.size[2] },
		collisiondetection = o.collide == true, bounce = o.bounce and { min = o.bounce * 0.6, max = o.bounce } or nil,
		texture = o.texture, glow = o.glow or 0,
	})
end

-- Wind-up: bubbles rise from the mouth, globs gather in it, a purple glow swells.
function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.emit({
		amount = 14, time = t, pos = at, radius = { min = 0.1, max = 0.3, bias = 0 },
		vel = { min = { x = -0.1, y = 0.5, z = -0.1 }, max = { x = 0.1, y = 1.0, z = 0.1 } },
		exptime = { min = 0.5, max = 0.9 }, size = { min = 0.1, max = 0.2 },
		texture = F.tex(F.tint(F.TEX.ring, c.palette.main), { blend = "alpha", fade = true, grow = { 0.6, 1.2 } }),
		glow = 6,
	})
	F.emit({
		amount = 8, time = t, pos = at, radius = { min = 0.6, max = 1.1, bias = 0 },
		attract = { kind = "point", origin = at, strength = { min = 2.5, max = 3.5 }, die_on_contact = true },
		vel = ZERO, exptime = { min = 0.25, max = 0.45 }, size = { min = 0.12, max = 0.2 },
		texture = goo(F, c.palette.main, { blend = "alpha", fade = true }), glow = 0,
	})
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t + 0.05, size = 0.7,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add", grow = { 0.2, 1.0 }, alpha = 0.6 }),
		glow = 10,
	})
	F.sound("mcl_sounds_dug_water", { pos = at, gain = 0.6, pitch = 0.8 })
end

-- Launch: a splash of goo flung along the shot, with gravity; a flash at the muzzle.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.8, life = 0.14 })
	spray(F, c.from, { amount = 14, speed = 3, life = { 0.4, 0.7 }, size = { 0.14, 0.24 }, gravity = 9,
		collide = true, bounce = 0.2, texture = goo(F, c.palette.main, { blend = "alpha", fade = { 1, 0.6 } }) })
	F.sound("mcl_throwing_throw", { pos = c.from, gain = 0.5, pitch = 0.7 })
end

-- The orb: a glob with a glow, dripping drops that fall and bubbles that rise from it. Returns true: decorated.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(GOO, c.palette.main) }, visual_size = { x = 0.6, y = 0.6 }, glow = 8 })
	F.on(c.obj, {
		amount = 20, time = 1.5, pos = { min = { x = -0.08, y = -0.08, z = -0.08 }, max = { x = 0.08, y = 0.08, z = 0.08 } },
		vel = { min = { x = -0.3, y = -0.5, z = -0.3 }, max = { x = 0.3, y = 0.1, z = 0.3 } },
		acc = { x = 0, y = -9, z = 0 }, vertical = true, collisiondetection = true,
		exptime = { min = 0.35, max = 0.6 }, size = { min = 0.14, max = 0.22 },
		texture = drop(F, c.palette.main, { blend = "alpha", fade = { 1, 0.7 } }), glow = 0,
	})
	F.on(c.obj, {
		amount = 8, time = 1.5, pos = { min = { x = -0.2, y = -0.2, z = -0.2 }, max = { x = 0.2, y = 0.2, z = 0.2 } },
		vel = { min = { x = -0.1, y = 0.4, z = -0.1 }, max = { x = 0.1, y = 0.9, z = 0.1 } },
		exptime = { min = 0.4, max = 0.7 }, size = { min = 0.1, max = 0.16 },
		texture = F.tex(F.tint(F.TEX.ring, c.palette.core), { blend = "alpha", fade = true, grow = { 0.6, 1.2 } }),
		glow = 8,
	})
	F.on(c.obj, {
		amount = 14, time = 1.5, pos = { x = 0, y = 0, z = 0 },
		vel = { min = { x = -0.1, y = -0.1, z = -0.1 }, max = { x = 0.1, y = 0.1, z = 0.1 } },
		exptime = { min = 0.2, max = 0.35 }, size = { min = 0.3, max = 0.45 },
		texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add", fade = true, grow = { 1, 0.3 } }),
		glow = 14,
	})
	return true
end

-- Beam: a heavy stream of goo that arcs down under gravity, drips behind it, and a splash and a puddle where it stops.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 18
	local dir = vector.multiply(d, 1 / len)
	F.emit({
		amount = 40, time = 0.3, pos = c.from, vel = vector.multiply(dir, speed), acc = { x = 0, y = -9, z = 0 },
		exptime = len / speed, size = { min = 0.3, max = 0.46 },
		texture = goo(F, c.palette.main, { blend = "alpha", fade = { 1, 0.8 } }), glow = 0,
	}, c.from)
	F.emit({
		amount = 24, time = 0.3, pos = c.from, vertical = true, collisiondetection = true,
		vel = vector.multiply(dir, speed * 0.7), acc = { x = 0, y = -12, z = 0 },
		exptime = { min = 0.5, max = 0.9 }, size = { min = 0.14, max = 0.2 },
		texture = drop(F, c.palette.main, { blend = "alpha", fade = { 1, 0.7 } }), glow = 0,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.8 })
	spray(F, c.to, { amount = 18, speed = 3, life = { 0.4, 0.7 }, size = { 0.14, 0.22 }, gravity = 9, collide = true,
		bounce = 0.3, texture = goo(F, c.palette.main, { blend = "alpha", fade = { 1, 0.6 } }) })
	F.decal({ pos = c.to, tex = F.tint(PUDDLE, c.palette.main), size = 1.6, life = 6 })
end

-- Melee: a smear of goo swept in an arc in front of the user, dripping as it goes.
function R.melee(F, c)
	for i = -2, 2 do
		local bulge = 0.45 - 0.08 * math.abs(i)
		local p = vector.add(c.centre, { x = c.fwd.x * bulge, y = i * 0.22, z = c.fwd.z * bulge })
		F.emit({
			amount = 4, time = 0.1, pos = p, vertical = true,
			vel = { min = vector.multiply(c.fwd, 1.5), max = vector.multiply(c.fwd, 2.5) },
			acc = { x = 0, y = -8, z = 0 }, exptime = { min = 0.3, max = 0.5 }, size = { min = 0.18, max = 0.26 },
			texture = drop(F, c.palette.main, { blend = "alpha", fade = { 1, 0.7 } }), glow = 0,
		})
	end
	F.emit({
		amount = 1, time = 0.02, pos = c.centre, vel = ZERO, exptime = 0.2, size = 0.8,
		texture = goo(F, c.palette.main, { blend = "alpha", fade = true, grow = { 0.6, 1.2 } }), glow = 0,
	})
end

-- Area: a ring of goo thrown wide, bubbles rising through it, and a toxic puddle that stays where it fell.
function R.area(F, c)
	local r = c.radius
	F.ring({ pos = c.centre, colour = c.palette.main, size = 0.5, grow = r * 1.4, life = 0.45 })
	spray(F, c.centre, { amount = 30, speed = r * 1.6, life = { 0.5, 0.9 }, size = { 0.14, 0.24 }, gravity = 10,
		collide = true, bounce = 0.2, texture = goo(F, c.palette.main, { blend = "alpha", fade = { 1, 0.6 } }) })
	F.emit({
		amount = 26, time = 0.5, pos = c.centre, radius = { min = r * 0.4, max = r * 0.9, bias = 0 },
		vel = { min = { x = -0.2, y = 0.6, z = -0.2 }, max = { x = 0.2, y = 1.2, z = 0.2 } },
		exptime = { min = 0.6, max = 1.1 }, size = { min = 0.12, max = 0.22 },
		texture = F.tex(F.tint(F.TEX.ring, c.palette.main), { blend = "alpha", fade = true, grow = { 0.6, 1.2 } }),
		glow = 6,
	})
	F.decal({ pos = c.centre, tex = F.tint(PUDDLE, c.palette.main), size = r * 1.6, life = 7 })
end

-- Impact: a flash, goo splashing out with gravity and bounce, drips, a few bubbles that pop, and a puddle.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.0, life = 0.12 })
	spray(F, at, { amount = 16, speed = 3.5, life = { 0.4, 0.7 }, size = { 0.14, 0.24 }, gravity = 9, collide = true,
		bounce = 0.25, texture = goo(F, c.palette.main, { blend = "alpha", fade = { 1, 0.6 } }) })
	F.emit({
		amount = 10, time = 0.3, pos = at, radius = { min = 0.1, max = 0.3, bias = 0 }, vertical = true,
		vel = ZERO, acc = { x = 0, y = -9, z = 0 }, collisiondetection = true,
		exptime = { min = 0.4, max = 0.7 }, size = { min = 0.12, max = 0.2 },
		texture = drop(F, c.palette.main, { blend = "alpha", fade = { 1, 0.7 } }), glow = 0,
	})
	F.emit({
		amount = 8, time = 0.1, pos = at, radius = { min = 0.2, max = 0.4, bias = 0 },
		vel = { min = { x = -0.2, y = 0.3, z = -0.2 }, max = { x = 0.2, y = 0.6, z = 0.2 } },
		exptime = { min = 0.3, max = 0.5 }, size = { min = 0.12, max = 0.22 },
		texture = F.tex(F.tint(F.TEX.ring, c.palette.core), { blend = "alpha", fade = true, grow = { 0.5, 1.4 } }),
		glow = 6,
	})
	F.decal({ pos = at, tex = F.tint(PUDDLE, c.palette.main), size = 1.0, life = 6 })
	F.ring({ pos = at, colour = c.palette.edge, size = 0.3, grow = 2.4, life = 0.3 })
	F.sound("mcl_throwing_snowball_impact_soft", { pos = at, gain = 0.8, pitch = 0.8 })
end

minemon.fx.register_move("type:poison", R)
