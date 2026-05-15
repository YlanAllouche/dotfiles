-- Change this to "path2" to test the alternate workspace strategy.
local activeVariant = "path1"

local variants = {
  path1 = hs.configdir .. "/path1/init.lua",
  path2 = hs.configdir .. "/path2/init.lua",
}

local function cleanupState(state)
  if not state then
    return
  end

  for _, watcher in ipairs(state.watchers or {}) do
    watcher:stop()
  end

  for _, hotkey in ipairs(state.hotkeys or {}) do
    hotkey:disable()
  end
end

cleanupState(_G.hammerspoon_path1_state)
cleanupState(_G.hammerspoon_path2_state)

local selectedVariantPath = variants[activeVariant]
if not selectedVariantPath then
  error("Unknown Hammerspoon variant: " .. tostring(activeVariant))
end

dofile(selectedVariantPath)
