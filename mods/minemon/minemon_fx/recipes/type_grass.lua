-- Grass type (M2.1, T-FX-b): every grass move without a recipe of its own. Spinning leaves and pollen motes, a green
-- flash at the muzzle. Five beats: pollen and leaves are drawn into the mouth; leaves burst from the muzzle; the
-- projectile is a ball of spinning leaves with a pollen trail; the impact scatters leaves round a green ring; the
-- aftermath is a slow drift of pollen (the default aura and cloud). Budget (docs/ART_GUIDE.md): cast 80, launch 60,
-- projectile 90/s, impact 160, area 200, beam 160.
-- luacheck: read_globals core vector minemon

local R = {}

local LEAF = "minemon_fx_leaf_spin_anim.png" -- 8 frames of 16 px: a leaf that flips as it spins
local ZERO = { x = 0, y = 0, z = 0 }

-- A spinning leaf particle (alpha blend: leaves are opaque), tinted with the type's main colour.
local function leaf(F, colour, o)
	local t = F.tex(F.tint(LEAF, colour), o)
	t.animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = -1 }
	return t
end

-- A ring of leaves thrown outwards from pos (a burst with negative attraction, as F.burst). speed in m/s.
local function leaf_burst(F, c, pos, speed, amount, life, size)
	F.emit({
		amount = amount, time = 0.06, pos = pos, radius = { min = 0.1, max = 0.3, bias = 0 },
		attract = { kind = "point", origin = pos, strength = { min = -speed / 0.3 * 0.6, max = -speed / 0.3 },
			die_on_contact = false },
		vel = ZERO, drag = { x = 1.2, y = 0.5, z = 1.2 }, acc = { x = 0, y = -1.0, z = 0 },
		exptime = { min = life[1], max = life[2] }, size = { min = size[1], max = size[2] },
		texture = leaf(F, c.palette.main, { blend = "alpha", fade = { 1, 0.5 } }), glow = 0,
	})
end

-- Wind-up: pollen and leaves drawn into the mouth, a bloom of light there, a rustle.
function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.5)
	F.inhale({ pos = at, colour = c.palette.main, radius = 1.0, amount = 18, time = t, size = { 0.12, 0.18 } })
	F.emit({
		amount = 8, time = t, pos = at, radius = { min = 0.6, max = 1.1, bias = 0 },
		attract = { kind = "point", origin = at, strength = { min = 2.5, max = 3.5 }, die_on_contact = true },
		vel = ZERO, exptime = { min = 0.25, max = 0.45 }, size = { min = 0.32, max = 0.44 },
		texture = leaf(F, c.palette.main, { blend = "alpha", fade = { 1, 0.6 } }), glow = 0,
	})
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t + 0.05, size = 0.7,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add", grow = { 0.2, 1.0 }, alpha = 0.7 }),
		glow = 14,
	})
	F.sound("default_dig_snappy", { pos = at, gain = 0.35, pitch = 1.5 })
end

-- Launch: a flash at the muzzle, leaves flung along the shot, a little pollen.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9, life = 0.15 })
	F.emit({
		amount = 14, time = 0.05, pos = c.from,
		vel = { min = vector.add(vector.multiply(c.dir, 3), { x = -1, y = -0.3, z = -1 }),
			max = vector.add(vector.multiply(c.dir, 6), { x = 1, y = 1.2, z = 1 }) },
		acc = { x = 0, y = -1.5, z = 0 }, drag = { x = 1.2, y = 0.6, z = 1.2 },
		exptime = { min = 0.5, max = 0.9 }, size = { min = 0.32, max = 0.44 },
		texture = leaf(F, c.palette.main, { blend = "alpha", fade = { 1, 0.5 } }), glow = 0,
	})
	F.burst({ pos = c.from, tex = F.TEX.mote, colour = c.palette.core, amount = 14, speed = 3,
		life = { 0.2, 0.45 }, size = { 0.1, 0.18 } })
	F.sound("default_dig_snappy", { pos = c.from, gain = 0.5, pitch = 1.2 })
end

