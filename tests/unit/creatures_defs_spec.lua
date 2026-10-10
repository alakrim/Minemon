-- Unit tests for mods/minemon/minemon_creatures/defs.lua (pure logic, no Luanti).
-- Species records are copied from mods/minemon/minemon_core/data/species.json (only the fields defs.lua reads).
-- luacheck: globals describe it assert

local here = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$") or "."
local D = dofile(here .. "/../../mods/minemon/minemon_creatures/defs.lua")

local SPECIES = {
	{ id = 1, name = "bulbasaur", types = { "grass", "poison" }, body_plan = "quadruped",
		size_class = "small", temperament = "peaceful", eldritch = false, catch_rate = 45,
		habitats = { "plains", "swamp" }, evolutions = { { to = 2 } },
		base_stats = { hp = 45, atk = 49, def = 49, spa = 65, spd = 65, spe = 45 } },
	{ id = 2, name = "ivysaur", types = { "grass", "poison" }, body_plan = "quadruped",
		size_class = "medium", temperament = "peaceful", eldritch = false, catch_rate = 45,
		habitats = { "plains", "swamp" }, evolutions = { { to = 3 } },
		base_stats = { hp = 60, atk = 62, def = 63, spa = 80, spd = 80, spe = 60 } },
	{ id = 3, name = "venusaur", types = { "grass", "poison" }, body_plan = "quadruped",
		size_class = "large", temperament = "peaceful", eldritch = false, catch_rate = 45,
		habitats = { "plains", "swamp" }, evolutions = {},
		base_stats = { hp = 80, atk = 82, def = 83, spa = 100, spd = 100, spe = 80 } },
	{ id = 4, name = "charmander", types = { "fire" }, body_plan = "biped",
		size_class = "small", temperament = "skittish", eldritch = false, catch_rate = 45,
		habitats = { "mountain" }, evolutions = { { to = 5 } },
		base_stats = { hp = 39, atk = 52, def = 43, spa = 60, spd = 50, spe = 65 } },
	{ id = 7, name = "squirtle", types = { "water" }, body_plan = "biped",
		size_class = "small", temperament = "skittish", eldritch = false, catch_rate = 45,
		habitats = { "beach", "water" }, evolutions = { { to = 8 } },
		base_stats = { hp = 44, atk = 48, def = 65, spa = 50, spd = 64, spe = 43 } },
	{ id = 16, name = "pidgey", types = { "normal", "flying" }, body_plan = "avian",
		size_class = "tiny", temperament = "skittish", eldritch = false, catch_rate = 255,
		habitats = { "forest" }, evolutions = { { to = 17 } },
		base_stats = { hp = 40, atk = 45, def = 40, spa = 35, spd = 35, spe = 56 } },
	{ id = 17, name = "pidgeotto", types = { "normal", "flying" }, body_plan = "avian",
		size_class = "medium", temperament = "territorial", eldritch = false, catch_rate = 120,
		habitats = { "forest" }, evolutions = { { to = 18 } },
		base_stats = { hp = 63, atk = 60, def = 55, spa = 50, spd = 50, spe = 71 } },
	{ id = 18, name = "pidgeot", types = { "normal", "flying" }, body_plan = "avian",
		size_class = "medium", temperament = "skittish", eldritch = false, catch_rate = 45,
		habitats = { "forest" }, evolutions = {},
		base_stats = { hp = 83, atk = 80, def = 75, spa = 70, spd = 70, spe = 101 } },
	{ id = 19, name = "rattata", types = { "normal" }, body_plan = "quadruped",
		size_class = "tiny", temperament = "aggressive", eldritch = false, catch_rate = 255,
		habitats = { "plains" }, evolutions = { { to = 20 } },
		base_stats = { hp = 30, atk = 56, def = 35, spa = 25, spd = 35, spe = 72 } },
	{ id = 25, name = "pikachu", types = { "electric" }, body_plan = "quadruped",
		size_class = "small", temperament = "peaceful", eldritch = false, catch_rate = 190,
		habitats = { "forest" }, evolutions = { { to = 26 } },
		base_stats = { hp = 35, atk = 55, def = 40, spa = 50, spd = 50, spe = 90 } },
	{ id = 26, name = "raichu", types = { "electric" }, body_plan = "biped",
		size_class = "small", temperament = "aggressive", eldritch = false, catch_rate = 75,
		habitats = { "forest" }, evolutions = {},
		base_stats = { hp = 60, atk = 90, def = 55, spa = 90, spd = 80, spe = 110 } },
	{ id = 95, name = "onix", types = { "rock", "ground" }, body_plan = "serpent",
		size_class = "colossal", temperament = "peaceful", eldritch = true, catch_rate = 45,
		habitats = { "cave", "desert" }, evolutions = { { to = 208 } },
		base_stats = { hp = 35, atk = 45, def = 160, spa = 30, spd = 45, spe = 70 } },
	{ id = 122, name = "mr_mime", types = { "psychic" }, body_plan = "biped",
		size_class = "medium", temperament = "aggressive", eldritch = false, catch_rate = 45,
		habitats = { "urban" }, evolutions = {},
		base_stats = { hp = 40, atk = 45, def = 65, spa = 100, spd = 120, spe = 90 } },
	{ id = 129, name = "magikarp", types = { "water" }, body_plan = "fish",
		size_class = "medium", temperament = "skittish", eldritch = false, catch_rate = 255,
		habitats = { "beach", "water" }, evolutions = { { to = 130 } },
		base_stats = { hp = 20, atk = 10, def = 55, spa = 15, spd = 20, spe = 80 } },
	{ id = 130, name = "gyarados", types = { "water", "flying" }, body_plan = "serpent",
		size_class = "colossal", temperament = "aggressive", eldritch = true, catch_rate = 45,
		habitats = { "beach", "water" }, evolutions = {},
		base_stats = { hp = 95, atk = 125, def = 79, spa = 60, spd = 100, spe = 81 } },
	{ id = 133, name = "eevee", types = { "normal" }, body_plan = "quadruped",
		size_class = "tiny", temperament = "skittish", eldritch = false, catch_rate = 45,
		habitats = { "urban" }, evolutions = { { to = 134 }, { to = 135 }, { to = 136 }, { to = 196 }, { to = 197 } },
		base_stats = { hp = 55, atk = 55, def = 50, spa = 45, spd = 65, spe = 55 } },
	{ id = 134, name = "vaporeon", types = { "water" }, body_plan = "quadruped",
		size_class = "medium", temperament = "territorial", eldritch = false, catch_rate = 45,
		habitats = { "urban", "water" }, evolutions = {},
		base_stats = { hp = 130, atk = 65, def = 60, spa = 110, spd = 95, spe = 65 } },
	{ id = 144, name = "articuno", types = { "ice", "flying" }, body_plan = "avian",
		size_class = "large", temperament = "territorial", eldritch = false, catch_rate = 3,
		habitats = { "rare", "snow" }, evolutions = {},
		base_stats = { hp = 90, atk = 85, def = 100, spa = 95, spd = 125, spe = 85 } },
	{ id = 145, name = "zapdos", types = { "electric", "flying" }, body_plan = "avian",
		size_class = "large", temperament = "aggressive", eldritch = false, catch_rate = 3,
		habitats = { "rare" }, evolutions = {},
		base_stats = { hp = 90, atk = 90, def = 85, spa = 125, spd = 90, spe = 100 } },
	{ id = 150, name = "mewtwo", types = { "psychic" }, body_plan = "biped",
		size_class = "large", temperament = "aggressive", eldritch = true, catch_rate = 3,
		habitats = { "rare" }, evolutions = {},
		base_stats = { hp = 106, atk = 110, def = 90, spa = 154, spd = 90, spe = 130 } },
	{ id = 151, name = "mew", types = { "psychic" }, body_plan = "biped",
		size_class = "small", temperament = "territorial", eldritch = false, catch_rate = 45,
		habitats = { "rare" }, evolutions = {},
		base_stats = { hp = 100, atk = 100, def = 100, spa = 100, spd = 100, spe = 100 } },
	{ id = 152, name = "chikorita", types = { "grass" }, body_plan = "quadruped",
		size_class = "medium", temperament = "peaceful", eldritch = false, catch_rate = 45,
		habitats = { "plains" }, evolutions = { { to = 153 } },
		base_stats = { hp = 45, atk = 49, def = 65, spa = 49, spd = 65, spe = 45 } },
	{ id = 155, name = "cyndaquil", types = { "fire" }, body_plan = "biped",
		size_class = "small", temperament = "skittish", eldritch = false, catch_rate = 45,
		habitats = { "plains" }, evolutions = { { to = 156 } },
		base_stats = { hp = 39, atk = 52, def = 43, spa = 60, spd = 50, spe = 65 } },
	{ id = 158, name = "totodile", types = { "water" }, body_plan = "biped",
		size_class = "small", temperament = "skittish", eldritch = false, catch_rate = 45,
		habitats = { "beach", "water" }, evolutions = { { to = 159 } },
		base_stats = { hp = 50, atk = 65, def = 64, spa = 44, spd = 48, spe = 43 } },
	{ id = 172, name = "pichu", types = { "electric" }, body_plan = "quadruped",
		size_class = "tiny", temperament = "territorial", eldritch = false, catch_rate = 190,
		habitats = { "forest" }, evolutions = { { to = 25 } },
		base_stats = { hp = 20, atk = 40, def = 15, spa = 35, spd = 35, spe = 60 } },
	{ id = 201, name = "unown", types = { "psychic" }, body_plan = "other",
		size_class = "small", temperament = "territorial", eldritch = true, catch_rate = 225,
		habitats = { "rare" }, evolutions = {},
		base_stats = { hp = 48, atk = 72, def = 48, spa = 72, spd = 48, spe = 48 } },
	{ id = 245, name = "suicune", types = { "water" }, body_plan = "quadruped",
		size_class = "large", temperament = "territorial", eldritch = false, catch_rate = 3,
		habitats = { "plains", "water" }, evolutions = {},
		base_stats = { hp = 100, atk = 75, def = 115, spa = 90, spd = 115, spe = 85 } },
	{ id = 249, name = "lugia", types = { "psychic", "flying" }, body_plan = "avian",
		size_class = "huge", temperament = "territorial", eldritch = true, catch_rate = 3,
		habitats = { "rare" }, evolutions = {},
		base_stats = { hp = 106, atk = 90, def = 130, spa = 90, spd = 154, spe = 110 } },
	{ id = 250, name = "ho_oh", types = { "fire", "flying" }, body_plan = "avian",
		size_class = "huge", temperament = "aggressive", eldritch = true, catch_rate = 3,
		habitats = { "rare" }, evolutions = {},
		base_stats = { hp = 106, atk = 130, def = 90, spa = 110, spd = 154, spe = 90 } },
	{ id = 251, name = "celebi", types = { "psychic", "grass" }, body_plan = "biped",
		size_class = "small", temperament = "territorial", eldritch = false, catch_rate = 45,
		habitats = { "forest" }, evolutions = {},
		base_stats = { hp = 100, atk = 100, def = 100, spa = 100, spd = 100, spe = 100 } },
}

