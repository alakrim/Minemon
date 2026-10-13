-- Ghost (type default, M2.1 T-FX-c): wisps that drift and fade, and a violet void. The void is a subtractive smoke
-- (blend "sub"): it darkens the light where it is, so a ghost move looks like a hole in the scene. Silhouette: a
-- curling wisp, never a round ball. Palette (fx_logic.PALETTE): core #f0e8ff, main #9a78e8, edge #4a2a9a, smoke
-- #2a2040. Budgets: docs/ART_GUIDE.md 4. Totals at "high": cast ~35, launch ~30, projectile ~30/s, impact ~50.
-- luacheck: read_globals core vector minemon

local R = {}

local ZERO = { x = 0, y = 0, z = 0 }
local WISP = "minemon_fx_wisp.png" -- a drifting wisp with a curling tail (tools/gen_fx_textures_c.py)
local VOID_TINT = "#7a6a90" -- the subtractive puff's grey: it takes this much light away

-- The void: a sub-blend smoke flipbook that darkens what is behind it.
local function void(F, alpha)
	return F.tex(F.tint(F.TEX.smoke, VOID_TINT), { blend = "sub", alpha = alpha or 0.55, anim = "smoke" })
end

-- Cast: wisps are drawn into the mouth, the void gathers there and a violet glow swells.
function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.inhale({ pos = at, tex = WISP, colour = c.palette.main, radius = 1.1, amount = 18, time = t,
		size = { 0.2, 0.3 } })
	F.emit({
		amount = 6, time = t, pos = at, vel = ZERO, exptime = { min = t * 0.6, max = t }, size = { min = 0.5, max = 0.8 },
		texture = void(F, 0.5),
	})
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t + 0.05, size = 0.7,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add", grow = { 0.2, 1.0 }, alpha = 0.8 }),
		glow = 10,
	})
	F.sound("mobs_mc_enderman_teleport_src", { pos = at, gain = 0.4, pitch = 0.6 })
end

-- Launch: a dark puff that spits out of the muzzle, a violet flash and a burst of wisps.
function R.launch(F, c)
	F.emit({
		amount = 6, time = 0.05, pos = c.from,
		vel = { min = vector.multiply(c.dir, 0.5), max = vector.multiply(c.dir, 2) },
		exptime = { min = 0.4, max = 0.7 }, size = { min = 0.5, max = 0.8 }, texture = void(F),
	})
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.8, life = 0.14 })
	F.burst({ pos = c.from, tex = WISP, colour = c.palette.main, amount = 12, speed = 3, radius = 0.2,
		life = { 0.6, 1.0 }, size = { 0.3, 0.5 }, gravity = -0.3 })
	F.sound("mobs_mc_vex_hurt", { pos = c.from, gain = 0.4, pitch = 0.6 })
end

-- The orb: a violet glow with wisps that trail and drift apart, a void that dims the light around it, and eerie
-- motes. Returns true: decorated.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(F.TEX.glow, c.palette.main) }, visual_size = { x = 0.55, y = 0.55 },
		glow = 14 })
	F.on(c.obj, {
		amount = 10, time = 1.5, pos = { min = { x = -0.15, y = -0.15, z = -0.15 }, max = { x = 0.15, y = 0.15, z = 0.15 } },
		vel = { min = { x = -0.3, y = 0.1, z = -0.3 }, max = { x = 0.3, y = 0.5, z = 0.3 } },
		jitter = { min = { x = -0.4, y = -0.2, z = -0.4 }, max = { x = 0.4, y = 0.2, z = 0.4 } },
		exptime = { min = 0.8, max = 1.2 }, size = { min = 0.35, max = 0.5 },
		texture = F.tex(F.tint(WISP, c.palette.main), { blend = "add", fade = true }), glow = 8,
	})
	F.on(c.obj, {
		amount = 6, time = 1.5, pos = { min = { x = -0.1, y = -0.1, z = -0.1 }, max = { x = 0.1, y = 0.1, z = 0.1 } },
		vel = { min = { x = -0.1, y = 0, z = -0.1 }, max = { x = 0.1, y = 0.2, z = 0.1 } },
		exptime = { min = 0.8, max = 1.2 }, size = { min = 0.5, max = 0.8 }, texture = void(F),
	})
	F.on(c.obj, {
		amount = 8, time = 1.5, pos = { min = { x = -0.3, y = -0.3, z = -0.3 }, max = { x = 0.3, y = 0.3, z = 0.3 } },
		vel = { min = { x = -0.2, y = 0, z = -0.2 }, max = { x = 0.2, y = 0.3, z = 0.2 } },
		exptime = { min = 0.4, max = 0.8 }, size = { min = 0.12, max = 0.2 },
		texture = F.tex(F.tint(F.TEX.mote, c.palette.core), { blend = "add", fade = true }), glow = 10,
	})
	return true
