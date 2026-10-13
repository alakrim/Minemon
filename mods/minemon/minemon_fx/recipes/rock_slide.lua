-- Rock Slide (M2.1, T-FX-b, rock, area, 75 power): the signature of rock. Boulders fall from high above the target and
-- bounce on the ground; where they land stone blocks burst out and a cloud of dust rolls up; a crater stays for seven
-- seconds. Budget: area ~190 particles (boulders 20, chips 40), 1 crater decal.
-- luacheck: read_globals core vector minemon

local R = {}

local CHUNK = "minemon_fx_chunk_spin_anim.png" -- 4 frames of 16 px: a rough chunk, spinning
local CRATER = "minemon_fx_crater.png"
local COBBLE = { name = "mcl_core:cobble" }
local LAND_S = 0.6 -- the fall of a boulder from 3.5 nodes up

local function chunk(F, colour, o)
	local t = F.tex(F.tint(CHUNK, colour), o)
	t.animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = -1 }
	return t
end

function R.area(F, c)
	local r = c.radius
	local ctr = c.centre
	-- The boulders: heavy chunks dropped from above the area, falling fast and bouncing where they land.
	F.emit({
		amount = 20, time = 0.3,
		pos = { min = vector.add(ctr, { x = -r * 0.7, y = 3.2, z = -r * 0.7 }),
			max = vector.add(ctr, { x = r * 0.7, y = 3.6, z = r * 0.7 }) },
		vel = { min = { x = -0.2, y = -0.5, z = -0.2 }, max = { x = 0.2, y = 0, z = 0.2 } },
		acc = { x = 0, y = -16, z = 0 }, exptime = { min = 0.8, max = 0.95 }, size = { min = 0.4, max = 0.55 },
		texture = chunk(F, c.palette.edge, { blend = "alpha" }), collisiondetection = true,
		bounce = { min = 0.2, max = 0.35 }, glow = 0,
	})
	-- The crash, when the boulders land: a flash, stone blocks thrown up, dust and a crater.
	core.after(LAND_S, function()
		F.flare({ pos = ctr, colour = c.palette.core, size = 1.6, life = 0.15 })
		F.ring({ pos = ctr, colour = c.palette.edge, size = 0.8, grow = r * 2.2, life = 0.5 })
		F.burst({ pos = ctr, tex = F.TEX.dust, colour = c.palette.smoke, blend = "alpha", amount = 34,
			speed = r * 1.3, radius = 0.4, life = { 0.8, 1.5 }, size = { 0.8, 1.2 }, gravity = -0.4, glow = 0 })
		F.emit({
			amount = 40, time = 0.1, pos = ctr, radius = { min = 0.2, max = 0.5, bias = 0 },
			vel = { min = { x = -r * 0.7, y = 2, z = -r * 0.7 }, max = { x = r * 0.7, y = 4.5, z = r * 0.7 } },
			acc = { x = 0, y = -14, z = 0 }, collisiondetection = true, bounce = { min = 0.2, max = 0.4 },
			exptime = { min = 0.8, max = 1.4 }, size = { min = 0.2, max = 0.35 }, node = COBBLE, glow = 0,
		})
		F.decal({ pos = ctr, tex = F.tint(CRATER, c.palette.edge) .. "^[opacity:170", size = r * 1.1, life = 7 })
		F.sound("default_place_node_hard", { pos = ctr, gain = 1.0, pitch = 0.5 })
	end)
end

minemon.fx.register_move("rock_slide", R)