local function by_id(id)
	for _, sp in ipairs(SPECIES) do
		if sp.id == id then
			return sp
		end
	end
	error("no fixture species " .. id)
end

local function close(a, b)
	return math.abs(a - b) < 1e-6
end

describe("creatures_defs key and names", function()
	it("key_for lowercases and turns non-alphanumerics into underscores", function()
		assert.equals("mr_mime", D.key_for("Mr. Mime"))
		assert.equals("mr_mime", D.key_for("mr_mime"))
		assert.equals("farfetch_d", D.key_for("Farfetch'd"))
		assert.equals("ho_oh", D.key_for("Ho-Oh"))
		assert.equals("nidoran_f", D.key_for("nidoran_f"))
		assert.equals("rattata", D.key_for({ name = "rattata" }))
	end)

	it("entity_name adds the minemon_creatures prefix", function()
		assert.equals("minemon_creatures:mr_mime", D.entity_name({ name = "mr_mime" }))
	end)

	it("display_name title-cases each word", function()
		assert.equals("Rattata", D.display_name(by_id(19)))
		assert.equals("Mr Mime", D.display_name(by_id(122)))
	end)

	it("nametag_text is 'Name Lv N'; the colour is red only for aggressive species", function()
		assert.equals("Rattata Lv 4", D.nametag_text(by_id(19), 4))
		assert.equals("#FF3030", D.nametag_color(by_id(19)))
		assert.equals("#FFFFFF", D.nametag_color(by_id(129)))
	end)
end)

