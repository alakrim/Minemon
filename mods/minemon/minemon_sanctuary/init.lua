-- minemon_sanctuary: Sanctuaries, the Pokémon Centers of the night (T-28, D-030). Glue: the rules are in
-- sanctuary_logic.lua and pc_logic.lua. This file registers the nodes and items, wires the events, the kit and the
-- forms, and owns the public API `minemon.sanctuary` (the ward, the placement, the centres).
--   structure.lua  builds the shrine with code
--   shop.lua       coins, potions, the keeper's counter and the coin drops
--   pc.lua         the PC box (also `minemon.pc`)
-- Centres are kept in mod storage ("centres"); the spawn sanctuary is placed once ("spawn_placed").
-- luacheck: read_globals core minemon vector ItemStack mcl_spawn
-- luacheck: globals minemon

local MODPATH = core.get_modpath("minemon_sanctuary")
local LOGIC = dofile(MODPATH .. "/sanctuary_logic.lua")
local STRUCT = dofile(MODPATH .. "/structure.lua")
local SHOP = dofile(MODPATH .. "/shop.lua")
local PC = dofile(MODPATH .. "/pc.lua")

local NODE = STRUCT.NODE
local STORE = core.get_mod_storage()
local KEY_CENTRES = "centres"
local KEY_SPAWN = "spawn_placed"
local KEY_KIT = "minemon:sanctuary:kit"
local KIT_CHECK_S = 2 -- the starter kit is checked this often
local CHIME = "mcl_bells_bell_stroke" -- VoxeLibre's bell, the chime of the altar
local SPARK = "minemon_sanctuary_spark.png"
local mcl_sounds = rawget(_G, "mcl_sounds")

minemon.sanctuary = minemon.sanctuary or {}
minemon.pc = PC
local API = minemon.sanctuary

local function load_saved_centres()
	local raw = STORE:get_string(KEY_CENTRES)
	if raw == "" then
		return {}
	end
	return LOGIC.load_centres(core.parse_json(raw))
end

local centres = load_saved_centres()

local function save_centres()
	STORE:set_string(KEY_CENTRES, core.write_json(centres))
end

-- Public API ---------------------------------------------------------------------------------------------------------

-- The centres (altar positions), as a copy.
function API.list()
	return LOGIC.load_centres(centres)
end

-- The centre whose ward holds pos, or nil. Inside a ward no wild creature attacks.
function API.ward_centre(pos)
	return LOGIC.warded_by(centres, pos)
end

function API.is_safe(pos)
	return API.ward_centre(pos) ~= nil
end

-- True when a wild spawn at pos is refused (within 24 nodes of a centre).
function API.blocks_spawn(pos)
	return LOGIC.spawn_refused(centres, pos)
end

-- Registers a centre. Returns true when it is new.
function API.add_centre(pos)
	local list, added = LOGIC.add_centre(centres, pos)
	if added then
		centres = list
		save_centres()
	end
	return added
end

-- Builds a sanctuary whose floor node is floor_pos (the stone under the centre). Returns the altar position (the
-- centre) or nil. The area is expected to be loaded (a player stands near it).
function API.place(floor_pos)
	local altar = STRUCT.place(floor_pos)
	if altar ~= nil then
		API.add_centre(altar)
	end
	return altar
end

-- Places the spawn sanctuary once per world: about SPAWN_OFFSET nodes from the world spawn, on dry solid ground.
-- Returns true and the altar position when it was placed now; false otherwise.
function API.ensure_spawn()
	if STORE:get_string(KEY_SPAWN) == "1" then
		return false
	end
	local ws = STRUCT.world_spawn()
	local floor = STRUCT.find_ground(ws.x, ws.z, LOGIC.ring_points)
	if floor == nil then
		core.log("warning", "[minemon_sanctuary] no ground for the spawn sanctuary near the spawn point")
		return false
	end
	local altar = API.place(floor)
	if altar == nil then
		return false
	end
	STORE:set_string(KEY_SPAWN, "1")
	core.log("action", string.format("[minemon_sanctuary] spawn sanctuary placed at %d %d %d", altar.x, altar.y,
		altar.z))
	return true, altar
