-- The owned brain (T-22, D-027): what a creature that belongs to a player does. Registered as "owned" in
-- minemon_creatures. It returns "skip_states" for owned creatures, so mcl_mobs' wander and melee do not run: this
-- brain moves the creature itself (go_to_pos, teleport) and fights with the move system (minemon_combat).
-- The distances and the target rule are in party_logic.lua. Wild creatures, and owned creatures the party did not send
-- out, are not touched (it returns nil).
-- Loaded as dofile(...)(S): S is the party state of init.lua. Returns the brain function.
-- luacheck: read_globals core minemon mcl_util vector

local MODPATH = core.get_modpath("minemon_party")
local LOGIC = dofile(MODPATH .. "/party_logic.lua")

-- The nearest wild creature within ASSIST_RANGE that attacks the owner or this creature, or nil.
local function find_assist(self, owner, pos)
	local own_guid = self.object:get_guid()
	local owner_guid = owner:get_guid()
	local best, best_d = nil, nil
	for _, o in ipairs(core.get_objects_inside_radius(pos, LOGIC.ASSIST_RANGE)) do
		if not o:is_player() and o:get_guid() ~= own_guid and minemon.creatures.get_instance(o) ~= nil
			and not minemon.creatures.is_owned(o) and not minemon.creatures.is_exhausted(o) then
			local le = o:get_luaentity()
			local att = le and le.attack
			if type(att) == "userdata" then
				local g = att:get_guid()
				if g == owner_guid or g == own_guid then
					local opos = o:get_pos()
					local d = vector.distance(pos, opos)
					if best == nil or d < best_d then
						best, best_d = o, d
					end
				end
			end
		end
	end
	return best
end

-- The ordered target if it still counts: it exists, is not exhausted and is within TARGET_RANGE. Returns the target,
-- its position and the distance; or nil. An exhausted target is cleared and the owner is told.
local function ordered_target(S, rec, pos)
	local t = rec.target
	if t == nil then
		return nil
	end
	if not t:is_valid() or t:get_pos() == nil then
		rec.target = nil
		return nil
	end
	if minemon.creatures.is_exhausted(t) then
		rec.target = nil
		local m = minemon.creatures.get_instance(t)
		S.say(rec.name, S.member_display(m or { species_id = 0, nickname = "" }) .. " is exhausted! (capture comes soon)")
		return nil
	end
	local tpos = t:get_pos()
	local d = vector.distance(pos, tpos)
	if not LOGIC.target_valid(true, false, d) then
		rec.target = nil
		return nil
	end
	return t, tpos, d
end

-- Attacks target: mcl's attack state (do_attack), then the move system. The move is used when the target is within
-- its range; otherwise the creature walks toward the target.
local function fight(self, target, tpos, d)
	local cur = self.attack
	if self.state ~= "attack" or type(cur) ~= "userdata" or cur:get_guid() ~= target:get_guid() then
		self.attack = nil
		self.state = "stand"
		self:do_attack(target)
	end
	local move_id = minemon.combat.choose_move(self.object, target)
	local move = move_id and minemon.data.get_move(move_id)
	local reach = move and move.range_m or 3
	if move_id and d <= reach then
		self:set_velocity(0)
		self:set_animation("stand")
		minemon.combat.use_move(self.object, target, move_id)
	elseif d > reach then
		self:go_to_pos(tpos, self.run_velocity)
	else
		self:set_velocity(0)
		self:set_animation("stand")
	end
end

-- Follows the owner: walk beyond FOLLOW_START, stand within FOLLOW_STOP.
local function follow(self, rec, opos, dist)
	local action = LOGIC.follow_action(dist, rec.walking)
	if action == "walk" then
		rec.walking = true
		local speed = dist > LOGIC.FAST_FOLLOW_DIST and self.run_velocity or self.walk_velocity
		self:go_to_pos(opos, speed)
	else
		rec.walking = false
		self:set_velocity(0)
		self:set_animation("stand")
	end
end

-- One brain step (every BRAIN_S seconds). The order: offline owner, teleport, the ordered target, the nearest
-- assisting wild creature, follow.
local function step(self, S, rec)
	local owner = rec.player
	if owner == nil or not owner:is_valid() then
		S.recall(rec.name, true)
		return
	end
	local opos = owner:get_pos()
	local pos = self.object:get_pos()
	if opos == nil or pos == nil then
		return
	end
	local dist = vector.distance(pos, opos)
	if LOGIC.needs_teleport(dist) then
		self.object:set_pos(LOGIC.behind(opos, owner:get_look_dir()))
		self:set_velocity(0)
		rec.walking = false
		return
	end
	local target, tpos, d = ordered_target(S, rec, pos)
	if target == nil then
		if self.state == "attack" then
			self.state = "stand"
			self.attack = nil
		end
		local assist = find_assist(self, owner, pos)
		if assist ~= nil then
			local apos = assist:get_pos()
			fight(self, assist, apos, vector.distance(pos, apos))
			return
		end
		follow(self, rec, opos, dist)
		return
	end
	fight(self, target, tpos, d)
end

-- Only creatures the party manages are this brain's (D-028): the ones sent out by the party (_mm_party). After a
-- restart the flag is gone, so an owned creature whose uid is in its owner's party list (owner online) is adopted;
-- the rest are left alone (returns false).
local function managed(S, self)
	if self._mm_party then
		return true
	end
	local p = core.get_player_by_name(self.owner or "")
	if p ~= nil and self._mm ~= nil and LOGIC.index_of(S.list(p), self._mm.uid) ~= nil then
		self._mm_party = true
		return true
	end
	return false
end

return function(S)
	return function(self, dtime)
		if not minemon.creatures.is_owned(self.object) then
			return nil
		end
		if not managed(S, self) then
			return nil
		end
		if self._party_fainted then
			return "skip_states" -- removed on the next step (init.lua S.on_fainted)
		end
		local rec = S.active_rec(self.owner or "")
		-- No active record for this entity (a restart, or a stale entity): it is removed.
		if rec == nil or rec.guid ~= self.object:get_guid() then
			S.orphan(self)
			return "skip_states"
		end
		self._party_acc = (self._party_acc or 0) + dtime
		if self._party_acc < LOGIC.BRAIN_S then
			return "skip_states"
		end
		self._party_acc = 0
		step(self, S, rec)
		return "skip_states"
	end
end
