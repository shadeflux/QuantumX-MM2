--[[
    Quantum X | Murder Mystery 2
    Final – fixed Auto Shoot (Sheriff) and Auto Farm Escape
]]

if getgenv().QuantumX_MM2_Loaded then return end
getgenv().QuantumX_MM2_Loaded = true

-- ===== LOAD WINDUI =====
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
if not WindUI then
    warn("❌ WindUI failed to load")
    return
end

-- ===== SERVICES =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local lp = Players.LocalPlayer

-- ===== CONFIG =====
getgenv().MM2Config = {
    espEnabled = false,
    gunEspEnabled = false,
    speedEnabled = false,
    speedValue = 16,
    noclipEnabled = false,
    autoPickupGun = false,
    killAllMurderer = false,
    killMurdererSheriff = false,
    resetOnFullBag = false,
    autoFarmCoins = false,
    autoOpenCrates = false,
    dieAtFullBag = false,
    teleportUnderMapFullBag = false,
    autoFlingMurderer = false,
    safeDistance = 30, -- fixed
}

-- ===== UTILITIES =====
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

-- ===== DETECT ROLE =====
local function getRoleInfo(plr)
    local char = plr.Character
    if not char then return "Unknown", Color3.fromRGB(255,255,255) end

    if char:FindFirstChild("Knife") or (plr.Backpack and plr.Backpack:FindFirstChild("Knife")) then
        return "Murderer", Color3.fromRGB(255,0,0)
    end
    if char:FindFirstChild("Gun") or (plr.Backpack and plr.Backpack:FindFirstChild("Gun")) then
        return "Sheriff", Color3.fromRGB(0,100,255)
    end
    return "Innocent", Color3.fromRGB(0,255,0)
end

-- ===== NAMEPLATE =====
local function createNameplate(plr, role, color)
    local char = plr.Character
    if not char then return end

    local old = char:FindFirstChild("QuantumNameplate")
    if old then old:Destroy() end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "QuantumNameplate"
    billboard.Adornee = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    billboard.Size = UDim2.new(0, 200, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = string.format("%s\n%s", plr.Name, role)
    label.TextColor3 = color
    label.TextStrokeTransparency = 0.5
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Parent = billboard

    billboard.Parent = char
end

local function removeNameplates()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            local old = plr.Character:FindFirstChild("QuantumNameplate")
            if old then old:Destroy() end
        end
    end
end

-- ===== ESP LOOP =====
local function espLoop()
    while getgenv().MM2Config.espEnabled do
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= lp and plr.Character then
                local highlight = plr.Character:FindFirstChild("QuantumESP")
                if not highlight then
                    highlight = Instance.new("Highlight", plr.Character)
                    highlight.Name = "QuantumESP"
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.OutlineColor = Color3.fromRGB(255,255,255)
                end
                local _, color = getRoleInfo(plr)
                highlight.FillColor = color

                local role, _ = getRoleInfo(plr)
                createNameplate(plr, role, color)
            end
        end
        task.wait(0.2)
    end
    -- cleanup
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then
            local highlight = plr.Character:FindFirstChild("QuantumESP")
            if highlight then highlight:Destroy() end
        end
    end
    removeNameplates()
end

-- ===== FIND DROPPED GUN =====
local function getDroppedGun()
    local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local best, bestDist = nil, math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local isGun = (obj:IsA("Tool") and obj.Name == "Gun") or (obj:IsA("Model") and obj.Name:lower():find("gun"))
        if isGun then
            local held = false
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Character and obj:IsDescendantOf(plr.Character) then
                    held = true
                    break
                end
            end
            if not held then
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
    end
    return best
end

-- ===== GUN ESP LOOP =====
local function gunEspLoop()
    while getgenv().MM2Config.gunEspEnabled do
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local isGun = (obj:IsA("Tool") and obj.Name == "Gun") or (obj:IsA("Model") and obj.Name:lower():find("gun"))
            if isGun then
                local held = false
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr.Character and obj:IsDescendantOf(plr.Character) then
                        held = true
                        break
                    end
                end
                if not held then
                    local highlight = obj:FindFirstChild("GunESP")
                    if not highlight then
                        highlight = Instance.new("Highlight", obj)
                        highlight.Name = "GunESP"
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.FillTransparency = 0.3
                        highlight.OutlineTransparency = 0
                        highlight.OutlineColor = Color3.fromRGB(255,255,255)
                    end
                    highlight.FillColor = Color3.fromRGB(255, 165, 0)
                end
            end
        end
        task.wait(0.3)
    end
    -- cleanup
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("Tool") and obj.Name == "Gun") or (obj:IsA("Model") and obj.Name:lower():find("gun")) then
            local highlight = obj:FindFirstChild("GunESP")
            if highlight then highlight:Destroy() end
        end
    end
