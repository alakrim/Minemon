-- Integration test (D-033): the admin tuning knobs as the gameplay code reads them, in the assembled game, with no real
-- players. A stone platform at the origin is forceloaded. A fake player (the party and capture methods, plus an
-- inventory) drives the flow. Checks, in order:
--   (1) the knobs start at their defaults;
--   (2) the spawn gate (minemon.creatures.gate_passes): passes by default, is false with spawn_enabled off, and is
--       false with spawn_cap_mult 0 (no natural spawns);
--   (3) the level offset: +10 raises the wild level of a natural-style spawn (level nil) by exactly 10 at the same
--       position, and an explicit level (5) is not offset;
--   (4) catch_mode: "normal" breaks free on a 0.9999 draw, "always" catches with the same draw, "never" never catches
--       (and makes no shake);
--   (5) exp_mult 0: a defeat grants no exp; at 1 it grants exp again;
--   (6) minemon.tuning.reset() puts every knob back to its default.
-- Writes PASS n or FAIL <reason> to test_result.txt, then shuts down.
-- luacheck: read_globals core minemon vector ItemStack

local PLATFORM_Y = 5 -- stone top at y = 5.5; the fake player stands there
local HALF = 6
local TOP_Y = 9
local STONE = "mcl_core:stone"
local NAME = "tuning_test_player"
local RATTATA = 19
local BULBASAUR = 1
local ORIGIN_X = 0
local ORIGIN_Z = 0

local finished = false
local checks = 0

local function finish(line)
	if finished then
		return
	end
	finished = true
	core.safe_file_write(core.get_worldpath() .. "/test_result.txt", line .. "\n")
	core.request_shutdown()
end

local function check(cond, msg)
	checks = checks + 1
	if not cond then
		error(msg, 0)
	end
end

-- The fake player: the party and capture methods, plus an inventory (as in tests/integration/growth).
local function make_fake()
	local store = {}
	local meta = {
		get_string = function(_, key)
			return store[key] or ""
		end,
		set_string = function(_, key, value)
			store[key] = value
		end,
	}
	local inv = {}
	inv.contains_item = function()
		return false
	end
	inv.add_item = function()
		return ItemStack("")
	end
	inv.remove_item = function() end
	local fake = {}
	fake.get_meta = function()
		return meta
	end
	fake.get_inventory = function()
		return inv
	end
	fake.get_player_name = function()
		return NAME
	end
	fake.get_pos = function()
		return vector.new(0, PLATFORM_Y + 0.5, 0)
	end
	fake.get_look_dir = function()
		return vector.new(0, 0, 1)
	end
	fake.is_valid = function()
		return true
	end
	fake.is_player = function()
		return true
	end
	fake.get_guid = function()
		return "tuning-test-fake-player"
	end
	return fake
end

local function build_platform()
	for x = -HALF, HALF do
		for z = -HALF, HALF do
			core.set_node(vector.new(x, PLATFORM_Y, z), { name = STONE })
			for y = PLATFORM_Y + 1, TOP_Y do
				core.set_node(vector.new(x, y, z), { name = "air" })
			end
		end
	end
	for _, p in ipairs({ { -HALF, -HALF }, { HALF, -HALF }, { -HALF, HALF }, { HALF, HALF } }) do
		check(core.forceload_block(vector.new(p[1], PLATFORM_Y, p[2]), true, 256), "forceload failed")
	end
end

-- An rng whose float() is always v. 0.9999 fails the first shake of a normal catch; 0 passes none.
local function fixed_rng(v)
	return { float = function() return v end }
end

local function species(id)
	return minemon.data.get_species(id)
end

local function wild_at(species_id, x, z, level)
	local obj = minemon.creatures.spawn(vector.new(x, PLATFORM_Y + 1, z), species_id, level, nil)
	check(obj ~= nil, "wild spawn failed for species " .. species_id)
	return obj
end

local function lead(fake)
	return minemon.party.get(fake)[1]
end

