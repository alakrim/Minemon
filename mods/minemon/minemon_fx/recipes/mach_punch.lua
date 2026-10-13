-- Mach Punch (M2.1, T-FX2-a): a stutter. Five jabs land in the time of one blink: five small stars flash on the
-- victim one after another, each a little off the last, and the last is the biggest. The idea is the speed of it:
-- the stars are short-lived and are placed by timers (0.045 s apart), not by one spawner. Priority move, weak
-- (power 40). Budget: cast 8, melee 8, impact 30 particles over 0.2 s.
-- luacheck: read_globals core vector minemon

local R = {}

local STAR = "minemon_fx_impact_star.png"
local SPEED = "minemon_fx_speedline.png"
local STEP_S = 0.045
-- Five jabs: offsets across and up the victim (nodes), and their sizes (the last one lands hardest).
local JABS = {
	{ x = -0.22, y = 0.10, size = 0.7 },
	{ x = 0.16, y = -0.06, size = 0.75 },
	{ x = -0.08, y = 0.18, size = 0.8 },
	{ x = 0.22, y = 0.12, size = 0.85 },
	{ x = 0.00, y = 0.00, size = 1.2 },
}

-- Wind-up: the fists are drawn in, quick motes go into the chest.
function R.cast(F, c)
	local at = F.anchor(c.user, "middle", 0.6, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.12, c.time or 0.3)
	F.inhale({ pos = at, tex = F.TEX.spark, colour = c.palette.main, radius = 0.8, amount = 14, time = t,
		size = { 0.07, 0.1 } })
end

-- The run in: two speed lines fly at the victim, one for each fist.
function R.melee(F, c)
	for _, dy in ipairs({ 0.1, -0.1 }) do
		F.emit({
			amount = 1, time = 0.02, pos = vector.add(c.centre, { x = 0, y = dy, z = 0 }),
			vel = vector.multiply(c.fwd, 8), exptime = 0.14, size = 0.5,
			texture = F.tex(F.tint(SPEED, c.palette.main), { blend = "add", fade = true }), glow = 14,
		})
	end
end

-- Five jabs: a star at each place on the victim, timed STEP_S apart. Each jab is a flash and a little flick.
function R.impact(F, c)
	local at = c.pos
	for i, j in ipairs(JABS) do
		core.after((i - 1) * STEP_S, function()
			local p = vector.add(at, { x = j.x, y = j.y, z = 0 })
			F.emit({
				amount = 1, time = 0.02, pos = p, vel = { x = 0, y = 0, z = 0 }, exptime = 0.1, size = j.size,
				texture = F.tex(F.tint(STAR, c.palette.core), { blend = "add", fade = true, grow = { 0.7, 1.0 } }),
				glow = 14,
			})
			F.emit({
				amount = 2, time = 0.02, pos = p,
				vel = { min = { x = -1.5, y = 0.5, z = -1 }, max = { x = 1.5, y = 1.5, z = 1 } },
				exptime = { min = 0.1, max = 0.18 }, size = { min = 0.08, max = 0.12 },
				texture = F.tex(F.tint(SPEED, c.palette.main), { blend = "add", fade = true }), glow = 14,
			})
			F.sound("default_dig_oddly_breakable_by_hand", { pos = p, gain = 0.4, pitch = 1.8 + 0.1 * i })
		end)
	end
end

minemon.fx.register_move("mach_punch", R)
