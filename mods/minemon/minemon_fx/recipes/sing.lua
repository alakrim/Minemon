-- Sing (M2.1 T-FX2-C, status, normal, sleep at 55 percent): a sung tune as music notes. A glow swells at the mouth and
-- two notes lift off it; over the cloud's life a crowd of notes floats up round the target, swaying as they go, and
-- two rings of sound leave the target twice. The notes are the signature: no other move in the set has them. Budget:
-- docs/ART_GUIDE.md 4 (cast 80, cloud 160).
-- luacheck: read_globals core vector minemon

local R = {}

local NOTE = "minemon_fx_note.png" -- a music note (tools/gen_fx_textures_c2.py)
local ZERO = { x = 0, y = 0, z = 0 }

-- Cast: a glow at the mouth and two notes lifting off it.
function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t + 0.05, size = 0.7,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add", grow = { 0.3, 1.0 }, alpha = 0.7 }),
		glow = 10,
	})
	for k = 0, 1 do
		core.after(k * 0.18, function()
			F.emit({
				amount = 1, time = 0.02, pos = vector.add(at, { x = 0, y = 0.1 * k, z = 0 }),
				vel = { x = 0.15 * (k * 2 - 1), y = 1.0, z = 0 }, exptime = 0.9, size = 0.42,
				texture = F.tex(F.tint(NOTE, c.palette.core), { blend = "alpha", fade = { 1, 0 } }), glow = 6,
			})
		end)
	end
	F.sound("mobs_mc_cow_say", { pos = at, gain = 0.15, pitch = 2.0 })
end

-- Cloud: notes drift up round the target and sway; two sound rings leave it.
function R.cloud(F, c)
	local at = c.centre
	local t = c.time or 3
	local box = { min = { x = at.x - 1.4, y = at.y + 0.4, z = at.z - 1.4 },
		max = { x = at.x + 1.4, y = at.y + 1.6, z = at.z + 1.4 } }
	F.emit({
		amount = 14, time = t, pos = box,
		vel = { min = { x = -0.12, y = 0.35, z = -0.12 }, max = { x = 0.12, y = 0.7, z = 0.12 } },
		jitter = { min = { x = -0.15, y = 0, z = -0.15 }, max = { x = 0.15, y = 0, z = 0.15 } },
		exptime = { min = 1.6, max = 2.4 }, size = { min = 0.3, max = 0.44 },
		texture = F.tex(F.tint(NOTE, c.palette.core), { blend = "alpha", fade = { 1, 0 }, grow = { 0.8, 1.1 } }),
		glow = 4,
	})
	for _, when in ipairs({ 0.2, 1.0 }) do
		core.after(when, function()
			F.ring({ pos = at, colour = c.palette.core, size = 0.4, grow = 2.6, life = 0.6 })
		end)
	end
	F.sound("mobs_mc_cow_say", { pos = at, gain = 0.2, pitch = 1.6 })
end

minemon.fx.register_move("sing", R)
