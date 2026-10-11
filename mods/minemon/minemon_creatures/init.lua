-- minemon_creatures: one mcl_mobs mob per species (D-026, T-21a). Glue only. The rules live in defs.lua and
-- habitats.lua (pure) and spawning.lua (spawn glue). Health is custom: the instance holds it (self._mm.hp).
-- luacheck: read_globals core mcl_mobs
-- luacheck: globals minemon

local MODPATH = core.get_modpath("minemon_creatures")
local defs = dofile(MODPATH .. "/defs.lua")
local spawning = dofile(MODPATH .. "/spawning.lua")
local runtime = dofile(MODPATH .. "/runtime.lua")
local wild_brain = dofile(MODPATH .. "/wild_brain.lua")

minemon.creatures = minemon.creatures or {}
local API = minemon.creatures

-- The generated Cobblemon pack's entry for a dex number, or nil (T-25c, D-029). The pack defines a global.
local function pack_entry(dex)
	local pack = rawget(_G, "minemon_pack")
	local models = pack and pack.models
	return models and models[dex] or nil
end

-- Sets the model, texture and collision box for the instance's shiny state (T-25c). mcl_mobs picks its own
-- texture at activation, so this runs from on_spawn and after_activate.
local function apply_visual(self, species)
	local inst = self._mm
	if inst == nil then
		return
	end
	local vis = defs.visual_for(species, pack_entry(species.id), inst.shiny == true)
	self.object:set_properties({
		mesh = vis.mesh,
		textures = vis.textures[1], -- the engine takes one flat list of texture names
		visual_size = vis.visual_size,
		collisionbox = vis.collisionbox,
		selectionbox = vis.selectionbox,
	})
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
-- A natural spawn is wild, so it rolls for shiny (T-25c).
local function make_on_spawn(species, min_level)
	return function(self)
		if self._mm == nil then
			local pos = self.object:get_pos()
			local level = math.max(spawning.level_at(pos), min_level)
			local rng = spawning.rng_at(pos)
			self._mm = minemon.instance.new(species, level, rng)
			self._mm.shiny = defs.roll_shiny(rng)
		end
		apply(self, species)
		apply_visual(self, species)
		return true
	end
end

-- after_activate runs on every activation, after on_spawn: the runtime hook first, then the visuals (T-25c).
local function make_after_activate(species)
	return function(self, staticdata, def, dtime)
		runtime.after_activate(self, staticdata, def, dtime)
		apply_visual(self, species)
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
		local def = defs.build_def(sp, pack_entry(sp.id))
		def.on_spawn = make_on_spawn(sp, defs.min_spawn_level(stage))
		-- Runtime hooks (T-24): brains, the single damage path, punches, death safety net.
		def.do_custom = runtime.do_custom
		def.do_punch = runtime.do_punch
		def.deal_damage = runtime.deal_damage
		def.after_activate = make_after_activate(sp)
		def.on_die = runtime.on_die
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

-- Runtime API (T-24, D-027). The rules are in runtime_logic.lua; see runtime.lua for the hooks.

-- The single damage path: returns the HP removed. info = {move_id?, effectiveness?, crit?, source?, type?}.
API.damage = runtime.damage

-- Adds HP up to max; returns the HP added. Exhausted creatures do not heal.
API.heal = runtime.heal

-- Called when a creature's HP reaches 0: wild creatures become exhausted, owned creatures faint.
API.on_zero_hp = runtime.on_zero_hp

-- A failed capture (D-030, T-26): the exhausted creature breaks free and turns on the aggressor for 30 s.
API.break_free = runtime.break_free

function API.is_exhausted(obj)
	return runtime.is_exhausted(obj)
end

function API.is_owned(obj)
	return runtime.is_owned(obj)
end

function API.owner_name(obj)
	return runtime.owner_name(obj)
end

-- Brains run in do_custom in registration order. Return true to stop the chain (mcl default states still run),
-- "skip_states" to stop the chain and skip the default states, or nil to continue.
API.register_brain = runtime.register_brain

-- Wild brain (T-21b, D-009, D-026): aggressive, territorial, skittish and peaceful temperaments. It runs in the
-- brain chain and hears every hit on a wild creature. The rules are in wild_logic.lua; wild_brain.lua is the glue.
API.wild = wild_brain
API.register_brain("wild", wild_brain.think)
minemon.events.register("creature_hurt", wild_brain.on_hurt)

-- A wild creature (owner_name nil) despawns through the sweep in spawning.lua. An owned one is tamed,
-- persistent and never despawns.
function API.spawn(pos, species_id, level, owner_name)
	local species = minemon.data.get_species(species_id)
	if not species then
		return nil
	end
	level = level or spawning.level_at(pos)
	local rng = spawning.rng_at(pos)
	local inst = minemon.instance.new(species, level, rng)
	local staticdata = { _mm = inst }
	if owner_name and owner_name ~= "" then
		staticdata.owner = owner_name
		staticdata.tamed = true
		staticdata.persistent = true
		staticdata.can_despawn = false
	else
		-- A wild spawn rolls for shiny (T-25c). Owned spawns (captures) keep the instance's own flag.
		inst.shiny = defs.roll_shiny(rng)
	end
	return core.add_entity(pos, defs.entity_name(species), core.serialize(staticdata))
end
