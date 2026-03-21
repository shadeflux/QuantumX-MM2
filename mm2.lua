--[[
    ╔══════════════════════════════════════════════╗
    ║      Quantum X  –  Murder Mystery 2          ║
    ║  Pełne funkcje: ESP, Farm, Kill, Fling…      ║
    ║                                              ║
    ║  Może działać samodzielnie LUB jako moduł    ║
    ║  załadowany przez loader.lua.                ║
    ╚══════════════════════════════════════════════╝

    Bezpośrednie użycie (bez loadera):
        loadstring(game:HttpGet("https://raw.githubusercontent.com/shadeflux/QuantumX-MM2/main/mm2.lua"))()

    PlaceId Murder Mystery 2: 142823291
]]

-- ───────────────────────────────────────────
-- 1. ANTI-DUPLICATE GUARD
-- ───────────────────────────────────────────
if getgenv().QuantumX_MM2_Loaded then
    warn("[QuantumX MM2] Już załadowany – przerywam.")
    return
end
getgenv().QuantumX_MM2_Loaded = true

print("[QuantumX MM2] Inicjalizacja…")

-- ───────────────────────────────────────────
-- 2. WERYFIKACJA GAMY  (opcjonalne ostrzeżenie)
-- ───────────────────────────────────────────
local MM2_PLACE_ID = 142823291
if game.PlaceId ~= MM2_PLACE_ID then
    warn(string.format(
        "[QuantumX MM2] ⚠️ PlaceId %d ≠ %d (MM2). Część funkcji może nie działać.",
        game.PlaceId, MM2_PLACE_ID
    ))
end

-- ───────────────────────────────────────────
-- 3. SERVICES
-- ───────────────────────────────────────────
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp                = Players.LocalPlayer

