-- Dragon (type default, M2.1 T-FX-c): indigo-violet energy with gold sparks, and a roaring shock ring on every hit.
-- Silhouette: a hard bright core in a violet halo that throws gold crackles. Palette (fx_logic.PALETTE): core
-- #f0ecff, main #8a6aff, edge #3a2ac0, smoke #40305a. Gold sparks: #ffd040. Budgets: docs/ART_GUIDE.md 4.
-- Totals at "high": cast ~45, launch ~40, projectile ~40/s, impact ~100.
-- luacheck: read_globals core vector minemon

local R = {}

local ZERO = { x = 0, y = 0, z = 0 }
local GOLD = "#ffd040"

local function gold(F)
	return F.tex(F.tint(F.TEX.spark, GOLD), { blend = "add", fade = true })
end

-- Cast: indigo motes are drawn into the mouth, a violet glow swells there and gold crackles jump around it.
function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.5)
	F.inhale({ pos = at, colour = c.palette.main, radius = 1.0, amount = 20, time = t, size = { 0.1, 0.16 } })
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t + 0.05, size = 0.8,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add", grow = { 0.2, 1.1 }, alpha = 0.8 }),
		glow = 14,
	})
	F.emit({
		amount = 10, time = t, pos = at, radius = { min = 0.3, max = 0.6, bias = 0 },
		vel = { min = { x = -0.5, y = -0.5, z = -0.5 }, max = { x = 0.5, y = 0.5, z = 0.5 } },
		exptime = { min = 0.15, max = 0.3 }, size = { min = 0.06, max = 0.1 }, texture = gold(F), glow = 14,
	})
	F.sound("mobs_mc_ender_dragon_attack", { pos = at, gain = 0.25, pitch = 1.8 })
end

-- Launch: a violet flash and a shock ring at the muzzle, and a fan of gold sparks along the shot.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 1.0, life = 0.15 })
	F.ring({ pos = c.from, colour = c.palette.main, size = 0.4, grow = 3.0, life = 0.3 })
	F.emit({
		amount = 14, time = 0.05, pos = c.from,
		vel = { min = vector.add(vector.multiply(c.dir, 3), { x = -0.5, y = 0, z = -0.5 }),
			max = vector.add(vector.multiply(c.dir, 7), { x = 0.5, y = 1, z = 0.5 }) },
		exptime = { min = 0.2, max = 0.4 }, size = { min = 0.08, max = 0.13 }, texture = gold(F), glow = 14,
	})
	F.sound("mobs_mc_ender_dragon_shoot", { pos = c.from, gain = 0.6, pitch = 1.1 })
end

-- The orb: an indigo core in a violet halo, a trail of glow, gold crackles and a shock ring left every third of a
-- second. Returns true: decorated.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(F.TEX.glow, c.palette.main) }, visual_size = { x = 0.7, y = 0.7 },
		glow = 14 })
	F.on(c.obj, {
		amount = 40, time = 1.5, pos = { min = { x = -0.06, y = -0.06, z = -0.06 }, max = { x = 0.06, y = 0.06, z = 0.06 } },
		vel = ZERO, exptime = { min = 0.2, max = 0.35 }, size = { min = 0.3, max = 0.45 },
		texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add", fade = true, grow = { 1, 0.3 } }),
		glow = 14,
	})
	F.on(c.obj, {
		amount = 18, time = 1.5, pos = { min = { x = -0.35, y = -0.35, z = -0.35 }, max = { x = 0.35, y = 0.35, z = 0.35 } },
		vel = { min = { x = -0.6, y = -0.6, z = -0.6 }, max = { x = 0.6, y = 0.6, z = 0.6 } },
		exptime = { min = 0.2, max = 0.4 }, size = { min = 0.07, max = 0.12 }, texture = gold(F), glow = 14,
	})
	F.on(c.obj, {
		amount = 4, time = 1.5, pos = ZERO, vel = ZERO, exptime = { min = 0.25, max = 0.35 },
		size = { min = 0.45, max = 0.6 },
		texture = F.tex(F.tint(F.TEX.ring, c.palette.main), { blend = "add", fade = true, grow = { 0.5, 1.6 } }),
		glow = 14,
	})
	return true
end

-- Beam: a violet beam with a white core, gold sparks racing along it, and a shock ring where it lands.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 40
	local dir = vector.multiply(d, 1 / len)
	F.emit({
		amount = 60, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = { min = 0.48, max = 0.66 }, texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add" }),
		glow = 14,
	}, c.from)
	F.emit({
		amount = 40, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = { min = 0.18, max = 0.27 }, texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add" }),
		glow = 14,
	}, c.from)
	F.emit({
		amount = 30, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed * 0.8), exptime = len / (speed * 0.8),
		size = { min = 0.1, max = 0.16 }, texture = gold(F), glow = 14,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9 })
	F.flare({ pos = c.to, colour = c.palette.core, size = 1.2, life = 0.4 })
	F.ring({ pos = c.to, colour = c.palette.main, size = 0.5, grow = 3.0, life = 0.35 })
	F.burst({ pos = c.to, tex = F.TEX.spark, colour = GOLD, amount = 14, speed = 4, life = { 0.2, 0.5 } })
