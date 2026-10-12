-- minemon_fx (M2.1 art pass, D-032): effect recipes per move, creature art profiles, status visuals and the hit
-- feel. Glue only; the pure rules are in fx_logic.lua and the effect library in lib.lua. docs/ART_GUIDE.md is the
-- guide for adding recipes and art profiles.
--
-- Public API (minemon.fx):
--   play(phase, ctx) -> bool       run the recipe for ctx.move_id's phase; false when no recipe handles it
--   register_move(key, recipe)     key: a move id, "type:<type>" or "default"; recipe: {phase = fn(F, ctx), ...}
--   register_art(key, profile)     key: the species key ("charmander"); profile: see art/charmander.lua
--   register_status(kind, look)    the look of a primary status (recipes/status.lua)
--   anchor(obj, name)              world position of a locator ("mouth", "target", "middle", "head", "fire", ...)
--   lib                            the effect library F (lib.lua)
--
-- Phases (ctx fields): cast (user, target, time), launch (user, target, from, dir), projectile (obj, user; return
-- true when the recipe decorated the orb), beam (user, from, to), melee (user, target, centre, fwd), area (user,
-- centre, radius), aura (user, centre), cloud (centre, radius, time), impact (user, victim, pos, result). Every ctx
-- has move_id, move and type.
-- luacheck: read_globals core vector
-- luacheck: globals minemon

local MODPATH = core.get_modpath("minemon_fx")
local L = dofile(MODPATH .. "/fx_logic.lua")
local F = dofile(MODPATH .. "/lib.lua")

minemon.fx = minemon.fx or {}
local API = minemon.fx
API.lib = F
API.logic = L

local recipes = {}
local art = {}

-- ---------------------------------------------------------------- quality

local QUALITY_KEY = "minemon:fx:quality"
local server_quality = core.settings:get("minemon_fx_quality") or L.DEFAULT_QUALITY
if not L.valid_quality(server_quality) then
	server_quality = L.DEFAULT_QUALITY
end
local quality_cache = {}

F.quality_of = function(player)
	local name = player:get_player_name()
	local q = quality_cache[name]
	if q == nil then
		local stored = player:get_meta():get_string(QUALITY_KEY)
		q = L.quality_scale(L.valid_quality(stored) and stored or server_quality)
		quality_cache[name] = q
	end
	return q
end

core.register_on_leaveplayer(function(player)
	quality_cache[player:get_player_name()] = nil
end)

core.register_chatcommand("fx", {
	params = "<low|medium|high>",
	description = "Set your effect quality (particle counts). low suits weak GPUs.",
	func = function(name, param)
		local player = core.get_player_by_name(name)
		if not player then
			return false, "Not in game."
		end
		param = (param or ""):lower()
		if not L.valid_quality(param) then
			return false, "Usage: /fx <low|medium|high>"
		end
		player:get_meta():set_string(QUALITY_KEY, param)
		quality_cache[name] = nil
		return true, "Effect quality: " .. param
	end,
})

-- ---------------------------------------------------------------- recipes

function API.register_move(key, recipe)
	assert(type(key) == "string" and type(recipe) == "table", "minemon_fx: register_move(key, recipe)")
	recipes[key] = recipe
end

function API.recipe(key)
	return recipes[key]
end

function API.anchor(obj, name, frac, fwd)
	return F.anchor(obj, name, frac, fwd)
end

-- Runs one phase. A failing recipe is logged and reported as unhandled, so the old visuals still show.
function API.play(phase, ctx)
	if type(ctx) ~= "table" or type(ctx.move) ~= "table" then
		return false
	end
	ctx.type = ctx.type or ctx.move.type
	ctx.palette = ctx.palette or L.palette(ctx.type)
	local fn, key = L.find_phase(recipes, ctx.move_id, ctx.type, phase)
	if not fn then
		return false
	end
	local ok, res = pcall(fn, F, ctx)
	if not ok then
		core.log("error", string.format("[minemon_fx] %s.%s failed: %s", tostring(key), phase, tostring(res)))
		return false
	end
	if phase == "cast" and ctx.user then
		API.art_event(ctx.user, "cast", ctx)
	end
	if phase == "impact" then
		API.feel(ctx)
	end
	return res ~= false
