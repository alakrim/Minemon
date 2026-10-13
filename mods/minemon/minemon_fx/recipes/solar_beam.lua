-- Solar Beam (M2.1, T-FX-b, grass, projectile, 120 power, cast 0.6 s): the signature of grass. Light falls from the sky
-- into the mouth during the long wind-up; the sun-orb flies with a trail of motes and spinning leaves; the impact is a
-- white flash with a pillar of light rising from the target and leaves thrown round it. Budget: cast ~75, launch ~50,
-- projectile ~70/s, impact ~110.
-- luacheck: read_globals core vector minemon

local R = {}

local LEAF = "minemon_fx_leaf_spin_anim.png" -- 8 frames of 16 px: a spinning leaf
local ZERO = { x = 0, y = 0, z = 0 }
local LIGHT = "#f4ffd0" -- the pale green-white of the sunlight
local GOLD = "#fff6a0" -- the warm core of the sun-orb

local function leaf(F, colour, o)
	local t = F.tex(F.tint(LEAF, colour), o)
	t.animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = -1 }
	return t
end

-- Anticipation: light falls out of the sky above the user and is drawn into the mouth; the mouth glows.
function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.3, c.time or 0.6)
	F.emit({
		amount = 34, time = t,
		pos = { min = vector.add(at, { x = -1.6, y = 2.0, z = -1.6 }), max = vector.add(at, { x = 1.6, y = 3.0, z = 1.6 }) },
		attract = { kind = "point", origin = at, strength = { min = 4, max = 6 }, die_on_contact = true },
		vel = ZERO, exptime = { min = t * 0.6, max = t }, size = { min = 0.1, max = 0.16 },
		texture = F.tex(F.tint(F.TEX.mote, LIGHT), { blend = "add", fade = { 0.3, 1 } }), glow = 14,
	})
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t + 0.05, size = 1.0,
		texture = F.tex(F.tint(F.TEX.glow, GOLD), { blend = "add", grow = { 0.2, 1.4 }, alpha = 0.9 }), glow = 14,
	})
	F.sound("mcl_mobs_mob_poof", { pos = at, gain = 0.3, pitch = 1.6 })
end

-- Release: a white flash and a ring of light at the muzzle; sparks fly out.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = "#ffffff", size = 1.6, life = 0.2 })
	F.ring({ pos = c.from, colour = LIGHT, size = 0.5, grow = 2.4, life = 0.3 })
	F.burst({ pos = c.from, tex = F.TEX.spark, colour = GOLD, amount = 20, speed = 4, life = { 0.2, 0.5 },
		size = { 0.12, 0.2 } })
	F.sound("mcl_bows_bow_shoot", { pos = c.from, gain = 0.7, pitch = 0.6 })
end

-- The sun-orb: a bright gold core with a trail of light motes and spinning leaves. Returns true: decorated.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(F.TEX.glow, GOLD) }, visual_size = { x = 0.95, y = 0.95 }, glow = 14 })
	F.on(c.obj, {
		amount = 40, time = 1.5, pos = { min = { x = -0.1, y = -0.1, z = -0.1 }, max = { x = 0.1, y = 0.1, z = 0.1 } },
		vel = ZERO, exptime = { min = 0.25, max = 0.45 }, size = { min = 0.3, max = 0.5 },
		texture = F.tex(F.tint(F.TEX.glow, LIGHT), { blend = "add", fade = true, grow = { 1, 0.3 } }), glow = 14,
	})
	F.on(c.obj, {
		amount = 18, time = 1.5, pos = { x = 0, y = 0, z = 0 },
		vel = { min = { x = -0.5, y = -0.5, z = -0.5 }, max = { x = 0.5, y = 0.5, z = 0.5 } },
		exptime = { min = 0.4, max = 0.8 }, size = { min = 0.12, max = 0.2 },
		texture = F.tex(F.tint(F.TEX.mote, LIGHT), { blend = "add", fade = true }), glow = 14,
	})
	F.on(c.obj, {
		amount = 10, time = 1.5, pos = { min = { x = -0.2, y = -0.2, z = -0.2 }, max = { x = 0.2, y = 0.2, z = 0.2 } },
		vel = { min = { x = -0.4, y = 0, z = -0.4 }, max = { x = 0.4, y = 0.4, z = 0.4 } },
		acc = { x = 0, y = -1, z = 0 }, exptime = { min = 0.6, max = 1.0 }, size = { min = 0.28, max = 0.38 },
		texture = leaf(F, "#9be070", { blend = "alpha", fade = { 1, 0.5 } }), glow = 0,
	})
	return true
end

-- Impact: a white flash, a pillar of light rising from the target, a ring and leaves scattered round it.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = "#ffffff", size = 2.6, life = 0.25 })
	F.emit({
		amount = 36, time = 0.25,
		pos = { min = vector.add(at, { x = -0.3, y = 0, z = -0.3 }), max = vector.add(at, { x = 0.3, y = 0.4, z = 0.3 }) },
		vel = { min = { x = -0.1, y = 3, z = -0.1 }, max = { x = 0.1, y = 6, z = 0.1 } },
		drag = { x = 0.5, y = 0, z = 0.5 }, exptime = { min = 0.4, max = 0.8 }, size = { min = 0.14, max = 0.22 },
		vertical = true, texture = F.tex(F.tint(F.TEX.streak, "#fff8c8"), { blend = "add", fade = true }), glow = 14,
	})
	F.ring({ pos = at, colour = LIGHT, size = 0.8, grow = 4.2, life = 0.45 })
	F.emit({
		amount = 16, time = 0.1, pos = at, radius = { min = 0.2, max = 0.5, bias = 0 },
		vel = { min = { x = -2, y = 1, z = -2 }, max = { x = 2, y = 3, z = 2 } }, drag = { x = 1, y = 0.5, z = 1 },
		acc = { x = 0, y = -2, z = 0 }, exptime = { min = 0.6, max = 1.1 }, size = { min = 0.25, max = 0.35 },
		texture = leaf(F, "#6fe05a", { blend = "alpha", fade = { 1, 0.5 } }), glow = 0,
	})
	F.sound("mcl_bows_firework_soft", { pos = at, gain = 0.9, pitch = 1.2 })
end

minemon.fx.register_move("solar_beam", R)
