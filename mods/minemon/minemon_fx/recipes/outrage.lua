-- Outrage (M2.1 wave 2, group B, power 90, cast 0.6, dragon): a rage. During the cast, dark violet steam rises off the
-- user's shoulders and its chest pulses; the launch is a violet flash with a crescent that snaps forward; the orb is a
-- violet core with gold sparks and crescent slashes that spin off it; on the hit five crescents fan out of the victim
-- in turn, a big violet ring opens and gold sparks fly. Strong: big and loud. The crescents are the signature (Dragon
-- Rage is a fire-and-smoke blast; Dragon Breath has no crescents).
-- Budget at "high": cast ~40, launch ~40, projectile ~70/s, impact ~110.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	slash = "minemon_fx_slash.png",
	glow = "minemon_fx_glow.png",
	spark = "minemon_fx_spark.png",
	ring = "minemon_fx_ring.png",
	smoke = "minemon_fx_smoke_anim.png",
}
local ZERO = { x = 0, y = 0, z = 0 }
local GOLD = "#ffd860"
local SLASH_FLIP = "^[transformFX"

-- Wind-up: dark violet steam rises off the user's shoulders and the chest glows, pulsing.
function R.cast(F, c)
	local at = F.anchor(c.user, "middle", 0.7, 0)
	if not at then
		return false
	end
	local t = math.max(0.2, c.time or 0.6)
	F.emit({
		amount = 12, time = t, pos = { min = vector.subtract(at, { x = 0.4, y = 0.1, z = 0.4 }),
			max = vector.add(at, { x = 0.4, y = 0.3, z = 0.4 }) },
		vel = { min = { x = -0.2, y = 0.5, z = -0.2 }, max = { x = 0.2, y = 1.0, z = 0.2 } },
		exptime = { min = 0.5, max = 0.8 }, size = { min = 0.3, max = 0.45 },
		texture = F.tex(F.tint(TEX.smoke, c.palette.smoke), { blend = "alpha", alpha = 0.55, anim = "smoke" }),
		glow = 0,
	})
	F.emit({
		amount = 1, time = t, pos = at, vel = ZERO, exptime = t, size = 0.9,
		texture = F.tex(F.tint(TEX.glow, c.palette.main), { blend = "add", fade = { 0.2, 0.9 }, grow = { 0.6, 1.2 } }),
		glow = 14,
	})
	F.sound("fire_fire", { pos = at, gain = 0.3, pitch = 0.6 })
end

-- The launch: a violet flash, a ring and a crescent that snaps forward from the muzzle.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 1.2, life = 0.16 })
	F.ring({ pos = c.from, colour = c.palette.main, size = 0.5, grow = 3.0, life = 0.3 })
	F.emit({
		amount = 1, time = 0.02, pos = vector.add(c.from, vector.multiply(c.dir, 0.3)), vel = ZERO, exptime = 0.16,
		size = 1.3, texture = F.tex(F.tint(TEX.slash, c.palette.main), { blend = "add", fade = true,
			grow = { 0.6, 1.0 } }), glow = 14,
	})
	F.sound("mcl_criticals_hit", { pos = c.from, gain = 0.5, pitch = 0.7 })
end

-- The orb: a violet core with a halo; gold sparks crackle off it and crescents spin away from it.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.glow, c.palette.main) }, visual_size = { x = 1.0, y = 1.0 },
		glow = 14 })
	F.on(c.obj, {
		amount = 40, time = 1.5, pos = { min = { x = -0.15, y = -0.15, z = -0.15 }, max = { x = 0.15, y = 0.15, z = 0.15 } },
		vel = { min = { x = -0.8, y = -0.8, z = -0.8 }, max = { x = 0.8, y = 0.8, z = 0.8 } },
		exptime = { min = 0.15, max = 0.3 }, size = { min = 0.12, max = 0.2 },
		texture = F.tex(F.tint(TEX.spark, GOLD), { blend = "add", fade = true }), glow = 14,
	})
	F.on(c.obj, {
		amount = 6, time = 1.5, pos = ZERO, vel = { x = 0, y = 0, z = 0 },
		exptime = { min = 0.25, max = 0.35 }, size = { min = 0.5, max = 0.7 },
		texture = F.tex(F.tint(TEX.slash, c.palette.main), { blend = "add", fade = true, grow = { 0.6, 1.0 } }),
		glow = 14,
	})
	return true
end

-- The fan: five crescents slash out of the victim in turn, a violet ring opens and gold sparks fly off the hit.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.8, life = 0.14 })
	F.ring({ pos = at, colour = c.palette.main, size = 0.5, grow = 4.2, life = 0.4 })
	local fan = { { 0.4, -0.2 }, { -0.4, -0.1 }, { 0.2, 0.4 }, { -0.2, 0.35 }, { 0, -0.4 } }
	for i, f in ipairs(fan) do
		local p = vector.add(at, { x = f[1], y = f[2], z = 0 })
		local tex = (i % 2 == 0) and (TEX.slash .. SLASH_FLIP) or TEX.slash
		F.after(0.04 * i, function()
			F.emit({
				amount = 1, time = 0.02, pos = p, vel = ZERO, exptime = 0.2, size = 1.5,
				texture = F.tex(F.tint(tex, c.palette.main), { blend = "add", fade = true, grow = { 0.6, 1.1 } }),
				glow = 14,
			})
		end)
	end
	F.burst({ pos = at, tex = TEX.spark, colour = GOLD, amount = 26, speed = 5, radius = 0.2,
		life = { 0.2, 0.45 }, size = { 0.12, 0.2 }, glow = 14, collide = true, bounce = 0.2 })
	F.sound("mcl_criticals_hit", { pos = at, gain = 0.8, pitch = 0.6 })
end

minemon.fx.register_move("outrage", R)
