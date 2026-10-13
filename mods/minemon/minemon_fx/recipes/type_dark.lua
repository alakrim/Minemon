-- Dark (type default, M2.1 T-FX-c): shadow tendrils that lash out and curl, black smoke that eats the light (a
-- subtractive puff, blend "sub") and red glints in the dark. Silhouette: strands that whip and sway, not a ball.
-- Palette (fx_logic.PALETTE): core #e8d8f0, main #7a5a8a, edge #2a1a30, smoke #141018. The glints are #ff3030.
-- Budgets: docs/ART_GUIDE.md 4. Totals at "high": cast ~45, launch ~35, projectile ~35/s, impact ~75.
-- luacheck: read_globals core vector minemon

local R = {}

local ZERO = { x = 0, y = 0, z = 0 }
local TENDRIL = "minemon_fx_tendril.png" -- a shadow strand (tools/gen_fx_textures_c.py)
local SHADE = "#2a1a30"
local GLINT = "#ff3030"
local VOID_TINT = "#6a5a78"

local function strand(F, alpha)
	return F.tex(F.tint(TENDRIL, SHADE), { blend = "alpha", fade = true, alpha = alpha })
end

local function glint(F)
	return F.tex(F.tint(F.TEX.spark, GLINT), { blend = "add", fade = true })
end

-- Cast: shadow is drawn into the mouth by a sub-blend pull; strands lick out of it and a red glint swells.
function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.5)
	F.emit({
		amount = 16, time = t, pos = at, radius = { min = 0.7, max = 1.0, bias = 0 },
		attract = { kind = "point", origin = at, strength = { min = 2.5, max = 3.5 }, die_on_contact = true },
		vel = ZERO, exptime = { min = 0.25, max = 0.45 }, size = { min = 0.25, max = 0.4 },
		texture = F.tex(F.tint(F.TEX.smoke, VOID_TINT), { blend = "sub", alpha = 0.6, anim = "smoke" }),
	})
	F.emit({
		amount = 6, time = t, pos = at, vel = { min = { x = -0.3, y = 0.3, z = -0.3 }, max = { x = 0.3, y = 0.9, z = 0.3 } },
		exptime = { min = 0.3, max = 0.5 }, size = { min = 0.4, max = 0.6 }, vertical = true, glow = 0,
		texture = strand(F, 0.8),
	})
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t + 0.05, size = 0.5,
		texture = F.tex(F.tint(F.TEX.glow, GLINT), { blend = "add", grow = { 0.2, 0.8 }, alpha = 0.6 }), glow = 14,
	})
	F.sound("mobs_mc_wolf_hurt.2", { pos = at, gain = 0.35, pitch = 0.5 })
end

-- Launch: a black puff at the muzzle, a red flash and a spray of glints.
function R.launch(F, c)
	F.emit({
		amount = 8, time = 0.05, pos = c.from,
		vel = { min = vector.multiply(c.dir, 0.5), max = vector.multiply(c.dir, 2) },
		exptime = { min = 0.4, max = 0.7 }, size = { min = 0.5, max = 0.8 },
		texture = F.tex(F.tint(F.TEX.smoke, c.palette.smoke), { blend = "alpha", alpha = 0.7, anim = "smoke" }),
	})
	F.flare({ pos = c.from, colour = GLINT, size = 0.9, life = 0.12 })
	F.emit({
		amount = 10, time = 0.05, pos = c.from,
		vel = { min = vector.multiply(c.dir, 2), max = vector.add(vector.multiply(c.dir, 6), { x = 0, y = 1, z = 0 }) },
		exptime = { min = 0.2, max = 0.4 }, size = { min = 0.07, max = 0.12 }, texture = glint(F), glow = 14,
	})
	F.sound("mobs_mc_wolf_hurt.1", { pos = c.from, gain = 0.5, pitch = 0.7 })
end

-- The orb: a dark body with strands that whip off it, a sub-blend shadow and red glints.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(F.TEX.glow, "#5a4a6a") }, visual_size = { x = 0.6, y = 0.6 } })
	F.on(c.obj, {
		amount = 14, time = 1.5, pos = { min = { x = -0.1, y = -0.1, z = -0.1 }, max = { x = 0.1, y = 0.1, z = 0.1 } },
		vel = { min = { x = -0.2, y = 0, z = -0.2 }, max = { x = 0.2, y = 0.4, z = 0.2 } },
		exptime = { min = 0.4, max = 0.7 }, size = { min = 0.5, max = 0.9 }, vertical = true, glow = 0,
		texture = strand(F, 0.9),
	})
	F.on(c.obj, {
		amount = 10, time = 1.5, pos = { min = { x = -0.1, y = -0.1, z = -0.1 }, max = { x = 0.1, y = 0.1, z = 0.1 } },
		vel = { min = { x = -0.1, y = 0, z = -0.1 }, max = { x = 0.1, y = 0.2, z = 0.1 } },
		exptime = { min = 0.6, max = 0.9 }, size = { min = 0.6, max = 0.9 },
		texture = F.tex(F.tint(F.TEX.smoke, VOID_TINT), { blend = "sub", alpha = 0.5, anim = "smoke" }),
	})
	F.on(c.obj, {
		amount = 10, time = 1.5, pos = ZERO,
		vel = { min = { x = -0.7, y = -0.7, z = -0.7 }, max = { x = 0.7, y = 0.7, z = 0.7 } },
		exptime = { min = 0.2, max = 0.4 }, size = { min = 0.07, max = 0.12 }, texture = glint(F), glow = 14,
	})
	return true
