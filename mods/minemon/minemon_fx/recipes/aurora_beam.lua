-- Aurora Beam (M2.1 wave 2, group B, power 65, attack -1 at 10%): an aurora. The orb is a teal glow that drags three
-- ribbons of light (teal, green, violet) that sway left and right as it flies, like the northern lights; on the hit a
-- curtain of light rises off the victim, tall and thin, and frost sparkles at its foot. Medium: the swaying ribbons
-- and the rising curtain are the signature (Ice Beam and Blizzard are cold rays and clouds).
-- Budget at "high": launch ~25, projectile ~60/s, impact ~70.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	streak = "minemon_fx_streak.png",
	frost = "minemon_fx_frost.png",
	glow = "minemon_fx_glow.png",
}
local ZERO = { x = 0, y = 0, z = 0 }
local TEAL = "#7ff5e0"
local GREEN = "#9affa0"
local VIOLET = "#b49cff"

-- The shot: a teal flash and three ribbons of colour leaving the muzzle.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = TEAL, size = 0.9, life = 0.14 })
	F.emit({
		amount = 9, time = 0.05, pos = c.from,
		vel = { min = vector.multiply(c.dir, 5), max = vector.multiply(c.dir, 7) },
		exptime = { min = 0.2, max = 0.32 }, size = { min = 0.2, max = 0.28 },
		texture = F.tex(F.tint(TEX.streak, TEAL), { blend = "add", fade = true }), vertical = true, glow = 14,
	})
	F.sound("default_glass_footstep", { pos = c.from, gain = 0.4, pitch = 1.2 })
end

-- The orb: a teal glow; three ribbons (teal, green, violet) are left behind it, drifting to the sides in turn.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.glow, TEAL) }, visual_size = { x = 0.6, y = 0.6 }, glow = 14 })
	local ribbons = { { TEAL, -0.8 }, { GREEN, 0.8 }, { VIOLET, 0 } }
	for _, r in ipairs(ribbons) do
		F.on(c.obj, {
			amount = 9, time = 1.5, pos = ZERO, vel = { x = r[2], y = 0.4, z = 0 },
			exptime = { min = 0.3, max = 0.5 }, size = { min = 0.22, max = 0.32 },
			texture = F.tex(F.tint(TEX.streak, r[1]), { blend = "add", fade = true }), vertical = true, glow = 14,
		})
	end
	return true
end

-- The curtain: a tall thin band of teal and violet light rises off the victim and fades; frost sparkles at its foot.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = TEAL, size = 1.0, life = 0.12 })
	for i, col in ipairs({ TEAL, VIOLET }) do
		F.emit({
			amount = 6, time = 0.2,
			pos = { min = vector.add(at, { x = (i - 1.5) * 0.3, y = -0.2, z = 0 }),
				max = vector.add(at, { x = (i - 1.5) * 0.3, y = 0.3, z = 0 }) },
			vel = { x = 0, y = 1.1, z = 0 }, drag = { x = 0.2, y = 0.1, z = 0.2 },
			exptime = { min = 0.7, max = 1.0 }, size = { min = 0.5, max = 0.7 },
			texture = F.tex(F.tint(TEX.streak, col), { blend = "add", fade = true }), vertical = true, glow = 14,
		})
	end
	F.emit({
		amount = 8, time = 0.1, pos = at,
		vel = { min = { x = -0.8, y = 0.2, z = -0.8 }, max = { x = 0.8, y = 0.9, z = 0.8 } },
		exptime = { min = 0.4, max = 0.7 }, size = { min = 0.1, max = 0.15 },
		texture = F.tex(F.tint(TEX.frost, TEAL), { blend = "alpha", fade = true }), glow = 6,
	})
	F.sound("default_glass_footstep", { pos = at, gain = 0.5, pitch = 0.9 })
end

minemon.fx.register_move("aurora_beam", R)
