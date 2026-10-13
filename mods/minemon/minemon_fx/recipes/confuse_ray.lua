-- Confuse Ray (M2.1 T-FX2-C, status, ghost, confusion): a violet ray that winds round the target. A line of violet
-- motes runs from the user's mouth to the target; then a helix of wisps climbs the target's body in a spiral, one turn
-- every second, alternating two tones so it reads as a rope of spirits. It is not a ring and not a wobble: a spiral.
-- Budget: docs/ART_GUIDE.md 4 (cast 80, cloud 160). Totals at "high": cast ~20, cloud ~50 across the helix.
-- luacheck: read_globals core vector minemon

local R = {}

local WISP = "minemon_fx_wisp.png"
local ZERO = { x = 0, y = 0, z = 0 }

-- Cast: violet motes stream from the mouth along the ray to the target.
function R.cast(F, c)
	if not (c.user and c.user:get_pos() and c.target and c.target:get_pos()) then
		return false
	end
	local at = F.anchor(c.user, "mouth", 0.75, 0.6) or c.user:get_pos()
	local dir = vector.normalize(vector.subtract(c.target:get_pos(), at))
	local t = math.max(0.15, c.time or 0.4)
	F.emit({
		amount = 14, time = t, pos = at,
		vel = { min = vector.multiply(dir, 5), max = vector.multiply(dir, 6.5) },
		exptime = { min = 0.35, max = 0.5 }, size = { min = 0.12, max = 0.18 },
		texture = F.tex(F.tint(F.TEX.mote, c.palette.main), { blend = "add", fade = true }), glow = 10,
	})
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t + 0.05, size = 0.7,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add", grow = { 0.3, 1.0 }, alpha = 0.7 }),
		glow = 10,
	})
	F.sound("mobs_mc_enderman_teleport_src", { pos = at, gain = 0.25, pitch = 1.3 })
end

-- Cloud: a helix of wisps climbs the target: fourteen steps, each a little higher and further round.
function R.cloud(F, c)
	local at = c.centre
	local steps = 14
	for i = 0, steps - 1 do
		core.after(i * 0.15, function()
			local a = i * 0.75
			local y = at.y - 0.2 + i * 0.12
			local p = { x = at.x + math.cos(a) * 0.5, y = y, z = at.z + math.sin(a) * 0.5 }
			local colour = (i % 2 == 0) and c.palette.main or c.palette.core
			F.emit({
				amount = 3, time = 0.05, pos = p,
				vel = { min = { x = -0.1, y = 0.1, z = -0.1 }, max = { x = 0.1, y = 0.3, z = 0.1 } },
				exptime = { min = 0.7, max = 1.0 }, size = { min = 0.22, max = 0.32 },
				texture = F.tex(F.tint(WISP, colour), { blend = "add", fade = true }), glow = 8,
			})
		end)
	end
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = (c.time or 3), size = 1.0,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.edge), { blend = "add", grow = { 0.5, 1.0 }, alpha = 0.3 }),
		glow = 6,
	})
end

minemon.fx.register_move("confuse_ray", R)
