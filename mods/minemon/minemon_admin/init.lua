-- minemon_admin: the admin panel (T-33, D-033). /admin opens it: Tuning (the live knobs and their presets), Spawn,
-- Player and World. Glue only. The field parsing, presets and formspec strings are in admin_logic.lua (pure,
-- busted-tested). Every action checks the minemon_admin privilege on the server, because formspec fields can be
-- forged. The actions are on minemon.admin; they take a player (an ObjectRef, or a fake with the same methods in
-- tests) and return ok, text (and for spawns, the objects).
-- luacheck: read_globals core vector ItemStack mcl_util
-- luacheck: globals minemon

local MODPATH = core.get_modpath("minemon_admin")
local A = dofile(MODPATH .. "/admin_logic.lua")

local PRIV = "minemon_admin"
local FORM = "minemon_admin:panel"
local PREFIX = "[admin] "
local NOT_ALLOWED = "You may not use the admin panel."
local EYE_HEIGHT = 1.625
local SEARCH_NODES = 8 -- up and down, for the ground under a spawn spot
local WILD_BOND = 70 -- the bond of a creature given to the player (as a capture starts it, T-30 aside)
local GIVE_BALL = "poke_ball"
local FIELD_MAX = 64 -- the longest text kept from a submitted field
local FLY_PRIVS = { fly = true, fast = true, noclip = true }
local LIFE_COMMANDS = { give = "lives_give", revive = "lives_revive" }

minemon.admin = minemon.admin or {}
local API = minemon.admin
API.logic = A

core.register_privilege(PRIV, {
	description = "Use the admin panel (/admin): live tuning, spawns, items, time and teleports.",
	give_to_singleplayer = true,
	give_to_admin = true,
})

local states = {} -- player name -> the panel state (admin_logic default_state)

-- The privilege, checked on the server. Returns the player's name, or nil.
local function gate(player)
	local name = player and player:get_player_name()
	if name == nil or name == "" or not core.check_player_privs(name, { [PRIV] = true }) then
		return nil
	end
	return name
end

local function say(name, text)
	core.chat_send_player(name, PREFIX .. text)
end

local function state_of(name)
	local st = states[name]
	if st == nil then
		st = A.default_state()
		states[name] = st
	end
	return st
end

-- What the formspec needs from the store: its defs and order, and the current values.
local function view()
	local values = {}
	for _, key in ipairs(minemon.tuning.ORDER) do
		values[key] = minemon.tuning.get(key)
	end
	return { defs = minemon.tuning.DEFS, order = minemon.tuning.ORDER, values = values }
end

local function show(player, st)
	core.show_formspec(player:get_player_name(), FORM, A.formspec(st, view()))
end

-- A species from a name or a dex number (data.get_species takes a number for the id and text for the name).
local function resolve_species(text)
	if text:match("^%d+$") then
		return minemon.data.get_species(tonumber(text))
	end
	return minemon.data.get_species(text)
end

local function name_of_inst(inst)
	local sp = minemon.data.get_species(inst.species_id)
	return sp and sp.name or "creature"
end

-- Presets and knobs ---------------------------------------------------------------------------------------------------

