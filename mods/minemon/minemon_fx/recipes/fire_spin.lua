-- Fire Spin (M2.1 wave 2, group B, power 15, accuracy 70, trap): a cage of fire. The orb is invisible: its only look is
-- a tight swirl of flame tongues that spin round it, so it reads as a whirl of fire. On the hit, eight tongues of fire
-- stand round the victim's middle in a ring and burn there for about 1.6 seconds: the victim is trapped inside it.
-- Weak: the launch is a small puff and the ring is the whole point. Small and quick to fire, the cage is what stays.
-- Budget at "high": launch ~10, projectile ~40/s, impact ~50.
-- luacheck: read_globals core vector minemon

local R = {}

local BLANK = "minemon_fx_blank.png"
local CAGE_R = 0.45
local CAGE_TONGUES = 8
local CAGE_TIME = 1.6

-- The puff: a little flame from the muzzle.
function R.launch(F, c)
	F.flames({ pos = c.from, amount = 8, size = { 0.22, 0.32 }, life = { 0.2, 0.3 }, spread = 0.05, rise = 0.6,
		time = 0.05 })
	F.sound("fire_fire", { pos = c.from, gain = 0.3, pitch = 1.6 })
end

-- The whirl: the orb is hidden; a tight ring of tongues spins round its place, and embers fall off it.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { BLANK }, visual_size = { x = 0.05, y = 0.05 }, glow = 0 })
	F.on(c.obj, {
		amount = 24, time = 1.5, pos = { min = { x = -0.22, y = -0.1, z = -0.22 }, max = { x = 0.22, y = 0.25, z = 0.22 } },
		vel = { min = { x = -0.1, y = 0.3, z = -0.1 }, max = { x = 0.1, y = 0.7, z = 0.1 } },
		exptime = { min = 0.25, max = 0.4 }, size = { min = 0.22, max = 0.32 },
		texture = F.tex(F.TEX.flame, { blend = "add", anim = "flame", grow = { 1, 0.6 } }), vertical = true, glow = 14,
	})
	return true
end

-- The cage: eight tongues of fire stand in a ring round the victim's middle for 1.6 s, and a flash marks the start.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = "#ffffff", size = 1.0, life = 0.12 })
	local ctr = at
	if c.victim and c.victim:get_pos() then
		ctr = F.anchor(c.victim, "middle", 0.5) or at
	end
	for i = 0, CAGE_TONGUES - 1 do
		local a = i / CAGE_TONGUES * 2 * math.pi
		local p = { x = ctr.x + math.cos(a) * CAGE_R, y = ctr.y - 0.1, z = ctr.z + math.sin(a) * CAGE_R }
		F.flames({ pos = p, amount = 5, size = { 0.3, 0.42 }, life = { 0.35, 0.55 }, spread = 0.03, rise = 0.9,
			time = CAGE_TIME })
	end
	F.embers({ pos = ctr, amount = 10, speed = 1.5, up = 2, radius = 0.3 })
	F.sound("fire_fire", { pos = at, gain = 0.6, pitch = 1.3 })
end

minemon.fx.register_move("fire_spin", R)
