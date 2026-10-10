-- Integration test (T-23): minemon_combat in the assembled game.
-- Builds a flat stone platform above the terrain and forceloads it, so the creatures are active. Then runs:
--   (a) ember from an owned Cyndaquil L20 at a wild Bulbasaur L20 3 m away: returns true, the orb hits, the target
--       loses HP, and the owned user's PP drops by 1;
--   (b) a second ember straight after is refused with "cooldown";
--   (c) tackle from a Bulbasaur 1.5 m away, in front of Cyndaquil, hits Cyndaquil (melee arc);
--   (d) bubble (area burst) from Squirtle hits Bulbasaur and a bystander Cyndaquil, not Squirtle (the user);
--   (e) growl (status cloud) lowers the target's atk stage once, not once per check; agility (aura) raises the
--       user's spe stage by 2; thunder_wave (status cloud) paralyses a Charmander;
--   (f) a move outside the moveset returns false; a target out of range returns false ("out of range");
--   (g) choose_move returns a move id from the moveset that is not on cooldown;
--   (h) every move in moves.json passes validate(). The warnings (valid moves that do not work fully) are written
--       to moves_report.txt in the world directory.
-- Writes PASS n or FAIL <reason> to test_result.txt, then shuts down.
-- luacheck: read_globals core minemon vector VoxelManip VoxelArea mcl_util

local LOGIC = dofile(core.get_modpath("minemon_combat") .. "/moves_logic.lua")

local X0, X1 = -16, 100
local Z0, Z1 = -16, 16
local ABOVE = 6
local FLIGHT_WAIT_S = 2
local MELEE_WAIT_S = 1.5
local CLOUD_WAIT_S = 1.5
local CLOUD_LATER_S = 4.5

local checks = 0
local finished = false
local floor_y = nil

local function finish(line)
	if finished then
		return
	end
	finished = true
	core.safe_file_write(core.get_worldpath() .. "/test_result.txt", line .. "\n")
	core.request_shutdown()
end

local function check(cond, msg)
	if not cond then
		error(msg, 0)
	end
	checks = checks + 1
end

-- Runs fn; an error ends the test with FAIL.
local function guard(fn)
	local ok, err = pcall(fn)
	if not ok then
		finish("FAIL " .. tostring(err))
	end
end

local function wait(seconds, fn)
	core.after(seconds, function()
		guard(fn)
	end)
end

local function build_platform(fy)
	local vm = VoxelManip()
	local emin, emax = vm:read_from_map(vector.new(X0, fy, Z0), vector.new(X1, fy + ABOVE, Z1))
	local area = VoxelArea:new({ MinEdge = emin, MaxEdge = emax })
	local data = vm:get_data()
	local c_air = core.get_content_id("air")
	local c_stone = core.get_content_id("mcl_core:stone")
	for z = Z0, Z1 do
		for x = X0, X1 do
			for y = fy, fy + ABOVE do
				data[area:index(x, y, z)] = (y == fy) and c_stone or c_air
			end
		end
	end
	vm:set_data(data)
	vm:write_to_map(true)
end

-- Forceloads every mapblock in the platform's box (one row more above and below, in case of a block boundary).
local function forceload(fy)
	local n = 0
	local by = math.floor(fy / 16) * 16
	for y = by - 16, by + 16, 16 do
		for x = math.floor(X0 / 16) * 16, X1, 16 do
			for z = math.floor(Z0 / 16) * 16, Z1, 16 do
				if core.forceload_block(vector.new(x, y, z), true, 256) then
					n = n + 1
				end
			end
		end
	end
	return n
end

