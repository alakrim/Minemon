-- Unit tests for mods/minemon/minemon_core/tuning.lua (D-033): the admin knob store and its apply helpers.
-- Pure logic, no Luanti. Covers: coerce (clamp, step snap, bad input, bools from strings, choice options), create,
-- get, set, reset and is_default, saved values loaded and bad saved values dropped, save called on set and reset, and
-- the apply_catch, apply_level and apply_chance edge cases.
-- luacheck: globals describe it assert

local here = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$") or "."
local T = dofile(here .. "/../../mods/minemon/minemon_core/tuning.lua")

describe("tuning.coerce numbers", function()
	it("clamps to min and max", function()
		assert.equals(10, T.coerce("catch_mult", 100))
		assert.equals(0.1, T.coerce("catch_mult", -5))
		assert.equals(-50, T.coerce("level_offset", -999))
		assert.equals(50, T.coerce("level_offset", "999"))
	end)

	it("snaps to the step", function()
		assert.equals(2.5, T.coerce("exp_mult", "2.6"))
		assert.equals(1.25, T.coerce("spawn_cap_mult", 1.3))
		assert.equals(8, T.coerce("level_offset", 7.6))
	end)

	it("reads numeric strings", function()
		assert.equals(3, T.coerce("shiny_mult", "3"))
	end)

	it("returns nil for bad numbers", function()
		assert.is_nil(T.coerce("catch_mult", "abc"))
		assert.is_nil(T.coerce("catch_mult", nil))
		assert.is_nil(T.coerce("catch_mult", 0 / 0))
	end)
end)

describe("tuning.coerce bools and choices", function()
	it("reads true and false, and the strings", function()
		assert.is_true(T.coerce("spawn_enabled", true))
		assert.is_true(T.coerce("spawn_enabled", "true"))
		assert.is_false(T.coerce("spawn_enabled", false))
		assert.is_false(T.coerce("spawn_enabled", "false"))
	end)

	it("returns nil for other bool input", function()
		assert.is_nil(T.coerce("spawn_enabled", "yes"))
		assert.is_nil(T.coerce("spawn_enabled", 1))
	end)

	it("accepts only the listed options for a choice", function()
		assert.equals("always", T.coerce("catch_mode", "always"))
		assert.equals("never", T.coerce("catch_mode", "never"))
		assert.equals("normal", T.coerce("catch_mode", "normal"))
		assert.is_nil(T.coerce("catch_mode", "sometimes"))
	end)

	it("returns nil for an unknown key", function()
		assert.is_nil(T.coerce("no_such_knob", 1))
	end)
end)

describe("tuning.create: get, set, reset, is_default", function()
	it("starts at the defaults", function()
		local S = T.create({}, nil)
		assert.equals(1, S.get("catch_mult"))
		assert.equals("normal", S.get("catch_mode"))
		assert.is_true(S.get("spawn_enabled"))
		assert.equals(0, S.get("level_offset"))
		assert.is_true(S.is_default())
	end)

	it("returns nil for an unknown key", function()
		local S = T.create({}, nil)
		assert.is_nil(S.get("no_such_knob"))
	end)

	it("sets a value and returns the coerced one", function()
		local S = T.create({}, nil)
		assert.equals(2, S.set("catch_mult", 2))
		assert.equals(2, S.get("catch_mult"))
		assert.is_false(S.is_default())
	end)

	it("returns nil and a reason for a bad value, and leaves the value alone", function()
		local S = T.create({}, nil)
		local v, why = S.set("catch_mult", "abc")
		assert.is_nil(v)
		assert.is_string(why)
		assert.equals(1, S.get("catch_mult"))
	end)

	it("is_default is true again when a value is set back to its default", function()
		local S = T.create({}, nil)
		S.set("exp_mult", 3)
		assert.is_false(S.is_default())
		S.set("exp_mult", 1)
		assert.equals(1, S.get("exp_mult"))
		assert.is_true(S.is_default())
	end)

	it("reset puts every knob back to its default", function()
		local S = T.create({}, nil)
		S.set("catch_mode", "always")
		S.set("level_offset", 10)
		S.reset()
		assert.equals("normal", S.get("catch_mode"))
		assert.equals(0, S.get("level_offset"))
		assert.is_true(S.is_default())
	end)

	it("the panel order lists every knob once", function()
		local seen, n = {}, 0
		for _, key in ipairs(T.ORDER) do
			assert.is_not_nil(T.DEFS[key], "no def for " .. key)
			assert.is_nil(seen[key], "duplicate " .. key)
			seen[key] = true
			n = n + 1
		end
		local count = 0
		for _ in pairs(T.DEFS) do
			count = count + 1
		end
		assert.equals(count, n)
	end)
end)

