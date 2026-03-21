--[[
    Quantum X  –  mm2.lua  v1.6.6
    Murder Mystery 2 – full feature set.
    Works standalone OR auto-loaded by loader.lua.

    Standalone:
        loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/shadeflux/QuantumX-MM2/main/mm2.lua"
        ))()
]]

if getgenv().QuantumX_MM2_Loaded then return end
getgenv().QuantumX_MM2_Loaded = true

local VERSION      = "v1.6.6"
local MM2_PLACE_ID = 142823291
local DISCORD      = "discord.gg/2W2MUCEDCB"

if game.PlaceId ~= MM2_PLACE_ID then
    warn(("[QuantumX MM2] PlaceId %d ≠ %d – some features may not work."):format(game.PlaceId, MM2_PLACE_ID))
end

-- ── Services ───────────────────────────────────────────
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local RS         = game:GetService("ReplicatedStorage")
local lp         = Players.LocalPlayer

-- ── Config ─────────────────────────────────────────────
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
    teleportUnderMapFullBag = false,
    autoFlingMurderer       = false,
    safeDistance            = 60,
}

-- ── Delegation helpers ─────────────────────────────────
local function isSpeedEnabled()
    return getgenv().QuantumX_Config and getgenv().QuantumX_Config.speedEnabled
        or getgenv().MM2Config.speedEnabled
end
local function getSpeedValue()
    return getgenv().QuantumX_Config and getgenv().QuantumX_Config.speedValue
        or getgenv().MM2Config.speedValue
end
local function isNoclipEnabled()
    return getgenv().QuantumX_Config and getgenv().QuantumX_Config.noclipEnabled
        or getgenv().MM2Config.noclipEnabled
end

-- ── Utilities ──────────────────────────────────────────
local function getChar()     return lp.Character end
local function getRootPart() local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHumanoid() local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getCoinBag()  local c = getChar(); return c and c:FindFirstChild("CoinBag") end
local function isAlive()     local h = getHumanoid(); return h ~= nil and h.Health > 0 end

-- ── Round / death tracking ─────────────────────────────
local roundActive = true

local function hookCharacter(char)
    char:WaitForChild("Humanoid", 10)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    roundActive = true
    hum.Died:Connect(function()
        roundActive = false
        print("[QuantumX MM2] Died – auto-features paused until next character.")
    end)
end

if lp.Character then task.spawn(hookCharacter, lp.Character) end
lp.CharacterAdded:Connect(function(c) task.spawn(hookCharacter, c) end)

-- ── Remote helper ──────────────────────────────────────
local function fireRemote(name, ...)
    local args = {...}
    for _, v in ipairs(RS:GetDescendants()) do
        if v.Name == name and v:IsA("RemoteEvent") then
            pcall(v.FireServer, v, table.unpack(args)); return
        end
    end
end

-- ── Role detection ─────────────────────────────────────
local function getRole(plr)
    local c  = plr.Character; if not c then return "Unknown", Color3.fromRGB(255,255,255) end
    local bp = plr:FindFirstChild("Backpack")
    if c:FindFirstChild("Knife") or (bp and bp:FindFirstChild("Knife")) then
        return "Murderer", Color3.fromRGB(255,50,50)
    end
    if c:FindFirstChild("Gun") or (bp and bp:FindFirstChild("Gun")) then
        return "Sheriff", Color3.fromRGB(80,140,255)
    end
    return "Innocent", Color3.fromRGB(50,255,100)
end

-- ── Nameplate ──────────────────────────────────────────
local function createNameplate(plr, role, color)
    local c = plr.Character; if not c then return end
    local old = c:FindFirstChild("QuantumNP"); if old then old:Destroy() end
    local head = c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart"); if not head then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "QuantumNP"; bb.Adornee = head
    bb.Size = UDim2.new(0,220,0,44); bb.StudsOffset = Vector3.new(0,3,0)
    bb.AlwaysOnTop = true; bb.ResetOnSpawn = false
    local lbl = Instance.new("TextLabel", bb)
    lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Text = "["..role.."]\n"..plr.Name; lbl.TextColor3 = color
    lbl.TextStrokeTransparency = 0.35; lbl.TextStrokeColor3 = Color3.new(0,0,0)
    lbl.TextScaled = true; lbl.Font = Enum.Font.SourceSansBold
    bb.Parent = c
