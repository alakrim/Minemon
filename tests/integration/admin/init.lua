-- Integration test (T-33, D-033): the admin panel's actions in the assembled game, with no real players.
-- A stone platform at the origin is forceloaded. The admin is a fake player with the minemon_admin privilege (an auth
-- record is made for it); the other fake has no privilege. Checks:
--   (1) the minemon_admin privilege and /admin are registered; a name without the privilege is refused;
--   (2) spawn 2 Rattata Lv 7 in front of the player: 2 creatures, both at level 7;
--   (3) spawn with Exhausted: the creature is exhausted; spawn with Shiny: the instance is shiny; without: not;
--   (4) the Hard preset sets catch_mult 0.5, level_offset 10, dread_mult 2, exp_mult 0.75; Normal resets every knob;
--   (5) the tuning field path (t_catch_mult) and the −/+ step set the knobs;
--   (6) Clear wild removes the wild creatures spawned here;
--   (7) the time buttons, the give-items group (no inventory: it counts the registered items) and the fly toggle.
-- Writes PASS n or FAIL <reason> to test_result.txt, then shuts down.
-- luacheck: read_globals core minemon vector

local PLATFORM_Y = 5 -- stone top at y = 5.5
local HALF = 6
local TOP_Y = 9
local STONE = "mcl_core:stone"
local PRIV = "minemon_admin"
local ADMIN = "admin_test_admin"
local NOPRIV = "admin_test_nopriv"
local SPECIES = "rattata"
local LEVEL = 7

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

-- Runs fn after delay seconds; a failure ends the test with FAIL.
local function stage(delay, fn)
	core.after(delay, function()
		local ok, err = pcall(fn)
		if not ok then
			finish("FAIL " .. tostring(err))
		end
	end)
end

-- A fake player: the methods the panel calls, with self as the first argument where Luanti passes it.
local function make_fake(name)
	local fake = {}
	fake.get_player_name = function()
		return name
	end
	fake.get_pos = function()
		return vector.new(0, PLATFORM_Y + 0.5, 0)
	end
	fake.get_look_dir = function()
		return vector.new(0, 0, 1)
	end
	fake.get_properties = function()
		return {}
	end
	fake.is_valid = function()
		return true
	end
	fake.is_player = function()
		return true
	end
	fake.set_pos = function(_, p)
		fake.last_pos = p
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

-- An auth record and the privilege for a name (the fake players are not connected).
local function grant(name, privs)
	local auth = core.get_auth_handler()
	if auth.get_auth(name) == nil then
		auth.create_auth(name, core.get_password_hash(name, "test"))
	end
	core.set_player_privs(name, privs)
end

local function spawn_params(count, extra)
	local p = { species = SPECIES, level = tostring(LEVEL), count = tostring(count), dread = false, shiny = false,
		exhausted = false, give = false }
	for k, v in pairs(extra or {}) do
		p[k] = v
	end
	return p
end

-- A knob is the wanted value (steps leave float noise, so within 1e-6).
local function knob_is(key, want)
	local got = minemon.tuning.get(key)
	local same = type(got) == "number" and math.abs(got - want) < 1e-6 or got == want
	return same, string.format("%s is %s, want %s", key, tostring(got), tostring(want))
end

local admin, nobody, spawned = nil, nil, {}
local clear_objs = {}