describe("tuning.create: saved values", function()
	it("loads good saved values", function()
		local S = T.create({ catch_mult = "2", spawn_enabled = "false", catch_mode = "never" }, nil)
		assert.equals(2, S.get("catch_mult"))
		assert.is_false(S.get("spawn_enabled"))
		assert.equals("never", S.get("catch_mode"))
		assert.is_false(S.is_default())
	end)

	it("drops bad saved values and keeps the defaults for them", function()
		local S = T.create({ level_offset = "abc", catch_mode = "sometimes", no_such_knob = 5, exp_mult = 4 }, nil)
		assert.equals(0, S.get("level_offset"))
		assert.equals("normal", S.get("catch_mode"))
		assert.equals(4, S.get("exp_mult"))
		assert.is_nil(S.get("no_such_knob"))
	end)

	it("ignores a saved value that is not a table", function()
		local S = T.create("garbage", nil)
		assert.is_true(S.is_default())
	end)
end)

describe("tuning.create: save", function()
	it("is called with the values after every set", function()
		local saved = {}
		local S = T.create({}, function(values)
			saved = values
		end)
		S.set("catch_mult", 3)
		assert.equals(3, saved.catch_mult)
		S.set("spawn_enabled", false)
		assert.is_false(saved.spawn_enabled)
	end)

	it("is called after a reset, with no values", function()
		local calls, last = 0, nil
		local S = T.create({ catch_mult = 3 }, function(values)
			calls = calls + 1
			last = values
		end)
		S.reset()
		assert.equals(1, calls)
		assert.is_nil(next(last))
	end)

	it("is not called for a bad value", function()
		local calls = 0
		local S = T.create({}, function()
			calls = calls + 1
		end)
		S.set("catch_mult", "abc")
		assert.equals(0, calls)
	end)
end)

describe("tuning.apply_catch", function()
	it("always gives 1 and never gives 0, whatever the odds and the multiplier", function()
		assert.equals(1, T.apply_catch(0, "always", 0.1))
		assert.equals(0, T.apply_catch(1, "never", 10))
	end)

	it("normal multiplies the odds and caps them at 1", function()
		assert.equals(0.6, T.apply_catch(0.3, "normal", 2))
		assert.equals(1, T.apply_catch(0.8, "normal", 2))
	end)

	it("normal with multiplier 1 leaves the odds as they are", function()
		assert.equals(0.37, T.apply_catch(0.37, "normal", 1))
	end)

	it("a zero multiplier gives 0", function()
		assert.equals(0, T.apply_catch(0.5, "normal", 0))
	end)
end)

describe("tuning.apply_level", function()
	it("adds the offset", function()
		assert.equals(15, T.apply_level(5, 10))
		assert.equals(5, T.apply_level(5, 0))
	end)

	it("keeps the result within 1..100", function()
		assert.equals(100, T.apply_level(95, 50))
		assert.equals(1, T.apply_level(10, -50))
		assert.equals(1, T.apply_level(2, -50))
	end)
end)

describe("tuning.apply_chance", function()
	it("multiplies and clamps to 0..1", function()
		assert.equals(0.5, T.apply_chance(0.25, 2))
		assert.equals(1, T.apply_chance(0.5, 20))
		assert.equals(0, T.apply_chance(0.5, 0))
		assert.equals(0, T.apply_chance(0.5, -3))
	end)
end)
