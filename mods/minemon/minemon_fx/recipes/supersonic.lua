-- Supersonic (M2.1 T-FX2-C, status, normal, confusion): sound waves that wobble the target. Three pale rings leave the
-- user's head and fly at the target, and when they arrive the target is hit by a pulse of rings that jiggle left and
-- right, each one a little off-centre, so it reads as a shaking wave rather than a neat shockwave. Budget: cloud 160.
-- luacheck: read_globals core vector minemon

local R = {}

local ZERO = { x = 0, y = 0, z = 0 }

-- Cast: three rings leave the head one after another, flying at the target.
function R.cast(F, c)
	if not (c.user and c.user:get_pos() and c.target and c.target:get_pos()) then
		return false
	end
	local head = F.anchor(c.user, "head", 1.0) or c.user:get_pos()
	local dir = vector.normalize(vector.subtract(c.target:get_pos(), head))
	for k = 0, 2 do
		core.after(k * 0.12, function()
			F.emit({
				amount = 1, time = 0.02, pos = head, vel = vector.multiply(dir, 4.5), exptime = 0.5, size = 0.5,
				texture = F.tex(F.tint(F.TEX.ring, c.palette.core), { blend = "add", fade = true, grow = { 0.5, 1.6 } }),
				glow = 10,
			})
		end)
	end
	F.sound("default_dig_snappy", { pos = head, gain = 0.2, pitch = 2.2 })
end

-- Cloud: the target is hit by six pulses of rings, each shifted a little left or right of the last.
function R.cloud(F, c)
	local at = c.centre
	local t = c.time or 3
	local sides = { -0.22, 0.2, -0.16, 0.24, -0.2, 0.12 }
	for k = 1, 6 do
		core.after((k - 1) * (t / 6.5), function()
			local p = vector.add(at, { x = sides[k], y = (k % 2 == 0) and 0.25 or -0.1, z = 0 })
			F.ring({ pos = p, colour = (k % 2 == 0) and c.palette.core or c.palette.main, size = 0.35, grow = 2.6,
				life = 0.55 })
		end)
	end
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t, size = 1.2,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add", grow = { 0.6, 1.0 }, alpha = 0.18 }),
		glow = 6,
	})
end

minemon.fx.register_move("supersonic", R)
