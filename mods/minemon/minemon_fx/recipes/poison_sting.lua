-- Poison Sting (M2.1 wave 2, group B, power 15, poison 30%, beam): a needle. A thin purple spike flicks from the user
-- to the victim in one line, and where it lands three drops of poison fall off the victim's body. Weak: a single thin
-- line and a few drops; quick. The look is the needle, not the goo (Sludge and Smog are the wide poison moves).
-- Budget at "high": beam ~40, impact ~20.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	shard = "minemon_fx_shard.png",
	drop = "minemon_fx_drop.png",
	glow = "minemon_fx_glow.png",
}

-- The needle: thin purple spikes along the line at 26 m/s, and a small flash at the muzzle.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 26
	local dir = vector.multiply(d, 1 / len)
	F.emit({
		amount = 12, time = 0.12, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
		size = { min = 0.2, max = 0.28 },
		texture = F.tex(F.tint(TEX.shard, c.palette.main), { blend = "alpha", fade = { 1, 0.5 } }), glow = 6,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.7, life = 0.1 })
end

-- The sting: three drops of poison fall off the victim's body, with a small purple flash.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 0.8, life = 0.1 })
	F.emit({
		amount = 3, time = 0.05, pos = at,
		vel = { min = { x = -0.3, y = 0.2, z = -0.3 }, max = { x = 0.3, y = 0.6, z = 0.3 } },
		acc = { x = 0, y = -9.8, z = 0 }, exptime = { min = 0.35, max = 0.55 }, size = { min = 0.12, max = 0.17 },
		collisiondetection = true, bounce = { min = 0.1, max = 0.2 },
		texture = F.tex(F.tint(TEX.drop, c.palette.main), { blend = "alpha", fade = true }), glow = 4,
	})
	F.sound("watersplash", { pos = at, gain = 0.3, pitch = 0.6 })
end

minemon.fx.register_move("poison_sting", R)
