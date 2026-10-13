-- Hyper Beam (M2.1, T-FX-a, signature normal move): a thick white ray. The user charges a white glow with motes
-- drawn in, the beam has three layers (a wide warm halo, a white core and a hot centre line) and the stop point
-- flashes with stars. Budget: cast ~60, beam ~150, impact ~100. Launch, projectile, melee, area and impact come from
-- type:normal.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	glow = "minemon_fx_glow.png",
	mote = "minemon_fx_mote.png",
	star = "minemon_fx_star.png",
	streak = "minemon_fx_streak.png",
}
local ZERO = { x = 0, y = 0, z = 0 }

-- The charge: a big white glow swells at the mouth while motes are drawn into it.
function R.cast(F, c)
	local at = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not at then
		return false
	end
	local t = math.max(0.15, c.time or 0.5)
	F.inhale({ pos = at, tex = TEX.mote, colour = c.palette.core, radius = 1.4, amount = 40, time = t,
		size = { 0.1, 0.18 } })
	F.emit({
		amount = 1, time = t, pos = at, vel = ZERO, exptime = t + 0.1, size = 1.2,
		texture = F.tex(F.tint(TEX.glow, c.palette.core), { blend = "add", grow = { 0.2, 1.4 }, alpha = 0.95 }),
		glow = 14,
	})
	F.sound("mcl_criticals_hit.0", { pos = at, gain = 0.2, pitch = 0.7 })
end

-- The ray: three layers of light from the user to the stop point, with motes drawn along its length.
function R.beam(F, c)
	local d = vector.subtract(c.to, c.from)
	local len = vector.length(d)
	if len <= 0.01 then
		return
	end
	local speed = 40
	local dir = vector.multiply(d, 1 / len)
	local layers = {
		{ tex = TEX.glow, col = c.palette.main, size = { 0.7, 0.9 }, n = 70 },
		{ tex = TEX.glow, col = c.palette.core, size = { 0.36, 0.48 }, n = 60 },
		{ tex = TEX.streak, col = c.palette.core, size = { 0.2, 0.3 }, n = 30 },
	}
	for _, layer in ipairs(layers) do
		F.emit({
			amount = layer.n, time = 0.45, pos = c.from, vel = vector.multiply(dir, speed), exptime = len / speed,
			size = { min = layer.size[1], max = layer.size[2] },
			texture = F.tex(F.tint(layer.tex, layer.col), { blend = "add" }), glow = 14,
		}, c.from)
	end
	F.emit({
		amount = 20, time = 0.45, pos = c.from, vel = vector.multiply(dir, 10), exptime = len / 10,
		jitter = { min = { x = -0.4, y = -0.4, z = -0.4 }, max = { x = 0.4, y = 0.4, z = 0.4 } },
		size = { min = 0.12, max = 0.2 },
		texture = F.tex(F.tint(TEX.mote, c.palette.core), { blend = "add", fade = true }), glow = 14,
	}, c.from)
	F.flare({ pos = c.from, colour = c.palette.core, size = 1.3 })
	F.emit({
		amount = 1, time = 0.02, pos = c.to, vel = ZERO, exptime = 0.4, size = 1.6,
		texture = F.tex(F.tint(TEX.star, c.palette.core), { blend = "add", fade = true, grow = { 0.6, 1.2 } }),
		glow = 14,
	})
	F.ring({ pos = c.to, colour = c.palette.core, size = 0.6, grow = 2.5, life = 0.35 })
end

minemon.fx.register_move("hyper_beam", R)
