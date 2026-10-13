-- Ground type (M2.1, T-FX-b): every ground move without a recipe of its own. Real blocks of dirt fly up and fall with
-- gravity and bounce (node particles), dust rolls along the ground, and a crater mark stays where it lands. Five beats:
-- dirt and dust rise from the ground round the user while a glow swells at the mouth; a burst of dirt leaves the
-- muzzle; the projectile is a spinning rock with a dust trail and falling dirt; the impact throws dirt and dust and
-- leaves a small crater; the aftermath is the default cloud and aura. Budget (docs/ART_GUIDE.md): cast 80, launch 60,
-- projectile 90/s, impact 160, area 200, beam 160.
-- luacheck: read_globals core vector minemon

local R = {}

local CHUNK = "minemon_fx_chunk_spin_anim.png" -- 4 frames of 16 px: a rough chunk, spinning
local CRATER = "minemon_fx_crater.png" -- an impact crater decal: dark floor, cracks, a lit rim
local DIRT = { name = "mcl_core:dirt" } -- real blocks: node particles take their texture from the node
local ZERO = { x = 0, y = 0, z = 0 }

local function dust(F, colour, o)
	return F.tex(F.tint(F.TEX.dust, colour), o)
end

-- Dirt blocks thrown from pos: they rise, fall under gravity and bounce on the ground.
local function dirt(F, pos, o)
	return F.emit({
		amount = o.amount, time = o.time or 0.05, pos = pos, radius = o.radius, vel = o.vel,
		acc = { x = 0, y = -(o.gravity or 14), z = 0 }, exptime = { min = o.life[1], max = o.life[2] },
		size = { min = o.size[1], max = o.size[2] }, collisiondetection = true, bounce = { min = 0.2, max = 0.4 },
		node = DIRT, glow = 0,
	})
end

-- Wind-up: dirt and dust rise from the ground round the user; a glow swells at the mouth.
function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	local feet = c.user:get_pos()
	if not at or not feet then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	dirt(F, { min = vector.subtract(feet, { x = 0.6, y = 0, z = 0.6 }),
		max = vector.add(feet, { x = 0.6, y = 0.1, z = 0.6 }) }, { amount = 10, time = t,
		vel = { min = { x = -0.2, y = 1.0, z = -0.2 }, max = { x = 0.2, y = 2.0, z = 0.2 } }, gravity = 9,
		life = { 0.4, 0.7 }, size = { 0.12, 0.2 } })
	F.emit({
		amount = 8, time = t, pos = { min = vector.subtract(feet, { x = 0.7, y = 0, z = 0.7 }),
			max = vector.add(feet, { x = 0.7, y = 0.2, z = 0.7 }) },
		vel = { min = { x = -0.1, y = 0.4, z = -0.1 }, max = { x = 0.1, y = 0.8, z = 0.1 } },
		exptime = { min = 0.6, max = 1.0 }, size = { min = 0.5, max = 0.7 },
		texture = dust(F, c.palette.smoke, { blend = "alpha", alpha = 0.6, grow = { 0.6, 1.3 } }), glow = 0,
	})
	F.inhale({ pos = at, tex = F.TEX.dust, colour = c.palette.main, radius = 1.0, amount = 12, time = t,
		size = { 0.12, 0.2 } })
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t + 0.05, size = 0.7,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add", grow = { 0.2, 1.0 }, alpha = 0.5 }),
		glow = 6,
	})
	F.sound("default_dig_crumbly", { pos = at, gain = 0.5, pitch = 0.6 })
end