end

-- Melee: five shock rings swept in front of the user, each with a spray of gold.
function R.melee(F, c)
	for i = -2, 2 do
		local bulge = 0.45 - 0.08 * math.abs(i)
		local p = vector.add(c.centre, { x = c.fwd.x * bulge, y = i * 0.22, z = c.fwd.z * bulge })
		F.ring({ pos = p, colour = c.palette.main, size = 0.35, grow = 2.2, life = 0.25 })
		F.emit({
			amount = 4, time = 0.1, pos = p, vel = vector.multiply(c.fwd, 3), exptime = { min = 0.15, max = 0.3 },
			size = { min = 0.08, max = 0.13 }, texture = gold(F), glow = 14,
		})
	end
end

-- Area: a roar. A shock ring runs out to the edge, gold sparks fall back down and a dark violet cloud rises.
function R.area(F, c)
	local r = c.radius or 3
	F.flare({ pos = c.centre, colour = c.palette.core, size = 1.4, life = 0.2 })
	F.ring({ pos = c.centre, colour = c.palette.main, size = 0.6, grow = r * 2 / 0.6, life = 0.5 })
	core.after(0.12, function()
		F.ring({ pos = c.centre, colour = c.palette.edge, size = 0.6, grow = r * 2 / 0.6, life = 0.6 })
	end)
	F.burst({ pos = c.centre, tex = F.TEX.spark, colour = GOLD, amount = 30, speed = r * 1.5, radius = 0.3,
		life = { 0.5, 0.9 }, size = { 0.07, 0.12 }, gravity = 6, collide = true, bounce = 0.3 })
	F.smoke({ pos = c.centre, colour = c.palette.smoke, amount = 6, size = { 0.8, 1.2 }, life = { 1.2, 1.8 },
		alpha = 0.5, rise = 0.6, spread = 0.8 })
	F.sound("mobs_mc_ender_dragon_attack", { pos = c.centre, gain = 0.7, pitch = 1.0 })
end

-- Impact: a flash, two shock rings in turn, an indigo burst, gold sparks that fall and bounce, a violet mark on the
-- victim and a magic circle on the ground for 5 s.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.4, life = 0.14 })
	F.ring({ pos = at, colour = c.palette.core, size = 0.4, grow = 4.0, life = 0.4 })
	core.after(0.07, function()
		F.ring({ pos = at, colour = c.palette.main, size = 0.4, grow = 4.8, life = 0.45 })
	end)
	F.burst({ pos = at, tex = F.TEX.glow, colour = c.palette.main, amount = 22, speed = 4, life = { 0.3, 0.6 },
		size = { 0.18, 0.3 } })
	F.burst({ pos = at, tex = F.TEX.spark, colour = GOLD, amount = 26, speed = 5, life = { 0.3, 0.6 },
		size = { 0.07, 0.12 }, gravity = 6, collide = true, bounce = 0.3 })
	F.smoke({ pos = at, colour = c.palette.smoke, amount = 6, size = { 0.5, 0.8 }, life = { 0.8, 1.2 }, alpha = 0.5,
		rise = 0.6 })
	if c.victim and c.victim:get_pos() then
		F.on(c.victim, {
			amount = 14, time = 0.6, pos = { min = { x = -0.3, y = 0.2, z = -0.3 }, max = { x = 0.3, y = 1.0, z = 0.3 } },
			vel = { min = { x = -0.5, y = -0.5, z = -0.5 }, max = { x = 0.5, y = 0.5, z = 0.5 } },
			exptime = { min = 0.3, max = 0.5 }, size = { min = 0.08, max = 0.12 }, texture = gold(F), glow = 14,
		})
		F.on(c.victim, {
			amount = 8, time = 0.6, pos = { min = { x = -0.25, y = 0.2, z = -0.25 }, max = { x = 0.25, y = 1.0, z = 0.25 } },
			vel = { min = { x = 0, y = 0.2, z = 0 }, max = { x = 0, y = 0.6, z = 0 } },
			exptime = { min = 0.3, max = 0.5 }, size = { min = 0.3, max = 0.45 },
			texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add", fade = true }), glow = 14,
		})
	end
	F.decal({ pos = at, tex = F.tint(F.TEX.ring, c.palette.edge), size = 2.4, life = 5 })
	F.sound("mobs_mc_ender_dragon_attack", { pos = at, gain = 0.9, pitch = 1.2 })
end

minemon.fx.register_move("type:dragon", R)
