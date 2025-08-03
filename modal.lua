--------------------------------------------------------------------------------
--  modal.lua  –  Apply Profile Preview Modal
--
--  Handles the modal popup UI for confirming changes when applying a profile.
--  Compares the current active objectives with the selected profile and
--  displays additions/removals. Also handles confirmation and cancellation.
--
--  Public API:
--      modal.show_preview         → bool: toggle checkbox flag (external)
--      modal.compute_diffs(profile, state)
--      modal.compute_and_open(profile, state)
--      modal.show(profile, state, names)
--------------------------------------------------------------------------------

--──────────────────────────── Dependencies ──────────────────────────────
local imgui    = require('imgui')
local profiles = require('profiles')
local log      = require('log')
local utils    = require('utils')
local pack     = require('packets')
local Set      = require('set')

--──────────────────────────── Module State ──────────────────────────────
local modal = {
    show_preview = true,          -- toggle for displaying modal
    modal_open   = false,         -- internal flag to trigger modal
    should_close = false,         -- flag for whether modal should close
    modal_diffs  = {              -- calculated adds/removes
        add = {},
        remove = {}
    },
}

--──────────────────────────── Difference Calculation ────────────────────
-- Determines which objectives need to be added or removed.
function modal.compute_diffs(selected_profile, state)
    local have   = state.active or {}
    local want   = Set(profiles.load(selected_profile)) or {}
    local locked = profiles.get_locked_table()

    have   = utils.as_set(have)
    want   = utils.as_set(want)
    locked = utils.as_set(locked)

    local add, remove = {}, {}

    for id in pairs(want) do
        if not have[id] then
            table.insert(add, id)
        end
    end

    for id in pairs(have) do
        if not want[id] and not locked[id] then
            table.insert(remove, id)
        end
    end

    modal.modal_diffs = { add = add, remove = remove }
    modal.should_close = false
end

-- Wrapper that triggers a recompute and flags modal to open
function modal.compute_and_open(selected_profile, state)
    modal.compute_diffs(selected_profile, state)
    modal.modal_open = true
end

--──────────────────────────── Modal UI Renderer ─────────────────────────
-- Draws the popup modal, showing adds/removals and handling buttons.
function modal.show(selected_profile, state, names)
    if modal.modal_open then
        imgui.OpenPopup("Apply Profile Preview")
        modal.modal_open = false
    end

    if imgui.BeginPopupModal("Apply Profile Preview", nil, ImGuiWindowFlags_AlwaysAutoResize) then
        imgui.Text("This will update your active objectives:")
        imgui.Separator()

        if #modal.modal_diffs.add > 0 then
            imgui.Text("To Add:")
            for _, id in ipairs(modal.modal_diffs.add) do
                imgui.BulletText(utils.obj_name(id))
            end
        end

        if #modal.modal_diffs.remove > 0 then
            imgui.Text("To Remove:")
            for _, id in ipairs(modal.modal_diffs.remove) do
                imgui.BulletText(utils.obj_name(id))
            end
        end

        imgui.Separator()

        if imgui.Button("Apply Changes") then
            modal.should_close = true
            imgui.CloseCurrentPopup()
            profiles.apply(selected_profile, state)
            log.printf("Applied profile '%s' to game.", selected_profile)
        end

        imgui.SameLine()

        if imgui.Button("Cancel") then
            modal.should_close = true
            imgui.CloseCurrentPopup()
            log.printf("Cancelled profile application.")
        end

        imgui.EndPopup()

        if modal.should_close then
            imgui.CloseCurrentPopup()
        end
    end
end

return modal
