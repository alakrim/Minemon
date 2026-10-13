-- Synthesis (M2.1 T-FX2-C, aura, grass, heal): sunlight. Six rays of gold-green light fall from high above and land on
-- the user, one after another round it, then a burst of spores sparks off the body as it takes the light in. Recover
-- rises from the feet; Synthesis falls from the sky: the same heal, the other direction. Budget: aura 120.
-- luacheck: read_globals core vector minemon

local R = {}

local SPARK = "minemon_fx_spark.png"
local RAY = "#e8ffb0"
local ZERO = { x = 0, y = 0, z = 0 }

function R.aura(F, c)
	local user = c.user
	if not (user and user:get_pos()) then
		return
	end
	local centre = c.centre
	local top = centre.y + 2.2
	for k = 0, 5 do
		core.after(k * 0.07, function()
			local a = k * (2 * math.pi / 6)
			-- A ray is a short line of sparks falling fast from high above, onto the user's side.
			local p = { x = centre.x + math.cos(a) * 0.8, y = top, z = centre.z + math.sin(a) * 0.8 }
			F.emit({
				amount = 5, time = 0.25, pos = p, vel = { x = 0, y = -5.0, z = 0 },
				jitter = { min = { x = -0.05, y = 0, z = -0.05 }, max = { x = 0.05, y = 0, z = 0.05 } },
				exptime = { min = 0.35, max = 0.45 }, size = { min = 0.1, max = 0.14 },
				texture = F.tex(F.tint(SPARK, RAY), { blend = "add", fade = true }), glow = 14,
			})
		end)
	end
	-- The take-up: a burst of spores off the body once the rays have landed.
	core.after(0.5, function()
		F.burst({ pos = vector.add(centre, { x = 0, y = -0.2, z = 0 }), tex = F.TEX.mote, colour = c.palette.main,
			amount = 12, speed = 1.3, radius = 0.25, life = { 0.5, 0.9 }, size = { 0.1, 0.16 }, gravity = -0.4,
			glow = 14 })
		F.flare({ pos = centre, colour = c.palette.core, size = 1.0, life = 0.18 })
	end)
	F.emit({
		amount = 1, time = 1.0, pos = centre, vel = ZERO, exptime = 1.1, size = 1.6,
		texture = F.tex(F.tint(F.TEX.glow, "#f0ffc8"), { blend = "add", grow = { 0.7, 1.1 }, alpha = 0.25 }), glow = 10,
	})
end

minemon.fx.register_move("synthesis", R)
