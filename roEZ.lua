--------------------------------------------------------------------------------
--  roEZ.lua  –  Main entry point for the “roEZ” addon (Ashita v4)
--  Provides a GUI-driven tool for managing Records of Eminence (RoE) profiles.
--------------------------------------------------------------------------------

addon.name    = 'roEZ'
addon.version = '0.5-beta'
addon.author  = 'Commandobill'
addon.desc    = 'GUI-centric RoE profile helper'
addon.link    = 'https://github.com/commandobill/roEZ'

--──────────────────────────── Dependencies ──────────────────────────────
local imgui   = require('imgui')               -- Ashita’s ImGui wrapper
local struct  = require('struct')              -- Packet structure helper
local bit     = require('bit')                 -- Bitwise operations
local names   = require('combined_objectives') -- All RoE objective metadata
local profile = require('profiles')            -- Profile save/load manager
local gui     = require('ui')                  -- Main GUI rendering logic
local pack    = require('packets')             -- RoE-related packet helpers
local log     = require('log')                 -- Logging helper

--──────────────────────────── World Readiness ───────────────────────────
-- Utility to determine whether the player and world are in a valid state.
local function is_world_ready()
    local player     = AshitaCore:GetMemoryManager():GetPlayer()
    local player_ent = GetPlayerEntity()
    return not (player == nil or player.isZoning or player_ent == nil)
end

--──────────────────────────── Runtime State ─────────────────────────────
-- Holds current RoE progress and completed objective information.
local state = {
    active    = {},    -- [id] = current progress count
    complete  = {},    -- [id] = true if completed
    max_count = 30,    -- Maximum RoE objectives allowed at once
}

--──────────────────────────── Packet Handling ───────────────────────────
-- Captures and parses RoE-related packets to update the internal state.
ashita.events.register('packet_in', 'roez_pkt', function(e)
    pack.handle_roe_packet(e, state)
end)

--──────────────────────────── GUI Render Loop ───────────────────────────
-- Called each frame to draw the UI if visible.
ashita.events.register('d3d_present', 'roez_present', function()
    gui.render(state, profile, names)
end)

--──────────────────────────── Manual UI Toggle ──────────────────────────
-- Enables /roez as a slash command to open the UI.
ashita.events.register('command', 'roez_cmd', function(e)
    local a = e.command:args()
    if #a == 0 or a[1]:lower() ~= '/roez' then return end
    e.blocked = true
    gui.show = true
end)

--──────────────────────────── Initial Refresh ───────────────────────────
-- Sends a one-time RoE refresh packet shortly after addon loads.
local _startup = { sent = false }

local function startup_refresh()
    if _startup.sent then return end
    if is_world_ready() then
        pack.request_roe_refresh()
        log.printf('Requested RoE status refresh (startup).')
        _startup.sent = true
    end
end

ashita.events.register('load', 'roez_load', startup_refresh)
