--[[
    ╔══════════════════════════════════════════════════╗
    ║       Quantum X  –  mm2.lua                      ║
    ║  Murder Mystery 2 – pełne funkcje.               ║
    ║                                                  ║
    ║  Może działać samodzielnie LUB być załadowany    ║
    ║  przez loader.lua. W obu przypadkach działa      ║
    ║  identycznie – różni się tylko źródłem GUI.      ║
    ╚══════════════════════════════════════════════════╝

    Bezpośrednie użycie (standalone, bez loadera):
        loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/shadeflux/QuantumX-MM2/main/mm2.lua"
        ))()
]]

-- ─────────────────────────────────────────────────────────
-- SEKCJA 1: ANTI-DUPLICATE GUARD
-- ─────────────────────────────────────────────────────────
if getgenv().QuantumX_MM2_Loaded then
    warn("[QuantumX MM2] Już załadowany – przerywam duplikat.")
    return
end
getgenv().QuantumX_MM2_Loaded = true

-- ─────────────────────────────────────────────────────────
-- SEKCJA 2: SPRAWDZENIE GAMY
-- ─────────────────────────────────────────────────────────
local MM2_PLACE_ID = 142823291
if game.PlaceId ~= MM2_PLACE_ID then
    warn(string.format(
        "[QuantumX MM2] ⚠️ PlaceId %d ≠ %d. Część funkcji może nie działać.",
        game.PlaceId, MM2_PLACE_ID
    ))
end

-- ─────────────────────────────────────────────────────────
-- SEKCJA 3: SERVICES
-- ─────────────────────────────────────────────────────────
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp                = Players.LocalPlayer

-- ─────────────────────────────────────────────────────────
-- SEKCJA 4: KONFIGURACJA MM2
-- ─────────────────────────────────────────────────────────
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

-- ─────────────────────────────────────────────────────────
-- SEKCJA 5: DELEGACJA SPEED/NOCLIP DO LOADERA
--   Jeśli loader jest aktywny, speed/noclip odczytują
--   z jego konfiguracji zamiast z MM2Config.
--   Dzięki temu nie ma duplikowanych pętli.
-- ─────────────────────────────────────────────────────────
local function isSpeedEnabled()
    if getgenv().QuantumX_Config then
        return getgenv().QuantumX_Config.speedEnabled
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
        return getgenv().QuantumX_Config.noclipEnabled
    end
    return getgenv().MM2Config.noclipEnabled
end

-- ─────────────────────────────────────────────────────────
-- SEKCJA 6: UTILITY FUNCTIONS
-- ─────────────────────────────────────────────────────────
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

-- Wyszukuje Remote po nazwie w całym ReplicatedStorage
local function safeFireRemote(name, ...)
    local args = { ... }
    pcall(function()
        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v.Name == name and v:IsA("RemoteEvent") then
                v:FireServer(table.unpack(args))
                return
            end
        end
    end)
end

-- ─────────────────────────────────────────────────────────
-- SEKCJA 7: WYKRYWANIE ROLI
-- ─────────────────────────────────────────────────────────
local function getRoleInfo(plr)
    local char = plr.Character
    if not char then return "Unknown", Color3.fromRGB(255, 255, 255) end

    local bp = plr:FindFirstChild("Backpack")

    if char:FindFirstChild("Knife") or (bp and bp:FindFirstChild("Knife")) then
        return "Murderer", Color3.fromRGB(255, 50, 50)
    end
    if char:FindFirstChild("Gun") or (bp and bp:FindFirstChild("Gun")) then
        return "Sheriff", Color3.fromRGB(50, 130, 255)
    end
    return "Innocent", Color3.fromRGB(50, 255, 100)
end

-- ─────────────────────────────────────────────────────────
-- SEKCJA 8: NAMEPLATE (etykieta nad głową gracza)
-- ─────────────────────────────────────────────────────────
local function createNameplate(plr, role, color)
    local char = plr.Character
    if not char then return end

    local old = char:FindFirstChild("QuantumNameplate")
    if old then old:Destroy() end

    local adornee = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    if not adornee then return end

    local bb = Instance.new("BillboardGui")
    bb.Name             = "QuantumNameplate"
    bb.Adornee          = adornee
    bb.Size             = UDim2.new(0, 220, 0, 44)
    bb.StudsOffset      = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop      = true
    bb.ResetOnSpawn     = false

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = "[" .. role .. "]\n" .. plr.Name
    lbl.TextColor3             = color
    lbl.TextStrokeTransparency = 0.35
    lbl.TextStrokeColor3       = Color3.new(0, 0, 0)
    lbl.TextScaled             = true
    lbl.Font                   = Enum.Font.SourceSansBold
    lbl.Parent                 = bb
    bb.Parent                  = char
