-- Rock type (M2.1, T-FX-b): every rock move without a recipe of its own. Heavy chunks that spin, fall under gravity
-- and bounce, and real stone blocks (cobble) that chip off where they land. Five beats: loose stones are drawn into the
-- mouth; chips fly from the muzzle; the projectile is a heavy spinning rock with dust and falling chips behind it; the
-- impact throws chunks and stone with a heavy thud and a cloud of dust; the aftermath is the default cloud and aura.
-- Budget (docs/ART_GUIDE.md): cast 80, launch 60, projectile 90/s, impact 160, area 200, beam 160.
-- luacheck: read_globals core vector minemon

local R = {}

local CHUNK = "minemon_fx_chunk_spin_anim.png" -- 4 frames of 16 px: a rough chunk, spinning
local CRATER = "minemon_fx_crater.png" -- a crater decal, tinted for the stone
local COBBLE = { name = "mcl_core:cobble" } -- real blocks: node particles take their texture from the node
local ZERO = { x = 0, y = 0, z = 0 }

-- A spinning chunk particle, tinted with the type's main colour.
local function chunk(F, colour, o)
	local t = F.tex(F.tint(CHUNK, colour), o)
	t.animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = -1 }
	return t
end

-- Chunks thrown radially out of pos, heavy: gravity, bounce and collisions with the ground. o: amount, speed, life,
-- size, texture, time, gravity, collide.
local function spray(F, pos, o)
	local speed = o.speed or 4
	return F.emit({
		amount = o.amount, time = o.time or 0.05, pos = pos, radius = { min = 0.1, max = 0.25, bias = 0 },
		attract = { kind = "point", origin = pos, strength = { min = -speed / 0.25 * 0.6, max = -speed / 0.25 },
			die_on_contact = false },
		vel = ZERO, acc = { x = 0, y = -(o.gravity or 12), z = 0 },
		exptime = { min = o.life[1], max = o.life[2] }, size = { min = o.size[1], max = o.size[2] },
		collisiondetection = o.collide ~= false, bounce = { min = 0.2, max = 0.4 },
		texture = o.texture, glow = 0,
	})
end

-- Stone blocks (cobble) thrown from pos: node particles that fall, bounce and land.
local function stones(F, pos, o)
	return F.emit({
		amount = o.amount, time = o.time or 0.05, pos = pos, radius = o.radius or { min = 0.1, max = 0.3, bias = 0 },
		vel = o.vel or ZERO, acc = { x = 0, y = -(o.gravity or 14), z = 0 },
		exptime = { min = o.life[1], max = o.life[2] }, size = { min = o.size[1], max = o.size[2] },
		collisiondetection = true, bounce = { min = 0.2, max = 0.4 }, node = COBBLE, glow = 0,
	})
end

-- Wind-up: loose chunks are drawn into the mouth and a faint glow swells there.
function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.emit({
		amount = 12, time = t, pos = at, radius = { min = 0.8, max = 1.3, bias = 0 },
		attract = { kind = "point", origin = at, strength = { min = 2.5, max = 3.5 }, die_on_contact = true },
		vel = ZERO, exptime = { min = 0.3, max = 0.5 }, size = { min = 0.14, max = 0.22 },
		texture = chunk(F, c.palette.edge, { blend = "alpha", fade = { 1, 0.7 } }), glow = 0,
	})
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t + 0.05, size = 0.7,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add", grow = { 0.2, 1.0 }, alpha = 0.4 }),
		glow = 6,
	})
	F.sound("default_gravel_dig", { pos = at, gain = 0.4, pitch = 1.4 })
end

-- Launch: heavy chunks and stone chips flung from the muzzle; a flash and a dull knock.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.8, life = 0.14 })
	spray(F, c.from, { amount = 10, speed = 5, life = { 0.4, 0.7 }, size = { 0.2, 0.3 }, gravity = 12,
		texture = chunk(F, c.palette.edge, { blend = "alpha", fade = { 1, 0.6 } }) })
	stones(F, c.from, { amount = 6, time = 0.05, life = { 0.5, 0.9 }, size = { 0.12, 0.2 }, gravity = 14,
		vel = { min = vector.multiply(c.dir, 3), max = vector.multiply(c.dir, 5) } })
	F.sound("default_place_node_hard", { pos = c.from, gain = 0.6, pitch = 0.8 })
