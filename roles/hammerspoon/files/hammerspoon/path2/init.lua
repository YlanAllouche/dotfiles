-- Path 2 keeps native Cmd+1/2/3 in applications and moves workspace switching
-- to a dedicated chord that emits F18/F19/F20.

local state = { hotkeys = {}, watchers = {} }
_G.hammerspoon_path2_state = state

local workspaceModifiers = { "ctrl", "cmd" }

local workspaceSlots = {
  { number = "1", trigger = "f18" },
  { number = "2", trigger = "f19" },
  { number = "3", trigger = "f20" },
}

local function sendWorkspaceTrigger(triggerKey)
  hs.eventtap.keyStroke({}, triggerKey, 0)
end

for _, slot in ipairs(workspaceSlots) do
  local hotkey = hs.hotkey.bind(workspaceModifiers, slot.number, function()
    sendWorkspaceTrigger(slot.trigger)
  end)
  table.insert(state.hotkeys, hotkey)
end
