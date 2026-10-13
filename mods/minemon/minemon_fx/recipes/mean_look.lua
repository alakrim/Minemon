-- Mean Look (M2.1 T-FX2-C, status, normal, no damage, a trap): a ring of runes closes in on the target and locks it to
-- the ground. Runes are pulled inwards from a wide ring over the cloud's life (a point attraction), and a dark seal
-- stays under the target's feet, so the place reads as pinned. The only move whose shape converges: the others spread
-- out. Budget: docs/ART_GUIDE.md 4 (cast 80, cloud 160, decal 1).
-- luacheck: read_globals core vector minemon

local R = {}

local RUNE = "minemon_fx_rune.png"
local ZERO = { x = 0, y = 0, z = 0 }

-- Cast: a few runes lift off the user's head and circle it before they are thrown at the target.
function R.cast(F, c)
	local head = F.anchor(c.user, "head", 1.0)
	if not head then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.inhale({ pos = head, tex = RUNE, colour = c.palette.edge, radius = 0.9, amount = 10, time = t,
		size = { 0.14, 0.2 } })
	F.flare({ pos = head, colour = c.palette.core, size = 0.6, life = 0.14 })
	F.sound("mcl_enchanting_enchant", { pos = head, gain = 0.2, pitch = 0.7 })
end

-- Cloud: runes are drawn inwards from a ring round the target; the seal under it is drawn at the same time.
function R.cloud(F, c)
	local at = c.centre
	local t = c.time or 3
	F.emit({
		amount = 14, time = t, pos = at,
		radius = { min = 2.0, max = 2.4, bias = 0 },
		attract = { kind = "point", origin = at, strength = { min = 1.2, max = 1.6 }, die_on_contact = false },
		vel = ZERO, exptime = { min = 1.0, max = 1.6 }, size = { min = 0.2, max = 0.28 },
		texture = F.tex(F.tint(RUNE, c.palette.edge), { blend = "alpha", fade = true }), glow = 0,
	})
	F.decal({ pos = at, tex = F.tint(F.TEX.ring, c.palette.smoke), size = 2.2, life = t, glow = 0 })
	core.after(t * 0.5, function()
		F.decal({ pos = at, tex = F.tint(F.TEX.ring, c.palette.edge), size = 1.2, life = t * 0.5, glow = 0 })
	end)
end

minemon.fx.register_move("mean_look", R)
