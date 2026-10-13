-- Fury Swipes (M2.1, T-FX2-a): a flurry. Many small claw flicks in every direction, not three neat cuts (Scratch is
-- the neat one). The flicks fly from the chest in melee, and on the victim they land one after another, 0.04 s
-- apart, each a short flick of light in one of four directions and a pinch of sparks. Weak (power 18): every flick
-- is small and quick. Budget: cast 10, melee 12 (six flicks), impact 24 particles over 0.25 s.
-- luacheck: read_globals core vector minemon

local R = {}

local FLICKS = {
	"minemon_fx_claw.png",
	"minemon_fx_claw.png^[transformFX",
	"minemon_fx_speedline.png",
	"minemon_fx_streak.png^[transformR90",
}
local STEP_S = 0.04
local COUNT = 6

local function flick_tex(F, c, i)
	return F.tex(F.tint(FLICKS[(i - 1) % #FLICKS + 1], c.palette.core), { blend = "add", fade = true })
end

-- Wind-up: a cloud of tiny sparks is drawn in round the chest, the flurry about to start.
function R.cast(F, c)
	local at = F.anchor(c.user, "middle", 0.6, 0.4)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.3)
	F.inhale({ pos = at, tex = F.TEX.spark, colour = c.palette.main, radius = 0.7, amount = 10, time = t,
		size = { 0.05, 0.08 } })
end

-- The flurry leaves the chest: six flicks, each in a random place across the front of the body.
function R.melee(F, c)
	for i = 1, COUNT do
		local side = (math.random() - 0.5) * 0.8
		local lift = (math.random() - 0.5) * 0.5
		local p = vector.add(c.centre, { x = -c.fwd.z * side + c.fwd.x * 0.2, y = lift, z = c.fwd.x * side + c.fwd.z * 0.2 })
		F.emit({
			amount = 1, time = 0.02, pos = p, vel = vector.multiply(c.fwd, 6), exptime = 0.12, size = 0.4,
			texture = flick_tex(F, c, i), glow = 10,
		})
	end
end

-- Six flicks land on the victim one after another, and each one leaves a few sparks behind.
function R.impact(F, c)
	local at = c.pos
	for i = 1, COUNT do
		F.after((i - 1) * STEP_S, function()
			local p = vector.add(at, { x = (math.random() - 0.5) * 0.5, y = (math.random() - 0.5) * 0.4, z = 0 })
			F.emit({
				amount = 1, time = 0.02, pos = p, vel = { x = 0, y = 0, z = 0 }, exptime = 0.14, size = 0.55,
				texture = flick_tex(F, c, i), glow = 10,
			})
			F.emit({
				amount = 2, time = 0.02, pos = p,
				vel = { min = { x = -1.2, y = 0.2, z = -0.6 }, max = { x = 1.2, y = 1.0, z = 0.6 } },
				exptime = { min = 0.12, max = 0.2 }, size = { min = 0.06, max = 0.1 },
				texture = F.tex(F.tint(F.TEX.spark, c.palette.core), { blend = "add", fade = true }), glow = 10,
			})
		end)
	end
	F.sound("default_dig_oddly_breakable_by_hand", { pos = at, gain = 0.4, pitch = 2.0 })
end

minemon.fx.register_move("fury_swipes", R)
