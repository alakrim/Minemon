-- minemon_core: the global `minemon` table and the Gen 2 rules (data, formulas, rng, instance, events).
-- The pure modules (data, formulas, rng, instance, events) do not touch the Luanti API, so busted can test
-- them. This file is the glue: it reads and parses data/*.json, and it gives the logger to the event registry.
-- luacheck: globals minemon

minemon = rawget(_G, "minemon") or {}
minemon.version = "0.1.0"

local MODPATH = core.get_modpath("minemon_core")

local function load_module(name)
	return dofile(MODPATH .. "/" .. name .. ".lua")
end

-- io.open in read mode works for untrusted mods, because the sandbox allows reads from mod directories.
local function read_json(name)
	local path = MODPATH .. "/data/" .. name .. ".json"
	local f, err = io.open(path, "rb")
	if not f then
		error("minemon_core: cannot open " .. path .. ": " .. tostring(err))
	end
	local text = f:read("*a")
	f:close()
	local parsed, parse_err = core.parse_json(text, nil, true)
	if parsed == nil then
		error("minemon_core: cannot parse data/" .. name .. ".json: " .. tostring(parse_err))
	end
	return parsed
end

minemon.data = load_module("data").new({
	species = read_json("species"),
	moves = read_json("moves"),
	types = read_json("types"),
	items = read_json("items"),
})
minemon.rng = load_module("rng")
minemon.formulas = load_module("formulas")
minemon.instance = load_module("instance").create(minemon.formulas, minemon.data)
minemon.events = load_module("events").create(function(message)
	core.log("error", "[minemon_core] " .. message)
end)

-- Tuning (D-033): the admin panel's live knobs, saved in this mod's storage. minemon.tuning.get(key) gives the
-- current value; mods read it when they need it. "tuning_changed"(key, value) fires after each set (value nil
-- after a reset).
local TUNING = load_module("tuning")
local storage = core.get_mod_storage()
minemon.tuning = TUNING.create(core.parse_json(storage:get_string("tuning")) or {}, function(values)
	storage:set_string("tuning", core.write_json(values) or "{}")
end)
minemon.tuning.logic = TUNING
local tuning_set, tuning_reset = minemon.tuning.set, minemon.tuning.reset
function minemon.tuning.set(key, raw)
	local v, why = tuning_set(key, raw)
	if v ~= nil then
		minemon.events.fire("tuning_changed", key, v)
	end
	return v, why
end
function minemon.tuning.reset()
	tuning_reset()
	minemon.events.fire("tuning_changed", nil, nil)
end