end

local function clearNameplates()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local n = p.Character:FindFirstChild("QuantumNP"); if n then n:Destroy() end
        end
    end
end

-- ══════════════════════════════════════════════════════
-- PLAYER ESP
-- ══════════════════════════════════════════════════════
local function espLoop()
    while getgenv().MM2Config.espEnabled do
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp and p.Character then
                local ok2 = pcall(function()
                    local role, color = getRole(p)
                    local h = p.Character:FindFirstChild("QuantumESP")
                    if not h then
                        h = Instance.new("Highlight", p.Character)
                        h.Name = "QuantumESP"; h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        h.FillTransparency = 0.45; h.OutlineTransparency = 0
                        h.OutlineColor = Color3.fromRGB(255,255,255)
                    end
                    h.FillColor = color
                    createNameplate(p, role, color)
                end)
            end
        end
        task.wait(0.2)
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local h = p.Character:FindFirstChild("QuantumESP"); if h then h:Destroy() end
        end
    end
    clearNameplates()
end

-- ══════════════════════════════════════════════════════
-- GUN DROP DETECTION  (FIXED)
-- ══════════════════════════════════════════════════════
--[[
  In MM2 the Sheriff's gun drops into Workspace as a direct child when
  the Sheriff dies or drops it.  It keeps its tool name: "Gun", "Revolver",
  or similar.  We only scan Workspace:GetChildren() (direct children) to
  avoid false-positives from guns equipped by other players.
  We also check for the model form "GunDrop" that some MM2 versions use.
]]
local GUN_NAMES = { Gun = true, Revolver = true, GunDrop = true, SheriffGun = true }

local function findDroppedGun()
    -- Direct children of Workspace only (not inside any player character)
    for _, obj in ipairs(Workspace:GetChildren()) do
        -- Tool form  (Gun / Revolver dropped as Tool)
        if obj:IsA("Tool") and GUN_NAMES[obj.Name] then
            local part = obj:FindFirstChildWhichIsA("BasePart")
            if part then return obj, part end
        end
        -- Model form  (GunDrop)
        if obj:IsA("Model") and GUN_NAMES[obj.Name] then
            local part = obj:FindFirstChildWhichIsA("BasePart")
            if part then return obj, part end
        end
    end
    -- Wider scan – go one level deeper (MM2 may nest under a "Drops" folder)
    for _, folder in ipairs(Workspace:GetChildren()) do
        if folder:IsA("Folder") or folder:IsA("Model") then
            for _, obj in ipairs(folder:GetChildren()) do
                if (obj:IsA("Tool") or obj:IsA("Model")) and GUN_NAMES[obj.Name] then
                    local part = obj:FindFirstChildWhichIsA("BasePart")
                    if part then return obj, part end
                end
            end
        end
    end
    return nil, nil
end

-- ── Gun ESP  ───────────────────────────────────────────
local function clearGunESP()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local h = obj:FindFirstChild("GunESP"); if h then h:Destroy() end
    end
end

local function gunEspLoop()
    clearGunESP()
    local lastGun = nil
    while getgenv().MM2Config.gunEspEnabled do
        local gunObj, _ = findDroppedGun()
        if gunObj ~= lastGun then
            clearGunESP()
            lastGun = gunObj
        end
        if gunObj and not gunObj:FindFirstChild("GunESP") then
            local h = Instance.new("Highlight", gunObj)
            h.Name = "GunESP"; h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.FillTransparency = 0.25; h.OutlineTransparency = 0
            h.OutlineColor = Color3.fromRGB(255,255,255)
            h.FillColor    = Color3.fromRGB(255,165,0)
        end
        task.wait(0.1)
    end
    clearGunESP()
end

-- ── Teleport to gun ────────────────────────────────────
local function teleportToGun()
    local hrp = getRootPart(); if not hrp then return end
    local _, part = findDroppedGun()
    if part then
        hrp.CFrame = part.CFrame * CFrame.new(0,2,0)
    else
        warn("[QuantumX MM2] No dropped gun found.")
    end
end

