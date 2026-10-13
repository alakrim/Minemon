-- Barrier (M2.1 T-FX2-C, aura, psychic, defence +2): a ring of stone plates slams in round the user. Eight violet
-- plates fly in from two metres out and stop at one, standing upright round the body; a flash locks them there and
-- they hang for two seconds before they fade. The plates are the look: they arrive, they do not spin. Budget: aura
-- 120.
-- luacheck: read_globals core vector minemon

local R = {}

local SHARD = "minemon_fx_shard.png" -- an upright shard, a blade-shaped plate (tools/gen_fx_textures.py)
local ZERO = { x = 0, y = 0, z = 0 }
local PLATES = 8

function R.aura(F, c)
	local user = c.user
	if not (user and user:get_pos()) then
		return
	end
	local centre = c.centre
	local tex = F.tex(F.tint(SHARD, c.palette.core), { blend = "add", fade = { 1, 0.7 } })
	for k = 0, PLATES - 1 do
		local a = k * (2 * math.pi / PLATES)
		local dir = { x = math.cos(a), y = 0, z = math.sin(a) }
		-- Slam: each plate starts two metres out and flies in for a third of a second.
		F.emit({
			amount = 1, time = 0.02, pos = vector.add(centre, vector.multiply(dir, 2.0)),
			vel = vector.multiply(dir, -3.0), exptime = 0.36, size = 0.4,
			texture = tex, glow = 10,
		})
		-- Lock: the plate stays where it lands, one metre out, and fades.
		F.after(0.36, function()
			F.emit({
				amount = 1, time = 0.02, pos = vector.add(centre, vector.multiply(dir, 1.0)), vel = ZERO,
				exptime = 2.0, size = 0.4,
				texture = F.tex(F.tint(SHARD, c.palette.main), { blend = "add", fade = { 1, 0 } }), glow = 10,
			})
		end)
	end
	F.after(0.36, function()
		F.ring({ pos = centre, colour = c.palette.main, size = 0.5, grow = 2.6, life = 0.4 })
		F.flare({ pos = centre, colour = c.palette.core, size = 1.0, life = 0.16 })
	end)
	F.sound("default_dig_cracky", { pos = centre, gain = 0.3, pitch = 1.8 })
end

minemon.fx.register_move("barrier", R)
