-- Double Kick (M2.1, T-FX2-a): two kicks, one low and one high, 0.13 s apart. The idea is the rhythm: a low pulse
-- of orange light on the victim's shin, then, as the second foot arrives, a high pulse at the head. Each pulse is a
-- star and a small ring; the two rings are never on screen together. Weak (power 30): small and quick. Budget: cast
-- 8, melee 12, impact 30 particles over 0.2 s.
-- luacheck: read_globals core vector minemon

local R = {}

local GAP_S = 0.13
local STAR = "minemon_fx_impact_star.png"
local SPEED = "minemon_fx_speedline.png"

-- Wind-up: a glow flickers twice at the middle (two short pulses, the rhythm of what comes).
function R.cast(F, c)
	local at = F.anchor(c.user, "middle", 0.6, 0.4)
	if not at then
		return false
	end
	local t = math.max(0.12, c.time or 0.3)
	for i = 0, 1 do
		F.after(i * t / 2, function()
			F.emit({
				amount = 1, time = 0.02, pos = at, vel = { x = 0, y = 0, z = 0 }, exptime = t / 3, size = 0.7,
				texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add", fade = true, grow = { 0.6, 1.0 } }),
				glow = 14,
			})
		end)
	end
end

-- The first kick: a bar low on the floor. The second, after GAP_S: a bar at head height.
function R.melee(F, c)
	local feet = c.user:get_pos()
	if not feet then
		return
	end
	local low = vector.add(feet, { x = 0, y = 0.25, z = 0 })
	local high = vector.add(feet, { x = 0, y = 1.1, z = 0 })
	F.emit({
		amount = 2, time = 0.04, pos = low, vel = { min = vector.multiply(c.fwd, 5), max = vector.multiply(c.fwd, 7) },
		exptime = { min = 0.12, max = 0.2 }, size = { min = 0.5, max = 0.6 },
		texture = F.tex(F.tint(SPEED, c.palette.main), { blend = "add", fade = true }), glow = 14,
	})
	F.after(GAP_S, function()
		if not c.user:get_pos() then
			return
		end
		F.emit({
			amount = 2, time = 0.04, pos = high, vel = { min = vector.multiply(c.fwd, 5), max = vector.multiply(c.fwd, 7) },
			exptime = { min = 0.12, max = 0.2 }, size = { min = 0.5, max = 0.6 },
			texture = F.tex(F.tint(SPEED, c.palette.main), { blend = "add", fade = true }), glow = 14,
		})
	end)
end

-- One pulse at a point: a star, a small ring and a click.
local function pulse(F, c, at, pitch)
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = { x = 0, y = 0, z = 0 }, exptime = 0.18, size = 1.0,
		texture = F.tex(F.tint(STAR, c.palette.core), { blend = "add", fade = true, grow = { 0.6, 1.0 } }), glow = 14,
	})
	F.ring({ pos = at, colour = c.palette.main, size = 0.4, grow = 2.0, life = 0.2 })
	F.sound("default_dig_oddly_breakable_by_hand", { pos = at, gain = 0.5, pitch = pitch })
end

-- The victim takes two pulses: low on the shin, then high on the head.
function R.impact(F, c)
	local victim = c.victim
	local feet = victim and victim:get_pos()
	if not feet then
		return
	end
	local low = vector.add(feet, { x = 0, y = 0.35, z = 0 })
	local high = vector.add(feet, { x = 0, y = 1.0, z = 0 })
	pulse(F, c, low, 1.3)
	F.after(GAP_S, function()
		if victim:get_pos() then
			pulse(F, c, high, 1.6)
		end
	end)
end

minemon.fx.register_move("double_kick", R)
