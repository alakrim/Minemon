-- minemon_fx: pure rules (no Luanti API; busted-tested in tests/unit/fx_logic_spec.lua). Quality scaling, the type
-- palettes, recipe lookup, anchor maths and the damage number text. See docs/ART_GUIDE.md.

local M = {}

-- Particle count multiplier per quality level. Every amount in a recipe is written for "high".
M.QUALITY = { low = 0.4, medium = 0.7, high = 1.0 }
M.DEFAULT_QUALITY = "high"

-- Hard cap on one spawner's particle count after scaling (a recipe bug must not flood a client).
M.MAX_AMOUNT = 120

-- Budget (docs/ART_GUIDE.md, "Performance budget"): the particles one effect phase may spawn at "high".
M.PHASE_BUDGET = { cast = 80, launch = 60, projectile = 90, impact = 160, beam = 160, melee = 90, area = 200,
	aura = 120, cloud = 160, status = 30 }

function M.quality_scale(level)
	return M.QUALITY[level] or M.QUALITY[M.DEFAULT_QUALITY]
end

function M.valid_quality(level)
	return M.QUALITY[level] ~= nil
end

-- The scaled particle count: at least 1 when the recipe asked for any, at most MAX_AMOUNT.
function M.amount(n, scale)
	n = tonumber(n) or 0
	if n <= 0 then
		return 0
	end
	return math.max(1, math.min(M.MAX_AMOUNT, math.floor(n * (scale or 1) + 0.5)))
end

