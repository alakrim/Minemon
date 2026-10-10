-- minemon_combat: real-time creature moves (T-23, M1 contract). Glue only. The rules are pure and busted-tested:
-- moves_logic.lua (archetypes, validation), choose_logic.lua (move choice), status_logic.lua (status maths and the
-- bounded registry). This file builds the context G, the public API and the single globalstep. archetypes.lua has
-- the six archetypes, status.lua the status effects and vfx.lua the particles and HUD text.
-- luacheck: read_globals core vector mcl_util vl_projectile
-- luacheck: globals minemon

local MODPATH = core.get_modpath("minemon_combat")

local function load(name)
	return dofile(MODPATH .. "/" .. name .. ".lua")
end

local LOGIC = load("moves_logic")
local CHOOSE = load("choose_logic")
local SL = load("status_logic")
local VFX = load("vfx")
local STATUS = load("status")
local ARCH = load("archetypes")

minemon.combat = minemon.combat or {}
local API = minemon.combat

-- Seeded from the clock. The first Park-Miller draw of a small seed is near 0, so the seed is spread out.
local rng = minemon.rng.new(math.floor(core.get_us_time() % 2147483646) * 1000003 + 1)

local PLAYER_LEVEL = 20
local PLAYER_STATS = { hp = 100, atk = 60, def = 60, spa = 60, spd = 60, spe = 60 }
local PLAYER_HEIGHT = 1.7
local TICK_S = 0.5

local G = {
	rng = rng,
	formulas = minemon.formulas,
	logic = LOGIC,
	vfx = VFX,
	status = STATUS,
	type_mult = minemon.data.type_multiplier,
}

-- A creature's instance and luaentity, or nil for players and for anything that is not a creature.
local function creature_of(obj)
	if not obj or not obj:get_pos() or obj:is_player() then
		return nil, nil
	end
	local inst = minemon.creatures.get_instance(obj)
	if not inst then
		return nil, nil
	end
	return inst, obj:get_luaentity()
end

function G.guid(obj)
	return obj:get_guid()
end

function G.height(obj)
	if obj:is_player() then
		return PLAYER_HEIGHT
	end
	local cb = obj:get_properties().collisionbox
	return (cb and cb[5]) or 0.5
end

-- The point at 80% of the body height, where beams start and end.
function G.eye(obj)
	return vector.add(obj:get_pos(), vector.new(0, G.height(obj) * 0.8, 0))
end

-- Horizontal unit vector the object faces (yaw 0 faces +z, as in Luanti).
function G.forward(obj)
	local yaw = obj:get_yaw()
	return vector.new(-math.sin(yaw), 0, math.cos(yaw))
end

function G.types_of(obj)
	if obj:is_player() then
		return { "normal" }
	end
	local inst = creature_of(obj)
	local sp = inst and minemon.data.get_species(inst.species_id)
	return (sp and sp.types) or { "normal" }
end

-- The attacker or defender view of formulas.damage (see PLAN.md, minemon.formulas.damage).
function G.view_of(obj)
	if obj:is_player() then
		return { level = PLAYER_LEVEL, stats = PLAYER_STATS, types = { "normal" }, status = STATUS.get(obj),
			stages = {} }
	end
	local inst, le = creature_of(obj)
	if not inst then
		return nil
	end
	local sp = minemon.data.get_species(inst.species_id)
	if not sp then
		return nil
	end
	return {
		level = inst.level,
		stats = minemon.instance.stats(inst, sp),
		types = sp.types,
		status = STATUS.get(obj),
		stages = le._mm_stages or {},
	}
end

-- A creature that is alive, or a player with HP.
function G.is_combatant(obj)
	if not obj or not obj:get_pos() then
		return false
	end
	if obj:is_player() then
		return obj:get_hp() > 0
	end
	local inst, le = creature_of(obj)
	return inst ~= nil and le ~= nil and inst.hp > 0 and not le._removed
end

-- The user itself, and its owner's creatures and owner player. Wild creatures have no friends.
function G.is_friend(user, obj)
	if G.guid(obj) == G.guid(user) then
		return true
	end
	local ule = user:get_luaentity()
	local owner = ule and ule.owner
	if owner == nil or owner == "" then
		return false
	end
	if obj:is_player() then
		return obj:get_player_name() == owner
	end
	local ole = obj:get_luaentity()
	return ole ~= nil and ole.owner == owner
end

function G.roll(percent)
	return rng:float() * 100 < percent
end

function G.animate(obj, clip)
	local le = obj:get_luaentity()
	local a = le and le.animation
	if a and a[clip .. "_start"] then
		obj:set_animation({ x = a[clip .. "_start"], y = a[clip .. "_end"] }, 15, 0, false)
	end
end

-- Damage through minemon.creatures.damage (T-24) when it exists. Until then, mcl_util.deal_damage, which runs the
-- mob's own damage path, and the instance HP is synced to the entity health afterwards.
function G.apply_damage(victim, amount, user, info)
	amount = math.floor(amount)
	if amount <= 0 then
		return
	end
	STATUS.wake_on_damage(victim)
	if victim:is_player() then
		local p = LOGIC.player_damage(amount)
		if user then
			victim:punch(user, 1.0, { full_punch_interval = 1, damage_groups = { fleshy = p } })
		else
			mcl_util.deal_damage(victim, p, { type = "generic" })
		end
		return
	end
	if minemon.creatures.damage then
		minemon.creatures.damage(victim, amount, user, info)
		return
	end
	local reason = user and { type = "mob", source = user } or { type = "generic" }
	mcl_util.deal_damage(victim, amount, reason)
	local inst, le = creature_of(victim)
	if inst and le and type(le.health) == "number" then
		inst.hp = math.max(0, math.floor(le.health))
	end
