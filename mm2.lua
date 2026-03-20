--[[
    Quantum X | Murder Mystery 2
    ESP + Basic Movement
]]

if getgenv().QuantumX_MM2_Loaded then return end
getgenv().QuantumX_MM2_Loaded = true

-- ===== LOAD WINDUI =====
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

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
-- In Murder Mystery 2:
--   murderer: has "Knife" in Character or Backpack
--   sheriff: has "Gun" in Character or Backpack
--   innocent: none of the above
local function getRoleColor(plr)
    local char = plr.Character
    if not char then return Color3.fromRGB(255,255,255) end -- white if no character

    -- Check for knife (murderer)
    if char:FindFirstChild("Knife") or (plr.Backpack and plr.Backpack:FindFirstChild("Knife")) then
        return Color3.fromRGB(255,0,0) -- red
    end
    -- Check for gun (sheriff)
    if char:FindFirstChild("Gun") or (plr.Backpack and plr.Backpack:FindFirstChild("Gun")) then
        return Color3.fromRGB(0,100,255) -- blue
    end
    -- Innocent
    return Color3.fromRGB(0,255,0) -- green
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
    -- Cleanup when disabled
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

-- ===== NO PC ERROR =====
task.spawn(function()
    while task.wait(0.1) do
        if getgenv().MM2Config.noPcError then
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton1(Vector2.new())
            end)
        end
    end
end)

-- ===== CREATE WINDOW (default theme) =====
local Window = WindUI:CreateWindow({
    Title = "Quantum X | MM2",
    SubTitle = "by Quantum Team",
    Size = UDim2.new(0, 450, 0, 350),
    -- no Theme specified → uses default
})

-- ===== TAB: MAIN =====
local MainTab = Window:CreateTab({
    Title = "Main",
    Icon = "rbxassetid://4483362458",
})

MainTab:CreateSection("Visuals")
MainTab:CreateToggle({
    Title = "Player ESP",
    Default = false,
    Callback = function(v)
        getgenv().MM2Config.espEnabled = v
        if v then
            task.spawn(espLoop)
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
MainTab:CreateToggle({
    Title = "Noclip",
    Default = false,
    Callback = function(v)
        getgenv().MM2Config.noclipEnabled = v
    end
})

MainTab:CreateSection("Misc")
MainTab:CreateToggle({
    Title = "No PC Error",
    Default = false,
    Callback = function(v)
        getgenv().MM2Config.noPcError = v
    end
})

-- ===== TAB: SCRIPTS =====
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

-- ===== TAB: CREDITS =====
local CreditsTab = Window:CreateTab({
    Title = "Credits",
    Icon = "rbxassetid://4483362458",
})
CreditsTab:CreateLabel("Quantum X | Murder Mystery 2")
CreditsTab:CreateLabel("ESP: murderer (red), sheriff (blue), innocent (green)")
CreditsTab:CreateLabel("UI: WindUI (Footagesus)")
CreditsTab:CreateLabel("Developed by Quantum Team")
CreditsTab:CreateLabel("Discord: discord.gg/quantumx")
