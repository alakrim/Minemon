-- Charmander: THE REFERENCE ART PROFILE (M2.1, hand-made by the orchestrator; docs/ART_GUIDE.md).
-- The tail flame is the soul of the design: a painted, animated flame sprite riding on Cobblemon's locator_fire bone
-- (it follows every animation), glowing at full brightness so it reads in the dark, with embers rising off it and a
-- soft halo that the client's bloom picks up. When Charmander casts a move, the flame flares up.
-- Cost: 1 attached entity, and every 2 s one short spawner per nearby player (~10 particles/s).
-- luacheck: read_globals core vector minemon

local profile = {}

profile.parts = {
	{
		name = "tail_flame",
		bone = "locator_fire",
		-- Bone space is model units (10 = 1 node); the sprite is centred, so lift it by half its height.
		offset = { x = 0, y = 2.9, z = 0 },
		sprite = { texture = "minemon_fx_flame_anim.png", frames = 8, frame_s = 0.07, size = 0.58, aspect = 1.2 },
		emit = function(F, part, seconds)
			F.on(part, {
				amount = math.floor(7 * seconds), time = seconds,
				pos = { min = { x = -0.05, y = 0.05, z = -0.05 }, max = { x = 0.05, y = 0.15, z = 0.05 } },
				vel = { min = { x = -0.15, y = 0.5, z = -0.15 }, max = { x = 0.15, y = 1.1, z = 0.15 } },
				jitter = { min = { x = -0.6, y = 0, z = -0.6 }, max = { x = 0.6, y = 0, z = 0.6 } },
				exptime = { min = 0.5, max = 0.9 }, size = { min = 0.05, max = 0.09 },
				texture = F.tex(F.TEX.ember, { blend = "add", fade = { 1, 0.4 } }), glow = 14,
			})
			F.on(part, {
				amount = math.floor(3 * seconds), time = seconds, pos = { x = 0, y = 0, z = 0 },
				vel = { x = 0, y = 0.1, z = 0 }, exptime = { min = 0.6, max = 0.8 }, size = { min = 0.66, max = 0.84 },
				texture = F.tex(F.tint(F.TEX.glow, "#ff7a20"), { blend = "add", fade = { 0, 0.35 } }), glow = 14,
			})
		end,
	},
}

-- The flame flares up for the whole cast of any move.
function profile.cast(_F, _obj, parts, ctx)
	if parts.tail_flame then
		minemon.fx.pulse_part(parts.tail_flame, 1.7, math.max(0.2, (ctx and ctx.time) or 0.4))
	end
end

minemon.fx.register_art("charmander", profile)
