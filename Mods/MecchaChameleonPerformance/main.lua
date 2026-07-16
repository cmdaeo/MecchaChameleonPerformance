--[[
    MecchaChameleonPerformance - Config-driven
    Original config is captured from the LIVE game (not guessed defaults) (WIP) and stored
    hidden inside the mod's own folder, not on Desktop.
    Two hotkeys: F1 = Enable (user config), F2 = Disable (restore captured original).
--]]

local UEHelpers = require("UEHelpers")

-- ============================================================
-- PATHS
-- ============================================================
local function GetDesktopPath(filename)
    local home = os.getenv("USERPROFILE") or os.getenv("HOME")
    return home .. "\\Desktop\\" .. filename
end

local UserConfigPath = GetDesktopPath("performance_chameleon_mod.txt")

-- Hidden original config lives inside the mod's own folder, not Desktop
local ModDir = debug.getinfo(1, "S").source:match("^@(.*[\\/])") or "./"
local OriginalConfigPath = ModDir .. "original_config.dat"

-- Path to the game's live log file (auto-detected via UE4SS game directory API)
local function FindGameLogPath()
    local dirs = IterateGameDirectories()
    if not dirs or not dirs.Game then return nil end
    -- Logs typically live at <GameRoot>/<ProjectName>/Saved/Logs/<ProjectName>.log
    -- We search common relative paths since project folder name varies per build
    local candidates = {
        dirs.Game.__absolute_path .. "\\..\\..\\Saved\\Logs",
        dirs.Game.__absolute_path .. "\\Saved\\Logs",
    }
    for _, dir in ipairs(candidates) do
        local test = io.open(dir, "r")
        if test then test:close() end
    end
    return dirs.Game.__absolute_path .. "\\..\\..\\Saved\\Logs"
end

local GameLogDir = FindGameLogPath()

local CVarList = {} -- populated when parsing the user config, in order
local ModEnabled = false

-- ============================================================
-- CONSOLE EXEC
-- ============================================================
local function ExecCmd(cvar, value)
    local cmd = value ~= nil and (cvar .. " " .. tostring(value)) or cvar
    local ok, err = pcall(function()
        local PC = UEHelpers.GetPlayerController()
        local KismetSystemLibrary = StaticFindObject("/Script/Engine.Default__KismetSystemLibrary")
        if PC and PC:IsValid() and KismetSystemLibrary then
            KismetSystemLibrary:ExecuteConsoleCommand(PC:GetWorld(), cmd, PC)
        else
            print(string.format("[MecchaChameleonPerformance] Missing PC or KismetSystemLibrary, skipped: %s\n", cmd))
        end
    end)
    if not ok then
        print(string.format("[MecchaChameleonPerformance] ExecCmd error for '%s': %s\n", cmd, tostring(err)))
    end
end

-- ============================================================
-- READ CVAR'S CURRENT VALUE BY LOG PARSING
-- Issues "cvarname" with no value, then tails the newest log file
-- looking for the "CVarName = value" response line the engine prints.
-- ============================================================
local function FindNewestLogFile()
    if not GameLogDir then return nil end
    local handle = io.popen('dir "' .. GameLogDir .. '\\*.log" /b /o-d 2>nul')
    if not handle then return nil end
    local newest = handle:read("*l")
    handle:close()
    if not newest then return nil end
    return GameLogDir .. "\\" .. newest
end

local function ReadCVarLiveValue(cvar, logPath)
    ExecCmd(cvar, nil) -- no value = query mode, forces engine to log current value

    local f = io.open(logPath, "r")
    if not f then return nil end

    local content = f:read("*a")
    f:close()

    -- Engine prints lines like: LogConsoleResponse: Display: CVarName = "100.000"
    -- Search from the end for the most recent matching line
    local pattern = cvar:gsub("([%.%%])", "%%%1") .. '%s*=%s*"?([%-%d%.]+)"?'
    local lastMatch = nil
    for line in content:gmatch("[^\r\n]+") do
        local m = line:match(pattern)
        if m then lastMatch = m end
    end
    return lastMatch
end

-- ============================================================
-- CONFIG PARSER - reads cvar=value lines, ignores ; comments and blanks
-- ============================================================
local function ParseConfigFile(path)
    local pairsOut = {}
    local f = io.open(path, "r")
    if not f then return nil end
    for line in f:lines() do
        local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
        if trimmed ~= "" and trimmed:sub(1, 1) ~= ";" then
            local cvar, value = trimmed:match("^([%w%.%_]+)%s*=%s*(.+)$")
            if cvar and value then
                value = value:gsub("%s*;.*$", ""):gsub("%s+$", "")
                table.insert(pairsOut, { cvar = cvar, value = value })
            end
        end
    end
    f:close()
    return pairsOut
end

