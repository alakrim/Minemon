-- Spore (M2.1 T-FX2-C, status, grass, sleep at 100 percent): a sure-fire spore burst. The user throws a thick spray of
-- green-gold spores at the target, and where they land they bloom: a round shell of spores flies out from the target
-- and two rings open behind it. Unlike Sleep Powder (sinking veil), the spores fly outwards, so the look is a flower
-- opening, not rain. Budget: docs/ART_GUIDE.md 4 (cast 80, cloud 160).
-- luacheck: read_globals core vector minemon

local R = {}

local SPORE = "#c8ff70"
local MOTE = "minemon_fx_mote.png"
local ZERO = { x = 0, y = 0, z = 0 }

-- Cast: a dense, fast spray from the mouth straight at the target.
function R.cast(F, c)
	if not (c.user and c.user:get_pos() and c.target and c.target:get_pos()) then
		return false
	end
	local at = F.anchor(c.user, "mouth", 0.75, 0.6) or c.user:get_pos()
	local dir = vector.normalize(vector.subtract(c.target:get_pos(), at))
	local t = math.max(0.15, c.time or 0.4)
	F.emit({
		amount = 18, time = t, pos = at,
		vel = { min = vector.multiply(dir, 4), max = vector.multiply(dir, 6) },
		jitter = { min = { x = -0.4, y = -0.4, z = -0.4 }, max = { x = 0.4, y = 0.4, z = 0.4 } },
		drag = { x = 0.6, y = 0.6, z = 0.6 },
		exptime = { min = 0.3, max = 0.5 }, size = { min = 0.1, max = 0.16 },
		texture = F.tex(F.tint(MOTE, SPORE), { blend = "add", fade = true }), glow = 12,
	})
	F.flare({ pos = at, colour = c.palette.core, size = 0.8, life = 0.14 })
	F.sound("default_grass_footstep", { pos = at, gain = 0.3, pitch = 1.6 })
end

-- Cloud: the bloom. A burst of spores flies out from the target's middle, then two rings open out of it.
function R.cloud(F, c)
	local at = c.centre
	local t = c.time or 3
	F.burst({ pos = at, tex = MOTE, colour = SPORE, amount = 60, speed = 1.8, radius = 0.25, life = { 1.2, 1.8 },
		size = { 0.2, 0.28 }, glow = 10 })
	F.ring({ pos = at, colour = c.palette.core, size = 0.4, grow = 3.2, life = 0.5 })
	core.after(0.35, function()
		F.ring({ pos = at, colour = c.palette.main, size = 0.4, grow = 2.6, life = 0.7 })
	end)
	F.emit({
		amount = 1, time = t, pos = at, vel = ZERO, exptime = t, size = 1.4,
		texture = F.tex(F.tint(F.TEX.glow, SPORE), { blend = "add", grow = { 0.6, 1.0 }, alpha = 0.3 }), glow = 8,
	})
end

minemon.fx.register_move("spore", R)