end

local function removeAllNameplates()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then
            local n = plr.Character:FindFirstChild("QuantumNameplate")
            if n then n:Destroy() end
        end
    end
end

-- ─────────────────────────────────────────────────────────
-- SEKCJA 9: ESP GRACZY
-- ─────────────────────────────────────────────────────────
local function espLoop()
    while getgenv().MM2Config.espEnabled do
        pcall(function()
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp and plr.Character then
                    local role, color = getRoleInfo(plr)

                    local h = plr.Character:FindFirstChild("QuantumESP")
                    if not h then
                        h = Instance.new("Highlight")
                        h.Name                = "QuantumESP"
                        h.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
                        h.FillTransparency    = 0.45
                        h.OutlineTransparency = 0
                        h.OutlineColor        = Color3.fromRGB(255, 255, 255)
                        h.Parent              = plr.Character
                    end
                    h.FillColor = color
                    createNameplate(plr, role, color)
                end
            end
        end)
        task.wait(0.2)
    end
    -- Cleanup
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then
            local h = plr.Character:FindFirstChild("QuantumESP")
            if h then h:Destroy() end
        end
    end
    removeAllNameplates()
end

-- ─────────────────────────────────────────────────────────
-- SEKCJA 10: GUN ESP (porzucony pistolet)
-- ─────────────────────────────────────────────────────────
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
        pcall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                local isGun = (obj:IsA("Tool") and obj.Name == "Gun")
                    or (obj:IsA("Model") and obj.Name:lower():find("gun"))
                if isGun and not isGunHeld(obj) then
                    if not obj:FindFirstChild("GunESP") then
                        local h = Instance.new("Highlight")
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
        end)
        task.wait(0.3)
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local h = obj:FindFirstChild("GunESP")
        if h then h:Destroy() end
    end
end

-- ─────────────────────────────────────────────────────────
-- SEKCJA 11: ZNAJDŹ PORZUCONY PISTOLET
-- ─────────────────────────────────────────────────────────
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
                local d = (part.Position - hrp.Position).Magnitude
                if d < bestDist then bestDist = d; best = part end
            end
        end
    end
    return best
end

-- ─────────────────────────────────────────────────────────
-- SEKCJA 12: TELEPORT DO PISTOLETU
-- ─────────────────────────────────────────────────────────
local function teleportToGun()
    local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
    if not hrp then warn("[QuantumX MM2] Brak HumanoidRootPart."); return end
    local part = getDroppedGun()
    if part then
        hrp.CFrame = part.CFrame * CFrame.new(0, 2, 0)
        print("[QuantumX MM2] ✅ Teleport do pistoletu.")
    else
        warn("[QuantumX MM2] Nie znaleziono porzuconego pistoletu.")
    end
end

-- ─────────────────────────────────────────────────────────
-- SEKCJA 13: SPEED / NOCLIP (tylko w trybie standalone)
--   Loader obsługuje te pętle globalnie – nie duplikujemy.
-- ─────────────────────────────────────────────────────────
if not getgenv().QuantumX_Loader_Loaded then
    print("[QuantumX MM2] Standalone – uruchamiam własne pętle Speed/Noclip.")

    task.spawn(function()
        while true do
            if isSpeedEnabled() then
                local hum = getHumanoid()
                if hum then hum.WalkSpeed = getSpeedValue() end
            end
            task.wait()
        end
    end)

    RunService.Stepped:Connect(function()
        if isNoclipEnabled() then
            local char = getChar()
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end
    end)
else
    print("[QuantumX MM2] Loader aktywny – Speed/Noclip obsługuje loader.")
end

