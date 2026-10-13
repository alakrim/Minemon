-- Living flames for the fire species whose models carry fire locators (M2.1, after art/charmander.lua, the
-- reference): the Charmander line's tail flames, Magmar's tail, the Cyndaquil line's back and collar flames. Each
-- flame is the reference part (an animated flame sprite riding the locator bone, embers, a soft halo), sized for the
-- species; the flames flare up while the creature casts. Cost per flame: 1 attached entity, ~10 particles/s.
-- luacheck: read_globals core vector minemon

-- One flame part on a bone. size: sprite width in nodes; the sprite is centred, so it is lifted by half its height
-- (offset in model units, 10 = 1 node).
local function flame(name, bone, size)
	return {
		name = name,
		bone = bone,
		offset = { x = 0, y = size * 5, z = 0 },
		sprite = { texture = "minemon_fx_flame_anim.png", frames = 8, frame_s = 0.07, size = size, aspect = 1.2 },
		emit = function(F, part, seconds)
			F.on(part, {
				amount = math.floor(7 * seconds), time = seconds,
				pos = { min = { x = -0.08 * size, y = 0.1 * size, z = -0.08 * size },
					max = { x = 0.08 * size, y = 0.25 * size, z = 0.08 * size } },
				vel = { min = { x = -0.15, y = 0.5, z = -0.15 }, max = { x = 0.15, y = 0.6 + size, z = 0.15 } },
				jitter = { min = { x = -0.6, y = 0, z = -0.6 }, max = { x = 0.6, y = 0, z = 0.6 } },
				exptime = { min = 0.5, max = 0.9 }, size = { min = 0.05 + 0.03 * size, max = 0.09 + 0.05 * size },
				texture = F.tex(F.TEX.ember, { blend = "add", fade = { 1, 0.4 } }), glow = 14,
			})
			F.on(part, {
				amount = math.floor(3 * seconds), time = seconds, pos = { x = 0, y = 0, z = 0 },
				vel = { x = 0, y = 0.1, z = 0 }, exptime = { min = 0.6, max = 0.8 },
				size = { min = size * 1.15, max = size * 1.45 },
				texture = F.tex(F.tint(F.TEX.glow, "#ff7a20"), { blend = "add", fade = { 0, 0.35 } }), glow = 14,
			})
		end,
	}
end

local function profile(parts)
	local p = { parts = parts }
	function p.cast(_F, _obj, by_name, ctx)
		for _, part in pairs(by_name) do
			minemon.fx.pulse_part(part, 1.6, math.max(0.2, (ctx and ctx.time) or 0.4))
		end
	end
	return p
end

minemon.fx.register_art("charmeleon", profile({ flame("tail_flame", "locator_fire", 0.7) }))
minemon.fx.register_art("charizard", profile({ flame("tail_flame", "locator_fire", 0.9) }))
minemon.fx.register_art("magmar", profile({ flame("tail_flame", "locator_fire", 0.6) }))
minemon.fx.register_art("cyndaquil", profile({ flame("back_flame", "locator_fire", 0.55) }))
minemon.fx.register_art("quilava", profile({
	flame("head_flame", "locator_fire1", 0.55),
	flame("back_flame", "locator_fire2", 0.6),
}))
minemon.fx.register_art("typhlosion", profile({ flame("collar_flame", "locator_fire", 1.0) }))
