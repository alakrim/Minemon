-- Hyper Fang (M2.1, T-FX2-a): a bite. The jaw opens in the wind-up (two white fangs show at the mouth, one above
-- and one below). In the blow, an upper row of three fangs drops onto the victim's head and a lower row rises from
-- its feet, and they meet at the victim's middle; the snap throws white shards back from the bite. Strong (power
-- 80): the teeth are big and bright. Budget: cast 10, melee 18, impact 30 particles.
-- luacheck: read_globals core vector minemon

local R = {}

local FANG = "minemon_fx_fang.png" -- tip down: the upper teeth
local FANG_UP = "minemon_fx_fang.png^[transformFY" -- tip up: the lower teeth
local SHARD = "minemon_fx_shard.png"
local TEETH = { -1, 0, 1 }
local TOOTH_GAP = 0.2

local function right_of(fwd, k)
	return { x = -fwd.z * k, y = 0, z = fwd.x * k }
end

local function middle_of(F, obj)
	return F.anchor(obj, "middle", 0.55) or vector.add(obj:get_pos(), { x = 0, y = 0.5, z = 0 })
end

-- Wind-up: the jaw opens. A fang fades in above and below the mouth, and a glint shows between them.
function R.cast(F, c)
	local mouth = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not mouth then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.emit({
		amount = 1, time = t, pos = vector.add(mouth, { x = 0, y = 0.12, z = 0 }), vel = { x = 0, y = 0, z = 0 },
		exptime = t + 0.05, size = 0.45,
		texture = F.tex(F.tint(FANG, c.palette.core), { blend = "add", fade = true, grow = { 0.6, 1.0 } }), glow = 12,
	})
	F.emit({
		amount = 1, time = t, pos = vector.add(mouth, { x = 0, y = -0.12, z = 0 }), vel = { x = 0, y = 0, z = 0 },
		exptime = t + 0.05, size = 0.45,
		texture = F.tex(F.tint(FANG_UP, c.palette.core), { blend = "add", fade = true, grow = { 0.6, 1.0 } }), glow = 12,
	})
	F.flare({ pos = mouth, colour = c.palette.core, size = 0.5, life = 0.12 })
end

-- The bite: the upper teeth drop from above the victim's head, the lower ones rise from its feet, and they meet at
-- its middle.
function R.melee(F, c)
	local mid = middle_of(F, c.target)
	for _, k in ipairs(TEETH) do
		local side = right_of(c.fwd, k * TOOTH_GAP)
		F.emit({
			amount = 1, time = 0.02, pos = vector.add(vector.add(mid, side), { x = 0, y = 0.6, z = 0 }),
			vel = { x = 0, y = -5, z = 0 }, exptime = 0.16, size = 0.55,
			texture = F.tex(F.tint(FANG, c.palette.core), { blend = "add", fade = true }), glow = 12,
		})
		F.emit({
			amount = 1, time = 0.02, pos = vector.add(vector.add(mid, side), { x = 0, y = -0.6, z = 0 }),
			vel = { x = 0, y = 5, z = 0 }, exptime = 0.16, size = 0.55,
			texture = F.tex(F.tint(FANG_UP, c.palette.core), { blend = "add", fade = true }), glow = 12,
		})
	end
end

-- The snap: a white star where the teeth meet, and shards thrown back out of the bite.
function R.impact(F, c)
	local at = c.pos
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = { x = 0, y = 0, z = 0 }, exptime = 0.2, size = 1.4,
		texture = F.tex(F.tint("minemon_fx_impact_star.png", c.palette.core), { blend = "add", fade = true,
			grow = { 0.6, 1.1 } }), glow = 12,
	})
	F.emit({
		amount = 6, time = 0.04, pos = at, radius = { min = 0.05, max = 0.15, bias = 0 },
		vel = { min = { x = -2.5, y = -1, z = -2.5 }, max = { x = 2.5, y = 2, z = 2.5 } },
		acc = { x = 0, y = -8, z = 0 }, collisiondetection = true, bounce = { min = 0.2, max = 0.35 },
		exptime = { min = 0.3, max = 0.5 }, size = { min = 0.12, max = 0.18 },
		texture = F.tex(F.tint(SHARD, c.palette.core), { blend = "add", fade = true }), glow = 12,
	})
	F.sound("default_dig_snappy", { pos = at, gain = 0.9, pitch = 0.9 })
end

minemon.fx.register_move("hyper_fang", R)
