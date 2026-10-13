-- Rain Dance (M2.1 T-FX2-C, weather, water, status cloud): a ring of falling streaks round the user. Water is drawn
-- into a point above the head; then a ring of rain falls round the user, twelve streaks deep, and splashes ring out on
-- the ground in the gaps for the whole cloud. The ring is at a distance: it falls round the user, not on the camera.
-- Budget: docs/ART_GUIDE.md 4 (cast 80, cloud 160).
-- luacheck: read_globals core vector minemon

local R = {}

local DROP = "minemon_fx_drop.png" -- a tall falling drop (tools/gen_fx_textures.py)
local WATER = "#4fb2ff"
local RING = 1.9

-- Cast: water is drawn into a point above the head.
function R.cast(F, c)
	local head = F.anchor(c.user, "head", 1.0)
	if not head then
		return false
	end
	local t = math.max(0.15, c.time or 0.4)
	F.inhale({ pos = vector.add(head, { x = 0, y = 0.6, z = 0 }), tex = DROP, colour = "#8ad0ff", radius = 0.9,
		amount = 12, time = t, size = { 0.14, 0.2 } })
	F.sound("default_glass_footstep", { pos = head, gain = 0.25, pitch = 1.1 })
end

-- Cloud: a ring of rain falls round the user; splashes ring out on the ground in between.
function R.cloud(F, c)
	local user = c.user
	if not (user and user:get_pos()) then
		return
	end
	local feet = user:get_pos()
	local t = c.time or 3
	for k = 0, 11 do
		local a = k * (2 * math.pi / 12)
		local p = { x = feet.x + math.cos(a) * RING, y = feet.y + 3.0, z = feet.z + math.sin(a) * RING }
		F.emit({
			amount = 6, time = t, pos = p, vel = { x = 0, y = -6.5, z = 0 },
			jitter = { min = { x = -0.1, y = 0, z = -0.1 }, max = { x = 0.1, y = 0, z = 0.1 } },
			exptime = { min = 0.45, max = 0.6 }, size = { min = 0.2, max = 0.26 },
			texture = F.tex(F.tint(DROP, WATER), { blend = "alpha", fade = true }), glow = 0,
		})
	end
	for k = 0, 7 do
		core.after(0.3 + k * 0.35, function()
			local a = (k * 2.3) % (2 * math.pi)
			local p = { x = feet.x + math.cos(a) * RING, y = feet.y + 0.05, z = feet.z + math.sin(a) * RING }
			F.ring({ pos = p, colour = "#bfe6ff", size = 0.2, grow = 1.6, life = 0.3 })
		end)
	end
end

minemon.fx.register_move("rain_dance", R)
