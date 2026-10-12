-- The default recipe (M2.1): every phase, tinted by the move's type palette (fx_logic.PALETTE). Any move without a
-- recipe of its own (and any type without a "type:<name>" recipe) looks like this. Budget: docs/ART_GUIDE.md.
-- luacheck: read_globals core vector minemon

local R = {}

local function mouth(F, c)
	return F.anchor(c.user, "mouth", 0.75, 0.6) or c.from
end

-- Wind-up: motes of the type's colour gather at the mouth while a glow swells there.
function R.cast(F, c)
	local at = mouth(F, c)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.inhale({ pos = at, colour = c.palette.main, radius = 0.9, amount = 22, time = t })
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = { x = 0, y = 0, z = 0 }, exptime = t, size = 0.66,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add", grow = { 0.2, 1.0 }, alpha = 0.8 }),
		glow = 14,
	})
end

-- Launch: a flash at the muzzle and a spray of sparks along the shot.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9 })
	F.emit({
		amount = 10, time = 0.05, pos = c.from,
		vel = { min = vector.multiply(c.dir, 2), max = vector.add(vector.multiply(c.dir, 6), { x = 0, y = 1, z = 0 }) },
		exptime = { min = 0.15, max = 0.35 }, size = { min = 0.18, max = 0.36 },
		texture = F.tex(F.tint(F.TEX.spark, c.palette.main), { blend = "add", fade = true }),
		glow = 14,
	})
end

-- The orb: a glowing core of the type's colour and a trail that shrinks behind it. Returns true: decorated.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(F.TEX.glow, c.palette.main) }, visual_size = { x = 0.6, y = 0.6 } })
	F.on(c.obj, {
		amount = 50, time = 1.5, pos = { min = { x = -0.05, y = -0.05, z = -0.05 }, max = { x = 0.05, y = 0.05, z = 0.05 } },
		vel = { x = 0, y = 0, z = 0 }, exptime = { min = 0.2, max = 0.35 }, size = { min = 0.36, max = 0.54 },
		texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add", fade = true, grow = { 1, 0.2 } }),
		glow = 14,
	})
	F.on(c.obj, {
		amount = 18, time = 1.5, pos = { x = 0, y = 0, z = 0 },
		vel = { min = { x = -0.6, y = -0.6, z = -0.6 }, max = { x = 0.6, y = 0.6, z = 0.6 } },
		exptime = { min = 0.3, max = 0.6 }, size = { min = 0.15, max = 0.27 },
		texture = F.tex(F.tint(F.TEX.spark, c.palette.core), { blend = "add", fade = true }),
		glow = 14,
	})
	return true
end

-- Beam: a stream of light from the user to the stop point, with a hot core and sparks at both ends.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 40
	local dir = vector.multiply(d, 1 / len)
	for _, layer in ipairs({ { tex = F.TEX.glow, col = c.palette.main, size = { 0.48, 0.66 }, n = 70 },
			{ tex = F.TEX.glow, col = c.palette.core, size = { 0.18, 0.27 }, n = 50 } }) do
		F.emit({
			amount = layer.n, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed),
			exptime = len / speed, size = { min = layer.size[1], max = layer.size[2] },
			texture = F.tex(F.tint(layer.tex, layer.col), { blend = "add" }), glow = 14,
		}, c.from)
	end
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9 })
	F.flare({ pos = c.to, colour = c.palette.core, size = 1.2, life = 0.4 })
	F.burst({ pos = c.to, colour = c.palette.main, amount = 16, speed = 4, life = { 0.2, 0.5 } })
end

-- Melee: a bright arc swept in front of the user (five points of a crescent, each a short spray).
function R.melee(F, c)
	for i = -2, 2 do
		local bulge = 0.45 - 0.08 * math.abs(i)
		local p = vector.add(c.centre, { x = c.fwd.x * bulge, y = i * 0.22, z = c.fwd.z * bulge })
		F.emit({
			amount = 6, time = 0.12, pos = p,
			vel = { min = vector.multiply(c.fwd, 1.5), max = vector.multiply(c.fwd, 3) },
			exptime = { min = 0.12, max = 0.25 }, size = { min = 0.42, max = 0.6 },
			texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add", fade = true, grow = { 1, 0.4 } }),
			glow = 14,
		})
	end
