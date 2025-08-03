--------------------------------------------------------------------------------
--  objective_list.lua  –  Column Renderer for Objective Lists
--
--  Shared function to render a scrollable list of objectives within a child
--  ImGui window. Used in multiple contexts (e.g., Profiles and Single tabs).
--
--  Public API:
--      draw_column(title, idset, selset, do_filter, skip_cb, w, h, filter)
--        → Renders the column and returns updated selection table.
--------------------------------------------------------------------------------

--──────────────────────────── Dependencies ──────────────────────────────
local imgui = require('imgui')
local utils = require('utils')
local names = require('combined_objectives')

--──────────────────────────── Column Renderer ───────────────────────────
-- Parameters:
--   title     – string: label for the column
--   idset     – table: set of IDs to display
--   selset    – table: table of selected IDs
--   do_filter – bool: whether to apply filter string
--   skip_cb   – func(id): optional, returns true to hide specific IDs
--   w, h      – number: dimensions of the child window
--   filter    – string: filter text to match objective names
local function draw_column(title, idset, selset, do_filter, skip_cb, w, h, filter)
    imgui.BeginChild(title, { w, h }, true)
    imgui.Text(title)
    imgui.Separator()

    -- Gather and sort objective IDs
    local ids = {}
    for id in pairs(idset) do
        table.insert(ids, id)
    end
    table.sort(ids)

    -- Draw filtered list with optional skip callback
    for _, id in ipairs(ids) do
        if not (skip_cb and skip_cb(id)) then
            local lbl = utils.obj_name(id)
            if not do_filter or not filter or filter == '' or lbl:lower():find(filter:lower(), 1, true) then
                local sel = selset[id] and true or false
                if imgui.Selectable(lbl, sel) then
                    -- Ctrl-click allows multi-select, otherwise resets
                    if not imgui.GetIO().KeyCtrl then selset = {} end
                    selset[id] = sel and nil or true
                end
            end
        end
    end

    imgui.EndChild()
    return selset
end

return draw_column
