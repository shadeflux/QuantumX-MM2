--[[
    Quantum X  –  mm2.lua  v1.6.6
    Murder Mystery 2 – full feature set.
    Works standalone OR loaded via loader.lua.

    Standalone usage:
        loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/shadeflux/QuantumX-MM2/main/mm2.lua"
        ))()
]]

if getgenv().QuantumX_MM2_Loaded then
    warn("[QuantumX MM2] Already loaded – skipping duplicate.")
    return
end
getgenv().QuantumX_MM2_Loaded = true

-- ── Constants ──────────────────────────────────────────
local VERSION      = "v1.6.6"
local MM2_PLACE_ID = 142823291
if game.PlaceId ~= MM2_PLACE_ID then
    warn(string.format("[QuantumX MM2] ⚠️ PlaceId %d ≠ %d. Some features may not work.",
        game.PlaceId, MM2_PLACE_ID))
end

-- ── Services ───────────────────────────────────────────
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp                = Players.LocalPlayer

-- ── MM2 Config ─────────────────────────────────────────
getgenv().MM2Config = {
    espEnabled              = false,
    gunEspEnabled           = false,
    speedEnabled            = false,
    speedValue              = (getgenv().QuantumX_Config and getgenv().QuantumX_Config.speedValue) or 16,
    noclipEnabled           = false,
    autoPickupGun           = false,
    killAllMurderer         = false,
    killMurdererSheriff     = false,
    resetOnFullBag          = false,
    autoFarmCoins           = false,
    autoOpenCrates          = false,
    dieAtFullBag            = false,
    teleportUnderMapFullBag = false,
    autoFlingMurderer       = false,
    safeDistance            = 30,
}

-- ── Speed/Noclip delegation ────────────────────────────
local function isSpeedEnabled()
    if getgenv().QuantumX_Config then return getgenv().QuantumX_Config.speedEnabled end
    return getgenv().MM2Config.speedEnabled
end
local function getSpeedValue()
    if getgenv().QuantumX_Config then return getgenv().QuantumX_Config.speedValue end
    return getgenv().MM2Config.speedValue
end
local function isNoclipEnabled()
    if getgenv().QuantumX_Config then return getgenv().QuantumX_Config.noclipEnabled end
    return getgenv().MM2Config.noclipEnabled
end

-- ── Utilities ──────────────────────────────────────────
local function getChar()     return lp.Character end
local function getHumanoid() local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getCoinBag()  local c = getChar(); return c and c:FindFirstChild("CoinBag") end

local function safeFireRemote(name, ...)
    local args = {...}
    pcall(function()
        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v.Name == name and v:IsA("RemoteEvent") then
                v:FireServer(table.unpack(args)); return
            end
        end
    end)
end

-- ── Role detection ─────────────────────────────────────
local function getRoleInfo(plr)
    local char = plr.Character
    if not char then return "Unknown", Color3.fromRGB(255,255,255) end
    local bp = plr:FindFirstChild("Backpack")
    if char:FindFirstChild("Knife") or (bp and bp:FindFirstChild("Knife")) then
        return "Murderer", Color3.fromRGB(255,50,50)
    end
    if char:FindFirstChild("Gun") or (bp and bp:FindFirstChild("Gun")) then
        return "Sheriff", Color3.fromRGB(80,140,255)
    end
    return "Innocent", Color3.fromRGB(50,255,100)
end

-- ── Nameplate ──────────────────────────────────────────
local function createNameplate(plr, role, color)
    local char = plr.Character; if not char then return end
    local old = char:FindFirstChild("QuantumNameplate"); if old then old:Destroy() end
    local adornee = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    if not adornee then return end
    local bb = Instance.new("BillboardGui")
    bb.Name="QuantumNameplate"; bb.Adornee=adornee
    bb.Size=UDim2.new(0,220,0,44); bb.StudsOffset=Vector3.new(0,3,0)
    bb.AlwaysOnTop=true; bb.ResetOnSpawn=false
    local lbl = Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
    lbl.Text="["..role.."]\n"..plr.Name
    lbl.TextColor3=color; lbl.TextStrokeTransparency=0.35
    lbl.TextStrokeColor3=Color3.new(0,0,0)
    lbl.TextScaled=true; lbl.Font=Enum.Font.SourceSansBold
    lbl.Parent=bb; bb.Parent=char
