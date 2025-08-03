--------------------------------------------------------------------------------
--  roez/ui.lua  –  GUI logic for the “roEZ” addon (Ashita v4)
--  Handles the Profiles and Single Objectives management interfaces.
--------------------------------------------------------------------------------

--──────────────────────────── Dependencies ──────────────────────────────
local imgui    = require('imgui')              -- Ashita’s ImGui wrapper
local profiles = require('profiles')           -- Profile save/load manager
local Set      = require('set')                -- Lightweight set library
local log      = require('log')                -- Logging helper
local pack     = require('packets')            -- RoE-related packet helpers
local styles   = require('styles')             -- UI theme styling
local utils    = require('utils')              -- Utility functions
local modal    = require('modal')              -- Modal confirmation popup
local draw_column = require('objective_list')  -- Draws list columns
local names    = require('combined_objectives')-- All RoE objective metadata

--──────────────────────────── Constants ────────────────────────────────
local POSSIBLE_OBJECTIVE_COUNT = 30            -- Max number of objectives

--──────────────────────────── UI State ─────────────────────────────────
local ui = {
    show             = true,                   -- Whether UI window is shown
    hide_completed   = true,                   -- Filter out completed objectives
    filter           = '',                     -- Global filter string
    selected_profile = nil,                    -- Currently selected profile
    profile_rename   = '',                     -- Rename input buffer
    queue            = Set(),                  -- Objectives to be applied
    sel_master       = Set(),                  -- Selected items in master list
    sel_queue        = Set(),                  -- Selected items in queue
    sel_lock         = Set(),                  -- Selected items in locked
    show_preview     = true,                   -- Show preview modal toggle
}

--──────────────────────────── Helpers ──────────────────────────────────
-- Toggles selection state in a set
local function selectable(id, label, selset)
    local sel = selset[id] and true or false
    if imgui.Selectable(label, sel) then
        if not imgui.GetIO().KeyCtrl then selset = Set() end
        selset[id] = sel and nil or true
    end
    return selset
end

-- Returns the total number of objectives selected (locked + queue)
local function total_selected_count()
    local count = 0
    for _ in pairs(ui.queue) do count = count + 1 end
    for _ in pairs(profiles.get_locked_table()) do count = count + 1 end
    return count
end

-- Adds an objective to the queue
local function add_to_queue(id)
    if not ui.queue[id] and total_selected_count() < POSSIBLE_OBJECTIVE_COUNT then
        ui.queue[id] = true
        profiles.remove_locked(id)
    end
end

-- Adds an objective to the locked table
local function add_to_locked(id)
    if not profiles.get_locked_table()[id] and total_selected_count() < POSSIBLE_OBJECTIVE_COUNT then
        profiles.add_locked(id)
        ui.queue[id] = nil
    end
end

-- Moves selected items between sets using a callback
local function move(sel_src, _, dst_cb)
    for id in pairs(sel_src) do
        dst_cb(id)
        sel_src[id] = nil
    end
end

