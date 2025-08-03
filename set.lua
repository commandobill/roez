--------------------------------------------------------------------------------
--  set.lua  –  Minimal Set helper object with utility methods
--  Provides a compact, dependency-free way to create and operate on sets.
--
--  Example Usage:
--      local S = require('set')
--      local a = S{ 1, 2, 3 }
--      local b = S{ 3, 4 }
--      a:add(5)                -- {1,2,3,5}
--      print(a:contains(2))    --> true
--      local c = a:diff(b)     -- {1,2,5}
--      for id in c:it() do ... end
--------------------------------------------------------------------------------

--──────────────────────────── Internal Constructor ──────────────────────
-- Wraps a raw Lua table with Set methods via metatable.
local function _new_set(values)
    local self = {}
    if values then for _, v in pairs(values) do self[v] = true end end
    local mt = {}

    function mt.__index(t, k)
        if     k == 'add'          then return function(_, v) t[v] = true end
        elseif k == 'remove'       then return function(_, v) t[v] = nil end
        elseif k == 'contains'     then return function(_, v) return t[v] end
        elseif k == 'length'       then return function()
                                        local c = 0
                                        for _ in pairs(t) do c = c + 1 end
                                        return c
                                     end
        elseif k == 'keyset'       then return function()
                                        local r = S{}
                                        for v in pairs(t) do r:add(v) end
                                        return r
                                     end
        elseif k == 'update'       then return function(_, o)
                                        for v in pairs(o) do t[v] = true end
                                     end
        elseif k == 'diff'         then return function(_, o)
                                        local r = S{}
                                        for v in pairs(t) do if not o[v] then r:add(v) end end
                                        return r
                                     end
        elseif k == 'intersection' then return function(_, o)
                                        local r = S{}
                                        for v in pairs(t) do if o[v] then r:add(v) end end
                                        return r
                                     end
        elseif k == 'union'        then return function(_, o)
                                        local r = S{}
                                        r:update(t)
                                        r:update(o)
                                        return r
                                     end
        elseif k == 'it'           then return function()
                                        local k
                                        return function() k = next(t, k); return k end
                                     end
        end
    end

    return setmetatable(self, mt)
end

--──────────────────────────── Public Constructor ────────────────────────
-- Call-style interface for Set creation: S{1,2,3}
S = setmetatable({}, {
    __call = function(_, iter)
        return _new_set(iter)
    end
})

return S
