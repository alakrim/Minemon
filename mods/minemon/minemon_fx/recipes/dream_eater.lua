-- Dream Eater (M2.1 wave 2, group B, power 100, cast 0.6): it eats the victim's dream. During the cast, violet wisps
-- rise from the user's head; the orb is a violet glow that trails slow wisps; on the hit, the victim's dream comes out
-- of it as violet wisps and drifts back along the air to the user, who takes it in. Strong: big and slow, and the
-- wisps travel the whole way back, so the drain reads at a glance. Violet is the psychic palette's edge; the look is
-- the wisps, not runes or rings.
-- Budget at "high": cast ~30, launch ~25, projectile ~50/s, impact ~80.
-- luacheck: read_globals core vector minemon

local R = {}

local TEX = {
	wisp = "minemon_fx_wisp.png",
	glow = "minemon_fx_glow.png",
	mote = "minemon_fx_mote.png",
}
local ZERO = { x = 0, y = 0, z = 0 }
local DREAM = "#b07aff"
local DREAM_DARK = "#6a3ab0"

-- Wind-up: violet wisps rise from above the user's head and a dim glow gathers at its mouth.
function R.cast(F, c)
	local head = F.anchor(c.user, "head", 1.0, 0)
	local mouth = F.anchor(c.user, "mouth", 0.75, 0.6)
	if not head or not mouth then
		return false
	end
	local t = math.max(0.2, c.time or 0.6)
	F.emit({
		amount = 12, time = t, pos = { min = vector.subtract(head, { x = 0.4, y = 0, z = 0.4 }),
			max = vector.add(head, { x = 0.4, y = 0.2, z = 0.4 }) },
		vel = { min = { x = -0.1, y = 0.3, z = -0.1 }, max = { x = 0.1, y = 0.6, z = 0.1 } },
		exptime = { min = 0.6, max = 0.9 }, size = { min = 0.28, max = 0.4 },
		texture = F.tex(F.tint(TEX.wisp, DREAM), { blend = "alpha", alpha = 0.85, fade = true }), glow = 6,
	})
	F.emit({
		amount = 1, time = 0.02, pos = mouth, vel = ZERO, exptime = t + 0.05, size = 0.7,
		texture = F.tex(F.tint(TEX.glow, DREAM), { blend = "add", grow = { 0.2, 1.0 }, alpha = 0.8 }), glow = 14,
	})
end

-- The launch: a violet flash and slow wisps drifting off the muzzle.
function R.launch(F, c)
	F.flare({ pos = c.from, colour = DREAM, size = 1.1, life = 0.16 })
	F.emit({
		amount = 10, time = 0.1, pos = c.from,
		vel = { min = vector.multiply(c.dir, 1.5), max = vector.multiply(c.dir, 2.5) },
		exptime = { min = 0.6, max = 1.0 }, size = { min = 0.3, max = 0.42 },
		texture = F.tex(F.tint(TEX.wisp, DREAM_DARK), { blend = "alpha", alpha = 0.8, fade = true }), glow = 6,
	})
	F.sound("mcl_enchanting_enchant", { pos = c.from, gain = 0.5, pitch = 0.8 })
end

-- The orb: a violet glow with a trail of wisps that hang in the air where the orb has been.
function R.projectile(F, c)
	c.obj:set_properties({ textures = { F.tint(TEX.glow, DREAM) }, visual_size = { x = 0.9, y = 0.9 }, glow = 14 })
	F.on(c.obj, {
		amount = 24, time = 1.5, pos = { min = { x = -0.12, y = -0.12, z = -0.12 }, max = { x = 0.12, y = 0.12, z = 0.12 } },
		vel = { min = { x = -0.2, y = -0.1, z = -0.2 }, max = { x = 0.2, y = 0.3, z = 0.2 } },
		drag = { x = 0.8, y = 0.6, z = 0.8 }, exptime = { min = 0.7, max = 1.1 }, size = { min = 0.3, max = 0.44 },
		texture = F.tex(F.tint(TEX.wisp, DREAM), { blend = "alpha", alpha = 0.8, fade = { 0.8, 0 } }), glow = 6,
	})
	return true
end

-- The drain: wisps come out of the victim and stream back to the user, a long way, and a violet flash marks the start.
function R.impact(F, c)
	local at = c.pos
	F.flare({ pos = at, colour = DREAM, size = 1.4, life = 0.16 })
	local user_at = c.user and c.user:get_pos() and F.anchor(c.user, "middle", 0.6) or nil
	if user_at and c.victim and c.victim:get_pos() then
		local d = vector.subtract(user_at, at)
		local len = vector.length(d)
		if len > 0.1 then
			local dir = vector.multiply(d, 1 / len)
			local speed = 4.5
			F.emit({
				amount = 22, time = 0.7, pos = { min = vector.subtract(at, { x = 0.3, y = 0.3, z = 0.3 }),
					max = vector.add(at, { x = 0.3, y = 0.3, z = 0.3 }) },
				vel = vector.multiply(dir, speed), drag = { x = 0.2, y = 0.2, z = 0.2 }, exptime = len / speed + 0.5,
				size = { min = 0.3, max = 0.42 },
				texture = F.tex(F.tint(TEX.wisp, DREAM), { blend = "alpha", alpha = 0.85, fade = { 0.85, 0 } }),
				glow = 6,
			}, at)
		end
	end
	F.burst({ pos = at, tex = TEX.mote, colour = DREAM, amount = 14, speed = 3, radius = 0.25,
		life = { 0.4, 0.8 }, size = { 0.14, 0.2 }, gravity = -0.8, glow = 14 })
	F.sound("mcl_enchanting_enchant", { pos = at, gain = 0.8, pitch = 0.6 })
end

minemon.fx.register_move("dream_eater", R)