end

function G.apply_stage(obj, stat, stages)
	local inst, le = creature_of(obj)
	if not inst then
		return false
	end
	le._mm_stages = le._mm_stages or {}
	le._mm_stages[stat] = LOGIC.clamp_stage((le._mm_stages[stat] or 0) + stages)
	return true
end

-- Effectiveness text for every player within FEEDBACK_RANGE_M of pos.
function G.feedback_near(pos, text, colour)
	if not pos then
		return
	end
	for _, player in ipairs(core.get_connected_players()) do
		local pp = player:get_pos()
		if pp and vector.distance(pp, pos) <= VFX.FEEDBACK_RANGE_M then
			VFX.feedback(player, text, colour)
		end
	end
end

ARCH.register_orb(G)

local function now()
	return core.get_gametime()
end

local function on_cooldown_le(le, move_id)
	local ready = le and le._mm_cooldown and le._mm_cooldown[move_id]
	return ready ~= nil and now() < ready
end

local function find_slot(inst, move_id)
	for _, slot in ipairs(inst.moves or {}) do
		if slot.id == move_id then
			return slot
		end
	end
	return nil
end

local function in_range(user, target, move)
	return vector.distance(user:get_pos(), target:get_pos()) <= move.range_m + LOGIC.RANGE_SLACK
end

local function is_owned(inst, le)
	return (inst.owner ~= nil and inst.owner ~= "") or (le.owner ~= nil and le.owner ~= "")
end

-- Runs when the cast time ends. The target is checked again: it must still exist and be in range.
local function finish_cast(user, target, move_id, move)
	if not user:get_pos() then
		return
	end
	local le = user:get_luaentity()
	if le then
		le._mm_cast = nil
	end
	if not creature_of(user) then
		return
	end
	local needs_target = LOGIC.needs_target(move.archetype)
	if needs_target then
		if not target or not target:get_pos() then
			return
		end
		if LOGIC.needs_range(move.archetype) and not in_range(user, target, move) then
			return
		end
	end
	ARCH.fire(G, move.archetype, user, target, move_id, move)
end

-- Public API (PLAN.md, minemon_combat). Returns true when the cast started, or false and a reason.
function API.use_move(user, target, move_id)
	local inst, le = creature_of(user)
	if not inst then
		return false, "user is not a creature"
	end
	local move = minemon.data.get_move(move_id)
	if not move then
		return false, "unknown move " .. tostring(move_id)
	end
	local slot = find_slot(inst, move_id)
	if not slot then
		return false, "move not in moveset"
	end
	local owned = is_owned(inst, le)
	if owned and (slot.pp or 0) <= 0 then
		return false, "no PP left"
	end
	if on_cooldown_le(le, move_id) then
		return false, "cooldown"
	end
	if le._mm_cast then
		return false, "busy"
	end
	if minemon.creatures.is_exhausted(user) then
		return false, "exhausted"
	end
	local status = STATUS.get(user)
	if SL.blocks_moves(status) then
		return false, status == "sleep" and "asleep" or "frozen"
	end
	if status == "paralysis" and SL.paralysis_fails(rng) then
		return false, "paralysed"
	end
	local needs_target = LOGIC.needs_target(move.archetype)
	if needs_target then
		if not target or not target:get_pos() or G.guid(target) == G.guid(user) then
			return false, "no target"
		end
		if LOGIC.needs_range(move.archetype) and not in_range(user, target, move) then
			return false, "out of range"
		end
	end
	if owned then
		slot.pp = slot.pp - 1
	end
	le._mm_cooldown = le._mm_cooldown or {}
	le._mm_cooldown[move_id] = now() + move.cooldown_s
	le._mm_cast = move_id
	VFX.windup(G.eye(user), move.type, move.cast_s)
	core.after(move.cast_s, function()
		finish_cast(user, target, move_id, move)
	end)
	return true
end

-- The best move the creature can use now against target (nil target: the user's own view). Returns a move id or nil.
function API.choose_move(user, target)
	local inst, le = creature_of(user)
	if not inst then
		return nil
	end
	local owned = is_owned(inst, le)
	local candidates = {}
	for _, slot in ipairs(inst.moves or {}) do
		local move = minemon.data.get_move(slot.id)
		if move then
			candidates[#candidates + 1] = {
				id = slot.id,
				pp = owned and slot.pp or nil,
				move = move,
				on_cooldown = on_cooldown_le(le, slot.id),
			}
		end
	end
	local sp = minemon.data.get_species(inst.species_id)
	local ctx = {
		user_types = (sp and sp.types) or {},
		target_types = (target and target:get_pos()) and G.types_of(target) or { "normal" },
		target_status = (target and target:get_pos()) and STATUS.get(target) or "none",
		type_mult = G.type_mult,
	}
	return CHOOSE.choose(candidates, ctx, rng)
end

function API.on_cooldown(user, move_id)
	local _, le = creature_of(user)
	return on_cooldown_le(le, move_id)
end

-- Clears stages, cooldowns, the cast and the status. For recall (T-22).
function API.reset(obj)
	local inst, le = creature_of(obj)
	if not inst then
		return false
	end
	le._mm_stages = {}
	le._mm_cooldown = {}
	le._mm_cast = nil
	STATUS.clear(obj)
	return true
end

-- One globalstep: status ticks and cloud checks every 0.5 s (PLAN.md performance rules).
local tick_acc = 0
core.register_globalstep(function(dtime)
	tick_acc = tick_acc + dtime
	if tick_acc < TICK_S then
		return
	end
	local dt = tick_acc
	tick_acc = 0
	STATUS.tick(dt, rng, G.apply_damage)
	ARCH.tick_clouds(G, dt)
end)
