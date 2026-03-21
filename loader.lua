--[[
    Quantum X  –  loader.lua  v1.6.6
    Usage:
        loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/shadeflux/QuantumX-MM2/main/loader.lua"
        ))()
]]

if getgenv().QuantumX_Loader_Loaded then
    warn("[QuantumX] Loader already running – skipping duplicate.")
    return
end
getgenv().QuantumX_Loader_Loaded = true

-- ── Constants ──────────────────────────────────────────
local VERSION      = "v1.6.6"
local MM2_PLACE_ID = 142823291
local MM2_URL      = "https://raw.githubusercontent.com/shadeflux/QuantumX-MM2/main/mm2.lua"
local WINDUI_URLS  = {
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/source.lua",
}

-- ── Services ───────────────────────────────────────────
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

-- ── Global config  (shared with mm2.lua) ──────────────
getgenv().QuantumX_Config = {
    speedEnabled  = false,
    speedValue    = 16,
    noclipEnabled = false,
}

-- ── Helpers ────────────────────────────────────────────
local function getChar()     return lp.Character end
local function getHumanoid() local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end

local function safeHttp(url)
    local ok, r = pcall(function() return game:HttpGet(url) end)
    return ok, r
end
local function safeExec(src)
    local ok, fn = pcall(loadstring, src)
    if not ok or type(fn) ~= "function" then return false, tostring(fn) end
    local ok2, e = pcall(fn)
    return ok2, tostring(e)
end

-- ── Universal loops  (every game) ─────────────────────
task.spawn(function()
    while true do
        if getgenv().QuantumX_Config.speedEnabled then
            local h = getHumanoid()
            if h then h.WalkSpeed = getgenv().QuantumX_Config.speedValue end
        end
        task.wait()
    end
end)

RunService.Stepped:Connect(function()
    if getgenv().QuantumX_Config.noclipEnabled then
        local c = getChar()
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)

