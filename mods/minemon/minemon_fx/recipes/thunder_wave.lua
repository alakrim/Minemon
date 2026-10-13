-- Thunder Wave (M2.1 T-FX2-C, status, electric, paralysis): a wave of current that runs along the ground. The user
-- crackles, then a line of bolt flickers races across the floor from its feet to the target's feet, one step every
-- 0.08 s, and the target is left with a short crackle round its body. Ground-hugging and fast: Thunder Shock and
-- Thunderbolt fly in the air; this runs along the floor. Budget: cast 80, cloud 160.
-- luacheck: read_globals core vector minemon

local R = {}

local BOLT = "minemon_fx_bolt_anim.png"
local BOLT_ANIM = { type = "vertical_frames", aspect_w = 48, aspect_h = 48, length = 0.15 }
local ZERO = { x = 0, y = 0, z = 0 }
local CRACKLE = { min = { x = -0.6, y = -0.4, z = -0.6 }, max = { x = 0.6, y = 0.4, z = 0.6 } }

local function bolt(F, colour)
	local t = F.tex(F.tint(BOLT, colour), { blend = "add" })
	t.animation = BOLT_ANIM
	return t
end

-- Cast: sparks crackle round the user's body while it charges.
function R.cast(F, c)
	if not (c.user and c.user:get_pos()) then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.on(c.user, {
		amount = 16, time = t,
		pos = { min = { x = -0.3, y = 0.2, z = -0.3 }, max = { x = 0.3, y = 1.2, z = 0.3 } },
		vel = ZERO, jitter = CRACKLE, exptime = { min = 0.08, max = 0.16 }, size = { min = 0.14, max = 0.22 },
		texture = F.tex(F.tint(F.TEX.spark, c.palette.main), { blend = "add" }), glow = 14,
	})
	F.sound("lightning_thunder", { object = c.user, gain = 0.2, pitch = 2.4 })
end

-- Cloud: a line of bolt flickers runs along the ground from the user to the target, then the target crackles.
function R.cloud(F, c)
	local target = c.target
	local user = c.user
	if not (user and user:get_pos() and target and target:get_pos()) then
		return
	end
	local from, to = user:get_pos(), target:get_pos()
	local steps = 8
	for i = 0, steps do
		core.after(i * 0.08, function()
			local f = i / steps
			local p = vector.add(vector.multiply(from, 1 - f), vector.multiply(to, f))
			p.y = p.y + 0.15
			F.emit({
				amount = 2, time = 0.03, pos = p, vel = ZERO, jitter = { min = { x = -0.2, y = 0, z = -0.2 },
					max = { x = 0.2, y = 0.3, z = 0.2 } },
				exptime = { min = 0.12, max = 0.2 }, size = { min = 0.8, max = 1.0 },
				texture = bolt(F, c.palette.core), glow = 14,
			})
			F.emit({
				amount = 4, time = 0.03, pos = p, vel = { min = { x = -0.5, y = 1.0, z = -0.5 },
					max = { x = 0.5, y = 2.2, z = 0.5 } },
				exptime = { min = 0.15, max = 0.25 }, size = { min = 0.1, max = 0.16 },
				texture = F.tex(F.tint(F.TEX.spark, c.palette.main), { blend = "add", fade = true }), glow = 14,
			})
		end)
	end
	core.after(steps * 0.08 + 0.1, function()
		F.on(target, {
			amount = 12, time = 2.2,
			pos = { min = { x = -0.3, y = 0.1, z = -0.3 }, max = { x = 0.3, y = 1.2, z = 0.3 } },
			vel = ZERO, jitter = CRACKLE, exptime = { min = 0.08, max = 0.14 }, size = { min = 0.12, max = 0.18 },
			texture = F.tex(F.tint(F.TEX.spark, c.palette.core), { blend = "add" }), glow = 14,
		})
	end)
	F.sound("lightning_thunder", { pos = from, gain = 0.25, pitch = 2.2 })
end

minemon.fx.register_move("thunder_wave", R)
