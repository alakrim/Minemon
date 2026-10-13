-- Psychic (type default, M2.1 T-FX-c): a slow hypnotic pulse. Pink rings swell outwards from the cast, the shot
-- leaves a trail of rings and floating runes, and every hit draws a sigil on the ground that stays for a while.
-- Palette (fx_logic.PALETTE): core #fff0fa, main #ff6ab4, edge #c02a8a, smoke #8a5a90. Budgets: docs/ART_GUIDE.md 4.
-- Totals at "high": cast ~40, launch ~30, projectile ~30/s, impact ~60, beam ~120, melee ~40, area ~60.
-- luacheck: read_globals core vector minemon

local R = {}

local ZERO = { x = 0, y = 0, z = 0 }
local RUNE = "minemon_fx_rune.png" -- psychic sigil (tools/gen_fx_textures_c.py)

-- Cast: runes are drawn into the mouth, a glow swells there and two rings pulse out of it.
function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.5)
	F.inhale({ pos = at, tex = RUNE, colour = c.palette.main, radius = 1.0, amount = 16, time = t,
		size = { 0.12, 0.18 } })
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t + 0.05, size = 0.7,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add", grow = { 0.2, 1.1 }, alpha = 0.8 }),
		glow = 14,
	})
	F.ring({ pos = at, colour = c.palette.main, size = 0.2, grow = 1.6, life = t * 0.6 })
	core.after(t * 0.5, function()
		F.ring({ pos = at, colour = c.palette.edge, size = 0.2, grow = 1.6, life = t * 0.5 })
	end)
	F.sound("mcl_enchanting_enchant", { pos = at, gain = 0.45, pitch = 0.9 })
end

-- Launch: a pink flash, a ring at the muzzle and a fan of runes along the shot.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9, life = 0.16 })
	F.ring({ pos = c.from, colour = c.palette.main, size = 0.35, grow = 2.6, life = 0.28 })
	F.emit({
		amount = 12, time = 0.05, pos = c.from,
		vel = { min = vector.multiply(c.dir, 2), max = vector.multiply(c.dir, 4.5) },
		exptime = { min = 0.3, max = 0.5 }, size = { min = 0.12, max = 0.2 },
		texture = F.tex(F.tint(RUNE, c.palette.main), { blend = "add", fade = true }), glow = 14,
	})
	F.sound("mcl_enchanting_enchant", { pos = c.from, gain = 0.5, pitch = 1.5 })
end

-- The orb: a pink glow with a ring left behind every quarter second, runes that drift off it and a white core.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(F.TEX.glow, c.palette.main) }, visual_size = { x = 0.55, y = 0.55 },
		glow = 14 })
	F.on(c.obj, {
		amount = 6, time = 1.5, pos = { min = { x = -0.05, y = -0.05, z = -0.05 }, max = { x = 0.05, y = 0.05, z = 0.05 } },
		vel = ZERO, exptime = { min = 0.3, max = 0.4 }, size = { min = 0.45, max = 0.6 },
		texture = F.tex(F.tint(F.TEX.ring, c.palette.main), { blend = "add", fade = true, grow = { 0.4, 1.8 } }),
		glow = 14,
	})
	F.on(c.obj, {
		amount = 8, time = 1.5, pos = { min = { x = -0.25, y = -0.25, z = -0.25 }, max = { x = 0.25, y = 0.25, z = 0.25 } },
		vel = { min = { x = -0.3, y = 0.1, z = -0.3 }, max = { x = 0.3, y = 0.5, z = 0.3 } },
		exptime = { min = 0.5, max = 0.9 }, size = { min = 0.14, max = 0.22 },
		texture = F.tex(F.tint(RUNE, c.palette.main), { blend = "add", fade = true }), glow = 10,
	})
	F.on(c.obj, {
		amount = 12, time = 1.5, pos = ZERO,
		vel = { min = { x = -0.5, y = -0.5, z = -0.5 }, max = { x = 0.5, y = 0.5, z = 0.5 } },
		exptime = { min = 0.2, max = 0.35 }, size = { min = 0.15, max = 0.25 },
		texture = F.tex(F.tint(F.TEX.spark, c.palette.core), { blend = "add", fade = true }), glow = 14,
	})
	return true
end

