--[[
    Quantum X | Murder Mystery 2
    Single file – works with any executor
]]

if getgenv().QuantumX_MM2_Loaded then return end
getgenv().QuantumX_MM2_Loaded = true

-- ===== LOAD WINDUI =====
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/zzerexx/WindUI/main/source.lua"))()

-- ===== CONFIG =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

getgenv().MM2Config = {
    espEnabled = false,
    autoCollect = false,
    autoFarm = false,
    speedEnabled = false,
    speedValue = 16,
}

-- ===== UTILITIES =====
local function getChar()
    return lp.Character
end

local function getHumanoid()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ===== ESP =====
local function setupESP()
    while getgenv().MM2Config.espEnabled do
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= lp and plr.Character then
                local hl = plr.Character:FindFirstChild("QuantumESP")
                if not hl then
                    hl = Instance.new("Highlight", plr.Character)
                    hl.Name = "QuantumESP"
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.FillTransparency = 0.5
                    hl.OutlineTransparency = 0
                    hl.OutlineColor = Color3.fromRGB(255,255,255)
                end
                local hasKnife = plr.Character:FindFirstChild("Knife") or plr.Backpack:FindFirstChild("Knife")
                hl.FillColor = hasKnife and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)
            end
        end
        task.wait(0.2)
    end
    -- cleanup
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then
            local hl = plr.Character:FindFirstChild("QuantumESP")
            if hl then hl:Destroy() end
        end
    end
end

-- ===== AUTO COLLECT =====
local function autoCollectLoop()
    while getgenv().MM2Config.autoCollect do
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, item in pairs(workspace:GetDescendants()) do
                if item:IsA("Model") and (item.Name:lower():find("coin") or item.Name:lower():find("gift") or item.Name:lower():find("present")) then
                    local part = item:FindFirstChildWhichIsA("BasePart")
                    if part then
                        hrp.CFrame = part.CFrame
                        task.wait(0.1)
                    end
                end
            end
        end
        task.wait(0.2)
    end
end

-- ===== AUTO FARM =====
local function autoFarmLoop()
    local lastAttack = 0
    local cooldown = 0.5
    while getgenv().MM2Config.autoFarm do
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local nearest, nearestDist = nil, math.huge
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= lp and plr.Character then
                    local target = plr.Character:FindFirstChild("HumanoidRootPart")
                    if target then
                        local dist = (target.Position - hrp.Position).Magnitude
                        if dist < nearestDist then
                            nearestDist = dist
                            nearest = target
                        end
                    end
                end
            end
            if nearest then
                hrp.CFrame = nearest.CFrame * CFrame.new(0,0,3)
                if tick() - lastAttack > cooldown and nearestDist < 15 then
                    local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                    if remote then
                        local attackRemote = remote:FindFirstChild("Attack")
                        if attackRemote then
                            attackRemote:FireServer()
                        end
                    end
                    lastAttack = tick()
                end
            end
        end
        task.wait(0.1)
    end
end

-- ===== SPEED HACK =====
RunService.Stepped:Connect(function()
    if getgenv().MM2Config.speedEnabled then
        local hum = getHumanoid()
        if hum then
            hum.WalkSpeed = getgenv().MM2Config.speedValue
        end
    end
end)

-- ===== WINDUI GUI =====
local Window = WindUI:CreateWindow({
    Title = "Quantum X | MM2",
    SubTitle = "by Quantum Team",
    Size = UDim2.new(0, 500, 0, 400),
    Theme = "Amethyst",
})

local MainTab = Window:CreateTab({
    Title = "Main",
    Icon = "rbxassetid://4483362458",
})

MainTab:CreateSection("ESP")
MainTab:CreateToggle({
    Title = "Player ESP",
    Default = false,
    Callback = function(v)
        getgenv().MM2Config.espEnabled = v
        if v then
            task.spawn(setupESP)
        end
    end
})

MainTab:CreateSection("Auto")
MainTab:CreateToggle({
    Title = "Auto Collect (Coins/Gifts)",
    Default = false,
    Callback = function(v)
        getgenv().MM2Config.autoCollect = v
        if v then
            task.spawn(autoCollectLoop)
        end
    end
})

MainTab:CreateToggle({
    Title = "Auto Farm (Attack nearest)",
    Default = false,
    Callback = function(v)
        getgenv().MM2Config.autoFarm = v
        if v then
            task.spawn(autoFarmLoop)
        end
    end
})

MainTab:CreateSection("Movement")
MainTab:CreateToggle({
    Title = "Speed Hack",
    Default = false,
    Callback = function(v)
        getgenv().MM2Config.speedEnabled = v
    end
})
MainTab:CreateSlider({
    Title = "Speed Value",
    Min = 16,
    Max = 250,
    Default = 16,
    Callback = function(v)
        getgenv().MM2Config.speedValue = v
    end
})

-- Additional scripts tab
local ScriptsTab = Window:CreateTab({
    Title = "Scripts",
    Icon = "rbxassetid://4483362458",
})
ScriptsTab:CreateButton({
    Title = "Infinite Yield",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end
})
ScriptsTab:CreateButton({
    Title = "Dex Explorer",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
    end
})
ScriptsTab:CreateButton({
    Title = "SimpleSpy",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpyBeta.lua"))()
    end
})

local CreditsTab = Window:CreateTab({
    Title = "Credits",
    Icon = "rbxassetid://4483362458",
})
CreditsTab:CreateLabel("Quantum X | Murder Mystery 2")
CreditsTab:CreateLabel("UI: WindUI")
CreditsTab:CreateLabel("Developed by Quantum Team")
CreditsTab:CreateLabel("Discord: discord.gg/quantumx")
