-- Leech Life (M2.1, T-FX2-a): the life runs the wrong way. The wind-up draws yellow-green motes into the user. In
-- the blow, a stream of motes is torn out of the victim and flies back into the user, and when the stream arrives
-- the user's chest flares green: the life is taken, not given. The only move in the group whose particles travel
-- from the victim to the user. Weak (power 20). Budget: cast 10, melee 14 (flowing back), impact 22 particles.
-- luacheck: read_globals core vector minemon

local R = {}

local MOTE = "minemon_fx_mote.png"
local ARRIVE_S = 0.35 -- the stream reaches the user in about this time

local function middle_of(F, obj)
	return F.anchor(obj, "middle", 0.55) or vector.add(obj:get_pos(), { x = 0, y = 0.5, z = 0 })
end

-- Wind-up: motes are drawn into the chest of the user from the air round it.
function R.cast(F, c)
	local at = F.anchor(c.user, "middle", 0.6, 0.4)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.3)
	F.inhale({ pos = at, tex = MOTE, colour = c.palette.main, radius = 1.0, amount = 14, time = t,
		size = { 0.07, 0.12 } })
end

-- The stream: motes leave the victim's middle and fly back to the user's chest.
function R.melee(F, c)
	local from = middle_of(F, c.target)
	local to = middle_of(F, c.user)
	local back = vector.subtract(to, from)
	local len = vector.length(back)
	if len <= 0.01 then
		return
	end
	local dir = vector.multiply(back, 1 / len)
	F.emit({
		amount = 12, time = 0.12, pos = { min = vector.subtract(from, { x = 0.15, y = 0.15, z = 0.15 }),
			max = vector.add(from, { x = 0.15, y = 0.15, z = 0.15 }) },
		vel = { min = vector.multiply(dir, len / ARRIVE_S * 0.8), max = vector.multiply(dir, len / ARRIVE_S * 1.1) },
		exptime = { min = ARRIVE_S, max = ARRIVE_S + 0.1 }, size = { min = 0.16, max = 0.24 },
		texture = F.tex(F.tint(MOTE, c.palette.main), { blend = "add", fade = true }), glow = 14,
	})
end

-- The blow: a small green flash on the victim, a few motes puffed off it, and a flare in the user's chest when the
-- stream arrives.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 0.8, life = 0.1 })
	F.burst({ pos = at, tex = MOTE, colour = c.palette.main, amount = 5, speed = 1.2, life = { 0.3, 0.5 },
		size = { 0.14, 0.2 }, glow = 14 })
	local user = c.user
	core.after(ARRIVE_S, function()
		if not user:get_pos() then
			return
		end
		local chest = F.anchor(user, "middle", 0.6, 0.0)
		if chest then
			F.emit({
				amount = 1, time = 0.02, pos = chest, vel = { x = 0, y = 0, z = 0 }, exptime = 0.3, size = 1.0,
				texture = F.tex(F.tint(F.TEX.glow, c.palette.main), { blend = "add", fade = true, grow = { 0.6, 1.2 } }),
				glow = 14,
			})
		end
	end)
	F.sound("default_dig_snappy", { pos = at, gain = 0.4, pitch = 2.0 })
end

minemon.fx.register_move("leech_life", R)
