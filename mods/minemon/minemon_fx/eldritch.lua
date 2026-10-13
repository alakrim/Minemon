-- Eldritch presence (M2.1, owner directive): big creatures (fx_logic.is_eldritch) feel imposing without being huge.
--   * an aura: void smoke that darkens what is behind it (subtractive blend), slow motes drifting around the body;
--   * at night, eyes that glow (on the model's eye locators);
--   * for players nearby, the world loses colour and light (set_lighting), in two steps, and comes back when they
--     leave. VoxeLibre sets its lighting once at join; the fields changed here are restored from get_lighting().
-- Cost: every AURA_S, one or two short attached spawners per eldritch creature near a player; one set_lighting per
-- player when the presence level changes.
-- luacheck: read_globals core vector minemon

local F = minemon.fx.lib
local L = minemon.fx.logic

local AURA_S = 2.0
local PRESENCE_S = 0.5
local RANGE = 48
local auras = setmetatable({}, { __mode = "k" }) -- luaentity -> species

local M = {}

function M.track(obj, species)
	local le = obj and obj:get_luaentity()
	if not le then
		return
	end
	auras[le] = L.is_eldritch(species) and species or nil
end

local function body(obj)
	local cb = obj:get_properties().collisionbox or { -0.5, 0, -0.5, 0.5, 1, 0.5 }
	return (cb[4] - cb[1]) / 2, cb[5] - cb[2], cb[2]
end

-- Night and dusk: the eyes glow from dusk on (the world is already dark enough then to read them).
local function is_night()
	local t = core.get_timeofday()
	return t < 0.25 or t > 0.75
end

local function emit_aura(obj, s)
	local hw, h, y0 = body(obj)
	-- Void smoke: dark wisps that subtract light, rising slowly off the body.
	F.on(obj, {
		amount = math.floor(9 * s), time = s,
		pos = { min = { x = -hw, y = y0 + h * 0.2, z = -hw }, max = { x = hw, y = y0 + h * 0.9, z = hw } },
		vel = { min = { x = -0.1, y = 0.15, z = -0.1 }, max = { x = 0.1, y = 0.4, z = 0.1 } },
		drag = { x = 0.3, y = 0, z = 0.3 },
		exptime = { min = 1.4, max = 2.2 }, size = { min = 0.5 * hw + 0.3, max = 0.9 * hw + 0.5 },
		texture = F.tex(F.tint(F.TEX.smoke, "#2c2236"), { blend = "sub", anim = "smoke", alpha = 0.7,
			fade = { 0.0, 0.7 } }),
	})
	-- Motes: a few violet sparks drifting around, close to the body.
	F.on(obj, {
		amount = math.floor(4 * s), time = s,
		pos = { min = { x = -hw * 1.3, y = y0, z = -hw * 1.3 }, max = { x = hw * 1.3, y = y0 + h, z = hw * 1.3 } },
		vel = { min = { x = -0.05, y = 0.05, z = -0.05 }, max = { x = 0.05, y = 0.25, z = 0.05 } },
		jitter = { min = { x = -0.4, y = -0.1, z = -0.4 }, max = { x = 0.4, y = 0.1, z = 0.4 } },
		exptime = { min = 1.5, max = 2.5 }, size = { min = 0.05, max = 0.1 },
		texture = F.tex(F.tint(F.TEX.mote, "#b070ff"), { blend = "add", fade = { 0, 1 } }), glow = 14,
	})
	-- Eyes that glow in the dark.
	if is_night() then
		local loc = F.locators(obj)
		local scale = (obj:get_properties().visual_size or {}).x or 1
		for _, key in ipairs({ "eye_left", "eye_right" }) do
			local e = loc and loc[key]
			if e then
				-- A hot core that flickers, a red bloom round it, and now and then a spark that drifts off.
				local at = { x = e[1] * scale, y = e[2] * scale, z = e[3] * scale + 0.03 }
				F.on(obj, {
					amount = math.floor(12 * s), time = s, pos = at,
					vel = { x = 0, y = 0, z = 0 }, exptime = { min = 0.15, max = 0.25 },
					size = { min = 0.16 + 0.06 * scale, max = 0.2 + 0.08 * scale },
					texture = F.tex(F.tint(F.TEX.glow, "#ffb0a0"), { blend = "add" }), glow = 14,
				})
				F.on(obj, {
					amount = math.floor(3 * s), time = s, pos = at,
					vel = { x = 0, y = 0, z = 0 }, exptime = { min = 0.6, max = 0.8 },
					size = { min = 0.5 + 0.2 * scale, max = 0.6 + 0.25 * scale },
					texture = F.tex(F.tint(F.TEX.glow, "#ff2a1a"), { blend = "add", alpha = 0.55 }), glow = 14,
				})
				F.on(obj, {
					amount = math.max(1, math.floor(1 * s)), time = s, pos = at,
					vel = { min = { x = -0.1, y = 0.1, z = -0.1 }, max = { x = 0.1, y = 0.3, z = 0.1 } },
					exptime = { min = 0.6, max = 1.0 }, size = { min = 0.04, max = 0.07 },
					texture = F.tex(F.tint(F.TEX.ember, "#ff4030"), { blend = "add", fade = true }), glow = 14,
				})
			end
		end
	end
end

local aura_acc = 0
local presence_acc = 0
local presence = {} -- player name -> { level = n, base = { saturation, exposure_correction, intensity } }

-- How much light the presence takes (exposure correction) per level; less at night, when the world is already
-- dark and the creature must still read (M2.1 review: night shots were black).
local DARK_DAY = { 0.0, 0.2, 0.38 }
local DARK_NIGHT = { 0.0, 0.05, 0.1 }

local function apply_presence(player, level)
	local name = player:get_player_name()
	local rec = presence[name]
	if not rec then
		local cur = player:get_lighting() or {}
		rec = { level = 0, base = {
			saturation = cur.saturation or 1.0,
			exposure = (cur.exposure and cur.exposure.exposure_correction) or 0.0,
			shadows = (cur.shadows and cur.shadows.intensity) or 0.33,
		} }
		presence[name] = rec
	end
	local night = is_night()
	if rec.level == level and rec.night == night then
		return
	end
	rec.level = level
	rec.night = night
	local b = rec.base
	local sat = ({ 1.0, 0.72, 0.45 })[level + 1]
	local dark = (night and DARK_NIGHT or DARK_DAY)[level + 1]
	player:set_lighting({
		saturation = b.saturation * sat,
		exposure = { exposure_correction = b.exposure - dark },
		shadows = { intensity = math.min(1, b.shadows + 0.15 * level),
			tint = level > 0 and { r = 40, g = 10, b = 60 } or { r = 0, g = 0, b = 0 } },
	})
end

core.register_on_leaveplayer(function(player)
	presence[player:get_player_name()] = nil
end)

core.register_globalstep(function(dtime)
	aura_acc = aura_acc + dtime
	presence_acc = presence_acc + dtime
	if aura_acc >= AURA_S then
		aura_acc = 0
		for le in pairs(auras) do
			local obj = le.object
			local p = obj and obj:get_pos()
			if p and #F.viewers(p, RANGE) > 0 then
				local ok, err = pcall(emit_aura, obj, AURA_S)
				if not ok then
					core.log("error", "[minemon_fx] eldritch aura failed: " .. tostring(err))
				end
			elseif not p then
				auras[le] = nil
			end
		end
	end
	if presence_acc >= PRESENCE_S then
		presence_acc = 0
		for _, player in ipairs(core.get_connected_players()) do
			local pp = player:get_pos()
			local best
			for le in pairs(auras) do
				local p = le.object and le.object:get_pos()
				if p and pp then
					local d = vector.distance(p, pp)
					if not best or d < best then
						best = d
					end
				end
			end
			apply_presence(player, L.presence_level(best))
		end
	end
end)

return M
