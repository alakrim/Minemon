-- Karate Chop (M2.1, T-FX2-a): a chevron. The hand is raised over the head (speed lines are drawn up into it), then
-- it comes down edge-first: two claw cuts meet in a V that falls onto the victim's shoulder, and at the blow the V
-- flashes and throws splinters of light sideways. Fighting type: orange, with the chop's own V shape. Budget: cast
-- 14, melee 14, impact 34 particles.
-- luacheck: read_globals core vector minemon

local R = {}

local CLAW = "minemon_fx_claw.png"
local CLAW_FX = "minemon_fx_claw.png^[transformFX" -- the other diagonal: the two arms of the V
local SPEED = "minemon_fx_speedline.png"
local ZERO = { x = 0, y = 0, z = 0 }

local function right_of(fwd, k)
	return { x = -fwd.z * k, y = 0, z = fwd.x * k }
end

-- Wind-up: speed lines are drawn up into the raised hand, above the head.
function R.cast(F, c)
	local head = F.anchor(c.user, "head", 1.0)
	if not head then
		return false
	end
	local t = math.max(0.15, c.time or 0.3)
	F.inhale({ pos = vector.add(head, { x = 0, y = 0.2, z = 0 }), tex = SPEED, colour = c.palette.main, radius = 0.9,
		amount = 16, time = t, size = { 0.2, 0.32 } })
	F.emit({
		amount = 1, time = t, pos = vector.add(head, { x = 0, y = 0.25, z = 0 }), vel = ZERO, exptime = 0.2, size = 0.6,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add", fade = true, grow = { 0.5, 1.0 } }),
		glow = 14,
	})
end

-- The chop: the two arms of the V come down from above the head, edge first, in front of the user.
function R.melee(F, c)
	local top = vector.add(c.centre, { x = c.fwd.x * 0.25, y = 0.5, z = c.fwd.z * 0.25 })
	for _, arm in ipairs({ { tex = CLAW, k = -0.12 }, { tex = CLAW_FX, k = 0.12 } }) do
		F.emit({
			amount = 1, time = 0.02, pos = vector.add(top, right_of(c.fwd, arm.k)),
			vel = { x = c.fwd.x * 2, y = -6, z = c.fwd.z * 2 }, exptime = 0.2, size = 1.0,
			texture = F.tex(F.tint(arm.tex, c.palette.core), { blend = "add", fade = true }), glow = 14,
		})
	end
end

-- The blow: the V lands on the victim's shoulder, a flash, and splinters thrown sideways from the edge.
function R.impact(F, c)
	local at = c.pos
	for _, arm in ipairs({ { tex = CLAW, k = -0.14 }, { tex = CLAW_FX, k = 0.14 } }) do
		F.emit({
			amount = 1, time = 0.02, pos = vector.add(at, right_of(c.fwd, arm.k)), vel = ZERO, exptime = 0.3,
			size = 1.2, texture = F.tex(F.tint(arm.tex, "#ffffff"), { blend = "add", fade = true,
				grow = { 0.85, 1.1 } }), glow = 14,
		})
	end
	F.flare({ pos = at, colour = c.palette.core, size = 1.0, life = 0.12 })
	for _, side in ipairs({ 1, -1 }) do
		local sideways = right_of(c.fwd, side)
		F.emit({
			amount = 7, time = 0.04, pos = at,
			vel = { min = vector.add(vector.multiply(sideways, 2.5), { x = 0, y = 0.5, z = 0 }),
				max = vector.add(vector.multiply(sideways, 4.5), { x = 0, y = 1.5, z = 0 }) },
			acc = { x = 0, y = -6, z = 0 }, exptime = { min = 0.2, max = 0.4 }, size = { min = 0.1, max = 0.16 },
			texture = F.tex(F.tint(SPEED, c.palette.main), { blend = "add", fade = true }), glow = 14,
		})
	end
	F.sound("default_dig_choppy", { pos = at, gain = 0.8, pitch = 1.3 })
end

minemon.fx.register_move("karate_chop", R)
