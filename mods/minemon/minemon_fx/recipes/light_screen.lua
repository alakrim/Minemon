-- Light Screen (M2.1 T-FX2-C, aura, psychic, special defence +2 against special moves): a screen of pink light, six
-- bars of glints standing one body-length in front of the user, each bar a vertical column that shimmers and fades.
-- The bars are the look: a grille you could see through, not a curve (that is Reflect) and not a dome (that is
-- Protect). Budget: docs/ART_GUIDE.md 4 (aura 120).
-- luacheck: read_globals core vector minemon

local R = {}

local ZERO = { x = 0, y = 0, z = 0 }
local BARS = 6

local function facing(obj)
	local yaw = obj:get_yaw() or 0
	local fwd = { x = -math.sin(yaw), y = 0, z = math.cos(yaw) }
	return fwd, { x = -fwd.z, y = 0, z = fwd.x }
end

function R.aura(F, c)
	local user = c.user
	if not (user and user:get_pos()) then
		return
	end
	local centre = c.centre
	local fwd, side = facing(user)
	local base = vector.add(centre, vector.multiply(fwd, 0.9))
	for k = 0, BARS - 1 do
		local p = vector.add(base, vector.multiply(side, (k - (BARS - 1) / 2) * 0.4))
		F.emit({
			amount = 6, time = 0.12, vel = ZERO,
			pos = { min = vector.add(p, { x = 0, y = -0.5, z = 0 }), max = vector.add(p, { x = 0, y = 1.3, z = 0 }) },
			exptime = { min = 0.9, max = 1.3 }, size = { min = 0.14, max = 0.2 },
			texture = F.tex(F.tint(F.TEX.mote, c.palette.core), { blend = "add", fade = true }), glow = 10,
		})
	end
	F.ring({ pos = base, colour = c.palette.main, size = 0.3, grow = 2.0, life = 0.35 })
end

minemon.fx.register_move("light_screen", R)
