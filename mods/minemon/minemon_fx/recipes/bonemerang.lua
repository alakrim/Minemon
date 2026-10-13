-- Bonemerang (M2.1, T-FX-b, ground, beam, 50 power): the signature of ground throws. A spinning bone flies
-- out to the target and comes back along the same line a moment later, with a trail of dust each way; the
-- first pass throws sparks.
-- Budget: beam ~80 particles (two passes).
-- luacheck: read_globals core vector minemon

local R = {}

local BONE = "minemon_fx_bone_spin_anim.png" -- 4 frames of 16 px: a bone spinning in the picture plane
local PASS_S = 0.4 -- one way

local function bone(F, colour)
	local t = F.tex(F.tint(BONE, colour), { blend = "alpha" })
	t.animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = -1 }
	return t
end

-- One pass of the bone from pos along vel, with its dust trail.
local function pass(F, c, pos, vel)
	F.emit({
		amount = 1, time = 0.02, pos = pos, vel = vel, exptime = PASS_S, size = 0.9, texture = bone(F, c.palette.main),
		glow = 0,
	})
	F.emit({
		amount = 18, time = PASS_S, pos = pos, vel = vel, exptime = { min = 0.3, max = 0.5 },
		size = { min = 0.3, max = 0.5 },
		texture = F.tex(F.tint(F.TEX.dust, c.palette.smoke), { blend = "alpha", alpha = 0.6, grow = { 0.6, 1.2 } }),
		glow = 0,
	}, pos)
end

function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local dir = vector.multiply(d, 1 / len)
	local vel = vector.multiply(dir, len / PASS_S)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.8 })
	F.sound("mcl_throwing_throw", { pos = c.from, gain = 0.6, pitch = 0.6 })
	pass(F, c, c.from, vel)
	F.burst({ pos = c.to, tex = F.TEX.spark, colour = c.palette.core, amount = 10, speed = 3, life = { 0.2, 0.4 },
		size = { 0.1, 0.16 } })
	-- The bone comes back along the line once it has struck, spinning.
	F.after(PASS_S, function()
		pass(F, c, c.to, vector.multiply(vel, -1))
		F.sound("mcl_throwing_throw", { pos = c.to, gain = 0.5, pitch = 0.8 })
	end)
end

minemon.fx.register_move("bonemerang", R)