-- A wild or owned creature at (x, z) on the platform, with the given moves. Walk and run speeds are zero, so the
-- distances the test sets stay put.
local function make(x, z, species_id, level, owner, moves)
	local pos = vector.new(x, floor_y + 0.5, z)
	local obj = minemon.creatures.spawn(pos, species_id, level, owner)
	check(obj, "spawn failed for species " .. species_id)
	local inst = minemon.creatures.get_instance(obj)
	check(inst, "no instance for species " .. species_id)
	inst.moves = {}
	for _, id in ipairs(moves) do
		local m = minemon.data.get_move(id)
		check(m, "unknown move " .. id)
		inst.moves[#inst.moves + 1] = { id = id, pp = m.pp }
	end
	local le = obj:get_luaentity()
	le.walk_velocity = 0
	le.run_velocity = 0
	return obj
end

local function face(obj, other)
	local a, b = obj:get_pos(), other:get_pos()
	obj:set_yaw(math.atan2(-(b.x - a.x), b.z - a.z))
end

local function hp_of(obj)
	return minemon.creatures.get_instance(obj).hp
end

local function move_pp(obj, id)
	for _, slot in ipairs(minemon.creatures.get_instance(obj).moves) do
		if slot.id == id then
			return slot.pp
		end
	end
	return nil
end

local function stage_of(obj, stat)
	local le = obj:get_luaentity()
	return (le._mm_stages and le._mm_stages[stat]) or 0
end

local function remove_all(list)
	for _, obj in ipairs(list) do
		if obj:get_pos() then
			obj:remove()
		end
	end
end

-- (h): every move validates. Returns the number of moves and the number of warnings.
local function validate_all_moves()
	local path = core.get_modpath("minemon_core") .. "/data/moves.json"
	local f = io.open(path, "rb")
	check(f, "cannot open " .. path)
	local text = f:read("*a")
	f:close()
	local moves = core.parse_json(text)
	check(type(moves) == "table", "cannot parse moves.json")
	local ids = {}
	for id in pairs(moves) do
		ids[#ids + 1] = id
	end
	table.sort(ids)
	local bad, lines = {}, {}
	for _, id in ipairs(ids) do
		local reason = LOGIC.validate(moves[id])
		if reason then
			bad[#bad + 1] = id .. ": " .. reason
		end
		for _, w in ipairs(LOGIC.warnings(moves[id])) do
			lines[#lines + 1] = id .. " (" .. moves[id].archetype .. "): " .. w
		end
	end
	local out = io.open(core.get_worldpath() .. "/moves_report.txt", "wb")
	if out then
		out:write(table.concat(lines, "\n") .. "\n")
		out:close()
	end
	check(#bad == 0, "invalid moves: " .. table.concat(bad, "; "))
	check(#ids > 200, "expected about 228 moves, got " .. #ids)
	return #ids, #lines
end

-- (a), (b), (f), (g): Cyndaquil (owned) and Bulbasaur (wild), 3 m apart.
local function scenario_basic(done)
	local cyn = make(0, 0, 155, 20, "tester", { "ember", "tackle", "growl" })
	local bulb = make(3, 0, 1, 20, nil, { "tackle", "growl" })
	face(cyn, bulb)
	face(bulb, cyn)
	local pp_before = move_pp(cyn, "ember")
	local hp_before = hp_of(bulb)

	local r1, why1 = minemon.combat.use_move(cyn, bulb, "ember")
	check(r1 == true, "(a) ember should start, got " .. tostring(r1) .. " " .. tostring(why1))
	check(move_pp(cyn, "ember") == pp_before - 1, "(a) owned user PP should drop by 1")
	local r2, why2 = minemon.combat.use_move(cyn, bulb, "ember")
	check(r2 == false and why2 == "cooldown", "(b) second ember should be refused with cooldown, got "
		.. tostring(r2) .. " " .. tostring(why2))
	check(minemon.combat.on_cooldown(cyn, "ember"), "(b) on_cooldown should report ember")

	local r3, why3 = minemon.combat.use_move(cyn, bulb, "hydro_pump")
	check(r3 == false and why3 == "move not in moveset", "(f) move outside the moveset, got " .. tostring(why3))
	local r5, why5 = minemon.combat.use_move(cyn, bulb, "tackle")
	check(r5 == false and why5 == "busy", "(a) a creature cannot start a second move while casting, got "
		.. tostring(why5))

	local picked = minemon.combat.choose_move(cyn, bulb)
	check(picked == "tackle" or picked == "growl", "(g) choose_move returned " .. tostring(picked))
	check(not minemon.combat.on_cooldown(cyn, picked), "(g) choose_move returned a move on cooldown")

	wait(FLIGHT_WAIT_S, function()
		check(hp_of(bulb) < hp_before, "(a) Bulbasaur HP should drop: " .. hp_before .. " -> " .. hp_of(bulb))
		-- Idle again: growl has no cooldown, so the range check is what refuses it.
		local far = make(14, 0, 4, 5, nil, { "scratch" })
		local r4, why4 = minemon.combat.use_move(cyn, far, "growl")
		check(r4 == false and why4 == "out of range", "(f) distant target should be out of range, got "
			.. tostring(why4))
		remove_all({ far, cyn, bulb })
		done()
	end)
end

-- (c): Bulbasaur tackles Cyndaquil from 1.5 m, in front.
local function scenario_melee(done)
	local bulb = make(16, 0, 1, 20, nil, { "tackle" })
	local cyn = make(17.5, 0, 155, 20, nil, { "ember" })
	face(bulb, cyn)
	face(cyn, bulb)
	-- Accuracy stage +6 so the 95% accuracy roll cannot miss (the rng is seeded from the clock). Without it the check
	-- fails about 1 run in 20, which says nothing about the melee path.
	bulb:get_luaentity()._mm_stages = { acc = 6 }
	local hp_before = hp_of(cyn)
	check(minemon.combat.use_move(bulb, cyn, "tackle") == true, "(c) tackle should start")
	wait(MELEE_WAIT_S, function()
		check(hp_of(cyn) < hp_before, "(c) Cyndaquil HP should drop from tackle: " .. hp_before .. " -> "
			.. hp_of(cyn))
		remove_all({ bulb, cyn })
		done()
	end)
end

-- (d): Squirtle's bubble hits Bulbasaur and a bystander, not Squirtle.
local function scenario_area(done)
	local squirtle = make(32, 0, 7, 20, nil, { "bubble" })
	local bulb = make(36, 0, 1, 20, nil, { "tackle" })
	local bystander = make(39, 0, 155, 20, nil, { "ember" })
	face(squirtle, bulb)
	local sq_hp, bulb_hp, by_hp = hp_of(squirtle), hp_of(bulb), hp_of(bystander)
	check(minemon.combat.use_move(squirtle, bulb, "bubble") == true, "(d) bubble should start")
	wait(FLIGHT_WAIT_S, function()
		check(hp_of(bulb) < bulb_hp, "(d) target should be hit by bubble")
		check(hp_of(bystander) < by_hp, "(d) bystander within the burst should be hit")
		check(hp_of(squirtle) == sq_hp, "(d) the user must not be hit by its own burst")
		remove_all({ squirtle, bulb, bystander })
		done()
	end)
end

-- (e): agility (aura) on the user, to spe +2.
local function scenario_aura(done)
	local pika = make(64, 0, 25, 20, nil, { "agility" })
	check(minemon.combat.use_move(pika, nil, "agility") == true, "(e) agility should start with no target")
	wait(1.5, function()
		check(stage_of(pika, "spe") == 2, "(e) agility should raise spe by 2, got " .. stage_of(pika, "spe"))
		remove_all({ pika })
		done()
	end)
end

-- (e): growl (status cloud) lowers the target's atk once, and thunder_wave (status cloud) paralyses.
local function scenario_clouds(done)
	local cyn = make(48, 0, 155, 20, nil, { "growl" })
	local bulb = make(51, 0, 1, 20, nil, { "tackle" })
	face(cyn, bulb)
	check(minemon.combat.use_move(cyn, bulb, "growl") == true, "(e) growl should start")
	wait(CLOUD_WAIT_S, function()
		check(stage_of(bulb, "atk") == -1, "(e) growl should lower atk by 1, got " .. stage_of(bulb, "atk"))
		wait(CLOUD_LATER_S, function()
			check(stage_of(bulb, "atk") == -1, "(e) growl applied more than once: atk " .. stage_of(bulb, "atk"))
			remove_all({ cyn, bulb })
			local pika = make(80, 0, 25, 20, nil, { "thunder_wave" })
			local charm = make(83, 0, 4, 20, nil, { "scratch" })
			face(pika, charm)
			check(minemon.combat.use_move(pika, charm, "thunder_wave") == true, "(e) thunder_wave should start")
			wait(CLOUD_WAIT_S, function()
				local status = minemon.creatures.get_instance(charm).status
				check(status == "paralysis", "(e) thunder_wave should paralyse Charmander, status is " .. status)
				remove_all({ pika, charm })
				done()
			end)
		end)
	end)
end

core.after(1, function()
	guard(function()
		local ground = core.get_spawn_level(0, 0) or 40
		floor_y = math.max(math.floor(ground) + 30, 80)
		local n = forceload(floor_y)
		check(n >= 8, "forceload failed (" .. n .. " blocks)")
		core.emerge_area(vector.new(X0, floor_y - 2, Z0), vector.new(X1, floor_y + ABOVE, Z1),
			function(_, _, calls_remaining)
				if calls_remaining ~= 0 then
					return
				end
				guard(function()
					build_platform(floor_y)
					local moves, warned = validate_all_moves()
					scenario_basic(function()
						scenario_melee(function()
							scenario_area(function()
								scenario_aura(function()
									scenario_clouds(function()
										finish(string.format("PASS %d checks; moves=%d warnings=%d "
											.. "(see moves_report.txt)", checks, moves, warned))
									end)
								end)
							end)
						end)
					end)
				end)
			end)
	end)
end)
