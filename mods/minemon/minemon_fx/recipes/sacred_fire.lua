-- Sacred Fire (M2.1 wave 2, group B, power 100, accuracy 95, burn 50%): a holy fire. A pale gold halo opens at the
-- muzzle; the orb is a white-gold light with a soft halo and embers that rise off it instead of falling (the only fire
-- move that rises); on the hit a column of light climbs out of the victim's feet, a gold ring opens and a sigil stays
-- on the ground for six seconds. Strong: big and slow to read. The colours are the gold pale tones of the fire palette,
-- not orange: the fire type is orange flame.
-- Budget at "high": launch ~35, projectile ~55/s, impact ~110, plus one decal.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	glow = "minemon_fx_glow.png",
	ring = "minemon_fx_ring.png",
	rune = "minemon_fx_rune.png",
	ember = "minemon_fx_ember.png",
	flare = "minemon_fx_flare.png",
}
local ZERO = { x = 0, y = 0, z = 0 }
local HOLY = "#fff2b0"
local GOLD = "#ffd860"
local RISE = { x = 0, y = 1.4, z = 0 }

-- The halo: a pale gold ring at the muzzle and a column of holy sparks that rise from it.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = HOLY, size = 1.2, life = 0.2 })
	F.ring({ pos = c.from, colour = GOLD, size = 0.45, grow = 3.4, life = 0.4 })
	F.emit({
		amount = 16, time = 0.06, pos = c.from,
		vel = { min = { x = -0.5, y = 0.8, z = -0.5 }, max = { x = 0.5, y = 2.0, z = 0.5 } },
		acc = { x = 0, y = 1.2, z = 0 }, exptime = { min = 0.35, max = 0.6 }, size = { min = 0.12, max = 0.2 },
		texture = F.tex(F.tint(TEX.glow, GOLD), { blend = "add", fade = true, grow = { 1, 0.5 } }), glow = 14,
	})
	F.sound("mcl_enchanting_enchant", { pos = c.from, gain = 0.6, pitch = 1.5 })
end

-- The orb: a white-gold light with a soft halo, and holy embers that rise off it and fade.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.glow, HOLY) }, visual_size = { x = 1.0, y = 1.0 }, glow = 14 })
	F.on(c.obj, {
		amount = 14, time = 1.5, pos = { min = { x = -0.12, y = -0.12, z = -0.12 }, max = { x = 0.12, y = 0.12, z = 0.12 } },
		vel = ZERO, exptime = { min = 0.5, max = 0.8 }, size = { min = 0.7, max = 0.95 },
		texture = F.tex(F.tint(TEX.glow, GOLD), { blend = "add", fade = true, grow = { 0.8, 1.2 } }), glow = 14,
	})
	F.on(c.obj, {
		amount = 22, time = 1.5, pos = { min = { x = -0.3, y = -0.3, z = -0.3 }, max = { x = 0.3, y = 0.3, z = 0.3 } },
		vel = { min = { x = -0.2, y = 0.6, z = -0.2 }, max = { x = 0.2, y = 1.3, z = 0.2 } }, acc = RISE,
		exptime = { min = 0.5, max = 0.9 }, size = { min = 0.12, max = 0.2 },
		texture = F.tex(F.TEX.ember, { blend = "add", fade = { 1, 0.4 } }), glow = 14,
	})
	return true
end

-- The pillar: a column of light climbs out of the victim's feet, a gold ring opens, the sigil lies on the ground and
-- holy sparks rise from it.
function R.impact(F, c)
	local at = c.pos
	local feet = vector.add(at, { x = 0, y = -0.5, z = 0 })
	F.flare({ pos = at, colour = HOLY, size = 1.9, life = 0.2 })
	F.emit({
		amount = 26, time = 0.25,
		pos = { min = vector.add(feet, { x = -0.25, y = 0, z = -0.25 }),
			max = vector.add(feet, { x = 0.25, y = 0, z = 0.25 }) },
		vel = { min = { x = -0.2, y = 3.0, z = -0.2 }, max = { x = 0.2, y = 4.5, z = 0.2 } },
		drag = { x = 0.3, y = 0.1, z = 0.3 }, exptime = { min = 0.5, max = 0.8 }, size = { min = 0.45, max = 0.7 },
		texture = F.tex(F.tint(TEX.glow, HOLY), { blend = "add", fade = true, grow = { 0.7, 1.2 } }), glow = 14,
	})
	F.ring({ pos = at, colour = GOLD, size = 0.5, grow = 4.0, life = 0.5 })
	F.emit({
		amount = 18, time = 0.2, pos = { min = vector.subtract(at, { x = 0.3, y = 0.3, z = 0.3 }),
			max = vector.add(at, { x = 0.3, y = 0.6, z = 0.3 }) },
		vel = { min = { x = -0.3, y = 1.0, z = -0.3 }, max = { x = 0.3, y = 2.4, z = 0.3 } }, acc = RISE,
		exptime = { min = 0.6, max = 1.0 }, size = { min = 0.12, max = 0.2 },
		texture = F.tex(F.TEX.ember, { blend = "add", fade = { 1, 0.3 } }), glow = 14,
	})
	F.decal({ pos = at, tex = F.tint(TEX.rune, GOLD), size = 2.4, life = 6 })
	F.sound("mcl_enchanting_enchant", { pos = at, gain = 0.9, pitch = 1.0 })
end

minemon.fx.register_move("sacred_fire", R)
