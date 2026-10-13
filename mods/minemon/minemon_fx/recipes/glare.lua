-- Glare (M2.1 T-FX2-C, status, normal, paralysis): a stare that stings. The user's eyes flash, then three short pulses
-- of pale light run from its head to the target's head, each one a dashed line of speedline glints, and each pulse
-- hits with a small white flare. Straight, fast and thin: a dashed line, not a beam. Budget: cast 80, cloud 160.
-- luacheck: read_globals core vector minemon

local R = {}

local SPEED = "minemon_fx_speedline.png" -- a thin horizontal streak
local ZERO = { x = 0, y = 0, z = 0 }

-- Cast: the user's eyes flash.
function R.cast(F, c)
	local head = F.anchor(c.user, "head", 1.0)
	if not head then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.emit({
		amount = 1, time = 0.02, pos = head, vel = ZERO, exptime = t, size = 0.9,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add", grow = { 0.3, 1.0 }, alpha = 0.7 }),
		glow = 12,
	})
	F.sound("mcl_criticals_hit.0", { pos = head, gain = 0.2, pitch = 1.9 })
end

-- Cloud: three pulses run from the user's head to the target's head, each one a dashed line of glints.
function R.cloud(F, c)
	local user, target = c.user, c.target
	if not (user and user:get_pos() and target and target:get_pos()) then
		return
	end
	local from = F.anchor(user, "head", 1.0) or user:get_pos()
	local to = F.anchor(target, "head", 1.0) or target:get_pos()
	local d = vector.subtract(to, from)
	local speed = 14
	local dir = vector.multiply(d, 1 / math.max(0.01, vector.length(d)))
	for k = 0, 2 do
		F.after(k * 0.2, function()
			F.emit({
				amount = 7, time = 0.03, pos = from, vel = vector.multiply(dir, speed),
				exptime = vector.length(d) / speed, size = { min = 0.34, max = 0.46 },
				texture = F.tex(F.tint(SPEED, c.palette.core), { blend = "add", fade = true }), glow = 12,
			}, from)
			F.flare({ pos = to, colour = c.palette.core, size = 0.8, life = 0.16 })
		end)
	end
end

minemon.fx.register_move("glare", R)
