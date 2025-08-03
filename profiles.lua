--------------------------------------------------------------------------------
--  profiles.lua  –  Persistent profile manager + locked-objective store
--
--  Manages saved RoE objective profiles and locked objective lists.
--  Uses Ashita's per-character `settings` system for persistence.
--
--  Public API:
--      profiles.names()                  → sorted list of saved profile names
--      profiles.load(name)              → table of objective IDs
--      profiles.save_current(name, map) → saves the passed active objectives
--      profiles.apply(name, state)      → applies profile (respects locks)
--      profiles.get_locked_table()      → returns lock table
--      profiles.set_locked_table(t)     → replaces and saves lock table
--      profiles.add_locked(id)          → marks a single objective as locked
--      profiles.remove_locked(id)       → unmarks objective as locked
--------------------------------------------------------------------------------

--──────────────────────────── Dependencies ──────────────────────────────
local settings  = require('settings')     -- Ashita per-character settings
local struct    = require('struct')
local coroutine = coroutine
local Set       = require('set')
local log       = require('log')
local pack      = require('packets')
local utils     = require('utils')

--──────────────────────────── Default Config ────────────────────────────
-- Initial structure if no config file exists.
local defaults = T{
    profiles = { default = {} },   -- profile name ⇒ { id1, id2, ... }
    locked   = {},                 -- id ⇒ true
    debug = false
}

--=============================================================================
-- Registers a callback for the settings to monitor for character switches.
--=============================================================================
settings.register('settings', 'settings_update', function (s)
    if (s ~= nil) then
        cfg = s;
    end
    settings.save();
end);

--──────────────────────────── Public Interface ──────────────────────────
local profiles = T{
    cfg = settings.load(defaults)
}

-- Loads a profile's list of objective IDs by name
function profiles.load(name)
    return cfg.profiles[name:lower()]
end

-- Returns a sorted list of all saved profile names
function profiles.names()
    local t = {}
    for k in pairs(cfg.profiles) do t[#t + 1] = k end
    table.sort(t)
    return t
end

-- Get/set lock table for objectives
function profiles.get_locked_table()  return cfg.locked end
function profiles.set_locked_table(t) cfg.locked = t; settings.save() end

-- Saves the currently active objectives under the given profile name
function profiles.save_current(name, active_map)
    if type(name) ~= 'string' then return end
    local list = {}
    for id in pairs(active_map) do list[#list + 1] = id end
    cfg.profiles[name:lower()] = list
    settings.save()
end

-- Applies a profile by adding/removing objectives, respecting locked list
function profiles.apply(name, state)
    name = type(name) == 'string' and name:lower() or nil
    local want = profiles.load(name) or {}
    want = Set(want)
    if not next(want) then
        log.printf('Profile not found or empty.')
        return
    end

    local have = state.active
    local add  = {}
    local drop = {}

    for id in pairs(want) do
        if cfg.debug then log.printf('Checking:' .. id) end
        if not have[id] then add[id] = true end
    end
    for id in pairs(have) do
        if not want[id] and not cfg.locked[id] then drop[id] = true end
    end

    local free = state.max_count - utils.set_size(have) + utils.set_size(drop)
    if utils.set_size(add) > free then
        log.printf('Not enough free RoE slots.')
        return
    end

    for id in pairs(drop) do
        pack.send_cancel(id)
        coroutine.sleep(0.3)
    end
    for id in pairs(add) do
        if cfg.debug then log.printf('Adding:' .. id) end
        pack.send_accept(id)
        coroutine.sleep(0.3)
    end
end

-- Adds/removes a specific objective ID to/from the locked list
function profiles.add_locked(id)
    cfg.locked[id] = true
    settings.save()
end

function profiles.remove_locked(id)
    cfg.locked[id] = nil
    settings.save()
end

return profiles
