-- Growl (M2.1 T-FX2-C, status, normal, attack -1): a bark. A fan of short, shaking dashes leaves the user's mouth in a
-- wedge towards the target, and the target is hit by three barks, each a burst of dashes that pushes outwards from its
-- middle. The dashes are horizontal (speedlines) and jitter as they fly: a rattle, not a ring. Budget: cast 80, cloud
-- 160.
-- luacheck: read_globals core vector minemon

local R = {}

local DASH = "minemon_fx_speedline.png"
local ZERO = { x = 0, y = 0, z = 0 }

local function rotate_y(v, a)
	local c, s = math.cos(a), math.sin(a)
	return { x = v.x * c - v.z * s, y = v.y, z = v.x * s + v.z * c }
end

-- Cast: the user's mouth opens and a fan of dashes is thrown out at the target.
function R.cast(F, c)
	if not (c.user and c.user:get_pos() and c.target and c.target:get_pos()) then
		return false
	end
	local at = F.anchor(c.user, "mouth", 0.75, 0.6) or c.user:get_pos()
	local dir = vector.normalize(vector.subtract(c.target:get_pos(), at))
	local t = math.max(0.15, c.time or 0.4)
	for _, spread in ipairs({ -0.35, 0, 0.35 }) do
		local d = rotate_y(dir, spread)
		F.emit({
			amount = 4, time = t, pos = at, vel = vector.multiply(d, 6),
			jitter = { min = { x = -0.3, y = -0.3, z = -0.3 }, max = { x = 0.3, y = 0.3, z = 0.3 } },
			exptime = { min = 0.25, max = 0.4 }, size = { min = 0.4, max = 0.55 },
			texture = F.tex(F.tint(DASH, c.palette.main), { blend = "add", fade = true }), glow = 8,
		})
	end
	F.sound("mobs_mc_wolf_growl", { pos = at, gain = 0.3, pitch = 1.1 })
end

-- Cloud: three barks of dashes burst out of the target's middle, each a little wider than the one before.
function R.cloud(F, c)
	local at = F.anchor(c.target, "middle", 0.55) or c.centre
	for k = 0, 2 do
		F.after(k * 0.45, function()
			F.burst({ pos = at, tex = DASH, colour = c.palette.main, amount = 10 + 2 * k, speed = 2.2 + 0.4 * k,
				radius = 0.3, life = { 0.3, 0.5 }, size = { 0.5, 0.7 }, glow = 8 })
			F.ring({ pos = at, colour = c.palette.edge, size = 0.3, grow = 2.0 + 0.6 * k, life = 0.3 })
		end)
	end
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = (c.time or 3) * 0.6, size = 1.0,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.edge), { blend = "add", grow = { 0.6, 1.0 }, alpha = 0.15 }),
		glow = 4,
	})
end

minemon.fx.register_move("growl", R)