describe("creatures_defs temperament and size", function()
	it("aggressive and territorial are hostile; skittish and peaceful are passive", function()
		assert.is_true(D.is_hostile("aggressive"))
		assert.is_true(D.is_hostile("territorial"))
		assert.is_false(D.is_hostile("skittish"))
		assert.is_false(D.is_hostile("peaceful"))
	end)

	it("an unknown temperament is an error", function()
		assert.has_error(function()
			D.is_hostile("grumpy")
		end)
	end)

	it("size_scale maps the six size classes", function()
		assert.equals(0.5, D.size_scale("tiny"))
		assert.equals(0.8, D.size_scale("small"))
		assert.equals(1.2, D.size_scale("medium"))
		assert.equals(1.8, D.size_scale("large"))
		assert.equals(2.6, D.size_scale("huge"))
		assert.equals(3.5, D.size_scale("colossal"))
		assert.has_error(function()
			D.size_scale("gigantic")
		end)
	end)
end)

describe("creatures_defs.build_def", function()
	it("Rattata (aggressive, tiny, quadruped) has the expected spawn class, mesh, texture and size", function()
		local d = D.build_def(by_id(19))
		assert.equals("hostile", d.spawn_class)
		assert.equals("animal", d.type)
		assert.is_false(d.passive)
		assert.equals("mesh", d.visual)
		assert.equals("mm_quadruped.glb", d.mesh)
		assert.are.same({ { "mm_type_normal.png" } }, d.textures)
		-- The brief says small, but species.json says tiny: the data wins.
		assert.is_true(close(d.visual_size.x, 0.5))
		assert.is_true(close(d.visual_size.y, 0.5))
		assert.is_true(close(d.collisionbox[5], 0.25))
		assert.equals(12 + 6, d.view_range)
		assert.is_false(d.fly)
		assert.is_nil(d.fly_in)
		assert.is_false(d.breathes_in_water)
		assert.equals(1 + math.floor(56 / 30), d.damage)
		assert.equals(2.5, d.reach)
		assert.are.same({}, d.drops)
		assert.is_true(d.can_despawn)
		assert.equals(3, d.spawn_in_group)
	end)

	it("Rattata walk and run speeds follow spe", function()
		local d = D.build_def(by_id(19))
		assert.is_true(close(d.walk_velocity, 0.8 + 72 / 150))
		assert.is_true(close(d.run_velocity, 2 * (0.8 + 72 / 150)))
	end)

	it("Gyarados is serpent, aggressive and very large (colossal in the data, not large)", function()
		local d = D.build_def(by_id(130))
		assert.equals("mm_serpent.glb", d.mesh)
		assert.equals("hostile", d.spawn_class)
		assert.is_true(close(d.visual_size.x, 3.5))
		assert.equals(0, d.spawn_in_group)
	end)

	it("Magikarp is a fish: fly_in is water, it breathes water and does not fly", function()
		local d = D.build_def(by_id(129))
		assert.is_false(d.fly)
		assert.is_true(d.breathes_in_water)
		assert.is_true(d.passive)
		assert.equals("passive", d.spawn_class)
		local has_water = false
		for _, n in ipairs(d.fly_in) do
			if n == "mcl_core:water_source" then
				has_water = true
			end
		end
		assert.is_true(has_water)
	end)

	it("Pidgey is avian: it flies, and it is tiny and passive", function()
		local d = D.build_def(by_id(16))
		assert.is_true(d.fly)
		assert.equals("mm_avian.glb", d.mesh)
		assert.equals("passive", d.spawn_class)
		assert.is_true(close(d.visual_size.x, 0.5))
	end)

	it("the medium scale is 1.2 and the collision box scales with it", function()
		local d = D.build_def(by_id(122))
		assert.is_true(close(d.visual_size.x, 1.2))
		assert.is_true(close(d.collisionbox[1], -0.3))
		assert.is_true(close(d.collisionbox[4], 0.3))
		assert.is_true(close(d.collisionbox[5], 0.6))
	end)

	it("the animation ranges match the T-18 contract", function()
		local a = D.build_def(by_id(19)).animation
		assert.equals(0, a.stand_start)
		assert.equals(20, a.stand_end)
		assert.equals(21, a.walk_start)
		assert.equals(41, a.walk_end)
		assert.equals(42, a.run_start)
		assert.equals(52, a.run_end)
		assert.equals(53, a.punch_start)
		assert.equals(63, a.punch_end)
		assert.equals(64, a.die_start)
		assert.equals(74, a.die_end)
		assert.equals(75, a.sit_start)
		assert.equals(85, a.sit_end)
	end)

	it("the def holds data only (no functions), so the glue can add hooks", function()
		for _, sp in ipairs(SPECIES) do
			for k, v in pairs(D.build_def(sp)) do
				assert.is_not.equals("function", type(v), sp.name .. "." .. k)
			end
		end
	end)
end)

