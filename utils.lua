--------------------------------------------------------------------------------
--  utils.lua  –  Utility functions for table conversion and RoE objective names
--------------------------------------------------------------------------------

--──────────────────────────── Dependencies ──────────────────────────────
local names = require('combined_objectives') -- RoE objective metadata
local M = {}

--──────────────────────────── Table → Set Conversion ────────────────────
-- Converts a mixed table (list or dict) or a string of numbers into a set.
-- Accepts:
--   - Table of booleans or values: { [1]=true, [3]=true } or { 1, 3 }
--   - String like "1 2 3" or "Objective: 101, 203"
function M.as_set(value)
    if type(value) == 'table' then
        local out = {}
        for k, v in pairs(value) do
            if type(k) == 'number' and v then
                out[k] = true
            elseif type(v) == 'number' then
                out[v] = true
            end
        end
        return out
    elseif type(value) == 'string' then
        local out = {}
        for id in value:gmatch('%d+') do
            out[tonumber(id)] = true
        end
        return out
    end
    return {}
end

--──────────────────────────── Table Size Counter ────────────────────────
-- Returns the number of keys in a table (i.e. set size).
function M.set_size(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

--──────────────────────────── Objective Name Resolver ───────────────────
-- Returns the name of an objective based on its ID.
-- Falls back to string ID or placeholder text if needed.
function M.obj_name(id)
    return names[id].name or names[tostring(id)].name or ('[ID %d]'):format(id)
end

return M