-- ── Standalone Speed / Noclip ──────────────────────────
if not getgenv().QuantumX_Loader_Loaded then
    task.spawn(function()
        while true do
            if isSpeedEnabled() then
                local h = getHumanoid(); if h then h.WalkSpeed = getSpeedValue() end
            end
            task.wait()
        end
    end)
    RunService.Stepped:Connect(function()
        if isNoclipEnabled() then
            local c = getChar()
            if c then for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end end
        end
    end)
end

-- ══════════════════════════════════════════════════════
-- COIN DETECTION  (FIXED)
-- ══════════════════════════════════════════════════════
--[[
  In MM2 coins are BasePart instances named "Coin" scattered in Workspace
  (or inside a folder).  They are NOT wrapped in a Model.
  Previous code looked for Model and then FindFirstChildWhichIsA("BasePart")
  which always returned nil for plain Parts.
  FIX: accept both BasePart named "Coin" AND Model containing a BasePart.
]]
local function collectCoins()
    local coins = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local name = obj.Name:lower()
        if not (name:find("coin") or name:find("money")) then continue end
        if obj:IsA("BasePart") then
            table.insert(coins, obj)
        elseif obj:IsA("Model") then
            local p = obj:FindFirstChildWhichIsA("BasePart")
            if p then table.insert(coins, p) end
        end
    end
    return coins
end

-- ── Murderer position helper ───────────────────────────
local function getMurdererPos()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            local role = getRole(p)
            if role == "Murderer" and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then return hrp.Position end
            end
        end
    end
    return nil
end

-- ══════════════════════════════════════════════════════
-- AUTO FARM COINS  (FIXED)
-- ══════════════════════════════════════════════════════
--[[
  FIX: The flee check and the teleport are now OUTSIDE pcall so that
  an early return actually exits the loop iteration and not just the
  pcall callback.  The logic is:

  STEP 1 – Guard: skip if dead or round not active.
  STEP 2 – Gather data (coins, murderer pos).
  STEP 3 – FLEE: if murderer within safeDistance of US → pick coin
           farthest from murderer → teleport → skip to next tick.
  STEP 4 – FARM: pick nearest coin that is ≥ safeDistance from murderer.
  STEP 5 – FALLBACK: if no safe coin exists pick least-dangerous one.
]]
local function coinFarmLoop()
    while getgenv().MM2Config.autoFarmCoins do
        -- STEP 1
        if not roundActive or not isAlive() then task.wait(0.1); continue end

        local hrp = getRootPart()
        if not hrp then task.wait(0.1); continue end

        -- STEP 2
        local coins  = collectCoins()
        local mPos   = getMurdererPos()

        if #coins == 0 then task.wait(0.1); continue end

        -- STEP 3 – FLEE (runs outside pcall so return works properly)
        if mPos then
            local myDist = (mPos - hrp.Position).Magnitude
            if myDist < getgenv().MM2Config.safeDistance then
                -- Teleport to coin farthest from murderer
                local best, bestD = nil, -math.huge
                for _, p in ipairs(coins) do
                    local d = (mPos - p.Position).Magnitude
                    if d > bestD then bestD = d; best = p end
                end
                if best then hrp.CFrame = best.CFrame * CFrame.new(0,2,0) end
                task.wait(0.05); continue  -- skip normal farming this tick
            end
        end

        -- STEP 4 – FARM safe coins
        local target = nil
        if mPos then
            local safeBest, safeD = nil, math.huge
            for _, p in ipairs(coins) do
                local distFromMurderer = (mPos - p.Position).Magnitude
                if distFromMurderer >= getgenv().MM2Config.safeDistance then
                    local d = (p.Position - hrp.Position).Magnitude
                    if d < safeD then safeD = d; safeBest = p end
                end
            end
            if safeBest then
                target = safeBest
            else
                -- STEP 5 – FALLBACK: all coins unsafe, pick least-dangerous
                local farthest, fd = nil, -math.huge
                for _, p in ipairs(coins) do
                    local d = (mPos - p.Position).Magnitude
                    if d > fd then fd = d; farthest = p end
                end
                target = farthest
            end
        else
            -- No murderer detected
            local nearest, nd = nil, math.huge
            for _, p in ipairs(coins) do
                local d = (p.Position - hrp.Position).Magnitude
                if d < nd then nd = d; nearest = p end
            end
            target = nearest
        end

        if target then hrp.CFrame = target.CFrame * CFrame.new(0,2,0) end
        task.wait(0.05)
    end