local function part_one()
	check(core.registered_privileges[PRIV] ~= nil, "privilege " .. PRIV .. " is not registered")
	check(core.registered_chatcommands["admin"] ~= nil, "/admin is not registered")
	check(minemon.admin ~= nil and minemon.admin.spawn ~= nil, "minemon.admin is missing")
	build_platform()
	grant(ADMIN, { interact = true, [PRIV] = true })
	grant(NOPRIV, { interact = true })
	admin = make_fake(ADMIN)
	nobody = make_fake(NOPRIV)

	local ok = minemon.admin.spawn(nobody, spawn_params(1))
	check(ok == false, "a name without the privilege was not refused")
	check(minemon.admin.preset(nobody, "Hard") == false, "a preset ran without the privilege")

	local ok2, text2, objs = minemon.admin.spawn(admin, spawn_params(2))
	check(ok2 == true, "spawn 2 failed: " .. tostring(text2))
	check(objs ~= nil and #objs == 2, "expected 2 creatures, got " .. tostring(objs and #objs))
	for _, obj in ipairs(objs) do
		local inst = minemon.creatures.get_instance(obj)
		check(inst ~= nil and inst.level == LEVEL, "creature is not level " .. LEVEL)
		check(inst.shiny == false, "a plain spawn came out shiny")
		spawned[#spawned + 1] = obj
	end

	local ok3, _, exhausted = minemon.admin.spawn(admin, spawn_params(1, { exhausted = true, level = "5" }))
	check(ok3 == true and exhausted ~= nil and #exhausted == 1, "exhausted spawn failed")
	check(minemon.creatures.is_exhausted(exhausted[1]), "the Exhausted spawn is not exhausted")
	spawned[#spawned + 1] = exhausted[1]

	local ok4, _, shiny = minemon.admin.spawn(admin, spawn_params(1, { shiny = true }))
	check(ok4 == true and shiny ~= nil, "shiny spawn failed")
	check(minemon.creatures.get_instance(shiny[1]).shiny == true, "the Shiny spawn is not shiny")
	spawned[#spawned + 1] = shiny[1]

	local okb, textb = minemon.admin.spawn(admin, spawn_params(1, { species = "nosuchmon" }))
	check(okb == false and textb:find("Unknown species", 1, true) ~= nil, "an unknown species was accepted")
	local okc = minemon.admin.spawn(admin, spawn_params(1, { level = "101" }))
	check(okc == false, "level 101 was accepted")
end

local function part_two()
	check(minemon.admin.preset(admin, "Hard") == true, "Hard preset failed")
	local ok1, why1 = knob_is("catch_mult", 0.5)
	check(ok1, why1)
	local ok2, why2 = knob_is("level_offset", 10)
	check(ok2, why2)
	local ok3, why3 = knob_is("dread_mult", 2)
	check(ok3, why3)
	local ok4, why4 = knob_is("exp_mult", 0.75)
	check(ok4, why4)

	minemon.admin.apply_fields(admin, { t_catch_mult = "2" })
	local ok5, why5 = knob_is("catch_mult", 2)
	check(ok5, why5)
	minemon.admin.step(admin, "catch_mult", 1)
	local ok6, why6 = knob_is("catch_mult", 2.1)
	check(ok6, why6)
	minemon.admin.step(admin, "catch_mult", -1)
	minemon.admin.step(admin, "catch_mult", -1)
	local ok7, why7 = knob_is("catch_mult", 1.9)
	check(ok7, why7)

	check(minemon.admin.preset(admin, "Normal") == true, "Normal preset failed")
	check(minemon.tuning.is_default(), "Normal did not reset every knob")

	-- The time buttons and the fly toggle, on the fake player's name.
	check(minemon.admin.set_time(admin, "midnight") == true, "set_time failed")
	local t = core.get_timeofday()
	check(t < 0.02 or t > 0.98, "time is not midnight: " .. tostring(t))
	check(minemon.admin.toggle_fly(admin) == true, "toggle_fly failed")
	check(core.get_player_privs(ADMIN).fly == true, "fly was not granted")
	minemon.admin.toggle_fly(admin)
	check(core.get_player_privs(ADMIN).fly ~= true, "fly was not taken back")

	local okg = minemon.admin.give_items(admin, "balls")
	check(okg == true, "give_items balls failed")
	check(minemon.admin.give_items(admin, "nosuchgroup") == false, "an unknown item group was accepted")

	clear_objs = spawned
	local okw, textw = minemon.admin.clear_wild(admin)
	check(okw == true, "clear_wild failed: " .. tostring(textw))
end

local function part_three()
	for _, obj in ipairs(clear_objs) do
		check(not obj:is_valid(), "a wild creature survived Clear wild")
	end
	finish("PASS " .. checks)
end

stage(1, part_one)
stage(2, part_two)
stage(3, part_three)
