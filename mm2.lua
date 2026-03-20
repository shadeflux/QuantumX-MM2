--[[
    Quantum X | Murder Mystery 2
    ESP + Basic Movement
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
local lp = Players.LocalPlayer

-- ===== CONFIG =====
getgenv().MM2Config = {
    espEnabled = false,
    speedEnabled = false,
    speedValue = 16,
    noclipEnabled = false,
    noPcError = false,
}

-- ===== UTILITIES =====
local function getChar()
    return lp.Character
end

local function getHumanoid()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ===== DETECT ROLE =====
local function getRoleColor(plr)
    local char = plr.Character
    if not char then return Color3.fromRGB(255,255,255) end

    if char:FindFirstChild("Knife") or (plr.Backpack and plr.Backpack:FindFirstChild("Knife")) then
        return Color3.fromRGB(255,0,0) -- red (murderer)
    end
    if char:FindFirstChild("Gun") or (plr.Backpack and plr.Backpack:FindFirstChild("Gun")) then
        return Color3.fromRGB(0,100,255) -- blue (sheriff)
    end
    return Color3.fromRGB(0,255,0) -- green (innocent)
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
                highlight.FillColor = getRoleColor(plr)
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

-- ===== WINDUI GUI (poprawna składnia) =====
local Window = WindUI:CreateWindow({
    Title = "Quantum X | MM2",
    SubTitle = "by Quantum Team",
    Size = UDim2.new(0, 450, 0, 350),
})

-- Main Tab
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "rbxassetid://4483362458",
})

MainTab:Section({
    Title = "Visuals",
})
MainTab:Toggle({
    Title = "Player ESP",
    Default = false,
    Callback = function(v)
        getgenv().MM2Config.espEnabled = v
        if v then
            task.spawn(espLoop)
        end
    end
})

MainTab:Section({
    Title = "Movement",
})
MainTab:Toggle({
    Title = "Speed Hack",
    Default = false,
    Callback = function(v)
        getgenv().MM2Config.speedEnabled = v
    end
})
MainTab:Slider({
    Title = "Speed Value",
    Min = 16,
    Max = 250,
    Default = 16,
    Callback = function(v)
        getgenv().MM2Config.speedValue = v
    end
})
MainTab:Toggle({
    Title = "Noclip",
    Default = false,
    Callback = function(v)
        getgenv().MM2Config.noclipEnabled = v
    end
})

-- Scripts Tab
local ScriptsTab = Window:Tab({
    Title = "Scripts",
    Icon = "rbxassetid://4483362458",
})
ScriptsTab:Button({
    Title = "Infinite Yield",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end
})
ScriptsTab:Button({
    Title = "Dex Explorer",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
    end
})
ScriptsTab:Button({
    Title = "SimpleSpy",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpyBeta.lua"))()
    end
})

-- Credits Tab
local CreditsTab = Window:Tab({
    Title = "Credits",
    Icon = "rbxassetid://4483362458",
})
CreditsTab:Label("Quantum X | Murder Mystery 2")
CreditsTab:Label("ESP: murderer (red), sheriff (blue), innocent (green)")
CreditsTab:Label("UI: WindUI (Footagesus)")
CreditsTab:Label("Developed by Quantum Team")
CreditsTab:Label("Discord: discord.gg/quantumx")