-- ─────────────────────────────────────────────────────────
-- SEKCJA 14: AUTO FARM COINS (ucieczka przed mordercą)
-- ─────────────────────────────────────────────────────────
local function coinFarmLoop()
    while getgenv().MM2Config.autoFarmCoins do
        pcall(function()
            local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local coins = {}
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and (
                    obj.Name:lower():find("coin") or obj.Name:lower():find("money")
                ) then
                    local part = obj:FindFirstChildWhichIsA("BasePart")
                    if part then table.insert(coins, part) end
                end
            end
            if #coins == 0 then return end

            -- Pozycja mordercy (jeśli istnieje)
            local mPos = nil
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp then
                    local role = getRoleInfo(plr)
                    if role == "Murderer" and plr.Character then
                        local mHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                        if mHRP then mPos = mHRP.Position; break end
                    end
                end
            end

            -- Ucieczka: teleport do monety najdalszej od mordercy
            if mPos then
                local distToMe = (mPos - hrp.Position).Magnitude
                if distToMe < getgenv().MM2Config.safeDistance then
                    local farthest, fDist = nil, -math.huge
                    for _, part in ipairs(coins) do
                        local d = (mPos - part.Position).Magnitude
                        if d > fDist then fDist = d; farthest = part end
                    end
                    if farthest then
                        hrp.CFrame = farthest.CFrame * CFrame.new(0, 2, 0)
                        task.wait(0.25)
                        return
                    end
                end
            end

            -- Normalny tryb: najbliższa moneta
            local nearest, nDist = nil, math.huge
            for _, part in ipairs(coins) do
                local d = (part.Position - hrp.Position).Magnitude
                if d < nDist then nDist = d; nearest = part end
            end
            if nearest then
                hrp.CFrame = nearest.CFrame * CFrame.new(0, 2, 0)
            end
        end)
        task.wait(0.05)
    end
end

