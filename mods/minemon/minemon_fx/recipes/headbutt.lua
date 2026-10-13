-- Headbutt (M2.1, T-FX2-a): the dazed look. The user's head glows as it winds up; the blow is a short bar of light
-- at the head; and on the victim, five white stars circle above its head for half a second (it is dazed: the flinch
-- chance of the move). The circling is drawn by the server: a fresh star is placed on the ring every 0.1 s. Budget:
-- cast 10, melee 6, impact 36 particles (30 of them are the stars, one at a time).
-- luacheck: read_globals core vector minemon

local R = {}

local STAR = "minemon_fx_star.png"
local STAR_COLOUR = "#fff0a0"
local STEPS = 6
local STARS = 5
local STEP_S = 0.1
local RING_R = 0.32

-- Wind-up: the head heats up. A glow swells at the head and two motes are drawn into it.
function R.cast(F, c)
	local at = F.anchor(c.user, "head", 1.0)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.emit({
		amount = 1, time = t, pos = at, vel = { x = 0, y = 0, z = 0 }, exptime = t + 0.05, size = 0.7,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add", grow = { 0.3, 1.0 }, alpha = 0.9 }),
		glow = 10,
	})
	F.inhale({ pos = at, tex = F.TEX.mote, colour = c.palette.core, radius = 0.6, amount = 6, time = t,
		size = { 0.06, 0.1 } })
end

-- The push: two speed lines leave the forehead, level with the head.
function R.melee(F, c)
	local at = F.anchor(c.user, "head", 1.0) or c.centre
	F.emit({
		amount = 2, time = 0.05, pos = at, vel = { min = vector.multiply(c.fwd, 5), max = vector.multiply(c.fwd, 7) },
		exptime = { min = 0.12, max = 0.2 }, size = { min = 0.45, max = 0.6 },
		texture = F.tex(F.tint("minemon_fx_speedline.png", c.palette.core), { blend = "add", fade = true }),
		glow = 10,
	})
end

-- The blow: a flash on the head and a dazed halo of stars, one new star on the ring every STEP_S for STEPS steps.
function R.impact(F, c)
	local victim = c.victim
	local head = victim and victim:get_pos() and F.anchor(victim, "head", 1.0)
	if not head then
		return
	end
	F.flare({ pos = head, colour = c.palette.core, size = 1.2, life = 0.14 })
	F.sound("mcl_criticals_hit.2", { pos = head, gain = 0.6, pitch = 1.1 })
	for step = 0, STEPS - 1 do
		core.after(step * STEP_S, function()
			for k = 0, STARS - 1 do
				local a = k / STARS * 2 * math.pi + step * 0.7
				local p = { x = head.x + math.cos(a) * RING_R, y = head.y + 0.08 * math.sin(2 * a),
					z = head.z + math.sin(a) * RING_R }
				F.emit({
					amount = 1, time = 0.02, pos = p, vel = { x = 0, y = 0, z = 0 }, exptime = 0.16, size = 0.36,
					texture = F.tex(F.tint(STAR, STAR_COLOUR), { blend = "add", fade = true, grow = { 0.8, 1.1 } }),
					glow = 10,
				})
			end
		end)
	end
end

minemon.fx.register_move("headbutt", R)
