-- Art stage (M2.1, docs/ART_GUIDE.md). Test-only: loaded by scripts/screenshot.sh through MINEMON_SHOT_EXTRA_MODS,
-- never shipped. It reads the same shot list as tests/screenshot/minemon_shots (<world>/minemon_shots.json) and acts
-- on every shot that has a "scene" table:
--
--   "scene": {
--     "at": [x, z],          scene centre on the real terrain (the surface y is found here)
--     "user": 4,             species id of the creature that acts (stands left of centre, seen from the camera)
--     "target": 19,          optional species id of the creature it faces (right of centre)
--     "d": 5,                distance between user and target (default 5); without a target the user stands at "at"
--     "move": "ember",       optional move the user casts at the target
--     "show_s": 0.3,         seconds between the move's effect start (end of cast) and the capture
--     "cast_early_s": 0,     optional: start the cast this much earlier (a negative show_s also catches the wind-up)
--     "status": "burn",      optional primary status put on the target at once (or on the user without a target)
--     "user_yaw_deg": 0,     optional facing for a portrait (0 faces the camera when the camera looks along +z)
--     "level": 20,           optional level (default 20)
--     "cam": [dx, dy, dz]    camera offset from the scene centre's ground point (default [0, 1.6, -5])
--     "mesh", "texture"      optional overrides of the user's model and skin (art style trials)
--     "lineup": [{"species": 4, "dx": -1.5, "yaw_deg": 200, "mesh": "...", "texture": "..."}, ...]
--                            or {"entity": "mod:name", "dx": 0, "y": 0.4, "yaw_deg": 180} for any registered entity
--                            optional extra creatures standing in a row (dx from the centre), for comparisons
--   }
--
-- The shot's own "pos" must equal at + cam on x and z (the helper teleports the player there); its y is replaced by
-- the ground y + cam dy. The capture happens wait_s + 1 seconds after the teleport (see minemon_shots).
--
-- luacheck: read_globals core minemon vector

local SHOTS_FILE = core.get_worldpath() .. "/minemon_shots.json"
local MATCH_R = 0.004
local POLL_S = 0.1
local CLEAR_R = 24

local scenes = {}
local active = {}
local armed = nil
local acc = 0

local function log(msg)
	core.log("action", "[minemon_stage] " .. msg)
end

