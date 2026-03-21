--[[
    Quantum X  –  mm2.lua  v1.6.6
    Murder Mystery 2 – full feature set.
    Works standalone OR loaded via loader.lua.

    Standalone usage:
        loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/shadeflux/QuantumX-MM2/main/mm2.lua"
        ))()
]]

-- ── Anti-duplicate ─────────────────────────────────────
if getgenv().QuantumX_MM2_Loaded then
    warn("[QuantumX MM2] Already loaded – skipping duplicate.")
    return
end
getgenv().QuantumX_MM2_Loaded = true

-- ── Constants ──────────────────────────────────────────
local VERSION      = "v1.6.6"
local MM2_PLACE_ID = 142823291
local DISCORD      = "discord.gg/2W2MUCEDCB"

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
    safeDistance            = 60,  -- increased from 30 to 60 studs
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
local function isAlive()
    local h = getHumanoid()
    return h and h.Health > 0
end

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
    local bb  = Instance.new("BillboardGui")
    bb.Name = "QuantumNameplate"; bb.Adornee = adornee
    bb.Size = UDim2.new(0,220,0,44); bb.StudsOffset = Vector3.new(0,3,0)
    bb.AlwaysOnTop = true; bb.ResetOnSpawn = false
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Text = "["..role.."]\n"..plr.Name
    lbl.TextColor3 = color; lbl.TextStrokeTransparency = 0.35
    lbl.TextStrokeColor3 = Color3.new(0,0,0)
    lbl.TextScaled = true; lbl.Font = Enum.Font.SourceSansBold
    lbl.Parent = bb; bb.Parent = char
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
                        h.Name = "QuantumESP"
                        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        h.FillTransparency = 0.45; h.OutlineTransparency = 0
                        h.OutlineColor = Color3.fromRGB(255,255,255)
                        h.Parent = plr.Character
                    end
                    h.FillColor = color
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

-- ── Gun helpers ────────────────────────────────────────
-- Returns true when the object is currently held by any player character.
local function isGunHeld(obj)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character and obj:IsDescendantOf(plr.Character) then return true end
    end
    return false
end

-- Collects every gun-like object that is NOT held by a player.
-- FIX: also checks Backpacks so dropped tools inside player folders are ignored.
local function getDroppedGuns()
    local results = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local isGun = (obj:IsA("Tool") and obj.Name == "Gun")
            or (obj:IsA("Model") and obj.Name:lower():find("gun"))
        if not isGun then continue end
        -- Skip guns held by / in any player
        local skip = false
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character and obj:IsDescendantOf(plr.Character) then skip = true; break end
            if obj:IsDescendantOf(plr) then skip = true; break end  -- covers Backpack too
        end
        if not skip then
            local part = obj:FindFirstChildWhichIsA("BasePart")
                or (obj:IsA("BasePart") and obj)
            if part then table.insert(results, { obj = obj, part = part }) end
        end
    end
    return results
end

local function getNearestDroppedGun()
    local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, nil end
    local best, bestPart, bestDist = nil, nil, math.huge
    for _, entry in ipairs(getDroppedGuns()) do
        local d = (entry.part.Position - hrp.Position).Magnitude
        if d < bestDist then bestDist = d; best = entry.obj; bestPart = entry.part end
    end
    return best, bestPart
end

-- ── Gun ESP loop  (FIX: re-scans after sheriff death) ──
local gunEspConnections = {}

local function cleanGunESP()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local h = obj:FindFirstChild("GunESP"); if h then h:Destroy() end
    end
end