end

-- Area: a ground shockwave, dust, and a flash at the centre.
function R.area(F, c)
	F.flare({ pos = c.centre, colour = c.palette.core, size = 1.5, life = 0.25 })
	F.ring({ pos = c.centre, colour = c.palette.main, size = 0.6, grow = c.radius * 1.5, life = 0.45 })
	F.burst({ pos = c.centre, colour = c.palette.main, amount = 40, speed = c.radius * 2.2, radius = 0.3,
		life = { 0.3, 0.6 }, size = { 0.3, 0.54 } })
	F.burst({ pos = c.centre, tex = F.TEX.dust, colour = c.palette.smoke, blend = "alpha", amount = 16,
		speed = c.radius, life = { 0.6, 1.0 }, size = { 0.6, 0.9 }, gravity = -0.5, glow = 0 })
end

-- Aura: motes rise around the user in a column, with a soft pulse of light.
function R.aura(F, c)
	F.emit({
		amount = 40, time = 0.6, pos = c.centre, radius = { min = 0.5, max = 0.8, bias = 0 },
		vel = { min = { x = 0, y = 0.8, z = 0 }, max = { x = 0, y = 1.8, z = 0 } },
		exptime = { min = 0.5, max = 0.9 }, size = { min = 0.18, max = 0.33 },
		texture = F.tex(F.tint(F.TEX.mote, c.palette.main), { blend = "add", fade = true }), glow = 14,
	})
	F.ring({ pos = c.centre, colour = c.palette.main, size = 0.45, grow = 2.5, life = 0.5 })
end

-- Cloud: a lingering, slowly churning cloud of the type's smoke colour.
function R.cloud(F, c)
	local r = c.radius * 0.6
	F.emit({
		amount = 60, time = c.time or 3,
		pos = { min = vector.subtract(c.centre, { x = r, y = 0.1, z = r }),
			max = vector.add(c.centre, { x = r, y = 0.6, z = r }) },
		vel = { min = { x = -0.15, y = 0.05, z = -0.15 }, max = { x = 0.15, y = 0.25, z = 0.15 } },
		exptime = { min = 1.2, max = 2.0 }, size = { min = 0.9, max = 1.5 },
		texture = F.tex(F.tint(F.TEX.smoke, c.palette.main), { blend = "alpha", alpha = 0.55, anim = "smoke" }),
	})
	F.emit({
		amount = 30, time = c.time or 3,
		pos = { min = vector.subtract(c.centre, { x = r, y = 0, z = r }),
			max = vector.add(c.centre, { x = r, y = 0.8, z = r }) },
		vel = { min = { x = -0.1, y = 0.1, z = -0.1 }, max = { x = 0.1, y = 0.3, z = 0.1 } },
		exptime = { min = 0.8, max = 1.4 }, size = { min = 0.15, max = 0.27 },
		texture = F.tex(F.tint(F.TEX.mote, c.palette.core), { blend = "add", fade = { 0, 1 } }), glow = 10,
	})
end

-- Impact: a flash, a spray of sparks of the type's colour, a ring and a little smoke.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.05 })
	F.burst({ pos = at, colour = c.palette.main, amount = 22, speed = 4, life = { 0.25, 0.55 }, gravity = 4 })
	F.ring({ pos = at, colour = c.palette.edge, size = 0.3, grow = 2.5, life = 0.3 })
	F.smoke({ pos = at, colour = c.palette.smoke, amount = 4, size = { 0.36, 0.6 }, life = { 0.6, 0.9 }, alpha = 0.5 })
end

minemon.fx.register_move("default", R)