-- Launch: a burst of dirt blocks from the muzzle and a puff of dust; a flash.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.8, life = 0.14 })
	dirt(F, c.from, { amount = 12, time = 0.05, radius = { min = 0.1, max = 0.3, bias = 0 },
		vel = { min = vector.add(vector.multiply(c.dir, 3), { x = -1, y = 1, z = -1 }),
			max = vector.add(vector.multiply(c.dir, 6), { x = 1, y = 2.5, z = 1 }) },
		gravity = 14, life = { 0.5, 0.9 }, size = { 0.18, 0.28 } })
	F.burst({ pos = c.from, tex = F.TEX.dust, colour = c.palette.smoke, blend = "alpha", amount = 12, speed = 2.5,
		life = { 0.5, 0.9 }, size = { 0.35, 0.55 }, gravity = -0.3, glow = 0 })
	F.sound("default_dig_crumbly", { pos = c.from, gain = 0.7, pitch = 0.8 })
end

-- The orb: a spinning rock with a trail of dust and dirt blocks that fall from it. Returns true: decorated.
function R.projectile(F, c)
	local obj = c.obj
	obj:set_properties({ textures = { F.tint(CHUNK, c.palette.main) }, spritediv = { x = 1, y = 4 },
		visual_size = { x = 0.7, y = 0.7 } })
	obj:set_sprite({ x = 0, y = 0 }, 4, 0.12, false)
	F.on(obj, {
		amount = 26, time = 1.5, pos = { min = { x = -0.15, y = -0.15, z = -0.15 }, max = { x = 0.15, y = 0.15, z = 0.15 } },
		vel = { min = { x = -0.3, y = -0.1, z = -0.3 }, max = { x = 0.3, y = 0.4, z = 0.3 } },
		exptime = { min = 0.6, max = 0.9 }, size = { min = 0.4, max = 0.6 },
		texture = dust(F, c.palette.smoke, { blend = "alpha", alpha = 0.5, grow = { 0.6, 1.3 } }), glow = 0,
	})
	F.on(obj, {
		amount = 6, time = 1.5, pos = { x = 0, y = 0, z = 0 },
		vel = { min = { x = -0.4, y = 0.2, z = -0.4 }, max = { x = 0.4, y = 0.6, z = 0.4 } },
		acc = { x = 0, y = -14, z = 0 }, collisiondetection = true, bounce = { min = 0.2, max = 0.4 },
		exptime = { min = 0.5, max = 0.9 }, size = { min = 0.15, max = 0.2 }, node = DIRT, glow = 0,
	})
	return true
end

-- Beam: dirt blocks thrown along the line under gravity, a rolling dust cloud, and a thump where it lands.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 25
	local dir = vector.multiply(d, 1 / len)
	F.emit({
		amount = 24, time = 0.3, pos = c.from, vel = vector.multiply(dir, speed),
		acc = { x = 0, y = -10, z = 0 }, collisiondetection = true, bounce = { min = 0.2, max = 0.4 },
		exptime = len / speed, size = { min = 0.2, max = 0.3 }, node = DIRT, glow = 0,
	}, c.from)
	F.emit({
		amount = 30, time = 0.3, pos = c.from, vel = vector.multiply(dir, speed * 0.5),
		exptime = { min = 0.6, max = 1.0 }, size = { min = 0.4, max = 0.6 },
		texture = dust(F, c.palette.smoke, { blend = "alpha", alpha = 0.6, grow = { 0.7, 1.3 } }), glow = 0,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.8 })
	F.burst({ pos = c.to, tex = F.TEX.dust, colour = c.palette.smoke, blend = "alpha", amount = 18, speed = 3,
		life = { 0.6, 1.0 }, size = { 0.35, 0.55 }, gravity = -0.5, glow = 0 })
	F.ring({ pos = c.to, colour = c.palette.edge, size = 0.3, grow = 2.2, life = 0.3 })
	F.sound("default_gravel_dig", { pos = c.to, gain = 0.7, pitch = 0.9 })
end