end

-- The hit feel every damaging move gets after its own impact: a white catch light, a short hit stop on both
-- fighters and the floating damage number.
function API.feel(ctx)
	local res = ctx.result
	if not res or res.missed or not ctx.victim or not ctx.victim:get_pos() then
		return
	end
	local amount = ctx.dealt or res.amount or 0
	if amount <= 0 then
		return
	end
	local at = F.anchor(ctx.victim, "middle", 0.55) or ctx.pos
	F.flare({ pos = at, colour = "#ffffff", size = res.crit and 6 or 4, life = 0.12 })
	F.hitstop({ ctx.victim, ctx.user }, res.crit and 0.14 or 0.08)
	local top = F.anchor(ctx.victim, "head", 1.0) or at
	F.number(vector.add(top, { x = 0, y = 0.3, z = 0 }), amount, res.effectiveness, res.crit)
	if res.crit then
		F.sound("mcl_criticals_hit", { pos = at, gain = 0.6 })
	end
end

-- ---------------------------------------------------------------- creature art

local PART = "minemon_fx:part"
local parts = setmetatable({}, { __mode = "k" }) -- creature luaentity -> { objs = {...}, key = species key }

-- A glowing part riding on a bone (a tail flame, a spark): an animated sprite with its own particles. It removes
-- itself when its creature is gone and re-sends its particles every PART_REFRESH_S to the players near it, so
-- players who arrive later see them and nothing is sent to anyone far away.
local PART_REFRESH_S = 2.0

core.register_entity(PART, {
	initial_properties = {
		visual = "sprite",
		textures = { F.TEX.blank },
		physical = false,
		pointable = false,
		static_save = false,
		collisionbox = { 0, 0, 0, 0, 0, 0 },
		selectionbox = { 0, 0, 0, 0, 0, 0 },
		use_texture_alpha = true,
		glow = 14,
		shaded = false,
	},
	on_step = function(self, dtime)
		self._t = (self._t or PART_REFRESH_S) + dtime
		if self._t < PART_REFRESH_S then
			return
		end
		self._t = 0
		if not self.object:get_attach() then
			self.object:remove()
			return
		end
		if self._emit then
			local ok, err = pcall(self._emit, F, self.object, PART_REFRESH_S)
			if not ok then
				core.log("error", "[minemon_fx] part emitter failed: " .. tostring(err))
				self._emit = nil
			end
		end
	end,
})

local function clear_parts(le)
	local rec = parts[le]
	if rec then
		for _, obj in ipairs(rec.objs) do
			if obj:get_pos() then
				obj:remove()
			end
		end
	end
	parts[le] = nil
end