end

-- ===== TELEPORT TO DROPPED GUN =====
local function teleportToGun()
    local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local targetPart = getDroppedGun()
    if targetPart then
        hrp.CFrame = targetPart.CFrame * CFrame.new(0, 2, 0)
    else
        warn("No dropped gun found on the map")
    end
end

-- ===== SPEED HACK =====
local function speedLoop()
    while true do
        if getgenv().MM2Config.speedEnabled then
            local hum = getHumanoid()
            if hum then
                hum.WalkSpeed = getgenv().MM2Config.speedValue
            end
        end
        task.wait()
    end
end
task.spawn(speedLoop)

-- ===== NOCLIP =====
RunService.Stepped:Connect(function()
    if getgenv().MM2Config.noclipEnabled then
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

-- ===== AUTO FARM COINS (z ucieczką przed mordercą) =====
local function coinFarmLoop()
    while getgenv().MM2Config.autoFarmCoins do
        local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
        if not hrp then task.wait(0.05); continue end

        -- Znajdź mordercę
        local murdererChar = nil
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= lp then
                local role, _ = getRoleInfo(plr)
                if role == "Murderer" and plr.Character then
                    murdererChar = plr.Character
                    break
                end
            end
        end

        -- Zbierz wszystkie monety
        local coins = {}
        for _, coin in ipairs(Workspace:GetDescendants()) do
            if coin:IsA("Model") and (coin.Name:lower():find("coin") or coin.Name:lower():find("money")) then
                local part = coin:FindFirstChildWhichIsA("BasePart")
                if part then
                    table.insert(coins, {model = coin, part = part})
                end
            end
        end
        if #coins == 0 then task.wait(0.05); continue end

        -- Jeśli morderca istnieje, znajdź monetę bezpieczną (daleko od mordercy)
        if murdererChar then
            local mPos = murdererChar:FindFirstChild("HumanoidRootPart")
            if mPos then
                -- Sprawdź odległość od obecnej pozycji do mordercy
                local distToMurderer = (mPos.Position - hrp.Position).Magnitude
                if distToMurderer < getgenv().MM2Config.safeDistance then
                    -- Znajdź monetę najdalej od mordercy
                    local farthestCoin, farthestDist = nil, -math.huge
                    for _, coin in ipairs(coins) do
                        local coinDist = (mPos.Position - coin.part.Position).Magnitude
                        if coinDist > farthestDist then
                            farthestDist = coinDist
                            farthestCoin = coin.part
                        end
                    end
                    if farthestCoin then
                        hrp.CFrame = farthestCoin.CFrame * CFrame.new(0, 2, 0)
                        task.wait(0.2) -- chwila na teleport
                        continue -- od razu przejdź do następnej iteracji, żeby nie wrócić do niebezpiecznej monety
                    end
                end
            end
        end

        -- Normalne zbieranie – znajdź najbliższą monetę
        local nearestCoin, nearestDist = nil, math.huge
        for _, coin in ipairs(coins) do
            local dist = (coin.part.Position - hrp.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearestCoin = coin.part
            end
        end

        if nearestCoin then
            hrp.CFrame = nearestCoin.CFrame * CFrame.new(0, 2, 0)
        end
        task.wait(0.05)
    end
end

-- ===== AUTO OPEN CRATES =====
local function autoOpenCratesLoop()
    while getgenv().MM2Config.autoOpenCrates do
        local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, crate in ipairs(Workspace:GetDescendants()) do
                if crate:IsA("Model") and crate.Name:lower():find("crate") then
                    local part = crate:FindFirstChildWhichIsA("BasePart")
                    if part then
                        hrp.CFrame = part.CFrame * CFrame.new(0, 2, 0)
                        task.wait(0.5)
                        -- symulacja otwierania (remote)
                        local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                        if remote then
                            local openRemote = remote:FindFirstChild("OpenCrate")
                            if openRemote then openRemote:FireServer(crate) end
                        end
                    end
                end
            end
        end
        task.wait(1)
    end
end

-- ===== DIE AT FULL BAG =====
local function checkCoinBagLoop()
    while true do
        if getgenv().MM2Config.dieAtFullBag then
            local bag = getCoinBag()
            if bag and bag:FindFirstChild("Amount") then
                local amount = bag.Amount.Value
                local max = bag.MaxAmount.Value
                if amount >= max then
                    local hum = getHumanoid()
                    if hum then
                        hum.Health = 0
                    end
                end
            end
        end
        task.wait(0.5)
    end
end
task.spawn(checkCoinBagLoop)

-- ===== TELEPORT UNDER MAP AT FULL BAG =====
local function teleportUnderMapLoop()
    while true do
        if getgenv().MM2Config.teleportUnderMapFullBag then
            local bag = getCoinBag()
            if bag and bag:FindFirstChild("Amount") then
                local amount = bag.Amount.Value
                local max = bag.MaxAmount.Value
                if amount >= max then
                    local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = CFrame.new(0, -500, 0)
                    end
                end
            end
        end
        task.wait(0.5)
    end
end
task.spawn(teleportUnderMapLoop)

-- ===== AUTO FLING MURDERER (jako szeryf) =====
local function autoFlingMurdererLoop()
    while getgenv().MM2Config.autoFlingMurderer do
        local myRole, _ = getRoleInfo(lp)
        if myRole == "Sheriff" then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp then
                    local role, _ = getRoleInfo(plr)
                    if role == "Murderer" and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        local target = plr.Character.HumanoidRootPart
                        local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.CFrame = target.CFrame * CFrame.new(0, 0, 3)
                            -- symulacja strzału
                            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvent")
                            if remote then
                                remote:FireServer("Shoot", target)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end

-- ===== KILL ALL AS MURDERER =====
local function killAllMurdererLoop()
    while getgenv().MM2Config.killAllMurderer do
        local myRole, _ = getRoleInfo(lp)
        if myRole == "Murderer" then
            -- Auto-equip knife
            local knife = lp.Character:FindFirstChild("Knife")
            if not knife then
                knife = lp.Backpack:FindFirstChild("Knife")
                if knife then
                    knife.Parent = lp.Character
                end
            end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local target = plr.Character.HumanoidRootPart
                    local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = target.CFrame * CFrame.new(0, 0, 3)
                        local remote = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvent")
                        if remote then
                            remote:FireServer("Attack", target)
                        end
                        task.wait(0.2)
                    end
                end
            end
        end
        task.wait(0.5)
    end
end

-- ===== KILL MURDERER AS SHERIFF (z auto-equip i strzałem) =====
local function killMurdererSheriffLoop()
    while getgenv().MM2Config.killMurdererSheriff do
        local myRole, _ = getRoleInfo(lp)
        if myRole == "Sheriff" then
            -- Auto-equip gun
            local gun = lp.Character:FindFirstChild("Gun")
            if not gun then
                gun = lp.Backpack:FindFirstChild("Gun")
                if gun then
                    gun.Parent = lp.Character
                end
            end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp then
                    local role, _ = getRoleInfo(plr)
                    if role == "Murderer" and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        local target = plr.Character.HumanoidRootPart
                        local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.CFrame = target.CFrame * CFrame.new(0, 0, 5)
                            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvent")
                            if remote then
                                remote:FireServer("Shoot", target)
                            end
                            task.wait(0.3)
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end

-- ===== AUTO PICKUP GUN =====
local function autoPickupGunLoop()
    while getgenv().MM2Config.autoPickupGun do
        local gunPart = getDroppedGun()
        if gunPart then
            local hrp = getChar() and getChar():FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = gunPart.CFrame * CFrame.new(0, 2, 0)
                local tool = gunPart.Parent
                if tool:IsA("Tool") then
                    tool.Parent = lp.Backpack
                end
            end
        end
        task.wait(0.5)
    end
end

-- ===== RESET ON FULL BAG =====
local function resetOnFullBagLoop()
    while true do
        if getgenv().MM2Config.resetOnFullBag then
            local bag = getCoinBag()
            if bag and bag:FindFirstChild("Amount") then
                local amount = bag.Amount.Value
                local max = bag.MaxAmount.Value
                if amount >= max then
                    lp.Character:BreakJoints()
                end
            end
        end
        task.wait(0.5)
    end
end
task.spawn(resetOnFullBagLoop)

-- ===== GUI =====
local Window = WindUI:CreateWindow({
    Title = "Quantum X | MM2",
    SubTitle = "by Quantum Team",
    Size = UDim2.new(0, 550, 0, 500),
})

-- Main Tab
local MainTab = Window:Tab({ Title = "Main", Icon = "rbxassetid://4483362458" })

MainTab:Section({ Title = "ESP" })
MainTab:Toggle({ Title = "Player ESP", Default = false, Callback = function(v) getgenv().MM2Config.espEnabled = v; if v then task.spawn(espLoop) end end })
MainTab:Toggle({ Title = "Gun ESP (Dropped Sheriff Gun)", Default = false, Callback = function(v) getgenv().MM2Config.gunEspEnabled = v; if v then task.spawn(gunEspLoop) end end })

MainTab:Section({ Title = "Movement" })
MainTab:Toggle({ Title = "Speed Hack", Default = false, Callback = function(v) getgenv().MM2Config.speedEnabled = v end })
MainTab:Slider({ Title = "Speed Value", Min = 16, Max = 250, Default = 16, Callback = function(v) getgenv().MM2Config.speedValue = v end })
MainTab:Toggle({ Title = "Noclip", Default = false, Callback = function(v) getgenv().MM2Config.noclipEnabled = v end })

MainTab:Section({ Title = "Gun Teleport" })
MainTab:Button({ Title = "Teleport to Nearest Dropped Gun", Callback = teleportToGun })

-- Auto Tab
local AutoTab = Window:Tab({ Title = "Auto", Icon = "rbxassetid://4483362458" })

AutoTab:Section({ Title = "Farm" })
AutoTab:Toggle({ Title = "Auto Farm Coins (Escapes Murderer)", Default = false, Callback = function(v) getgenv().MM2Config.autoFarmCoins = v; if v then task.spawn(coinFarmLoop) end end })
AutoTab:Toggle({ Title = "Auto Open Crates", Default = false, Callback = function(v) getgenv().MM2Config.autoOpenCrates = v; if v then task.spawn(autoOpenCratesLoop) end end })

AutoTab:Section({ Title = "Gun" })
AutoTab:Toggle({ Title = "Auto Pickup Gun", Default = false, Callback = function(v) getgenv().MM2Config.autoPickupGun = v; if v then task.spawn(autoPickupGunLoop) end end })

AutoTab:Section({ Title = "Kill" })
AutoTab:Toggle({ Title = "Kill All as Murderer (Auto-Equip Knife)", Default = false, Callback = function(v) getgenv().MM2Config.killAllMurderer = v; if v then task.spawn(killAllMurdererLoop) end end })
AutoTab:Toggle({ Title = "Kill Murderer as Sheriff (Auto-Equip Gun)", Default = false, Callback = function(v) getgenv().MM2Config.killMurdererSheriff = v; if v then task.spawn(killMurdererSheriffLoop) end end })
AutoTab:Toggle({ Title = "Auto Fling Murderer (as Sheriff)", Default = false, Callback = function(v) getgenv().MM2Config.autoFlingMurderer = v; if v then task.spawn(autoFlingMurdererLoop) end end })

AutoTab:Section({ Title = "Coin Bag" })
AutoTab:Toggle({ Title = "Die At Full Bag", Default = false, Callback = function(v) getgenv().MM2Config.dieAtFullBag = v end })
AutoTab:Toggle({ Title = "Teleport Under Map At Full Bag", Default = false, Callback = function(v) getgenv().MM2Config.teleportUnderMapFullBag = v end })
AutoTab:Toggle({ Title = "Reset on Full Bag", Default = false, Callback = function(v) getgenv().MM2Config.resetOnFullBag = v end })

-- Scripts Tab
local ScriptsTab = Window:Tab({ Title = "Scripts", Icon = "rbxassetid://4483362458" })
ScriptsTab:Button({ Title = "Infinite Yield", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end })
ScriptsTab:Button({ Title = "Dex Explorer", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))() end })
ScriptsTab:Button({ Title = "SimpleSpy", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpyBeta.lua"))() end })

-- Credits Tab
local CreditsTab = Window:Tab({ Title = "Credits", Icon = "rbxassetid://4483362458" })
CreditsTab:AddLabel("Quantum X | Murder Mystery 2")
CreditsTab:AddLabel("ESP: Murderer (red), Sheriff (blue), Innocent (green)")
CreditsTab:AddLabel("Gun ESP: orange for dropped guns")
CreditsTab:AddLabel("Auto Farm with Murderer Evasion (teleport to farthest coin)")
CreditsTab:AddLabel("Kill All (Murderer) auto-equips knife")
CreditsTab:AddLabel("Kill Murderer (Sheriff) auto-equips gun and shoots")
CreditsTab:AddLabel("UI: WindUI (Footagesus)")
CreditsTab:AddLabel("Developed by Quantum Team")
CreditsTab:AddLabel("Discord: discord.gg/quantumx")
