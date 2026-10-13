-- Mega Drain (M2.1 wave 2, group B, power 40, grass): a leech line. The orb is a green glow; on the hit a stream of
-- green leaves runs from the victim back to the user along the air between them, like a line of light that
-- pulls the life out, and the victim's middle flashes green where it lets go. Medium: the stream of leaves is the
-- signature (Absorb's motes are small and sparse; Giga Drain swirls).
-- Budget at "high": launch ~20, projectile ~40/s, impact ~80.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	leaf = "minemon_fx_leaf_spin_anim.png",
	mote = "minemon_fx_mote.png",
	glow = "minemon_fx_glow.png",
}
local LEAF_ANIM = { type = "vertical_frames", aspect_w = 32, aspect_h = 32, length = -1 }
local ZERO = { x = 0, y = 0, z = 0 }

local function leaf(F, colour, o)
	local t = F.tex(F.tint(TEX.leaf, colour), o)
	t.animation = LEAF_ANIM
	return t
end

-- The shot: a green flash and leaves flung forward.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.9, life = 0.12 })
	F.emit({
		amount = 8, time = 0.05, pos = c.from,
		vel = { min = vector.multiply(c.dir, 3), max = vector.multiply(c.dir, 5) },
		exptime = { min = 0.3, max = 0.5 }, size = { min = 0.12, max = 0.18 },
		texture = leaf(F, c.palette.main, { blend = "alpha", fade = { 1, 0.5 } }), glow = 4,
	})
	F.sound("default_dig_snappy", { pos = c.from, gain = 0.4, pitch = 1.6 })
end

-- The orb: a green glow with a faint trail of motes.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.glow, c.palette.main) }, visual_size = { x = 0.6, y = 0.6 },
		glow = 14 })
	F.on(c.obj, {
		amount = 16, time = 1.5, pos = ZERO, vel = { min = { x = -0.2, y = -0.2, z = -0.2 },
			max = { x = 0.2, y = 0.2, z = 0.2 } },
		exptime = { min = 0.25, max = 0.4 }, size = { min = 0.12, max = 0.18 },
		texture = F.tex(F.tint(TEX.mote, c.palette.core), { blend = "add", fade = true }), glow = 14,
	})
	return true
end

-- The drain: leaves stream from the victim back along the line to the user; the victim's middle flashes as they leave.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 1.2, life = 0.14 })
	local user = c.user
	local chest = user and user:get_pos() and F.anchor(user, "middle", 0.6) or nil
	if chest then
		local d = vector.subtract(chest, at)
		local len = vector.length(d)
		if len > 0.1 then
			local dir = vector.multiply(d, 1 / len)
			local speed = 4.0
			F.emit({
				amount = 36, time = 0.5, pos = { min = vector.subtract(at, { x = 0.15, y = 0.15, z = 0.15 }),
					max = vector.add(at, { x = 0.15, y = 0.15, z = 0.15 }) },
				vel = vector.multiply(dir, speed), jitter = { min = { x = -0.4, y = -0.4, z = -0.4 },
					max = { x = 0.4, y = 0.4, z = 0.4 } },
				exptime = len / speed + 0.2, size = { min = 0.13, max = 0.19 },
				texture = leaf(F, c.palette.main, { blend = "alpha", fade = { 1, 0.6 } }), glow = 4,
			}, at)
		end
	end
	F.ring({ pos = at, colour = c.palette.main, size = 0.3, grow = 2.4, life = 0.25 })
	F.sound("default_dig_snappy", { pos = at, gain = 0.6, pitch = 1.2 })
end

minemon.fx.register_move("mega_drain", R)
