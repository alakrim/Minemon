-- Amnesia (M2.1 T-FX2-C, aura, psychic, special defence +2): a mind cleared. Two pink halo rings pulse out of the
-- head, and five stars pop off it one after another and float up and away, lazily spinning out. The head is the
-- subject: the stars come out of it, not out of the body. Budget: docs/ART_GUIDE.md 4 (aura 120).
-- luacheck: read_globals core vector minemon

local R = {}

function R.aura(F, c)
	local user = c.user
	if not (user and user:get_pos()) then
		return
	end
	local head = F.anchor(user, "head", 1.0) or c.centre
	F.ring({ pos = head, colour = c.palette.main, size = 0.3, grow = 2.8, life = 0.55 })
	F.after(0.15, function()
		F.ring({ pos = head, colour = c.palette.core, size = 0.25, grow = 2.2, life = 0.5 })
	end)
	for k = 0, 4 do
		F.after(0.05 + k * 0.09, function()
			local a = k * 1.26
			F.emit({
				amount = 1, time = 0.02, pos = head,
				vel = { x = math.cos(a) * 1.0, y = 1.4, z = math.sin(a) * 1.0 }, acc = { x = 0, y = -0.4, z = 0 },
				exptime = { min = 0.9, max = 1.2 }, size = 0.3,
				texture = F.tex(F.tint("minemon_fx_star.png", c.palette.core), { blend = "add", fade = true, grow = { 0.7, 1.1 } }),
				glow = 14,
			})
		end)
	end
	F.flare({ pos = head, colour = c.palette.core, size = 0.9, life = 0.16 })
	F.sound("mcl_enchanting_enchant", { pos = head, gain = 0.3, pitch = 1.5 })
end

minemon.fx.register_move("amnesia", R)