local function gunEspLoop()
    -- Clean old highlights each time the loop restarts
    cleanGunESP()
    while getgenv().MM2Config.gunEspEnabled do
        pcall(function()
            -- Remove ESP from guns that are now held
            for _, obj in ipairs(Workspace:GetDescendants()) do
                local h = obj:FindFirstChild("GunESP")
                if h and isGunHeld(obj) then h:Destroy() end
            end
            -- Add ESP to newly dropped guns
            for _, entry in ipairs(getDroppedGuns()) do
                if not entry.obj:FindFirstChild("GunESP") then
                    local h = Instance.new("Highlight")
                    h.Name = "GunESP"; h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.FillTransparency = 0.3; h.OutlineTransparency = 0
                    h.OutlineColor = Color3.fromRGB(255,255,255)
                    h.FillColor    = Color3.fromRGB(255,165,0)
                    h.Parent = entry.obj
                end
            end
        end)
        task.wait(0.2)  -- faster scan than before
    end
    cleanGunESP()
end

-- ── Teleport to gun ────────────────────────────────────
local function teleportToGun()
    local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
    if not hrp then warn("[QuantumX MM2] No HumanoidRootPart."); return end
    local _, part = getNearestDroppedGun()
    if part then
        hrp.CFrame = part.CFrame * CFrame.new(0,2,0)
        print("[QuantumX MM2] ✅ Teleported to dropped gun.")
    else
        warn("[QuantumX MM2] No dropped gun found on the map.")
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

-- ── Auto Farm Coins  (FIXED murderer evasion) ──────────
--[[
    FIX LOGIC:
    Every tick we first find the murderer position.
    We then score every coin by its distance FROM the murderer.
    If a coin is within safeDistance of the murderer we mark it "dangerous".
    We always teleport to the safest coin (farthest from murderer) that is
    also reachable.  If ALL coins are dangerous we still pick the least-dangerous
    one so the player is never stuck.  The key improvement over the old code is
    that we NEVER teleport to a coin that is within safeDistance of the murderer
    as long as a safer option exists — regardless of how close the murderer
    is to the player right now.
]]
local function coinFarmLoop()
    while getgenv().MM2Config.autoFarmCoins do
        pcall(function()
            if not isAlive() then return end
            local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            -- Collect all coins
            local coins = {}
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and (
                    obj.Name:lower():find("coin") or obj.Name:lower():find("money")
                ) then
                    local p = obj:FindFirstChildWhichIsA("BasePart")
                    if p then table.insert(coins, p) end
                end
            end
            if #coins == 0 then return end

            -- Find murderer position (nil if none detected)
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

            local target = nil

            if mPos then
                -- Split coins into safe / unsafe relative to murderer
                local safe, unsafe = {}, {}
                for _, p in ipairs(coins) do
                    local distFromMurderer = (mPos - p.Position).Magnitude
                    if distFromMurderer >= getgenv().MM2Config.safeDistance then
                        table.insert(safe, p)
                    else
                        table.insert(unsafe, p)
                    end
                end

                if #safe > 0 then
                    -- Among safe coins pick nearest to the player
                    local nearest, nd = nil, math.huge
                    for _, p in ipairs(safe) do
                        local d = (p.Position - hrp.Position).Magnitude
                        if d < nd then nd = d; nearest = p end
                    end
                    target = nearest
                else
                    -- All coins are near murderer – pick the least-dangerous one
                    local farthest, fd = nil, -math.huge
                    for _, p in ipairs(unsafe) do
                        local d = (mPos - p.Position).Magnitude
                        if d > fd then fd = d; farthest = p end
                    end
                    target = farthest
                end
            else
                -- No murderer detected – pick nearest coin normally
                local nearest, nd = nil, math.huge
                for _, p in ipairs(coins) do
                    local d = (p.Position - hrp.Position).Magnitude
                    if d < nd then nd = d; nearest = p end
                end
                target = nearest
            end

            if target then
                hrp.CFrame = target.CFrame * CFrame.new(0, 2, 0)
            end
        end)
        task.wait(0.05)
    end
end

