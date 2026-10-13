-- Low Kick (M2.1, T-FX2-a): a sweep of the legs. Two bars of orange light run along the floor at ankle height from
-- the user's foot (melee), and on the victim's shin a star flashes; the victim's feet are swept away from each
-- other, shown as two skids of light and dust sliding out sideways over the ground. The whole look is low: nothing
-- above the knee. Budget: cast 10, melee 10, impact 28 particles.
-- luacheck: read_globals core vector minemon

local R = {}

local SPEED = "minemon_fx_speedline.png"
local DUST = "minemon_fx_dust.png"

local function feet_of(obj)
	local p = obj:get_pos()
	return p and { x = p.x, y = p.y, z = p.z } or nil
end

-- Wind-up: a glow swells at the ankle and the dust under the foot is pressed in.
function R.cast(F, c)
	local feet = feet_of(c.user)
	if not feet then
		return false
	end
	local t = math.max(0.15, c.time or 0.3)
	local ankle = vector.add(feet, vector.add(vector.multiply(c.fwd, 0.25), { x = 0, y = 0.15, z = 0 }))
	F.emit({
		amount = 1, time = t, pos = ankle, vel = { x = 0, y = 0, z = 0 }, exptime = t + 0.05, size = 0.8,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add", grow = { 0.4, 1.0 }, alpha = 0.8 }),
		glow = 14,
	})
	F.inhale({ pos = ankle, tex = SPEED, colour = c.palette.main, radius = 0.6, amount = 8, time = t,
		size = { 0.14, 0.22 } })
end

-- The sweep: two bars run low along the floor from the foot, at ankle height and just above it.
function R.melee(F, c)
	local feet = feet_of(c.user)
	if not feet then
		return
	end
	for _, dy in ipairs({ 0.14, 0.3 }) do
		F.emit({
			amount = 2, time = 0.05, pos = vector.add(feet, { x = 0, y = dy, z = 0 }),
			vel = { min = vector.multiply(c.fwd, 5), max = vector.multiply(c.fwd, 7) },
			exptime = { min = 0.15, max = 0.25 }, size = { min = 0.5, max = 0.65 },
			texture = F.tex(F.tint(SPEED, c.palette.main), { blend = "add", fade = true }), glow = 14,
		})
	end
end

-- The hit: a star on the shin, then the feet slide apart over the ground: two skids of light and a little dust.
function R.impact(F, c)
	local victim = c.victim
	local feet = victim and feet_of(victim)
	if not feet then
		return
	end
	local shin = vector.add(feet, { x = 0, y = 0.3, z = 0 })
	F.emit({
		amount = 1, time = 0.02, pos = shin, vel = { x = 0, y = 0, z = 0 }, exptime = 0.2, size = 1.2,
		texture = F.tex(F.tint("minemon_fx_impact_star.png", c.palette.core), { blend = "add", fade = true,
			grow = { 0.6, 1.1 } }), glow = 14,
	})
	local across = { x = -c.fwd.z, y = 0, z = c.fwd.x }
	for _, side in ipairs({ 1, -1 }) do
		local dir = vector.multiply(across, side)
		F.emit({
			amount = 2, time = 0.05, pos = vector.add(feet, { x = 0, y = 0.08, z = 0 }),
			vel = { min = vector.multiply(dir, 3), max = vector.multiply(dir, 4.5) },
			drag = { x = 0.5, y = 0.5, z = 0.5 }, exptime = { min = 0.3, max = 0.45 }, size = { min = 0.5, max = 0.7 },
			texture = F.tex(F.tint(SPEED, c.palette.main), { blend = "add", fade = true }), glow = 14,
		})
		F.emit({
			amount = 4, time = 0.05, pos = vector.add(feet, { x = 0, y = 0.05, z = 0 }),
			vel = { min = vector.multiply(dir, 1.5), max = vector.multiply(dir, 2.6) },
			drag = { x = 0.6, y = 0.6, z = 0.6 }, exptime = { min = 0.35, max = 0.55 }, size = { min = 0.35, max = 0.5 },
			texture = F.tex(F.tint(DUST, c.palette.smoke), { blend = "alpha", alpha = 0.6, fade = true }), glow = 0,
		})
	end
	F.sound("default_dig_oddly_breakable_by_hand", { pos = shin, gain = 0.8, pitch = 0.9 })
end

minemon.fx.register_move("low_kick", R)
