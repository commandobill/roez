--------------------------------------------------------------------------------
--  log.lua  –  Logging Helper
--
--  Provides formatted logging utilities for printing addon messages to chat.
--  Integrates with Ashita’s `chat` module to format standard, warning,
--  and error messages with the addon’s name as a prefix.
--
--  Public API:
--      log.printf(fmt, ...)   → Standard message
--      log.warnf(fmt, ...)   → Yellow warning message
--      log.errorf(fmt, ...)  → Red error message
--------------------------------------------------------------------------------

--──────────────────────────── Dependencies ──────────────────────────────
local chat = require('chat')

--──────────────────────────── Module Table ──────────────────────────────
local M = {}

-- Prints a standard info message to the chat log
function M.printf(fmt, ...)
    print(chat.header(addon.name) .. chat.message(fmt:format(...)))
end

-- Prints a yellow warning message to the chat log
function M.warnf(fmt, ...)
    print(chat.header(addon.name) .. chat.warning(fmt:format(...)))
end

-- Prints a red error message to the chat log
function M.errorf(fmt, ...)
    print(chat.header(addon.name) .. chat.error(fmt:format(...)))
end

return M