local function run()
	local fake = make_fake()
	local T = minemon.tuning
	check(T ~= nil, "minemon.tuning is missing")

	-- (1) the defaults
	check(T.is_default(), "the knobs do not start at their defaults")
	check(T.get("catch_mode") == "normal", "catch_mode default is not normal")
	check(T.get("exp_mult") == 1, "exp_mult default is not 1")

	-- (2) the spawn gate, before any creature is spawned here (so the local cap is not reached)
	local rattata_name = minemon.creatures.entity_name(species(RATTATA))
	local origin = vector.new(ORIGIN_X, PLATFORM_Y + 1, ORIGIN_Z)
	check(minemon.creatures.gate_passes(rattata_name, origin), "the gate refuses a spawn by default")
	T.set("spawn_enabled", false)
	check(not minemon.creatures.gate_passes(rattata_name, origin), "spawn_enabled false still lets a spawn pass")
	T.reset()
	T.set("spawn_cap_mult", 0)
	check(not minemon.creatures.gate_passes(rattata_name, origin), "spawn_cap_mult 0 still lets a spawn pass")
	T.reset()
	check(minemon.creatures.gate_passes(rattata_name, origin), "the gate still refuses after the reset")

	-- (3) the level offset: the same position gives the same seeded level, so the difference is exactly the offset
	local probe = wild_at(RATTATA, ORIGIN_X, ORIGIN_Z, nil)
	local base_level = probe:get_luaentity()._mm.level
	probe:remove()
	T.set("level_offset", 10)
	local raised = wild_at(RATTATA, ORIGIN_X, ORIGIN_Z, nil)
	local raised_level = raised:get_luaentity()._mm.level
	check(raised_level == base_level + 10,
		"level_offset +10 gave level " .. tostring(raised_level) .. ", base " .. tostring(base_level))
	raised:remove()
	local explicit = wild_at(RATTATA, ORIGIN_X, ORIGIN_Z, 5)
	check(explicit:get_luaentity()._mm.level == 5,
		"an explicit level of 5 was offset to " .. tostring(explicit:get_luaentity()._mm.level))
	explicit:remove()
	T.reset()

	-- (4) the catch mode: the same exhausted Bulbasaur and the same draw give three different outcomes
	local normal = wild_at(BULBASAUR, -3, -3, 5)
	minemon.creatures.damage(normal, 9999, nil, nil)
	check(minemon.creatures.is_exhausted(normal), "the Bulbasaur (normal) is not exhausted")
	local n0, caught0 = minemon.capture._resolve(fake, normal, "poke_ball", fixed_rng(0.9999))
	check(caught0 == false, "a normal catch with a failing draw caught")
	check(n0 == 0, "a normal catch with a failing draw showed shakes: " .. tostring(n0))

	T.set("catch_mode", "always")
	local always = wild_at(BULBASAUR, -1, -3, 5)
	minemon.creatures.damage(always, 9999, nil, nil)
	local n1, caught1 = minemon.capture._resolve(fake, always, "poke_ball", fixed_rng(0.9999))
	check(caught1 == true, "catch_mode always did not catch with a failing draw")
	check(n1 == 3, "catch_mode always did not show 3 shakes: " .. tostring(n1))
	T.reset()

	T.set("catch_mode", "never")
	local never = wild_at(BULBASAUR, 1, -3, 5)
	minemon.creatures.damage(never, 9999, nil, nil)
	local n2, caught2 = minemon.capture._resolve(fake, never, "poke_ball", fixed_rng(0))
	check(caught2 == false, "catch_mode never caught, even with a passing draw")
	check(n2 == 0, "catch_mode never showed shakes: " .. tostring(n2))
	T.reset()

	-- (5) exp_mult: a defeat with the Bulbasaur out gives exp at 1 and none at 0
	local rng = minemon.rng.new(4242)
	local bulb = minemon.instance.new(species(BULBASAUR), 15, rng)
	bulb.owner = NAME
	bulb.bond = 0
	minemon.party.set(fake, { bulb })
	local sent, why = minemon.party.send_out(fake, 1)
	check(sent, "send_out failed: " .. tostring(why))
	local obj = minemon.party.get_active(fake)
	check(obj ~= nil, "the Bulbasaur is not out")
	local victim = minemon.instance.new(species(RATTATA), 10, rng)
	local victim_le = { _mm = victim, name = "minemon_creatures:rattata" }

	T.set("exp_mult", 0)
	local before = lead(fake).exp
	minemon.events.fire("creature_defeated", victim_le, obj)
	check(lead(fake).exp == before, "exp_mult 0 still granted exp: " .. before .. " -> " .. lead(fake).exp)
	T.reset()

	local before_one = lead(fake).exp
	minemon.events.fire("creature_defeated", victim_le, obj)
	check(lead(fake).exp > before_one, "exp_mult 1 granted no exp after the reset")

	-- (6) reset puts every knob back
	T.set("spawn_enabled", false)
	T.set("level_offset", -7)
	T.reset()
	check(T.is_default(), "reset did not put the knobs back to their defaults")

	for _, o in ipairs({ obj, normal, always, never }) do
		if o:is_valid() then
			o:remove()
		end
	end
	minemon.party.set(fake, {})
	finish(string.format("PASS %d checks", checks))
end

core.after(1, function()
	local ok, err = pcall(function()
		build_platform()
		run()
	end)
	if not ok then
		minemon.tuning.reset()
		finish("FAIL " .. tostring(err))
	end
end)
