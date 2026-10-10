-- Status effects on creatures and players (T-23). Glue: the maths is in status_logic.lua.
-- One record per object in a bounded registry, keyed by the object's guid (player name for players).
-- A creature's status is mirrored to its instance (inst.status) and its walk and run speed. init.lua ticks this
-- from its single globalstep.
-- luacheck: read_globals core minemon

local SL = dofile(core.get_modpath("minemon_combat") .. "/status_logic.lua")

local M = {}
local registry = SL.new_registry(SL.REGISTRY_CAP)

local function key_of(obj)
	return obj:get_guid()
end

-- The status kind of obj, or "none".
function M.get(obj)
	if not obj or not obj:get_pos() then
		return "none"
	end
	local e = registry.get(key_of(obj))
	return e and e.record.kind or "none"
end

-- Creature: instance status and walk and run speeds. Player: paralysis halves the physics speed.
local function set_mirror(obj, kind)
	local inst = minemon.creatures.get_instance(obj)
	local le = obj:get_luaentity()
	if inst and le then
		inst.status = kind
		le._mm_base_speed = le._mm_base_speed or { walk = le.walk_velocity or 0, run = le.run_velocity or 0 }
		local m = SL.speed_mult(kind)
		le.walk_velocity = le._mm_base_speed.walk * m
		le.run_velocity = le._mm_base_speed.run * m
	elseif obj:is_player() then
		local p = obj:get_physics_override()
		p.speed = kind == "paralysis" and SL.PARALYSIS_SPEED or 1
		obj:set_physics_override(p)
	end
end

-- Gives obj a status of the minimal set. Returns false when obj already has one, or the kind is not in the set.
function M.apply(obj, kind, rng)
	if not SL.is_minimal(kind) or not obj or not obj:get_pos() then
		return false
	end
	local key = key_of(obj)
	if registry.get(key) ~= nil then
		return false
	end
	if not registry.put(key, { obj = obj, record = SL.new_record(kind, rng) }) then
		return false
	end
	set_mirror(obj, kind)
	return true
end

function M.clear(obj)
	local key = key_of(obj)
	if registry.get(key) == nil then
		return
	end
	registry.remove(key)
	if obj:get_pos() then
		set_mirror(obj, "none")
	end
end

-- Sleep ends when the target takes damage.
function M.wake_on_damage(obj)
	if M.get(obj) == "sleep" then
		M.clear(obj)
	end
end

-- A fire move thaws a frozen target.
function M.thaw_on_fire(obj)
	if M.get(obj) == "freeze" then
		M.clear(obj)
	end
end

-- Advances every status by dt seconds (init.lua calls this every 0.5 s). damage_fn(obj, amount) applies burn and
-- poison damage. Removed objects are pruned first.
function M.tick(dt, rng, damage_fn)
	registry.prune(function(e)
		return e.obj:get_pos() ~= nil
	end)
	registry.each(function(_, e)
		local obj = e.obj
		local max_hp = obj:get_properties().hp_max or 20
		local out = SL.advance(e.record, dt, rng, max_hp)
		if out.damage > 0 then
			damage_fn(obj, out.damage)
		end
		if out.cured then
			M.clear(obj)
		end
	end)
end

return M
