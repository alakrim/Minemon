-- Scary Face (M2.1 T-FX2-C, status, normal, speed -2): a scowl that jabs at the target's face. A dark, spiky starburst
-- snaps onto the target's face and flickers three times, and dark smoke puffs swell round its head as it fades. No
-- eyes, no rings: the spikes are the expression, and they are dark, so the move reads as a menacing face. Budget: cast
-- 80, cloud 160; smoke at most 0.7 per particle.
-- luacheck: read_globals core vector minemon

local R = {}

local STAR = "minemon_fx_impact_star.png"
local ZERO = { x = 0, y = 0, z = 0 }

-- Cast: the user's brow darkens: a dark puff swells at its head.
function R.cast(F, c)
	local head = F.anchor(c.user, "head", 1.0)
	if not head then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.smoke({ pos = head, colour = c.palette.smoke, amount = 8, size = { 0.5, 0.7 }, life = { t, t + 0.3 },
		rise = 0.2, spread = 0.15, alpha = 0.5, time = t })
	F.sound("mobs_mc_vex_hurt", { pos = head, gain = 0.2, pitch = 0.5 })
end

-- Cloud: a dark spiky starburst on the target's face, flickering, with dark smoke round the head.
function R.cloud(F, c)
	local head = (c.target and F.anchor(c.target, "head", 1.0)) or c.centre
	local t = c.time or 3
	for k = 0, 2 do
		core.after(k * 0.6, function()
			F.emit({
				amount = 1, time = 0.02, pos = head, vel = ZERO, exptime = 0.7, size = 1.6 + 0.2 * k,
				texture = F.tex(F.tint(STAR, "#2e2630"), { blend = "alpha", fade = { 1, 0 }, grow = { 0.7, 1.2 } }),
				glow = 0,
			})
		end)
	end
	F.smoke({ pos = head, colour = "#4a4048", amount = 10, size = { 0.5, 0.7 }, life = { 1.0, 1.4 },
		rise = 0.15, spread = 0.35, alpha = 0.4, time = t })
end

minemon.fx.register_move("scary_face", R)
