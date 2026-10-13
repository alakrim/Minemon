-- Focus Energy (M2.1 T-FX2-C, aura, fighting, critical-hit chance): concentration. Eight streaks of focus fly in from
-- all round the body and gather on the user's middle, and when they arrive the energy bursts out in a short orange
-- flash. The look is inward, then outward: it is a breath held, not a wind-up that rises. Budget: aura 120.
-- luacheck: read_globals core vector minemon

local R = {}

local SPEED = "minemon_fx_speedline.png"
local ZERO = { x = 0, y = 0, z = 0 }

function R.aura(F, c)
	local user = c.user
	if not (user and user:get_pos()) then
		return
	end
	local centre = c.centre
	for k = 0, 7 do
		local a = k * math.pi / 4
		local p = { x = centre.x + math.cos(a) * 1.3, y = centre.y + 0.1 * math.sin(a * 2), z = centre.z + math.sin(a) * 1.3 }
		local inward = vector.multiply(vector.normalize(vector.subtract(centre, p)), 3.4)
		F.emit({
			amount = 1, time = 0.02, pos = p, vel = inward, exptime = { min = 0.36, max = 0.42 }, size = 0.6,
			texture = F.tex(F.tint(SPEED, c.palette.main), { blend = "add", fade = true }), glow = 14,
		})
	end
	core.after(0.4, function()
		F.flare({ pos = centre, colour = c.palette.core, size = 1.3, life = 0.2 })
		F.burst({ pos = centre, colour = c.palette.main, amount = 16, speed = 2.4, radius = 0.2, life = { 0.3, 0.6 },
			size = { 0.1, 0.18 }, glow = 14 })
	end)
	F.emit({
		amount = 1, time = 0.4, pos = centre, vel = ZERO, exptime = 0.45, size = 1.0,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.edge), { blend = "add", grow = { 0.4, 1.0 }, alpha = 0.4 }), glow = 10,
	})
	F.sound("mcl_criticals_hit.0", { pos = centre, gain = 0.2, pitch = 0.8 })
end

minemon.fx.register_move("focus_energy", R)