end

-- ══════════════════════════════════════════════════════
-- AUTO OPEN CRATES  (FIXED – ProximityPrompt + touch)
-- ══════════════════════════════════════════════════════
local function autoOpenCratesLoop()
    while getgenv().MM2Config.autoOpenCrates do
        if not roundActive or not isAlive() then task.wait(0.5); continue end
        local hrp = getRootPart(); if not hrp then task.wait(0.5); continue end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if not getgenv().MM2Config.autoOpenCrates then break end
            if not (obj:IsA("Model") and (obj.Name:lower():find("crate") or obj.Name:lower():find("box"))) then continue end
            local part = obj:FindFirstChildWhichIsA("BasePart"); if not part then continue end
            hrp.CFrame = part.CFrame * CFrame.new(0,3,0); task.wait(0.3)
            for _, pp in ipairs(obj:GetDescendants()) do
                if pp:IsA("ProximityPrompt") then pcall(fireproximityprompt, pp); task.wait(0.1) end
            end
            task.wait(0.8)
        end
        task.wait(1)
    end
end

-- ══════════════════════════════════════════════════════
-- AUTO PICKUP GUN  (FIXED – touches GunDrop directly)
-- ══════════════════════════════════════════════════════
local function autoPickupGunLoop()
    while getgenv().MM2Config.autoPickupGun do
        if not roundActive or not isAlive() then task.wait(0.4); continue end
        local hrp = getRootPart(); if not hrp then task.wait(0.4); continue end
        local gunObj, part = findDroppedGun()
        if gunObj and part then
            -- Land directly on the gun (triggers server touch handler)
            hrp.CFrame = CFrame.new(part.Position + Vector3.new(0,1,0))
            task.wait(0.1)
            -- ProximityPrompt attempt
            for _, pp in ipairs(gunObj:GetDescendants()) do
                if pp:IsA("ProximityPrompt") then pcall(fireproximityprompt, pp); break end
            end
            -- Direct reparent fallback
            if gunObj:IsA("Tool") then pcall(function() gunObj.Parent = lp.Backpack end) end
        end
        task.wait(0.35)
    end
end

-- ── Kill All as Murderer ───────────────────────────────
local function killAllMurdererLoop()
    while getgenv().MM2Config.killAllMurderer do
        if not isAlive() then task.wait(0.5); continue end
        if getRole(lp) ~= "Murderer" then task.wait(0.5); continue end
        local c = getChar()
        if c and not c:FindFirstChild("Knife") then
            local bp = lp:FindFirstChild("Backpack")
            if bp then local k = bp:FindFirstChild("Knife"); if k then k.Parent = c end end
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp and p.Character then
                local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
                local hrp  = getRootPart()
                if tHRP and hrp then
                    hrp.CFrame = tHRP.CFrame * CFrame.new(0,0,3)
                    fireRemote("Attack", tHRP); task.wait(0.2)
                end
            end
        end
        task.wait(0.5)
    end
end

-- ── Kill Murderer as Sheriff ───────────────────────────
local function killMurdererSheriffLoop()
    while getgenv().MM2Config.killMurdererSheriff do
        if not isAlive() then task.wait(0.5); continue end
        if getRole(lp) ~= "Sheriff" then task.wait(0.5); continue end
        local c = getChar()
        if c and not c:FindFirstChild("Gun") then
            local bp = lp:FindFirstChild("Backpack")
            if bp then local g = bp:FindFirstChild("Gun"); if g then g.Parent = c end end
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp then
                local role = getRole(p)
                if role == "Murderer" and p.Character then
                    local mHRP = p.Character:FindFirstChild("HumanoidRootPart")
                    local hrp  = getRootPart()
                    if mHRP and hrp then
                        hrp.CFrame = mHRP.CFrame * CFrame.new(0,0,5)
                        fireRemote("Shoot", mHRP); task.wait(0.3)
                    end
                end
            end
        end
        task.wait(0.5)
    end
end

