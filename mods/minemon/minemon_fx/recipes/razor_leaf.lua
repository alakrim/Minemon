-- Razor Leaf (M2.1, T-FX-b, grass, area, 55 power): the signature of grass storms. A green ring rushes out
-- and a storm of spinning leaves whirls out from the centre; each victim takes razor cuts (two crescent
-- slashes) and a burst of leaves.
-- Budget: area ~150 particles, impact ~60.
-- luacheck: read_globals core vector minemon

local R = {}

local LEAF = "minemon_fx_leaf_spin_anim.png" -- 8 frames of 16 px: a spinning leaf
local SLASH = "minemon_fx_slash.png" -- a crescent melee arc: a cut
local ZERO = { x = 0, y = 0, z = 0 }

local function leaf(F, colour, o)
	local t = F.tex(F.tint(LEAF, colour), o)
	t.animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = -1 }
	return t
end

-- Leaves thrown out of pos (negative attraction, as F.burst). speed in m/s, life {min, max}, size {min, max}.
local function leaves(F, pos, colour, speed, amount, life, size)
	F.emit({
		amount = amount, time = 0.08, pos = pos, radius = { min = 0.15, max = 0.4, bias = 0 },
		attract = { kind = "point", origin = pos, strength = { min = -speed / 0.3 * 0.6, max = -speed / 0.3 },
			die_on_contact = false },
		vel = ZERO, drag = { x = 1.1, y = 0.5, z = 1.1 }, acc = { x = 0, y = -1, z = 0 },
		exptime = { min = life[1], max = life[2] }, size = { min = size[1], max = size[2] },
		texture = leaf(F, colour, { blend = "alpha", fade = { 1, 0.5 } }), glow = 0,
	})
end

-- The storm: a green shock ring, then leaves whirling out from the centre over the whole radius.
function R.area(F, c)
	local r = c.radius
	local ctr = c.centre
	F.flare({ pos = ctr, colour = c.palette.core, size = 1.2, life = 0.2 })
	F.ring({ pos = ctr, colour = c.palette.main, size = 0.6, grow = r * 1.6, life = 0.4 })
	leaves(F, ctr, c.palette.main, r * 1.8, 50, { 0.8, 1.4 }, { 0.22, 0.34 })
	leaves(F, ctr, "#c8ff9a", r * 0.9, 20, { 0.5, 0.9 }, { 0.14, 0.22 })
	F.sound("mcl_tools_shears_cut", { pos = ctr, gain = 0.8, pitch = 1.2 })
end

-- Razor cuts on each victim: two crescent slashes crossing, a burst of leaves and a thin flash.
function R.impact(F, c)
	local at = c.pos
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.16, size = 1.6,
		texture = F.tex(F.tint(SLASH, c.palette.core), { blend = "add", fade = true, grow = { 0.6, 1.0 } }), glow = 14,
	})
	F.emit({
		amount = 1, time = 0.02, pos = vector.add(at, { x = 0.15, y = -0.1, z = 0 }), vel = ZERO, exptime = 0.16,
		size = 1.2, texture = F.tex(F.tint(SLASH .. "^[transformFX", c.palette.main),
			{ blend = "add", fade = true, grow = { 0.6, 1.0 } }), glow = 14,
	})
	F.flare({ pos = at, colour = c.palette.core, size = 0.9, life = 0.12 })
	leaves(F, at, c.palette.main, 3, 16, { 0.5, 0.9 }, { 0.2, 0.3 })
	F.sound("default_dig_snappy", { pos = at, gain = 0.8, pitch = 1.5 })
end

minemon.fx.register_move("razor_leaf", R)
