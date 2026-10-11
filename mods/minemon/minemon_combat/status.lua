-- Status effects on creatures and players (T-23, fixed in T-23b). Glue: the maths is in status_logic.lua.
-- One record per object in a bounded registry, keyed by the object's guid (player name for players).
-- A creature's status is mirrored to its instance (inst.status) and its walk and run speed. init.lua ticks this
-- from its single globalstep.
--
-- Reload (T-23b): the registry lives in memory, but inst.status and the walk and run speeds are saved with the
-- entity (mcl_mobs saves every non-function field). The original speeds are kept in _mm_base_walk and
-- _mm_base_run, so a speed is always restored from them. restore_on_activate() runs as the "status_restore"
-- brain: on the first tick of an activation it registers a status the instance still has.
-- luacheck: read_globals core minemon

local SL = dofile(core.get_modpath("minemon_combat") .. "/status_logic.lua")

local M = {}
local registry = SL.new_registry(SL.REGISTRY_CAP)
local activated = setmetatable({}, { __mode = "k" }) -- luaentity -> true once its first tick ran

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

-- Creature: instance status and walk and run speeds, from the saved base speeds. Player: paralysis halves the
-- physics speed.
local function set_mirror(obj, kind)
	local inst = minemon.creatures.get_instance(obj)
	local le = obj:get_luaentity()
	if inst and le then
		inst.status = kind
		if le._mm_base_walk == nil then
			le._mm_base_walk = le.walk_velocity or 0
		end
		if le._mm_base_run == nil then
			le._mm_base_run = le.run_velocity or 0
		end
		local m = SL.speed_mult(kind)
		le.walk_velocity = le._mm_base_walk * m
		le.run_velocity = le._mm_base_run * m
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

-- Registers a status again with a fresh duration (SL.restore_record) and re-applies its speed. An unknown kind, or a
-- full registry, clears the status instead. Returns true when the status was registered.
function M.restore(obj, kind)
	if not obj or not obj:get_pos() then
		return false
	end
	local key = key_of(obj)
	if registry.get(key) ~= nil then
		return false
	end
	if SL.is_minimal(kind) and registry.put(key, { obj = obj, record = SL.restore_record(kind) }) then
		set_mirror(obj, kind)
		return true
	end
	set_mirror(obj, "none")
	return false
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

-- The "status_restore" brain (T-23b). Runs on the first tick of each activation, because the luaentity table is new
-- on every activation. If the instance says a status that the registry does not hold, the status is restored; a
-- status the registry already holds is left alone. Entries for removed objects are pruned by tick(): a removed
-- entity has no speed left to restore, and the saved staticdata carries the status for the next activation.
function M.restore_on_activate(le)
	if activated[le] then
		return
	end
	activated[le] = true
	local inst = le._mm
	local obj = le.object
	if not inst or inst.status == nil or inst.status == "none" or not obj or not obj:get_pos() then
		return
	end
	if M.get(obj) == "none" then
		M.restore(obj, inst.status)
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