--──────────────────────────── Profiles Tab ─────────────────────────────
function ui.render_profiles(state)
    local locked_runtime = profiles.get_locked_table()

    -- Profile Selection UI
    imgui.Text('Profile:'); imgui.SameLine()
    imgui.PushItemWidth(180)
    local current = ui.selected_profile or '(none)'
    if imgui.BeginCombo('##profile', current) then
        for _, name in ipairs(profiles.names()) do
            if imgui.Selectable(name, name == ui.selected_profile) then
                ui.selected_profile = name
                local loaded = Set(profiles.load(name))
                ui.queue = loaded:diff(locked_runtime)
            end
        end
        imgui.Separator()
        if imgui.Selectable('Load Current Objectives') then
            ui.queue = Set()
            for id in pairs(state.active or {}) do
                if not locked_runtime[id] then
                    ui.queue[id] = true
                end
            end
            ui.sel_master = Set()
            ui.sel_queue  = Set()
        end
        imgui.EndCombo()
    end
    imgui.PopItemWidth(); imgui.SameLine()

    -- Rename / Save / Delete
    imgui.PushItemWidth(180)
    local rb = { ui.profile_rename }
    if imgui.InputText('##rename', rb, 64) then ui.profile_rename = rb[1] end
    imgui.PopItemWidth(); imgui.SameLine()

    if imgui.Button('Save') then
        local tgt = (ui.profile_rename ~= '' and ui.profile_rename) or ui.selected_profile
        if tgt and tgt ~= '' then
            profiles.save_current(tgt, ui.queue)
            log.printf('Profile saved: %s', tgt)
            ui.selected_profile, ui.profile_rename = tgt, ''
        else
            log.warnf('Please Provide a name for the profile.')
        end
    end
    imgui.SameLine()
    if imgui.Button('Delete') and ui.selected_profile then
        profiles.save_current(ui.selected_profile, {})
        ui.selected_profile = nil
        ui.queue = Set()
    end
    imgui.Separator()

    -- Objective count center-aligned
    local text = string.format("Objectives Set: %d / %d", total_selected_count(), POSSIBLE_OBJECTIVE_COUNT)
    imgui.SetCursorPosX((imgui.GetWindowSize() - imgui.CalcTextSize(text)) * 0.5)
    imgui.Text(text)

    -- Global filter and completed toggle
    imgui.Text('Global Filter:'); imgui.SameLine()
    imgui.PushItemWidth(-1)
    local fb = { ui.filter }
    if imgui.InputText('Filter', fb, 64) then ui.filter = fb[1] end
    imgui.PopItemWidth()

    local hc = { ui.hide_completed }
    if imgui.Checkbox('Hide Completed Objectives', hc) then
        ui.hide_completed = hc[1]
    end
    imgui.Spacing()

    -- List layout calculation
    local availW, availH = imgui.GetContentRegionAvail()
    availH = availH - 40
    local border_size, arrowW, arrowH = 19, 40, 32
    local leftW = (availW - 2 * arrowW - border_size * 2) * 0.5
    local halfH = (availH - border_size * 2) * 0.5 - border_size
    local btn = { arrowW, arrowH }

    -- Left Column (Master List)
    imgui.BeginChild('##leftstack', { leftW + border_size, availH }, true)
        ui.sel_master = draw_column('All Objectives', names, ui.sel_master, true,
            function(id)
                return ui.queue[id] or locked_runtime[id] or (ui.hide_completed and (state.complete or {})[id])
            end,
            leftW, availH - border_size, ui.filter)
    imgui.EndChild()
    imgui.SameLine()

    -- Arrows (Middle Column)
    imgui.BeginChild('##arrows', { arrowW + border_size, availH }, true)
        imgui.BeginChild('##arrows1', { arrowW, halfH }, false)
            if imgui.Button('>>', btn) then move(ui.sel_master, {}, add_to_locked) end
            if imgui.Button('<<', btn) then
                for id in pairs(ui.sel_lock) do profiles.remove_locked(id); ui.sel_lock[id] = nil end
            end
        imgui.EndChild()
        imgui.BeginChild('##midarrows', { arrowW, arrowH + border_size }, false); imgui.EndChild()
        imgui.BeginChild('##arrows2', { arrowW, halfH }, false)
            if imgui.Button('>', btn) then move(ui.sel_master, {}, add_to_queue) end
            if imgui.Button('<', btn) then
                for id in pairs(ui.sel_queue) do ui.queue[id], ui.sel_queue[id] = nil, nil end
            end
        imgui.EndChild()
    imgui.EndChild(); imgui.SameLine()

    -- Right Column (Locked & Queue)
    imgui.BeginChild('##rightstack', { -1, availH }, true)
        ui.sel_lock = draw_column('Locked', locked_runtime, ui.sel_lock, false, nil, -1, halfH, nil)
        imgui.BeginChild('##midbtns', { -1, arrowH + border_size }, true)
            if imgui.Button('v', btn) then
                move(ui.sel_lock, {}, function(id)
                    profiles.remove_locked(id); add_to_queue(id)
                end)
            end
            imgui.SameLine()
            if imgui.Button('^', btn) then
                move(ui.sel_queue, ui.queue, function(id) add_to_locked(id) end)
            end
        imgui.EndChild()
        ui.sel_queue = draw_column('Profile Queue', ui.queue, ui.sel_queue, false, nil, -1, -1, nil)
    imgui.EndChild()

    -- Profile Apply Section
    imgui.Spacing()
    imgui.Separator()
    local cb = { ui.show_preview }
    if imgui.Checkbox("Show Preview", cb) then
        ui.show_preview = cb[1]
    end
    imgui.SameLine()
    imgui.SetCursorPosX(imgui.GetWindowSize() - 400)
    if imgui.Button("Apply Profile to Game", { 300, 30 }) then
        if not ui.selected_profile then
            log.warnf("No profile selected to apply.")
        elseif ui.show_preview then
            modal.compute_and_open(ui.selected_profile, state)
        else
            profiles.apply(ui.selected_profile, state)
            log.printf("Applied profile '%s' to game.", ui.selected_profile)
        end
    end
    modal.show(ui.selected_profile, state, names)