-- Beam: a pink stream with a white-hot core, runes drifting along it, and a ring where it lands.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 30
	local dir = vector.multiply(d, 1 / len)
	F.emit({
		amount = 60, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = { min = 0.4, max = 0.56 }, texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add" }),
		glow = 14,
	}, c.from)
	F.emit({
		amount = 40, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = { min = 0.14, max = 0.22 }, texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add" }),
		glow = 14,
	}, c.from)
	F.emit({
		amount = 14, time = 0.5, pos = c.from, vel = vector.multiply(dir, speed * 0.5), exptime = len / (speed * 0.5),
		size = { min = 0.12, max = 0.18 }, texture = F.tex(F.tint(RUNE, c.palette.main), { blend = "add", fade = true }),
		glow = 10,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9 })
	F.flare({ pos = c.to, colour = c.palette.core, size = 1.2, life = 0.4 })
	F.ring({ pos = c.to, colour = c.palette.main, size = 0.5, grow = 2.5, life = 0.3 })
	F.burst({ pos = c.to, tex = RUNE, colour = c.palette.main, amount = 14, speed = 3, life = { 0.4, 0.8 } })
end

-- Melee: five small rings swept in front of the user, each with a short spray of runes.
function R.melee(F, c)
	for i = -2, 2 do
		local bulge = 0.45 - 0.08 * math.abs(i)
		local p = vector.add(c.centre, { x = c.fwd.x * bulge, y = i * 0.22, z = c.fwd.z * bulge })
		F.ring({ pos = p, colour = c.palette.main, size = 0.3, grow = 2.2, life = 0.25 })
		F.emit({
			amount = 4, time = 0.1, pos = p, vel = vector.multiply(c.fwd, 2.5), exptime = { min = 0.15, max = 0.3 },
			size = { min = 0.12, max = 0.18 }, texture = F.tex(F.tint(RUNE, c.palette.main), { blend = "add",
				fade = true }),
			glow = 10,
		})
	end
end

-- Area: a psychic wave. Two rings reach the edge of the area in turn, and runes fly out across it.
function R.area(F, c)
	local r = c.radius or 3
	local at = c.centre
	F.flare({ pos = at, colour = c.palette.core, size = 1.4, life = 0.22 })
	F.ring({ pos = at, colour = c.palette.main, size = 0.8, grow = r * 2 / 0.8, life = 0.5 })
	core.after(0.15, function()
		F.ring({ pos = at, colour = c.palette.edge, size = 0.8, grow = r * 2 / 0.8, life = 0.6 })
	end)
	F.burst({ pos = at, tex = RUNE, colour = c.palette.main, amount = 26, speed = r * 1.2, radius = 0.4,
		life = { 0.6, 1.1 }, size = { 0.14, 0.24 } })
	F.burst({ pos = at, colour = c.palette.main, amount = 20, speed = r * 1.5, radius = 0.3,
		life = { 0.3, 0.6 }, size = { 0.2, 0.32 } })
end

-- Impact: a flash and three rings in turn (a pulse), runes that float up, a pink mark on the victim and a sigil on
-- the ground that fades out over 5 s.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.2, life = 0.14 })
	F.ring({ pos = at, colour = c.palette.core, size = 0.3, grow = 2.6, life = 0.3 })
	core.after(0.12, function()
		F.ring({ pos = at, colour = c.palette.main, size = 0.3, grow = 3.4, life = 0.4 })
	end)
	core.after(0.26, function()
		F.ring({ pos = at, colour = c.palette.edge, size = 0.3, grow = 4.0, life = 0.45 })
	end)
	F.burst({ pos = at, tex = RUNE, colour = c.palette.main, amount = 22, speed = 3.5, life = { 0.5, 0.9 },
		size = { 0.14, 0.22 }, gravity = -0.6 })
	F.smoke({ pos = at, colour = c.palette.smoke, amount = 4, size = { 0.4, 0.6 }, life = { 0.7, 1.0 },
		alpha = 0.4, rise = 0.4 })
	if c.victim and c.victim:get_pos() then
		F.on(c.victim, {
			amount = 14, time = 0.9,
			pos = { min = { x = -0.3, y = 0.2, z = -0.3 }, max = { x = 0.3, y = 1.0, z = 0.3 } },
			vel = { min = { x = -0.05, y = 0.4, z = -0.05 }, max = { x = 0.05, y = 0.8, z = 0.05 } },
			exptime = { min = 0.6, max = 1.0 }, size = { min = 0.14, max = 0.22 },
			texture = F.tex(F.tint(RUNE, c.palette.main), { blend = "add", fade = true }), glow = 10,
		})
	end
	F.decal({ pos = at, tex = F.tint(RUNE, c.palette.main), size = 2.0, life = 5 })
	F.sound("mcl_enchanting_enchant", { pos = at, gain = 0.7, pitch = 0.8 })
end

minemon.fx.register_move("type:psychic", R)