-- ── Load WindUI ────────────────────────────────────────
local WindUI
for i, url in ipairs(WINDUI_URLS) do
    print(string.format("[QuantumX] WindUI attempt %d/%d …", i, #WINDUI_URLS))
    local okH, src = safeHttp(url)
    if not okH or type(src) ~= "string" or #src < 100 then
        warn("[QuantumX] HTTP fail #"..i); continue
    end
    local okC, fn = pcall(loadstring, src)
    if not okC or type(fn) ~= "function" then
        warn("[QuantumX] Compile fail #"..i); continue
    end
    local okE, lib = pcall(fn)
    if not okE or lib == nil then
        warn("[QuantumX] Exec fail #"..i..": "..tostring(lib)); continue
    end
    WindUI = lib
    print("[QuantumX] ✅ WindUI loaded (URL #"..i..").")
    break
end

if not WindUI then
    warn("[QuantumX] ❌ WindUI unavailable. Speed/Noclip still active, no GUI.")
    return
end
getgenv().QuantumX_WindUI = WindUI

-- ── Purple theme ───────────────────────────────────────
pcall(function()
    WindUI:SetTheme({
        SchemeColor  = Color3.fromHex("#7C3AED"),
        Background   = Color3.fromHex("#0D0D14"),
        Header       = Color3.fromHex("#13131F"),
        TextColor    = Color3.fromRGB(230, 220, 255),
        ElementColor = Color3.fromHex("#1A1A2E"),
    })
end)
pcall(function() WindUI:SetAccent(Color3.fromHex("#7C3AED")) end)

-- ── Create window ──────────────────────────────────────
local Window
do
    local ok, r = pcall(function()
        return WindUI:CreateWindow({
            Title    = "Quantum X",
            SubTitle = "discord.gg/2W2MUCEDCB",
            Size     = UDim2.new(0, 580, 0, 540),
        })
    end)
    if not ok or r == nil then
        warn("[QuantumX] ❌ Window creation failed: "..tostring(r)); return
    end
    Window = r
    getgenv().QuantumX_Window = Window
    print("[QuantumX] ✅ GUI window ready.")
end

pcall(function()
    Window:Tag({
        Title  = VERSION,
        Icon   = "discord",
        Color  = Color3.fromHex("#7C3AED"),
        Radius = 13,
    })
end)

-- ── Tab: Universal ─────────────────────────────────────
local UTab = Window:Tab({ Title = "Universal", Icon = "rbxassetid://4483362458" })

UTab:Section({ Title = "⚡ Movement" })
UTab:Toggle({
    Title    = "Speed Hack",
    Default  = false,
    Callback = function(v)
        getgenv().QuantumX_Config.speedEnabled = v
        if getgenv().MM2Config then getgenv().MM2Config.speedEnabled = v end
    end,
})
UTab:Slider({
    Title    = "Walk Speed",
    Min      = 16, Max = 350, Default = 16,
    Callback = function(v)
        getgenv().QuantumX_Config.speedValue = v
        if getgenv().MM2Config then getgenv().MM2Config.speedValue = v end
    end,
})
UTab:Toggle({
    Title    = "Noclip",
    Default  = false,
    Callback = function(v)
        getgenv().QuantumX_Config.noclipEnabled = v
        if getgenv().MM2Config then getgenv().MM2Config.noclipEnabled = v end
    end,
})

UTab:Section({ Title = "🛠️ Misc" })
UTab:Button({
    Title    = "Rejoin Server",
    Callback = function()
        pcall(function()
            game:GetService("TeleportService"):Teleport(game.PlaceId, lp)
        end)
    end,
})

UTab:Section({ Title = "🔧 Dev Tools" })
UTab:Button({ Title = "Infinite Yield", Callback = function()
    local ok, s = safeHttp("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source")
    if ok then safeExec(s) end
end })
UTab:Button({ Title = "Dex Explorer", Callback = function()
    local ok, s = safeHttp("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua")
    if ok then safeExec(s) end
end })
UTab:Button({ Title = "SimpleSpy", Callback = function()
    local ok, s = safeHttp("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpyBeta.lua")
    if ok then safeExec(s) end
end })

-- ── Tab: MM2 Loader ────────────────────────────────────
local MM2Tab        = Window:Tab({ Title = "MM2", Icon = "rbxassetid://4483362458" })
local isInMM2       = (game.PlaceId == MM2_PLACE_ID)
local mm2Attempted  = false

MM2Tab:Section({ Title = "🎮 Status" })
if isInMM2 then
    MM2Tab:Paragraph({ Title = "✅ Murder Mystery 2 detected!", Content = "MM2 features will load automatically in 3 seconds." })
else
    MM2Tab:Paragraph({ Title = "⚠️ Not in Murder Mystery 2", Content = "PlaceId: "..tostring(game.PlaceId).."  |  Required: "..tostring(MM2_PLACE_ID) })
    MM2Tab:Paragraph({ Title = "MM2 features are locked.", Content = "Join Murder Mystery 2 to unlock all features." })
end

MM2Tab:Section({ Title = "📦 Script" })

local function loadMM2()
    if mm2Attempted then warn("[QuantumX] mm2.lua already loaded."); return end
    if not isInMM2 then warn("[QuantumX] ⛔ Blocked – not in MM2."); return end
    mm2Attempted = true
    print("[QuantumX] Fetching mm2.lua from GitHub…")
    local okH, src = safeHttp(MM2_URL)
    if not okH then
        warn("[QuantumX] ❌ HTTP error: "..tostring(src))
        MM2Tab:Paragraph({ Title = "❌ Download failed.", Content = tostring(src):sub(1, 80) })
        mm2Attempted = false; return
    end
    local okE, err = safeExec(src)
    if okE then
        print("[QuantumX] ✅ mm2.lua executed successfully!")
    else
        warn("[QuantumX] ❌ mm2.lua runtime error: "..tostring(err))
        MM2Tab:Paragraph({ Title = "❌ Execution error.", Content = tostring(err):sub(1, 80) })
        mm2Attempted = false
    end
end

MM2Tab:Button({
    Title    = isInMM2 and "▶  Load MM2 Features" or "⛔  Available in MM2 only",
    Callback = loadMM2,
})

if isInMM2 then
    task.delay(3, function()
        if not getgenv().QuantumX_MM2_Loaded then loadMM2() end
    end)
end

print("[QuantumX] ✅ Loader "..VERSION.." fully initialized.")
