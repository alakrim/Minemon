-- Earthquake (M2.1, T-FX-b, ground, area, 100 power): the signature of ground. Three shockwaves go out through the
-- ground a beat apart, dirt blocks rise in a ring and fall back and bounce, a dust wall rolls out, and a crater stays
-- for ten seconds. Budget: area ~190 particles, 1 crater decal.
-- luacheck: read_globals core vector minemon

local R = {}

local CRATER = "minemon_fx_crater.png"
local DIRT = { name = "mcl_core:dirt" }
local ZERO = { x = 0, y = 0, z = 0 }

function R.area(F, c)
	local r = c.radius
	local ctr = c.centre
	F.ring({ pos = ctr, colour = c.palette.main, size = 1.0, grow = r * 2.4, life = 0.7 })
	F.after(0.15, function()
		F.ring({ pos = ctr, colour = c.palette.edge, size = 0.8, grow = r * 2.8, life = 0.8 })
	end)
	F.after(0.35, function()
		F.ring({ pos = ctr, colour = c.palette.main, size = 0.6, grow = r * 3.2, life = 0.9 })
	end)
	-- Dirt rises in a ring round the centre, then falls back with gravity and bounces.
	F.emit({
		amount = 40, time = 0.1, pos = ctr, radius = { min = r * 0.4, max = r * 0.7, bias = 0 },
		vel = { min = { x = -0.8, y = 3, z = -0.8 }, max = { x = 0.8, y = 5.5, z = 0.8 } },
		acc = { x = 0, y = -14, z = 0 }, collisiondetection = true, bounce = { min = 0.2, max = 0.4 },
		exptime = { min = 0.9, max = 1.5 }, size = { min = 0.1, max = 0.16 }, node = DIRT, glow = 0,
	})
	-- A dust wall rolls out along the ground.
	F.burst({ pos = ctr, tex = F.TEX.dust, colour = c.palette.smoke, blend = "alpha", amount = 40, speed = r * 1.5,
		radius = 0.4, life = { 0.8, 1.4 }, size = { 0.45, 0.7 }, gravity = -0.1, glow = 0 })
	F.emit({
		amount = 24, time = 0.4, pos = ctr, radius = { min = r * 0.8, max = r * 1.0, bias = 0 },
		vel = ZERO, exptime = { min = 1.0, max = 1.5 }, size = { min = 0.5, max = 0.75 },
		texture = F.tex(F.tint(F.TEX.dust, c.palette.smoke), { blend = "alpha", alpha = 0.45, grow = { 0.6, 1.3 } }),
		glow = 0,
	})
	F.decal({ pos = ctr, tex = F.tint(CRATER, c.palette.edge) .. "^[opacity:150", size = r * 1.7, life = 10 })
	F.sound("default_dig_crumbly", { pos = ctr, gain = 1.2, pitch = 0.5 })
	F.after(0.3, function()
		F.sound("default_gravel_dig", { pos = ctr, gain = 0.8, pitch = 0.6 })
	end)
end

minemon.fx.register_move("earthquake", R)