-- ─────────────────────────────────────────────────────────
-- SEKCJA 15: AUTO OPEN CRATES
-- ─────────────────────────────────────────────────────────
local function autoOpenCratesLoop()
    while getgenv().MM2Config.autoOpenCrates do
        pcall(function()
            local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj.Name:lower():find("crate") then
                    local part = obj:FindFirstChildWhichIsA("BasePart")
                    if part then
                        hrp.CFrame = part.CFrame * CFrame.new(0, 2, 0)
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

-- ─────────────────────────────────────────────────────────
-- SEKCJA 16: AUTO PICKUP GUN
-- ─────────────────────────────────────────────────────────
local function autoPickupGunLoop()
    while getgenv().MM2Config.autoPickupGun do
        pcall(function()
            local part = getDroppedGun()
            if part then
                local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = part.CFrame * CFrame.new(0, 2, 0)
                    task.wait(0.1)
                    local tool = part.Parent
                    if tool and tool:IsA("Tool") then
                        tool.Parent = lp.Backpack
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end

-- ─────────────────────────────────────────────────────────
-- SEKCJA 17: KILL ALL AS MURDERER (auto-equip noża)
-- ─────────────────────────────────────────────────────────
local function killAllMurdererLoop()
    while getgenv().MM2Config.killAllMurderer do
        pcall(function()
            local myRole = getRoleInfo(lp)
            if myRole ~= "Murderer" then return end

            local char = getChar()
            if char and not char:FindFirstChild("Knife") then
                local bp = lp:FindFirstChild("Backpack")
                if bp then
                    local knife = bp:FindFirstChild("Knife")
                    if knife then knife.Parent = char end
                end
            end

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

-- ─────────────────────────────────────────────────────────
-- SEKCJA 18: KILL MURDERER AS SHERIFF
-- ─────────────────────────────────────────────────────────
local function killMurdererSheriffLoop()
    while getgenv().MM2Config.killMurdererSheriff do
        pcall(function()
            local myRole = getRoleInfo(lp)
            if myRole ~= "Sheriff" then return end

            local char = getChar()
            if char and not char:FindFirstChild("Gun") then
                local bp = lp:FindFirstChild("Backpack")
                if bp then
                    local gun = bp:FindFirstChild("Gun")
                    if gun then gun.Parent = char end
                end
            end

            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp then
                    local role = getRoleInfo(plr)
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

-- ─────────────────────────────────────────────────────────
-- SEKCJA 19: AUTO FLING MURDERER (jako Sheriff)
-- ─────────────────────────────────────────────────────────
local function autoFlingMurdererLoop()
    while getgenv().MM2Config.autoFlingMurderer do
        pcall(function()
            local myRole = getRoleInfo(lp)
            if myRole ~= "Sheriff" then return end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp then
                    local role = getRoleInfo(plr)
                    if role == "Murderer" and plr.Character then
                        local mHRP = plr.Character:FindFirstChild("HumanoidRootPart")
                        local hrp  = getChar() and getChar():FindFirstChild("HumanoidRootPart")
                        if mHRP and hrp then
                            hrp.CFrame = mHRP.CFrame * CFrame.new(0, 0, 2)
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

-- ─────────────────────────────────────────────────────────
-- SEKCJA 20: AKCJE PRZY PEŁNYM WORKU (stałe pętle)
-- ─────────────────────────────────────────────────────────
local function checkBagFull()
    local bag = getCoinBag()
    if not bag then return false end
    local a = bag:FindFirstChild("Amount")
    local m = bag:FindFirstChild("MaxAmount")
    return a and m and a.Value >= m.Value
end

-- Die at full bag
task.spawn(function()
    while true do
        if getgenv().MM2Config.dieAtFullBag then
            pcall(function()
                if checkBagFull() then
                    local hum = getHumanoid()
                    if hum then hum.Health = 0 end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- Teleport pod mapę przy pełnym worku
task.spawn(function()
    while true do
        if getgenv().MM2Config.teleportUnderMapFullBag then
            pcall(function()
                if checkBagFull() then
                    local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
                    if hrp then hrp.CFrame = CFrame.new(0, -500, 0) end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- Reset (BreakJoints) przy pełnym worku
task.spawn(function()
    while true do
        if getgenv().MM2Config.resetOnFullBag then
            pcall(function()
                if checkBagFull() then
                    local char = getChar()
                    if char then char:BreakJoints() end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- ─────────────────────────────────────────────────────────
-- SEKCJA 21: GUI
--   Jeśli loader załadował WindUI i stworzył okno →
--   dodajemy zakładki do istniejącego okna.
--   W trybie standalone → tworzymy własne okno od zera.
-- ─────────────────────────────────────────────────────────
local WindUI = getgenv().QuantumX_WindUI
if not WindUI then
    print("[QuantumX MM2] Standalone – ładuję WindUI samodzielnie…")
    local ok, src = pcall(function()
        return game:HttpGet(
            "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
        )
    end)
    if ok and type(src) == "string" and #src > 100 then
        local okC, fn = pcall(loadstring, src)
        if okC and type(fn) == "function" then
            local okE, lib = pcall(fn)
            if okE and lib ~= nil then
                WindUI = lib
                getgenv().QuantumX_WindUI = WindUI
                print("[QuantumX MM2] ✅ WindUI załadowane (standalone).")
            else
                warn("[QuantumX MM2] ❌ WindUI exec fail: " .. tostring(lib))
            end
        else
            warn("[QuantumX MM2] ❌ WindUI compile fail: " .. tostring(fn))
        end
    else
        warn("[QuantumX MM2] ❌ WindUI HTTP fail: " .. tostring(src))
    end
end

if not WindUI then
    warn("[QuantumX MM2] ❌ Brak WindUI – GUI niedostępne. Funkcje działają w tle.")
    return
end

-- Użyj istniejącego okna lub stwórz nowe
local Window = getgenv().QuantumX_Window
local standalone = false

if not Window then
    standalone = true
    local ok, result = pcall(function()
        return WindUI:CreateWindow({
            Title    = "Quantum X | MM2",
            SubTitle = "by Quantum Team",
            Size     = UDim2.new(0, 580, 0, 560),
        })
    end)
    if ok and result then
        Window = result
        getgenv().QuantumX_Window = Window
        print("[QuantumX MM2] Standalone: własne okno GUI.")
    else
        warn("[QuantumX MM2] ❌ Błąd tworzenia okna: " .. tostring(result))
        return
    end
else
    print("[QuantumX MM2] Loader wykryty: dodaję zakładki do istniejącego okna.")
end

-- ── Zakładka ESP ────────────────────────────
local EspTab = Window:Tab({ Title = "ESP", Icon = "rbxassetid://4483362458" })

EspTab:Section({ Title = "👁 Player ESP" })
EspTab:Toggle({
    Title    = "Player ESP  (Murderer / Sheriff / Innocent)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.espEnabled = v
        if v then task.spawn(espLoop) end
    end,
})
EspTab:Toggle({
    Title    = "Gun ESP  (porzucony pistolet)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.gunEspEnabled = v
        if v then task.spawn(gunEspLoop) end
    end,
})
EspTab:Section({ Title = "🔫 Teleport" })
EspTab:Button({ Title = "Teleport do pistoletu", Callback = teleportToGun })

-- ── Zakładka Auto ────────────────────────────
local AutoTab = Window:Tab({ Title = "Auto", Icon = "rbxassetid://4483362458" })

AutoTab:Section({ Title = "💰 Farm" })
AutoTab:Toggle({
    Title    = "Auto Farm Coins  (ucieczka przed mordercą)",
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
    Title    = "Auto Pickup Gun",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.autoPickupGun = v
        if v then task.spawn(autoPickupGunLoop) end
    end,
})

AutoTab:Section({ Title = "⚔️ Kill" })
AutoTab:Toggle({
    Title    = "Kill All jako Murderer  (auto-equip nóż)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.killAllMurderer = v
        if v then task.spawn(killAllMurdererLoop) end
    end,
})
AutoTab:Toggle({
    Title    = "Kill Murderer jako Sheriff  (auto-equip + strzał)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.killMurdererSheriff = v
        if v then task.spawn(killMurdererSheriffLoop) end
    end,
})
AutoTab:Toggle({
    Title    = "Auto Fling Murderer  (jako Sheriff)",
    Default  = false,
    Callback = function(v)
        getgenv().MM2Config.autoFlingMurderer = v
        if v then task.spawn(autoFlingMurdererLoop) end
    end,
})

-- ── Zakładka Coin Bag ────────────────────────
local BagTab = Window:Tab({ Title = "Coin Bag", Icon = "rbxassetid://4483362458" })

BagTab:Section({ Title = "💼 Przy pełnym worku monet…" })
BagTab:Toggle({
    Title    = "Die at Full Bag  (umrzyj)",
    Default  = false,
    Callback = function(v) getgenv().MM2Config.dieAtFullBag = v end,
})
BagTab:Toggle({
    Title    = "Teleport Under Map at Full Bag",
    Default  = false,
    Callback = function(v) getgenv().MM2Config.teleportUnderMapFullBag = v end,
})
BagTab:Toggle({
    Title    = "Reset on Full Bag  (BreakJoints)",
    Default  = false,
    Callback = function(v) getgenv().MM2Config.resetOnFullBag = v end,
})

-- ── Zakładki tylko w trybie standalone ──────
if standalone then
    local MoveTab = Window:Tab({ Title = "Movement", Icon = "rbxassetid://4483362458" })
    MoveTab:Section({ Title = "⚡ Poruszanie" })
    MoveTab:Toggle({
        Title    = "Speed Hack",
        Default  = false,
        Callback = function(v) getgenv().MM2Config.speedEnabled = v end,
    })
    MoveTab:Slider({
        Title    = "Speed Value",
        Min      = 16,
        Max      = 350,
        Default  = 16,
        Callback = function(v) getgenv().MM2Config.speedValue = v end,
    })
    MoveTab:Toggle({
        Title    = "Noclip",
        Default  = false,
        Callback = function(v) getgenv().MM2Config.noclipEnabled = v end,
    })
    MoveTab:Section({ Title = "🔧 Dev Tools" })
    MoveTab:Button({
        Title = "Infinite Yield",
        Callback = function()
            pcall(function()
                loadstring(game:HttpGet(
                    "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"
                ))()
            end)
        end,
    })

    local CredTab = Window:Tab({ Title = "Credits", Icon = "rbxassetid://4483362458" })
    CredTab:AddLabel("Quantum X | Murder Mystery 2")
    CredTab:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    CredTab:AddLabel("ESP: czerwony=Murderer, niebieski=Sheriff, zielony=Innocent")
    CredTab:AddLabel("Gun ESP: pomarańczowy – porzucony pistolet")
    CredTab:AddLabel("Auto Farm: ucieczka (teleport do najdalszej monety)")
    CredTab:AddLabel("UI: WindUI by Footagesus")
    CredTab:AddLabel("Developed by Quantum Team  |  discord.gg/quantumx")
end

print("[QuantumX MM2] ✅ Wszystkie funkcje gotowe!")