describe("creatures_defs.stages", function()
	local list = { by_id(16), by_id(17), by_id(18), by_id(172), by_id(25), by_id(26), by_id(133), by_id(134),
		by_id(1), by_id(2), by_id(3) }
	local stage = D.stages(list)

	it("counts evolutions: Pidgey 1, Pidgeotto 2, Pidgeot 3", function()
		assert.equals(1, stage[16])
		assert.equals(2, stage[17])
		assert.equals(3, stage[18])
	end)

	it("handles a baby chain and an Eevee branch: Pichu 1, Pikachu 2, Raichu 3, Eevee 1, Vaporeon 2", function()
		assert.equals(1, stage[172])
		assert.equals(2, stage[25])
		assert.equals(3, stage[26])
		assert.equals(1, stage[133])
		assert.equals(2, stage[134])
	end)

	it("Bulbasaur 1 and Venusaur 3", function()
		assert.equals(1, stage[1])
		assert.equals(3, stage[3])
	end)
end)

describe("creatures_defs.spawn_plan exclusions", function()
	it("legendaries, mythicals and Unown never spawn", function()
		for _, id in ipairs({ 144, 145, 150, 151, 201, 250, 249, 245, 251 }) do
			local plan, reason = D.spawn_plan(by_id(id), 1)
			assert.is_nil(plan, by_id(id).name)
			assert.equals("legendary_or_unown", reason)
		end
	end)

	it("starter families never spawn naturally", function()
		for _, id in ipairs({ 4, 7, 152, 155, 158 }) do
			local plan, reason = D.spawn_plan(by_id(id), 1)
			assert.is_nil(plan)
			assert.equals("starter", reason)
		end
	end)

	it("eldritch species never spawn", function()
		local plan, reason = D.spawn_plan(by_id(95), 1)
		assert.is_nil(plan)
		assert.equals("eldritch", reason)
	end)

	it("a species with only the rare habitat does not spawn", function()
		local plan, reason = D.spawn_plan({ id = 999, name = "ghost_test", catch_rate = 45, eldritch = false,
			habitats = { "rare" }, evolutions = {}, base_stats = {} }, 1)
		assert.is_nil(plan)
		assert.equals("no_habitat", reason)
	end)

	it("a normal species spawns with the level-2 minimum and its catch rate as weight", function()
		local plan = D.spawn_plan(by_id(19), 1)
		assert.equals(255, plan.chance)
		assert.equals(2, plan.min_level)
		assert.equals(1, plan.stage)
		assert.are.same({ "plains" }, plan.habitats)
	end)
end)

describe("creatures_defs minimum spawn level", function()
	it("unevolved needs level 2, stage 2 needs 16, stage 3 needs 30", function()
		assert.equals(2, D.min_spawn_level(1))
		assert.equals(16, D.min_spawn_level(2))
		assert.equals(30, D.min_spawn_level(3))
	end)

	it("an unknown stage is an error", function()
		assert.has_error(function()
			D.min_spawn_level(4)
		end)
	end)

	it("evolved forms spawn 4x rarer and need their stage's level", function()
		local list = { by_id(16), by_id(17), by_id(18) }
		local stage = D.stages(list)
		local p2 = D.spawn_plan(by_id(17), stage[17])
		local p3 = D.spawn_plan(by_id(18), stage[18])
		assert.equals(16, p2.min_level)
		assert.equals(30, p3.min_level)
		assert.equals(30, p2.chance)
		assert.equals(2, p3.chance)
	end)
end)
