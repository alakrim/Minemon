-- Rollout (M2.1, T-FX2-a): a rock that rolls. The user curls up: small stone chips are drawn in round its middle
-- (wind-up). In the blow a spinning rock chunk rolls along the ground to the victim, leaving chips that bounce
-- behind it. On the victim the rock hits: its chunks burst out, dust goes up, and a crater is left under the
-- victim's feet (the mark stays for six seconds). Weak (power 30), repeated: small rocks, and the crater is the
-- only thing that stays. Budget: cast 10, melee 12, impact 26 particles and one decal.
-- luacheck: read_globals core vector minemon

local R = {}

local CHUNK = "minemon_fx_chunk_spin_anim.png" -- 4 frames of 16 px: a rough chunk, spinning
local CHIP = "minemon_fx_chip.png"
local CRATER = "minemon_fx_crater.png"
local DUST = "minemon_fx_dust.png"
local SPIN = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = -1 }

-- A spinning chunk texture: the flipbook of CHUNK tinted for the move, with a fade (o.fade table or true).
local function chunk(F, colour, fade)
	local t = F.tex(F.tint(CHUNK, colour), { blend = "alpha", fade = fade })
	t.animation = SPIN
	return t
end

-- Wind-up: chips are drawn in round the user's middle, and a glow of stone colour swells there.
function R.cast(F, c)
	local at = F.anchor(c.user, "middle", 0.5, 0.0)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.3)
	F.inhale({ pos = at, tex = CHIP, colour = c.palette.main, radius = 0.9, amount = 12, time = t,
		size = { 0.1, 0.16 } })
	F.emit({
		amount = 1, time = t, pos = at, vel = { x = 0, y = 0, z = 0 }, exptime = t + 0.05, size = 0.7,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add", grow = { 0.3, 1.0 }, alpha = 0.6 }),
		glow = 6,
	})
end

-- The roll: a spinning chunk travels along the ground from the user, and chips bounce off the ground behind it.
function R.melee(F, c)
	local feet = c.user:get_pos()
	if not feet then
		return
	end
	local ground = vector.add(feet, { x = 0, y = 0.35, z = 0 })
	F.emit({
		amount = 1, time = 0.02, pos = ground, vel = vector.multiply(c.fwd, 6), exptime = 0.24, size = 0.7,
		texture = chunk(F, c.palette.main, true), glow = 0,
	})
	F.emit({
		amount = 4, time = 0.1, pos = vector.add(ground, { x = 0, y = -0.2, z = 0 }),
		vel = { min = vector.multiply(c.fwd, 1.5), max = vector.multiply(c.fwd, 2.5) },
		acc = { x = 0, y = -9, z = 0 }, collisiondetection = true, bounce = { min = 0.2, max = 0.35 },
		exptime = { min = 0.3, max = 0.5 }, size = { min = 0.12, max = 0.18 },
		texture = F.tex(F.tint(CHIP, c.palette.smoke), { blend = "alpha", fade = { 1, 0.5 } }), glow = 0,
	})
end

-- The hit, when the rock arrives: a flash, chunks burst out and bounce, dust goes up, and a crater is left under
-- the victim's feet.
function R.impact(F, c)
	local victim = c.victim
	if not (victim and victim:get_pos()) then
		return
	end
	F.flare({ pos = c.pos, colour = c.palette.core, size = 0.9, life = 0.1 })
	F.after(0.14, function()
		local feet = victim:get_pos()
		if not feet then
			return
		end
		local at = vector.add(feet, { x = 0, y = 0.15, z = 0 })
		F.emit({
			amount = 4, time = 0.04, pos = at, radius = { min = 0.05, max = 0.2, bias = 0 },
			vel = { min = { x = -2.5, y = 2.2, z = -2.5 }, max = { x = 2.5, y = 4.0, z = 2.5 } },
			acc = { x = 0, y = -9, z = 0 }, collisiondetection = true, bounce = { min = 0.25, max = 0.45 },
			exptime = { min = 0.6, max = 1.0 }, size = { min = 0.2, max = 0.3 },
			texture = chunk(F, c.palette.main, { 1, 0.6 }), glow = 0,
		})
		F.emit({
			amount = 6, time = 0.04, pos = { min = vector.add(at, { x = -0.25, y = 0, z = -0.25 }),
				max = vector.add(at, { x = 0.25, y = 0.05, z = 0.25 }) },
			vel = { min = { x = -1.2, y = 0.1, z = -1.2 }, max = { x = 1.2, y = 0.4, z = 1.2 } },
			exptime = { min = 0.4, max = 0.7 }, size = { min = 0.4, max = 0.6 },
			texture = F.tex(F.tint(DUST, c.palette.smoke), { blend = "alpha", alpha = 0.6, fade = true }), glow = 0,
		})
		F.decal({ pos = feet, tex = F.tint(CRATER, c.palette.main), size = 1.3, life = 6 })
		F.sound("default_dig_cracky", { pos = at, gain = 0.8, pitch = 0.8 })
	end)
end

minemon.fx.register_move("rollout", R)