end

--──────────────────────────── Single Objectives Tab ─────────────────────
function ui.render_singles(state)
    imgui.Text("Single RoE Objective Manager")
    imgui.Separator()

    local locked = profiles.get_locked_table()
    local active = state.active or {}
    local complete = state.complete or {}
    local filter = ui.filter or ''

    local ids = {}
    for id in pairs(names) do table.insert(ids, id) end
    table.sort(ids)

    local availW, availH = imgui.GetContentRegionAvail()
    local halfW = availW * 0.5 - 10

    -- Left Column: Available
    imgui.BeginChild("##single_left", {halfW, availH}, true)
        imgui.Text("Available Objectives")
        imgui.Separator()
        imgui.Text("Filter:"); imgui.SameLine()
        local fb = { filter }
        if imgui.InputText("##filter", fb, 64) then
            ui.filter = fb[1]; filter = fb[1]
        end
        imgui.Separator()
        for _, id in ipairs(ids) do
            local entry = names[id] or {}
            local name = entry.name or ("[ID %d]"):format(id)
            if not complete[id]
               and (not filter or filter == '' or name:lower():find(filter:lower(), 1, true))
            then
                if locked[id] then
                    imgui.TextDisabled(name .. " (locked)")
                else
                    imgui.Text(name); imgui.SameLine()
                    if active[id] then
                        imgui.TextDisabled("[Active]")
                    elseif imgui.Button("Apply##"..id) then
                        if profiles.debug then log.printf('Applying objective '..id) end
                        pack.send_accept(id)
                    end
                end
            end
        end
    imgui.EndChild()

    imgui.SameLine()

    -- Right Column: Active Objectives
    imgui.BeginChild("##single_right", {-1, availH}, true)
        imgui.Text("Active Objectives")
        imgui.Separator()

        local active_ids = {}
        for id in pairs(active) do table.insert(active_ids, id) end
        table.sort(active_ids)

        imgui.Text(string.format("Active: %d / %d", #active_ids, POSSIBLE_OBJECTIVE_COUNT))
        imgui.Separator()

        for _, id in ipairs(active_ids) do
            local entry = names[id] or {}
            local name = entry.name or ("[ID %d]"):format(id)
            local goal = tonumber(entry.goal) or 1
            local current = tonumber(active[id]) or 0
            local percent = current / goal
            local clamped = math.min(percent, 1.0)
            local label = string.format("%d%%  %s", math.floor(percent * 100), name)
            local color = percent > 1.0 and {1.0, 0.25, 0.25, 1.0} or {0.5, 0.5, 1.0, 1.0}

            imgui.PushStyleColor(ImGuiCol_PlotHistogram, color)
            imgui.ProgressBar(clamped, {imgui.GetContentRegionAvail() - 90, 20}, label)
            if imgui.IsItemHovered() then
                imgui.BeginTooltip()
                imgui.Text(string.format("%d / %d", current, goal))
                imgui.EndTooltip()
            end
            imgui.PopStyleColor()

            imgui.SameLine()
            if locked[id] then
                imgui.TextDisabled("(locked)")
            elseif imgui.Button("Remove##"..id) then
                if profiles.debug then log.printf('Removing objective '..id) end
                pack.send_cancel(id)
            end
        end
    imgui.EndChild()
end

--──────────────────────────── Main Render Loop ──────────────────────────
function ui.render(state, profiles)
    styles.push_theme()
    if not ui.show then return end

    imgui.SetNextWindowSize({ 900, 620 }, ImGuiCond_FirstUseEver)
    local open = { ui.show }
    if not imgui.Begin('roEZ', open) then
        imgui.End(); return
    end

    if imgui.BeginTabBar("roez_tabs") then
        if imgui.BeginTabItem("Profiles") then
            ui.render_profiles(state)
            imgui.EndTabItem()
        end
        if imgui.BeginTabItem("Single Objectives") then
            ui.render_singles(state)
            imgui.EndTabItem()
        end
        imgui.EndTabBar()
    end

    imgui.End()
    styles.pop_theme()
    ui.show = open[1]
end

return ui
