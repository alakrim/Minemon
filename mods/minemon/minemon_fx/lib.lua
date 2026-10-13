-- minemon_fx: the effects library F that recipes and art profiles are written with (docs/ART_GUIDE.md). Glue: it
-- touches core. Every particle goes through F.emit, which applies the per-player quality and the distance cut, so a
-- recipe never sends particles to a player who cannot see them, and amounts are always written for "high".
-- luacheck: read_globals core vector minemon

local MODPATH = core.get_modpath("minemon_fx")
local L = dofile(MODPATH .. "/fx_logic.lua")

local F = {}
F.logic = L

-- Textures (tools/gen_fx_textures.py). Neutral ones are white or grey and are tinted with F.tint; the fire set is
-- painted. Flipbooks are vertical strips: FRAMES gives the frame count and SIZE the frame size in pixels.
F.TEX = {
	glow = "minemon_fx_glow.png",
	flare = "minemon_fx_flare.png",
	spark = "minemon_fx_spark.png",
	mote = "minemon_fx_mote.png",
	streak = "minemon_fx_streak.png",
	ring = "minemon_fx_ring.png",
	dust = "minemon_fx_dust.png",
	smoke = "minemon_fx_smoke_anim.png",
	flame = "minemon_fx_flame_anim.png",
	fireball = "minemon_fx_fireball_anim.png",
	blast = "minemon_fx_blast_anim.png",
	ember = "minemon_fx_ember.png",
	scorch = "minemon_fx_scorch.png",
	blank = "minemon_fx_blank.png",
}
F.FRAMES = { smoke = 8, flame = 8, fireball = 4, blast = 8 }
F.SIZE = { smoke = 32, flame = 32, fireball = 32, blast = 64 }

F.RANGE = tonumber(core.settings:get("minemon_fx_range")) or 64

-- Particle sizes in recipes are in nodes; the engine counts them in tenths of a node. F.emit converts.
F.UNIT = 10
-- Presence (M2.1 review: battles are watched from 5-10 nodes away): every particle is PRESENCE_SIZE larger and lives
-- PRESENCE_LIFE longer than its recipe says. Tune the whole look here, not recipe by recipe.
F.PRESENCE_SIZE = 1.35
F.PRESENCE_LIFE = 1.15

local ZERO = { x = 0, y = 0, z = 0 }

-- Set by init.lua: the quality scale (0.4 .. 1.0) of one player.
F.quality_of = function(_player)
	return 1.0
end

-- ---------------------------------------------------------------- textures

function F.tint(name, colour)
	if not colour then
		return name
	end
	return name .. "^[multiply:" .. colour
end

-- A flipbook animation for one of the F.FRAMES textures, played once over each particle's life (length -1).
function F.anim(key, length)
	local px = F.SIZE[key]
	return { type = "vertical_frames", aspect_w = px, aspect_h = px, length = length or -1 }
end

-- A texture table for the modern particle API. o: blend ("add", "alpha", "screen", "clip"), fade (true: alpha 1 -> 0
-- over the life; or a tween table), alpha, grow ({from, to}: the scale over the life), anim (an F.FRAMES key).
function F.tex(name, o)
	o = o or {}
	local t = { name = name, blend = o.blend or "alpha" }
	if o.fade == true then
		t.alpha_tween = { o.alpha or 1, 0 }
	elseif type(o.fade) == "table" then
		t.alpha_tween = o.fade
	elseif o.alpha then
		t.alpha = o.alpha
	end
	if o.grow then
		t.scale_tween = { o.grow[1], o.grow[2] }
	end
	if o.anim then
		t.animation = F.anim(o.anim, o.anim_length)
	end
	return t
end

-- ---------------------------------------------------------------- emission

