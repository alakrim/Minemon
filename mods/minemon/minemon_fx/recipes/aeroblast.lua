-- Aeroblast (M2.1, T-FX-a, signature flying move): an air cannon. A wide, dense column of wind streaks runs from the
-- user to the target, two pressure rings roll out at the stop point and the hit throws streaks and feathers out in
-- every direction. Budget: beam ~150, impact ~130. Cast, launch, projectile, melee and area come from type:flying.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	streak = "minemon_fx_streak.png",
	feather = "minemon_fx_feather.png",
	glow = "minemon_fx_glow.png",
}

function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 34
	local dir = vector.multiply(d, 1 / len)
	-- The body of the wind: wide, pale streaks.
	F.emit({
		amount = 80, time = 0.4, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		jitter = { min = { x = -0.7, y = -0.7, z = -0.7 }, max = { x = 0.7, y = 0.7, z = 0.7 } },
		size = { min = 0.3, max = 0.44 },
		texture = F.tex(F.tint(TEX.streak, c.palette.main), { blend = "alpha", fade = true }), vertical = false,
		glow = 4,
	}, c.from)
	-- The hot core of the wind.
	F.emit({
		amount = 40, time = 0.4, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		jitter = { min = { x = -0.2, y = -0.2, z = -0.2 }, max = { x = 0.2, y = 0.2, z = 0.2 } },
		size = { min = 0.16, max = 0.24 },
		texture = F.tex(F.tint(TEX.streak, c.palette.core), { blend = "add" }), vertical = false, glow = 8,
	}, c.from)
	-- Feathers caught in the column.
	F.emit({
		amount = 18, time = 0.4, pos = c.from, vel = vector.multiply(dir, 9), exptime = len / 9,
		jitter = { min = { x = -1.4, y = -1.4, z = -1.4 }, max = { x = 1.4, y = 1.4, z = 1.4 } },
		size = { min = 0.25, max = 0.4 },
		texture = F.tex(F.tint(TEX.feather, c.palette.core), { blend = "alpha", fade = true }), glow = 4,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.core, size = 1.2 })
	-- The stop point: two pressure rings and a gust that blows outward.
	F.ring({ pos = c.to, colour = c.palette.main, size = 0.5, grow = 3.6, life = 0.45 })
	F.ring({ pos = c.to, colour = c.palette.edge, size = 0.4, grow = 2.6, life = 0.3 })
	F.burst({ pos = c.to, tex = TEX.streak, colour = c.palette.core, blend = "add", amount = 24, speed = 6,
		radius = 0.2, life = { 0.25, 0.5 }, size = { 0.18, 0.3 }, glow = 8 })
	F.sound("mcl_throwing_throw", { pos = c.to, gain = 0.8, pitch = 0.55 })
end

minemon.fx.register_move("aeroblast", R)