local function ApplyPairs(pairsList, label)
    for _, entry in ipairs(pairsList) do
        ExecCmd(entry.cvar, entry.value)
    end
    print(string.format("[MecchaChameleonPerformance] %s applied (%d cvars)\n", label, #pairsList))
end

-- ============================================================
-- CAPTURE ORIGINAL VALUES FROM THE LIVE GAME (runs once, before ApplyAll ever fires)
-- ============================================================
local function CaptureOriginalConfig()
    local existing = io.open(OriginalConfigPath, "r")
    if existing then existing:close(); return end -- already captured, never overwrite

    local userPairs = ParseConfigFile(UserConfigPath)
    if not userPairs then
        print("[MecchaChameleonPerformance] Cannot capture original config: user config missing.\n")
        return
    end

    local logPath = FindNewestLogFile()
    if not logPath then
        print("[MecchaChameleonPerformance] WARNING: could not locate game log file, falling back to defaults.\n")
    end

    local out = io.open(OriginalConfigPath, "w")
    if not out then
        print("[MecchaChameleonPerformance] ERROR: could not write hidden original config.\n")
        return
    end

    out:write("; Auto-captured live game values. Do not edit. Do not delete.\n")
    for _, entry in ipairs(userPairs) do
        local liveValue = logPath and ReadCVarLiveValue(entry.cvar, logPath) or nil
        if liveValue then
            out:write(string.format("%s=%s\n", entry.cvar, liveValue))
        else
            print(string.format("[MecchaChameleonPerformance] Could not capture live value for %s, will skip on restore.\n", entry.cvar))
        end
    end
    out:close()
    print("[MecchaChameleonPerformance] Original config captured from live game -> " .. OriginalConfigPath .. "\n")
end

-- ============================================================
-- WRITE USER CONFIG (only if missing)
-- ============================================================
local function WriteUserConfigIfMissing()
    local f = io.open(UserConfigPath, "r")
    if f then f:close(); return end

    f = io.open(UserConfigPath, "w")
    if not f then return end
    f:write([[
; ============================================================
; MECCHA CHAMELEON MecchaChameleonPerformance - USER CONFIG
; Edit values, save, press F1 in-game to apply.
; F2 disables and restores this game's ORIGINAL captured values.
; Lines starting with ; are comments.
; ============================================================

r.ScreenPercentage=100          ; render resolution %, lower = more FPS, blurrier
r.ShadowQuality=3               ; 0=off 1=low 2=med 3=high
r.Shadow.MaxResolution=1536     ; max shadow map texture resolution
r.Shadow.Virtual.Enable=1       ; 1=virtual shadow maps, 0=off for max FPS
r.Shadow.PerObject=1            ; 1=character shadows on, 0=off
r.Lumen.DiffuseIndirect.Allow=1 ; 1=Lumen GI on, 0=off (FPS gain)
r.Lumen.Reflections.Allow=1
r.MotionBlurQuality=0
r.MotionBlur.Amount=0.0
r.BloomQuality=3
r.DepthOfFieldQuality=0
r.AntiAliasingMethod=2          ; 0=none 1=FXAA 2=TAA 3=TSR
t.MaxFPS=0
r.ViewDistanceScale=1.0
r.Foliage.LODDistanceScale=1.0
r.SkeletalMeshLODBias=0
r.Nanite.MaxPixelsPerEdge=1.0
r.VT.MaxAnisotropy=8
r.HZBOcclusion=1
r.ParticleLightingWithoutProxies=1
r.Streaming.PoolSize=1000
r.Streaming.PoolSizeVRAMPercentage=0 ; 0=unlimited, removes 70% VRAM cap
r.Streaming.LimitPoolSizeToVRAM=1
r.Streaming.MaxTempMemoryAllowed=500
r.Streaming.FramesForFullUpdate=2
gc.TimeBetweenPurgingPendingKillObjects=30
r.GTSyncType=1                  ; game thread syncs to RHI thread, lowers input lag
r.OneFrameThreadLag=0
r.FilmGrain=0
r.Tonemapper.GrainQuantization=0
r.SceneColorFringeQuality=0
r.SceneColorFringe.Max=0
r.Tonemapper.Quality=1
r.Tonemapper.Sharpen=0.5
au.DisableHRTF=0
au.BinauralSpatializationEnabled=1
au.DisableOcclusion=0
au.3dVisualize.Enabled=0
p.NetworkSmoothingFactor=0
]])
    f:close()
    print("[MecchaChameleonPerformance] User config created on Desktop.\n")
end

-- ============================================================
-- HOTKEYS
-- ============================================================
RegisterKeyBind(Key.F1, function()
    local pairsList = ParseConfigFile(UserConfigPath)
    if pairsList then ApplyPairs(pairsList, "USER CONFIG (ENABLED)"); ModEnabled = true end
end)

RegisterKeyBind(Key.F2, function()
    local pairsList = ParseConfigFile(OriginalConfigPath)
    if pairsList then ApplyPairs(pairsList, "ORIGINAL CONFIG (DISABLED)"); ModEnabled = false
    else print("[MecchaChameleonPerformance] No captured original config found, cannot restore.\n") end
end)

-- ============================================================
-- INIT - capture original BEFORE any ApplyAll ever runs
-- ============================================================
WriteUserConfigIfMissing()
ExecuteWithDelay(2000, function()
    CaptureOriginalConfig() -- delayed so PlayerController/World are guaranteed valid
end)

print("[MecchaChameleonPerformance] Loaded.\n")
print("[MecchaChameleonPerformance] F1 = Enable, F2 = Disable/Restore original.\n")