-- ── Auto Fling Murderer ────────────────────────────────
local function autoFlingLoop()
    while getgenv().MM2Config.autoFlingMurderer do
        if not isAlive() then task.wait(0.5); continue end
        if getRole(lp) ~= "Sheriff" then task.wait(0.5); continue end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp and getRole(p) == "Murderer" and p.Character then
                local mHRP = p.Character:FindFirstChild("HumanoidRootPart")
                local hrp  = getRootPart()
                if mHRP and hrp then
                    hrp.CFrame = mHRP.CFrame * CFrame.new(0,0,2)
                    fireRemote("Shoot", mHRP); task.wait(0.15)
                end
            end
        end
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
        if getgenv().MM2Config.teleportUnderMapFullBag and isBagFull() then
            local hrp = getRootPart(); if hrp then hrp.CFrame = CFrame.new(0,-500,0) end
        end
        task.wait(0.5)
    end
end)
task.spawn(function()
    while true do
        if getgenv().MM2Config.resetOnFullBag and isBagFull() then
            local c = getChar(); if c then pcall(function() c:BreakJoints() end) end
        end
        task.wait(0.5)
    end
end)

-- ══════════════════════════════════════════════════════
-- WINDUI LOAD  (standalone only)
-- ══════════════════════════════════════════════════════
local WindUI = getgenv().QuantumX_WindUI
if not WindUI then
    print("[QuantumX MM2] Standalone – loading WindUI…")
    local ok, src = pcall(game.HttpGet, game, "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua")
    if ok and type(src) == "string" and #src > 100 then
        local okC, fn = pcall(loadstring, src)
        if okC and type(fn) == "function" then
            local okE, lib = pcall(fn)
            if okE and lib then WindUI = lib; getgenv().QuantumX_WindUI = WindUI
            else warn("[QuantumX MM2] WindUI exec: "..tostring(lib)) end
        end
    end
end
if not WindUI then warn("[QuantumX MM2] ❌ No WindUI – loops active, no GUI."); return end

if not getgenv().QuantumX_Loader_Loaded then
    pcall(function() WindUI:SetTheme({ SchemeColor = Color3.fromHex("#7C3AED"), Background = Color3.fromHex("#0D0D14"), Header = Color3.fromHex("#13131F"), TextColor = Color3.fromRGB(230,220,255), ElementColor = Color3.fromHex("#1A1A2E") }) end)
    pcall(function() WindUI:SetAccent(Color3.fromHex("#7C3AED")) end)
end

-- ── Window ─────────────────────────────────────────────
local Window    = getgenv().QuantumX_Window
local standalone = not Window

if standalone then
    local ok, r = pcall(function()
        return WindUI:CreateWindow({
            Title = "Quantum X | MM2", SubTitle = DISCORD, Author = DISCORD,
            Size = UDim2.new(0,580,0,580),
            Transparent = true, Theme = "Dark", Resizable = true,
            SideBarWidth = 200, BackgroundImageTransparency = 0.42,
            HideSearchBar = true, ScrollBarEnabled = false,
            User = { Enabled = true, Anonymous = false, Callback = function() end },
        })
    end)
    if not ok or r == nil then warn("[QuantumX MM2] ❌ Window failed: "..tostring(r)); return end
    Window = r; getgenv().QuantumX_Window = Window
    pcall(function() Window:Tag({ Title = VERSION, Icon = "discord", Color = Color3.fromRGB(255,255,255), Radius = 13 }) end)
    print("[QuantumX MM2] Standalone window created.")
else
    print("[QuantumX MM2] Loader window reused.")
end

-- ══════════════════════════════════════════════════════
-- GUI TABS
-- ══════════════════════════════════════════════════════

-- ESP Tab
local EspTab  = Window:Tab({ Title = "ESP", Icon = "rbxassetid://4483362458" })
local EspSec  = EspTab:Section({ Title = "👁️  Player ESP", Icon = "eye", Opened = true })
EspSec:Toggle({ Title = "Player ESP  (Murderer / Sheriff / Innocent)", Default = false, Callback = function(v)
    getgenv().MM2Config.espEnabled = v; if v then task.spawn(espLoop) end
end })
EspSec:Toggle({ Title = "Gun ESP  (dropped gun highlight)", Default = false, Callback = function(v)
    getgenv().MM2Config.gunEspEnabled = v; if v then task.spawn(gunEspLoop) end
end })
local GunSec = EspTab:Section({ Title = "🔫  Gun Teleport", Icon = "crosshair", Opened = true })
GunSec:Button({ Title = "Teleport to Dropped Gun", Callback = teleportToGun })