-- Players that should see an effect at pos, with their quality scale.
function F.viewers(pos, range)
	local out = {}
	if not pos then
		return out
	end
	local r = range or F.RANGE
	for _, player in ipairs(core.get_connected_players()) do
		local pp = player:get_pos()
		if pp and vector.distance(pp, pos) <= r then
			out[#out + 1] = { player = player, name = player:get_player_name(), scale = F.quality_of(player) }
		end
	end
	return out
end

-- Adds one particle spawner per nearby player, the amount scaled by that player's quality. def uses the modern
-- spawner fields (pos, vel, acc, exptime, size in NODES, texture, ...); its amount is the "high" amount. at is the
-- point used for the distance cut (default def.pos, or the attached object's position). Returns the spawner ids.
function F.emit(def, at)
	local ref = at
	if not ref then
		if def.attached then
			ref = def.attached:get_pos()
		elseif type(def.pos) == "table" and def.pos.x then
			ref = def.pos
		elseif type(def.pos) == "table" and def.pos.min then
			ref = def.pos.min
		end
	end
	local ids = {}
	local base = def.amount or 1
	local size = def.size
	local unit = F.UNIT * F.PRESENCE_SIZE
	if type(size) == "number" then
		size = size * unit
	elseif type(size) == "table" then
		size = { min = (size.min or 0) * unit, max = (size.max or 0) * unit, bias = size.bias }
	end
	local exptime = def.exptime
	if type(exptime) == "number" then
		exptime = exptime * F.PRESENCE_LIFE
	elseif type(exptime) == "table" then
		exptime = { min = (exptime.min or 0) * F.PRESENCE_LIFE, max = (exptime.max or 0) * F.PRESENCE_LIFE,
			bias = exptime.bias }
	end
	for _, v in ipairs(F.viewers(ref)) do
		local n = L.amount(base, v.scale)
		if n > 0 then
			local d = {}
			for k, val in pairs(def) do
				d[k] = val
			end
			d.amount = n
			d.size = size
			d.exptime = exptime
			d.playername = v.name
			d.time = d.time or 0.05
			ids[#ids + 1] = core.add_particlespawner(d)
		end
	end
	return ids
end

function F.delete(ids)
	for _, id in ipairs(ids or {}) do
		if id and id >= 0 then
			core.delete_particlespawner(id)
		end
	end
end

-- ---------------------------------------------------------------- primitives

-- One bright additive flash: the catch light of a cast, a launch or a hit.
-- o: pos, colour, size (default 4), life (default 0.18), glow.
function F.flare(o)
	return F.emit({
		amount = 1,
		time = 0.02,
		pos = o.pos,
		vel = ZERO,
		exptime = o.life or 0.18,
		size = o.size or 0.8,
		texture = F.tex(F.tint(F.TEX.flare, o.colour), { blend = "add", fade = true, grow = o.grow or { 1, 1.4 } }),
		glow = 14,
	})
end

-- A radial burst: particles appear on a small sphere around pos and fly outwards (attractor with negative strength).
-- o: pos, tex (default spark), colour, amount, speed (m/s at the shell, default 4), radius (0.15), life ({min, max}),
-- size ({min, max}), gravity (m/s^2 down), drag, blend ("add"), fade (true), grow, collide, bounce, glow, time, anim.
function F.burst(o)
	local radius = o.radius or 0.15
	local speed = o.speed or 4
	local life = o.life or { 0.3, 0.7 }
	local size = o.size or { 0.1, 0.2 }
	return F.emit({
		amount = o.amount or 20,
		time = o.time or 0.05,
		pos = o.pos,
		radius = { min = radius * 0.5, max = radius, bias = 0 },
		attract = { kind = "point", origin = o.pos, strength = { min = -speed / radius * 0.6, max = -speed / radius },
			die_on_contact = false },
		vel = o.vel or ZERO,
		acc = { x = 0, y = -(o.gravity or 0), z = 0 },
		drag = o.drag and { x = o.drag, y = o.drag, z = o.drag } or nil,
		exptime = { min = life[1], max = life[2] },
		size = { min = size[1], max = size[2] },
		collisiondetection = o.collide == true,
		bounce = o.bounce and { min = o.bounce * 0.6, max = o.bounce } or nil,
		texture = F.tex(F.tint(o.tex or F.TEX.spark, o.colour), { blend = o.blend or "add", fade = o.fade ~= false,
			grow = o.grow, anim = o.anim }),
		glow = o.glow or 14,
	})
end

-- Billowing smoke (alpha blend, flipbook). o: pos, colour (default dark grey), amount, size, life, rise (m/s up),
-- spread (box half size), time, alpha, attached.
function F.smoke(o)
	local spread = o.spread or 0.3
	local size = o.size or { 0.6, 1.05 }
	local life = o.life or { 0.9, 1.5 }
	local rise = o.rise or 0.8
	return F.emit({
		amount = o.amount or 8,
		time = o.time or 0.2,
		pos = { min = vector.subtract(o.pos, spread), max = vector.add(o.pos, spread) },
		vel = { min = { x = -0.2, y = rise * 0.6, z = -0.2 }, max = { x = 0.2, y = rise, z = 0.2 } },
		drag = { x = 0.6, y = 0.3, z = 0.6 },
		exptime = { min = life[1], max = life[2] },
		size = { min = size[1], max = size[2] },
		texture = F.tex(F.tint(F.TEX.smoke, o.colour or "#4a4440"), { blend = "alpha", alpha = o.alpha or 0.75,
			anim = "smoke", grow = { 0.6, 1.4 } }),
		attached = o.attached,
		glow = o.glow or 0,
	}, o.at)
end

-- Licking flames (painted flipbook, additive): the body of every fire effect. o: pos, amount, size, life, spread,
-- rise, time, attached, vertical (default true: the tongues stay upright).
function F.flames(o)
	local spread = o.spread or 0.2
	local size = o.size or { 0.45, 0.75 }
	local life = o.life or { 0.35, 0.6 }
	local rise = o.rise or 1.2
	return F.emit({
		amount = o.amount or 16,
		time = o.time or 0.3,
		pos = { min = vector.subtract(o.pos, spread), max = vector.add(o.pos, spread) },
		vel = { min = { x = -0.15, y = rise * 0.6, z = -0.15 }, max = { x = 0.15, y = rise, z = 0.15 } },
		exptime = { min = life[1], max = life[2] },
		size = { min = size[1], max = size[2] },
		texture = F.tex(F.TEX.flame, { blend = "add", anim = "flame", grow = { 1, 0.4 } }),
		vertical = o.vertical ~= false,
		attached = o.attached,
		glow = 14,
	}, o.at)
end

-- Hot embers that pop out, fall, bounce on the ground and wink out. o: pos, amount, speed, up (extra lift), life,
-- gravity, collide (default true), size, radius.
function F.embers(o)
	local speed = o.speed or 2.5
	local up = o.up or 1.5
	local life = o.life or { 0.6, 1.3 }
	local size = o.size or { 0.06, 0.12 }
	local r = o.radius or 0.2
	return F.emit({
		amount = o.amount or 14,
		time = o.time or 0.08,
		pos = { min = vector.subtract(o.pos, r), max = vector.add(o.pos, r) },
		vel = { min = { x = -speed, y = up * 0.4, z = -speed }, max = { x = speed, y = up + speed * 0.5, z = speed } },
		acc = { x = 0, y = -(o.gravity or 9), z = 0 },
		drag = { x = 0.4, y = 0, z = 0.4 },
		exptime = { min = life[1], max = life[2] },
		size = { min = size[1], max = size[2] },
		collisiondetection = o.collide ~= false,
		bounce = { min = 0.2, max = 0.45 },
		texture = F.tex(F.TEX.ember, { blend = "add", fade = { 1, 0.8 } }),
		glow = 14,
	})
end

-- A shockwave ring (additive). Billboards face the camera, so it reads as an expanding shell from any side.
-- o: pos, colour, size (start), grow (end scale factor, default 3), life.
function F.ring(o)
	return F.emit({
		amount = 1,
		time = 0.02,
		pos = o.pos,
		vel = ZERO,
		exptime = o.life or 0.35,
		size = o.size or 0.6,
		texture = F.tex(F.tint(F.TEX.ring, o.colour), { blend = "add", fade = true, grow = { 0.3, o.grow or 3 } }),
		glow = 14,
	})
end

-- The painted fire blast flipbook. o: pos, size, life, amount (1-3 overlapping blasts), spread.
function F.blast(o)
	local spread = o.spread or 0.1
	return F.emit({
		amount = o.amount or 1,
		time = o.time or 0.05,
		pos = { min = vector.subtract(o.pos, spread), max = vector.add(o.pos, spread) },
		vel = ZERO,
		exptime = o.life or 0.45,
		size = o.size or 1.2,
		texture = F.tex(F.TEX.blast, { blend = "add", anim = "blast" }),
		glow = 14,
	})
end

-- Particles drawn into a point (a wind-up: an inhale, a charge). o: pos, colour, tex (default mote), radius,
-- amount, time, life, size.
function F.inhale(o)
	local r = o.radius or 1.0
	local time = o.time or 0.5
	local size = o.size or { 0.08, 0.16 }
	return F.emit({
		amount = o.amount or 24,
		time = time,
		pos = o.pos,
		radius = { min = r * 0.7, max = r, bias = 0 },
		attract = { kind = "point", origin = o.pos, strength = { min = 2.5, max = 3.5 }, die_on_contact = true },
		vel = ZERO,
		exptime = { min = 0.25, max = 0.45 },
		size = { min = size[1], max = size[2] },
		texture = F.tex(F.tint(o.tex or F.TEX.mote, o.colour), { blend = "add", fade = { 0.2, 1 } }),
		glow = 14,
	})
end

-- A spawner riding on an object (a projectile trail, flames on a burning body). def is a spawner def; its pos, vel
-- and acc are relative to the object. Lives def.time seconds (default 1). Returns the ids.
function F.on(obj, def)
	def.attached = obj
	def.time = def.time or 1
	return F.emit(def, obj:get_pos())
end

-- ---------------------------------------------------------------- entities: decals and numbers

local DECAL = "minemon_fx:decal"
local NUMBER = "minemon_fx:number"
local DECAL_CAP = 16
local decals = {}

core.register_entity(DECAL, {
	initial_properties = {
		visual = "upright_sprite",
		textures = { F.TEX.blank, F.TEX.blank },
		physical = false,
		pointable = false,
		static_save = false,
		collisionbox = { 0, 0, 0, 0, 0, 0 },
		use_texture_alpha = true,
		backface_culling = false,
		shaded = false,
	},
	on_step = function(self, dtime)
		self._age = (self._age or 0) + dtime
		local life = self._life or 6
		local fade_at = life * 0.6
		-- Three alpha steps while it fades: three property updates in all, not one per step.
		local step = self._age < fade_at and 0 or math.min(3, math.floor((self._age - fade_at) / (life - fade_at) * 4))
		if step ~= (self._step or 0) and self._tex then
			self._step = step
			local t = self._tex .. "^[opacity:" .. tostring(math.floor(255 * (1 - step / 4)))
			self.object:set_properties({ textures = { t, t } })
		end
		if self._age >= life then
			self.object:remove()
		end
	end,
})

-- The y just above the first walkable node at or below pos (within 4 nodes), or nil.
local function ground_below(pos)
	local start = vector.round(pos)
	for dy = 0, 4 do
		local p = { x = start.x, y = start.y - dy, z = start.z }
		local node = core.get_node_or_nil(p)
		local def = node and core.registered_nodes[node.name]
		if def and def.walkable then
			return p.y + 0.5
		end
	end
	return nil
end

-- A mark lying flat on the ground under pos (a scorch, a frost patch, a crater). o: pos, tex, size, life, glow.
-- At most DECAL_CAP live at once (the oldest goes first).
function F.decal(o)
	local y = ground_below(o.pos)
	if not y then
		return nil
	end
	local p = { x = o.pos.x, y = y + 0.02, z = o.pos.z }
	local obj = core.add_entity(p, DECAL)
	if not obj then
		return nil
	end
	local size = o.size or 1.6
	obj:set_properties({ textures = { o.tex, o.tex }, visual_size = { x = size, y = size, z = size },
		glow = o.glow or 0 })
	obj:set_rotation({ x = math.pi / 2, y = math.random() * math.pi * 2, z = 0 })
	local le = obj:get_luaentity()
	le._life = o.life or 6
	le._tex = o.tex
	decals[#decals + 1] = obj
	while #decals > DECAL_CAP do
		local old = table.remove(decals, 1)
		if old and old:get_pos() then
			old:remove()
		end
	end
	return obj
end

core.register_entity(NUMBER, {
	initial_properties = {
		visual = "sprite",
		textures = { F.TEX.blank },
		visual_size = { x = 0.01, y = 0.01 },
		physical = false,
		pointable = false,
		static_save = false,
		collisionbox = { 0, 0, 0, 0, 0, 0 },
		selectionbox = { 0, 0, 0, 0, 0, 0 },
		nametag_bgcolor = "#00000000",
	},
	on_step = function(self, dtime)
		self._age = (self._age or 0) + dtime
		if self._age >= 0.9 then
			self.object:remove()
		end
	end,
})

-- A damage number that pops up from pos and drifts away (one entity, moved by the client: no packets while it flies).
function F.number(pos, amount, effectiveness, crit)
	if amount == nil or amount <= 0 then
		return nil
	end
	local text, colour, size = L.damage_text(amount, effectiveness, crit)
	local obj = core.add_entity(vector.add(pos, { x = (math.random() - 0.5) * 0.4, y = 0.2, z = 0 }), NUMBER)
	if not obj then
		return nil
	end
	obj:set_properties({ nametag = text, nametag_color = L.hex(colour), nametag_fontsize = math.floor(18 * size) })
	obj:set_velocity({ x = (math.random() - 0.5) * 0.6, y = 2.2, z = (math.random() - 0.5) * 0.6 })
	obj:set_acceleration({ x = 0, y = -3.2, z = 0 })
	return obj
end

-- ---------------------------------------------------------------- feel: hit stop, sound

-- Freezes the animation of each object for t seconds (a hit stop: the blow lands with weight).
function F.hitstop(objs, t)
	for _, obj in ipairs(objs) do
		if obj and obj:get_pos() and not obj:is_player() then
			local range, speed, blend, loop = obj:get_animation()
			if speed and speed > 0 then
				obj:set_animation_frame_speed(0)
				core.after(t or 0.08, function()
					if obj:get_pos() then
						local r2, s2 = obj:get_animation()
						-- Restore only if nothing else changed the clip meanwhile.
						if s2 == 0 and r2 and range and r2.x == range.x and r2.y == range.y then
							obj:set_animation(range, speed, blend, loop)
						end
					end
				end)
			end
		end
	end
end

-- A sound at a position or on an object. o: pos or object, gain, pitch (default with a small random spread), max.
function F.sound(name, o)
	local spec = { gain = o.gain or 1.0, pitch = o.pitch or (0.92 + math.random() * 0.16),
		max_hear_distance = o.max or 24 }
	if o.object then
		spec.object = o.object
	else
		spec.pos = o.pos
	end
	core.sound_play(name, spec, true)
end

-- ---------------------------------------------------------------- anchors

-- The world position of a named anchor on a creature: a Cobblemon locator (mouth, head, target, middle, fire, ...;
-- tools/cobblemon_import.py exports them) turned by the yaw. Without the locator: frac of the body height above the
-- feet (default 0.6), pushed forward by fwd times the half width. Players: the eye for mouth/head, else the chest.
function F.anchor(obj, name, frac, fwd)
	local pos = obj and obj:get_pos()
	if not pos then
		return nil
	end
	if obj:is_player() then
		local h = (name == "mouth" or name == "head") and 1.5 or 1.0
		return vector.add(pos, { x = 0, y = h, z = 0 })
	end
	local yaw = obj:get_yaw() or 0
	local props = obj:get_properties()
	local inst = minemon.creatures and minemon.creatures.get_instance and minemon.creatures.get_instance(obj)
	local pack = rawget(_G, "minemon_pack")
	local entry = inst and pack and pack.models and pack.models[inst.species_id]
	local loc = entry and entry.locators and entry.locators[name]
	local scale = (props.visual_size and props.visual_size.x) or 1
	if loc then
		local x, y, z = L.rotate_offset(loc[1], loc[2], loc[3], yaw, scale)
		return { x = pos.x + x, y = pos.y + y, z = pos.z + z }
	end
	local cb = props.collisionbox or { -0.25, 0, -0.25, 0.25, 0.5, 0.25 }
	local h = cb[5] - cb[2]
	local half = (cb[4] - cb[1]) / 2
	local fx, _, fz = L.rotate_offset(0, 0, half * (fwd or 0), yaw, 1)
	return { x = pos.x + fx, y = pos.y + cb[2] + h * (frac or 0.6), z = pos.z + fz }
end

-- The locator table of a creature's pack model, or nil.
function F.locators(obj)
	local inst = minemon.creatures and minemon.creatures.get_instance and minemon.creatures.get_instance(obj)
	local pack = rawget(_G, "minemon_pack")
	local entry = inst and pack and pack.models and pack.models[inst.species_id]
	return entry and entry.locators or nil
end

return F