-- ───────────────────────────────────────────
-- 4. KONFIGURACJA MM2
--    Prędkość synchronizuje się z loaderem,
--    jeśli ten jest aktywny.
-- ───────────────────────────────────────────
getgenv().MM2Config = {
    espEnabled              = false,
    gunEspEnabled           = false,
    -- Speed/Noclip: loader ma priorytety; jeśli loader jest, używamy jego config
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

-- Jeśli loader jest aktywny – deleguj speed/noclip do jego configu
local function isSpeedEnabled()
    if getgenv().QuantumX_Config then
        return getgenv().QuantumX_Config.speedEnabled or getgenv().MM2Config.speedEnabled
    end
    return getgenv().MM2Config.speedEnabled
end

local function getSpeedValue()
    if getgenv().QuantumX_Config then
        return getgenv().QuantumX_Config.speedValue
    end
    return getgenv().MM2Config.speedValue
end

local function isNoclipEnabled()
    if getgenv().QuantumX_Config then
        return getgenv().QuantumX_Config.noclipEnabled or getgenv().MM2Config.noclipEnabled
    end
    return getgenv().MM2Config.noclipEnabled
end

-- ───────────────────────────────────────────
-- 5. UTILITY FUNCTIONS
-- ───────────────────────────────────────────
local function getChar()
    return lp.Character
end

local function getHumanoid()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function getCoinBag()
    local c = getChar()
    return c and c:FindFirstChild("CoinBag")
end

local function safeFireRemote(remoteName, ...)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        or ReplicatedStorage:FindFirstChild("RemoteEvents")
    local remote
    if remotes then
        remote = remotes:FindFirstChild(remoteName)
    else
        remote = ReplicatedStorage:FindFirstChild(remoteName)
    end
    if remote then
        pcall(function() remote:FireServer(...) end)
        return true
    end
    -- Fallback: szukaj po całym ReplicatedStorage
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == remoteName and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
            pcall(function() v:FireServer(...) end)
            return true
        end
    end
    return false
end

-- ───────────────────────────────────────────
-- 6. WYKRYWANIE ROLI
-- ───────────────────────────────────────────
local function getRoleInfo(plr)
    local char = plr.Character
    if not char then return "Unknown", Color3.fromRGB(255, 255, 255) end

    local backpack = plr:FindFirstChild("Backpack")

    local hasKnife = char:FindFirstChild("Knife")
        or (backpack and backpack:FindFirstChild("Knife"))
    if hasKnife then
        return "Murderer", Color3.fromRGB(255, 50, 50)
    end

    local hasGun = char:FindFirstChild("Gun")
        or (backpack and backpack:FindFirstChild("Gun"))
    if hasGun then
        return "Sheriff", Color3.fromRGB(50, 120, 255)
    end

    return "Innocent", Color3.fromRGB(50, 255, 100)
end

-- ───────────────────────────────────────────
-- 7. NAMEPLATE (etykieta nad głową)
-- ───────────────────────────────────────────
local function createNameplate(plr, role, color)
    local char = plr.Character
    if not char then return end

    local old = char:FindFirstChild("QuantumNameplate")
    if old then old:Destroy() end

    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    if not head then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name          = "QuantumNameplate"
    billboard.Adornee       = head
    billboard.Size          = UDim2.new(0, 220, 0, 40)
    billboard.StudsOffset   = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop   = true
    billboard.ResetOnSpawn  = false

    local label = Instance.new("TextLabel")
    label.Size                 = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text                 = string.format("[%s]\n%s", role, plr.Name)
    label.TextColor3           = color
    label.TextStrokeTransparency = 0.4
    label.TextStrokeColor3     = Color3.new(0, 0, 0)
    label.TextScaled           = true
    label.Font                 = Enum.Font.SourceSansBold
    label.Parent               = billboard

    billboard.Parent = char
end

local function removeAllNameplates()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then
            local np = plr.Character:FindFirstChild("QuantumNameplate")
            if np then np:Destroy() end
        end
    end
end

-- ───────────────────────────────────────────
-- 8. ESP GRACZY
-- ───────────────────────────────────────────
local function espLoop()
    while getgenv().MM2Config.espEnabled do
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= lp and plr.Character then
                local role, color = getRoleInfo(plr)

                -- Highlight
                local highlight = plr.Character:FindFirstChild("QuantumESP")
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name         = "QuantumESP"
                    highlight.DepthMode    = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.FillTransparency    = 0.45
                    highlight.OutlineTransparency = 0
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.Parent       = plr.Character
                end
                highlight.FillColor = color

                -- Nameplate
                createNameplate(plr, role, color)
            end
        end
        task.wait(0.2)
    end

    -- Cleanup po wyłączeniu
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then
            local h = plr.Character:FindFirstChild("QuantumESP")
            if h then h:Destroy() end
        end
    end
    removeAllNameplates()
    print("[QuantumX MM2] ESP wyłączony – cleanup.")
end

-- ───────────────────────────────────────────
-- 9. GUN ESP (porzucony pistolet)
-- ───────────────────────────────────────────
local function isGunHeld(obj)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character and obj:IsDescendantOf(plr.Character) then
            return true
        end
    end
    return false
end

local function gunEspLoop()
    while getgenv().MM2Config.gunEspEnabled do
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local isGun = (obj:IsA("Tool") and obj.Name == "Gun")
                or (obj:IsA("Model") and obj.Name:lower():find("gun"))
            if isGun and not isGunHeld(obj) then
                local h = obj:FindFirstChild("GunESP")
                if not h then
                    h = Instance.new("Highlight")
                    h.Name                = "GunESP"
                    h.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
                    h.FillTransparency    = 0.3
                    h.OutlineTransparency = 0
                    h.OutlineColor        = Color3.fromRGB(255, 255, 255)
                    h.FillColor           = Color3.fromRGB(255, 165, 0)
                    h.Parent              = obj
                end
            end
        end
        task.wait(0.3)
    end

    -- Cleanup
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local h = obj:FindFirstChild("GunESP")
        if h then h:Destroy() end
    end
    print("[QuantumX MM2] Gun ESP wyłączony – cleanup.")
end

-- ───────────────────────────────────────────
-- 10. ZNAJDŹ PORZUCONY PISTOLET
-- ───────────────────────────────────────────
local function getDroppedGun()
    local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local best, bestDist = nil, math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local isGun = (obj:IsA("Tool") and obj.Name == "Gun")
            or (obj:IsA("Model") and obj.Name:lower():find("gun"))
        if isGun and not isGunHeld(obj) then
            local part = obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local dist = (part.Position - hrp.Position).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    best = part
                end
            end
        end
    end
    return best
end

-- ───────────────────────────────────────────
-- 11. TELEPORT DO PISTOLETU
-- ───────────────────────────────────────────
local function teleportToGun()
    local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
    if not hrp then
        warn("[QuantumX MM2] Brak HumanoidRootPart.")
        return
    end
    local targetPart = getDroppedGun()
    if targetPart then
        hrp.CFrame = targetPart.CFrame * CFrame.new(0, 2, 0)
        print("[QuantumX MM2] Teleport do pistoletu ✅")
    else
        warn("[QuantumX MM2] Nie znaleziono porzuconego pistoletu na mapie.")
    end
end

-- ───────────────────────────────────────────
-- 12. SPEED HACK (własna pętla MM2 – active
--     tylko gdy loader NIE jest załadowany)
-- ───────────────────────────────────────────
if not getgenv().QuantumX_Loader_Loaded then
    task.spawn(function()
        while true do
            if isSpeedEnabled() then
                local hum = getHumanoid()
                if hum then hum.WalkSpeed = getSpeedValue() end
            end
            task.wait()
        end
    end)

    -- Noclip (własna pętla – tylko bez loadera)
    RunService.Stepped:Connect(function()
        if isNoclipEnabled() then
            local char = getChar()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
    print("[QuantumX MM2] Standalone: Speed/Noclip loops aktywne.")
else
    print("[QuantumX MM2] Loader wykryty – Speed/Noclip delegowane do loadera.")
end

-- ───────────────────────────────────────────
-- 13. AUTO FARM COINS (z ucieczką przed mordercą)
-- ───────────────────────────────────────────
local function coinFarmLoop()
    while getgenv().MM2Config.autoFarmCoins do
        local ok2, err2 = pcall(function()
            local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            -- Zbierz monety z Workspace
            local coins = {}
            for _, coin in ipairs(Workspace:GetDescendants()) do
                if coin:IsA("Model") and (
                    coin.Name:lower():find("coin") or coin.Name:lower():find("money")
                ) then
                    local part = coin:FindFirstChildWhichIsA("BasePart")
                    if part then
                        table.insert(coins, { model = coin, part = part })
                    end
                end
            end
            if #coins == 0 then return end

            -- Znajdź mordercę
            local mPos = nil
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp then
                    local role, _ = getRoleInfo(plr)
                    if role == "Murderer" and plr.Character then
                        local mHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                        if mHRP then mPos = mHRP.Position end
                        break
                    end
                end
            end

            -- Ucieczka: jeśli morderca jest blisko, teleportuj do najdalszej monety
            if mPos then
                local distToMurderer = (mPos - hrp.Position).Magnitude
                if distToMurderer < getgenv().MM2Config.safeDistance then
                    local farthestCoin, farthestDist = nil, -math.huge
                    for _, coin in ipairs(coins) do
                        local d = (mPos - coin.part.Position).Magnitude
                        if d > farthestDist then
                            farthestDist = d
                            farthestCoin = coin.part
                        end
                    end
                    if farthestCoin then
                        hrp.CFrame = farthestCoin.CFrame * CFrame.new(0, 2, 0)
                        task.wait(0.25)
                        return
                    end
                end
            end

            -- Normalny tryb: teleport do najbliższej monety
            local nearestCoin, nearestDist = nil, math.huge
            for _, coin in ipairs(coins) do
                local d = (coin.part.Position - hrp.Position).Magnitude
                if d < nearestDist then
                    nearestDist = d
                    nearestCoin = coin.part
                end
            end
            if nearestCoin then
                hrp.CFrame = nearestCoin.CFrame * CFrame.new(0, 2, 0)
            end
        end)
        if not ok2 then
            warn("[QuantumX MM2] coinFarmLoop error:", err2)
        end
        task.wait(0.05)
    end
end

-- ───────────────────────────────────────────
-- 14. AUTO OPEN CRATES
-- ───────────────────────────────────────────
local function autoOpenCratesLoop()
    while getgenv().MM2Config.autoOpenCrates do
        local ok2, err2 = pcall(function()
            local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, crate in ipairs(Workspace:GetDescendants()) do
                if crate:IsA("Model") and crate.Name:lower():find("crate") then
                    local part = crate:FindFirstChildWhichIsA("BasePart")
                    if part then
                        hrp.CFrame = part.CFrame * CFrame.new(0, 2, 0)
                        task.wait(0.4)
                        safeFireRemote("OpenCrate", crate)
                        task.wait(0.6)
                    end
                end
            end
        end)
        if not ok2 then warn("[QuantumX MM2] autoOpenCratesLoop error:", err2) end
        task.wait(1)
    end
end

-- ───────────────────────────────────────────
-- 15. DIE AT FULL BAG
-- ───────────────────────────────────────────
task.spawn(function()
    while true do
        if getgenv().MM2Config.dieAtFullBag then
            pcall(function()
                local bag = getCoinBag()
                if bag then
                    local amountVal = bag:FindFirstChild("Amount")
                    local maxVal    = bag:FindFirstChild("MaxAmount")
                    if amountVal and maxVal and amountVal.Value >= maxVal.Value then
                        local hum = getHumanoid()
                        if hum then hum.Health = 0 end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- ───────────────────────────────────────────
-- 16. TELEPORT POD MAPĘ PRZY PEŁNYM WORKU
-- ───────────────────────────────────────────
task.spawn(function()
    while true do
        if getgenv().MM2Config.teleportUnderMapFullBag then
            pcall(function()
                local bag = getCoinBag()
                if bag then
                    local amountVal = bag:FindFirstChild("Amount")
                    local maxVal    = bag:FindFirstChild("MaxAmount")
                    if amountVal and maxVal and amountVal.Value >= maxVal.Value then
                        local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.CFrame = CFrame.new(0, -500, 0)
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- ───────────────────────────────────────────
-- 17. RESET ON FULL BAG
-- ───────────────────────────────────────────
task.spawn(function()
    while true do
        if getgenv().MM2Config.resetOnFullBag then
            pcall(function()
                local bag = getCoinBag()
                if bag then
                    local amountVal = bag:FindFirstChild("Amount")
                    local maxVal    = bag:FindFirstChild("MaxAmount")
                    if amountVal and maxVal and amountVal.Value >= maxVal.Value then
                        local char = getChar()
                        if char then char:BreakJoints() end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- ───────────────────────────────────────────
-- 18. AUTO FLING MURDERER (jako szeryf)
-- ───────────────────────────────────────────
local function autoFlingMurdererLoop()
    while getgenv().MM2Config.autoFlingMurderer do
        pcall(function()
            local myRole, _ = getRoleInfo(lp)
            if myRole ~= "Sheriff" then return end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp then
                    local role, _ = getRoleInfo(plr)
                    if role == "Murderer" and plr.Character then
                        local mHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                        local hrp  = getChar() and getChar():FindFirstChild("HumanoidRootPart")
                        if mHRP and hrp then
                            hrp.CFrame = mHRP.CFrame * CFrame.new(0, 0, 3)
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

-- ───────────────────────────────────────────
-- 19. KILL ALL AS MURDERER (auto-equip noża)
-- ───────────────────────────────────────────
local function killAllMurdererLoop()
    while getgenv().MM2Config.killAllMurderer do
        pcall(function()
            local myRole, _ = getRoleInfo(lp)
            if myRole ~= "Murderer" then return end

            -- Auto-equip noża z Backpacka
            local char = getChar()
            if char and not char:FindFirstChild("Knife") then
                local bp = lp:FindFirstChild("Backpack")
                if bp then
                    local knife = bp:FindFirstChild("Knife")
                    if knife then knife.Parent = char end
                end
            end

            -- Teleport + atak
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp and plr.Character then
                    local tHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                    local hrp  = getChar() and getChar():FindFirstChild("HumanoidRootPart")
                    if tHRP and hrp then
                        hrp.CFrame = tHRP.CFrame * CFrame.new(0, 0, 3)
                        safeFireRemote("Attack", tHRP)
                        task.wait(0.2)
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end

-- ───────────────────────────────────────────
-- 20. KILL MURDERER AS SHERIFF
--     (auto-equip pistoletu i strzał)
-- ───────────────────────────────────────────
local function killMurdererSheriffLoop()
    while getgenv().MM2Config.killMurdererSheriff do
        pcall(function()
            local myRole, _ = getRoleInfo(lp)
            if myRole ~= "Sheriff" then return end

            -- Auto-equip pistoletu z Backpacka
            local char = getChar()
            if char and not char:FindFirstChild("Gun") then
                local bp = lp:FindFirstChild("Backpack")
                if bp then
                    local gun = bp:FindFirstChild("Gun")
                    if gun then gun.Parent = char end
                end
            end

            -- Znajdź mordercę i strzelaj
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp then
                    local role, _ = getRoleInfo(plr)
                    if role == "Murderer" and plr.Character then
                        local mHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                        local hrp  = getChar() and getChar():FindFirstChild("HumanoidRootPart")
                        if mHRP and hrp then
                            hrp.CFrame = mHRP.CFrame * CFrame.new(0, 0, 5)
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

-- ───────────────────────────────────────────
-- 21. AUTO PICKUP GUN
-- ───────────────────────────────────────────
local function autoPickupGunLoop()
    while getgenv().MM2Config.autoPickupGun do
        pcall(function()
            local gunPart = getDroppedGun()
            if gunPart then
                local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = gunPart.CFrame * CFrame.new(0, 2, 0)
                    task.wait(0.1)
                    local tool = gunPart.Parent
                    if tool and tool:IsA("Tool") then
                        tool.Parent = lp.Backpack
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end

-- ───────────────────────────────────────────
-- 22. GUI
--    Jeśli loader jest aktywny i udostępnił
--    swoje okno → dodaj zakładki do niego.
--    W przeciwnym razie stwórz nowe okno.
-- ───────────────────────────────────────────

-- Załaduj WindUI (potrzebne tylko gdy loader go NIE załadował)
local WindUI = getgenv().QuantumX_WindUI
if not WindUI then
    local ok2, err2 = pcall(function()
        WindUI = loadstring(game:HttpGet(
            "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
        ))()
    end)
    if not ok2 or not WindUI then
        warn("[QuantumX MM2] ❌ WindUI nie załadowało się: " .. tostring(err2))
        return
    end
    getgenv().QuantumX_WindUI = WindUI
    print("[QuantumX MM2] WindUI załadowane (standalone).")
end

-- Użyj istniejącego okna loadera lub stwórz nowe
local Window = getgenv().QuantumX_Window
local standaloneMode = false

if not Window then
    -- Tryb standalone: tworzymy własne okno
    standaloneMode = true
    Window = WindUI:CreateWindow({
        Title    = "Quantum X | MM2",
        SubTitle = "by Quantum Team",
        Size     = UDim2.new(0, 580, 0, 540),
    })
    getgenv().QuantumX_Window = Window
    print("[QuantumX MM2] Standalone: własne okno GUI.")
else
    print("[QuantumX MM2] Loader wykryty: dodaję zakładki do istniejącego okna.")
end

-- ── Zakładka: ESP ──────────────────────────
local EspTab = Window:Tab({
    Title = "ESP",
    Icon  = "rbxassetid://4483362458",
})

EspTab:Section({ Title = "👁 Player ESP" })

EspTab:Toggle({
    Title    = "Player ESP (Murderer/Sheriff/Innocent)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.espEnabled = v
        if v then task.spawn(espLoop) end
        print("[QuantumX MM2] Player ESP:", v)
    end,
})

EspTab:Toggle({
    Title    = "Gun ESP (porzucony pistolet)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.gunEspEnabled = v
        if v then task.spawn(gunEspLoop) end
        print("[QuantumX MM2] Gun ESP:", v)
    end,
})

EspTab:Section({ Title = "🔫 Teleport" })

EspTab:Button({
    Title    = "Teleport do najbliższego pistoletu",
    Callback = teleportToGun,
})

-- ── Zakładka: Auto (Farm / Kill) ───────────
local AutoTab = Window:Tab({
    Title = "Auto",
    Icon  = "rbxassetid://4483362458",
})

AutoTab:Section({ Title = "💰 Farm" })

AutoTab:Toggle({
    Title    = "Auto Farm Coins (ucieczka przed mordercą)",
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

AutoTab:Toggle({
    Title    = "Auto Pickup Gun (podbiega po pistolet)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.autoPickupGun = v
        if v then task.spawn(autoPickupGunLoop) end
    end,
})

AutoTab:Section({ Title = "⚔️ Kill" })

AutoTab:Toggle({
    Title    = "Kill All jako Murderer (auto-equip nóż)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.killAllMurderer = v
        if v then task.spawn(killAllMurdererLoop) end
    end,
})

AutoTab:Toggle({
    Title    = "Kill Murderer jako Sheriff (auto-equip + strzał)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.killMurdererSheriff = v
        if v then task.spawn(killMurdererSheriffLoop) end
    end,
})

AutoTab:Toggle({
    Title    = "Auto Fling Murderer (jako Sheriff)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.autoFlingMurderer = v
        if v then task.spawn(autoFlingMurdererLoop) end
    end,
})

-- ── Zakładka: Coin Bag ─────────────────────
local BagTab = Window:Tab({
    Title = "Coin Bag",
    Icon  = "rbxassetid://4483362458",
})

BagTab:Section({ Title = "💼 Przy pełnym worku monet…" })

BagTab:Toggle({
    Title    = "Umrzyj (Die at Full Bag)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.dieAtFullBag = v
    end,
})

BagTab:Toggle({
    Title    = "Teleportuj pod mapę (Under Map)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.teleportUnderMapFullBag = v
    end,
})

BagTab:Toggle({
    Title    = "Reset postaci (BreakJoints)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.resetOnFullBag = v
    end,
})

-- ── Zakładka: Movement (tylko w trybie standalone) ──
if standaloneMode then
    local MoveTab = Window:Tab({
        Title = "Movement",
        Icon  = "rbxassetid://4483362458",
    })

    MoveTab:Section({ Title = "⚡ Poruszanie" })

    MoveTab:Toggle({
        Title    = "Speed Hack",
        Default  = false,
        Callback = function(v)
            getgenv().MM2Config.speedEnabled = v
        end,
    })

    MoveTab:Slider({
        Title    = "Speed Value",
        Min      = 16,
        Max      = 350,
        Default  = 16,
        Callback = function(v)
            getgenv().MM2Config.speedValue = v
        end,
    })

    MoveTab:Toggle({
        Title    = "Noclip",
        Default  = false,
        Callback = function(v)
            getgenv().MM2Config.noclipEnabled = v
        end,
    })

    -- Skrypty narzędziowe (tylko standalone)
    MoveTab:Section({ Title = "🔧 Dev Tools" })
    MoveTab:Button({
        Title    = "Infinite Yield",
        Callback = function()
            pcall(function()
                loadstring(game:HttpGet(
                    "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"
                ))()
            end)
        end,
    })
    MoveTab:Button({
        Title    = "Dex Explorer",
        Callback = function()
            pcall(function()
                loadstring(game:HttpGet(
                    "https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"
                ))()
            end)
        end,
    })
end

-- ── Zakładka: Credits (tylko standalone) ───
if standaloneMode then
    local CredTab = Window:Tab({
        Title = "Credits",
        Icon  = "rbxassetid://4483362458",
    })
    CredTab:AddLabel("Quantum X | Murder Mystery 2")
    CredTab:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    CredTab:AddLabel("ESP: Murderer=czerwony, Sheriff=niebieski, Innocent=zielony")
    CredTab:AddLabel("Gun ESP: pomarańczowy – porzucony pistolet")
    CredTab:AddLabel("Auto Farm: ucieczka przed mordercą (teleport do najdalszej monety)")
    CredTab:AddLabel("Kill All (Murderer): auto-equip nóż")
    CredTab:AddLabel("Kill Murderer (Sheriff): auto-equip pistolet + strzał")
    CredTab:AddLabel("UI: WindUI by Footagesus")
    CredTab:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    CredTab:AddLabel("Developed by Quantum Team")
    CredTab:AddLabel("Discord: discord.gg/quantumx")
    CredTab:AddLabel("GitHub: shadeflux/QuantumX-MM2")
end

print("[QuantumX MM2] ✅ Wszystkie funkcje załadowane pomyślnie!")
