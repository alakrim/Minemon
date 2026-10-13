-- Explosion (M2.1, T-FX-a, signature normal move): one white flash the size of the area, two rings, stars thrown out
-- in every direction, a dust cloud that rolls up and a bang. Budget: area ~190. Cast, launch, projectile, beam,
-- melee and impact come from type:normal.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	star = "minemon_fx_star.png",
	dust = "minemon_fx_dust.png",
	smoke = "minemon_fx_smoke_anim.png",
	glow = "minemon_fx_glow.png",
}

function R.area(F, c)
	local r = c.radius
	F.flare({ pos = c.centre, colour = c.palette.core, size = 2.6, life = 0.3 })
	F.emit({
		amount = 1, time = 0.02, pos = c.centre, vel = { x = 0, y = 0, z = 0 }, exptime = 0.45, size = r * 1.6,
		texture = F.tex(F.tint(TEX.glow, c.palette.core), { blend = "add", fade = true, grow = { 0.5, 1.0 } }),
		glow = 14,
	})
	F.ring({ pos = c.centre, colour = c.palette.core, size = 0.8, grow = r * 2.2, life = 0.5 })
	F.ring({ pos = c.centre, colour = c.palette.main, size = 0.6, grow = r * 2.8, life = 0.8 })
	F.burst({ pos = c.centre, tex = TEX.star, colour = c.palette.core, amount = 40, speed = r * 2.5, radius = 0.4,
		life = { 0.4, 0.8 }, size = { 0.6, 1.0 }, glow = 14 })
	F.burst({ pos = c.centre, tex = TEX.dust, colour = c.palette.smoke, blend = "alpha", amount = 30, speed = r * 1.2,
		life = { 1.0, 1.6 }, size = { 1.0, 1.6 }, gravity = -0.6, glow = 0 })
	F.emit({
		amount = 12, time = 0.3,
		pos = { min = { x = c.centre.x - 0.6, y = c.centre.y - 0.3, z = c.centre.z - 0.6 },
			max = { x = c.centre.x + 0.6, y = c.centre.y + 0.3, z = c.centre.z + 0.6 } },
		vel = { min = { x = -0.4, y = 1.0, z = -0.4 }, max = { x = 0.4, y = 2.0, z = 0.4 } },
		drag = { x = 0.5, y = 0.2, z = 0.5 }, exptime = { min = 1.2, max = 1.8 }, size = { min = 1.0, max = 1.5 },
		texture = F.tex(F.tint(TEX.smoke, c.palette.smoke), { blend = "alpha", alpha = 0.6, anim = "smoke" }),
	})
	F.sound("tnt_explode", { pos = c.centre, gain = 1.0, pitch = 1.1 })
end

minemon.fx.register_move("explosion", R)
