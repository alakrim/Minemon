-- Detect (M2.1 T-FX2-C, aura, fighting, priority +4): a scan. A ring of light at the feet, then a band of light climbs
-- the body in five steps, one every 0.12 s, each band a bar of speedline with a few sparks on it, the way a scanner
-- reads a figure from its feet to its head. The bands are horizontal and climb: the look is a scan, not a shield.
-- Budget: docs/ART_GUIDE.md 4 (aura 120).
-- luacheck: read_globals core vector minemon

local R = {}

local ZERO = { x = 0, y = 0, z = 0 }

function R.aura(F, c)
	local user = c.user
	if not (user and user:get_pos()) then
		return
	end
	local feet = user:get_pos()
	F.ring({ pos = vector.add(feet, { x = 0, y = 0.05, z = 0 }), colour = c.palette.main, size = 0.5, grow = 2.6,
		life = 0.5 })
	for k = 0, 4 do
		core.after(k * 0.12, function()
			local y = feet.y + 0.2 + k * 0.35
			local tone = (k % 2 == 0) and c.palette.core or c.palette.main
			F.emit({
				amount = 14, time = 0.05,
				pos = { min = { x = feet.x - 0.6, y = y - 0.05, z = feet.z - 0.6 },
					max = { x = feet.x + 0.6, y = y + 0.05, z = feet.z + 0.6 } },
				vel = ZERO, exptime = 0.4, size = 0.16,
				texture = F.tex(F.tint(F.TEX.spark, tone), { blend = "add", fade = true, grow = { 1.0, 1.3 } }), glow = 14,
			})
			F.emit({
				amount = 4, time = 0.05,
				pos = { min = { x = feet.x - 0.5, y = y - 0.05, z = feet.z - 0.5 },
					max = { x = feet.x + 0.5, y = y + 0.05, z = feet.z + 0.5 } },
				vel = ZERO, exptime = { min = 0.3, max = 0.5 }, size = { min = 0.1, max = 0.16 },
				texture = F.tex(F.tint(F.TEX.spark, c.palette.core), { blend = "add", fade = true }), glow = 14,
			})
		end)
	end
	F.sound("mcl_criticals_hit.0", { pos = feet, gain = 0.2, pitch = 0.9 })
end

minemon.fx.register_move("detect", R)
