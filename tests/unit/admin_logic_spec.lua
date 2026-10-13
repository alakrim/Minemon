-- Unit tests for mods/minemon/minemon_admin/admin_logic.lua (T-33, D-033): field parsing, presets, the tuning
-- changes, escaping and the formspec strings. Pure logic, no Luanti. The knob table has the store's shape (kind,
-- default, min, max, step, options, label) but is written out here, so this spec does not need minemon_core.
-- luacheck: globals describe it assert

local here = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$") or "."
local A = dofile(here .. "/../../mods/minemon/minemon_admin/admin_logic.lua")

local DEFS = {
	catch_mult = { kind = "number", default = 1, min = 0.1, max = 10, step = 0.1, label = "Catch chance ×" },
	catch_mode = { kind = "choice", default = "normal", options = { "normal", "always", "never" },
		label = "Catch mode" },
	spawn_enabled = { kind = "bool", default = true, label = "Wild spawns on" },
	spawn_cap_mult = { kind = "number", default = 1, min = 0, max = 4, step = 0.25, label = "Wild crowd ×" },
	level_offset = { kind = "number", default = 0, min = -50, max = 50, step = 1, label = "Wild level ±" },
	dread_mult = { kind = "number", default = 1, min = 0, max = 20, step = 0.5, label = "Dread chance ×" },
	shiny_mult = { kind = "number", default = 1, min = 0, max = 512, step = 1, label = "Shiny chance ×" },
	exp_mult = { kind = "number", default = 1, min = 0, max = 10, step = 0.25, label = "Exp ×" },
}
local ORDER = { "catch_mode", "catch_mult", "spawn_enabled", "spawn_cap_mult", "level_offset", "dread_mult",
	"shiny_mult", "exp_mult" }

-- The store's coerce, in miniature: clamp and snap numbers, read bools, check choices.
local function coerce(key, raw)
	local def = DEFS[key]
	if def == nil then
		return nil
	end
	if def.kind == "number" then
		local n = tonumber(raw)
		if n == nil or n ~= n then
			return nil
		end
		n = math.max(def.min, math.min(def.max, n))
		n = math.floor(n / def.step + 0.5) * def.step
		return math.max(def.min, math.min(def.max, n))
	elseif def.kind == "bool" then
		if raw == true or raw == "true" then
			return true
		elseif raw == false or raw == "false" then
			return false
		end
		return nil
	end
	for _, opt in ipairs(def.options) do
		if raw == opt then
			return opt
		end
	end
	return nil
end

local function defaults()
	local out = {}
	for _, key in ipairs(ORDER) do
		out[key] = DEFS[key].default
	end
	return out
end

local function tuning(values)
	return { defs = DEFS, order = ORDER, values = values or defaults() }
end

-- How many times the plain text sub occurs in text.
local function count(text, sub)
	local n, from = 0, 1
	while true do
		local i, j = text:find(sub, from, true)
		if i == nil then
			return n
		end
		n = n + 1
		from = j + 1
	end
end

