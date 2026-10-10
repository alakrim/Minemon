-- Integration test (T-21a): minemon_creatures registers all 251 species; spawn() gives the requested level,
-- health and nametag; owned spawns are tamed and never despawn; a wild creature survives 5 s; and the server step
-- interval is measured with no creatures, then with 40 creatures on dry ground in a forceloaded 64x64 area.
-- Natural spawns need players, so the creatures are spawned directly. The world seed changes every run, so the
-- test looks for a centre with enough dry ground. Writes PASS n or FAIL <reason> to test_result.txt, then shuts down.
-- luacheck: read_globals core minemon vector

local BASE_WINDOW_S = 8 -- step interval with no creatures
local LOAD_WINDOW_S = 75 -- step interval with PERF_COUNT creatures (the run stays under the 120 s timeout)
local SKIP_STEPS = 20 -- samples right after a phase change are skipped
local PERF_COUNT = 40
local HALF = 32 -- the perf area is 64x64 around the centre
local TOP, BOTTOM = 80, -8 -- vertical search and forceload range around the centre height
local CENTRES = { { 0, 0 }, { 96, 0 }, { -96, 0 }, { 0, 96 }, { 0, -96 } }
local MIN_DRY = 10

local finished = false
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
end

local function registration_check()
	local ids = minemon.data.all_species_ids()
	check(#ids == 251, "expected 251 species, got " .. #ids)
	local seen = {}
	for _, id in ipairs(ids) do
		local sp = minemon.data.get_species(id)
		check(sp, "species " .. id .. " missing")
		local name = minemon.creatures.entity_name(sp)
		check(core.registered_entities[name], "not registered: " .. name)
		check(not seen[name], "duplicate entity name: " .. name)
		seen[name] = true
	end
	check(minemon.creatures.key_for("Mr. Mime") == "mr_mime", "key_for(Mr. Mime) is wrong")
	return #ids
end

-- Wild and owned spawns at pos. Returns the number of checks made.
local function spawn_checks(pos)
	local obj = minemon.creatures.spawn(pos, 19, 7, nil)
	check(obj, "spawn(Rattata, 7) returned nil")
	local inst = minemon.creatures.get_instance(obj)
	check(inst, "no instance on the spawned object")
	check(inst.level == 7, "level is " .. tostring(inst.level) .. ", want 7")
	local le = obj:get_luaentity()
	check(le.health == inst.hp, "luaentity health " .. tostring(le.health) .. " ~= instance hp " .. inst.hp)
	check(obj:get_hp() == inst.hp, "object hp " .. obj:get_hp() .. " ~= instance hp " .. inst.hp)
	check(le.can_despawn == true, "wild creature must be able to despawn")
	check(not le.tamed, "wild creature must not be tamed")
	check(string.find(le.nametag or "", "Lv 7", 1, true), "nametag has no 'Lv 7': " .. tostring(le.nametag))
	check(string.find(le.nametag or "", "Rattata", 1, true), "nametag has no species name")
	local c = obj:get_properties().nametag_color
	if type(c) == "table" then
		check(c.r == 255 and c.g == 48 and c.b == 48, "Rattata nametag colour should be #FF3030")
	else
		check(string.upper(tostring(c)):find("FF3030", 1, true), "Rattata nametag colour should be #FF3030")
	end
	local box = obj:get_properties().collisionbox
	check(box and math.abs(box[5] - 0.25) < 1e-3, "Rattata (tiny) collision box height should be 0.25")
	check(minemon.creatures.is_exhausted(obj) == false, "is_exhausted must be false in T-21a")
	check(minemon.creatures.spawn(pos, 99999, 5, nil) == nil, "unknown species should return nil")

	local owned = minemon.creatures.spawn(pos, 25, 12, "tester")
	check(owned, "owned spawn returned nil")
	local ole = owned:get_luaentity()
	check(ole.can_despawn == false, "owned creature must not despawn")
	check(ole.persistent == true, "owned creature must be persistent")
	check(ole.tamed == true, "owned creature must be tamed")
	check(ole.owner == "tester", "owner is " .. tostring(ole.owner))
	check(minemon.creatures.get_instance(owned).level == 12, "owned level is wrong")
	return 16
end

-- Walkable full-cube top in column x, z, scanning down from TOP. Returns the standing position, or nil when the
-- column is water, has a partial block (stairs, slabs, fences) or has no two free nodes above it. A creature
-- placed on a partial block or under a low ceiling sinks into it and suffocates.
local function is_solid(name)
	local def = core.registered_nodes[name]
	return def ~= nil and def.walkable == true
end

local function surface_at(x, z)
	for y = TOP, BOTTOM, -1 do
		local node = core.get_node({ x = x, y = y, z = z })
		if is_solid(node.name) and node.name ~= "ignore" then
			local def = core.registered_nodes[node.name]
			if def.drawtype ~= nil and def.drawtype ~= "normal" then
				return nil
			end
			local a1 = core.get_node({ x = x, y = y + 1, z = z }).name
			local a2 = core.get_node({ x = x, y = y + 2, z = z }).name
			local above = core.registered_nodes[a1]
			if above and above.liquidtype and above.liquidtype ~= "none" then
				return nil
			end
			if is_solid(a1) or is_solid(a2) then
				return nil
			end
			return { x = x, y = y + 1, z = z }
		end
	end
	return nil
end

-- True when the eight neighbouring columns stand within one node of this height. A creature next to a steep wall
-- can walk into it and suffocate, which would make the survival check fail for the terrain, not for the mod.
local function is_flat(p)
	for dx = -1, 1 do
		for dz = -1, 1 do
			if not (dx == 0 and dz == 0) then
				local q = surface_at(p.x + dx, p.z + dz)
				if not q or math.abs(q.y - p.y) > 1 then
					return false
				end
			end
		end
	end
	return true
end

-- Flat, dry standing positions in the 64x64 area around centre (cx, cz), one per column on a 4-node grid.
local function dry_positions(cx, cz)
	local out = {}
	for dx = -HALF, HALF - 1, 4 do
		for dz = -HALF, HALF - 1, 4 do
			local p = surface_at(cx + dx, cz + dz)
			if p and is_flat(p) then
				out[#out + 1] = p
			end
		end
	end
	return out
end

-- Step interval measurement. Registered at load time (globalsteps cannot be added later).
local perf = nil

local function phase_summary(p)
	if p.count == 0 then
		return -1, 0
	end
	return p.sum / p.count, p.max
end

local function spawn_perf(positions)
	local creatures = {}
	local ids = { 19, 16, 25, 133, 122, 95, 4, 1, 143, 152 } -- land species only: fish die out of water
	for i = 1, PERF_COUNT do
		local pos = positions[(i - 1) % #positions + 1]
		local id = ids[(i - 1) % #ids + 1]
		local obj = minemon.creatures.spawn(pos, id, 5 + (i % 10), nil)
		check(obj, "perf spawn " .. i .. " failed")
		creatures[#creatures + 1] = { obj = obj, id = id }
	end
	return creatures
end

local function perf_step()
	if not perf or perf.report then
		return
	end
	local now = core.get_us_time()
	if perf.last then
		perf.steps = perf.steps + 1
		if perf.steps > SKIP_STEPS then
			local ms = (now - perf.last) / 1000
			local p = perf[perf.phase]
			p.sum = p.sum + ms
			p.count = p.count + 1
			if ms > p.max then
				p.max = ms
			end
		end
	end
	perf.last = now
	local elapsed = (now - perf.phase_started) / 1e6
	if perf.phase == "base" and elapsed >= BASE_WINDOW_S then
		local ok, res = pcall(spawn_perf, perf.positions)
		if not ok then
			perf.report = true
			finish("FAIL " .. tostring(res))
			return
		end
		perf.creatures = res
		perf.phase = "load"
		perf.phase_started = now
		perf.steps = 0
	elseif perf.phase == "load" and elapsed >= LOAD_WINDOW_S then
		perf.report = true
		local alive = 0
		for _, c in ipairs(perf.creatures) do
			if c.obj:get_pos() then
				alive = alive + 1
			end
		end
		local base_avg, base_max = phase_summary(perf.base)
		local load_avg, load_max = phase_summary(perf.load)
		finish(string.format("PASS %d checks; step_interval_ms base_avg=%.2f base_max=%.2f "
			.. "load_avg=%.2f load_max=%.2f steps=%d creatures=%d alive=%d",
			perf.checks, base_avg, base_max, load_avg, load_max, perf.load.count, #perf.creatures, alive))
	end
end
core.register_globalstep(perf_step)

-- Forceloads every mapblock that covers the 64x64 area between BOTTOM and TOP, so the creatures stay active.
-- Returns the number of blocks forceloaded.
local function forceload_area(cx, cy, cz)
	local blocks = 0
	local lo = math.floor((cy + BOTTOM) / 16) * 16
	local hi = math.floor((cy + TOP) / 16) * 16
	for y = lo, hi, 16 do
		for x = cx - HALF, cx + HALF - 1, 16 do
			for z = cz - HALF, cz + HALF - 1, 16 do
				if core.forceload_block(vector.new(x, y, z), true, 256) then
					blocks = blocks + 1
				end
			end
		end
	end
	return blocks
end

local function run(positions, checks)
	-- The probe stands on another dry position, not on the perf area's first one.
	local probe_pos = positions[#positions]
	local probe = minemon.creatures.spawn(probe_pos, 19, 3, nil)
	if not probe then
		finish("FAIL probe spawn failed")
		return
	end
	local probe_le = probe:get_luaentity()
	core.after(5, function()
		if not probe:get_pos() then
			finish(string.format("FAIL probe creature gone after 5 s (last health %s, spawned at %s)",
				tostring(probe_le.health), core.pos_to_string(probe_pos, 1)))
			return
		end
		perf = {
			phase = "base", phase_started = core.get_us_time(), last = nil, steps = 0, creatures = {},
			positions = positions, checks = checks + 1,
			base = { sum = 0, count = 0, max = 0 }, load = { sum = 0, count = 0, max = 0 },
		}
	end)
end

-- Emerges the box around centre index i, then uses it if it has enough dry ground; otherwise tries the next.
local function try_centre(i, checks)
	if i > #CENTRES then
		finish("FAIL no centre with " .. MIN_DRY .. " dry columns in the perf area")
		return
	end
	local cx, cz = CENTRES[i][1], CENTRES[i][2]
	core.emerge_area(vector.new(cx - HALF, BOTTOM, cz - HALF), vector.new(cx + HALF, TOP, cz + HALF),
		function(_, _, calls_remaining)
			if calls_remaining ~= 0 then
				return
			end
			local ok, err = pcall(function()
				local positions = dry_positions(cx, cz)
				if #positions < MIN_DRY then
					try_centre(i + 1, checks)
					return
				end
				-- The centre is the first dry position; the probe and the perf creatures stand on the same ground.
				local centre = positions[1]
				local ys = {}
				for _, p in ipairs(positions) do
					ys[#ys + 1] = p.y
				end
				table.sort(ys)
				local mid = { x = centre.x, y = ys[math.floor(#ys / 2) + 1], z = centre.z }
				check(forceload_area(cx, mid.y, cz) >= 16, "forceload failed")
				local n = checks + registration_check()
				n = n + spawn_checks(centre)
				run(positions, n)
			end)
			if not ok then
				finish("FAIL " .. tostring(err))
			end
		end)
end

core.after(1, function()
	try_centre(1, 0)
end)
