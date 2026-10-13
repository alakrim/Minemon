-- Sky Attack (M2.1, T-FX-a, signature flying move): the wings flare, feathers are drawn in, and a white-hot dive
-- streaks from the user to the target with a trail of feathers. The hit is a white flash with a feather burst that
-- floats up. Budget: cast ~60, beam ~150, impact ~120. Launch, projectile, melee and area come from type:flying.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	streak = "minemon_fx_streak.png",
	feather = "minemon_fx_feather.png",
	glow = "minemon_fx_glow.png",
	star = "minemon_fx_star.png",
}
local ZERO = { x = 0, y = 0, z = 0 }

-- The wings flare: feathers are drawn into the mouth from the air around the user, and a white glow swells.
function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.5)
	F.inhale({ pos = at, tex = TEX.feather, colour = c.palette.core, radius = 1.4, amount = 18, time = t,
		size = { 0.25, 0.36 } })
	F.emit({
		amount = 1, time = t, pos = at, vel = ZERO, exptime = t + 0.05, size = 0.9,
		texture = F.tex(F.tint(TEX.glow, c.palette.core), { blend = "add", grow = { 0.2, 1.0 }, alpha = 0.9 }),
		glow = 10,
	})
	F.sound("mcl_throwing_throw", { pos = at, gain = 0.4, pitch = 0.6 })
end

-- The dive: a white-hot streak down the line, with feathers left behind it that float on the air.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 28
	local dir = vector.multiply(d, 1 / len)
	F.emit({
		amount = 50, time = 0.4, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = { min = 0.22, max = 0.32 },
		texture = F.tex(F.tint(TEX.streak, c.palette.core), { blend = "add" }), vertical = false, glow = 10,
	}, c.from)
	F.emit({
		amount = 30, time = 0.4, pos = c.from, vel = vector.multiply(dir, 6), exptime = { min = 0.9, max = 1.4 },
		jitter = { min = { x = -0.6, y = -0.6, z = -0.6 }, max = { x = 0.6, y = 0.6, z = 0.6 } },
		drag = { x = 0.6, y = 0.6, z = 0.6 }, acc = { x = 0, y = -0.8, z = 0 },
		size = { min = 0.28, max = 0.42 },
		texture = F.tex(F.tint(TEX.feather, c.palette.main), { blend = "alpha", fade = true }), glow = 6,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.core, size = 1.1 })
	F.flare({ pos = c.to, colour = c.palette.core, size = 1.4, life = 0.3 })
	F.ring({ pos = c.to, colour = c.palette.main, size = 0.5, grow = 3.0, life = 0.35 })
end

-- The hit: a white flash, two rings, a star of light and a burst of feathers that floats up from the victim.
function R.impact(F, c)
	local at = c.pos
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.3, size = 1.8,
		texture = F.tex(F.tint(TEX.star, c.palette.core), { blend = "add", fade = true, grow = { 0.5, 1.1 } }),
		glow = 10,
	})
	F.flare({ pos = at, colour = c.palette.core, size = 1.4 })
	F.ring({ pos = at, colour = c.palette.main, size = 0.4, grow = 3.4, life = 0.4 })
	F.ring({ pos = at, colour = c.palette.edge, size = 0.5, grow = 2.2, life = 0.3 })
	F.burst({ pos = at, tex = TEX.feather, colour = c.palette.core, amount = 30, speed = 4, radius = 0.2,
		life = { 0.8, 1.5 }, size = { 0.24, 0.36 }, gravity = -0.8, drag = 0.5, blend = "alpha", glow = 6 })
	F.burst({ pos = at, tex = TEX.streak, colour = c.palette.core, amount = 14, speed = 6, radius = 0.15,
		life = { 0.2, 0.4 }, size = { 0.14, 0.22 }, glow = 10 })
	if c.victim and c.victim:get_pos() then
		F.on(c.victim, {
			amount = 12, time = 0.7,
			pos = { min = { x = -0.25, y = 0.2, z = -0.25 }, max = { x = 0.25, y = 1.0, z = 0.25 } },
			vel = { min = { x = 0, y = 0.4, z = 0 }, max = { x = 0, y = 1.0, z = 0 } }, drag = { x = 0.5, y = 0.2, z = 0.5 },
			exptime = { min = 0.6, max = 1.0 }, size = { min = 0.22, max = 0.34 },
			texture = F.tex(F.tint(TEX.feather, c.palette.core), { blend = "alpha", fade = true }), glow = 6,
		})
	end
	F.sound("mcl_throwing_throw", { pos = at, gain = 0.9, pitch = 0.5 })
end

minemon.fx.register_move("sky_attack", R)