-- Melee: a kick of dust and dirt blocks thrown forward along the ground.
function R.melee(F, c)
	local feet = c.user:get_pos()
	if not feet then
		return
	end
	local ahead = vector.add(feet, vector.multiply(c.fwd, 0.6))
	dirt(F, ahead, { amount = 10, time = 0.12, radius = { min = 0.2, max = 0.5, bias = 0 },
		vel = { min = vector.add(vector.multiply(c.fwd, 2), { x = -0.5, y = 1.5, z = -0.5 }),
			max = vector.add(vector.multiply(c.fwd, 3.5), { x = 0.5, y = 2.5, z = 0.5 }) },
		gravity = 12, life = { 0.5, 0.9 }, size = { 0.15, 0.25 } })
	F.emit({
		amount = 12, time = 0.12, pos = ahead, radius = { min = 0.3, max = 0.6, bias = 0 },
		vel = { min = vector.multiply(c.fwd, 1.5), max = vector.multiply(c.fwd, 3) },
		exptime = { min = 0.5, max = 0.9 }, size = { min = 0.4, max = 0.6 },
		texture = dust(F, c.palette.smoke, { blend = "alpha", alpha = 0.6, grow = { 0.6, 1.3 } }), glow = 0,
	})
end

-- Area: a shockwave through the ground (two rings, the second a beat later), a dust cloud, dirt blocks that rise and
-- bounce, and a crater that stays. The quake of Earthquake and Magnitude.
function R.area(F, c)
	local r = c.radius
	local at = c.centre
	F.ring({ pos = at, colour = c.palette.main, size = 0.8, grow = r * 1.8, life = 0.55 })
	core.after(0.2, function()
		F.ring({ pos = at, colour = c.palette.edge, size = 0.6, grow = r * 2.2, life = 0.6 })
	end)
	F.burst({ pos = at, tex = F.TEX.dust, colour = c.palette.smoke, blend = "alpha", amount = 30, speed = r * 1.2,
		radius = 0.4, life = { 0.8, 1.4 }, size = { 0.45, 0.7 }, gravity = -0.4, glow = 0 })
	dirt(F, at, { amount = 40, time = 0.1, radius = { min = 0.2, max = 0.5, bias = 0 },
		vel = { min = { x = -r * 0.8, y = 2.5, z = -r * 0.8 }, max = { x = r * 0.8, y = 5, z = r * 0.8 } },
		gravity = 14, life = { 0.8, 1.4 }, size = { 0.2, 0.35 } })
	F.decal({ pos = at, tex = F.tint(CRATER, c.palette.edge) .. "^[opacity:170", size = r * 1.5, life = 10 })
	F.sound("default_dig_crumbly", { pos = at, gain = 1.0, pitch = 0.5 })
end

-- Impact: a ring, a puff of dust, dirt blocks that bounce away, and a small crater under the victim.
function R.impact(F, c)
	local at = c.pos
	F.ring({ pos = at, colour = c.palette.main, size = 0.4, grow = 2.8, life = 0.3 })
	F.emit({
		amount = 14, time = 0.1, pos = at, radius = { min = 0.2, max = 0.4, bias = 0 },
		vel = { min = { x = -0.3, y = 0.5, z = -0.3 }, max = { x = 0.3, y = 1.2, z = 0.3 } },
		exptime = { min = 0.6, max = 1.0 }, size = { min = 0.4, max = 0.6 },
		texture = dust(F, c.palette.smoke, { blend = "alpha", alpha = 0.7, grow = { 0.6, 1.4 } }), glow = 0,
	})
	dirt(F, at, { amount = 16, time = 0.05, radius = { min = 0.1, max = 0.3, bias = 0 },
		vel = { min = { x = -2.5, y = 1.5, z = -2.5 }, max = { x = 2.5, y = 4, z = 2.5 } },
		gravity = 14, life = { 0.6, 1.0 }, size = { 0.18, 0.28 } })
	F.decal({ pos = at, tex = F.tint(CRATER, c.palette.edge) .. "^[opacity:170", size = 0.8, life = 5 })
	F.sound("default_dig_crumbly", { pos = at, gain = 0.9, pitch = 0.9 })
end

minemon.fx.register_move("type:ground", R)