end

-- The orb: a heavy spinning rock; dust and chips fall from it. Returns true: decorated.
function R.projectile(F, c)
	local obj = c.obj
	obj:set_properties({ textures = { F.tint(CHUNK, c.palette.main) }, spritediv = { x = 1, y = 4 },
		visual_size = { x = 0.8, y = 0.8 } })
	obj:set_sprite({ x = 0, y = 0 }, 4, 0.1, false)
	F.on(obj, {
		amount = 16, time = 1.5, pos = { min = { x = -0.12, y = -0.12, z = -0.12 }, max = { x = 0.12, y = 0.12, z = 0.12 } },
		vel = { min = { x = -0.3, y = -0.1, z = -0.3 }, max = { x = 0.3, y = 0.3, z = 0.3 } },
		exptime = { min = 0.5, max = 0.8 }, size = { min = 0.4, max = 0.6 },
		texture = F.tex(F.tint(F.TEX.dust, c.palette.smoke), { blend = "alpha", alpha = 0.5, grow = { 0.6, 1.3 } }),
		glow = 0,
	})
	F.on(obj, {
		amount = 14, time = 1.5, pos = { x = 0, y = 0, z = 0 },
		vel = { min = { x = -0.4, y = 0, z = -0.4 }, max = { x = 0.4, y = 0.4, z = 0.4 } },
		acc = { x = 0, y = -14, z = 0 }, collisiondetection = true, bounce = { min = 0.2, max = 0.4 },
		exptime = { min = 0.4, max = 0.8 }, size = { min = 0.15, max = 0.22 },
		texture = chunk(F, c.palette.edge, { blend = "alpha", fade = { 1, 0.7 } }), glow = 0,
	})
	return true
end

-- Beam: one heavy rock flies along the line, chips and dust behind it, and a burst of stone where it lands.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 24
	local dir = vector.multiply(d, 1 / len)
	F.emit({
		amount = 1, time = 0.02, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = { min = 0.9, max = 0.9 }, texture = chunk(F, c.palette.edge, { blend = "alpha" }), glow = 0,
	}, c.from)
	F.emit({
		amount = 20, time = 0.3, pos = c.from, vel = vector.multiply(dir, speed * 0.5),
		exptime = { min = 0.5, max = 0.9 }, size = { min = 0.5, max = 0.8 },
		texture = F.tex(F.tint(F.TEX.dust, c.palette.smoke), { blend = "alpha", alpha = 0.6, grow = { 0.6, 1.3 } }),
		glow = 0,
	}, c.from)
	stones(F, c.from, { amount = 10, time = 0.3, vel = vector.multiply(dir, speed * 0.6), gravity = 12,
		life = { 0.4, 0.7 }, size = { 0.12, 0.2 } })
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.8 })
	F.burst({ pos = c.to, tex = F.TEX.dust, colour = c.palette.smoke, blend = "alpha", amount = 16, speed = 3,
		life = { 0.6, 1.0 }, size = { 0.5, 0.8 }, gravity = -0.4, glow = 0 })
	stones(F, c.to, { amount = 10, time = 0.05, life = { 0.5, 0.9 }, size = { 0.12, 0.2 }, gravity = 14,
		vel = { min = { x = -2, y = 1.5, z = -2 }, max = { x = 2, y = 3.5, z = 2 } } })
	F.sound("default_place_node_hard", { pos = c.to, gain = 0.8, pitch = 0.7 })
end

-- Melee: a swipe of chunks thrown forward in an arc, and a cloud of dust at the arc's heart.
function R.melee(F, c)
	for i = -2, 2 do
		local bulge = 0.45 - 0.08 * math.abs(i)
		local p = vector.add(c.centre, { x = c.fwd.x * bulge, y = i * 0.22, z = c.fwd.z * bulge })
		F.emit({
			amount = 4, time = 0.1, pos = p, vel = { min = vector.multiply(c.fwd, 2), max = vector.multiply(c.fwd, 3.5) },
			acc = { x = 0, y = -10, z = 0 }, exptime = { min = 0.25, max = 0.4 }, size = { min = 0.22, max = 0.32 },
			texture = chunk(F, c.palette.edge, { blend = "alpha", fade = { 1, 0.6 } }), glow = 0,
		})
	end
	F.emit({
		amount = 10, time = 0.12, pos = c.centre, radius = { min = 0.2, max = 0.5, bias = 0 }, vel = ZERO,
		exptime = { min = 0.5, max = 0.8 }, size = { min = 0.5, max = 0.8 },
		texture = F.tex(F.tint(F.TEX.dust, c.palette.smoke), { blend = "alpha", alpha = 0.6, grow = { 0.6, 1.3 } }),
		glow = 0,
	})
