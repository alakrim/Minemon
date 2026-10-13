-- Leer (M2.1 T-FX2-C, status, normal, defence -1): a hostile stare. The user narrows its eyes (a glint at its head),
-- then two white slit eyes open on the target's face and hold, and blink shut and open once more. The eyes are the
-- whole move: they sit where the target's face is, and no particle moves across the screen. Budget: cloud 160.
-- luacheck: read_globals core vector minemon

local R = {}

local EYE = "minemon_fx_eye.png" -- an almond eye with a slit pupil (tools/gen_fx_textures_c2.py)
local ZERO = { x = 0, y = 0, z = 0 }

-- Cast: a white glint at the user's head, as if it narrowed its eyes.
function R.cast(F, c)
	local head = F.anchor(c.user, "head", 1.0)
	if not head then
		return false
	end
	F.flare({ pos = head, colour = c.palette.core, size = 0.7, life = 0.14 })
	F.emit({
		amount = 1, time = 0.02, pos = head, vel = ZERO, exptime = (c.time or 0.4) + 0.05, size = 0.5,
		texture = F.tex(F.tint(EYE, c.palette.core), { blend = "alpha", grow = { 0.5, 1.0 }, fade = { 0.6, 0 } }),
		glow = 6,
	})
	F.sound("mcl_criticals_hit.0", { pos = head, gain = 0.2, pitch = 0.7 })
end

-- Cloud: two eyes open on the target's face (wide, then a blink), held in place; each eye is a sprite on the head.
function R.cloud(F, c)
	local target = c.target
	local head = vector.add(c.centre, { x = 0, y = 0.35, z = 0 })
	local t = c.time or 3
	local function open(z, life)
		F.emit({
			amount = 1, time = 0.02, pos = vector.add(head, { x = -0.15, y = 0, z = z }), vel = ZERO,
			exptime = life, size = 0.9,
			texture = F.tex(F.tint(EYE, c.palette.core), { blend = "alpha", grow = { 0.6, 1.0 }, fade = { 1, 0.4 } }),
			glow = 8,
		})
	end
	for _, z in ipairs({ -0.2, 0.2 }) do
		open(z, 1.2)
	end
	-- A blink, then the glare again.
	core.after(1.5, function()
		for _, z in ipairs({ -0.2, 0.2 }) do
			open(z, t - 1.5)
		end
	end)
	F.flare({ pos = head, colour = c.palette.main, size = 0.6, life = 0.2 })
end

minemon.fx.register_move("leer", R)