local function load_scenes()
	local f = io.open(SHOTS_FILE, "rb")
	if not f then
		return
	end
	local shots = core.parse_json(f:read("*a")) or {}
	f:close()
	for _, s in ipairs(shots) do
		if type(s.scene) == "table" and type(s.scene.at) == "table" then
			s.scene.name = s.name
			s.scene.wait_s = s.wait_s or 10
			s.scene.cam_x, s.scene.cam_z = s.pos[1], s.pos[3]
			scenes[#scenes + 1] = s.scene
		end
	end
	log(#scenes .. " scenes")
end

-- The y of the first air node above walkable ground at (x, z), searching from y0 + 40 down.
local function ground_y(x, z, y0)
	for y = math.floor(y0) + 40, math.floor(y0) - 60, -1 do
		local below = core.get_node({ x = x, y = y - 1, z = z })
		local here = core.get_node({ x = x, y = y, z = z })
		local def = core.registered_nodes[below.name]
		if def and def.walkable and below.name ~= "ignore" and not core.registered_nodes[here.name].walkable then
			return y
		end
	end
	return nil
end

local function clear()
	for _, a in ipairs(active) do
		if a.obj:get_pos() then
			a.obj:remove()
		end
	end
	active = {}
end

local function spawn_fixed(pos, species_id, yaw, move_id, level)
	local obj = minemon.creatures.spawn(pos, species_id, level, nil)
	if not obj then
		log("spawn failed for species " .. tostring(species_id))
		return nil
	end
	local inst = minemon.creatures.get_instance(obj)
	inst.shiny = false
	if move_id then
		local m = minemon.data.get_move(move_id)
		inst.moves = { { id = move_id, pp = m and m.pp or 0 } }
	end
	local le = obj:get_luaentity()
	le.walk_velocity = 0
	le.run_velocity = 0
	le.passive = true
	le.order = "stand"
	le.walk_chance = 0
	obj:set_yaw(yaw)
	le.target_yaw = yaw % (2 * math.pi)
	le.delay = 0
	active[#active + 1] = { obj = obj, pos = pos, yaw = yaw }
	return obj
end

local function arm(sc, player)
	clear()
	local cx, cz = sc.at[1], sc.at[2]
	local p = player:get_pos()
	local gy = ground_y(cx, cz, p.y)
	if not gy then
		log(sc.name .. ": no ground at the scene centre")
		return
	end
	for _, obj in ipairs(core.get_objects_inside_radius({ x = cx, y = gy, z = cz }, CLEAR_R)) do
		local le = (not obj:is_player()) and obj:get_luaentity() or nil
		if le and le.is_mob then
			obj:remove()
		end
	end
	local cam = sc.cam or { 0, 1.6, -5 }
	player:set_physics_override({ gravity = 0 })
	player:set_pos({ x = sc.cam_x, y = gy + cam[2], z = sc.cam_z })
	local level = sc.level or 20
	local d = sc.d or 5
	-- Side view: the camera looks along +z, so the user stands on -x and faces +x (yaw -pi/2), the target on +x.
	local user, target
	if sc.target then
		local up = { x = cx - d / 2, y = ground_y(cx - d / 2, cz, gy) or gy, z = cz }
		local tp = { x = cx + d / 2, y = ground_y(cx + d / 2, cz, gy) or gy, z = cz }
		user = spawn_fixed(up, sc.user, -math.pi / 2, sc.move, level)
		target = spawn_fixed(tp, sc.target, math.pi / 2, nil, level)
	elseif sc.user then
		user = spawn_fixed({ x = cx, y = gy, z = cz }, sc.user, math.rad(sc.user_yaw_deg or 180), sc.move, level)
	end
	if user and (sc.mesh or sc.texture) then
		user:set_properties({ mesh = sc.mesh, textures = sc.texture and { sc.texture } or nil })
	end
	for _, e in ipairs(sc.lineup or {}) do
		local x = cx + (e.dx or 0)
		local at = { x = x, y = ground_y(x, cz, gy) or gy, z = cz + (e.dz or 0) }
		local o
		if e.entity then
			-- Any registered entity (art trials: a sprite creature, a voxel prop); it stands at "at" facing yaw_deg.
			o = core.add_entity(vector.add(at, { x = 0, y = e.y or 0, z = 0 }), e.entity)
			if o then
				o:set_yaw(math.rad(e.yaw_deg or 180))
				active[#active + 1] = { obj = o, pos = o:get_pos(), yaw = math.rad(e.yaw_deg or 180) }
			end
		else
			o = spawn_fixed(at, e.species, math.rad(e.yaw_deg or 180), nil, level)
		end
		if o and (e.mesh or e.texture) then
			o:set_properties({ mesh = e.mesh, textures = e.texture and { e.texture } or nil })
		end
	end
	if not user then
		return
	end
	if sc.status then
		minemon.combat.apply_status(target or user, sc.status, user)
	end
	if sc.move and target and sc.repeat_s then
		-- Repeat mode (effects review): cast again every repeat_s until the next scene, so any capture moment
		-- shows some phase of the move whatever the capture lag.
		local name = sc.name
		local function again()
			if armed ~= name or not user:get_pos() or not target:get_pos() then
				return
			end
			local le = user:get_luaentity()
			if le then
				le._mm_cooldown = nil
			end
			local inst = minemon.creatures.get_instance(user)
			if inst and inst.moves and inst.moves[1] then
				inst.moves[1].pp = 99
			end
			minemon.combat.use_move(user, target, sc.move)
			core.after(sc.repeat_s, again)
		end
		core.after(0.3, again)
		return
	end
	if sc.move and target then
		local m = minemon.data.get_move(sc.move)
		local delay = (sc.wait_s + 1) - m.cast_s - (sc.show_s or 0.3) - (sc.cast_early_s or 0)
		log(string.format("%s: %s in %.2f s", sc.name, sc.move, delay))
		core.after(math.max(0.05, delay), function()
			if user:get_pos() and target:get_pos() then
				local ok, why = minemon.combat.use_move(user, target, sc.move)
				log(string.format("%s use_move: %s %s", sc.name, tostring(ok), tostring(why)))
			end
		end)
	end
end

core.register_globalstep(function(dtime)
	acc = acc + dtime
	if acc < POLL_S then
		return
	end
	acc = 0
	for _, a in ipairs(active) do
		local p = a.obj:get_pos()
		if p and (math.abs(p.x - a.pos.x) > 0.05 or math.abs(p.z - a.pos.z) > 0.05) then
			a.obj:set_pos({ x = a.pos.x, y = p.y, z = a.pos.z })
		end
		local le = p and a.obj:get_luaentity()
		if le and not a.cast_started and not minemon.combat.is_busy then
			a.obj:set_yaw(a.yaw)
			le.target_yaw = a.yaw % (2 * math.pi)
			le.delay = 0
		end
	end
	for _, player in ipairs(core.get_connected_players()) do
		local p = player:get_pos()
		for _, sc in ipairs(scenes) do
			if p and math.abs(p.x - sc.cam_x) < MATCH_R and math.abs(p.z - sc.cam_z) < MATCH_R and armed ~= sc.name then
				armed = sc.name
				arm(sc, player)
			end
		end
	end
end)

-- The starter is chosen at join, so the party chooser (it opens 1 s after a join with an empty party) never covers a
-- shot. The HUD is cleared by minemon_shots.
core.register_on_joinplayer(function(player)
	if minemon.party and minemon.party.choose_starter then
		minemon.party.choose_starter(player, 4)
	end
end)

-- The starter is chosen at join, so the party chooser (it opens 1 s after a join with an empty party) never covers a
-- shot. The HUD is cleared by minemon_shots.
core.register_on_joinplayer(function(player)
	if minemon.party and minemon.party.choose_starter then
		minemon.party.choose_starter(player, 4)
	end
end)

load_scenes()
