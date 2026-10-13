-- Gastly (M2.1): in Cobblemon its gas is particles, so the voxel model is only the dark ball and the face. Here the
-- gas is ours: violet-black smoke that rolls off the ball and drifts, a poison-green wisp now and then, and a few
-- motes. No sprite: the part is an invisible anchor at the ball's centre. Cost: 1 attached entity, ~11 particles/s.
-- luacheck: read_globals core vector minemon

local profile = {}

profile.parts = {
	{
		name = "gas",
		bone = "",
		offset = { x = 0, y = 7, z = 0 },
		sprite = { size = 0.01 },
		emit = function(F, part, seconds)
			-- The gas shell: puffs born on the ball's surface that swell and drift up and out.
			F.on(part, {
				amount = math.floor(6 * seconds), time = seconds,
				pos = { min = { x = -0.45, y = -0.35, z = -0.45 }, max = { x = 0.45, y = 0.35, z = 0.45 } },
				vel = { min = { x = -0.15, y = 0.05, z = -0.15 }, max = { x = 0.15, y = 0.3, z = 0.15 } },
				drag = { x = 0.4, y = 0.2, z = 0.4 },
				exptime = { min = 1.2, max = 1.8 }, size = { min = 0.45, max = 0.7 },
				texture = F.tex(F.tint(F.TEX.smoke, "#4a2a66"), { blend = "alpha", alpha = 0.6, anim = "smoke",
					grow = { 0.7, 1.3 } }),
			})
			F.on(part, {
				amount = math.floor(2 * seconds), time = seconds,
				pos = { min = { x = -0.4, y = -0.4, z = -0.4 }, max = { x = 0.4, y = 0.1, z = 0.4 } },
				vel = { min = { x = -0.1, y = 0.1, z = -0.1 }, max = { x = 0.1, y = 0.3, z = 0.1 } },
				exptime = { min = 1.0, max = 1.5 }, size = { min = 0.3, max = 0.45 },
				texture = F.tex(F.tint(F.TEX.smoke, "#7aff9a"), { blend = "alpha", alpha = 0.25, anim = "smoke" }),
			})
			F.on(part, {
				amount = math.floor(3 * seconds), time = seconds,
				pos = { min = { x = -0.6, y = -0.4, z = -0.6 }, max = { x = 0.6, y = 0.5, z = 0.6 } },
				vel = { min = { x = -0.05, y = 0.05, z = -0.05 }, max = { x = 0.05, y = 0.2, z = 0.05 } },
				exptime = { min = 1.0, max = 1.6 }, size = { min = 0.06, max = 0.1 },
				texture = F.tex(F.tint(F.TEX.mote, "#c890ff"), { blend = "add", fade = { 0, 1 } }), glow = 12,
			})
		end,
	},
}

minemon.fx.register_art("gastly", profile)
