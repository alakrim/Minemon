-- minemon_creatures: one mcl_mobs mob per species (D-026, T-21a). Glue only. The rules live in defs.lua and
-- habitats.lua (pure) and spawning.lua (spawn glue). Health is custom: the instance holds it (self._mm.hp).
-- luacheck: read_globals core mcl_mobs
-- luacheck: globals minemon

local MODPATH = core.get_modpath("minemon_creatures")
local defs = dofile(MODPATH .. "/defs.lua")
local spawning = dofile(MODPATH .. "/spawning.lua")

minemon.creatures = minemon.creatures or {}
local API = minemon.creatures

-- The species data is read with io, which needs a trusted mod. core.request_insecure_environment() works only
-- at init time, from this main scope. The shim is temporary (see shim_core.lua).
if minemon.data == nil then
	local shim = dofile(MODPATH .. "/shim_core.lua")
	local ok, err = shim.install(core.request_insecure_environment())
	if not ok then
		core.log("error", "[minemon_creatures] no species data: " .. tostring(err))
	end
end

-- Sets the instance's stats on the entity: HP, damage, nametag (and the object HP, which the engine ignores).
local function apply(self, species)
	local inst = self._mm
	local st = minemon.instance.stats(inst, species)
	self.hp_max = st.hp
	self.health = inst.hp
	self.old_health = inst.hp
	self.damage = 1 + math.floor(st.atk / 25 + inst.level / 10)
	local props = { hp_max = st.hp }
	if self.owner == nil or self.owner == "" then
		props.nametag_color = defs.nametag_color(species)
	end
	self.object:set_properties(props)
	self.object:set_hp(inst.hp)
	self.nametag = defs.nametag_text(species, inst.level)
	self:update_tag()
end

-- on_spawn runs once per entity, after activation. A natural spawn has no instance yet: its level comes from
-- the position and is at least the stage's minimum (the spawn gate checks the same level at the spawn node).
local function make_on_spawn(species, min_level)
	return function(self)
		if self._mm == nil then
			local pos = self.object:get_pos()
			local level = math.max(spawning.level_at(pos), min_level)
			self._mm = minemon.instance.new(species, level, spawning.rng_at(pos))
		end
		apply(self, species)
		return true
	end
end

local function species_list()
	local out = {}
	for _, id in ipairs(minemon.data.all_species_ids()) do
		out[#out + 1] = minemon.data.get_species(id)
	end
	return out
end

local function register_all()
	local list = species_list()
	local stages = defs.stages(list)
	for _, sp in ipairs(list) do
		local stage = stages[sp.id]
		local name = defs.entity_name(sp)
		local def = defs.build_def(sp)
		def.on_spawn = make_on_spawn(sp, defs.min_spawn_level(stage))
		mcl_mobs.register_mob(name, def)
		local plan = defs.spawn_plan(sp, stage)
		if plan then
			spawning.register(name, plan)
		end
	end
end

if minemon.data ~= nil then
	register_all()
end

-- Public API (PLAN.md M1 contract).

function API.key_for(species)
	return defs.key_for(species)
end

function API.entity_name(species)
	return defs.entity_name(species)
end

function API.get_instance(obj)
	local le = obj and obj:get_luaentity()
	if not le or type(le.name) ~= "string" or le.name:sub(1, #defs.PREFIX) ~= defs.PREFIX then
		return nil
	end
	return le._mm
end

-- T-21b implements the exhausted state; until then no creature is exhausted.
function API.is_exhausted(_obj)
	return false
end

-- A wild creature (owner_name nil) despawns through the sweep in spawning.lua. An owned one is tamed,
-- persistent and never despawns.
function API.spawn(pos, species_id, level, owner_name)
	local species = minemon.data.get_species(species_id)
	if not species then
		return nil
	end
	level = level or spawning.level_at(pos)
	local inst = minemon.instance.new(species, level, spawning.rng_at(pos))
	local staticdata = { _mm = inst }
	if owner_name and owner_name ~= "" then
		staticdata.owner = owner_name
		staticdata.tamed = true
		staticdata.persistent = true
		staticdata.can_despawn = false
	end
	return core.add_entity(pos, defs.entity_name(species), core.serialize(staticdata))
end
