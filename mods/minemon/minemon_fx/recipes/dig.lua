-- Dig (M2.1, T-FX2-a): a dirt fountain. The user digs in: a dark hole is pressed into the ground under its feet
-- (decal, the wind-up) and loose dirt pops up round the hole. In the blow, a scoop of real dirt blocks is flung out
-- of the hole in a low arc toward the victim, and where it lands a fountain of dirt jumps up from the victim's
-- feet. The dirt is node particles (the real block's texture), so it reads as the ground itself. Strong (power 60).
-- Budget: cast 6 + 1 decal, melee 8, impact 16 node particles and dust.
-- luacheck: read_globals core vector minemon

local R = {}

local DIRT = { name = "mcl_core:dirt" } -- real blocks: node particles take their texture from the node
local HOLE = "minemon_fx_crater.png^[multiply:#2e2016"
local DUST = "minemon_fx_dust.png"

local function feet_of(obj)
	local p = obj:get_pos()
	return p and { x = p.x, y = p.y + 0.05, z = p.z } or nil
end

-- Wind-up: a dark hole is pressed into the ground under the user, and a few dirt blocks pop up round it.
function R.cast(F, c)
	local feet = feet_of(c.user)
	if not feet then
		return false
	end
	local t = math.max(0.15, c.time or 0.3)
	F.decal({ pos = feet, tex = HOLE, size = 1.1, life = 6 })
	F.emit({
		amount = 4, time = t, pos = { min = vector.add(feet, { x = -0.25, y = 0, z = -0.25 }),
			max = vector.add(feet, { x = 0.25, y = 0.1, z = 0.25 }) },
		vel = { min = { x = -0.5, y = 1.5, z = -0.5 }, max = { x = 0.5, y = 2.5, z = 0.5 } },
		acc = { x = 0, y = -9, z = 0 }, collisiondetection = true, exptime = { min = 0.4, max = 0.6 },
		size = { min = 0.12, max = 0.16 }, node = DIRT,
	})
end

-- The scoop: dirt blocks come out of the hole and arc over the ground toward the victim.
function R.melee(F, c)
	local feet = feet_of(c.user)
	if not feet then
		return
	end
	F.emit({
		amount = 8, time = 0.08, pos = { min = vector.add(feet, { x = -0.15, y = 0, z = -0.15 }),
			max = vector.add(feet, { x = 0.15, y = 0.1, z = 0.15 }) },
		vel = { min = vector.add(vector.multiply(c.fwd, 3), { x = -0.8, y = 3.5, z = -0.8 }),
			max = vector.add(vector.multiply(c.fwd, 5), { x = 0.8, y = 5.0, z = 0.8 }) },
		acc = { x = 0, y = -9, z = 0 }, collisiondetection = true, bounce = { min = 0.15, max = 0.3 },
		exptime = { min = 0.4, max = 0.7 }, size = { min = 0.12, max = 0.16 }, node = DIRT,
	})
	F.emit({
		amount = 3, time = 0.08, pos = feet,
		vel = { min = vector.multiply(c.fwd, 1), max = vector.multiply(c.fwd, 2) },
		exptime = { min = 0.4, max = 0.6 }, size = { min = 0.4, max = 0.55 },
		texture = F.tex(F.tint(DUST, c.palette.smoke), { blend = "alpha", alpha = 0.55, fade = true }), glow = 0,
	})
end

-- The fountain: where the dirt lands, it jumps up from the victim's feet, falls back and bounces. Half a second
-- later it has come down, so the dirt is only in the air for about a second.
function R.impact(F, c)
	local victim = c.victim
	if not (victim and victim:get_pos()) then
		return
	end
	F.after(0.14, function()
		local feet = feet_of(victim)
		if not feet then
			return
		end
		F.emit({
			amount = 14, time = 0.04, pos = { min = vector.add(feet, { x = -0.25, y = 0, z = -0.25 }),
				max = vector.add(feet, { x = 0.25, y = 0.1, z = 0.25 }) },
			vel = { min = { x = -1.2, y = 4.5, z = -1.2 }, max = { x = 1.2, y = 7.0, z = 1.2 } },
			acc = { x = 0, y = -9, z = 0 }, collisiondetection = true, bounce = { min = 0.2, max = 0.4 },
			exptime = { min = 0.8, max = 1.2 }, size = { min = 0.12, max = 0.16 }, node = DIRT,
		})
		F.emit({
			amount = 4, time = 0.05, pos = feet,
			vel = { min = { x = -0.8, y = 0.2, z = -0.8 }, max = { x = 0.8, y = 0.6, z = 0.8 } },
			exptime = { min = 0.5, max = 0.8 }, size = { min = 0.45, max = 0.6 },
			texture = F.tex(F.tint(DUST, c.palette.smoke), { blend = "alpha", alpha = 0.6, fade = true }), glow = 0,
		})
		F.sound("default_dig_crumbly", { pos = feet, gain = 0.9, pitch = 0.9 })
	end)
	F.flare({ pos = c.pos, colour = c.palette.core, size = 0.7, life = 0.1 })
end

minemon.fx.register_move("dig", R)