-- Applies a preset (Normal resets). Returns ok, text.
function API.preset(player, preset_name)
	if gate(player) == nil then
		return false, NOT_ALLOWED
	end
	local p = A.preset(preset_name)
	if p == nil then
		return false, "Unknown preset."
	end
	local changes = A.preset_changes(p.name, view().values, minemon.tuning.DEFS, minemon.tuning.ORDER)
	for _, c in ipairs(changes) do
		minemon.tuning.set(c.key, c.value)
	end
	return true, string.format("%s preset applied (%d knob%s changed).", p.name, #changes,
		#changes == 1 and "" or "s")
end

-- Sets the knobs whose t_<key> field differs from the store. Returns the number changed.
function API.apply_fields(player, fields)
	if gate(player) == nil then
		return 0
	end
	local changes = A.tuning_changes(fields, minemon.tuning.ORDER, view().values, minemon.tuning.logic.coerce)
	for _, c in ipairs(changes) do
		minemon.tuning.set(c.key, c.raw)
	end
	return #changes
end

-- One −/+ step of a number knob. dir is 1 or -1. Returns ok, text.
function API.step(player, key, dir)
	if gate(player) == nil then
		return false, NOT_ALLOWED
	end
	local def = minemon.tuning.DEFS[key]
	if def == nil or def.kind ~= "number" then
		return false, "Not a number knob."
	end
	local want = A.step(key, minemon.tuning.get(key), dir, minemon.tuning.DEFS, minemon.tuning.logic.coerce)
	local stored = minemon.tuning.set(key, want)
	return true, string.format("%s: %s", def.label, A.format_value(key, stored, minemon.tuning.DEFS))
end

-- Spawn -----------------------------------------------------------------------------------------------------------

-- A node is solid (true), air (false) or not loaded (nil).
local function solid_at(p)
	local node = core.get_node_or_nil(p)
	if node == nil then
		return nil
	end
	if node.name == "air" then
		return false
	end
	local def = core.registered_nodes[node.name]
	return def ~= nil and def.walkable ~= false
end

-- Where the i-th creature of a spawn stands: SPAWN_RANGE nodes in front of the player (the look direction, flattened),
-- fanned out to the side for later ones, on the first air node above the ground.
local function spot(player, i)
	local pos = player:get_pos()
	local dir = player:get_look_dir()
	local len = math.sqrt(dir.x * dir.x + dir.z * dir.z)
	local dx, dz = 0, 1
	if len > 1e-6 then
		dx, dz = dir.x / len, dir.z / len
	end
	local side = math.floor(i / 2) * (i % 2 == 0 and 1 or -1)
	local x = math.floor(pos.x + dx * A.SPAWN_RANGE - dz * side + 0.5)
	local z = math.floor(pos.z + dz * A.SPAWN_RANGE + dx * side + 0.5)
	local y = math.floor(pos.y + 0.5)
	for _ = 1, SEARCH_NODES do
		if solid_at(vector.new(x, y - 1, z)) ~= false then
			break
		end
		y = y - 1
	end
	for _ = 1, SEARCH_NODES do
		if solid_at(vector.new(x, y, z)) ~= true then
			break
		end
		y = y + 1
	end
	return vector.new(x, y, z)
end

-- The Dread stats of minemon_creatures' make_dread, for an instance that is not yet an entity (the level and exp move,
-- full HP). The rules are minemon.creatures.dread_rules (dread_logic.lua).
local function make_dread_inst(inst, sp, rng)
	inst.dread = true
	inst.level = minemon.creatures.dread_rules.dread_level(inst.level, rng)
	inst.exp = minemon.formulas.exp_for_level(inst.level, sp.growth_rate)
	inst.hp = minemon.instance.stats(inst, sp).hp
end

