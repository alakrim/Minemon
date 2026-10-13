-- Take Down (M2.1, T-FX2-a): a horizontal crack. A bar of white light is drawn across the user's chest as it
-- braces, the shoulder carries a pair of bars forward, and on the victim a single wide white bar splits across the
-- chest, with three chips flung off the crack and bouncing. Heavy (power 90): the bar is long and it holds. Budget:
-- cast 12, melee 12, impact 40 particles.
-- luacheck: read_globals core vector minemon

local R = {}

local BAR = "minemon_fx_speedline.png"
local CHIP = "minemon_fx_chip.png"
local DUST = "minemon_fx_dust.png"

-- Wind-up: a bar of light grows across the chest and the motes gather into it.
function R.cast(F, c)
	local at = F.anchor(c.user, "middle", 0.6, 0.0)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.emit({
		amount = 1, time = t, pos = at, vel = { x = 0, y = 0, z = 0 }, exptime = t + 0.05, size = 1.0,
		texture = F.tex(F.tint(BAR, c.palette.core), { blend = "add", grow = { 0.3, 1.0 }, alpha = 0.8 }),
		glow = 10,
	})
end

-- The shoulder: two bars travel forward with the body.
function R.melee(F, c)
	for _, dy in ipairs({ 0.12, -0.12 }) do
		F.emit({
			amount = 1, time = 0.02, pos = vector.add(c.centre, { x = 0, y = dy, z = 0 }),
			vel = vector.multiply(c.fwd, 6), exptime = 0.18, size = 1.0,
			texture = F.tex(F.tint(BAR, c.palette.core), { blend = "add", fade = true, grow = { 1, 0.7 } }),
			glow = 10,
		})
	end
end

-- The crack: one wide bar across the victim's chest, three chips off it, and a little dust at the feet.
function R.impact(F, c)
	local at = c.pos
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = { x = 0, y = 0, z = 0 }, exptime = 0.26, size = 1.6,
		texture = F.tex(F.tint(BAR, "#ffffff"), { blend = "add", fade = true, grow = { 0.5, 1.2 } }), glow = 10,
	})
	F.flare({ pos = at, colour = c.palette.core, size = 1.0, life = 0.12 })
	F.emit({
		amount = 3, time = 0.03, pos = at,
		vel = { min = { x = -2.2, y = 0.8, z = -1.2 }, max = { x = 2.2, y = 2.6, z = 1.2 } },
		acc = { x = 0, y = -9, z = 0 }, collisiondetection = true, bounce = { min = 0.2, max = 0.35 },
		exptime = { min = 0.5, max = 0.8 }, size = { min = 0.13, max = 0.2 },
		texture = F.tex(F.tint(CHIP, c.palette.smoke), { blend = "alpha", fade = { 1, 0.4 } }), glow = 0,
	})
	local feet = c.victim and c.victim:get_pos()
	if feet then
		F.emit({
			amount = 6, time = 0.04, pos = { min = vector.add(feet, { x = -0.3, y = 0.05, z = -0.3 }),
				max = vector.add(feet, { x = 0.3, y = 0.1, z = 0.3 }) },
			vel = { min = { x = -1.2, y = 0, z = -1.2 }, max = { x = 1.2, y = 0.25, z = 1.2 } },
			exptime = { min = 0.4, max = 0.7 }, size = { min = 0.4, max = 0.6 },
			texture = F.tex(F.tint(DUST, c.palette.smoke), { blend = "alpha", alpha = 0.65, fade = true }),
			glow = 0,
		})
	end
	F.sound("mcl_criticals_hit.0", { pos = at, gain = 0.8, pitch = 0.8 })
end

minemon.fx.register_move("take_down", R)
