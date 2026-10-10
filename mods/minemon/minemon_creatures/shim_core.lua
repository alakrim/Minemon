-- TEMPORARY SHIM (T-21a). Opus deletes this file at merge, once T-20 (minemon_core API) has landed.
-- minemon_creatures/init.lua loads it only when minemon.data is nil. It fills only the tables that are missing:
-- data (get_species, all_species_ids), rng, formulas (calc_stats, wild_level), instance (new, stats).
-- Reading species.json needs io, which only a trusted mod has; init.lua passes the insecure environment in.
-- luacheck: read_globals core PcgRandom
-- luacheck: globals minemon

local M = {}

local STATS = { "hp", "atk", "def", "spa", "spd", "spe" }

local function clamp(v, lo, hi)
	if v < lo then
		return lo
	end
	if v > hi then
		return hi
	end
	return v
end

local function new_rng(seed)
	local pcg = PcgRandom(seed)
	local rng = {}
	rng.float = function(_self)
		return pcg:next(0, 65535) / 65536
	end
	rng.int = function(_self, a, b)
		return pcg:next(a, b)
	end
	return rng
end

local function calc_stats(base, level, ivs, bond)
	local function other(b, iv)
		return math.floor(math.floor((2 * b + iv) * level / 100) + 5)
	end
	local s = {
		hp = math.floor((2 * base.hp + ivs.hp) * level / 100) + level + 10,
		atk = other(base.atk, ivs.atk),
		def = other(base.def, ivs.def),
		spa = other(base.spa, ivs.spa),
		spd = other(base.spd, ivs.spd),
		spe = other(base.spe, ivs.spe),
	}
	local mult = 1 + math.floor((bond or 0) / 25) / 100
	for _, k in ipairs(STATS) do
		s[k] = math.floor(s[k] * mult)
	end
	return s
end

local function wild_level(distance, is_night, rng)
	local lvl = 2 + math.floor(distance / 80) + rng:int(-2, 2)
	if is_night then
		lvl = math.floor(lvl * 1.2)
	end
	return clamp(lvl, 2, 70)
end

local function new_instance(species, level, rng)
	local ivs = {}
	for _, k in ipairs(STATS) do
		ivs[k] = rng:int(0, 15)
	end
	local stats = calc_stats(species.base_stats, level, ivs, 0)
	local learned = {}
	for _, e in ipairs(species.learnset or {}) do
		if e.level <= level then
			learned[#learned + 1] = { id = e.move, pp = 10 }
		end
	end
	local moves = {}
	for i = math.max(1, #learned - 3), #learned do
		moves[#moves + 1] = learned[i]
	end
	return {
		uid = tostring(species.id) .. "-" .. tostring(rng:int(1, 1000000000)),
		species_id = species.id,
		nickname = "",
		level = level,
		exp = 0,
		ivs = ivs,
		bond = 0,
		hp = stats.hp,
		status = "none",
		moves = moves,
		ball = "poke_ball",
		shiny = false,
		owner = nil,
	}
end

-- ins: the insecure environment (or nil). Returns true, or nil and a reason.
function M.install(ins)
	if not ins or not ins.io then
		return nil, "minemon_core data needs a trusted mod (add it to secure.trusted_mods)"
	end
	local path = core.get_modpath("minemon_core") .. "/data/species.json"
	local f, err = ins.io.open(path, "rb")
	if not f then
		return nil, tostring(err)
	end
	local text = f:read("*a")
	f:close()
	local list = core.parse_json(text)
	if type(list) ~= "table" then
		return nil, "species.json did not parse"
	end

	local by_id, by_name = {}, {}
	for _, sp in ipairs(list) do
		by_id[sp.id] = sp
		by_name[string.lower(sp.name)] = sp
	end
	minemon.data = minemon.data or {
		get_species = function(id_or_name)
			if type(id_or_name) == "number" then
				return by_id[id_or_name]
			end
			return by_name[string.lower(tostring(id_or_name))]
		end,
		all_species_ids = function()
			local ids = {}
			for i = 1, #list do
				ids[i] = list[i].id
			end
			return ids
		end,
	}
	minemon.rng = minemon.rng or { new = new_rng }
	minemon.formulas = minemon.formulas or { calc_stats = calc_stats, wild_level = wild_level }
	minemon.instance = minemon.instance or {
		new = new_instance,
		stats = function(inst, species)
			return calc_stats(species.base_stats, inst.level, inst.ivs, inst.bond)
		end,
	}
	return true
end

return M
