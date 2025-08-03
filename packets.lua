--------------------------------------------------------------------------------
--  packets.lua  –  RoE Packet Helpers
--
--  Constructs and sends relevant RoE packets (accept/cancel/refresh), and
--  parses incoming packets (active objectives and completion map).
--
--  Public API:
--      packets.send_accept(id)          → sends 0x10C packet to accept objective
--      packets.send_cancel(id)          → sends 0x10D packet to cancel objective
--      packets.request_roe_refresh()    → sends 0x00F packet to request RoE list
--      packets.cancel_roe(id)           → called by UI cancel (×) button
--      packets.handle_roe_packet(e, state)  → parses 0x111/0x112 into state
--------------------------------------------------------------------------------

--──────────────────────────── Dependencies ──────────────────────────────
local struct = require('struct')
local bit    = require('bit')
local T      = T

--──────────────────────────── Constants ─────────────────────────────────
local PKT_ROE_QUERY     = 0x00F
local PKT_ROE_ACCEPT    = 0x10C
local PKT_ROE_CANCEL    = 0x10D
local PKT_ACTIVE_LIST   = 0x111
local PKT_COMPLETE_MAP  = 0x112

--──────────────────────────── Module Table ──────────────────────────────
local P = {}

--──────────────────────────── Outgoing Packets ──────────────────────────

-- Internal helper to send RoE accept/cancel packet
local function send_roe_packet(pid, roe_id)
    local pkt = struct.pack('bbbbHbb', pid, 0x04, 0x00, 0x00, roe_id, 0x00, 0x00):totable()
    AshitaCore:GetPacketManager():AddOutgoingPacket(pid, pkt)
end

-- Send packet to accept objective
function P.send_accept(id)
    send_roe_packet(PKT_ROE_ACCEPT, id)
end

-- Send packet to cancel objective
function P.send_cancel(id)
    send_roe_packet(PKT_ROE_CANCEL, id)
end

-- Request full RoE objective list/status from server
function P.request_roe_refresh()
    local pkt = T{ 0x0F, 0x12, 0x03, 0x00, 0x00 }
    AshitaCore:GetPacketManager():AddOutgoingPacket(PKT_ROE_QUERY, pkt)
end

-- Called from UI (×) to cancel an active RoE objective
function P.cancel_roe(id)
    id = tonumber(id)
    if not id or id <= 0 then return end
    send_roe_packet(PKT_ROE_CANCEL, id)
end

--──────────────────────────── Incoming Packets ──────────────────────────

-- Parse incoming RoE packets to update the `state` table
function P.handle_roe_packet(e, state)
    if e.id == PKT_ACTIVE_LIST then
        -- Parse 0x111: active objectives (id + progress)
        state.active = {}
        for i = 1, state.max_count do
            local offset = 5 + (i - 1) * 4
            local word   = struct.unpack('I', e.data, offset) -- uint32 LE
            local id     = bit.band(word, 0xFFF)               -- bits 0–11
            if id and id > 0 then
                local prog = bit.rshift(word, 12)              -- bits 12–31
                state.active[id] = prog
            end
        end

    elseif e.id == PKT_COMPLETE_MAP then
        -- Parse 0x112: completed objectives bitmap
        local offset = struct.unpack('H', e.data, 133)
        for i = 0, 1023 do
            local byte = e.data:byte(5 + math.floor(i / 8))
            if bit.band(byte, bit.lshift(1, i % 8)) ~= 0 then
                state.complete[i + offset * 1024] = true
            end
        end
    end
end

return P
