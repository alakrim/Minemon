-- Smokescreen (M2.1 T-FX2-C, status, normal, accuracy -1): a smoke bomb. It pops at the user's feet and a low bank of
-- grey smoke rolls out along the ground in a flat ring, round the target and past it, with a second ring of smoke
-- behind the first. Smoke that spreads flat and wide, not up: the look is a wall at knee height. Budget: smoke at most
-- 0.7 per particle and a vertical speed of about 0.1 (docs/ART_GUIDE.md 4 and the M2.1 review).
-- luacheck: read_globals core vector minemon

local R = {}

local ZERO = { x = 0, y = 0, z = 0 }

-- Cast: a smoke bomb pops at the user's feet; a little grey puff rolls off towards the target.
function R.cast(F, c)
	if not (c.user and c.user:get_pos()) then
		return false
	end
	local feet = vector.add(c.user:get_pos(), { x = 0, y = 0.3, z = 0 })
	local dir = { x = 0, y = 0, z = 0 }
	if c.target and c.target:get_pos() then
		dir = vector.normalize({ x = c.target:get_pos().x - feet.x, y = 0, z = c.target:get_pos().z - feet.z })
	end
	F.emit({
		amount = 8, time = 0.3, pos = feet, radius = { min = 0.2, max = 0.4, bias = 0 },
		vel = { min = vector.multiply(dir, 0.6), max = vector.multiply(dir, 1.0) },
		drag = { x = 0.4, y = 0.4, z = 0.4 }, exptime = { min = 0.8, max = 1.2 }, size = { min = 0.7, max = 0.95 },
		texture = F.tex(F.tint(F.TEX.smoke, c.palette.smoke), { blend = "alpha", alpha = 0.8, anim = "smoke" }),
	})
	F.sound("default_dig_crumbly", { pos = feet, gain = 0.3, pitch = 0.6 })
end

-- Cloud: a bank of grey smoke rolls out flat from the target's knees, and a second bank follows it out.
function R.cloud(F, c)
	local low = vector.add(c.centre, { x = 0, y = -0.15, z = 0 })
	F.burst({ pos = low, tex = F.TEX.smoke, anim = "smoke", colour = c.palette.smoke, blend = "alpha", amount = 26,
		speed = 1.0, radius = 0.3, life = { 1.8, 2.4 }, size = { 0.7, 0.95 }, grow = { 0.8, 1.6 }, gravity = 0,
		glow = 0 })
	F.ring({ pos = low, colour = c.palette.smoke, size = 0.6, grow = 4.0, life = 0.8 })
	F.after(0.6, function()
		F.burst({ pos = low, tex = F.TEX.smoke, anim = "smoke", colour = c.palette.smoke, blend = "alpha", amount = 14,
			speed = 0.8, radius = 0.3, life = { 1.6, 2.2 }, size = { 0.5, 0.7 }, grow = { 0.8, 1.5 }, glow = 0 })
		F.ring({ pos = low, colour = c.palette.main, size = 0.6, grow = 4.0, life = 0.9 })
	end)
	F.emit({
		amount = 1, time = 0.02, pos = low, vel = ZERO, exptime = c.time or 3, size = 1.3,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.smoke), { blend = "alpha", alpha = 0.25, grow = { 0.8, 1.2 } }),
		glow = 0,
	})
end

minemon.fx.register_move("smokescreen", R)