-- The orb: a ball of spinning leaves (a flipbook sprite) with a pollen glow; the leaves it sheds fall and spin.
-- Returns true: decorated.
function R.projectile(F, c)
	local obj = c.obj
	obj:set_properties({ textures = { LEAF }, spritediv = { x = 1, y = 8 }, visual_size = { x = 0.6, y = 0.6 },
		glow = 8 })
	obj:set_sprite({ x = 0, y = 0 }, 8, 0.07, false)
	F.on(obj, {
		amount = 40, time = 1.5, pos = { min = { x = -0.1, y = -0.1, z = -0.1 }, max = { x = 0.1, y = 0.1, z = 0.1 } },
		vel = { min = { x = -0.3, y = -0.2, z = -0.3 }, max = { x = 0.3, y = 0.4, z = 0.3 } },
		acc = { x = 0, y = -1.2, z = 0 },
		exptime = { min = 0.5, max = 0.8 }, size = { min = 0.34, max = 0.46 },
		texture = leaf(F, c.palette.main, { blend = "alpha", fade = { 1, 0.4 }, grow = { 1, 0.6 } }), glow = 0,
	})
	F.on(obj, {
		amount = 18, time = 1.5, pos = { x = 0, y = 0, z = 0 },
		vel = { min = { x = -0.4, y = -0.1, z = -0.4 }, max = { x = 0.4, y = 0.4, z = 0.4 } },
		exptime = { min = 0.3, max = 0.6 }, size = { min = 0.1, max = 0.2 },
		texture = F.tex(F.tint(F.TEX.mote, c.palette.core), { blend = "add", fade = true }), glow = 14,
	})
	return true
end

-- Beam: a stream of pollen with leaves riding it, and a bloom where it stops.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 30
	local dir = vector.multiply(d, 1 / len)
	F.emit({
		amount = 50, time = 0.4, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = { min = 0.14, max = 0.22 },
		texture = F.tex(F.tint(F.TEX.mote, c.palette.main), { blend = "add", fade = true }), glow = 14,
	}, c.from)
	F.emit({
		amount = 22, time = 0.4, pos = c.from,
		vel = { min = vector.add(vector.multiply(dir, 5), { x = -0.8, y = -0.8, z = -0.8 }),
			max = vector.add(vector.multiply(dir, 8), { x = 0.8, y = 0.8, z = 0.8 }) },
		exptime = { min = 0.6, max = 1.0 }, size = { min = 0.34, max = 0.44 },
		texture = leaf(F, c.palette.main, { blend = "alpha", fade = { 1, 0.6 } }), glow = 0,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9 })
	F.flare({ pos = c.to, colour = c.palette.core, size = 1.1, life = 0.3 })
	leaf_burst(F, c, c.to, 3, 12, { 0.4, 0.8 }, { 0.3, 0.42 })
end

-- Melee: five leaves swept in an arc in front of the user, and a bright bloom at its heart.
function R.melee(F, c)
	for i = -2, 2 do
		local bulge = 0.45 - 0.08 * math.abs(i)
		local p = vector.add(c.centre, { x = c.fwd.x * bulge, y = i * 0.22, z = c.fwd.z * bulge })
		F.emit({
			amount = 5, time = 0.12, pos = p,
			vel = { min = vector.multiply(c.fwd, 1.5), max = vector.multiply(c.fwd, 3) },
			exptime = { min = 0.2, max = 0.35 }, size = { min = 0.4, max = 0.5 },
			texture = leaf(F, c.palette.main, { blend = "alpha", fade = { 1, 0.5 } }), glow = 0,
		})
	end
	F.emit({
		amount = 1, time = 0.02, pos = c.centre, vel = ZERO, exptime = 0.18, size = 0.9,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add", fade = true, grow = { 0.6, 1.2 } }),
		glow = 14,
	})
end

-- Area: a green shock ring, leaves flung out from the centre and a drift of pollen.
function R.area(F, c)
	F.flare({ pos = c.centre, colour = c.palette.core, size = 1.2, life = 0.2 })
	F.ring({ pos = c.centre, colour = c.palette.main, size = 0.6, grow = c.radius * 1.6, life = 0.4 })
	leaf_burst(F, c, c.centre, 4, 40, { 0.6, 1.2 }, { 0.2, 0.32 })
	F.burst({ pos = c.centre, tex = F.TEX.mote, colour = c.palette.core, amount = 24, speed = c.radius * 1.5,
		life = { 0.4, 0.8 }, size = { 0.1, 0.2 } })
end

-- Impact: a flash, leaves scattered round a green ring, pollen and a leaf-cut rustle.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = "#ffffff", size = 1.8, life = 0.14 })
	F.ring({ pos = at, colour = c.palette.main, size = 0.4, grow = 3, life = 0.3 })
	leaf_burst(F, c, at, 2.5, 16, { 0.6, 1.1 }, { 0.36, 0.5 })
	F.burst({ pos = at, tex = F.TEX.mote, colour = c.palette.core, amount = 18, speed = 3, life = { 0.3, 0.7 },
		size = { 0.08, 0.16 }, gravity = 0.5 })
	F.sound("mcl_tools_shears_cut", { pos = at, gain = 0.6 })
end

minemon.fx.register_move("type:grass", R)
