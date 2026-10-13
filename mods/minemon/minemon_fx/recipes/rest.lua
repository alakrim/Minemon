-- Rest (M2.1 T-FX2-C, aura, psychic, full heal and sleep): the user drops into a blue cocoon. A soft blue glow closes
-- round the body and a ring settles on it, then three letter Zs lift off the head one after another, each a little
-- bigger, and drift up and fade. Sleep is slow and rising, the way Sleep Powder sinks: the cocoon is the look. Budget:
-- docs/ART_GUIDE.md 4 (aura 120).
-- luacheck: read_globals core vector minemon

local R = {}

local ZED = "minemon_fx_zed.png" -- a capital Z (tools/gen_fx_textures_c2.py)
local BLUE = "#bcd8ff"
local ZERO = { x = 0, y = 0, z = 0 }

function R.aura(F, c)
	local user = c.user
	if not (user and user:get_pos()) then
		return
	end
	local centre = c.centre
	local head = F.anchor(user, "head", 1.0) or centre
	F.emit({
		amount = 1, time = 0.02, pos = centre, vel = ZERO, exptime = 1.3, size = 2.2,
		texture = F.tex(F.tint(F.TEX.glow, "#8fb8ff"), { blend = "add", grow = { 0.6, 1.0 }, alpha = 0.3 }), glow = 8,
	})
	F.ring({ pos = centre, colour = BLUE, size = 0.8, grow = 2.4, life = 0.8 })
	for k = 0, 2 do
		F.after(0.2 + k * 0.45, function()
			F.emit({
				amount = 1, time = 0.02, pos = vector.add(head, { x = 0.1 * k, y = 0.1 * k, z = 0 }),
				vel = { x = 0.15, y = 0.55, z = 0 }, exptime = 1.4, size = 0.5 + 0.1 * k,
				texture = F.tex(F.tint(ZED, BLUE), { blend = "alpha", fade = { 1, 0 }, grow = { 0.8, 1.2 } }), glow = 6,
			})
		end)
	end
	F.sound("default_dig_snappy", { pos = head, gain = 0.15, pitch = 0.7 })
end

minemon.fx.register_move("rest", R)
