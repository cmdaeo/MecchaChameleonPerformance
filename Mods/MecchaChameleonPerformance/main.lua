--[[
    MecchaChameleonPerformance - Config-driven performance mod
    F1 = Enable (apply user config), F2 = Disable (restore captured original).
    User config on Desktop is ONLY written if missing - never overwrites user edits.
    Original config is ALWAYS re-captured fresh every time the mod loads,
    since mod load = assumed fresh game startup. No timers used.
--]]

local UEHelpers = require("UEHelpers")

print("[MecchaChameleonPerformance] Script loading\n")

-- ============================================================
-- PATHS
-- ============================================================
local function GetDesktopPath(filename)
    local home = os.getenv("USERPROFILE") or os.getenv("HOME")
    return home .. "\\Desktop\\" .. filename
end

local UserConfigPath = GetDesktopPath("performance_chameleon_mod.txt")

local ModDir = debug.getinfo(1, "S").source:match("^@(.*[\\/])") or "./"
local OriginalConfigPath = ModDir .. "original_config.dat"

local ModEnabled = false
local OriginalCaptured = false -- guards against re-capturing multiple times within the SAME session
                                -- (e.g. ClientRestart firing again on respawn), but the file itself
                                -- is still freshly overwritten once per game launch.

-- ============================================================
-- KISMET SYSTEM LIBRARY HELPERS
-- ============================================================
local function GetKSL()
    local ok, ksl = pcall(function()
        return StaticFindObject("/Script/Engine.Default__KismetSystemLibrary")
    end)
    if ok and ksl and ksl:IsValid() then return ksl end
    return nil
end

local function ExecCmd(cvar, value)
    local cmd = value ~= nil and (cvar .. " " .. tostring(value)) or cvar
    local ok, err = pcall(function()
        local PC = UEHelpers.GetPlayerController()
        local ksl = GetKSL()
        if PC and PC:IsValid() and ksl then
            ksl:ExecuteConsoleCommand(PC:GetWorld(), cmd, PC)
        else
            print(string.format("[MecchaChameleonPerformance] Missing PC or KismetSystemLibrary, skipped: %s\n", cmd))
        end
    end)
    if not ok then
        print(string.format("[MecchaChameleonPerformance] ExecCmd error for '%s': %s\n", cmd, tostring(err)))
    end
end

local function ReadCVarLiveValue(cvar)
    local ksl = GetKSL()
    if not ksl then
        print("[MecchaChameleonPerformance] KismetSystemLibrary not found\n")
        return nil
    end

    local okFloat, floatVal = pcall(function()
        return ksl:GetConsoleVariableFloatValue(cvar)
    end)

    if okFloat and floatVal ~= nil then
        return tostring(floatVal)
    end

    print(string.format("[MecchaChameleonPerformance] Could not read cvar '%s': ok=%s\n", cvar, tostring(okFloat)))
    return nil
end