-- Builds the parts of a profile on a creature. A part: { bone = "locator_fire", offset = {x,y,z} (model units:
-- 10 = 1 node), sprite = {texture, frames, frame_s, size}, emit = fn(F, part_obj, seconds) }.
local function attach_parts(obj, le, key, profile)
	clear_parts(le)
	local rec = { objs = {}, key = key }
	for _, p in ipairs(profile.parts or {}) do
		local part = core.add_entity(obj:get_pos(), PART)
		if part then
			local sp = p.sprite or {}
			local size = sp.size or 0.4
			part:set_properties({
				textures = { sp.texture or F.TEX.blank },
				spritediv = { x = 1, y = sp.frames or 1 },
				visual_size = { x = size, y = size * (sp.aspect or 1) },
				glow = sp.glow or 14,
			})
			if (sp.frames or 1) > 1 then
				part:set_sprite({ x = 0, y = 0 }, sp.frames, sp.frame_s or 0.08, false)
			end
			part:set_attach(obj, p.bone or "", p.offset or { x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 0 }, true)
			local ple = part:get_luaentity()
			ple._emit = p.emit
			ple._base_size = size
			ple._aspect = sp.aspect or 1
			ple._name = p.name
			rec.objs[#rec.objs + 1] = part
		end
	end
	parts[le] = rec
end

-- The species key of a creature (its name in the species data, as minemon_creatures' defs.key_for).
local function species_key(obj)
	local inst = minemon.creatures and minemon.creatures.get_instance(obj)
	local sp = inst and minemon.data.get_species(inst.species_id)
	return sp and sp.name or nil, inst
end

function API.register_art(key, profile)
	assert(type(key) == "string" and type(profile) == "table", "minemon_fx: register_art(key, profile)")
	art[key] = profile
end

function API.art(key)
	return art[key]
end

-- Applies (or re-applies, after an evolution) the art profile of a creature. Called on minemon_creatures'
-- creature_visual event.
function API.apply_art(obj)
	local le = obj and obj:get_luaentity()
	if not le then
		return
	end
	local key, inst = species_key(obj)
	if API.eldritch and inst then
		API.eldritch.track(obj, minemon.data.get_species(inst.species_id))
	end
	local profile = key and art[key]
	if not profile then
		clear_parts(le)
		return
	end
	local rec = parts[le]
	if rec and rec.key == key then
		return
	end
	attach_parts(obj, le, key, profile)
end

-- An art event ("cast", ...): the profile's handler gets (F, creature, parts by name, ctx).
function API.art_event(obj, event, ctx)
	local le = obj and obj:get_luaentity()
	local rec = le and parts[le]
	local profile = rec and art[rec.key]
	local fn = profile and profile[event]
	if type(fn) ~= "function" then
		return
	end
	local by_name = {}
	for _, part in ipairs(rec.objs) do
		local ple = part:get_luaentity()
		if ple and ple._name then
			by_name[ple._name] = part
		end
	end
	local ok, err = pcall(fn, F, obj, by_name, ctx)
	if not ok then
		core.log("error", "[minemon_fx] art " .. rec.key .. "." .. event .. " failed: " .. tostring(err))
	end
end

-- Scales a part for t seconds (a flare-up), then back. Two property updates.
function API.pulse_part(part, factor, t)
	local ple = part and part:get_luaentity()
	if not ple then
		return
	end
	local s = ple._base_size * factor
	part:set_properties({ visual_size = { x = s, y = s * ple._aspect } })
	core.after(t, function()
		if part:get_pos() then
			part:set_properties({ visual_size = { x = ple._base_size, y = ple._base_size * ple._aspect } })
		end
	end)
end

if minemon.events then
	minemon.events.register("creature_visual", function(obj)
		API.apply_art(obj)
	end)
end

-- ---------------------------------------------------------------- status visuals

-- Every STATUS_S, each creature with a primary status near a player gets a short spawner of its status look
-- (STATUS_LOOK in recipes/status.lua). Short spawners need no cleanup and follow the creature (attached).
local STATUS_S = 1.0
local STATUS_RADIUS = 40
local STATUS_CAP = 24
API.status_looks = {}
local status_acc = 0

-- kind: a primary status ("burn", "poison", "paralysis", "sleep", "freeze"); look: fn(F, obj, seconds).
function API.register_status(kind, look)
	API.status_looks[kind] = look
end

core.register_globalstep(function(dtime)
	status_acc = status_acc + dtime
	if status_acc < STATUS_S then
		return
	end
	status_acc = 0
	if not (minemon.combat and minemon.combat.status_of) then
		return
	end
	local seen, count = {}, 0
	for _, player in ipairs(core.get_connected_players()) do
		local pp = player:get_pos()
		for _, obj in ipairs(pp and core.get_objects_inside_radius(pp, STATUS_RADIUS) or {}) do
			if count >= STATUS_CAP then
				return
			end
			local le = not obj:is_player() and obj:get_luaentity() or nil
			if le and le._mm and not seen[le] then
				seen[le] = true
				local kind = minemon.combat.status_of(obj)
				local look = API.status_looks[kind]
				if look then
					count = count + 1
					local ok, err = pcall(look, F, obj, STATUS_S)
					if not ok then
						core.log("error", "[minemon_fx] status look " .. kind .. " failed: " .. tostring(err))
					end
				end
			end
		end
	end
end)

-- ---------------------------------------------------------------- content

local function load_dir(sub)
	local dir = MODPATH .. "/" .. sub
	local files = core.get_dir_list(dir, false) or {}
	table.sort(files)
	for _, file in ipairs(files) do
		if file:sub(-4) == ".lua" then
			dofile(dir .. "/" .. file)
		end
	end
end

API.eldritch = dofile(MODPATH .. "/eldritch.lua")
load_dir("recipes")
load_dir("art")