end

-- Nodes --------------------------------------------------------------------------------------------------------------

local function stone_sounds()
	if mcl_sounds and mcl_sounds.node_sound_stone_defaults then
		return mcl_sounds.node_sound_stone_defaults()
	end
	return nil
end

-- A golden burst and the bell, for the player who uses the altar.
local function celebrate(player, pos)
	core.add_particlespawner({
		amount = 40,
		time = 1.2,
		minpos = { x = pos.x - 0.6, y = pos.y + 0.2, z = pos.z - 0.6 },
		maxpos = { x = pos.x + 0.6, y = pos.y + 2.2, z = pos.z + 0.6 },
		minvel = { x = -0.3, y = 0.4, z = -0.3 },
		maxvel = { x = 0.3, y = 1.2, z = 0.3 },
		minacc = { x = 0, y = -0.2, z = 0 },
		maxacc = { x = 0, y = 0, z = 0 },
		minexptime = 0.8,
		maxexptime = 1.6,
		minsize = 1,
		maxsize = 2.5,
		texture = SPARK,
		glow = 14,
	})
	core.sound_play(CHIME, { to_player = player:get_player_name(), gain = 0.6 }, true)
end

-- The altar: recall, heal the party (HP, status, PP), set the respawn above the altar, celebrate.
local function altar_use(player, pos)
	if player == nil or not player:is_player() then
		return
	end
	minemon.party.recall(player)
	minemon.party.heal_all(player)
	local spawn = { x = pos.x, y = pos.y + 1, z = pos.z }
	if mcl_spawn and mcl_spawn.set_player_spawn_pos then
		-- on_bed is false: the spawn is a plain position, not a bed. With true, mcl_spawn checks for a bed at the
		-- position and clears the spawn when there is none (mcl_spawn/init.lua get_player_spawn_pos).
		mcl_spawn.set_player_spawn_pos(player, spawn, false, false)
	end
	celebrate(player, pos)
	core.chat_send_player(player:get_player_name(), LOGIC.RESTORED)
end

core.register_node(NODE.altar, {
	description = "Sanctuary Altar",
	_doc_items_longdesc = "Right click: restores your party, refills PP, and sets your respawn point here.",
	tiles = { "minemon_sanctuary_altar.png" },
	groups = { unbreakable = 1 },
	diggable = false,
	light_source = 14,
	sounds = stone_sounds(),
	on_rightclick = function(pos, _node, clicker)
		altar_use(clicker, pos)
	end,
})

core.register_node(NODE.pc, {
	description = "Sanctuary PC",
	_doc_items_longdesc = "Right click: store creatures in the box and take them out again.",
	tiles = { "minemon_sanctuary_pc.png" },
	paramtype2 = "facedir",
	groups = { pickaxey = 2 },
	sounds = stone_sounds(),
	on_rightclick = function(_pos, _node, clicker)
		if clicker and clicker:is_player() then
			PC.open(clicker)
		end
	end,
})

core.register_node(NODE.counter, {
	description = "Keeper's Counter",
	_doc_items_longdesc = "Right click: spend your coins on potions and balls.",
	tiles = { "minemon_sanctuary_counter.png" },
	paramtype2 = "facedir",
	groups = { pickaxey = 2 },
	sounds = stone_sounds(),
	on_rightclick = function(_pos, _node, clicker)
		if clicker and clicker:is_player() then
			SHOP.open_shop(clicker)
		end
	end,
})

core.register_node(NODE.lantern, {
	description = "Sanctuary Lantern",
	_doc_items_longdesc = "A lantern of the old shrines. The night does not enter where it burns.",
	tiles = { "minemon_sanctuary_lantern.png" },
	drawtype = "glasslike",
	paramtype = "light",
	sunlight_propagates = true,
	light_source = 14,
	groups = { pickaxey = 2 },
	sounds = stone_sounds(),
})

