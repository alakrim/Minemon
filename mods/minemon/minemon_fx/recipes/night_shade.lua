-- Night Shade (signature, M2.1 T-FX-c): a beam of void. A thick dark stream runs from the user to the target with
-- wisps riding it, and where it lands the void bursts out and leaves a violet stain. The beam and the impact are
-- this move's own; the wind-up, launch and the rest come from recipes/type_ghost.lua.
-- Totals at "high": beam ~130, impact ~70.
-- luacheck: read_globals core vector minemon

local R = {}

local ZERO = { x = 0, y = 0, z = 0 }
local WISP = "minemon_fx_wisp.png"
local VOID_TINT = "#7a6a90"

local function void(F, alpha)
	return F.tex(F.tint(F.TEX.smoke, VOID_TINT), { blend = "sub", alpha = alpha or 0.55, anim = "smoke" })
end

function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 26
	local dir = vector.multiply(d, 1 / len)
	-- The thick void: two layers of dark puffs, wider than the type's, so the beam reads as a hole in the light.
	F.emit({
		amount = 50, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = { min = 0.8, max = 1.1 }, texture = void(F, 0.6),
	}, c.from)
	F.emit({
		amount = 30, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = { min = 0.5, max = 0.7 }, texture = void(F, 0.35),
	}, c.from)
	-- Wisps that spiral off the stream and fade.
	F.emit({
		amount = 40, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed * 0.7),
		jitter = { min = { x = -0.5, y = -0.3, z = -0.5 }, max = { x = 0.5, y = 0.3, z = 0.5 } },
		exptime = { min = len / (speed * 0.7), max = len / (speed * 0.7) + 0.2 }, size = { min = 0.35, max = 0.55 },
		texture = F.tex(F.tint(WISP, c.palette.main), { blend = "add", fade = true }), glow = 8,
	}, c.from)
	F.emit({
		amount = 24, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = { min = 0.12, max = 0.2 }, texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add" }),
		glow = 10,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.core, size = 1.0 })
	F.flare({ pos = c.to, colour = c.palette.core, size = 1.2, life = 0.35 })
	F.ring({ pos = c.to, colour = c.palette.edge, size = 0.5, grow = 3.0, life = 0.4 })
	F.emit({
		amount = 10, time = 0.2, pos = c.to, vel = ZERO, exptime = { min = 0.5, max = 0.8 },
		size = { min = 0.9, max = 1.2 }, texture = void(F, 0.5),
	})
end

-- Impact: the void bursts out in two waves, wisps spill from it and cling to the victim, and a broad stain stays
-- on the ground for 6 s.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.4, life = 0.14 })
	F.burst({ pos = at, tex = F.TEX.smoke, anim = "smoke", colour = VOID_TINT, blend = "sub", amount = 18, speed = 3,
		life = { 0.7, 1.2 }, size = { 0.9, 1.3 }, glow = 0 })
	F.burst({ pos = at, tex = F.TEX.smoke, anim = "smoke", colour = VOID_TINT, blend = "sub", amount = 12, speed = 1.5,
		life = { 0.8, 1.3 }, size = { 1.0, 1.4 }, glow = 0 })
	F.burst({ pos = at, tex = WISP, colour = c.palette.main, amount = 20, speed = 4, life = { 0.8, 1.4 },
		size = { 0.35, 0.55 }, gravity = -0.4 })
	F.ring({ pos = at, colour = c.palette.main, size = 0.5, grow = 3.2, life = 0.45 })
	if c.victim and c.victim:get_pos() then
		F.on(c.victim, {
			amount = 18, time = 1.0,
			pos = { min = { x = -0.3, y = 0.1, z = -0.3 }, max = { x = 0.3, y = 1.1, z = 0.3 } },
			vel = { min = { x = -0.1, y = 0.1, z = -0.1 }, max = { x = 0.1, y = 0.5, z = 0.1 } },
			exptime = { min = 0.9, max = 1.3 }, size = { min = 0.35, max = 0.55 },
			texture = F.tex(F.tint(WISP, c.palette.main), { blend = "add", fade = true }), glow = 8,
		})
	end
	F.decal({ pos = at, tex = F.tint(F.TEX.dust, c.palette.smoke), size = 2.6, life = 6 })
	F.sound("mobs_mc_enderman_hurt.2", { pos = at, gain = 0.7, pitch = 0.5 })
end

minemon.fx.register_move("night_shade", R)