-- ============================================================
-- CONFIG PARSER
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
-- CAPTURE ORIGINAL VALUES FROM THE LIVE GAME
-- ALWAYS overwrites original_config.dat on every mod load, since a mod
-- load is assumed to mean the game just started fresh. Only runs ONCE
-- per session though (OriginalCaptured guard), in case the triggering
-- hook fires more than once (e.g. player respawn).
-- ============================================================
local function CaptureOriginalConfig()
    if OriginalCaptured then return end

    local userPairs = ParseConfigFile(UserConfigPath)
    if not userPairs then
        print("[MecchaChameleonPerformance] Cannot capture original config: user config missing.\n")
        return
    end

    local out = io.open(OriginalConfigPath, "w") -- always overwrite, fresh game session
    if not out then
        print("[MecchaChameleonPerformance] ERROR: could not write hidden original config.\n")
        return
    end

    out:write("; Auto-captured live game values (this game session). Do not edit. Do not delete.\n")
    local capturedCount = 0
    for _, entry in ipairs(userPairs) do
        local liveValue = ReadCVarLiveValue(entry.cvar)
        if liveValue then
            out:write(string.format("%s=%s\n", entry.cvar, liveValue))
            capturedCount = capturedCount + 1
        else
            print(string.format("[MecchaChameleonPerformance] Could not capture live value for %s, will skip on restore.\n", entry.cvar))
        end
    end
    out:close()

    OriginalCaptured = true
    print(string.format("[MecchaChameleonPerformance] Captured %d/%d cvars (fresh) -> %s\n", capturedCount, #userPairs, OriginalConfigPath))
end

-- ============================================================
-- WRITE USER CONFIG - ONLY if missing. This file belongs to the user;
-- their edits must persist across every future launch.
-- ============================================================
local function WriteUserConfigIfMissing()
    local existing = io.open(UserConfigPath, "r")
    if existing then
        existing:close()
        print("[MecchaChameleonPerformance] User config already exists, leaving it untouched -> " .. UserConfigPath .. "\n")
        return
    end

    local f = io.open(UserConfigPath, "w")
    if not f then
        print("[MecchaChameleonPerformance] ERROR: could not create user config on Desktop.\n")
        return
    end
    f:write([[
; ============================================================
; MECCHA CHAMELEON PERFORMANCE MOD - USER CONFIG
; ============================================================
; GOAL: Maximum FPS on LOW-END / OLDER PCs. Visuals are secondary.
; Game stays playable and readable, but looks plain/flat by design.
;
; HOW TO USE:
;   1. Edit any value below, then save this file.
;   2. Press F1 in-game to apply these settings.
;   3. Press F2 to restore the game's original settings.
;   4. Lines starting with ; are comments/explanations, ignored by the mod.
;
; NOTE: This file is ONLY created once, the first time the mod ever loads.
; Your edits are safe and will persist across every future launch.
; ============================================================

; ---- FRAMERATE ----
t.MaxFPS=0
; 0 = uncapped. Set a number (e.g. 60) to cap FPS and reduce heat/power draw.

; ---- RESOLUTION ----
r.ScreenPercentage=70
; Render resolution %. Biggest single FPS gain here. Lower = blurrier, faster.

; ---- SHADOWS ----
r.ShadowQuality=0
; 0 = lowest/blockiest, fastest. Range 0-5.
r.Shadow.MaxResolution=512
; Shadow map texture size. Lower = blockier edges, faster.
r.Shadow.Virtual.Enable=0
; Newer heavier shadow tech. Keep OFF on low-end PCs.
r.Shadow.PerObject=0
; Character/object dynamic shadows. 0=off (saves GPU), 1=on.

; ---- GLOBAL ILLUMINATION / LUMEN ----
r.Lumen.DiffuseIndirect.Allow=0
; Dynamic bounced lighting. 0=off, flatter but big FPS gain.
r.Lumen.Reflections.Allow=0
; Dynamic reflections on shiny surfaces. 0=off, faster.
r.Lumen.HardwareRayTracing=0
; Keep 0 always on low-end PCs.

; ---- RAY TRACING ----
r.RayTracing=0
r.RayTracing.Shadows=0

; ---- POST-PROCESS (purely cosmetic) ----
r.MotionBlurQuality=0
r.MotionBlur.Amount=0.0
r.BloomQuality=0
r.DepthOfFieldQuality=0
r.FilmGrain=0
r.Tonemapper.Quality=0
r.Tonemapper.Sharpen=0.0
r.SceneColorFringeQuality=0
r.SceneColorFringe.Max=0

; ---- ANTI-ALIASING ----
r.AntiAliasingMethod=1
; 0=off, 1=FXAA (cheap, recommended), 2=TAA, 3=MSAA, 4=TSR (most expensive).

; ---- GEOMETRY DETAIL ----
r.Nanite.MaxPixelsPerEdge=4.0
; Higher = less geometry detail required, faster.
r.SkeletalMeshLODBias=2
; Characters use lower detail sooner. Higher = faster.
r.ViewDistanceScale=0.6
; How far objects render before disappearing/simplifying. Lower = faster.
foliage.LODDistanceScale=0.5
; Same as above but for grass/trees. Lower = faster.

; ---- OCCLUSION CULLING ----
r.HZBOcclusion=1
; Skips rendering hidden objects. ALWAYS keep 1, free performance.

; ---- TEXTURE STREAMING / VRAM ----
r.Streaming.PoolSize=800
; VRAM (MB) reserved for streaming textures. Lower = less VRAM used.
r.Streaming.LimitPoolSizeToVRAM=1
; Prevents exceeding actual VRAM. Keep 1 on low-VRAM GPUs.
r.Streaming.MaxTempMemoryAllowed=100
; Extra temp memory during streaming spikes. Lower = less RAM/VRAM use.
r.Streaming.FramesForFullUpdate=2
; Frames spread across for texture loading. Lower = faster load, more CPU/frame.

; ---- MEMORY / GARBAGE COLLECTION ----
gc.TimeBetweenPurgingPendingKillObjects=20
; How often unused memory is cleaned (seconds). Lower = better for low-RAM systems.

; ---- INPUT LATENCY ----
r.GTSyncType=1
; Lower input lag, slightly less GPU parallelism. Recommended.
r.OneFrameThreadLag=0
; 0 = most responsive. 1 = slightly more FPS, slightly more input lag.

; ---- PARTICLES / VFX ----
fx.Niagara.QualityLevel=0
; Particle effect quality/count. 0 = lowest, fastest.

; ---- HAIR STRANDS ----
r.HairStrands.Enable=0
; Strand-based hair rendering. 0=off (uses simpler fallback), faster.
]])
    f:close()
    print("[MecchaChameleonPerformance] User config created on Desktop (first run) -> " .. UserConfigPath .. "\n")
end

-- ============================================================
-- HOTKEYS
-- ============================================================
RegisterKeyBind(Key.F1, function()
    if ModEnabled then
        print("[MecchaChameleonPerformance] Already enabled, skipping re-apply.\n")
        return
    end
    local pairsList = ParseConfigFile(UserConfigPath)
    if pairsList then
        ApplyPairs(pairsList, "USER CONFIG (ENABLED)")
        ModEnabled = true
    else
        print("[MecchaChameleonPerformance] Could not read user config file.\n")
    end
end)

RegisterKeyBind(Key.F2, function()
    if not ModEnabled then
        print("[MecchaChameleonPerformance] Already at original settings.\n")
        return
    end
    local pairsList = ParseConfigFile(OriginalConfigPath)
    if pairsList then
        ApplyPairs(pairsList, "ORIGINAL CONFIG (DISABLED)")
        ModEnabled = false
    else
        print("[MecchaChameleonPerformance] No captured original config found, cannot restore.\n")
    end
end)

-- ============================================================
-- INIT - create user config only if missing
-- mod load == assumed fresh game startup.
-- ============================================================
WriteUserConfigIfMissing()
CaptureOriginalConfig()

print("[MecchaChameleonPerformance] Loaded.\n")
print("[MecchaChameleonPerformance] F1 = Enable, F2 = Disable/Restore original.\n")
