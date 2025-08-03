--------------------------------------------------------------------------------
--  styles.lua  –  Pushes and pops a custom ImGui theme for roEZ UI
--------------------------------------------------------------------------------

--──────────────────────────── Dependencies ──────────────────────────────
local imgui = require('imgui')
local M = {}

--──────────────────────────── Internal State ────────────────────────────
local theme_applied = false
local theme_style_count = 0

--──────────────────────────── RGBA Helper ───────────────────────────────
-- Converts RGB in 0-255 and alpha [0-1] to ImGui-style color table.
local function col(r, g, b, a)
    return { r / 255, g / 255, b / 255, a }
end

--──────────────────────────── Theme Applier ─────────────────────────────
-- Pushes all style colors and tweaks ImGui rounding styles.
-- Should be called once per draw frame.
function M.push_theme()
    if theme_applied then return end
    theme_applied = true
    theme_style_count = 0

    local style = imgui.GetStyle()

    local bg   = col(11, 30, 61, 0.85)   -- Window background
    local pane = col(16, 37, 75, 0.90)   -- Child panels, buttons
    local hov  = col(46, 200, 66, 0.90)  -- Hovered state
    local act  = col(46, 82, 153, 0.90)  -- Active/pressed state
    local head = col(25, 75, 16, 0.90)   -- Header rows

    local function push(col_id, color)
        imgui.PushStyleColor(col_id, color)
        theme_style_count = theme_style_count + 1
    end

    push(ImGuiCol_WindowBg,             bg)
    push(ImGuiCol_ChildBg,              bg)
    push(ImGuiCol_PopupBg,              bg)
    push(ImGuiCol_ScrollbarBg,          pane)
    push(ImGuiCol_ScrollbarGrab,        {1, 1, 1, 1})
    push(ImGuiCol_ScrollbarGrabHovered, hov)
    push(ImGuiCol_ScrollbarGrabActive,  act)
    push(ImGuiCol_FrameBg,              pane)
    push(ImGuiCol_FrameBgHovered,       hov)
    push(ImGuiCol_FrameBgActive,        act)
    push(ImGuiCol_TitleBg,              bg)
    push(ImGuiCol_TitleBgActive,        pane)
    push(ImGuiCol_Button,               pane)
    push(ImGuiCol_ButtonHovered,        hov)
    push(ImGuiCol_ButtonActive,         act)
    push(ImGuiCol_Header,               head)
    push(ImGuiCol_HeaderHovered,        hov)
    push(ImGuiCol_HeaderActive,         act)
    push(ImGuiCol_Text,                 {1, 1, 1, 1})
    push(ImGuiCol_TextDisabled,         {0.6, 0.6, 0.6, 1})

    style.WindowRounding = 7
    style.FrameRounding  = 5
    style.TabRounding    = 5
end

--──────────────────────────── Theme Remover ─────────────────────────────
-- Pops all previously pushed style colors to restore global ImGui state.
function M.pop_theme()
    imgui.PopStyleColor(theme_style_count)
    theme_applied = false
    theme_style_count = 0
end

return M
