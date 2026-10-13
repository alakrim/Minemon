-- Protect (M2.1 T-FX2-C, aura, normal, priority +4): a hex shell. A flash, then two rings of hexagon plates stand
-- round the user, one ring at a metre and a second, rotated half a turn, a fraction further out, so it reads as a
-- honeycomb shell. They shine and fade in about a second. Budget: docs/ART_GUIDE.md 4 (aura 120).
-- luacheck: read_globals core vector minemon

local R = {}

local HEX = "minemon_fx_hex.png" -- a flat-topped hexagon outline (tools/gen_fx_textures_c2.py)
local ZERO = { x = 0, y = 0, z = 0 }

function R.aura(F, c)
	local centre = c.centre
	F.flare({ pos = centre, colour = c.palette.core, size = 1.6, life = 0.22 })
	for layer = 0, 1 do
		F.after(layer * 0.12, function()
			local rad = 0.85 + 0.3 * layer
			local shade = (layer == 0) and c.palette.core or c.palette.main
			for k = 0, 5 do
				local a = k * math.pi / 3 + layer * math.pi / 6
				local p = { x = centre.x + math.cos(a) * rad, y = centre.y, z = centre.z + math.sin(a) * rad }
				F.emit({
					amount = 1, time = 0.02, pos = p, vel = ZERO, exptime = 0.95 - 0.2 * layer, size = 0.6,
					texture = F.tex(F.tint(HEX, shade), { blend = "add", fade = true, grow = { 0.9, 1.2 } }),
					glow = 14,
				})
			end
		end)
	end
	F.ring({ pos = centre, colour = c.palette.main, size = 0.5, grow = 3.0, life = 0.4 })
end

minemon.fx.register_move("protect", R)
