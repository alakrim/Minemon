-- Lick (M2.1, T-FX2-a): a long wet tongue. The wind-up is a violet strand that curls out of the mouth and grows. In
-- the blow it is a tongue of light that runs from the mouth to the victim in a flick (five strands laid along the
-- way), and the victim is left wet: goo beads land on it and drip down with gravity. Weak (power 20), and it can
-- paralyse. Ghost type: the violet of the ghost palette, with the drip that makes it feel unpleasant. Budget: cast
-- 8, melee 12, impact 26 particles.
-- luacheck: read_globals core vector minemon

local R = {}

local TONGUE = "minemon_fx_tendril.png"
local GOO = "minemon_fx_goo.png"
local DROP = "minemon_fx_drop.png"

local function middle_of(F, obj)
	return F.anchor(obj, "middle", 0.55) or vector.add(obj:get_pos(), { x = 0, y = 0.5, z = 0 })
end

-- Wind-up: a violet strand grows out of the mouth, and motes are drawn back into it.
function R.cast(F, c)
	local mouth = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not mouth then
		return false
	end
	local t = math.max(0.15, c.time or 0.3)
	F.emit({
		amount = 1, time = t, pos = mouth, vel = { x = 0, y = 0, z = 0 }, exptime = t + 0.05, size = 0.7,
		texture = F.tex(F.tint(TONGUE, c.palette.main), { blend = "alpha", alpha = 0.9, grow = { 0.4, 1.3 } }),
		glow = 6,
	})
	F.inhale({ pos = mouth, tex = F.TEX.mote, colour = c.palette.main, radius = 0.8, amount = 8, time = t,
		size = { 0.07, 0.12 } })
end

-- The lick: strands of tongue laid along the way from the mouth to the victim, each one a little further on.
function R.melee(F, c)
	local from = F.anchor(c.user, "mouth", 0.75, 0.6) or c.centre
	local to = middle_of(F, c.target)
	local span = vector.subtract(to, from)
	for i = 1, 5 do
		local p = vector.add(from, vector.multiply(span, (i - 1) / 5))
		F.emit({
			amount = 1, time = 0.02, pos = p, vel = vector.multiply(span, 4), exptime = 0.2, size = 0.75,
			texture = F.tex(F.tint(TONGUE, c.palette.main), { blend = "alpha", alpha = 0.9, fade = true,
				grow = { 0.8, 1.2 } }),
			glow = 6,
		})
	end
end

-- The wet hit: a violet glow, goo beads that stick to the victim, and drops that run down it with gravity.
function R.impact(F, c)
	local at = c.pos
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = { x = 0, y = 0, z = 0 }, exptime = 0.25, size = 0.9,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add", fade = true, grow = { 0.6, 1.2 } }),
		glow = 6,
	})
	F.emit({
		amount = 3, time = 0.03, pos = at, radius = { min = 0.05, max = 0.25, bias = 0 },
		vel = { min = { x = -0.6, y = 0, z = -0.6 }, max = { x = 0.6, y = 0.6, z = 0.6 } },
		drag = { x = 0.5, y = 0.5, z = 0.5 },
		exptime = { min = 0.6, max = 0.9 }, size = { min = 0.22, max = 0.3 },
		texture = F.tex(F.tint(GOO, c.palette.main), { blend = "alpha", alpha = 0.85, fade = { 1, 0.6 } }), glow = 0,
	})
	F.emit({
		amount = 5, time = 0.06, pos = { min = vector.add(at, { x = -0.2, y = 0, z = -0.2 }),
			max = vector.add(at, { x = 0.2, y = 0.1, z = 0.2 }) },
		vel = { min = { x = -0.3, y = -0.4, z = -0.3 }, max = { x = 0.3, y = 0.2, z = 0.3 } },
		acc = { x = 0, y = -7, z = 0 }, collisiondetection = true, bounce = { min = 0.1, max = 0.25 },
		exptime = { min = 0.5, max = 0.8 }, size = { min = 0.1, max = 0.15 },
		texture = F.tex(F.tint(DROP, c.palette.edge), { blend = "alpha", alpha = 0.9, fade = { 1, 0.7 } }), glow = 0,
	})
	F.sound("default_dirt_footstep", { pos = at, gain = 0.7, pitch = 1.7 })
end

minemon.fx.register_move("lick", R)