end

-- Beam: a dark void stream with wisps riding it and a violet core; the wisps spill out where it lands.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 22
	local dir = vector.multiply(d, 1 / len)
	F.emit({
		amount = 36, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = { min = 0.6, max = 0.9 }, texture = void(F),
	}, c.from)
	F.emit({
		amount = 30, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed * 0.7),
		exptime = len / (speed * 0.7), size = { min = 0.3, max = 0.45 },
		texture = F.tex(F.tint(WISP, c.palette.main), { blend = "add", fade = true }), glow = 8,
	}, c.from)
	F.emit({
		amount = 30, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = { min = 0.14, max = 0.22 }, texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add" }),
		glow = 10,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.8 })
	F.flare({ pos = c.to, colour = c.palette.core, size = 1.0, life = 0.3 })
	F.burst({ pos = c.to, tex = WISP, colour = c.palette.main, amount = 12, speed = 3, life = { 0.5, 1.0 },
		size = { 0.3, 0.45 }, gravity = -0.3 })
end

-- Melee: a tongue of wisps swept in front of the user, with a puff of void at the arc's centre.
function R.melee(F, c)
	F.emit({
		amount = 6, time = 0.12, pos = c.centre, vel = ZERO, exptime = { min = 0.3, max = 0.5 },
		size = { min = 0.6, max = 0.8 }, texture = void(F, 0.45),
	})
	for i = -2, 2 do
		local bulge = 0.45 - 0.08 * math.abs(i)
		local p = vector.add(c.centre, { x = c.fwd.x * bulge, y = i * 0.22, z = c.fwd.z * bulge })
		F.emit({
			amount = 5, time = 0.12, pos = p, vel = vector.multiply(c.fwd, 2),
			exptime = { min = 0.3, max = 0.5 }, size = { min = 0.4, max = 0.6 },
			texture = F.tex(F.tint(WISP, c.palette.main), { blend = "add", fade = true }), glow = 8,
		})
	end
end

-- Area: a void wave. Dark puffs spread out across the area, wisps rise behind them and a violet ring marks the edge.
function R.area(F, c)
	local r = c.radius or 3
	F.burst({ pos = c.centre, tex = F.TEX.smoke, anim = "smoke", colour = VOID_TINT, blend = "sub", amount = 22,
		speed = r * 1.1, radius = 0.4, life = { 0.6, 1.0 }, size = { 0.7, 1.0 }, glow = 0 })
	F.burst({ pos = c.centre, tex = WISP, colour = c.palette.main, amount = 24, speed = r * 1.3, radius = 0.3,
		life = { 0.7, 1.2 }, size = { 0.3, 0.5 }, gravity = -0.2 })
	F.ring({ pos = c.centre, colour = c.palette.edge, size = 0.5, grow = r * 2 / 0.5, life = 0.5 })
	F.sound("mobs_mc_enderman_hurt.1", { pos = c.centre, gain = 0.5, pitch = 0.5 })
end

-- Impact: a flash, a void puff that eats the light, wisps that spill out of it, a ring, wisps that cling to the
-- victim and a violet stain on the ground for 6 s.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.1, life = 0.14 })
	F.burst({ pos = at, tex = F.TEX.smoke, anim = "smoke", colour = VOID_TINT, blend = "sub", amount = 10, speed = 2,
		life = { 0.6, 1.0 }, size = { 0.6, 0.9 }, glow = 0 })
	F.burst({ pos = at, tex = WISP, colour = c.palette.main, amount = 14, speed = 3, life = { 0.7, 1.2 },
		size = { 0.3, 0.5 }, gravity = -0.4 })
	F.ring({ pos = at, colour = c.palette.main, size = 0.4, grow = 2.4, life = 0.4 })
	if c.victim and c.victim:get_pos() then
		F.on(c.victim, {
			amount = 14, time = 1.0,
			pos = { min = { x = -0.25, y = 0.1, z = -0.25 }, max = { x = 0.25, y = 1.0, z = 0.25 } },
			vel = { min = { x = -0.1, y = 0.1, z = -0.1 }, max = { x = 0.1, y = 0.4, z = 0.1 } },
			exptime = { min = 0.8, max = 1.2 }, size = { min = 0.3, max = 0.5 },
			texture = F.tex(F.tint(WISP, c.palette.main), { blend = "add", fade = true }), glow = 8,
		})
	end
	F.decal({ pos = at, tex = F.tint(F.TEX.dust, c.palette.smoke), size = 2.0, life = 6 })
	F.sound("mobs_mc_enderman_hurt.1", { pos = at, gain = 0.6, pitch = 0.6 })
end

minemon.fx.register_move("type:ghost", R)