end

-- Beam: a sub-blend shadow stream with red glints riding it; strands lash out where it lands.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 30
	local dir = vector.multiply(d, 1 / len)
	F.emit({
		amount = 40, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = { min = 0.6, max = 0.9 },
		texture = F.tex(F.tint(F.TEX.smoke, VOID_TINT), { blend = "sub", alpha = 0.6, anim = "smoke" }),
	}, c.from)
	F.emit({
		amount = 26, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = { min = 0.08, max = 0.12 }, texture = glint(F), glow = 14,
	}, c.from)
	F.flare({ pos = c.from, colour = GLINT, size = 0.9 })
	F.flare({ pos = c.to, colour = GLINT, size = 1.1, life = 0.3 })
	F.burst({ pos = c.to, tex = TENDRIL, colour = SHADE, blend = "alpha", amount = 10, speed = 3,
		life = { 0.3, 0.5 }, size = { 0.5, 0.8 }, glow = 0 })
end

-- Melee: five strands swept forward across the arc, and a spray of glints at its centre.
function R.melee(F, c)
	for i = -2, 2 do
		local bulge = 0.45 - 0.08 * math.abs(i)
		local p = vector.add(c.centre, { x = c.fwd.x * bulge, y = i * 0.22, z = c.fwd.z * bulge })
		F.emit({
			amount = 4, time = 0.12, pos = p, vel = vector.multiply(c.fwd, 2), exptime = { min = 0.2, max = 0.35 },
			size = { min = 0.5, max = 0.7 }, vertical = true, glow = 0, texture = strand(F, 0.9),
		})
	end
	F.emit({
		amount = 6, time = 0.1, pos = c.centre, vel = { min = { x = -1, y = -1, z = -1 }, max = { x = 1, y = 1, z = 1 } },
		exptime = { min = 0.15, max = 0.3 }, size = { min = 0.07, max = 0.12 }, texture = glint(F), glow = 14,
	})
end

-- Area: a shadow eruption. Black puffs billow out across the area, strands whip out between them, and a red ring
-- runs round the edge.
function R.area(F, c)
	local r = c.radius or 3
	F.burst({ pos = c.centre, tex = F.TEX.smoke, anim = "smoke", colour = c.palette.smoke, blend = "alpha",
		amount = 22, speed = r, radius = 0.4, life = { 0.7, 1.2 }, size = { 0.8, 1.1 }, glow = 0 })
	F.burst({ pos = c.centre, tex = TENDRIL, colour = SHADE, blend = "alpha", amount = 14, speed = r * 1.4,
		life = { 0.5, 0.9 }, size = { 0.6, 0.9 }, glow = 0 })
	F.burst({ pos = c.centre, tex = F.TEX.spark, colour = GLINT, amount = 16, speed = r * 1.2, life = { 0.3, 0.6 },
		size = { 0.08, 0.14 } })
	F.ring({ pos = c.centre, colour = GLINT, size = 0.5, grow = r * 2 / 0.5, life = 0.45 })
	F.sound("mobs_mc_wolf_hurt.3", { pos = c.centre, gain = 0.6, pitch = 0.5 })
end

-- Impact: a red flash, black smoke rising, strands that burst out and wrap the victim, red glints and a black stain
-- on the ground for 6 s.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = GLINT, size = 1.2, life = 0.12 })
	F.smoke({ pos = at, colour = c.palette.smoke, amount = 8, size = { 0.6, 0.9 }, life = { 1.0, 1.5 }, alpha = 0.85,
		rise = 0.8, time = 0.3 })
	F.burst({ pos = at, tex = TENDRIL, colour = SHADE, blend = "alpha", amount = 16, speed = 4,
		life = { 0.4, 0.7 }, size = { 0.6, 0.9 }, glow = 0 })
	F.burst({ pos = at, tex = F.TEX.spark, colour = GLINT, amount = 20, speed = 4, life = { 0.3, 0.6 },
		size = { 0.08, 0.14 } })
	if c.victim and c.victim:get_pos() then
		F.on(c.victim, {
			amount = 10, time = 0.6,
			pos = { min = { x = -0.3, y = 0.1, z = -0.3 }, max = { x = 0.3, y = 1.0, z = 0.3 } },
			vel = { min = { x = 0, y = 0.2, z = 0 }, max = { x = 0, y = 0.6, z = 0 } },
			exptime = { min = 0.4, max = 0.6 }, size = { min = 0.5, max = 0.8 }, vertical = true, glow = 0,
			texture = strand(F, 0.9),
		})
	end
	F.decal({ pos = at, tex = F.tint(F.TEX.dust, c.palette.smoke), size = 1.8, life = 6 })
	F.sound("mobs_mc_wolf_hurt.1", { pos = at, gain = 0.8, pitch = 0.6 })
end

minemon.fx.register_move("type:dark", R)
