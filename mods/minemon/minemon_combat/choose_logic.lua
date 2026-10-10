-- Move choice (T-23). Pure: no Luanti API, so busted can test it.
-- A candidate is {id, pp, move, on_cooldown}; pp nil means unlimited (wild creatures).
-- ctx = {user_types, target_types, target_status, type_mult(atk_type, def_types)}.

local M = {}

M.RANDOM_CHANCE = 0.15
M.STATUS_SCORE = 30
M.STAB = 1.5

local function has(list, value)
	for _, v in ipairs(list or {}) do
		if v == value then
			return true
		end
	end
	return false
end

-- Expected damage = power x accuracy x STAB x type multiplier. Status moves score 30 when the target has no status.
function M.score(move, ctx)
	if move.category == "status" then
		if ctx.target_status == nil or ctx.target_status == "none" then
			return M.STATUS_SCORE
		end
		return 0
	end
	local power = tonumber(move.power) or 0
	if power <= 0 then
		return 0
	end
	local accuracy = (move.accuracy or 100) / 100
	local stab = has(ctx.user_types, move.type) and M.STAB or 1
	local mult = ctx.type_mult(move.type, ctx.target_types or {})
	return power * accuracy * stab * mult
end

-- Drops moves on cooldown and moves with no PP left.
function M.eligible(candidates)
	local out = {}
	for _, c in ipairs(candidates) do
		if not c.on_cooldown and (c.pp == nil or c.pp > 0) then
			out[#out + 1] = c
		end
	end
	return out
end

-- The best eligible move by score. Ties keep the earlier move in the list. Returns id, score or nil.
function M.choose_best(candidates, ctx)
	local best, best_score = nil, nil
	for _, c in ipairs(M.eligible(candidates)) do
		local s = M.score(c.move, ctx)
		if best_score == nil or s > best_score then
			best, best_score = c, s
		end
	end
	if best == nil then
		return nil, nil
	end
	return best.id, best_score
end

-- The best move, except that with RANDOM_CHANCE (from rng:float()) a random eligible move is picked.
function M.choose(candidates, ctx, rng)
	local list = M.eligible(candidates)
	if #list == 0 then
		return nil
	end
	if rng:float() < M.RANDOM_CHANCE then
		return list[rng:int(1, #list)].id
	end
	return (M.choose_best(candidates, ctx))
end

return M
