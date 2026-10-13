-- Ancient Power (M2.1 wave 2, group B, power 60, rock, raises every stat 10%, beam): stones from the old ground. The
-- cast lifts rock chips off the ground round the user; the beam throws spinning rock chunks along the line; on the hit
-- six spinning shards hang round the victim's body in a ring, rising slowly, with a warm gold flash. Medium: the
-- spinning rock that hangs round the victim is the signature (Rock Slide and Rock Throw are heavy falling rocks).
-- Budget at "high": cast ~40, beam ~70, impact ~70.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	chunk = "minemon_fx_chunk_spin_anim.png",
	glow = "minemon_fx_glow.png",
}
local CHUNK_ANIM = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = -1 }
local GRAV = { x = 0, y = -9.8, z = 0 }
local ORBIT_R = 0.6

local function chunk(F, colour, o)
	local t = F.tex(F.tint(TEX.chunk, colour), o)
	t.animation = CHUNK_ANIM
	return t
end

-- Wind-up: rock chips lift off the ground round the user's feet and fall back.
function R.cast(F, c)
	local at = F.anchor(c.user, "middle", 0.1) or c.from
	if not at then
		return false
	end
	local t = math.max(0.2, c.time or 0.6)
	local feet = { x = at.x, y = at.y - 0.4, z = at.z }
	F.emit({
		amount = 14, time = t,
		pos = { min = vector.subtract(feet, { x = 0.7, y = 0, z = 0.7 }),
			max = vector.add(feet, { x = 0.7, y = 0.1, z = 0.7 }) },
		vel = { min = { x = -0.4, y = 1.8, z = -0.4 }, max = { x = 0.4, y = 3.0, z = 0.4 } },
		acc = GRAV,
		exptime = { min = 0.6, max = 0.9 }, size = { min = 0.16, max = 0.24 },
		texture = chunk(F, c.palette.main, { blend = "alpha", fade = { 1, 0.6 } }), glow = 4,
	})
end

-- The beam of stones: spinning chunks fly from the user to the stop point, and a dust puff rises at the start.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 16
	local dir = vector.multiply(d, 1 / len)
	F.emit({
		amount = 16, time = 0.35, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		jitter = { min = { x = -0.3, y = -0.3, z = -0.3 }, max = { x = 0.3, y = 0.3, z = 0.3 } },
		size = { min = 0.22, max = 0.3 },
		texture = chunk(F, c.palette.main, { blend = "alpha", fade = { 1, 0.7 } }), glow = 4,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.7, life = 0.12 })
end

-- The orbit: six spinning rock shards hang round the victim's body, rising slowly, and a gold flash marks the hit.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.1, life = 0.14 })
	F.ring({ pos = at, colour = c.palette.core, size = 0.35, grow = 2.6, life = 0.3 })
	for i = 0, 5 do
		local a = i / 6 * 2 * math.pi
		local p = { x = at.x + math.cos(a) * ORBIT_R, y = at.y, z = at.z + math.sin(a) * ORBIT_R }
		F.emit({
			amount = 2, time = 0.9, pos = p, vel = { x = 0, y = 0.5, z = 0 }, exptime = { min = 0.9, max = 1.2 },
			size = { min = 0.24, max = 0.3 },
			texture = chunk(F, c.palette.main, { blend = "alpha", fade = { 1, 0.3 } }), glow = 4,
		})
	end
	F.sound("default_dig_stone", { pos = at, gain = 0.7, pitch = 0.8 })
end

minemon.fx.register_move("ancient_power", R)
