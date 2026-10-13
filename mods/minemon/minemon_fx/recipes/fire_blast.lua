-- Fire Blast (signature, M2.1 T-FX-c): a round ball of fire the size of a house. A big fireball flipbook leaves the
-- mouth with a wide muzzle blast, smoke and embers trail it, and the impact is the largest fire effect in the set:
-- three blasts stacked, two shock rings and a scorch that stays. Silhouette: round and heavy, unlike the comet of
-- the type recipe (recipes/type_fire.lua) or the jet of Flamethrower. Budgets: docs/ART_GUIDE.md 4.
-- Totals at "high": launch ~50, projectile ~50/s, impact ~140.
-- luacheck: read_globals core vector minemon

local R = {}

local ZERO = { x = 0, y = 0, z = 0 }

function R.launch(F, c)
	F.blast({ pos = c.from, size = 1.6, life = 0.4 })
	F.ring({ pos = c.from, colour = c.palette.main, size = 0.5, grow = 4.0, life = 0.4 })
	F.flare({ pos = c.from, colour = c.palette.core, size = 1.2, life = 0.15 })
	F.embers({ pos = c.from, amount = 22, speed = 5, up = 2, radius = 0.25 })
	F.sound("mobs_fireball", { pos = c.from, gain = 0.8, pitch = 0.8 })
end

-- The fireball: the flipbook body (four frames, a churning core and a corona), a trail of big flames, embers that
-- fall off it and a dark smoke wake. Returns true: decorated.
function R.projectile(F, c)
	local life = 1.5
	c.obj:set_properties({
		textures = { F.TEX.fireball },
		spritediv = { x = 1, y = F.FRAMES.fireball },
		visual_size = { x = 1.4, y = 1.4 },
		glow = 14,
	})
	c.obj:set_sprite({ x = 0, y = 0 }, F.FRAMES.fireball, 0.08, false)
	F.on(c.obj, {
		amount = 40, time = life,
		pos = { min = { x = -0.2, y = -0.2, z = -0.2 }, max = { x = 0.2, y = 0.2, z = 0.2 } },
		vel = { min = { x = -0.3, y = 0.2, z = -0.3 }, max = { x = 0.3, y = 0.8, z = 0.3 } },
		exptime = { min = 0.3, max = 0.5 }, size = { min = 0.6, max = 0.9 },
		texture = F.tex(F.TEX.flame, { blend = "add", anim = "flame", grow = { 1, 0.4 } }), vertical = true, glow = 14,
	})
	F.on(c.obj, {
		amount = 24, time = life, pos = ZERO,
		vel = { min = { x = -0.8, y = -0.2, z = -0.8 }, max = { x = 0.8, y = 0.8, z = 0.8 } },
		acc = { x = 0, y = -7, z = 0 }, exptime = { min = 0.5, max = 0.9 }, size = { min = 0.08, max = 0.14 },
		collisiondetection = true, bounce = { min = 0.2, max = 0.4 },
		texture = F.tex(F.TEX.ember, { blend = "add", fade = { 1, 0.7 } }), glow = 14,
	})
	F.on(c.obj, {
		amount = 16, time = life, pos = ZERO,
		vel = { min = { x = -0.2, y = 0.4, z = -0.2 }, max = { x = 0.2, y = 0.9, z = 0.2 } },
		exptime = { min = 0.9, max = 1.4 }, size = { min = 0.6, max = 0.9 },
		texture = F.tex(F.tint(F.TEX.smoke, c.palette.smoke), { blend = "alpha", alpha = 0.45, anim = "smoke" }),
	})
	return true
end

-- Impact: three blasts stacked (the largest sits lowest), two shock rings in turn, a column of flame, embers, soot,
-- flames on the victim and a scorch that stays for 8 s.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = "#ffffff", size = 2.2, life = 0.14 })
	F.blast({ pos = at, size = 2.4, life = 0.6 })
	F.blast({ pos = vector.add(at, { x = 0, y = 0.4, z = 0 }), size = 1.8, life = 0.5, spread = 0.35 })
	F.blast({ pos = vector.add(at, { x = 0, y = 0.8, z = 0 }), size = 1.3, life = 0.4, spread = 0.2 })
	F.ring({ pos = at, colour = c.palette.core, size = 0.5, grow = 4.0, life = 0.35 })
	core.after(0.1, function()
		F.ring({ pos = at, colour = c.palette.edge, size = 0.5, grow = 4.8, life = 0.45 })
	end)
	F.flames({ pos = at, amount = 26, size = { 0.5, 0.8 }, life = { 0.5, 0.8 }, spread = 0.4, rise = 2.6, time = 0.2 })
	F.embers({ pos = at, amount = 36, speed = 4.5, up = 4, size = { 0.1, 0.16 } })
	F.smoke({ pos = vector.add(at, { x = 0, y = 0.5, z = 0 }), colour = c.palette.smoke, amount = 10,
		size = { 0.8, 1.2 }, life = { 1.4, 2.0 }, rise = 1.2, time = 0.4 })
	if c.victim and c.victim:get_pos() then
		F.on(c.victim, {
			amount = 16, time = 0.7,
			pos = { min = { x = -0.35, y = 0.1, z = -0.35 }, max = { x = 0.35, y = 1.2, z = 0.35 } },
			vel = { min = { x = 0, y = 0.8, z = 0 }, max = { x = 0, y = 1.6, z = 0 } },
			exptime = { min = 0.4, max = 0.6 }, size = { min = 0.45, max = 0.65 },
			texture = F.tex(F.TEX.flame, { blend = "add", anim = "flame" }), vertical = true, glow = 14,
		})
	end
	F.decal({ pos = at, tex = F.TEX.scorch, size = 2.2, life = 8 })
	F.sound("fire_fire", { pos = at, gain = 1.0, pitch = 0.8 })
end

minemon.fx.register_move("fire_blast", R)