end

local function removeAllNameplates()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then
            local n = plr.Character:FindFirstChild("QuantumNameplate")
            if n then n:Destroy() end
        end
    end
end

-- ── Player ESP loop ────────────────────────────────────
local function espLoop()
    while getgenv().MM2Config.espEnabled do
        pcall(function()
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp and plr.Character then
                    local role, color = getRoleInfo(plr)
                    local h = plr.Character:FindFirstChild("QuantumESP")
                    if not h then
                        h = Instance.new("Highlight")
                        h.Name="QuantumESP"
                        h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                        h.FillTransparency=0.45; h.OutlineTransparency=0
                        h.OutlineColor=Color3.fromRGB(255,255,255)
                        h.Parent=plr.Character
                    end
                    h.FillColor=color
                    createNameplate(plr, role, color)
                end
            end
        end)
        task.wait(0.2)
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then
            local h = plr.Character:FindFirstChild("QuantumESP")
            if h then h:Destroy() end
        end
    end
    removeAllNameplates()
end

-- ── Gun ESP loop ───────────────────────────────────────
local function isGunHeld(obj)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character and obj:IsDescendantOf(plr.Character) then return true end
    end
    return false
end

local function gunEspLoop()
    while getgenv().MM2Config.gunEspEnabled do
        pcall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                local isGun = (obj:IsA("Tool") and obj.Name=="Gun")
                    or (obj:IsA("Model") and obj.Name:lower():find("gun"))
                if isGun and not isGunHeld(obj) and not obj:FindFirstChild("GunESP") then
                    local h = Instance.new("Highlight")
                    h.Name="GunESP"; h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                    h.FillTransparency=0.3; h.OutlineTransparency=0
                    h.OutlineColor=Color3.fromRGB(255,255,255)
                    h.FillColor=Color3.fromRGB(255,165,0)
                    h.Parent=obj
                end
            end
        end)
        task.wait(0.3)
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local h = obj:FindFirstChild("GunESP"); if h then h:Destroy() end
    end
end

-- ── Find dropped gun ───────────────────────────────────
local function getDroppedGun()
    local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local best, bestDist = nil, math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local isGun = (obj:IsA("Tool") and obj.Name=="Gun")
            or (obj:IsA("Model") and obj.Name:lower():find("gun"))
        if isGun and not isGunHeld(obj) then
            local part = obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local d = (part.Position - hrp.Position).Magnitude
                if d < bestDist then bestDist=d; best=part end
            end
        end
    end
    return best
end

local function teleportToGun()
    local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
    if not hrp then warn("[QuantumX MM2] No HumanoidRootPart."); return end
    local part = getDroppedGun()
    if part then
        hrp.CFrame = part.CFrame * CFrame.new(0,2,0)
        print("[QuantumX MM2] ✅ Teleported to gun.")
    else
        warn("[QuantumX MM2] No dropped gun found.")
    end
end

-- ── Speed / Noclip  (standalone only) ─────────────────
if not getgenv().QuantumX_Loader_Loaded then
    print("[QuantumX MM2] Standalone – starting own Speed/Noclip loops.")
    task.spawn(function()
        while true do
            if isSpeedEnabled() then
                local h = getHumanoid()
                if h then h.WalkSpeed = getSpeedValue() end
            end
            task.wait()
        end
    end)
    RunService.Stepped:Connect(function()
        if isNoclipEnabled() then
            local c = getChar()
            if c then
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end
    end)
else
    print("[QuantumX MM2] Loader active – Speed/Noclip delegated.")
end

