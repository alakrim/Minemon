-- Fire (type default, M2.1 T-FX-c): every fire move that has no recipe of its own. Ember keeps its own (recipes/
-- ember.lua). Distinct from Ember by shape and size: the shot is a small fire comet (a glow with tongues of flame and
-- embers that rise off it, no fireball body), and the impact is a column of flame that climbs out of the hit, a
-- small blast and a scorch on the ground. Palette (fx_logic.PALETTE): core #fff6c8, main #ff8a24, edge #d23a0c,
-- smoke #3b2b25. Budgets: docs/ART_GUIDE.md 4. Totals at "high": cast ~35, launch ~35, projectile ~40/s, impact ~60.
-- luacheck: read_globals core vector minemon

local R = {}

local ZERO = { x = 0, y = 0, z = 0 }

-- Cast: embers are drawn into the mouth, a few tongues of flame lick up from it and a glow swells.
function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.inhale({ pos = at, tex = F.TEX.ember, radius = 0.9, amount = 14, time = t, size = { 0.08, 0.12 } })
	F.flames({ pos = at, amount = 8, size = { 0.18, 0.28 }, life = { 0.25, 0.4 }, spread = 0.06, rise = 0.9, time = t })
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t + 0.05, size = 0.6,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add", grow = { 0.2, 0.9 }, alpha = 0.8 }),
		glow = 14,
	})
	F.sound("fire_fire", { pos = at, gain = 0.3, pitch = 1.4 })
end

-- Launch: a small blast at the muzzle, a flash and a fan of embers thrown along the shot.
function R.launch(F, c)
	F.blast({ pos = c.from, size = 0.6, life = 0.25 })
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.8, life = 0.14 })
	F.emit({
		amount = 14, time = 0.05, pos = c.from,
		vel = { min = vector.add(vector.multiply(c.dir, 3), { x = -0.6, y = 0, z = -0.6 }),
			max = vector.add(vector.multiply(c.dir, 6), { x = 0.6, y = 1.2, z = 0.6 }) },
		acc = { x = 0, y = -5, z = 0 }, exptime = { min = 0.25, max = 0.45 }, size = { min = 0.06, max = 0.1 },
		texture = F.tex(F.TEX.ember, { blend = "add", fade = { 1, 0.6 } }), glow = 14,
	})
	F.sound("mobs_fireball", { pos = c.from, gain = 0.4, pitch = 1.4 })
end

-- The comet: a small glow core with tongues of flame that stay where they were born, and embers that rise off it.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(F.TEX.glow, c.palette.main) }, visual_size = { x = 0.45, y = 0.45 },
		glow = 14 })
	F.on(c.obj, {
		amount = 36, time = 1.5, pos = { min = { x = -0.08, y = -0.08, z = -0.08 }, max = { x = 0.08, y = 0.08, z = 0.08 } },
		vel = { min = { x = -0.1, y = 0.4, z = -0.1 }, max = { x = 0.1, y = 0.9, z = 0.1 } },
		exptime = { min = 0.25, max = 0.4 }, size = { min = 0.25, max = 0.4 },
		texture = F.tex(F.TEX.flame, { blend = "add", anim = "flame", grow = { 1, 0.4 } }), vertical = true, glow = 14,
	})
	F.on(c.obj, {
		amount = 16, time = 1.5, pos = ZERO,
		vel = { min = { x = -0.5, y = 0.2, z = -0.5 }, max = { x = 0.5, y = 0.8, z = 0.5 } },
		acc = { x = 0, y = 1.5, z = 0 }, exptime = { min = 0.5, max = 0.9 }, size = { min = 0.05, max = 0.09 },
		texture = F.tex(F.TEX.ember, { blend = "add", fade = { 1, 0.7 } }), glow = 14,
	})
	F.on(c.obj, {
		amount = 8, time = 1.5, pos = ZERO,
		vel = { min = { x = -0.1, y = 0.3, z = -0.1 }, max = { x = 0.1, y = 0.6, z = 0.1 } },
		exptime = { min = 0.5, max = 0.8 }, size = { min = 0.3, max = 0.45 },
		texture = F.tex(F.tint(F.TEX.smoke, c.palette.smoke), { blend = "alpha", alpha = 0.35, anim = "smoke" }),
	})
	return true
