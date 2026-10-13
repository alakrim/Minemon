-- Sand Attack (M2.1 T-FX2-C, status, ground, accuracy -1): a kick of grit. The user scuffs its foot and a puff of dust
-- rises; then three throws of sand arc from the user's feet over to the target and fall on its face, where a little
-- dust hangs round the head for a second. The grains are gravity-bound: they arc and bounce, and nothing rises high.
-- Budget: docs/ART_GUIDE.md 4 (cast 80, cloud 160).
-- luacheck: read_globals core vector minemon

local R = {}

local GRAIN = "minemon_fx_mote.png"
local SAND = "#c8a050"
local DUST = "minemon_fx_dust.png"

-- Cast: the user scuffs a foot; a small puff of dust kicks up from the ground.
function R.cast(F, c)
	if not (c.user and c.user:get_pos()) then
		return false
	end
	local feet = c.user:get_pos()
	F.burst({ pos = vector.add(feet, { x = 0, y = 0.1, z = 0 }), tex = DUST, colour = c.palette.main, blend = "alpha",
		amount = 10, speed = 1.2, radius = 0.2, life = { 0.4, 0.7 }, size = { 0.2, 0.34 }, gravity = -0.2, glow = 0 })
	F.sound("default_dig_crumbly", { pos = feet, gain = 0.4, pitch = 1.1 })
end

-- Cloud: three throws of grit arc from the user's feet to the target's face.
function R.cloud(F, c)
	local user, target = c.user, c.target
	if not (user and user:get_pos() and target and target:get_pos()) then
		return
	end
	local from = vector.add(user:get_pos(), { x = 0, y = 0.4, z = 0 })
	local to = F.anchor(target, "head", 0.9) or target:get_pos()
	local d = vector.subtract(to, from)
	local horiz = vector.normalize({ x = d.x, y = 0, z = d.z })
	for k = 0, 2 do
		F.after(k * 0.25, function()
			F.emit({
				amount = 30, time = 0.05, pos = from,
				vel = { min = vector.add(vector.multiply(horiz, 5), { x = -0.6, y = 2.0, z = -0.6 }),
					max = vector.add(vector.multiply(horiz, 7), { x = 0.6, y = 3.4, z = 0.6 }) },
				acc = { x = 0, y = -9, z = 0 }, drag = { x = 0.2, y = 0, z = 0.2 },
				collisiondetection = true, bounce = { min = 0.1, max = 0.25 },
				exptime = { min = 0.6, max = 1.0 }, size = { min = 0.14, max = 0.2 },
				texture = F.tex(F.tint(GRAIN, SAND), { blend = "alpha", fade = { 1, 0.5 } }), glow = 0,
			})
		end)
	end
	-- Grit on the face: a dust that hangs round the head for a second, sinking very slightly.
	F.after(0.6, function()
		F.on(target, {
			amount = 8, time = 1.2,
			pos = { min = { x = -0.2, y = -0.1, z = -0.2 }, max = { x = 0.2, y = 0.2, z = 0.2 } },
			vel = { min = { x = -0.2, y = -0.05, z = -0.2 }, max = { x = 0.2, y = 0.05, z = 0.2 } },
			exptime = { min = 0.6, max = 1.0 }, size = { min = 0.18, max = 0.28 },
			texture = F.tex(F.tint(DUST, c.palette.main), { blend = "alpha", fade = true }), glow = 0,
		})
	end)
end

minemon.fx.register_move("sand_attack", R)
