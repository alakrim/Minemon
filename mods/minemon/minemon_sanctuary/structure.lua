-- minemon_sanctuary: the shrine itself (T-28, D-030). Glue: it builds the nodes with code (no schematic file).
-- Layout, from the floor centre F = (x, y0, z), with y0 the floor node:
--   floor      9 x 9 stonebrick at y0, cleared air above it up to y0 + 8 (an open roof: the sky stays)
--   pillars    4 stonebrick columns at the corners, y0 + 1 .. y0 + 4, each topped by a lantern at y0 + 5
--   frame      stonebrick beams along the edges at y0 + 4, between the pillars
--   altar      the centre, at y0 + 1 (the sanctuary centre); its air above is the respawn point
--   PC         west side, at (x - 2, y0 + 1, z); the keeper's counter on the east side, at (x + 2, y0 + 1, z)
-- Pure: nothing here reads the world except core.get_spawn_level, core.get_node and mcl_spawn's world spawn.
-- luacheck: read_globals core mcl_spawn

local M = {}

local NODE = {
	altar = "minemon_sanctuary:altar",
	pc = "minemon_sanctuary:pc",
	counter = "minemon_sanctuary:counter",
	lantern = "minemon_sanctuary:lantern",
	floor = "mcl_core:stonebrick",
}
M.NODE = NODE

local HALF = 4 -- the floor is 9 x 9: offsets -4 .. 4
local PILLAR = 3 -- the corner pillars stand at offsets +-3
local ROOF_CLEAR = 8 -- air is cleared up to y0 + ROOF_CLEAR
local BEAM_Y = 4 -- frame beams at y0 + 4 (the top of the pillars)
local LANTERN_Y = 5 -- the corner lanterns at y0 + 5

-- Places the sanctuary with its floor centre at floor_pos (the floor node). Returns the altar position (the centre),
-- or nil when the position is unusable. The caller registers the centre.
function M.place(floor_pos)
	if floor_pos == nil then
		return nil
	end
	local x, y0, z = floor_pos.x, floor_pos.y, floor_pos.z
	-- Clear the volume first, so nothing of the old terrain is left in the way.
	for dx = -HALF, HALF do
		for dz = -HALF, HALF do
			core.set_node({ x = x + dx, y = y0, z = z + dz }, { name = NODE.floor })
			for dy = 1, ROOF_CLEAR do
				core.set_node({ x = x + dx, y = y0 + dy, z = z + dz }, { name = "air" })
			end
		end
	end
	-- Frame beams along the four edges, corners excluded (the pillars stand there).
	for d = -PILLAR + 1, PILLAR - 1 do
		core.set_node({ x = x + d, y = y0 + BEAM_Y, z = z - PILLAR }, { name = NODE.floor })
		core.set_node({ x = x + d, y = y0 + BEAM_Y, z = z + PILLAR }, { name = NODE.floor })
		core.set_node({ x = x - PILLAR, y = y0 + BEAM_Y, z = z + d }, { name = NODE.floor })
		core.set_node({ x = x + PILLAR, y = y0 + BEAM_Y, z = z + d }, { name = NODE.floor })
	end
	-- Corner pillars and their lanterns.
	for _, sx in ipairs({ -PILLAR, PILLAR }) do
		for _, sz in ipairs({ -PILLAR, PILLAR }) do
			for dy = 1, BEAM_Y do
				core.set_node({ x = x + sx, y = y0 + dy, z = z + sz }, { name = NODE.floor })
			end
			core.set_node({ x = x + sx, y = y0 + LANTERN_Y, z = z + sz }, { name = NODE.lantern })
		end
	end
	-- The altar at the centre, the PC and the counter on the sides.
	local altar = { x = x, y = y0 + 1, z = z }
	core.set_node(altar, { name = NODE.altar })
	core.set_node({ x = x - 2, y = y0 + 1, z = z }, { name = NODE.pc })
	core.set_node({ x = x + 2, y = y0 + 1, z = z }, { name = NODE.counter })
	return altar
end

-- Ground for a sanctuary near (cx, cz): the first candidate whose 9 x 9 floor is solid and dry. Returns the floor
-- node position, or nil. Candidates are scanned at radii 8, 12 and 16 (8 angles each).
local function is_dry_solid(node_name)
	local def = core.registered_nodes[node_name]
	return def ~= nil and (def.liquidtype or "none") == "none" and node_name ~= "air" and node_name ~= "ignore"
end

local function floor_ok(x, y0, z)
	for _, dx in ipairs({ -HALF, 0, HALF }) do
		for _, dz in ipairs({ -HALF, 0, HALF }) do
			local node = core.get_node_or_nil({ x = x + dx, y = y0, z = z + dz })
			if node == nil or not is_dry_solid(node.name) then
				return false
			end
		end
	end
	return true
end

-- The first solid dry node with air above it, scanning down one column through the loaded area. Nil when none.
local SCAN_TOP = 96
local SCAN_BOTTOM = -48
local function scan_column(x, z)
	for y = SCAN_TOP, SCAN_BOTTOM, -1 do
		local node = core.get_node_or_nil({ x = x, y = y, z = z })
		local above = core.get_node_or_nil({ x = x, y = y + 1, z = z })
		if node ~= nil and above ~= nil and above.name == "air" and is_dry_solid(node.name) then
			return { x = x, y = y, z = z }
		end
	end
	return nil
end

-- The floor node for a sanctuary near the point (cx, cz), or nil. The spawn level is one above the ground.
-- Candidates come from core.get_spawn_level at radii 8, 12 and 16; when none is dry and solid, the centre column
-- is scanned.
function M.find_ground(cx, cz, ring_points)
	for _, radius in ipairs({ 8, 12, 16 }) do
		for _, p in ipairs(ring_points(cx, cz, radius, 8)) do
			local level = core.get_spawn_level(p.x, p.z)
			if level ~= nil and floor_ok(p.x, level - 1, p.z) then
				return { x = p.x, y = level - 1, z = p.z }
			end
		end
	end
	-- Only a floor that passes floor_ok is used: an unchecked fallback could build over water or air.
	local col = scan_column(math.floor(cx + 0.5), math.floor(cz + 0.5))
	if col ~= nil and floor_ok(col.x, col.y, col.z) then
		return col
	end
	return nil
end

-- The world spawn point (the static spawn, mcl_spawn's world spawn, or the origin).
function M.world_spawn()
	if mcl_spawn and mcl_spawn.get_world_spawn_pos then
		local ok, pos = pcall(mcl_spawn.get_world_spawn_pos)
		if ok and pos then
			return pos
		end
	end
	return { x = 0, y = 8, z = 0 }
end

return M
