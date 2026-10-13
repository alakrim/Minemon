-- Gust (M2.1 wave 2, group B, power 40, physical beam): a quick shove of air. No column, no ring: a fast fan of thin
-- speed lines snaps from the user to the victim in a fraction of a second, and on the hit a few feathers are blown
-- back off the victim the way the gust came. Weak: small and quick. Flying's other moves keep the column and the
-- pressure ring; this one is the speed lines alone.
-- Budget at "high": beam ~60, impact ~24.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	speedline = "minemon_fx_speedline.png",
	feather = "minemon_fx_feather.png",
	streak = "minemon_fx_streak.png",
}

-- The gust: thin speed lines run from the user to the stop point at 30 m/s, in a loose fan.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 30
	local dir = vector.multiply(d, 1 / len)
	F.emit({
		amount = 26, time = 0.2, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		jitter = { min = { x = -0.5, y = -0.5, z = -0.5 }, max = { x = 0.5, y = 0.5, z = 0.5 } },
		size = { min = 0.2, max = 0.3 },
		texture = F.tex(F.tint(TEX.speedline, c.palette.core), { blend = "add", fade = true }), vertical = false,
		glow = 10,
	}, c.from)
	F.emit({
		amount = 10, time = 0.2, pos = c.from, vel = vector.multiply(dir, speed * 0.8), exptime = len / speed,
		size = { min = 0.24, max = 0.34 },
		texture = F.tex(F.tint(TEX.streak, c.palette.main), { blend = "add", fade = true }), vertical = false,
		glow = 10,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.7, life = 0.1 })
end

-- The hit: feathers are blown back off the victim, away from the user, and turn as they fall.
function R.impact(F, c)
	local at = c.pos
	local back = { x = 1, y = 0, z = 0 }
	if c.user and c.user:get_pos() and c.victim and c.victim:get_pos() then
		local d = vector.subtract(c.victim:get_pos(), c.user:get_pos())
		d.y = 0
		if vector.length(d) > 0.01 then
			back = vector.normalize(d)
		end
	end
	F.emit({
		amount = 8, time = 0.05, pos = at,
		vel = { min = vector.add(vector.multiply(back, 2.5), { x = -0.6, y = 0.4, z = -0.6 }),
			max = vector.add(vector.multiply(back, 4), { x = 0.6, y = 1.2, z = 0.6 }) },
		acc = { x = 0, y = -2.5, z = 0 }, drag = { x = 0.8, y = 0.4, z = 0.8 },
		exptime = { min = 0.4, max = 0.7 }, size = { min = 0.14, max = 0.2 },
		texture = F.tex(F.tint(TEX.feather, c.palette.core), { blend = "alpha", fade = { 1, 0.4 } }), glow = 4,
	})
	F.flare({ pos = at, colour = c.palette.core, size = 0.8, life = 0.1 })
	F.sound("default_grass_footstep", { pos = at, gain = 0.4, pitch = 1.8 })
end

minemon.fx.register_move("gust", R)
