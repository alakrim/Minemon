-- Sandstorm (M2.1 T-FX2-C, weather, rock, status cloud): sand that whirls round the target. A puff of grit kicks up at
-- the user's feet; then a ring of sand grains turns round the target, re-sent every 0.3 s at a new angle so the ring
-- spins, and a low bank of dust rolls round its foot. Sand is pushed sideways in a whirl, never thrown up: the
-- vertical speed stays low (docs/ART_GUIDE.md 4 and the M2.1 review). Budget: cloud 160.
-- luacheck: read_globals core vector minemon

local R = {}

local GRAIN = "minemon_fx_mote.png"
local DUST = "minemon_fx_dust.png"
local ZERO = { x = 0, y = 0, z = 0 }

-- Cast: a puff of grit kicks up from the user's feet.
function R.cast(F, c)
	if not (c.user and c.user:get_pos()) then
		return false
	end
	local feet = vector.add(c.user:get_pos(), { x = 0, y = 0.1, z = 0 })
	F.burst({ pos = feet, tex = DUST, colour = c.palette.main, blend = "alpha", amount = 8, speed = 1.0, radius = 0.2,
		life = { 0.5, 0.8 }, size = { 0.3, 0.45 }, gravity = -0.2, glow = 0 })
	F.sound("default_dig_crumbly", { pos = feet, gain = 0.4, pitch = 0.9 })
end

-- Cloud: a ring of sand grains turns round the target, re-sent at a new angle every 0.3 s; the dust bank at its foot
-- is pushed round with it.
function R.cloud(F, c)
	local at = c.centre
	local t = c.time or 3
	local radius = (c.radius or 2.5) * 0.65
	for step = 0, 9 do
		F.after(step * 0.3, function()
			for j = 0, 5 do
				local a = step * 0.55 + j * (2 * math.pi / 6)
				local ca, sa = math.cos(a), math.sin(a)
				local p = { x = at.x + ca * radius, y = at.y + 0.3 + 0.2 * (j % 2), z = at.z + sa * radius }
				local tangent = { x = -sa * 2.4, y = 0.1, z = ca * 2.4 }
				F.emit({
					amount = 3, time = 0.05, pos = p, vel = tangent, drag = { x = 0.4, y = 0.2, z = 0.4 },
					exptime = { min = 1.0, max = 1.4 }, size = { min = 0.1, max = 0.14 },
					texture = F.tex(F.tint(GRAIN, c.palette.main), { blend = "alpha", fade = true }), glow = 0,
				})
				F.emit({
					amount = 2, time = 0.05, pos = { x = p.x, y = at.y - 0.1, z = p.z }, vel = { x = tangent.x * 0.5, y = 0.05,
						z = tangent.z * 0.5 },
					exptime = { min = 1.2, max = 1.6 }, size = { min = 0.3, max = 0.42 },
					texture = F.tex(F.tint(DUST, c.palette.smoke), { blend = "alpha", alpha = 0.6, fade = true }), glow = 0,
				})
			end
		end)
	end
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t, size = 1.2,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "alpha", alpha = 0.2, grow = { 0.8, 1.2 } }), glow = 0,
	})
end

minemon.fx.register_move("sandstorm", R)
