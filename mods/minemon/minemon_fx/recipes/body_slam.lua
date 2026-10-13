-- Body Slam (M2.1, T-FX2-a): a heavy fall onto the ground. The idea is low and flat: the user crouches and dust is
-- drawn into its feet, it leaps along the floor under a skirt of dust, and on the landing a shock ring runs out
-- over the victim's feet with a flat skirt of dust hugging the ground (no lift: every dust puff stays under 0.3 m/s
-- up). Strong (power 85): big and slow. Budget: cast 14, melee 14, impact 40 particles and one ring.
-- luacheck: read_globals core vector minemon

local R = {}

local DUST = "minemon_fx_dust.png"
local ZERO = { x = 0, y = 0, z = 0 }

local function feet_of(obj)
	local p = obj:get_pos()
	return p and { x = p.x, y = p.y + 0.1, z = p.z } or nil
end

-- Wind-up: the user crouches, and the dust round its feet is drawn in under it.
function R.cast(F, c)
	local feet = feet_of(c.user)
	if not feet then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.inhale({ pos = feet, tex = DUST, colour = c.palette.smoke, radius = 1.0, amount = 16, time = t,
		size = { 0.25, 0.4 } })
end

-- The leap: a low skirt of dust sweeps along the floor in front of the user.
function R.melee(F, c)
	local feet = feet_of(c.user)
	if not feet then
		return
	end
	F.emit({
		amount = 12, time = 0.08, pos = { min = vector.add(feet, { x = -0.2, y = 0, z = -0.2 }),
			max = vector.add(feet, { x = 0.2, y = 0.05, z = 0.2 }) },
		vel = { min = vector.add(vector.multiply(c.fwd, 3), { x = -1, y = 0, z = -1 }),
			max = vector.add(vector.multiply(c.fwd, 5), { x = 1, y = 0.15, z = 1 }) },
		drag = { x = 0.6, y = 0.6, z = 0.6 },
		exptime = { min = 0.4, max = 0.6 }, size = { min = 0.5, max = 0.7 },
		texture = F.tex(F.tint(DUST, c.palette.smoke), { blend = "alpha", alpha = 0.75, fade = true,
			grow = { 0.8, 1.5 } }),
		glow = 0,
	})
end

-- The landing: a ground shock ring from the victim's feet, a skirt of dust thrown flat out in eight directions, and
-- a low white flash.
function R.impact(F, c)
	local victim = c.victim
	local feet = victim and victim:get_pos()
	if not feet then
		return
	end
	local at = { x = feet.x, y = feet.y + 0.1, z = feet.z }
	F.ring({ pos = at, colour = c.palette.main, size = 0.5, grow = 4.2, life = 0.45 })
	F.flare({ pos = at, colour = c.palette.core, size = 1.2, life = 0.14 })
	for i = 0, 7 do
		local a = i / 8 * 2 * math.pi
		local dir = { x = math.cos(a), y = 0, z = math.sin(a) }
		F.emit({
			amount = 2, time = 0.03, pos = vector.add(at, vector.multiply(dir, 0.2)),
			vel = { min = vector.multiply(dir, 2.4), max = vector.multiply(dir, 3.4) },
			acc = ZERO, drag = { x = 0.9, y = 0.9, z = 0.9 },
			exptime = { min = 0.55, max = 0.9 }, size = { min = 0.6, max = 0.9 },
			texture = F.tex(F.tint(DUST, c.palette.smoke), { blend = "alpha", alpha = 0.75, fade = true,
				grow = { 0.8, 1.6 } }),
			glow = 0,
		})
	end
	F.sound("mcl_criticals_hit.1", { pos = at, gain = 0.9, pitch = 0.6 })
end

minemon.fx.register_move("body_slam", R)