-- Events and joins ---------------------------------------------------------------------------------------------------

local coin_rng = minemon.rng.new(9151) -- seeded, so the coin draws are repeatable (CONVENTIONS: randomness)

-- A defeated wild creature drops coins where it lay. Night doubles them.
minemon.events.register("creature_defeated", function(victim_le, _attacker)
	if type(victim_le) ~= "table" or victim_le.object == nil or not victim_le.object:is_valid() then
		return
	end
	local inst = victim_le._mm
	local pos = victim_le.object:get_pos()
	if inst == nil or pos == nil then
		return
	end
	local t = core.get_timeofday()
	SHOP.drop_coins(pos, inst.level, t < 0.2 or t > 0.8, coin_rng)
end)

-- The starter kit (3 Potions, 10 coins, and the hint) once per player, when the party is not empty.
local kit_timer = 0
core.register_globalstep(function(dtime)
	kit_timer = kit_timer + dtime
	if kit_timer < KIT_CHECK_S then
		return
	end
	kit_timer = 0
	for _, p in ipairs(core.get_connected_players()) do
		local meta = p:get_meta()
		if LOGIC.kit_due(meta:get_string(KEY_KIT) == "1", #minemon.party.get(p)) then
			meta:set_string(KEY_KIT, "1")
			local inv = p:get_inventory()
			inv:add_item("main", ItemStack("minemon:potion " .. LOGIC.KIT_POTIONS))
			inv:add_item("main", ItemStack("minemon:coin " .. LOGIC.KIT_COINS))
			core.chat_send_player(p:get_player_name(), "Starter supplies: 3 Potions and 10 coins.")
			core.chat_send_player(p:get_player_name(), LOGIC.HINT)
		end
	end
end)

-- The spawn sanctuary needs the ground around the world spawn loaded, which is not so yet when the first player joins.
-- So the placement is tried every SPAWN_RETRY_S seconds while a player is online, up to SPAWN_TRIES times; between the
-- tries the area is asked to load (core.emerge_area, asynchronous).
local SPAWN_RETRY_S = 5
local SPAWN_TRIES = 12
local SPAWN_EMERGE_R = 24
local spawn_timer = 0
local spawn_tries = 0

core.register_globalstep(function(dtime)
	if spawn_tries >= SPAWN_TRIES or STORE:get_string(KEY_SPAWN) == "1" then
		return
	end
	if #core.get_connected_players() == 0 then
		return
	end
	spawn_timer = spawn_timer + dtime
	if spawn_timer < SPAWN_RETRY_S then
		return
	end
	spawn_timer = 0
	spawn_tries = spawn_tries + 1
	if not API.ensure_spawn() then
		local ws = STRUCT.world_spawn()
		local r = SPAWN_EMERGE_R
		core.emerge_area(vector.new(ws.x - r, ws.y - 16, ws.z - r), vector.new(ws.x + r, ws.y + 16, ws.z + r))
	end
end)

core.register_on_leaveplayer(function(player)
	PC.forget(player:get_player_name())
end)

core.register_on_player_receive_fields(function(player, formname, fields)
	if formname == PC.FORM then
		return PC.on_fields(player, fields)
	end
	if formname == SHOP.FORM then
		return SHOP.on_fields(player, formname, fields)
	end
	return nil
end)

core.register_chatcommand("sanctuary", {
	description = "Place a Sanctuary with its floor under your feet (admin)",
	privs = { server = true },
	func = function(name)
		local p = core.get_player_by_name(name)
		if p == nil then
			return false, "You are not online."
		end
		local pos = vector.round(p:get_pos())
		local altar = API.place({ x = pos.x, y = pos.y - 1, z = pos.z })
		if altar == nil then
			return false, "The Sanctuary could not be placed."
		end
		return true, "A Sanctuary rises here."
	end,
})

return API
