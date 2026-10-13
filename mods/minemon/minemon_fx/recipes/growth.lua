-- Growth (M2.1 T-FX2-C, aura, normal, attack and special attack +1): the ground answers. Ten small leaves unfurl up
-- out of the soil in a ring round the user's feet and drift up past it, a ring of light rings the feet, and a burst of
-- pale green motes goes up from the middle of the body. Leaves come up from the ground, never down from above:
-- Synthesis is the sky, Growth is the soil. Leaves are 0.2 at most (docs/ART_GUIDE.md). Budget: aura 120.
-- luacheck: read_globals core vector minemon

local R = {}

local LEAF = "minemon_fx_leaf_spin_anim.png" -- 8 frames of 16 px: a leaf that flips as it spins
local PALE = "#d8f0a0"

local function leaf(F, colour, o)
	local t = F.tex(F.tint(LEAF, colour), o)
	t.animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = -1 }
	return t
end

function R.aura(F, c)
	local user = c.user
	if not (user and user:get_pos()) then
		return
	end
	local feet = user:get_pos()
	for k = 0, 9 do
		local a = k * (2 * math.pi / 10)
		local ca, sa = math.cos(a), math.sin(a)
		local p = { x = feet.x + ca * 0.8, y = feet.y + 0.05, z = feet.z + sa * 0.8 }
		F.emit({
			amount = 3, time = 0.1, pos = p,
			vel = { min = { x = ca * 0.2, y = 0.9, z = sa * 0.2 }, max = { x = ca * 0.4, y = 1.5, z = sa * 0.4 } },
			drag = { x = 0.5, y = 0.2, z = 0.5 },
			exptime = { min = 0.9, max = 1.2 }, size = { min = 0.16, max = 0.2 },
			texture = leaf(F, PALE, { blend = "alpha", fade = { 1, 0.5 } }), glow = 0,
		})
	end
	F.ring({ pos = vector.add(feet, { x = 0, y = 0.05, z = 0 }), colour = PALE, size = 0.5, grow = 2.4, life = 0.5 })
	F.after(0.3, function()
		F.burst({ pos = c.centre, tex = F.TEX.mote, colour = "#e8ffb0", amount = 14, speed = 1.4, radius = 0.2,
			life = { 0.5, 0.9 }, size = { 0.16, 0.24 }, gravity = -0.6, glow = 14 })
	end)
	F.sound("default_grass_footstep", { pos = feet, gain = 0.25, pitch = 1.2 })
end

minemon.fx.register_move("growth", R)