describe("admin_logic parsing", function()
	it("reads a level in 1..100 and rejects the rest", function()
		assert.equals(10, A.parse_level("10"))
		assert.equals(7, A.parse_level(" 7 "))
		assert.equals(1, A.parse_level("1"))
		assert.equals(100, A.parse_level("100"))
		assert.is_nil(A.parse_level("0"))
		assert.is_nil(A.parse_level("101"))
		assert.is_nil(A.parse_level("-3"))
		assert.is_nil(A.parse_level("7.5"))
		assert.is_nil(A.parse_level("abc"))
		assert.is_nil(A.parse_level(""))
		assert.is_nil(A.parse_level(nil))
	end)

	it("returns a message for a bad level", function()
		local n, why = A.parse_level("500")
		assert.is_nil(n)
		assert.equals("Must be between 1 and 100.", why)
		local _, junk = A.parse_level("x;y")
		assert.equals("Not a whole number: x\\;y", junk)
	end)

	it("reads a count in 1..10", function()
		assert.equals(1, A.parse_count("1"))
		assert.equals(10, A.parse_count("10"))
		assert.is_nil(A.parse_count("0"))
		assert.is_nil(A.parse_count("11"))
		assert.is_nil(A.parse_count("two"))
	end)

	it("reads the exp field as a positive whole number", function()
		assert.equals(1000, A.parse_exp("1000"))
		assert.is_nil(A.parse_exp("0"))
		assert.is_nil(A.parse_exp("1000000000"))
		assert.is_nil(A.parse_exp("12e3"))
	end)

	it("resolves a species through the given resolver, and reports unknown and empty input", function()
		local seen = {}
		local function resolve(text)
			seen[#seen + 1] = text
			if text == "pikachu" or text == "25" then
				return { id = 25, name = "Pikachu" }
			end
			return nil
		end
		assert.equals(25, A.parse_species(" pikachu ", resolve).id)
		assert.equals(25, A.parse_species("25", resolve).id)
		assert.equals("pikachu", seen[1])
		local sp, why = A.parse_species("nosuch", resolve)
		assert.is_nil(sp)
		assert.equals("Unknown species: nosuch", why)
		local none, empty = A.parse_species("   ", resolve)
		assert.is_nil(none)
		assert.equals("Enter a species name or dex number.", empty)
	end)
end)

describe("admin_logic presets", function()
	it("has the four presets in order, with the designed values", function()
		local names = {}
		for _, p in ipairs(A.PRESETS) do
			names[#names + 1] = p.name
		end
		assert.same({ "Easy", "Normal", "Hard", "Nightmare" }, names)
		assert.equals(2, A.preset("Easy").values.catch_mult)
		assert.equals(-5, A.preset("Easy").values.level_offset)
		assert.equals(2, A.preset("Easy").values.exp_mult)
		assert.equals(0.5, A.preset("Hard").values.catch_mult)
		assert.equals(10, A.preset("Hard").values.level_offset)
		assert.equals(2, A.preset("Hard").values.dread_mult)
		assert.equals(0.75, A.preset("Hard").values.exp_mult)
		assert.equals(0.3, A.preset("Nightmare").values.catch_mult)
		assert.equals(20, A.preset("Nightmare").values.level_offset)
		assert.equals(5, A.preset("Nightmare").values.dread_mult)
		assert.equals(1.5, A.preset("Nightmare").values.spawn_cap_mult)
		assert.is_nil(A.preset("Impossible"))
	end)

	it("Hard changes exactly the knobs it names, from defaults", function()
		local changes = A.preset_changes("Hard", defaults(), DEFS, ORDER)
		local keys = {}
		for _, c in ipairs(changes) do
			keys[c.key] = c.value
		end
		assert.same({ catch_mult = 0.5, level_offset = 10, dread_mult = 2, exp_mult = 0.75 }, keys)
	end)

	it("Normal resets every knob that is not at its default", function()
		local current = defaults()
		current.catch_mult = 2
		current.spawn_enabled = false
		local changes = A.preset_changes("Normal", current, DEFS, ORDER)
		assert.equals(2, #changes)
		local seen = {}
		for _, c in ipairs(changes) do
			seen[c.key] = c.value
		end
		assert.equals(1, seen.catch_mult)
		assert.equals(true, seen.spawn_enabled)
	end)

	it("Normal from defaults changes nothing; an unknown preset changes nothing", function()
		assert.same({}, A.preset_changes("Normal", defaults(), DEFS, ORDER))
		assert.same({}, A.preset_changes("Nope", defaults(), DEFS, ORDER))
	end)
end)

describe("admin_logic knob values", function()
	it("marks only the non-default values as changed", function()
		assert.is_false(A.is_changed("catch_mult", 1, DEFS))
		assert.is_true(A.is_changed("catch_mult", 2, DEFS))
		assert.is_true(A.is_changed("spawn_enabled", false, DEFS))
	end)

	it("formats numbers, bools and choices", function()
		assert.equals("1", A.format_value("catch_mult", 1, DEFS))
		assert.equals("0.25", A.format_value("spawn_cap_mult", 0.25, DEFS))
		assert.equals("on", A.format_value("spawn_enabled", true, DEFS))
		assert.equals("off", A.format_value("spawn_enabled", false, DEFS))
		assert.equals("always", A.format_value("catch_mode", "always", DEFS))
	end)

	it("steps a number by one step and stops at the bounds", function()
		local up = A.step("catch_mult", 1, 1, DEFS, coerce)
		assert.is_true(math.abs(up - 1.1) < 1e-9)
		assert.equals(10, A.step("catch_mult", 10, 1, DEFS, coerce))
		assert.equals(0.1, A.step("catch_mult", 0.1, -1, DEFS, coerce))
		assert.equals(0, A.step("spawn_cap_mult", 0.25, -1, DEFS, coerce))
	end)

	it("turns submitted fields into the changes only, and drops bad input", function()
		local current = defaults()
		local fields = {
			t_catch_mult = "2",
			t_catch_mode = "bogus",
			t_spawn_enabled = "true",
			t_exp_mult = "1",
		}
		local changes = A.tuning_changes(fields, ORDER, current, coerce)
		assert.equals(1, #changes)
		assert.equals("catch_mult", changes[1].key)
		assert.equals(2, changes[1].raw)
	end)

	it("reads a false checkbox as a change to off", function()
		local changes = A.tuning_changes({ t_spawn_enabled = "false" }, ORDER, defaults(), coerce)
		assert.equals(1, #changes)
		assert.equals(false, changes[1].raw)
	end)
end)

describe("admin_logic escaping", function()
	it("escapes backslash, brackets, semicolon and comma", function()
		assert.equals("a\\;b\\,c\\[d\\]\\\\", A.escape("a;b,c[d]\\"))
		assert.equals("", A.escape(nil))
		assert.equals("plain text 12", A.escape("plain text 12"))
	end)

	it("keeps user text from breaking the formspec", function()
		local st = A.default_state()
		st.tab = 2
		st.spawn.species = "x];button[0,0;1,1;evil"
		st.message = "hi; label[0,0;x]"
		local fs = A.formspec(st, tuning())
		assert.is_nil(fs:find("button[0,0;1,1;evil", 1, true))
		assert.is_truthy(fs:find("x\\]\\;button", 1, true))
		assert.is_nil(fs:find("label[0,0;x]", 1, true))
	end)
end)

describe("admin_logic formspec", function()
	it("names the four tabs in the tab header", function()
		local fs = A.formspec(A.default_state(), tuning())
		assert.is_truthy(fs:find("tabheader[0,0;tabs;Tuning,Spawn,Player,World;1;false;true]", 1, true))
		assert.is_truthy(fs:find("size[12,9]", 1, true))
	end)

	it("has one row per tuning key on the Tuning tab", function()
		local st = A.default_state()
		st.tab = 1
		local fs = A.formspec(st, tuning())
		for _, key in ipairs(ORDER) do
			assert.is_truthy(fs:find("t_" .. key, 1, true), "missing row for " .. key)
			assert.is_truthy(fs:find(DEFS[key].label, 1, true), "missing label for " .. key)
		end
		assert.equals(1, count(fs, "t_catch_mode;"))
		assert.equals(1, count(fs, "t_spawn_enabled;"))
		assert.equals(1, count(fs, "minus_catch_mult;"))
		assert.equals(1, count(fs, "plus_catch_mult;"))
		assert.equals(0, count(fs, "minus_catch_mode"))
		for _, p in ipairs(A.PRESETS) do
			assert.is_truthy(fs:find("preset_" .. p.name:lower(), 1, true))
		end
	end)

	it("marks a changed knob, and shows the value", function()
		local values = defaults()
		values.catch_mult = 2
		local fs = A.formspec(A.default_state(), tuning(values))
		assert.is_truthy(fs:find("(changed)", 1, true))
		assert.is_truthy(fs:find("2", 1, true))
	end)

	it("has the Spawn, Player and World controls on their tabs", function()
		local st = A.default_state()
		st.tab = 2
		local spawn = A.formspec(st, tuning())
		for _, name in ipairs({ "f_species", "f_level", "f_count", "f_dread", "f_shiny", "f_exhausted", "f_give",
			"spawn", "clear_wild", "exhaust_target" }) do
			assert.is_truthy(spawn:find(name, 1, true), "missing " .. name)
		end
		st.tab = 3
		local player = A.formspec(st, tuning())
		for _, name in ipairs({ "heal_party", "f_exp", "give_exp", "life_give", "life_revive", "give_balls",
			"give_coins", "give_potions", "give_evo", "give_shards" }) do
			assert.is_truthy(player:find(name, 1, true), "missing " .. name)
		end
		st.tab = 4
		local world = A.formspec(st, tuning())
		for _, name in ipairs({ "time_dawn", "time_noon", "time_dusk", "time_midnight", "to_sanctuary",
			"toggle_fly" }) do
			assert.is_truthy(world:find(name, 1, true), "missing " .. name)
		end
	end)

	it("shows the message line", function()
		local st = A.default_state()
		st.message = "[admin] Spawned 1 Pikachu Lv 10"
		local fs = A.formspec(st, tuning())
		assert.is_truthy(fs:find("Spawned 1 Pikachu Lv 10", 1, true))
	end)
end)

describe("admin_logic constants", function()
	it("keeps the Spawn and Player limits the brief names", function()
		assert.equals(1, A.LEVEL_MIN)
		assert.equals(100, A.LEVEL_MAX)
		assert.equals(10, A.COUNT_MAX)
		assert.equals(1000, A.EXP_DEFAULT)
		assert.equals(3, A.SPAWN_RANGE)
		assert.equals(32, A.CLEAR_RANGE)
		assert.equals(24, A.EXHAUST_RANGE)
		assert.equals(4, #A.TIMES)
		assert.equals(5, #A.GIVE_ORDER)
	end)

	it("lists only registered-style item names in the give groups", function()
		for _, group in ipairs(A.GIVE_ORDER) do
			for _, entry in ipairs(A.GIVE_GROUPS[group]) do
				assert.is_truthy(entry[1]:match("^minemon:[a-z_]+$"), "bad item name " .. entry[1])
				assert.is_truthy(entry[2] > 0)
			end
		end
	end)
end)
