-- Tuning (D-033): the live game knobs the admin panel changes. Pure logic, no Luanti API, so busted can test it.
-- Every knob has a default that leaves the game exactly as designed. Mods read a knob with get(key) at the moment
-- they need it (never cache it), so a change in the panel takes effect at once.

local M = {}

-- kind "number": min, max, step; kind "bool"; kind "choice": options. label is the panel text.
M.DEFS = {
	catch_mult = { kind = "number", default = 1, min = 0.1, max = 10, step = 0.1, label = "Catch chance ×" },
	catch_mode = { kind = "choice", default = "normal", options = { "normal", "always", "never" },
		label = "Catch mode" },
	spawn_enabled = { kind = "bool", default = true, label = "Wild spawns on" },
	spawn_cap_mult = { kind = "number", default = 1, min = 0, max = 4, step = 0.25, label = "Wild crowd ×" },
	level_offset = { kind = "number", default = 0, min = -50, max = 50, step = 1, label = "Wild level ±" },
	dread_mult = { kind = "number", default = 1, min = 0, max = 20, step = 0.5, label = "Dread chance ×" },
	shiny_mult = { kind = "number", default = 1, min = 0, max = 512, step = 1, label = "Shiny chance ×" },
	exp_mult = { kind = "number", default = 1, min = 0, max = 10, step = 0.25, label = "Exp ×" },
}

-- The keys in panel order.
M.ORDER = { "catch_mode", "catch_mult", "spawn_enabled", "spawn_cap_mult", "level_offset", "dread_mult",
	"shiny_mult", "exp_mult" }

-- The value a raw input becomes for a key, or nil when the key is unknown or the input cannot be read.
-- Numbers are clamped and snapped to the step; "true"/"false" strings are read for bools.
function M.coerce(key, raw)
	local def = M.DEFS[key]
	if def == nil then
		return nil
	end
	if def.kind == "number" then
		local n = tonumber(raw)
		if n == nil or n ~= n then
			return nil
		end
		n = math.max(def.min, math.min(def.max, n))
		n = math.floor(n / def.step + 0.5) * def.step
		return math.max(def.min, math.min(def.max, n))
	elseif def.kind == "bool" then
		if raw == true or raw == "true" then
			return true
		elseif raw == false or raw == "false" then
			return false
		end
		return nil
	end
	for _, opt in ipairs(def.options) do
		if raw == opt then
			return opt
		end
	end
	return nil
end

-- A store over a table of saved values. save(values) is called after every change (the glue persists it).
function M.create(saved, save)
	local values = {}
	for key, raw in pairs(type(saved) == "table" and saved or {}) do
		local v = M.coerce(key, raw)
		if v ~= nil then
			values[key] = v
		end
	end
	local S = { DEFS = M.DEFS, ORDER = M.ORDER }

	function S.get(key)
		local v = values[key]
		if v ~= nil then
			return v
		end
		local def = M.DEFS[key]
		return def and def.default
	end

	-- Returns the stored value, or nil and a reason.
	function S.set(key, raw)
		local v = M.coerce(key, raw)
		if v == nil then
			return nil, "bad value for " .. tostring(key)
		end
		if v == M.DEFS[key].default then
			values[key] = nil
		else
			values[key] = v
		end
		if save then
			save(values)
		end
		return v
	end

	function S.reset()
		values = {}
		if save then
			save(values)
		end
	end

	-- True when every knob is at its default.
	function S.is_default()
		return next(values) == nil
	end

	return S
end

-- Helpers the hooks use, so each mod applies a knob the same way.

-- A catch probability after the catch knobs: "always" is 1, "never" is 0, else p × catch_mult capped at 1.
function M.apply_catch(p, mode, mult)
	if mode == "always" then
		return 1
	elseif mode == "never" then
		return 0
	end
	return math.max(0, math.min(1, p * mult))
end

-- A wild level after the offset, within 1..100.
function M.apply_level(level, offset)
	return math.max(1, math.min(100, level + offset))
end

-- A chance after a multiplier, within 0..1.
function M.apply_chance(p, mult)
	return math.max(0, math.min(1, p * mult))
end

return M
