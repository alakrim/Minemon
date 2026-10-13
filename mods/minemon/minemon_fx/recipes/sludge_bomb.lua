-- Sludge Bomb (M2.1, T-FX-b, poison, beam, 90 power): the signature of poison. A heavy glob of sludge lobs through the
-- air with a trail of drips; where it lands it bursts in a splash of goo, smoke rises and a toxic puddle stays for
-- seven seconds. Budget: beam ~150 particles, 1 puddle.
-- luacheck: read_globals core vector minemon

local R = {}

local GOO = "minemon_fx_goo.png"
local DROP = "minemon_fx_drop.png"
local PUDDLE = "minemon_fx_toxic_puddle.png"
local ZERO = { x = 0, y = 0, z = 0 }

-- The lob: a big glob that drops a little as it flies (gravity), a trail of smaller globs, and drips that fall from it.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 16
	local dir = vector.multiply(d, 1 / len)
	local flight = len / speed
	local fall = { x = 0, y = -4, z = 0 }
	F.emit({
		amount = 1, time = 0.02, pos = c.from, vel = vector.multiply(dir, speed), acc = fall, exptime = flight,
		size = 1.1, texture = F.tex(F.tint(GOO, c.palette.main), { blend = "alpha" }), glow = 0,
	})
	F.emit({
		amount = 36, time = 0.3, pos = c.from, vel = vector.multiply(dir, speed * 0.9), acc = fall,
		exptime = { min = flight * 0.8, max = flight }, size = { min = 0.3, max = 0.46 },
		texture = F.tex(F.tint(GOO, c.palette.main), { blend = "alpha", fade = { 1, 0.8 } }), glow = 0,
	}, c.from)
	F.emit({
		amount = 22, time = flight, pos = c.from, vertical = true, collisiondetection = true,
		vel = vector.multiply(dir, speed * 0.6), acc = { x = 0, y = -10, z = 0 },
		exptime = { min = 0.5, max = 0.9 }, size = { min = 0.14, max = 0.2 },
		texture = F.tex(F.tint(DROP, c.palette.main), { blend = "alpha", fade = { 1, 0.7 } }), glow = 0,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.8 })
end

-- The splash where it lands: goo thrown out and bounced down, smoke, and the puddle.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.4, life = 0.14 })
	F.emit({
		amount = 30, time = 0.05, pos = at, radius = { min = 0.1, max = 0.3, bias = 0 },
		attract = { kind = "point", origin = at, strength = { min = -10, max = -16 }, die_on_contact = false },
		vel = ZERO, acc = { x = 0, y = -9, z = 0 }, collisiondetection = true, bounce = { min = 0.15, max = 0.3 },
		exptime = { min = 0.5, max = 0.9 }, size = { min = 0.2, max = 0.32 },
		texture = F.tex(F.tint(GOO, c.palette.main), { blend = "alpha", fade = { 1, 0.6 } }), glow = 0,
	})
	F.smoke({ pos = at, colour = c.palette.smoke, amount = 8, size = { 0.5, 0.8 }, life = { 0.8, 1.2 }, alpha = 0.5,
		rise = 0.6, time = 0.3 })
	F.decal({ pos = at, tex = F.tint(PUDDLE, c.palette.main) .. "^[opacity:200", size = 1.5, life = 7 })
	F.sound("mcl_throwing_snowball_impact_soft", { pos = at, gain = 0.9, pitch = 0.6 })
end

minemon.fx.register_move("sludge_bomb", R)
