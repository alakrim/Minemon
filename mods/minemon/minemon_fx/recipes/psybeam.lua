-- Psybeam (M2.1 wave 2, group B, power 65, confusion 10%): a prism. The orb is a pink glow and it drags a trail of
-- streaks in four colours (pink, yellow, cyan, violet): a rainbow that stays behind it for a moment. On the hit the
-- light splits: a white flash and four short bursts in the four colours fly out from the victim. The rainbow is the
-- signature; the confusion rings belong to Confusion.
-- Budget at "high": launch ~30, projectile ~50/s, impact ~70.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	streak = "minemon_fx_streak.png",
	spark = "minemon_fx_spark.png",
	glow = "minemon_fx_glow.png",
}
local ZERO = { x = 0, y = 0, z = 0 }
local PRISM = { "#ff5a8a", "#ffe64a", "#5affff", "#b48cff" }

-- The shot: a pink flash and the four colours of the prism thrown along the shot.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 1.0, life = 0.14 })
	for _, col in ipairs(PRISM) do
		F.emit({
			amount = 5, time = 0.04, pos = c.from,
			vel = { min = vector.multiply(c.dir, 6), max = vector.multiply(c.dir, 8) },
			exptime = { min = 0.2, max = 0.3 }, size = { min = 0.16, max = 0.22 },
			texture = F.tex(F.tint(TEX.streak, col), { blend = "add", fade = true }), vertical = false, glow = 14,
		})
	end
	F.sound("mcl_enchanting_enchant", { pos = c.from, gain = 0.5, pitch = 1.6 })
end

-- The orb: a pink glow with a white core, and a prism trail: four colours of streaks left where the orb was.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.glow, c.palette.main) }, visual_size = { x = 0.6, y = 0.6 },
		glow = 14 })
	for i, col in ipairs(PRISM) do
		local side = (i - 2.5) * 0.08
		F.on(c.obj, {
			amount = 9, time = 1.5, pos = { min = { x = side, y = -0.05, z = 0 }, max = { x = side, y = 0.05, z = 0 } },
			vel = ZERO, exptime = { min = 0.2, max = 0.32 }, size = { min = 0.2, max = 0.28 },
			texture = F.tex(F.tint(TEX.streak, col), { blend = "add", fade = true }), vertical = false, glow = 14,
		})
	end
	F.on(c.obj, {
		amount = 12, time = 1.5, pos = ZERO, vel = { min = { x = -0.3, y = -0.3, z = -0.3 },
			max = { x = 0.3, y = 0.3, z = 0.3 } },
		exptime = { min = 0.2, max = 0.35 }, size = { min = 0.1, max = 0.16 },
		texture = F.tex(F.tint(TEX.spark, c.palette.core), { blend = "add", fade = true }), glow = 14,
	})
	return true
end

-- The split: a white flash, a pink ring, and four short bursts of the prism colours flying out of the victim.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.4, life = 0.14 })
	F.ring({ pos = at, colour = c.palette.main, size = 0.3, grow = 2.8, life = 0.3 })
	for i, col in ipairs(PRISM) do
		local a = (i - 1) / 4 * 2 * math.pi + 0.4
		local dir = { x = math.cos(a), y = math.sin(a) * 0.6 + 0.3, z = 0 }
		F.emit({
			amount = 7, time = 0.04, pos = at, vel = vector.multiply(dir, 4.5),
			exptime = { min = 0.22, max = 0.4 }, size = { min = 0.14, max = 0.2 },
			texture = F.tex(F.tint(TEX.streak, col), { blend = "add", fade = true }), vertical = false, glow = 14,
		})
	end
	F.burst({ pos = at, tex = TEX.spark, colour = c.palette.core, amount = 14, speed = 4, radius = 0.15,
		life = { 0.2, 0.4 }, size = { 0.1, 0.16 }, glow = 14 })
	F.sound("mcl_enchanting_enchant", { pos = at, gain = 0.7, pitch = 1.2 })
end

minemon.fx.register_move("psybeam", R)
