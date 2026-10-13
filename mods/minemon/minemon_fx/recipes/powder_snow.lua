-- Powder Snow (M2.1 wave 2, group B, power 40, freeze 10%, area): a puff of fine snow. Crystals drift down out of the
-- air over the victim in a soft cloud (they fall; nothing rises, so the area stays low and clear of the camera); a
-- faint pale mist hangs at the feet; on the hit a small frost star flashes on the victim and a few flakes drift off it.
-- Weak: small and quick. The area is the look: a falling dusting, not a ring (Ice's area is a frost ring).
-- Budget at "high": area ~70, impact ~24.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	frost = "minemon_fx_frost.png",
	star = "minemon_fx_impact_star.png",
	glow = "minemon_fx_glow.png",
}
local ZERO = { x = 0, y = 0, z = 0 }

-- The dusting: fine crystals fall over the area from above, slowly, and a pale mist hangs low.
function R.area(F, c)
	local r = math.min(c.radius * 0.6, 2.4)
	local ctr = c.centre
	F.emit({
		amount = 34, time = 0.6,
		pos = { min = vector.subtract(ctr, { x = r, y = -1.2, z = r }), max = vector.add(ctr, { x = r, y = 0.8, z = r }) },
		vel = { min = { x = -0.2, y = -0.4, z = -0.2 }, max = { x = 0.2, y = -0.7, z = 0.2 } },
		drag = { x = 0.6, y = 0.3, z = 0.6 }, exptime = { min = 1.2, max = 1.9 }, size = { min = 0.1, max = 0.16 },
		texture = F.tex(F.tint(TEX.frost, c.palette.core), { blend = "alpha", fade = { 1, 0.3 } }), glow = 6,
	})
	F.emit({
		amount = 8, time = 0.8,
		pos = { min = vector.subtract(ctr, { x = r, y = 1.6, z = r }), max = vector.add(ctr, { x = r, y = 1.8, z = r }) },
		vel = ZERO, exptime = { min = 1.2, max = 1.8 }, size = { min = 0.42, max = 0.6 },
		texture = F.tex(F.tint(TEX.glow, c.palette.smoke), { blend = "alpha", alpha = 0.25, fade = true }), glow = 0,
	})
	F.sound("default_glass_footstep", { pos = ctr, gain = 0.3, pitch = 1.8 })
end

-- The flash: a frost star on the victim, a white catch light and a few flakes that drift off it.
function R.impact(F, c)
	local at = c.pos
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.22, size = 1.0,
		texture = F.tex(F.tint(TEX.star, c.palette.main), { blend = "add", fade = true, grow = { 0.6, 1.1 } }),
		glow = 10,
	})
	F.emit({
		amount = 8, time = 0.1, pos = at,
		vel = { min = { x = -0.8, y = -0.2, z = -0.8 }, max = { x = 0.8, y = 0.5, z = 0.8 } },
		exptime = { min = 0.5, max = 0.8 }, size = { min = 0.1, max = 0.15 },
		texture = F.tex(F.tint(TEX.frost, c.palette.core), { blend = "alpha", fade = true }), glow = 6,
	})
	F.sound("default_glass_footstep", { pos = at, gain = 0.4, pitch = 1.4 })
end

minemon.fx.register_move("powder_snow", R)
