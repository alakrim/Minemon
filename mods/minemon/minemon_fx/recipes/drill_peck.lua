-- Drill Peck (M2.1, T-FX2-a): a drill. The wind-up draws wind streaks into the beak. In the blow, a helix of light
-- is laid out from the beak to the victim's middle, three turns of it, and drawn in order over 0.24 s, so the
-- spiral is seen going forward. At the victim the drill throws a whirl of feathers and streaks round the hole,
-- spinning as it leaves. Strong (power 80): big, with the spiral and the whirl. Budget: cast 12, melee 14 (one
-- spawner per point, drawn over 0.24 s), impact 34 particles.
-- luacheck: read_globals core vector minemon

local R = {}

local STREAK = "minemon_fx_streak.png"
local FEATHER = "minemon_fx_feather.png"
local HELIX_POINTS = 12
local TURNS = 3
local RADIUS = 0.22
local STEP_S = 0.02

local function middle_of(F, obj)
	return F.anchor(obj, "middle", 0.55) or vector.add(obj:get_pos(), { x = 0, y = 0.5, z = 0 })
end

-- Wind-up: streaks are drawn into the beak from the air around it.
function R.cast(F, c)
	local beak = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not beak then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.inhale({ pos = beak, tex = STREAK, colour = c.palette.core, radius = 1.1, amount = 20, time = t,
		size = { 0.1, 0.18 } })
end

-- The helix: point i of the spiral from the beak to the victim is placed at its turn and drawn at i * STEP_S.
function R.melee(F, c)
	local from = F.anchor(c.user, "mouth", 0.75, 0.6) or c.centre
	local to = middle_of(F, c.target)
	local span = vector.subtract(to, from)
	local len = vector.length(span)
	if len <= 0.01 then
		return
	end
	local dir = vector.multiply(span, 1 / len)
	local side = vector.normalize({ x = -dir.z, y = 0, z = dir.x })
	local up = { x = 0, y = 1, z = 0 }
	for i = 0, HELIX_POINTS - 1 do
		local t = i / (HELIX_POINTS - 1)
		local a = t * TURNS * 2 * math.pi
		local p = vector.add(vector.add(from, vector.multiply(span, t)),
			vector.add(vector.multiply(side, RADIUS * math.cos(a)), vector.multiply(up, RADIUS * math.sin(a))))
		core.after(i * STEP_S, function()
			F.emit({
				amount = 1, time = 0.02, pos = p, vel = vector.multiply(dir, 6), exptime = 0.14, size = 0.32,
				texture = F.tex(F.tint(STREAK, c.palette.core), { blend = "add", fade = true }), glow = 10,
			})
		end)
	end
end

-- The drill: a flash, a whirl of streaks and feathers thrown out round the hole, spinning as they leave.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.1, life = 0.12 })
	F.ring({ pos = at, colour = c.palette.main, size = 0.4, grow = 2.6, life = 0.3 })
	-- The impact context has no facing: the blow's direction is the horizontal line from the user to the victim.
	local user_pos, vp = c.user:get_pos(), c.victim and c.victim:get_pos()
	local dx, dz = vp and (vp.x - user_pos.x) or 1, vp and (vp.z - user_pos.z) or 0
	local len = math.sqrt(dx * dx + dz * dz)
	local fwd = len > 0.01 and { x = dx / len, y = 0, z = dz / len } or { x = 1, y = 0, z = 0 }
	local side = vector.normalize({ x = -fwd.z, y = 0, z = fwd.x })
	for i = 0, 11 do
		local a = i / 12 * 2 * math.pi
		local radial = vector.add(vector.multiply(side, math.cos(a)), { x = 0, y = math.sin(a), z = 0 })
		local spin = vector.add(vector.multiply(side, -math.sin(a) * 0.7), { x = 0, y = math.cos(a) * 0.7, z = 0 })
		F.emit({
			amount = 1, time = 0.02, pos = at,
			vel = vector.add(vector.multiply(radial, 3.2), vector.multiply(spin, 1.5)),
			drag = { x = 0.5, y = 0.5, z = 0.5 }, exptime = { min = 0.3, max = 0.5 }, size = 0.3,
			texture = F.tex(F.tint(STREAK, c.palette.main), { blend = "add", fade = true }), glow = 10,
		})
	end
	for i = 1, 3 do
		F.emit({
			amount = 1, time = 0.02, pos = at,
			vel = vector.add(vector.multiply(side, (i - 2) * 1.2), { x = 0, y = 1.5, z = 0 }),
			acc = { x = 0, y = -1.2, z = 0 }, exptime = 0.6, size = 0.18,
			texture = F.tex(F.tint(FEATHER, c.palette.core), { blend = "alpha", fade = true }), glow = 0,
		})
	end
	F.sound("default_dig_snappy", { pos = at, gain = 0.6, pitch = 1.5 })
end

minemon.fx.register_move("drill_peck", R)
