-- Bubble (M2.1 wave 2, group B, power 20, area): a breath of soap bubbles. Three or four bubbles are blown from the
-- mouth as the cast ends; the area fills with slow, wobbling bubbles that rise and drift; each bubble that touches a
-- victim pops in a small ring of light and a few droplets. Weak: small, soft and quick. The bubbles are alpha blended
-- (they are see-through), so nothing hides behind them.
-- Budget at "high": cast ~16, area ~60, impact ~24.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	bubble = "minemon_fx_bubble.png",
	droplet = "minemon_fx_droplet.png",
}
local ZERO = { x = 0, y = 0, z = 0 }

-- Wind-up: a breath out of the mouth, three bubbles float off it (no inhale: this is a blow, not a draw).
function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.6)
	F.emit({
		amount = 4, time = t, pos = at,
		vel = { min = { x = -0.5, y = 0.3, z = -0.5 }, max = { x = 0.5, y = 0.8, z = 0.5 } },
		exptime = { min = 0.9, max = 1.3 }, size = { min = 0.16, max = 0.26 },
		texture = F.tex(F.tint(TEX.bubble, c.palette.core), { blend = "alpha", alpha = 0.9 }), glow = 6,
	})
end

-- Area: bubbles fill the radius, rising slowly and swaying apart. Their life is long enough to reach the far edge.
function R.area(F, c)
	-- The bubbles gather round the victim (a fixed 2.2 m box, so they are in view), and the rest of the area is empty.
	local r = 2.2
	local ctr = c.centre
	F.emit({
		amount = 26, time = 0.5,
		pos = { min = vector.subtract(ctr, { x = r, y = 0.2, z = r }), max = vector.add(ctr, { x = r, y = 0.6, z = r }) },
		vel = { min = { x = -0.35, y = 0.35, z = -0.35 }, max = { x = 0.35, y = 0.85, z = 0.35 } },
		drag = { x = 0.4, y = 0.2, z = 0.4 },
		exptime = { min = 1.1, max = 1.8 }, size = { min = 0.22, max = 0.38 },
		texture = F.tex(F.tint(TEX.bubble, c.palette.main), { blend = "alpha", alpha = 0.85, fade = { 0.85, 0 } }),
		glow = 4,
	})
	F.emit({
		amount = 8, time = 0.5,
		pos = { min = vector.subtract(ctr, { x = r * 0.6, y = 0, z = r * 0.6 }),
			max = vector.add(ctr, { x = r * 0.6, y = 0.4, z = r * 0.6 }) },
		vel = { min = { x = -0.2, y = 0.5, z = -0.2 }, max = { x = 0.2, y = 1.0, z = 0.2 } },
		exptime = { min = 0.8, max = 1.2 }, size = { min = 0.1, max = 0.16 },
		texture = F.tex(F.tint(TEX.droplet, c.palette.core), { blend = "add", fade = true }), glow = 10,
	})
	F.sound("watersplash", { pos = ctr, gain = 0.3, pitch = 1.8 })
end

-- The pop: the bubble that touched the victim swells and vanishes in a flash of light, with droplets that fall off it.
function R.impact(F, c)
	local at = c.pos
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = 0.3, size = 0.8,
		texture = F.tex(F.tint(TEX.bubble, c.palette.core), { blend = "alpha", fade = true, grow = { 0.5, 1.5 } }),
		glow = 6,
	})
	F.flare({ pos = at, colour = c.palette.core, size = 0.7, life = 0.12 })
	F.burst({ pos = at, tex = TEX.droplet, colour = c.palette.main, amount = 6, speed = 2.5, radius = 0.1,
		life = { 0.3, 0.55 }, size = { 0.06, 0.1 }, gravity = 9.8, collide = true, bounce = 0.2, blend = "alpha",
		glow = 6 })
	F.sound("watersplash", { pos = at, gain = 0.4, pitch = 2.0 })
end

minemon.fx.register_move("bubble", R)
