-- Sludge (M2.1 wave 2, group B, power 65, poison 30%, beam): a thick rope of goo. Big, heavy blobs of sludge sag out of
-- the user along the line (gravity pulls the rope down as it goes), and on the hit a splat of goo lands on the victim,
-- a toxic puddle stays on the ground for six seconds and sludge drips off the victim's body. Medium: the rope and the
-- splat are the signature; the type's goo streams are thin and bounce.
-- Budget at "high": beam ~100, impact ~70, plus one decal.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	goo = "minemon_fx_goo.png",
	puddle = "minemon_fx_toxic_puddle.png",
	drop = "minemon_fx_drop.png",
}
local SAG = { x = 0, y = -5, z = 0 }

-- The rope: big blobs of sludge fly out along the line and sag with gravity as they go.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 14
	local dir = vector.multiply(d, 1 / len)
	F.emit({
		amount = 28, time = 0.4, pos = c.from, vel = vector.multiply(dir, speed), acc = SAG,
		exptime = len / speed + 0.2, size = { min = 0.42, max = 0.56 },
		jitter = { min = { x = -0.2, y = -0.2, z = -0.2 }, max = { x = 0.2, y = 0.2, z = 0.2 } },
		texture = F.tex(F.tint(TEX.goo, c.palette.main), { blend = "alpha", fade = { 1, 0.7 } }), glow = 4,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.8, life = 0.1 })
end

-- The splat: sludge bursts out of the victim, a toxic puddle spreads on the ground and drips fall off the body.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.1, life = 0.12 })
	F.burst({ pos = at, tex = TEX.goo, colour = c.palette.main, amount = 14, speed = 3.5, radius = 0.2,
		life = { 0.4, 0.7 }, size = { 0.2, 0.3 }, gravity = 9.8, collide = true, bounce = 0.2, blend = "alpha",
		glow = 4 })
	F.emit({
		amount = 14, time = 0.5, pos = { min = vector.add(at, { x = -0.25, y = 0.2, z = -0.25 }),
			max = vector.add(at, { x = 0.25, y = 0.8, z = 0.25 }) },
		vel = { min = { x = 0, y = -0.4, z = 0 }, max = { x = 0, y = -0.8, z = 0 } }, acc = { x = 0, y = -9.8, z = 0 },
		exptime = { min = 0.4, max = 0.6 }, size = { min = 0.16, max = 0.22 },
		texture = F.tex(F.tint(TEX.drop, c.palette.main), { blend = "alpha", fade = true }), glow = 4,
	})
	F.decal({ pos = at, tex = F.tint(TEX.puddle, c.palette.main), size = 1.6, life = 6 })
	F.sound("watersplash", { pos = at, gain = 0.7, pitch = 0.5 })
end

minemon.fx.register_move("sludge", R)
