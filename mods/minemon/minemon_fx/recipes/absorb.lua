-- Absorb (M2.1 wave 2, group B, power 20, grass): a small sip. The orb is a little green mote that sheds a few motes
-- as it flies; on the hit, three green motes float out of the victim and drift back to the user, and the user's chest
-- glows once when they arrive. Weak: small, soft and quick. The drain is the look: the motes go the other way.
-- Budget at "high": launch ~12, projectile ~25/s, impact ~30.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	mote = "minemon_fx_mote.png",
	glow = "minemon_fx_glow.png",
}

-- The shot: a green flash and four motes out of the muzzle.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = c.palette.core, size = 0.6, life = 0.1 })
	F.emit({
		amount = 4, time = 0.04, pos = c.from,
		vel = { min = vector.multiply(c.dir, 2), max = vector.multiply(c.dir, 3) },
		exptime = { min = 0.2, max = 0.35 }, size = { min = 0.12, max = 0.18 },
		texture = F.tex(F.tint(TEX.mote, c.palette.main), { blend = "add", fade = true }), glow = 14,
	})
end

-- The orb: a green mote with a faint glow, and small motes that drift off it.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.glow, c.palette.main) }, visual_size = { x = 0.4, y = 0.4 },
		glow = 14 })
	F.on(c.obj, {
		amount = 14, time = 1.5, pos = { min = { x = -0.06, y = -0.06, z = -0.06 }, max = { x = 0.06, y = 0.06, z = 0.06 } },
		vel = { min = { x = -0.2, y = 0, z = -0.2 }, max = { x = 0.2, y = 0.3, z = 0.2 } },
		exptime = { min = 0.3, max = 0.5 }, size = { min = 0.1, max = 0.15 },
		texture = F.tex(F.tint(TEX.mote, c.palette.core), { blend = "add", fade = true }), glow = 14,
	})
	return true
end

-- The sip: three motes lift out of the victim and float back to the user; the user's chest glows when they land.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = c.palette.core, size = 0.8, life = 0.1 })
	local user = c.user
	local chest = user and user:get_pos() and F.anchor(user, "middle", 0.6) or nil
	if chest and c.victim and c.victim:get_pos() then
		local d = vector.subtract(chest, at)
		local len = vector.length(d)
		if len > 0.1 then
			local dir = vector.multiply(d, 1 / len)
			local speed = 2.2
			F.emit({
				amount = 3, time = 0.2, pos = at, vel = vector.multiply(dir, speed),
				exptime = len / speed, size = { min = 0.12, max = 0.16 },
				texture = F.tex(F.tint(TEX.mote, c.palette.core), { blend = "add", fade = { 1, 0.3 } }), glow = 14,
			}, at)
			F.after(len / speed, function()
				if user and user:get_pos() then
					F.flare({ pos = F.anchor(user, "middle", 0.6), colour = c.palette.core, size = 0.9, life = 0.2 })
				end
			end)
		end
	end
	F.sound("default_grass_footstep", { pos = at, gain = 0.4, pitch = 1.6 })
end

minemon.fx.register_move("absorb", R)
