-- minemon_admin logic (T-33, D-033): the admin panel's field parsing, the presets, the give lists and the formspec
-- strings. Pure: no Luanti API, so busted can test it. The glue (init.lua) reads the tuning store, the player and the
-- world, and calls these functions. Nothing here trusts a formspec: the glue checks the privilege on every action.

local M = {}

M.TABS = { "Tuning", "Spawn", "Player", "World" }
M.LEVEL_MIN = 1
M.LEVEL_MAX = 100
M.LEVEL_DEFAULT = 10
M.COUNT_MIN = 1
M.COUNT_MAX = 10
M.EXP_DEFAULT = 1000
M.EXP_MAX = 1000000
M.SPAWN_RANGE = 3 -- nodes in front of the player
M.CLEAR_RANGE = 32 -- nodes around the player for "Clear wild"
M.EXHAUST_RANGE = 24 -- nodes for "Exhaust target"
M.PARTY_MAX = 6 -- mirrors minemon_party's party_logic.MAX

-- The presets (D-033). Normal is the reset: every knob goes back to its default.
M.PRESETS = {
	{ name = "Easy", values = { catch_mult = 2, level_offset = -5, exp_mult = 2 } },
	{ name = "Normal", values = {} },
	{ name = "Hard", values = { catch_mult = 0.5, level_offset = 10, dread_mult = 2, exp_mult = 0.75 } },
	{ name = "Nightmare", values = { catch_mult = 0.3, level_offset = 20, dread_mult = 5, spawn_cap_mult = 1.5 } },
}

-- Items given by the Player tab: group name -> list of { item name, count }. Names are the registered ids (D-030).
M.GIVE_GROUPS = {
	balls = {
		{ "minemon:poke_ball", 10 }, { "minemon:great_ball", 10 }, { "minemon:ultra_ball", 10 },
		{ "minemon:master_ball", 10 }, { "minemon:umbral_ball", 10 },
	},
	coins = { { "minemon:coin", 500 } },
	potions = { { "minemon:potion", 10 } },
	evo = {
		{ "minemon:fire_stone", 1 }, { "minemon:water_stone", 1 }, { "minemon:thunder_stone", 1 },
		{ "minemon:leaf_stone", 1 }, { "minemon:moon_stone", 1 }, { "minemon:sun_stone", 1 },
		{ "minemon:link_cable", 1 },
	},
	shards = { { "minemon:dread_shard", 10 } },
}
M.GIVE_ORDER = { "balls", "coins", "potions", "evo", "shards" }
M.GIVE_LABELS = {
	balls = "10 of each ball",
	coins = "500 coins",
	potions = "10 Potions",
	evo = "Evolution stones + Link Cable",
	shards = "10 Dread Shards",
}

-- The World tab's times of day (core.set_timeofday takes 0..1).
M.TIMES = {
	{ name = "Dawn", value = 0.25 },
	{ name = "Noon", value = 0.5 },
	{ name = "Dusk", value = 0.78 },
	{ name = "Midnight", value = 0.0 },
}

-- Trims spaces at both ends.
local function trim(s)
	return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end
M.trim = trim

-- Escapes user text for a formspec label or item list: backslash, brackets, semicolon and comma get a backslash.
function M.escape(text)
	return (tostring(text or ""):gsub("[\\%[%];,]", "\\%0"))
end

-- A whole number from a field, within min..max. Returns the number, or nil and a message for the panel.
function M.parse_int(raw, min, max)
	local s = trim(raw)
	if s:match("^[+-]?%d+$") == nil then
		return nil, "Not a whole number: " .. M.escape(s)
	end
	local n = tonumber(s)
	if n < min or n > max then
		return nil, string.format("Must be between %d and %d.", min, max)
	end
	return n
end

-- The level field: 1..100.
function M.parse_level(raw)
	return M.parse_int(raw, M.LEVEL_MIN, M.LEVEL_MAX)
end

-- The count field: 1..10.
function M.parse_count(raw)
	return M.parse_int(raw, M.COUNT_MIN, M.COUNT_MAX)
end

-- The exp field of the Player tab: 1..EXP_MAX.
function M.parse_exp(raw)
	return M.parse_int(raw, 1, M.EXP_MAX)
end

-- The species field: a name ("pikachu") or a dex number. resolve(text) returns a species table or nil (the glue
-- passes minemon.data.get_species, which accepts both). Returns the species, or nil and a message.
function M.parse_species(raw, resolve)
	local s = trim(raw)
	if s == "" then
		return nil, "Enter a species name or dex number."
	end
	local sp = resolve(s)
	if sp == nil then
		return nil, "Unknown species: " .. M.escape(s)
	end
	return sp
