hs.loadSpoon("WinWin")
hs.loadSpoon("WindowGrid")
hs.loadSpoon("WindowHalfsAndThirds")
hs.loadSpoon("SpoonInstall")

Install=spoon.SpoonInstall

local hyper = {'ctrl', 'option'}

local alert = require 'hs.alert'
local application = require 'hs.application'
local geometry = require 'hs.geometry'
local grid = require 'hs.grid'
local hints = require 'hs.hints'
local hotkey = require 'hs.hotkey'
local layout = require 'hs.layout'
local window = require 'hs.window'
local speech = require 'hs.speech'

-- Init speaker.
speaker = speech.new()

-- Init.
hs.window.animationDuration = 0 -- don't waste time on animation when resize window

-- Key to launch application.
local key2App = {
  i = {'/Applications/iTerm.app', 'English', 2},
  j = {'/Applications/Emacs.app', 'English', 2},
  k = {'/Applications/Google Chrome.app', 'English', 1},
  l = {'/System/Library/CoreServices/Finder.app', 'English', 1},
  c = {'/Applications/Kindle.app', 'English', 2},
  n = {'/Applications/NeteaseMusic.app', 'Chinese', 1},
  w = {'/Applications/WeChat.app', 'Chinese', 1},
  s = {'/Applications/System Preferences.app', 'English', 1},
  d = {'/Applications/Dash.app', 'English', 1},
  b = {'/Applications/MindNode.app', 'Chinese', 1},
  p = {'/Applications/Preview.app', 'Chinese', 2},
  a = {'/Applications/wechatwebdevtools.app', 'English', 2},
}

-- Show launch application's keystroke.
local showAppKeystrokeAlertId = ""

local function showAppKeystroke()
  if showAppKeystrokeAlertId == "" then
    -- Show application keystroke if alert id is empty.
    local keystroke = ""
    local keystrokeString = ""
    for key, app in pairs(key2App) do
      keystrokeString = string.format("%-10s%s", key:upper(), app[1]:match("^.+/(.+)$"):gsub(".app", ""))

      if keystroke == "" then
        keystroke = keystrokeString
      else
        keystroke = keystroke .. "\n" .. keystrokeString
      end
    end

    showAppKeystrokeAlertId = hs.alert.show(keystroke, hs.alert.defaultStyle, hs.screen.mainScreen(), 10)
  else
    -- Otherwise hide keystroke alert.
    hs.alert.closeSpecific(showAppKeystrokeAlertId)
    showAppKeystrokeAlertId = ""
  end
end

hs.hotkey.bind(hyper, "h", showAppKeystroke)

-- Maximize window when specify application started.
local maximizeApps = {
  "/Applications/iTerm.app",
  "/Applications/Emacs.app",
}

local windowCreateFilter = hs.window.filter.new():setDefaultFilter()
windowCreateFilter:subscribe(
  hs.window.filter.windowCreated,
  function (win, ttl, last)
    for index, value in ipairs(maximizeApps) do
      if win:application():path() == value then
        win:maximize()
        return true
      end
    end
end)

-- Manage application's inputmethod status.
local function Chinese()
  hs.keycodes.currentSourceID("com.sogou.inputmethod.sogou.pinyin")
end

local function English()
  hs.keycodes.currentSourceID("com.apple.keylayout.ABC")
end

function findApplication(appPath)
  local apps = application.runningApplications()
  for i = 1, #apps do
    local app = apps[i]
    if app:path() == appPath then
      return app
    end
  end

  return nil
end

function launchApp(appPath)
    application.launchOrFocus(appPath)

    -- Move the application's window to the specified screen.
    for key, app in pairs(key2App) do
    local path = app[1]
    local screenNumber = app[3]

    if appPath == path then
      hs.timer.doAfter(
        1,
        function()
          local app = findApplication(appPath)
          local appWindow = app:mainWindow()

          moveToScreen(appWindow, screenNumber, false)
      end)
      break
    end
  end
end

-- Toggle an application between being the frontmost app, and being hidden
function toggleApplication(app)
  local appPath = app[1]
  local inputMethod = app[2]

  -- Tag app path use for `applicationWatcher'.
  startAppPath = appPath

  local app = findApplication(appPath)
  local setInputMethod = true

  if not app then
    -- Application not running, launch app
    launchApp(appPath)
  else
    -- Application running, toggle hide/unhide
    local mainwin = app:mainWindow()
    if mainwin then
      if app:isFrontmost() then
        -- Show mouse circle if has focus on target application.
        drawMouseCircle()

        setInputMethod = false
      else
        -- Focus target application if it not at frontmost.
        mainwin:application():activate(true)
        mainwin:application():unhide()
        mainwin:focus()
      end
    else
      -- Start application if application is hide.
      if app:hide() then
        launchApp(appPath)
      end
    end
  end

  if setInputMethod then
    if inputMethod == 'English' then
      English()
    else
      Chinese()
    end
  end
end

moveToScreen = function(win, n, showNotify)
  local screens = hs.screen.allScreens()
  if n > #screens then
    if showNotify then
	    hs.alert.show("No enough screens " .. #screens)
    end
  else
    local toScreen = hs.screen.allScreens()[n]:name()
    if showNotify then
	    hs.alert.show("Move " .. win:application():name() .. " to " .. toScreen)
    end
    hs.layout.apply({{nil, win:title(), toScreen, hs.layout.maximized, nil, nil}})
  end
end

function resizeToCenter()
  local win = hs.window.focusedWindow()
  local f = win:frame()
  local screen = win:screen()
  local max = screen:frame()
  local winScale = 0.7

  f.x = max.x + (max.w * (1 - winScale) / 2)
  f.y = max.y + (max.h * (1 - winScale) / 2)
  f.w = max.w * winScale
  f.h = max.h * winScale
  win:setFrame(f)
end

-- Window operations.
hs.hotkey.bind(hyper, 'U', resizeToCenter)

hs.hotkey.bind(
  hyper, "L",
  function()
    window.focusedWindow():moveToUnit(layout.left50)
end)

hs.hotkey.bind(
  hyper, "R",
  function()
    window.focusedWindow():moveToUnit(layout.right50)
end)

-- Start or focus application.
for key, app in pairs(key2App) do
    hotkey.bind(
        hyper, key,
        function()
            toggleApplication(app)
    end)
end

-- Move application to screen.
hs.hotkey.bind(
    hyper, "1",
    function()
        moveToScreen(hs.window.focusedWindow(), 1, true)
end)

hs.hotkey.bind(
    hyper, "2",
    function()
        moveToScreen(hs.window.focusedWindow(), 2, true)
end)

-- Binding key to start plugin.
Install:andUse(
    "WindowHalfsAndThirds",
    {
        config = {use_frame_correctness = true},
        hotkeys = {max_toggle = {hyper, "I"}}
})

Install:andUse(
    "WindowGrid",
    {
        config = {gridGeometries = {{"6x4"}}},
        hotkeys = {show_grid = {hyper, ","}},
        start = true
})

-- Reload config.
hs.hotkey.bind(
    hyper, "'", function ()
        speaker:speak("Offline to reloading...")
        hs.reload()
end)

-- We put reload notify at end of config, notify popup mean no error in config.
hs.notify.new({title="Manatee", informativeText="Andy, I am online!"}):send()

-- Speak something after configuration success.
speaker:speak("Andy, I am online!")
