-- String Shot (M2.1 T-FX2-C, status, bug, speed -2): silk shot out as a dotted thread. A stream of white beads runs
-- from the user's mouth to the target; on arrival the beads wind round the target in two loose orbits, one turning the
-- other way, and loop again. The thread is the look: a line of dots, then a loop of dots. Budget: cast 80, cloud 160.
-- luacheck: read_globals core vector minemon

local R = {}

local BEAD = "minemon_fx_mote.png"
local ZERO = { x = 0, y = 0, z = 0 }

-- Cast: the beads stream from the mouth in a thin dotted line at the target.
function R.cast(F, c)
	if not (c.user and c.user:get_pos() and c.target and c.target:get_pos()) then
		return false
	end
	local at = F.anchor(c.user, "mouth", 0.75, 0.6) or c.user:get_pos()
	local dir = vector.normalize(vector.subtract(c.target:get_pos(), at))
	local t = math.max(0.15, c.time or 0.4)
	F.emit({
		amount = 14, time = t, pos = at, vel = vector.multiply(dir, 9), exptime = { min = 0.35, max = 0.45 },
		size = { min = 0.14, max = 0.18 },
		texture = F.tex(F.tint(BEAD, c.palette.core), { blend = "add", fade = true }), glow = 8,
	})
	F.sound("default_dig_snappy", { pos = at, gain = 0.2, pitch = 2.4 })
end

-- Cloud: beads orbit the target in two loops, the second turning the other way. Each loop is re-sent every 0.5 s.
function R.cloud(F, c)
	local at = c.centre
	local t = c.time or 3
	for loop = 0, 4 do
		F.after(loop * 0.5, function()
			for k = 0, 5 do
				local a = k * math.pi / 3 + loop * 0.4
				local sense = (loop % 2 == 0) and 1 or -1
				local p = { x = at.x + math.cos(a) * 0.7, y = at.y + 0.5 + 0.25 * math.sin(a * 2), z = at.z + math.sin(a) * 0.7 }
				F.emit({
					amount = 1, time = 0.02, pos = p,
					vel = { x = -math.sin(a) * 1.4 * sense, y = 0, z = math.cos(a) * 1.4 * sense },
					exptime = 0.6, size = 0.2,
					texture = F.tex(F.tint(BEAD, c.palette.core), { blend = "add", fade = true }), glow = 8,
				})
			end
		end)
	end
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t, size = 0.9,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add", grow = { 0.6, 1.0 }, alpha = 0.2 }),
		glow = 6,
	})
end

minemon.fx.register_move("string_shot", R)