-- ── Auto Farm Coins ────────────────────────────────────
local function coinFarmLoop()
    while getgenv().MM2Config.autoFarmCoins do
        pcall(function()
            local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local coins = {}
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and (obj.Name:lower():find("coin") or obj.Name:lower():find("money")) then
                    local p = obj:FindFirstChildWhichIsA("BasePart")
                    if p then table.insert(coins, p) end
                end
            end
            if #coins == 0 then return end
            local mPos = nil
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp then
                    local role = getRoleInfo(plr)
                    if role == "Murderer" and plr.Character then
                        local m = plr.Character:FindFirstChild("HumanoidRootPart")
                        if m then mPos = m.Position; break end
                    end
                end
            end
            if mPos and (mPos - hrp.Position).Magnitude < getgenv().MM2Config.safeDistance then
                local farthest, fd = nil, -math.huge
                for _, p in ipairs(coins) do
                    local d = (mPos - p.Position).Magnitude
                    if d > fd then fd=d; farthest=p end
                end
                if farthest then hrp.CFrame = farthest.CFrame * CFrame.new(0,2,0); task.wait(0.25); return end
            end
            local nearest, nd = nil, math.huge
            for _, p in ipairs(coins) do
                local d = (p.Position - hrp.Position).Magnitude
                if d < nd then nd=d; nearest=p end
            end
            if nearest then hrp.CFrame = nearest.CFrame * CFrame.new(0,2,0) end
        end)
        task.wait(0.05)
    end
end

-- ── Auto Open Crates ───────────────────────────────────
local function autoOpenCratesLoop()
    while getgenv().MM2Config.autoOpenCrates do
        pcall(function()
            local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj.Name:lower():find("crate") then
                    local p = obj:FindFirstChildWhichIsA("BasePart")
                    if p then
                        hrp.CFrame = p.CFrame * CFrame.new(0,2,0)
                        task.wait(0.4); safeFireRemote("OpenCrate", obj); task.wait(0.6)
                    end
                end
            end
        end)
        task.wait(1)
    end
end

-- ── Auto Pickup Gun ────────────────────────────────────
local function autoPickupGunLoop()
    while getgenv().MM2Config.autoPickupGun do
        pcall(function()
            local part = getDroppedGun()
            if part then
                local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = part.CFrame * CFrame.new(0,2,0)
                    task.wait(0.1)
                    local tool = part.Parent
                    if tool and tool:IsA("Tool") then tool.Parent = lp.Backpack end
                end
            end
        end)
        task.wait(0.5)
    end
end

