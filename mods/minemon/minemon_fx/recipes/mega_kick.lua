-- Mega Kick (M2.1, T-FX2-a): a broad low sweep. The leg is drawn back as a thick arc of light behind the user's
-- knee; the kick is a wide smile-shaped arc of light that sweeps across the victim's legs at knee height, with a
-- row of dust kicked up along the floor. Strongest move of the group (power 120): big, slow, and it stops the
-- victim for 0.12 s. Budget: cast 12, melee 14, impact 34 particles.
-- luacheck: read_globals core vector minemon

local R = {}

-- The cast, melee and impact contexts differ: the cast and impact have no facing. The direction is the horizontal line
-- from the user to its target (cast) or victim (impact).
local function with_fwd(c)
	if c.fwd then
		return c
	end
	local other = c.victim or c.target
	local u, v = c.user:get_pos(), other and other:get_pos()
	local dx, dz = v and (v.x - u.x) or 1, v and (v.z - u.z) or 0
	local len = math.sqrt(dx * dx + dz * dz)
	local t = {}
	for k, val in pairs(c) do
		t[k] = val
	end
	t.fwd = len > 0.01 and { x = dx / len, y = 0, z = dz / len } or { x = 1, y = 0, z = 0 }
	return t
end


local ARC = "minemon_fx_arc_wide.png^[transformR90" -- turned to a low smile: it sweeps across the legs
local DUST = "minemon_fx_dust.png"
local ZERO = { x = 0, y = 0, z = 0 }

local function feet_of(obj)
	local p = obj:get_pos()
	return p and { x = p.x, y = p.y, z = p.z } or nil
end

-- Wind-up: the leg is drawn back. A faint arc forms behind the user, and dust is pressed into the floor under it.
function R.cast(F, c)
	c = with_fwd(c)
	local feet = feet_of(c.user)
	if not feet then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.emit({
		amount = 1, time = t, pos = vector.add(feet, { x = -c.fwd.x * 0.6, y = 0.45, z = -c.fwd.z * 0.6 }),
		vel = { x = 0, y = 0, z = 0 }, exptime = t + 0.05, size = 1.5,
		texture = F.tex(F.tint(ARC, c.palette.core), { blend = "add", grow = { 0.6, 1.0 }, alpha = 0.6 }), glow = 10,
	})
	F.inhale({ pos = vector.add(feet, { x = 0, y = 0.1, z = 0 }), tex = DUST, colour = c.palette.smoke, radius = 0.8,
		amount = 10, time = t, size = { 0.2, 0.3 } })
end

-- The sweep: the arc travels forward at knee height, and a low fan of dust is kicked along the floor in front.
function R.melee(F, c)
	local feet = feet_of(c.user)
	if not feet then
		return
	end
	F.emit({
		amount = 1, time = 0.02, pos = vector.add(feet, vector.add(vector.multiply(c.fwd, 0.7), { x = 0, y = 0.4, z = 0 })),
		vel = vector.multiply(c.fwd, 4), exptime = 0.24, size = 1.7,
		texture = F.tex(F.tint(ARC, c.palette.core), { blend = "add", fade = true, grow = { 0.8, 1.2 } }), glow = 10,
	})
	F.emit({
		amount = 6, time = 0.05, pos = vector.add(feet, { x = 0, y = 0.08, z = 0 }),
		vel = { min = vector.add(vector.multiply(c.fwd, 3), { x = -0.6, y = 0, z = -0.6 }),
			max = vector.add(vector.multiply(c.fwd, 5), { x = 0.6, y = 0.2, z = 0.6 }) },
		exptime = { min = 0.3, max = 0.5 }, size = { min = 0.3, max = 0.45 },
		texture = F.tex(F.tint(DUST, c.palette.smoke), { blend = "alpha", alpha = 0.6, fade = true }), glow = 0,
	})
end

-- The hit: a flash on the victim's legs, the arc again across them, a low shock of dust, and a heavy hit stop.
function R.impact(F, c)
	local victim = c.victim
	local feet = victim and feet_of(victim)
	if not feet then
		return
	end
	local knee = vector.add(feet, { x = 0, y = 0.4, z = 0 })
	F.emit({
		amount = 1, time = 0.02, pos = vector.add(feet, { x = 0, y = 0.35, z = 0 }), vel = ZERO, exptime = 0.3,
		size = 2.0, texture = F.tex(F.tint(ARC, "#ffffff"), { blend = "add", fade = true, grow = { 0.9, 1.2 } }),
		glow = 10,
	})
	F.emit({
		amount = 1, time = 0.02, pos = knee, vel = ZERO, exptime = 0.2, size = 1.8,
		texture = F.tex(F.tint("minemon_fx_impact_star.png", c.palette.core), { blend = "add", fade = true,
			grow = { 0.6, 1.1 } }), glow = 10,
	})
	for i = 0, 7 do
		local a = i / 8 * 2 * math.pi
		local dir = { x = math.cos(a), y = 0, z = math.sin(a) }
		F.emit({
			amount = 1, time = 0.02, pos = vector.add(feet, { x = 0, y = 0.1, z = 0 }),
			vel = vector.multiply(dir, 3), drag = { x = 0.9, y = 0.9, z = 0.9 },
			exptime = { min = 0.45, max = 0.7 }, size = { min = 0.5, max = 0.7 },
			texture = F.tex(F.tint(DUST, c.palette.smoke), { blend = "alpha", alpha = 0.6, fade = true,
				grow = { 0.8, 1.5 } }), glow = 0,
		})
	end
	F.hitstop({ victim, c.user }, 0.12)
	F.sound("mcl_criticals_hit.2", { pos = knee, gain = 0.9, pitch = 0.7 })
end

minemon.fx.register_move("mega_kick", R)