-- Gives one owned creature: the party if there is room, else the PC, as a capture does. Returns "party", "pc" or nil.
local function give_one(player, name, sp, level, flags)
	local rng = minemon.rng.new(math.floor(core.get_us_time() % 2147483646) + 1)
	local inst = minemon.instance.new(sp, level, rng)
	if flags.dread then
		make_dread_inst(inst, sp, rng)
	end
	inst.shiny = flags.shiny
	inst.owner = name
	inst.ball = GIVE_BALL
	inst.bond = WILD_BOND
	local list = minemon.party.get(player)
	if #list < A.PARTY_MAX then
		list[#list + 1] = inst
		minemon.party.set(player, list)
		return "party"
	end
	if minemon.pc ~= nil and minemon.pc.deposit(player, inst) then
		return "pc"
	end
	return nil
end

local function flags_text(flags)
	local tags = {}
	if flags.dread then
		tags[#tags + 1] = "Dread"
	end
	if flags.shiny then
		tags[#tags + 1] = "Shiny"
	end
	if flags.exhausted then
		tags[#tags + 1] = "exhausted"
	end
	return #tags > 0 and (" (" .. table.concat(tags, ", ") .. ")") or ""
end

-- The Spawn tab. params = { species, level, count (the panel's text), dread, shiny, exhausted, give (booleans) }.
-- Returns ok, text, and for a spawn the list of the objects made.
function API.spawn(player, params)
	local name = gate(player)
	if name == nil then
		return false, NOT_ALLOWED
	end
	local sp, why = A.parse_species(params.species, resolve_species)
	if sp == nil then
		return false, why
	end
	local level, lerr = A.parse_level(params.level)
	if level == nil then
		return false, "Level: " .. lerr
	end
	local count, cerr = A.parse_count(params.count)
	if count == nil then
		return false, "Count: " .. cerr
	end
	local flags = {
		dread = params.dread == true,
		shiny = params.shiny == true,
		exhausted = params.exhausted == true,
	}
	if params.give == true then
		local in_party, in_pc = 0, 0
		for _ = 1, count do
			local where = give_one(player, name, sp, level, flags)
			if where == nil then
				break
			end
			if where == "party" then
				in_party = in_party + 1
			else
				in_pc = in_pc + 1
			end
		end
		local done = in_party + in_pc
		if done == 0 then
			return false, "Your party and the PC are full."
		end
		return true, string.format("Gave %d %s Lv %d%s (%d to the party, %d to the PC).", done, sp.name, level,
			flags_text(flags), in_party, in_pc)
	end
	local objs = {}
	for i = 1, count do
		local obj = minemon.creatures.spawn(spot(player, i), sp.id, level, nil, flags.shiny)
		if obj == nil then
			break
		end
		if flags.dread then
			minemon.creatures.make_dread(obj)
		end
		if flags.exhausted then
			local inst = minemon.creatures.get_instance(obj)
			if inst ~= nil then
				minemon.creatures.damage(obj, inst.hp, nil)
			end
		end
		objs[#objs + 1] = obj
	end
	if #objs == 0 then
		return false, "The creature could not be spawned here."
	end
	return true, string.format("Spawned %d %s Lv %d%s", #objs, sp.name, level, flags_text(flags)), objs
end

-- Removes the wild creatures within CLEAR_RANGE nodes. Owned ones stay. Returns ok, text.
function API.clear_wild(player)
	if gate(player) == nil then
		return false, NOT_ALLOWED
	end
	local n = 0
	for _, obj in ipairs(core.get_objects_inside_radius(player:get_pos(), A.CLEAR_RANGE)) do
		if not obj:is_player() and minemon.creatures.get_instance(obj) ~= nil and not minemon.creatures.is_owned(obj) then
			local le = obj:get_luaentity()
			if le ~= nil then
				mcl_util.remove_entity(le)
				n = n + 1
			end
		end
	end
	return true, string.format("Cleared %d wild creature%s within %d nodes.", n, n == 1 and "" or "s", A.CLEAR_RANGE)
end

-- The first object the look ray reaches within EXHAUST_RANGE, or nil. A node first means none (as capture's odds).
local function target_of(player)
	local props = player:get_properties() or {}
	local from = vector.add(player:get_pos(), vector.new(0, props.eye_height or EYE_HEIGHT, 0))
	local to = vector.add(from, vector.multiply(player:get_look_dir(), A.EXHAUST_RANGE))
	for pt in core.raycast(from, to, true, false) do
		if pt.type == "node" then
			return nil
		end
		if pt.type == "object" and pt.ref ~= player then
			return pt.ref
		end
	end
	return nil
end

-- Exhausts the wild creature in the look ray: its HP goes to 0, as a defeat does. Returns ok, text.
function API.exhaust_target(player)
	if gate(player) == nil then
		return false, NOT_ALLOWED
	end
	local obj = target_of(player)
	local inst = obj ~= nil and minemon.creatures.get_instance(obj) or nil
	if inst == nil or minemon.creatures.is_owned(obj) then
		return false, "Look at a wild creature within " .. A.EXHAUST_RANGE .. " nodes."
	end
	if minemon.creatures.is_exhausted(obj) then
		return false, "That creature is already exhausted."
	end
	minemon.creatures.damage(obj, inst.hp, nil)
	return true, string.format("Exhausted %s Lv %d.", name_of_inst(inst), inst.level)
end

-- Player ----------------------------------------------------------------------------------------------------------

function API.heal_party(player)
	if gate(player) == nil then
		return false, NOT_ALLOWED
	end
	minemon.party.heal_all(player)
	return true, "Party healed."
end

-- Exp for the active creature. text is the panel's field. Returns ok, text.
function API.give_exp(player, text)
	if gate(player) == nil then
		return false, NOT_ALLOWED
	end
	local n, why = A.parse_exp(text)
	if n == nil then
		return false, "Exp: " .. why
	end
	local obj = minemon.party.get_active(player)
	local inst = obj ~= nil and minemon.creatures.get_instance(obj) or nil
	if inst == nil then
		return false, "No creature is out. Send one out with the Party Ball first."
	end
	minemon.growth.grant_exp(player, inst.uid, n)
	return true, string.format("Gave %d exp to %s.", n, name_of_inst(inst))
end

-- The items of one group of the Player tab (admin_logic GIVE_GROUPS). Unregistered items are skipped quietly.
function API.give_items(player, group)
	if gate(player) == nil then
		return false, NOT_ALLOWED
	end
	local list = A.GIVE_GROUPS[group]
	if list == nil then
		return false, "Unknown item group."
	end
	local inv = player.get_inventory and player:get_inventory() or nil
	local given = 0
	for _, entry in ipairs(list) do
		if core.registered_items[entry[1]] ~= nil then
			if inv ~= nil then
				local leftover = inv:add_item("main", ItemStack(entry[1] .. " " .. entry[2]))
				if not leftover:is_empty() then
					core.add_item(player:get_pos(), leftover)
				end
			end
			given = given + 1
		end
	end
	if given == 0 then
		return false, "Nothing to give: those items are not registered."
	end
	return true, "Gave " .. A.GIVE_LABELS[group] .. "."
end

-- +1 life ("give") or Revive ("revive"): runs the same code as /lives_give and /lives_revive, for the caller.
function API.lives(player, which)
	local name = gate(player)
	if name == nil then
		return false, NOT_ALLOWED
	end
	local cmd = core.registered_chatcommands[LIFE_COMMANDS[which] or ""]
	if cmd == nil then
		return false, "The lives commands are not loaded."
	end
	local ok, text = cmd.func(name, name)
	return ok == true, text or ""
end

-- World -----------------------------------------------------------------------------------------------------------

-- Sets the time of day to one of A.TIMES, by its lower-case name. Returns ok, text.
function API.set_time(player, key)
	if gate(player) == nil then
		return false, NOT_ALLOWED
	end
	for _, t in ipairs(A.TIMES) do
		if t.name:lower() == key then
			core.set_timeofday(t.value)
			return true, "Time set to " .. t.name .. "."
		end
	end
	return false, "Unknown time."
end

-- Teleports to the nearest Sanctuary altar. Returns ok, text.
function API.to_sanctuary(player)
	if gate(player) == nil then
		return false, NOT_ALLOWED
	end
	local centres = minemon.sanctuary ~= nil and minemon.sanctuary.list() or {}
	local here = player:get_pos()
	local best, best_d = nil, nil
	for _, c in ipairs(centres) do
		local d = vector.distance(here, c)
		if best_d == nil or d < best_d then
			best, best_d = c, d
		end
	end
	if best == nil then
		return false, "No Sanctuary is placed yet."
	end
	player:set_pos(vector.new(best.x, best.y + 1, best.z))
	return true, "Teleported to the Sanctuary."
end

-- Turns fly, fast and noclip on or off for the caller. Returns ok, text.
function API.toggle_fly(player)
	local name = gate(player)
	if name == nil then
		return false, NOT_ALLOWED
	end
	local privs = core.get_player_privs(name)
	local on = privs.fly ~= true
	local new = {}
	for k, v in pairs(privs) do
		if not FLY_PRIVS[k] then
			new[k] = v
		end
	end
	if on then
		for k in pairs(FLY_PRIVS) do
			new[k] = true
		end
	end
	core.set_player_privs(name, new)
	return true, on and "Fly, fast and noclip on." or "Fly, fast and noclip off."
end

-- The panel -------------------------------------------------------------------------------------------------------

-- Opens the panel for a player with the privilege. Returns true, or false.
function API.open(player)
	local name = gate(player)
	if name == nil then
		return false
	end
	show(player, state_of(name))
	return true
end

local function clip(v)
	return string.sub(tostring(v), 1, FIELD_MAX)
end

-- Keeps what was typed in the Spawn and Player fields, so a button sees it.
local function take_inputs(st, fields)
	local sp = st.spawn
	if fields.f_species ~= nil then
		sp.species = clip(fields.f_species)
	end
	if fields.f_level ~= nil then
		sp.level = clip(fields.f_level)
	end
	if fields.f_count ~= nil then
		sp.count = clip(fields.f_count)
	end
	if fields.f_dread ~= nil then
		sp.dread = fields.f_dread == "true"
	end
	if fields.f_shiny ~= nil then
		sp.shiny = fields.f_shiny == "true"
	end
	if fields.f_exhausted ~= nil then
		sp.exhausted = fields.f_exhausted == "true"
	end
	if fields.f_give ~= nil then
		sp.give = fields.f_give == "true"
	end
	if fields.f_exp ~= nil then
		st.exp = clip(fields.f_exp)
	end
end

-- Button names of the panel. Input fields (t_, f_), the tab and the key_ events are not buttons.
local SIMPLE_BUTTONS = {
	spawn = true, clear_wild = true, exhaust_target = true, heal_party = true, give_exp = true,
	life_give = true, life_revive = true, to_sanctuary = true, toggle_fly = true,
}

local function is_button(key)
	return SIMPLE_BUTTONS[key] == true or key:match("^give_") ~= nil or key:match("^preset_") ~= nil
		or key:match("^time_") ~= nil or key:match("^minus_") ~= nil or key:match("^plus_") ~= nil
end

-- Runs the button a submit carries. Returns ok, text.
local function run_button(player, st, key)
	if key == "spawn" then
		local ok, text = API.spawn(player, st.spawn)
		return ok, text
	elseif key == "clear_wild" then
		return API.clear_wild(player)
	elseif key == "exhaust_target" then
		return API.exhaust_target(player)
	elseif key == "heal_party" then
		return API.heal_party(player)
	elseif key == "give_exp" then
		return API.give_exp(player, st.exp)
	elseif key == "life_give" then
		return API.lives(player, "give")
	elseif key == "life_revive" then
		return API.lives(player, "revive")
	elseif key == "to_sanctuary" then
		return API.to_sanctuary(player)
	elseif key == "toggle_fly" then
		return API.toggle_fly(player)
	end
	local group = key:match("^give_(.+)$")
	if group ~= nil then
		return API.give_items(player, group)
	end
	local preset = key:match("^preset_(.+)$")
	if preset ~= nil then
		for _, p in ipairs(A.PRESETS) do
			if p.name:lower() == preset then
				return API.preset(player, p.name)
			end
		end
		return false, "Unknown preset."
	end
	local time = key:match("^time_(.+)$")
	if time ~= nil then
		return API.set_time(player, time)
	end
	local minus = key:match("^minus_(.+)$")
	if minus ~= nil then
		return API.step(player, minus, -1)
	end
	local plus = key:match("^plus_(.+)$")
	if plus ~= nil then
		return API.step(player, plus, 1)
	end
	return false, "Unknown button."
end

core.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= FORM then
		return false
	end
	local name = gate(player)
	if name == nil or fields.quit ~= nil then
		return true
	end
	local st = state_of(name)
	take_inputs(st, fields)
	if fields.tabs ~= nil then
		local t = tonumber(fields.tabs)
		if t ~= nil and t >= 1 and t <= #A.TABS then
			st.tab = math.floor(t)
		end
	end
	local changed = API.apply_fields(player, fields)
	local key = nil
	for k in pairs(fields) do
		if is_button(k) then
			key = k
			break
		end
	end
	if key ~= nil then
		local _, text = run_button(player, st, key)
		st.message = text
		say(name, text)
	elseif changed > 0 then
		st.message = string.format("Tuning: %d change%s.", changed, changed == 1 and "" or "s")
		say(name, st.message)
	end
	show(player, st)
	return true
end)

core.register_on_leaveplayer(function(player)
	states[player:get_player_name()] = nil
end)

core.register_chatcommand("admin", {
	description = "Open the admin panel: live tuning, spawns, items, time and teleports",
	privs = { [PRIV] = true },
	func = function(name)
		local p = core.get_player_by_name(name)
		if p == nil then
			return false, "You are not online."
		end
		if not API.open(p) then
			return false, NOT_ALLOWED
		end
		return true
	end,
})

return API