end

-- Area: boulders fall from above onto the target; they land with a crash that throws stone and dust, and the ground
-- keeps a crater.
function R.area(F, c)
	local r = c.radius
	local ctr = c.centre
	F.emit({
		amount = 18, time = 0.25,
		pos = { min = vector.add(ctr, { x = -r * 0.6, y = 3.2, z = -r * 0.6 }),
			max = vector.add(ctr, { x = r * 0.6, y = 3.8, z = r * 0.6 }) },
		vel = { min = { x = -0.2, y = -1, z = -0.2 }, max = { x = 0.2, y = -0.5, z = 0.2 } },
		acc = { x = 0, y = -16, z = 0 }, exptime = { min = 0.7, max = 0.9 }, size = { min = 0.35, max = 0.5 },
		texture = chunk(F, c.palette.edge, { blend = "alpha" }), collisiondetection = true,
		bounce = { min = 0.2, max = 0.35 }, glow = 0,
	})
	core.after(0.6, function()
		F.flare({ pos = ctr, colour = c.palette.core, size = 1.4, life = 0.15 })
		F.burst({ pos = ctr, tex = F.TEX.dust, colour = c.palette.smoke, blend = "alpha", amount = 30,
			speed = r * 1.2, radius = 0.4, life = { 0.8, 1.4 }, size = { 0.7, 1.1 }, gravity = -0.4, glow = 0 })
		stones(F, ctr, { amount = 36, time = 0.1, radius = { min = 0.2, max = 0.5, bias = 0 },
			vel = { min = { x = -r * 0.7, y = 2, z = -r * 0.7 }, max = { x = r * 0.7, y = 4.5, z = r * 0.7 } },
			gravity = 14, life = { 0.8, 1.4 }, size = { 0.2, 0.35 } })
		F.decal({ pos = ctr, tex = F.tint(CRATER, c.palette.edge), size = r * 1.4, life = 7 })
		F.sound("default_place_node_hard", { pos = ctr, gain = 1.0, pitch = 0.6 })
	end)
end

-- Impact: a flash, chunks and stone chips thrown out and bounced, a cloud of dust, and a heavy thud.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = "#ffffff", size = 1.0, life = 0.12 })
	spray(F, at, { amount = 14, speed = 4, life = { 0.5, 0.9 }, size = { 0.2, 0.3 }, gravity = 12,
		texture = chunk(F, c.palette.edge, { blend = "alpha", fade = { 1, 0.6 } }) })
	stones(F, at, { amount = 10, time = 0.05, radius = { min = 0.1, max = 0.3, bias = 0 }, life = { 0.5, 0.9 },
		size = { 0.14, 0.22 }, gravity = 14, vel = { min = { x = -2.5, y = 1.5, z = -2.5 },
			max = { x = 2.5, y = 3.5, z = 2.5 } } })
	F.emit({
		amount = 12, time = 0.1, pos = at, radius = { min = 0.2, max = 0.4, bias = 0 },
		vel = { min = { x = -0.3, y = 0.4, z = -0.3 }, max = { x = 0.3, y = 1.0, z = 0.3 } },
		exptime = { min = 0.6, max = 1.0 }, size = { min = 0.5, max = 0.8 },
		texture = F.tex(F.tint(F.TEX.dust, c.palette.smoke), { blend = "alpha", alpha = 0.6, grow = { 0.6, 1.3 } }),
		glow = 0,
	})
	F.ring({ pos = at, colour = c.palette.edge, size = 0.3, grow = 2.4, life = 0.3 })
	F.sound("default_dig_cracky", { pos = at, gain = 0.9, pitch = 0.8 })
end

minemon.fx.register_move("type:rock", R)
