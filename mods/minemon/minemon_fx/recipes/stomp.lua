-- Stomp (M2.1, T-FX2-a): a drop from above. The wind-up is a dark shadow on the ground under the victim (a decal
-- that stays for a moment). In the blow, two heavy blobs of dust fall out of the air onto the victim's head. The
-- splash is delayed 0.28 s, as long as the fall takes, and then it is a plume of dust rising from the feet and a
-- few chips that bounce: up, not out (Body Slam is the flat one). Strong-ish (power 65), flinch 30%. Budget: cast 6
-- + 1 decal, melee 12, impact 40 particles.
-- luacheck: read_globals core vector minemon

local R = {}

local DUST = "minemon_fx_dust.png"
local CHIP = "minemon_fx_chip.png"
local FALL_S = 0.28

local function feet_of(obj)
	local p = obj:get_pos()
	return p and { x = p.x, y = p.y + 0.05, z = p.z } or nil
end

-- Wind-up: a shadow forms on the ground under the victim, the place the foot will land.
function R.cast(F, c)
	local feet = feet_of(c.target)
	if not feet then
		return false
	end
	local t = math.max(0.15, c.time or 0.3)
	F.decal({ pos = feet, tex = DUST .. "^[multiply:#2a2420", size = 1.6, life = t + FALL_S + 0.4 })
end

-- The foot: two heavy blobs of dust drop out of the air above the victim's head.
function R.melee(F, c)
	local feet = feet_of(c.target)
	if not feet then
		return
	end
	local top = vector.add(feet, { x = 0, y = 2.3, z = 0 })
	for _, dx in ipairs({ -0.2, 0.2 }) do
		F.emit({
			amount = 1, time = 0.02, pos = vector.add(top, { x = dx, y = 0, z = 0 }),
			vel = { x = 0, y = -7.5, z = 0 }, exptime = 0.34, size = 0.7,
			texture = F.tex(F.tint(DUST, c.palette.smoke), { blend = "alpha", alpha = 0.9, grow = { 0.9, 1.1 } }),
			glow = 0,
		})
	end
	F.emit({
		amount = 6, time = 0.1, pos = { min = vector.add(top, { x = -0.3, y = 0, z = -0.3 }),
			max = vector.add(top, { x = 0.3, y = 0, z = 0.3 }) },
		vel = { x = 0, y = -7, z = 0 }, exptime = { min = 0.3, max = 0.4 }, size = { min = 0.3, max = 0.45 },
		texture = F.tex(F.tint(DUST, c.palette.smoke), { blend = "alpha", alpha = 0.6, fade = true }), glow = 0,
	})
end

-- The splash, FALL_S after the blow: a ring on the ground, a plume of dust rising, and chips that bounce.
function R.impact(F, c)
	local victim = c.victim
	if not (victim and victim:get_pos()) then
		return
	end
	core.after(FALL_S, function()
		local feet = feet_of(victim)
		if not feet then
			return
		end
		F.ring({ pos = vector.add(feet, { x = 0, y = 0.1, z = 0 }), colour = c.palette.main, size = 0.7, grow = 3.0,
			life = 0.35 })
		F.smoke({ pos = feet, colour = c.palette.smoke, amount = 8, size = { 0.5, 0.8 }, life = { 0.9, 1.4 },
			rise = 1.4, spread = 0.35, time = 0.15, alpha = 0.6 })
		F.emit({
			amount = 4, time = 0.04, pos = feet, radius = { min = 0.05, max = 0.2, bias = 0 },
			vel = { min = { x = -1.5, y = 1.5, z = -1.5 }, max = { x = 1.5, y = 3.2, z = 1.5 } },
			acc = { x = 0, y = -9, z = 0 }, collisiondetection = true, bounce = { min = 0.2, max = 0.4 },
			exptime = { min = 0.5, max = 0.9 }, size = { min = 0.12, max = 0.2 },
			texture = F.tex(F.tint(CHIP, c.palette.smoke), { blend = "alpha", fade = { 1, 0.5 } }), glow = 0,
		})
		F.sound("default_gravel_dig", { pos = feet, gain = 1.0, pitch = 0.7 })
	end)
end

minemon.fx.register_move("stomp", R)