-- ── Auto Open Crates ───────────────────────────────────
local function autoOpenCratesLoop()
    while getgenv().MM2Config.autoOpenCrates do
        pcall(function()
            if not isAlive() then return end
            local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj.Name:lower():find("crate") then
                    local p = obj:FindFirstChildWhichIsA("BasePart")
                    if p then
                        hrp.CFrame = p.CFrame * CFrame.new(0,2,0)
                        task.wait(0.4)
                        safeFireRemote("OpenCrate", obj)
                        task.wait(0.6)
                    end
                end
            end
        end)
        task.wait(1)
    end
end

-- ── Auto Pickup Gun  (FIXED: works after sheriff drops gun) ─
--[[
    FIX: The old code tried to reparent the Tool directly (client-side only,
    server doesn't see it).  The correct approach in MM2 is to teleport the
    character ON TOP of the gun part — the game's server-side TouchEnded /
    Touched handler will auto-collect it.  We also now detect guns that are
    dropped as BaseParts (not just Tools) so we catch the gun after sheriff
    dies.  We also make sure the player is alive before attempting pickup.
]]
local function autoPickupGunLoop()
    while getgenv().MM2Config.autoPickupGun do
        pcall(function()
            if not isAlive() then return end
            local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local _, part = getNearestDroppedGun()
            if part then
                -- Teleport directly onto the gun so the game's touch logic picks it up
                hrp.CFrame = part.CFrame * CFrame.new(0, 1, 0)
                task.wait(0.15)
                -- Attempt direct parent as a secondary method
                local tool = part.Parent
                if tool and tool:IsA("Tool") then
                    pcall(function() tool.Parent = lp.Backpack end)
                end
            end
        end)
        task.wait(0.4)
    end
end

-- ── Kill All as Murderer ───────────────────────────────
local function killAllMurdererLoop()
    while getgenv().MM2Config.killAllMurderer do
        pcall(function()
            if not isAlive() then return end
            if getRoleInfo(lp) ~= "Murderer" then return end
            local char = getChar()
            if char and not char:FindFirstChild("Knife") then
                local bp = lp:FindFirstChild("Backpack")
                if bp then local k = bp:FindFirstChild("Knife"); if k then k.Parent = char end end
            end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp and plr.Character then
                    local tHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                    local hrp  = getChar() and getChar():FindFirstChild("HumanoidRootPart")
                    if tHRP and hrp then
                        hrp.CFrame = tHRP.CFrame * CFrame.new(0,0,3)
                        safeFireRemote("Attack", tHRP)
                        task.wait(0.2)
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
            if not isAlive() then return end
            if getRoleInfo(lp) ~= "Sheriff" then return end
            local char = getChar()
            if char and not char:FindFirstChild("Gun") then
                local bp = lp:FindFirstChild("Backpack")
                if bp then local g = bp:FindFirstChild("Gun"); if g then g.Parent = char end end
            end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp then
                    local role = getRoleInfo(plr)
                    if role == "Murderer" and plr.Character then
                        local mHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                        local hrp  = getChar() and getChar():FindFirstChild("HumanoidRootPart")
                        if mHRP and hrp then
                            hrp.CFrame = mHRP.CFrame * CFrame.new(0,0,5)
                            safeFireRemote("Shoot", mHRP)
                            task.wait(0.3)
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
            if not isAlive() then return end
            if getRoleInfo(lp) ~= "Sheriff" then return end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp then
                    local role = getRoleInfo(plr)
                    if role == "Murderer" and plr.Character then
                        local mHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                        local hrp  = getChar() and getChar():FindFirstChild("HumanoidRootPart")
                        if mHRP and hrp then
                            hrp.CFrame = mHRP.CFrame * CFrame.new(0,0,2)
                            safeFireRemote("Shoot", mHRP)
                            task.wait(0.15)
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
                if isBagFull() then local h = getHumanoid(); if h then h.Health = 0 end end
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

-- ── Load WindUI  (standalone only) ─────────────────────
local WindUI = getgenv().QuantumX_WindUI

if not WindUI then
    print("[QuantumX MM2] Standalone – loading WindUI…")
    local ok, src = pcall(function()
        return game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua")
    end)
    if ok and type(src) == "string" and #src > 100 then
        local okC, fn = pcall(loadstring, src)
        if okC and type(fn) == "function" then
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
            Title                      = "Quantum X | MM2",
            SubTitle                   = DISCORD,
            Author                     = "by "..DISCORD,
            Size                       = UDim2.new(0, 580, 0, 580),
            Transparent                = true,
            Theme                      = "Dark",
            Resizable                  = true,
            SideBarWidth               = 200,
            BackgroundImageTransparency = 0.42,
            HideSearchBar              = true,
            ScrollBarEnabled           = false,
            User = {
                Enabled   = true,
                Anonymous = false,
                Callback  = function()
                    print("[QuantumX MM2] Profile clicked.")
                end,
            },
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

-- ═══════════════════════════════════════════════════════
-- GUI TABS
-- ═══════════════════════════════════════════════════════

-- ── Tab: ESP ───────────────────────────────────────────
local EspTab = Window:Tab({ Title = "ESP", Icon = "rbxassetid://4483362458" })

local EspSection = EspTab:Section({ Title = "👁️  Player ESP", Icon = "eye", Opened = true })
EspSection:Toggle({
    Title    = "Player ESP  (Murderer / Sheriff / Innocent)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.espEnabled = v
        if v then task.spawn(espLoop) end
    end,
})
EspSection:Toggle({
    Title    = "Gun ESP  (dropped Sheriff gun)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.gunEspEnabled = v
        if v then task.spawn(gunEspLoop) end
    end,
})

local GunTpSection = EspTab:Section({ Title = "🔫  Gun Teleport", Icon = "crosshair", Opened = true })
GunTpSection:Button({
    Title    = "Teleport to Nearest Dropped Gun",
    Callback = teleportToGun,
})

-- ── Tab: Auto Farm  (all sections inside one tab) ──────
local AutoTab = Window:Tab({ Title = "Auto Farm", Icon = "rbxassetid://4483362458" })

-- Section 1: Coin Farming
local CoinSection = AutoTab:Section({
    Title  = "💰  Coin Farming",
    Icon   = "coins",
    Opened = true,
})
CoinSection:Toggle({
    Title    = "Auto Farm Coins  (safe distance: 60 studs from murderer)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.autoFarmCoins = v
        if v then task.spawn(coinFarmLoop) end
    end,
})
CoinSection:Toggle({
    Title    = "Auto Open Crates",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.autoOpenCrates = v
        if v then task.spawn(autoOpenCratesLoop) end
    end,
})

-- Section 2: Coin Bag actions
local BagSection = AutoTab:Section({
    Title  = "💼  Coin Bag",
    Icon   = "package",
    Opened = true,
})
BagSection:Toggle({
    Title    = "Die at Full Bag",
    Default  = false,
    Callback = function(v) getgenv().MM2Config.dieAtFullBag = v end,
})
BagSection:Toggle({
    Title    = "Teleport Under Map at Full Bag",
    Default  = false,
    Callback = function(v) getgenv().MM2Config.teleportUnderMapFullBag = v end,
})
BagSection:Toggle({
    Title    = "Reset Character at Full Bag",
    Default  = false,
    Callback = function(v) getgenv().MM2Config.resetOnFullBag = v end,
})

-- Section 3: Weapons
local WeaponSection = AutoTab:Section({
    Title  = "🔫  Weapons",
    Icon   = "sword",
    Opened = true,
})
WeaponSection:Toggle({
    Title    = "Auto Pickup Gun  (teleports onto dropped gun)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.autoPickupGun = v
        if v then task.spawn(autoPickupGunLoop) end
    end,
})

-- Section 4: Kill
local KillSection = AutoTab:Section({
    Title  = "⚔️  Kill",
    Icon   = "skull",
    Opened = true,
})
KillSection:Toggle({
    Title    = "Kill All as Murderer  (auto-equip knife)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.killAllMurderer = v
        if v then task.spawn(killAllMurdererLoop) end
    end,
})
KillSection:Toggle({
    Title    = "Kill Murderer as Sheriff  (auto-equip gun + shoot)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.killMurdererSheriff = v
        if v then task.spawn(killMurdererSheriffLoop) end
    end,
})
KillSection:Toggle({
    Title    = "Auto Fling Murderer  (as Sheriff)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.autoFlingMurderer = v
        if v then task.spawn(autoFlingMurdererLoop) end
    end,
})

-- ── Tab: Credits ────────────────────────────────────────
local CredTab = Window:Tab({ Title = "Credits", Icon = "rbxassetid://4483362458" })

local AboutSection = CredTab:Section({ Title = "ℹ️  About", Icon = "info", Opened = true })
AboutSection:Paragraph({
    Title   = "Quantum X  "..VERSION,
    Content = "Full-featured script for Murder Mystery 2 on Roblox.",
})
AboutSection:Paragraph({
    Title   = "ESP",
    Content = "Murderer = red  •  Sheriff = blue  •  Innocent = green.\nGun ESP highlights dropped guns in orange.",
})
AboutSection:Paragraph({
    Title   = "Auto Farm Coins",
    Content = "Automatically teleports to coins. Avoids coins within 60 studs of the murderer. Picks the safest available coin every tick.",
})
AboutSection:Paragraph({
    Title   = "Auto Pickup Gun",
    Content = "Teleports onto dropped Sheriff guns so the game auto-collects them. Works after the Sheriff dies.",
})
AboutSection:Paragraph({
    Title   = "Kill features",
    Content = "Kill All (Murderer): auto-equips knife and teleports to each player.\nKill Murderer (Sheriff): auto-equips gun and shoots.\nAuto Fling: rushes and shoots the murderer as Sheriff.",
})
AboutSection:Paragraph({
    Title   = "Coin Bag",
    Content = "Three actions when your bag is full: Die / Teleport under map / Reset character.",
})

local LinkSection = CredTab:Section({ Title = "🔗  Community", Icon = "link", Opened = true })
LinkSection:Paragraph({
    Title   = "Discord Server",
    Content = DISCORD,
})
LinkSection:Button({
    Title    = "Copy Discord Link",
    Callback = function()
        pcall(function()
            setclipboard(DISCORD)
            print("[QuantumX] Discord link copied: "..DISCORD)
        end)
    end,
})
LinkSection:Paragraph({
    Title   = "GitHub",
    Content = "github.com/shadeflux/QuantumX-MM2",
})
LinkSection:Paragraph({
    Title   = "UI Library",
    Content = "WindUI by Footagesus",
})
LinkSection:Paragraph({
    Title   = "Developers",
    Content = "Quantum Team",
})

-- ── Standalone: Movement tab ───────────────────────────
if standalone then
    local MTab = Window:Tab({ Title = "Movement", Icon = "rbxassetid://4483362458" })

    local SpeedSection = MTab:Section({ Title = "⚡  Speed & Noclip", Icon = "zap", Opened = true })
    SpeedSection:Toggle({
        Title    = "Speed Hack",
        Default  = false,
        Callback = function(v) getgenv().MM2Config.speedEnabled = v end,
    })
    SpeedSection:Slider({
        Title    = "Walk Speed",
        Min      = 16, Max = 350, Default = 16,
        Callback = function(v) getgenv().MM2Config.speedValue = v end,
    })
    SpeedSection:Toggle({
        Title    = "Noclip",
        Default  = false,
        Callback = function(v) getgenv().MM2Config.noclipEnabled = v end,
    })

    local DevSection2 = MTab:Section({ Title = "🔧  Dev Tools", Icon = "terminal", Opened = false })
    DevSection2:Button({ Title = "Infinite Yield", Callback = function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
        end)
    end })
    DevSection2:Button({ Title = "Dex Explorer", Callback = function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
        end)
    end })
end

print("[QuantumX MM2] ✅ All features ready!")
