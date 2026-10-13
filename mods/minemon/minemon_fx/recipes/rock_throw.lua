-- Rock Throw (M2.1, T-FX-b, rock, beam, 50 power): the signature of rock throws. One big rock tumbles along the line
-- from the thrower with a dust trail, and where it lands it breaks: stone blocks fly, dust blooms and a ring of stone
-- dust goes out. Budget: beam ~70 particles, impact ~60.
-- luacheck: read_globals core vector minemon

local R = {}

local CHUNK = "minemon_fx_chunk_spin_anim.png" -- 4 frames of 16 px: a rough chunk, spinning
local COBBLE = { name = "mcl_core:cobble" }

local function chunk(F, colour, o)
	local t = F.tex(F.tint(CHUNK, colour), o)
	t.animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = -1 }
	return t
end

function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 22
	local dir = vector.multiply(d, 1 / len)
	-- The rock: one big chunk that tumbles all the way (its life is the flight time).
	F.emit({
		amount = 1, time = 0.02, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = 1.1, texture = chunk(F, c.palette.edge, { blend = "alpha" }), glow = 0,
	})
	-- Its dust trail, and a few stone blocks that fall away behind it.
	F.emit({
		amount = 24, time = 0.3, pos = c.from, vel = vector.multiply(dir, speed * 0.5),
		exptime = { min = 0.5, max = 0.9 }, size = { min = 0.5, max = 0.8 },
		texture = F.tex(F.tint(F.TEX.dust, c.palette.smoke), { blend = "alpha", alpha = 0.6, grow = { 0.6, 1.3 } }),
		glow = 0,
	}, c.from)
	F.emit({
		amount = 8, time = 0.3, pos = c.from, vel = vector.multiply(dir, speed * 0.6),
		acc = { x = 0, y = -14, z = 0 }, collisiondetection = true, bounce = { min = 0.2, max = 0.4 },
		exptime = { min = 0.4, max = 0.7 }, size = { min = 0.12, max = 0.2 }, node = COBBLE, glow = 0,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9 })
	F.sound("mcl_throwing_throw", { pos = c.from, gain = 0.6, pitch = 0.5 })
end

-- The break where the rock lands: a flash, stone blocks thrown up and bouncing, dust and a ring of stone dust.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.3, life = 0.14 })
	F.emit({
		amount = 16, time = 0.05, pos = at, radius = { min = 0.1, max = 0.3, bias = 0 },
		vel = { min = { x = -3, y = 2, z = -3 }, max = { x = 3, y = 4.5, z = 3 } },
		acc = { x = 0, y = -14, z = 0 }, collisiondetection = true, bounce = { min = 0.2, max = 0.4 },
		exptime = { min = 0.6, max = 1.0 }, size = { min = 0.16, max = 0.26 }, node = COBBLE, glow = 0,
	})
	F.burst({ pos = at, tex = F.TEX.dust, colour = c.palette.smoke, blend = "alpha", amount = 16, speed = 3,
		life = { 0.6, 1.0 }, size = { 0.5, 0.8 }, gravity = -0.4, glow = 0 })
	F.ring({ pos = at, colour = c.palette.edge, size = 0.4, grow = 3.0, life = 0.35 })
	F.sound("default_dig_cracky", { pos = at, gain = 0.9, pitch = 0.7 })
end

minemon.fx.register_move("rock_throw", R)