end

-- Beam: a jet of fire along the line with a bright core; a small blast where it lands.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 14
	local dir = vector.multiply(d, 1 / len)
	F.emit({
		amount = 50, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = { min = 0.5, max = 0.7 }, texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add" }),
		glow = 14,
	}, c.from)
	F.emit({
		amount = 40, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = { min = 0.4, max = 0.6 }, vertical = false,
		texture = F.tex(F.TEX.flame, { blend = "add", anim = "flame" }), glow = 14,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9 })
	F.blast({ pos = c.to, size = 0.8, life = 0.35 })
end

-- Melee: five tongues of flame swept in front of the user.
function R.melee(F, c)
	for i = -2, 2 do
		local bulge = 0.45 - 0.08 * math.abs(i)
		local p = vector.add(c.centre, { x = c.fwd.x * bulge, y = i * 0.22, z = c.fwd.z * bulge })
		F.flames({ pos = p, amount = 5, size = { 0.3, 0.45 }, life = { 0.25, 0.4 }, spread = 0.1, rise = 0.3,
			time = 0.12 })
	end
end

-- Area: a fire eruption. A blast in the middle, a ring, embers thrown wide and smoke that rises, and a scorch on the
-- ground the size of the area.
function R.area(F, c)
	local r = c.radius or 3
	F.blast({ pos = c.centre, size = 1.4, life = 0.5, amount = 2, spread = 0.4 })
	F.ring({ pos = c.centre, colour = c.palette.main, size = 0.5, grow = r * 2 / 0.5, life = 0.45 })
	F.embers({ pos = c.centre, amount = 30, speed = r * 0.7, up = 3, radius = 0.4 })
	F.smoke({ pos = c.centre, colour = c.palette.smoke, amount = 8, size = { 0.8, 1.2 }, life = { 1.2, 1.8 },
		alpha = 0.6, rise = 0.8, spread = 0.8 })
	F.decal({ pos = c.centre, tex = F.TEX.scorch, size = r * 0.9, life = 8 })
	F.sound("fire_fire", { pos = c.centre, gain = 0.7, pitch = 0.9 })
end

-- Impact: a flash, one blast, a column of flame that climbs out of the hit, embers, a ring, smoke, flames on the
-- victim for half a second and a scorch on the ground that fades over 7 s.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = "#ffffff", size = 1.2, life = 0.12 })
	F.blast({ pos = at, size = 1.1, life = 0.4 })
	F.flames({ pos = at, amount = 16, size = { 0.35, 0.55 }, life = { 0.4, 0.7 }, spread = 0.25, rise = 2.2,
		time = 0.15 })
	F.embers({ pos = at, amount = 20, speed = 3.5, up = 3.5, size = { 0.08, 0.14 } })
	F.ring({ pos = at, colour = c.palette.main, size = 0.4, grow = 2.8, life = 0.3 })
	F.smoke({ pos = vector.add(at, { x = 0, y = 0.3, z = 0 }), colour = c.palette.smoke, amount = 6,
		size = { 0.5, 0.8 }, life = { 1.0, 1.5 }, rise = 1.0, time = 0.3 })
	if c.victim and c.victim:get_pos() then
		F.on(c.victim, {
			amount = 8, time = 0.5,
			pos = { min = { x = -0.25, y = 0.1, z = -0.25 }, max = { x = 0.25, y = 0.6, z = 0.25 } },
			vel = { min = { x = 0, y = 0.6, z = 0 }, max = { x = 0, y = 1.2, z = 0 } },
			exptime = { min = 0.3, max = 0.45 }, size = { min = 0.3, max = 0.45 },
			texture = F.tex(F.TEX.flame, { blend = "add", anim = "flame" }), vertical = true, glow = 14,
		})
	end
	F.decal({ pos = at, tex = F.TEX.scorch, size = 1.1, life = 7 })
	F.sound("fire_fire", { pos = at, gain = 0.6, pitch = 1.2 })
end

minemon.fx.register_move("type:fire", R)