-- Auto Farm Tab
local AutoTab   = Window:Tab({ Title = "Auto Farm", Icon = "rbxassetid://4483362458" })
local CoinSec   = AutoTab:Section({ Title = "💰  Coin Farming", Icon = "coins",   Opened = true })
local BagSec    = AutoTab:Section({ Title = "💼  Coin Bag",     Icon = "package", Opened = true })
local WeaponSec = AutoTab:Section({ Title = "🔫  Weapons",      Icon = "sword",   Opened = true })
local KillSec   = AutoTab:Section({ Title = "⚔️  Kill",         Icon = "skull",   Opened = true })

CoinSec:Toggle({ Title = "Auto Farm Coins  (flees if murderer < 60 studs)", Default = false, Callback = function(v)
    getgenv().MM2Config.autoFarmCoins = v; if v then task.spawn(coinFarmLoop) end
end })
CoinSec:Toggle({ Title = "Auto Open Crates", Default = false, Callback = function(v)
    getgenv().MM2Config.autoOpenCrates = v; if v then task.spawn(autoOpenCratesLoop) end
end })

BagSec:Toggle({ Title = "Teleport Under Map at Full Bag", Default = false, Callback = function(v)
    getgenv().MM2Config.teleportUnderMapFullBag = v
end })
BagSec:Toggle({ Title = "Reset Character at Full Bag", Default = false, Callback = function(v)
    getgenv().MM2Config.resetOnFullBag = v
end })

WeaponSec:Toggle({ Title = "Auto Pickup Gun", Default = false, Callback = function(v)
    getgenv().MM2Config.autoPickupGun = v; if v then task.spawn(autoPickupGunLoop) end
end })

KillSec:Toggle({ Title = "Kill All as Murderer  (auto-equip knife)", Default = false, Callback = function(v)
    getgenv().MM2Config.killAllMurderer = v; if v then task.spawn(killAllMurdererLoop) end
end })
KillSec:Toggle({ Title = "Kill Murderer as Sheriff  (auto-equip + shoot)", Default = false, Callback = function(v)
    getgenv().MM2Config.killMurdererSheriff = v; if v then task.spawn(killMurdererSheriffLoop) end
end })
KillSec:Toggle({ Title = "Auto Fling Murderer  (as Sheriff)", Default = false, Callback = function(v)
    getgenv().MM2Config.autoFlingMurderer = v; if v then task.spawn(autoFlingLoop) end
end })

-- Credits Tab
local CredTab  = Window:Tab({ Title = "Credits", Icon = "rbxassetid://4483362458" })
local CredSec  = CredTab:Section({ Title = "Quantum X", Icon = "info", Opened = true })
CredSec:Paragraph({ Title = "Quantum X  "..VERSION, Content = "Developed by Quantum Team" })
CredSec:Button({ Title = "Copy Discord  –  "..DISCORD, Callback = function()
    pcall(function() setclipboard(DISCORD); print("[QuantumX] Copied: "..DISCORD) end)
end })

-- Standalone Movement Tab
if standalone then
    local MTab  = Window:Tab({ Title = "Movement", Icon = "rbxassetid://4483362458" })
    local SpSec = MTab:Section({ Title = "⚡ Speed & Noclip", Icon = "zap", Opened = true })
    SpSec:Toggle({ Title = "Speed Hack", Default = false, Callback = function(v) getgenv().MM2Config.speedEnabled = v end })
    SpSec:Slider({ Title = "Walk Speed", Min = 16, Max = 350, Default = 16, Callback = function(v) getgenv().MM2Config.speedValue = v end })
    SpSec:Toggle({ Title = "Noclip",     Default = false, Callback = function(v) getgenv().MM2Config.noclipEnabled = v end })
    local DevS = MTab:Section({ Title = "🔧 Dev Tools", Icon = "terminal", Opened = false })
    DevS:Button({ Title = "Infinite Yield", Callback = function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end) end })
    DevS:Button({ Title = "Dex Explorer",   Callback = function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))() end) end })
end

print("[QuantumX MM2] ✅ All features ready!")
