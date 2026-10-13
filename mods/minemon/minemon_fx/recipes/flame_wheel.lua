-- Flame Wheel (M2.1 wave 2, group B, power 60, burn 10%): a burning wheel that rolls at the target. The orb is the
-- flame wheel itself (a turning ring of fire, a 4-frame flipbook), it leaves a low track of flames along the ground;
-- on the hit it rolls over the victim: two scorched tracks stay on the ground and a short fire plume rises off the
-- victim. Medium: the wheel and the tracks are the signature, nothing in the type look is a turning ring.
-- Budget at "high": launch ~20, projectile ~45/s, impact ~60, plus two decals.
-- luacheck: read_globals core vector minemon

local R = {}

local WHEEL = "minemon_fx_flame_wheel_anim.png"
local WHEEL_FRAMES = 4
local ZERO = { x = 0, y = 0, z = 0 }

-- The launch: a low fire puff under the wheel, and a flash.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.8, life = 0.12 })
	F.flames({ pos = c.from, amount = 12, size = { 0.3, 0.42 }, life = { 0.2, 0.36 }, spread = 0.1, rise = 0.5,
		time = 0.05 })
	F.sound("fire_fire", { pos = c.from, gain = 0.5, pitch = 1.2 })
end

-- The wheel: the turning flame flipbook is the body, and its track is a line of low flames left on the ground.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { WHEEL }, spritediv = { x = 1, y = WHEEL_FRAMES }, visual_size = { x = 0.75,
		y = 0.75 }, glow = 14 })
	c.obj:set_sprite({ x = 0, y = 0 }, WHEEL_FRAMES, 0.07, false)
	F.on(c.obj, {
		amount = 28, time = 1.5, pos = { min = { x = -0.05, y = -0.25, z = -0.05 }, max = { x = 0.05, y = -0.2, z = 0.05 } },
		vel = { min = { x = -0.1, y = 0.2, z = -0.1 }, max = { x = 0.1, y = 0.5, z = 0.1 } },
		exptime = { min = 0.3, max = 0.5 }, size = { min = 0.32, max = 0.44 },
		texture = F.tex(F.TEX.flame, { blend = "add", anim = "flame", grow = { 1, 0.5 } }), vertical = true, glow = 14,
	})
	F.on(c.obj, {
		amount = 6, time = 1.5, pos = ZERO, vel = { x = 0, y = 0.3, z = 0 },
		exptime = { min = 0.5, max = 0.8 }, size = { min = 0.3, max = 0.45 },
		texture = F.tex(F.tint(F.TEX.smoke, c.palette.smoke), { blend = "alpha", alpha = 0.3, anim = "smoke" }),
	})
	return true
end

-- The roll-over: two scorch tracks lie on the ground under the victim, a plume of flame rises off it and embers fly.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = "#ffffff", size = 1.1, life = 0.12 })
	F.flames({ pos = at, amount = 14, size = { 0.35, 0.52 }, life = { 0.4, 0.65 }, spread = 0.2, rise = 1.8,
		time = 0.15 })
	F.embers({ pos = at, amount = 14, speed = 2.5, up = 2.5, size = { 0.06, 0.1 } })
	F.ring({ pos = at, colour = c.palette.main, size = 0.35, grow = 2.4, life = 0.25 })
	local dir = { x = 1, y = 0, z = 0 }
	if c.user and c.user:get_pos() and c.victim and c.victim:get_pos() then
		local d = vector.subtract(c.victim:get_pos(), c.user:get_pos())
		d.y = 0
		if vector.length(d) > 0.01 then
			dir = vector.normalize(d)
		end
	end
	for _, s in ipairs({ -0.4, 0.4 }) do
		F.decal({ pos = vector.add(at, vector.multiply(dir, s)), tex = F.TEX.scorch, size = 1.0, life = 6 })
	end
	F.sound("fire_fire", { pos = at, gain = 0.7, pitch = 1.0 })
end

minemon.fx.register_move("flame_wheel", R)
