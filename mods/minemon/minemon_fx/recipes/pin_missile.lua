-- Pin Missile (M2.1, T-FX-b, bug, beam, 14 power, several hits): the signature of bug volleys. Three quick waves of
-- needles fly along the line (a volley, each wave a fraction of a second behind the last), and each needle that lands
-- throws a small spark. Budget: beam ~150 particles.
-- luacheck: read_globals core vector minemon

local R = {}

local SPEED = "minemon_fx_speedline.png" -- a tapered horizontal streak: a needle
local ZERO = { x = 0, y = 0, z = 0 }

-- A volley wave of needles along dir from c.from, arriving at c.to.
local function wave(F, c, dir, len, speed, amount)
	F.emit({
		amount = amount, time = 0.04, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = { min = 0.6, max = 0.8 },
		texture = F.tex(F.tint(SPEED, c.palette.core), { blend = "add", fade = true }), glow = 14,
	}, c.from)
end

-- Three waves of needles, each 0.09 s behind the last; the first leaves the muzzle at once.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 48
	local dir = vector.multiply(d, 1 / len)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.7, life = 0.12 })
	wave(F, c, dir, len, speed, 18)
	F.after(0.09, function()
		wave(F, c, dir, len, speed, 18)
	end)
	F.after(0.18, function()
		wave(F, c, dir, len, speed, 18)
	end)
	F.flare({ pos = c.to, colour = c.palette.core, size = 1.0, life = 0.2 })
	F.emit({
		amount = 12, time = 0.1, pos = c.to, vel = ZERO, acc = { x = 0, y = 0, z = 0 },
		attract = { kind = "point", origin = c.to, strength = { min = -10, max = -14 }, die_on_contact = false },
		exptime = { min = 0.2, max = 0.4 }, size = { min = 0.1, max = 0.16 },
		texture = F.tex(F.tint(F.TEX.spark, c.palette.main), { blend = "add", fade = true }), glow = 14,
	})
	F.sound("mcl_bows_hit_other", { pos = c.to, gain = 0.5, pitch = 1.9 })
end

minemon.fx.register_move("pin_missile", R)
