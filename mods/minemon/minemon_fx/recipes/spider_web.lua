-- Spider Web (M2.1 T-FX2-C, status, bug, a trap that does nothing at once): the user spins silk from its mouth, then a
-- net of silk threads falls from high over the target, and a web hangs in front of the target for the cloud's life,
-- drawn with a new web texture that grows as the threads land. The web is an upright sprite: it reads from the camera,
-- where a flat ground decal would be too thin to see. Budget: docs/ART_GUIDE.md 4 (cast 80, cloud 160).
-- luacheck: read_globals core vector minemon

local R = {}

local WEB = "minemon_fx_web.png" -- a spider web disc with spokes and broken rings (tools/gen_fx_textures_c2.py)
local THREAD = "minemon_fx_streak.png"
local ZERO = { x = 0, y = 0, z = 0 }

-- Cast: silk spins off the mouth in a small swirl.
function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.inhale({ pos = at, tex = F.TEX.mote, colour = c.palette.core, radius = 0.9, amount = 14, time = t,
		size = { 0.08, 0.12 } })
	F.sound("default_dig_snappy", { pos = at, gain = 0.2, pitch = 2.6 })
end

-- Cloud: threads fall in a net over the target, and a web opens in front of it.
function R.cloud(F, c)
	local at = c.centre
	local t = c.time or 3
	F.emit({
		amount = 10, time = 0.6,
		pos = { min = { x = at.x - 0.7, y = at.y + 2.2, z = at.z - 0.7 },
			max = { x = at.x + 0.7, y = at.y + 2.8, z = at.z + 0.7 } },
		vel = { min = { x = -0.1, y = -5.0, z = -0.1 }, max = { x = 0.1, y = -4.0, z = 0.1 } },
		exptime = { min = 0.45, max = 0.6 }, size = { min = 0.16, max = 0.22 },
		texture = F.tex(F.tint(THREAD, c.palette.core), { blend = "add", fade = true }), glow = 8,
	})
	core.after(0.5, function()
		F.emit({
			amount = 1, time = 0.02, pos = vector.add(at, { x = 0, y = 0.7, z = 0 }), vel = ZERO, exptime = t - 0.5,
			size = 2.0,
			texture = F.tex(F.tint(WEB, c.palette.core), { blend = "alpha", grow = { 0.4, 1.0 }, fade = { 0.9, 0.5 } }),
			glow = 6,
		})
	end)
	F.flare({ pos = at, colour = c.palette.core, size = 0.7, life = 0.14 })
end

minemon.fx.register_move("spider_web", R)
