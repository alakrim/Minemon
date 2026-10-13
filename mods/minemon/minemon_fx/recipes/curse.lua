-- Curse (signature, M2.1 T-FX-c): a rising curse. Violet wisps and dark void rise out of the ground around the target
-- for the cloud's life and fade at the top, so the place reads as cursed from afar. Silhouette: a column that
-- climbs, not a puff that hangs. Budget: docs/ART_GUIDE.md 4 (cloud 160).
-- Totals at "high": cloud ~62 per 3 s, plus a steady core glow.
-- luacheck: read_globals core vector minemon

local R = {}

local WISP = "minemon_fx_wisp.png"
local VOID_TINT = "#7a6a90"

function R.cloud(F, c)
	local at = c.centre
	local t = c.time or 3
	local radius = (c.radius or 2.5) * 0.7
	local low = vector.subtract(at, { x = radius, y = 0, z = radius })
	local high = vector.add(at, { x = radius, y = 0.4, z = radius })
	F.emit({
		amount = 36, time = t, pos = { min = low, max = high },
		vel = { min = { x = -0.1, y = 0.6, z = -0.1 }, max = { x = 0.1, y = 1.2, z = 0.1 } },
		exptime = { min = 1.2, max = 2.0 }, size = { min = 0.4, max = 0.7 },
		texture = F.tex(F.tint(WISP, c.palette.main), { blend = "add", fade = true }), glow = 8,
	})
	F.emit({
		amount = 24, time = t, pos = { min = low, max = high },
		vel = { min = { x = -0.05, y = 0.3, z = -0.05 }, max = { x = 0.05, y = 0.6, z = 0.05 } },
		exptime = { min = 1.2, max = 2.0 }, size = { min = 0.8, max = 1.2 },
		texture = F.tex(F.tint(F.TEX.smoke, VOID_TINT), { blend = "sub", alpha = 0.5, anim = "smoke" }),
	})
	F.emit({
		amount = 1, time = 0.02, pos = { x = at.x, y = at.y + 0.2, z = at.z }, vel = { x = 0, y = 0, z = 0 },
		exptime = t, size = 1.0,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.edge), { blend = "add", grow = { 0.6, 1.2 }, alpha = 0.5 }),
		glow = 6,
	})
	F.sound("mobs_mc_enderman_random.1", { pos = at, gain = 0.4, pitch = 0.5 })
end

minemon.fx.register_move("curse", R)
