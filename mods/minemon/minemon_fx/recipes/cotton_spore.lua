-- Cotton Spore (M2.1 T-FX2-C, status, grass, speed -2): cotton tufts. Fluff is shaken off the user's head and floats
-- over to the target, where a soft cloud of tufts hangs and turns, each one slow and a little bigger than the last.
-- The tufts are white and alpha-blended and drift horizontally: nothing falls, nothing rises fast. Budget: cloud 160.
-- luacheck: read_globals core vector minemon

local R = {}

local TUFT = "minemon_fx_tuft.png" -- a cotton puff (tools/gen_fx_textures_c2.py)
local ZERO = { x = 0, y = 0, z = 0 }

-- Cast: a few tufts pulled off the head, floating slowly towards the target.
function R.cast(F, c)
	if not (c.user and c.user:get_pos() and c.target and c.target:get_pos()) then
		return false
	end
	local head = F.anchor(c.user, "head", 1.0) or c.user:get_pos()
	local dir = vector.normalize(vector.subtract(c.target:get_pos(), head))
	local t = math.max(0.2, c.time or 0.4)
	F.emit({
		amount = 8, time = t, pos = head,
		vel = { min = vector.add(vector.multiply(dir, 0.7), { x = -0.2, y = 0.2, z = -0.2 }),
			max = vector.add(vector.multiply(dir, 1.2), { x = 0.2, y = 0.5, z = 0.2 }) },
		drag = { x = 1.2, y = 0.8, z = 1.2 },
		exptime = { min = 1.2, max = 1.8 }, size = { min = 0.34, max = 0.46 },
		texture = F.tex(F.tint(TUFT, "#ffffff"), { blend = "alpha", fade = { 0.9, 0 }, grow = { 0.8, 1.1 } }),
	})
	F.sound("default_dig_snappy", { pos = head, gain = 0.2, pitch = 0.8 })
end

-- Cloud: tufts hang over the target in a soft, slowly moving cloud, bigger as they get older.
function R.cloud(F, c)
	local at = c.centre
	local t = c.time or 3
	local r = (c.radius or 2.5) * 0.45
	local puff = { min = { x = at.x - r, y = at.y + 0.6, z = at.z - r },
		max = { x = at.x + r, y = at.y + 2.0, z = at.z + r } }
	F.emit({
		amount = 24, time = t, pos = puff,
		vel = { min = { x = -0.5, y = 0.0, z = -0.3 }, max = { x = 0.5, y = 0.25, z = 0.3 } },
		drag = { x = 1.1, y = 0.8, z = 1.1 },
		exptime = { min = 2.0, max = 2.8 }, size = { min = 0.32, max = 0.5 },
		texture = F.tex(F.tint(TUFT, "#f4fff0"), { blend = "alpha", fade = { 0.95, 0 }, grow = { 0.8, 1.15 } }),
	})
	F.emit({
		amount = 1, time = 0.02, pos = at, vel = ZERO, exptime = t, size = 1.3,
		texture = F.tex(F.tint(F.TEX.glow, c.palette.core), { blend = "add", grow = { 0.6, 1.0 }, alpha = 0.2 }),
		glow = 4,
	})
end

minemon.fx.register_move("cotton_spore", R)
