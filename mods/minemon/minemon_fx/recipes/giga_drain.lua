-- Giga Drain (M2.1 wave 2, group B, power 60, grass): a leaf vortex. The orb is a ball of green light with leaves
-- spinning round it; on the hit the air around the victim fills with leaves that are drawn into a spinning vortex on
-- its middle, and then the whole green whirl streams back along the line to the user. Medium-strong: the vortex is
-- the signature; Mega Drain is a straight line of leaves.
-- Budget at "high": launch ~25, projectile ~55/s, impact ~110.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	leaf = "minemon_fx_leaf_spin_anim.png",
	mote = "minemon_fx_mote.png",
	glow = "minemon_fx_glow.png",
	ring = "minemon_fx_ring.png",
}
local LEAF_ANIM = { type = "vertical_frames", aspect_w = 32, aspect_h = 32, length = -1 }
local ZERO = { x = 0, y = 0, z = 0 }

local function leaf(F, colour, o)
	local t = F.tex(F.tint(TEX.leaf, colour), o)
	t.animation = LEAF_ANIM
	return t
end

-- The shot: a green flash and a few leaves flung forward.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 1.0, life = 0.12 })
	F.emit({
		amount = 10, time = 0.05, pos = c.from,
		vel = { min = vector.multiply(c.dir, 3), max = vector.multiply(c.dir, 5) },
		exptime = { min = 0.3, max = 0.5 }, size = { min = 0.14, max = 0.2 },
		texture = leaf(F, c.palette.main, { blend = "alpha", fade = { 1, 0.5 } }), glow = 4,
	})
	F.sound("default_dig_snappy", { pos = c.from, gain = 0.5, pitch = 1.3 })
end

-- The orb: a green light the size of a fist, with leaves that spin round it (they fall off and turn as they go).
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.glow, c.palette.main) }, visual_size = { x = 0.9, y = 0.9 },
		glow = 14 })
	F.on(c.obj, {
		amount = 22, time = 1.5, pos = { min = { x = -0.3, y = -0.3, z = -0.3 }, max = { x = 0.3, y = 0.3, z = 0.3 } },
		vel = { min = { x = -0.3, y = -0.2, z = -0.3 }, max = { x = 0.3, y = 0.4, z = 0.3 } },
		drag = { x = 1.0, y = 0.6, z = 1.0 }, exptime = { min = 0.4, max = 0.7 }, size = { min = 0.14, max = 0.2 },
		texture = leaf(F, c.palette.main, { blend = "alpha", fade = { 1, 0.5 } }), glow = 4,
	})
	return true
end

-- The vortex: leaves are drawn in from the air round the victim, whirl on its middle and stream back to the user.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.4, life = 0.14 })
	F.ring({ pos = at, colour = c.palette.main, size = 0.4, grow = 3.0, life = 0.3 })
	F.emit({
		amount = 34, time = 0.4, pos = { min = vector.subtract(at, { x = 1.0, y = 0.6, z = 1.0 }),
			max = vector.add(at, { x = 1.0, y = 0.6, z = 1.0 }) },
		attract = { kind = "point", origin = at, strength = { min = 3.0, max = 4.5 }, die_on_contact = false },
		vel = ZERO, drag = { x = 0.5, y = 0.5, z = 0.5 }, exptime = { min = 0.4, max = 0.6 },
		size = { min = 0.14, max = 0.2 },
		texture = leaf(F, c.palette.main, { blend = "alpha", fade = { 1, 0.4 } }), glow = 4,
	}, at)
	local user = c.user
	local chest = user and user:get_pos() and F.anchor(user, "middle", 0.6) or nil
	if chest then
		local d = vector.subtract(chest, at)
		local len = vector.length(d)
		if len > 0.1 then
			local dir = vector.multiply(d, 1 / len)
			local speed = 3.5
			F.after(0.3, function()
				F.emit({
					amount = 18, time = 0.4, pos = { min = vector.subtract(at, { x = 0.2, y = 0.2, z = 0.2 }),
						max = vector.add(at, { x = 0.2, y = 0.2, z = 0.2 }) },
					vel = vector.multiply(dir, speed), exptime = len / speed + 0.3, size = { min = 0.14, max = 0.2 },
					texture = F.tex(F.tint(TEX.mote, c.palette.core), { blend = "add", fade = true }), glow = 14,
				}, at)
			end)
		end
	end
	F.sound("default_dig_snappy", { pos = at, gain = 0.8, pitch = 1.0 })
end

minemon.fx.register_move("giga_drain", R)
