-- Confusion (M2.1 wave 2, group B, power 50, confusion 10%): a pink ripple that wobbles the victim. The orb is a small
-- pink glow that throws pink rings out to its left and right as it flies, so the trail swings from side to side. On
-- the hit, two pink rings open either side of the victim's body, one after the other (left, right, left), so its
-- outline seems to wobble, and a few motes drift round its middle. Medium: the swinging rings are the signature.
-- Budget at "high": launch ~20, projectile ~40/s, impact ~50.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	ring = "minemon_fx_ring.png",
	mote = "minemon_fx_mote.png",
	glow = "minemon_fx_glow.png",
}
local ZERO = { x = 0, y = 0, z = 0 }

-- The shot: a pink flash and a ring at the muzzle.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9, life = 0.14 })
	F.ring({ pos = c.from, colour = c.palette.main, size = 0.3, grow = 2.6, life = 0.25 })
	F.sound("mcl_enchanting_enchant", { pos = c.from, gain = 0.4, pitch = 1.5 })
end

-- The orb: a small pink glow; rings are thrown left and right of its path in turn, so the trail swings.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.glow, c.palette.main) }, visual_size = { x = 0.5, y = 0.5 },
		glow = 14 })
	for _, side in ipairs({ -1, 1 }) do
		F.on(c.obj, {
			amount = 8, time = 1.5, pos = ZERO, vel = { x = side * 0.9, y = 0, z = 0 },
			exptime = { min = 0.22, max = 0.34 }, size = { min = 0.28, max = 0.36 },
			texture = F.tex(F.tint(TEX.ring, c.palette.main), { blend = "add", fade = true, grow = { 0.6, 1.4 } }),
			glow = 14,
		})
	end
	return true
end

-- The wobble: pink rings open left, right, left of the victim's middle, a short beat apart, and motes drift round it.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.0, life = 0.12 })
	local beats = { { x = -0.4, t = 0 }, { x = 0.4, t = 0.12 }, { x = -0.4, t = 0.24 } }
	for _, b in ipairs(beats) do
		local p = vector.add(at, { x = b.x, y = 0, z = 0 })
		core.after(b.t, function()
			F.ring({ pos = p, colour = c.palette.main, size = 0.35, grow = 2.4, life = 0.3 })
		end)
	end
	if c.victim and c.victim:get_pos() then
		F.on(c.victim, {
			amount = 10, time = 0.5,
			pos = { min = { x = -0.3, y = 0.2, z = -0.3 }, max = { x = 0.3, y = 1.0, z = 0.3 } },
			vel = { min = { x = -0.3, y = -0.1, z = -0.3 }, max = { x = 0.3, y = 0.3, z = 0.3 } },
			exptime = { min = 0.3, max = 0.5 }, size = { min = 0.16, max = 0.24 },
			texture = F.tex(F.tint(TEX.mote, c.palette.core), { blend = "add", fade = true }), glow = 14,
		})
	end
	F.sound("mcl_enchanting_enchant", { pos = at, gain = 0.6, pitch = 1.0 })
end

minemon.fx.register_move("confusion", R)