end

-- The preset named name, or nil.
function M.preset(name)
	for _, p in ipairs(M.PRESETS) do
		if p.name == name then
			return p
		end
	end
	return nil
end

-- The changes a preset makes against the current values: a list of { key, value } for every key in order whose
-- value would differ from the current one. A key the preset does not name goes back to its default (Normal resets).
function M.preset_changes(name, current, defs, order)
	local p = M.preset(name)
	local out = {}
	if p == nil then
		return out
	end
	for _, key in ipairs(order) do
		local want = p.values[key]
		if want == nil then
			want = defs[key].default
		end
		if current[key] ~= want then
			out[#out + 1] = { key = key, value = want }
		end
	end
	return out
end

-- True when a value differs from the knob's default (the "(changed)" mark).
function M.is_changed(key, value, defs)
	return value ~= defs[key].default
end

-- A knob value as text: numbers with %g, bools as on/off, choices as they are.
function M.format_value(key, value, defs)
	local def = defs[key]
	if def.kind == "bool" then
		return value and "on" or "off"
	elseif def.kind == "number" then
		return string.format("%g", value)
	end
	return tostring(value)
end

-- One −/+ step of a number knob: coerce(key, current + dir × step), so the clamp and the snap are the store's.
function M.step(key, current, dir, defs, coerce)
	return coerce(key, current + dir * defs[key].step)
end

-- The tuning changes a submitted tuning tab asks for. fields holds the submitted "t_<key>" values (strings for
-- numbers and choices, "true"/"false" for checkboxes). Returns a list of { key, raw } for keys whose submitted value
-- differs from the current one. coerce is the store's coerce, so bad input is dropped here, not stored.
function M.tuning_changes(fields, order, current, coerce)
	local out = {}
	for _, key in ipairs(order) do
		local raw = fields["t_" .. key]
		if raw ~= nil then
			local v = coerce(key, raw)
			if v ~= nil and v ~= current[key] then
				out[#out + 1] = { key = key, raw = v }
			end
		end
	end
	return out
end

-- The panel state the glue keeps per player: the tab, the message line, the Spawn fields and the exp field.
function M.default_state()
	return {
		tab = 1,
		message = "",
		spawn = {
			species = "",
			level = tostring(M.LEVEL_DEFAULT),
			count = "1",
			dread = false,
			shiny = false,
			exhausted = false,
			give = false,
		},
		exp = tostring(M.EXP_DEFAULT),
	}
end

local function esc(text)
	return M.escape(text)
end

local function header(st)
	local index = st.tab or 1
	return string.format("tabheader[0,0;tabs;%s;%d;false;true]", table.concat(M.TABS, ","), index)
end

-- The Tuning tab: the four presets, then one row per knob in order.
local function tuning_tab(tuning)
	local fs = {}
	local defs, order, values = tuning.defs, tuning.order, tuning.values
	local x_names = { 0.5, 3.0, 5.5, 8.0 }
	for i, p in ipairs(M.PRESETS) do
		fs[#fs + 1] = string.format("button[%.2f,0.5;2.3,0.8;preset_%s;%s]", x_names[i], p.name:lower(), esc(p.name))
	end
	-- Real coordinates (formspec_version 6): a label's and a checkbox's y is the middle of the row.
	local y = 1.8
	for _, key in ipairs(order) do
		local def = defs[key]
		local value = values[key]
		local changed = M.is_changed(key, value, defs) and "  (changed)" or ""
		fs[#fs + 1] = string.format("label[0.5,%.2f;%s]", y + 0.33, esc(def.label))
		if def.kind == "number" then
			fs[#fs + 1] = string.format("field[4.6,%.2f;2.0,0.65;t_%s;;%s]", y, key,
				esc(M.format_value(key, value, defs)))
			fs[#fs + 1] = string.format("button[6.8,%.2f;0.8,0.65;minus_%s;-]", y, key)
			fs[#fs + 1] = string.format("button[7.7,%.2f;0.8,0.65;plus_%s;+]", y, key)
		elseif def.kind == "bool" then
			fs[#fs + 1] = string.format("checkbox[4.6,%.2f;t_%s;;%s]", y + 0.33, key, value and "true" or "false")
		else
			local items, index = {}, 1
			for i, opt in ipairs(def.options) do
				items[#items + 1] = esc(opt)
				if opt == value then
					index = i
				end
			end
			fs[#fs + 1] = string.format("dropdown[4.6,%.2f;2.6,0.65;t_%s;%s;%d]", y, key, table.concat(items, ","),
				index)
		end
		fs[#fs + 1] = string.format("label[8.7,%.2f;%s]", y + 0.33, esc(changed))
		y = y + 0.8
	end
	return fs
end

-- The Spawn tab: the species, level and count fields, the four flags, the actions.
local function spawn_tab(st)
	local s = st.spawn
	return {
		string.format("field[0.5,1.2;4.0,0.8;f_species;Species (name or dex no.);%s]", esc(s.species)),
		string.format("field[4.8,1.2;2.0,0.8;f_level;Level %d-%d;%s]", M.LEVEL_MIN, M.LEVEL_MAX, esc(s.level)),
		string.format("field[7.2,1.2;2.0,0.8;f_count;Count %d-%d;%s]", M.COUNT_MIN, M.COUNT_MAX, esc(s.count)),
		string.format("checkbox[0.5,2.6;f_dread;Dread;%s]", s.dread and "true" or "false"),
		string.format("checkbox[3.0,2.6;f_shiny;Shiny;%s]", s.shiny and "true" or "false"),
		string.format("checkbox[5.5,2.6;f_exhausted;Exhausted (ready to catch);%s]",
			s.exhausted and "true" or "false"),
		string.format("checkbox[0.5,3.3;f_give;Give to me (party);%s]", s.give and "true" or "false"),
		"button[0.5,4.4;3.0,0.8;spawn;Spawn]",
		string.format("button[3.8,4.4;3.8,0.8;clear_wild;Clear wild (%d nodes)]", M.CLEAR_RANGE),
		string.format("button[7.9,4.4;3.6,0.8;exhaust_target;Exhaust target]"),
	}
end

-- The Player tab: heal, exp, the item groups, the lives.
local function player_tab(st)
	local fs = {
		"button[0.5,1.0;3.0,0.8;heal_party;Heal party]",
		string.format("field[4.8,1.0;2.0,0.8;f_exp;Exp to give;%s]", esc(st.exp)),
		"button[7.2,1.0;3.0,0.8;give_exp;Give exp]",
		"button[0.5,2.2;3.0,0.8;life_give;+1 life]",
		"button[3.8,2.2;3.0,0.8;life_revive;Revive]",
	}
	local y = 3.4
	for _, group in ipairs(M.GIVE_ORDER) do
		fs[#fs + 1] = string.format("button[0.5,%.2f;5.0,0.7;give_%s;%s]", y, group, esc(M.GIVE_LABELS[group]))
		y = y + 0.8
	end
	return fs
end

-- The World tab: the times of day, the Sanctuary teleport, the fly and fast toggle.
local function world_tab()
	local fs = {}
	for i, t in ipairs(M.TIMES) do
		fs[#fs + 1] = string.format("button[%.2f,1.0;2.3,0.8;time_%s;%s]", 0.5 + (i - 1) * 2.5, t.name:lower(),
			esc(t.name))
	end
	fs[#fs + 1] = "button[0.5,2.2;5.0,0.8;to_sanctuary;Teleport to the nearest Sanctuary]"
	fs[#fs + 1] = "button[0.5,3.2;5.0,0.8;toggle_fly;Toggle fly, fast and noclip]"
	return fs
end

-- The formspec string. tuning = { defs, order, values } from the store. st is the panel state.
function M.formspec(st, tuning)
	local fs = { "formspec_version[6]", "size[12,9.5]", "no_prepend[]", "bgcolor[#00000088;true]",
		"box[0,0;12,9.5;#16161ef2]", header(st) }
	local tab = st.tab or 1
	if tab == 1 then
		for _, line in ipairs(tuning_tab(tuning)) do
			fs[#fs + 1] = line
		end
	elseif tab == 2 then
		for _, line in ipairs(spawn_tab(st)) do
			fs[#fs + 1] = line
		end
	elseif tab == 3 then
		for _, line in ipairs(player_tab(st)) do
			fs[#fs + 1] = line
		end
	else
		for _, line in ipairs(world_tab()) do
			fs[#fs + 1] = line
		end
	end
	fs[#fs + 1] = string.format("label[0.5,9.0;%s]", esc(st.message or ""))
	return table.concat(fs, "")
end

return M