-- Four tones per type, bright to dark: core (white-hot centre), main (the type's colour), edge (the cool rim) and
-- smoke (what the effect leaves behind). Neutral textures are multiplied by these ("^[multiply:").
M.PALETTE = {
	normal = { core = "#ffffff", main = "#e8e2c8", edge = "#a89c78", smoke = "#8a8270" },
	fire = { core = "#fff6c8", main = "#ff8a24", edge = "#d23a0c", smoke = "#3b2b25" },
	water = { core = "#e8fbff", main = "#4fb2ff", edge = "#1c5fd0", smoke = "#bfe6ff" },
	electric = { core = "#ffffff", main = "#ffe640", edge = "#ffb020", smoke = "#8a8aa0" },
	grass = { core = "#f0ffd0", main = "#6fe05a", edge = "#2f9a3a", smoke = "#5a7a40" },
	ice = { core = "#ffffff", main = "#a8f0ff", edge = "#5ab8f0", smoke = "#dff6ff" },
	fighting = { core = "#fff0e0", main = "#ff6a40", edge = "#b8301c", smoke = "#7a6050" },
	poison = { core = "#f6d8ff", main = "#c45ae6", edge = "#7a2aa8", smoke = "#5a3a6a" },
	ground = { core = "#fff2d0", main = "#e0b468", edge = "#9a6a30", smoke = "#8a7050" },
	flying = { core = "#ffffff", main = "#bcd8ff", edge = "#6a9ae8", smoke = "#d8e6f8" },
	psychic = { core = "#fff0fa", main = "#ff6ab4", edge = "#c02a8a", smoke = "#8a5a90" },
	bug = { core = "#f8ffd8", main = "#c4e040", edge = "#7a9a20", smoke = "#6a7040" },
	rock = { core = "#fff4dc", main = "#d0b070", edge = "#8a7040", smoke = "#7a6a58" },
	ghost = { core = "#f0e8ff", main = "#9a78e8", edge = "#4a2a9a", smoke = "#2a2040" },
	dragon = { core = "#f0ecff", main = "#8a6aff", edge = "#3a2ac0", smoke = "#40305a" },
	dark = { core = "#e8d8f0", main = "#7a5a8a", edge = "#2a1a30", smoke = "#141018" },
	steel = { core = "#ffffff", main = "#d8e4f4", edge = "#8898b0", smoke = "#9aa4b0" },
}

function M.palette(type_name)
	return M.PALETTE[type_name] or M.PALETTE.normal
end

-- Recipe lookup for one phase: the move's own recipe, then its type's, then the default. A recipe handles a phase
-- when it has a function under that name. Returns the function and the key it came from, or nil.
function M.find_phase(recipes, move_id, type_name, phase)
	local keys = { move_id, type_name and ("type:" .. type_name) or nil, "default" }
	for i = 1, 3 do
		local key = keys[i]
		local r = key and recipes[key]
		if r and type(r[phase]) == "function" then
			return r[phase], key
		end
	end
	return nil
end

-- A locator offset (entity space: +x right, +y up, +z forward, in nodes) turned by the entity's yaw and scaled.
-- Returns the world offset as plain numbers x, y, z (yaw 0 faces +z, as minemon_combat's G.forward).
function M.rotate_offset(lx, ly, lz, yaw, scale)
	local s = scale or 1
	local c, sn = math.cos(yaw), math.sin(yaw)
	return (lx * c - lz * sn) * s, ly * s, (lx * sn + lz * c) * s
end

-- The floating damage number: the text and colour (0xRRGGBB) and a size factor. Crits and super effective hits
-- read bigger.
M.NUMBER_COLOUR = { normal = 0xFFFFFF, super = 0xFFD040, weak = 0xA0A0A0, crit = 0xFF5030 }

function M.damage_text(amount, effectiveness, crit)
	local text = tostring(math.floor(amount))
	local colour, size = M.NUMBER_COLOUR.normal, 1.0
	if effectiveness ~= nil and effectiveness > 1 then
		colour, size = M.NUMBER_COLOUR.super, 1.3
	elseif effectiveness ~= nil and effectiveness < 1 then
		colour, size = M.NUMBER_COLOUR.weak, 0.85
	end
	if crit then
		text = text .. "!"
		colour, size = M.NUMBER_COLOUR.crit, size * 1.25
	end
	return text, colour, size
end

-- Creature size (M2.1, owner: "big ones must feel big without exaggerating"): the visual height in nodes for a
-- species' real height in metres. Small creatures read a little larger than life, big ones are compressed and capped.
-- Pidgey 0.3 m -> 0.63, Charmander 0.6 m -> 0.90, Charizard 1.7 m -> 1.66, Snorlax 2.1 m -> 1.9, Onix 8.8 m -> 3.2.
M.HEIGHT_CAP = 3.2

function M.visual_height(height_m)
	local h = 0.95 * (math.max(height_m or 0.5, 0.05) ^ 0.75) + 0.25
	return math.min(h, M.HEIGHT_CAP)
end

-- Eldritch presence (M2.1): big species carry an aura of dread. "Big" is bulk, not length: species of at least
-- ELDRITCH_WEIGHT_KG (Charizard, Snorlax, Machamp, Lapras...) or of the huge and colossal size classes (Onix,
-- Gyarados, Steelix, Arbok). Long and light creatures (Dratini, Ekans, Furret) stay out.
M.ELDRITCH_WEIGHT_KG = 80
M.ELDRITCH_CLASSES = { huge = true, colossal = true }
M.ELDRITCH_EXCLUDE = { seel = true } -- heavy but harmless-looking

function M.is_eldritch(species)
	if type(species) ~= "table" then
		return false
	end
	if M.ELDRITCH_EXCLUDE[species.name] then
		return false
	end
	return (species.weight_kg or 0) >= M.ELDRITCH_WEIGHT_KG or M.ELDRITCH_CLASSES[species.size_class] == true
end

-- The presence level a player feels at distance d from the nearest eldritch creature: 0 none, 1 uneasy, 2 dread.
M.PRESENCE_NEAR = 8
M.PRESENCE_FAR = 14

function M.presence_level(d)
	if d == nil or d > M.PRESENCE_FAR then
		return 0
	end
	return d > M.PRESENCE_NEAR and 1 or 2
end

-- A ColorSpec string from 0xRRGGBB.
function M.hex(colour)
	return string.format("#%06x", colour % 0x1000000)
end

return M