-- ── Kill All as Murderer ───────────────────────────────
local function killAllMurdererLoop()
    while getgenv().MM2Config.killAllMurderer do
        pcall(function()
            if getRoleInfo(lp) ~= "Murderer" then return end
            local char = getChar()
            if char and not char:FindFirstChild("Knife") then
                local bp = lp:FindFirstChild("Backpack")
                if bp then local k = bp:FindFirstChild("Knife"); if k then k.Parent=char end end
            end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp and plr.Character then
                    local tHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                    local hrp  = getChar() and getChar():FindFirstChild("HumanoidRootPart")
                    if tHRP and hrp then
                        hrp.CFrame = tHRP.CFrame * CFrame.new(0,0,3)
                        safeFireRemote("Attack", tHRP); task.wait(0.2)
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end

-- ── Kill Murderer as Sheriff ───────────────────────────
local function killMurdererSheriffLoop()
    while getgenv().MM2Config.killMurdererSheriff do
        pcall(function()
            if getRoleInfo(lp) ~= "Sheriff" then return end
            local char = getChar()
            if char and not char:FindFirstChild("Gun") then
                local bp = lp:FindFirstChild("Backpack")
                if bp then local g = bp:FindFirstChild("Gun"); if g then g.Parent=char end end
            end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp then
                    local role = getRoleInfo(plr)
                    if role == "Murderer" and plr.Character then
                        local mHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                        local hrp  = getChar() and getChar():FindFirstChild("HumanoidRootPart")
                        if mHRP and hrp then
                            hrp.CFrame = mHRP.CFrame * CFrame.new(0,0,5)
                            safeFireRemote("Shoot", mHRP); task.wait(0.3)
                        end
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end

-- ── Auto Fling Murderer ────────────────────────────────
local function autoFlingMurdererLoop()
    while getgenv().MM2Config.autoFlingMurderer do
        pcall(function()
            if getRoleInfo(lp) ~= "Sheriff" then return end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp then
                    local role = getRoleInfo(plr)
                    if role == "Murderer" and plr.Character then
                        local mHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                        local hrp  = getChar() and getChar():FindFirstChild("HumanoidRootPart")
                        if mHRP and hrp then
                            hrp.CFrame = mHRP.CFrame * CFrame.new(0,0,2)
                            safeFireRemote("Shoot", mHRP); task.wait(0.15)
                        end
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end

-- ── Coin Bag background loops ──────────────────────────
local function isBagFull()
    local bag = getCoinBag(); if not bag then return false end
    local a = bag:FindFirstChild("Amount"); local m = bag:FindFirstChild("MaxAmount")
    return a and m and a.Value >= m.Value
end

task.spawn(function()
    while true do
        if getgenv().MM2Config.dieAtFullBag then
            pcall(function()
                if isBagFull() then local h = getHumanoid(); if h then h.Health=0 end end
            end)
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while true do
        if getgenv().MM2Config.teleportUnderMapFullBag then
            pcall(function()
                if isBagFull() then
                    local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.CFrame = CFrame.new(0,-500,0) end
                end
            end)
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while true do
        if getgenv().MM2Config.resetOnFullBag then
            pcall(function()
                if isBagFull() then
                    local c = getChar(); if c then c:BreakJoints() end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- ── Load WindUI  (standalone only) ────────────────────
local WindUI = getgenv().QuantumX_WindUI

if not WindUI then
    print("[QuantumX MM2] Standalone – loading WindUI…")
    local ok, src = pcall(function()
        return game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua")
    end)
    if ok and type(src)=="string" and #src>100 then
        local okC, fn = pcall(loadstring, src)
        if okC and type(fn)=="function" then
            local okE, lib = pcall(fn)
            if okE and lib ~= nil then
                WindUI = lib
                getgenv().QuantumX_WindUI = WindUI
                print("[QuantumX MM2] ✅ WindUI loaded (standalone).")
            else
                warn("[QuantumX MM2] ❌ WindUI exec failed: "..tostring(lib))
            end
        else
            warn("[QuantumX MM2] ❌ WindUI compile failed: "..tostring(fn))
        end
    else
        warn("[QuantumX MM2] ❌ WindUI HTTP failed: "..tostring(src))
    end
end

if not WindUI then
    warn("[QuantumX MM2] ❌ No WindUI – GUI unavailable. Background loops still active.")
    return
end

-- ── Purple theme  (standalone only) ───────────────────
if not getgenv().QuantumX_Loader_Loaded then
    pcall(function()
        WindUI:SetTheme({
            SchemeColor  = Color3.fromHex("#7C3AED"),
            Background   = Color3.fromHex("#0D0D14"),
            Header       = Color3.fromHex("#13131F"),
            TextColor    = Color3.fromRGB(230,220,255),
            ElementColor = Color3.fromHex("#1A1A2E"),
        })
    end)
    pcall(function() WindUI:SetAccent(Color3.fromHex("#7C3AED")) end)
end

-- ── Window  (reuse loader's or create own) ─────────────
local Window    = getgenv().QuantumX_Window
local standalone = not Window

if standalone then
    local ok, r = pcall(function()
        return WindUI:CreateWindow({
            Title    = "Quantum X | MM2",
            SubTitle = "discord.gg/2W2MUCEDCB",
            Size     = UDim2.new(0, 580, 0, 580),
        })
    end)
    if not ok or r == nil then
        warn("[QuantumX MM2] ❌ Window creation failed: "..tostring(r)); return
    end
    Window = r
    getgenv().QuantumX_Window = Window
    pcall(function()
        Window:Tag({
            Title  = VERSION,
            Icon   = "discord",
            Color  = Color3.fromHex("#7C3AED"),
            Radius = 13,
        })
    end)
    print("[QuantumX MM2] Standalone: own GUI window created.")
else
    print("[QuantumX MM2] Loader detected: adding tabs to existing window.")
end

-- ── Tab: ESP ───────────────────────────────────────────
local EspTab = Window:Tab({ Title = "ESP", Icon = "rbxassetid://4483362458" })

EspTab:Section({ Title = "👁️  Player ESP" })
EspTab:Toggle({
    Title    = "Player ESP  (Murderer / Sheriff / Innocent)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.espEnabled = v
        if v then task.spawn(espLoop) end
    end,
})
EspTab:Toggle({
    Title    = "Gun ESP  (dropped Sheriff gun)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.gunEspEnabled = v
        if v then task.spawn(gunEspLoop) end
    end,
})

EspTab:Section({ Title = "🔫  Gun Teleport" })
EspTab:Button({ Title = "Teleport to Nearest Dropped Gun", Callback = teleportToGun })

-- ── Tab: Auto Farm ─────────────────────────────────────
local AutoTab = Window:Tab({ Title = "Auto Farm", Icon = "rbxassetid://4483362458" })

AutoTab:Section({ Title = "💰  Coin Farming" })
AutoTab:Toggle({
    Title    = "Auto Farm Coins  (escapes murderer within 30 studs)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.autoFarmCoins = v
        if v then task.spawn(coinFarmLoop) end
    end,
})
AutoTab:Toggle({
    Title    = "Auto Open Crates",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.autoOpenCrates = v
        if v then task.spawn(autoOpenCratesLoop) end
    end,
})

AutoTab:Section({ Title = "🔫  Weapons" })
AutoTab:Toggle({
    Title    = "Auto Pickup Gun",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.autoPickupGun = v
        if v then task.spawn(autoPickupGunLoop) end
    end,
})

AutoTab:Section({ Title = "⚔️  Kill" })
AutoTab:Toggle({
    Title    = "Kill All as Murderer  (auto-equip knife)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.killAllMurderer = v
        if v then task.spawn(killAllMurdererLoop) end
    end,
})
AutoTab:Toggle({
    Title    = "Kill Murderer as Sheriff  (auto-equip + shoot)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.killMurdererSheriff = v
        if v then task.spawn(killMurdererSheriffLoop) end
    end,
})
AutoTab:Toggle({
    Title    = "Auto Fling Murderer  (as Sheriff)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.autoFlingMurderer = v
        if v then task.spawn(autoFlingMurdererLoop) end
    end,
})

-- ── Tab: Coin Bag ──────────────────────────────────────
local BagTab = Window:Tab({ Title = "Coin Bag", Icon = "rbxassetid://4483362458" })

BagTab:Section({ Title = "💼  On Full Bag…" })
BagTab:Toggle({
    Title    = "Die at Full Bag",
    Default  = false,
    Callback = function(v) getgenv().MM2Config.dieAtFullBag = v end,
})
BagTab:Toggle({
    Title    = "Teleport Under Map at Full Bag",
    Default  = false,
    Callback = function(v) getgenv().MM2Config.teleportUnderMapFullBag = v end,
})
BagTab:Toggle({
    Title    = "Reset Character at Full Bag",
    Default  = false,
    Callback = function(v) getgenv().MM2Config.resetOnFullBag = v end,
})

-- ── Standalone: Movement tab ───────────────────────────
if standalone then
    local MTab = Window:Tab({ Title = "Movement", Icon = "rbxassetid://4483362458" })
    MTab:Section({ Title = "⚡  Speed & Noclip" })
    MTab:Toggle({
        Title    = "Speed Hack",
        Default  = false,
        Callback = function(v) getgenv().MM2Config.speedEnabled = v end,
    })
    MTab:Slider({
        Title    = "Walk Speed",
        Min      = 16, Max = 350, Default = 16,
        Callback = function(v) getgenv().MM2Config.speedValue = v end,
    })
    MTab:Toggle({
        Title    = "Noclip",
        Default  = false,
        Callback = function(v) getgenv().MM2Config.noclipEnabled = v end,
    })
    MTab:Section({ Title = "🔧  Dev Tools" })
    MTab:Button({ Title = "Infinite Yield", Callback = function()
        pcall(function()
            loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"
            ))()
        end)
    end })
    MTab:Button({ Title = "Dex Explorer", Callback = function()
        pcall(function()
            loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"
            ))()
        end)
    end })
end

print("[QuantumX MM2] ✅ All features ready!")
