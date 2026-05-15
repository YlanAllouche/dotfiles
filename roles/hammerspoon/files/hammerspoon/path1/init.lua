-- Path 1 reclaims Cmd+1/2/3 for workspace switching through F18/F19/F20.
-- When Chrome is focused, Ctrl+1/2/3 forwards back to Chrome as Cmd+1/2/3.

local state = { hotkeys = {}, chromeHotkeys = {}, watchers = {} }
_G.hammerspoon_path1_state = state

local workspaceSlots = {
  { number = "1", trigger = "f18" },
  { number = "2", trigger = "f19" },
  { number = "3", trigger = "f20" },
}

local chromeBundleID = "com.google.Chrome"

local function sendWorkspaceTrigger(triggerKey)
  hs.eventtap.keyStroke({}, triggerKey, 0)
end

local function forwardNumberToChrome(number)
  local app = hs.application.frontmostApplication()
  if not app or app:bundleID() ~= chromeBundleID then
    return
  end

  hs.eventtap.keyStroke({ "cmd" }, number, 0, app)
end

local function setChromeHotkeysEnabled(enabled)
  for _, hotkey in ipairs(state.chromeHotkeys) do
    if enabled then
      hotkey:enable()
    else
      hotkey:disable()
    end
  end
end

for _, slot in ipairs(workspaceSlots) do
  local hotkey = hs.hotkey.bind({ "cmd" }, slot.number, function()
    sendWorkspaceTrigger(slot.trigger)
  end)
  table.insert(state.hotkeys, hotkey)
end

for _, slot in ipairs(workspaceSlots) do
  local hotkey = hs.hotkey.new({ "ctrl" }, slot.number, function()
    forwardNumberToChrome(slot.number)
  end)
  hotkey:disable()
  table.insert(state.hotkeys, hotkey)
  table.insert(state.chromeHotkeys, hotkey)
end

local watcher = hs.application.watcher.new(function(_, eventType, app)
  if eventType == hs.application.watcher.activated then
    setChromeHotkeysEnabled(app and app:bundleID() == chromeBundleID)
    return
  end

  if eventType == hs.application.watcher.deactivated and app and app:bundleID() == chromeBundleID then
    setChromeHotkeysEnabled(false)
  end
end)

watcher:start()
table.insert(state.watchers, watcher)

local frontmostApp = hs.application.frontmostApplication()
setChromeHotkeysEnabled(frontmostApp and frontmostApp:bundleID() == chromeBundleID)
