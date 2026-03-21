--[[
    ╔══════════════════════════════════════════════════╗
    ║           Quantum X  –  loader.lua               ║
    ║  Uruchom ten plik jako jedyny punkt wejścia.     ║
    ║  Automatycznie ładuje mm2.lua gdy jesteś w MM2.  ║
    ╚══════════════════════════════════════════════════╝

    Użycie w executorze:
        loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/shadeflux/QuantumX-MM2/main/loader.lua"
        ))()
]]

-- ─────────────────────────────────────────────────────────
-- SEKCJA 1: ANTI-DUPLICATE GUARD
-- ─────────────────────────────────────────────────────────
if getgenv().QuantumX_Loader_Loaded then
    warn("[QuantumX] Loader już działa – przerywam duplikat.")
    return
end
getgenv().QuantumX_Loader_Loaded = true

-- ─────────────────────────────────────────────────────────
-- SEKCJA 2: STAŁE KONFIGURACYJNE
-- ─────────────────────────────────────────────────────────
local LOADER_VERSION  = "2.1"
local MM2_PLACE_ID    = 142823291
local MM2_SCRIPT_URL  = "https://raw.githubusercontent.com/shadeflux/QuantumX-MM2/main/mm2.lua"

-- Kolejność URL do WindUI – próbujemy po kolei aż jeden zadziała
local WINDUI_URLS = {
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/source.lua",
}

-- ─────────────────────────────────────────────────────────
-- SEKCJA 3: SERVICES & LOCAL PLAYER
-- ─────────────────────────────────────────────────────────
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

-- ─────────────────────────────────────────────────────────
-- SEKCJA 4: GLOBALNA KONFIGURACJA (dostępna dla mm2.lua)
-- ─────────────────────────────────────────────────────────
getgenv().QuantumX_Config = {
    speedEnabled  = false,
    speedValue    = 16,
    noclipEnabled = false,
}

-- ─────────────────────────────────────────────────────────
-- SEKCJA 5: UTILITY FUNCTIONS
-- ─────────────────────────────────────────────────────────
local function getChar()
    return lp.Character
end

local function getHumanoid()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- Bezpieczny HttpGet z pcall – zwraca (ok, wynik/błąd)
local function safeHttpGet(url)
    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)
    return ok, result
end

-- Bezpieczny loadstring + wykonanie z pcall
local function safeLoadstring(src)
    local ok, fn = pcall(loadstring, src)
    if not ok or type(fn) ~= "function" then
        return false, tostring(fn)
    end
    local ok2, err2 = pcall(fn)
    if not ok2 then
        return false, tostring(err2)
    end
    return true, nil
end

-- ─────────────────────────────────────────────────────────
-- SEKCJA 6: PĘTLE UNIVERSAL (Speed / Noclip)
--   Działają zawsze, niezależnie od gry.
-- ─────────────────────────────────────────────────────────
task.spawn(function()
    while true do
        if getgenv().QuantumX_Config.speedEnabled then
            local hum = getHumanoid()
            if hum then
                hum.WalkSpeed = getgenv().QuantumX_Config.speedValue
            end
        end
        task.wait()
    end
end)

RunService.Stepped:Connect(function()
    if getgenv().QuantumX_Config.noclipEnabled then
        local char = getChar()
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = false
                end
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────────
-- SEKCJA 7: ŁADOWANIE WINDUI
--   Próbujemy każdego URL po kolei – pcall na każdym kroku.
-- ─────────────────────────────────────────────────────────
local WindUI = nil

for i, url in ipairs(WINDUI_URLS) do
    print(string.format("[QuantumX] WindUI próba %d/%d …", i, #WINDUI_URLS))

    local okHttp, src = safeHttpGet(url)
    if not okHttp or type(src) ~= "string" or #src < 100 then
        warn("[QuantumX] HTTP fail #" .. i .. ": " .. tostring(src))
        continue
    end

    -- Krok 1: skompiluj
    local okCompile, fn = pcall(loadstring, src)
    if not okCompile or type(fn) ~= "function" then
        warn("[QuantumX] Compile fail #" .. i .. ": " .. tostring(fn))
        continue
    end

    -- Krok 2: wykonaj i odbierz zwracaną wartość
    local okExec, lib = pcall(fn)
    if not okExec then
        warn("[QuantumX] Exec fail #" .. i .. ": " .. tostring(lib))
        continue
    end
    if lib == nil then
        warn("[QuantumX] WindUI URL #" .. i .. " zwróciło nil – pomijam.")
        continue
    end

    WindUI = lib
    print("[QuantumX] ✅ WindUI załadowane (URL #" .. i .. ").")
    break
end

if not WindUI then
    warn("[QuantumX] ❌ WindUI niedostępne. Speed/Noclip działają, ale brak GUI.")
    return
end

getgenv().QuantumX_WindUI = WindUI

-- ─────────────────────────────────────────────────────────
-- SEKCJA 8: TWORZENIE GŁÓWNEGO OKNA
-- ─────────────────────────────────────────────────────────
local Window
do
    local ok, result = pcall(function()
        return WindUI:CreateWindow({
            Title    = "Quantum X  v" .. LOADER_VERSION,
            SubTitle = "Universal Loader",
            Size     = UDim2.new(0, 580, 0, 540),
        })
    end)
    if not ok or result == nil then
        warn("[QuantumX] ❌ Błąd tworzenia okna: " .. tostring(result))
        return
    end
    Window = result
    getgenv().QuantumX_Window = Window
    print("[QuantumX] ✅ Okno GUI gotowe.")
end

-- ─────────────────────────────────────────────────────────
-- SEKCJA 9: ZAKŁADKA „Universal"
-- ─────────────────────────────────────────────────────────
local UniversalTab = Window:Tab({
    Title = "Universal",
    Icon  = "rbxassetid://4483362458",
})

UniversalTab:Section({ Title = "⚡ Ruch" })

UniversalTab:Toggle({
    Title    = "Speed Hack",
    Default  = false,
    Callback = function(v)
        getgenv().QuantumX_Config.speedEnabled = v
        if getgenv().MM2Config then
            getgenv().MM2Config.speedEnabled = v
        end
    end,
})

UniversalTab:Slider({
    Title    = "Prędkość (WalkSpeed)",
    Min      = 16,
    Max      = 350,
    Default  = 16,
    Callback = function(v)
        getgenv().QuantumX_Config.speedValue = v
        if getgenv().MM2Config then
            getgenv().MM2Config.speedValue = v
        end
    end,
})

UniversalTab:Toggle({
    Title    = "Noclip",
    Default  = false,
    Callback = function(v)
        getgenv().QuantumX_Config.noclipEnabled = v
        if getgenv().MM2Config then
            getgenv().MM2Config.noclipEnabled = v
        end
    end,
})

UniversalTab:Section({ Title = "🛠 Misc" })

UniversalTab:Button({
    Title    = "Rejoin Server",
    Callback = function()
        pcall(function()
            game:GetService("TeleportService"):Teleport(game.PlaceId, lp)
        end)
    end,
})

UniversalTab:Section({ Title = "🔧 Dev Tools" })

UniversalTab:Button({
    Title    = "Infinite Yield",
    Callback = function()
        local ok, src = safeHttpGet(
            "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"
        )
        if ok then safeLoadstring(src) end
    end,
})

UniversalTab:Button({
    Title    = "Dex Explorer",
    Callback = function()
        local ok, src = safeHttpGet(
            "https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"
        )
        if ok then safeLoadstring(src) end
    end,
})

UniversalTab:Button({
    Title    = "SimpleSpy",
    Callback = function()
        local ok, src = safeHttpGet(
            "https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpyBeta.lua"
        )
        if ok then safeLoadstring(src) end
    end,
})

-- ─────────────────────────────────────────────────────────
-- SEKCJA 10: ZAKŁADKA „MM2"
-- ─────────────────────────────────────────────────────────
local MM2Tab = Window:Tab({
    Title = "MM2",
    Icon  = "rbxassetid://4483362458",
})

local isInMM2 = (game.PlaceId == MM2_PLACE_ID)

if isInMM2 then
    MM2Tab:AddLabel("✅ Wykryto Murder Mystery 2!")
    MM2Tab:AddLabel("Auto-ładowanie mm2.lua za 3 sekundy…")
else
    MM2Tab:AddLabel("⚠️ Nie jesteś w Murder Mystery 2.")
    MM2Tab:AddLabel("Twoje PlaceId: " .. tostring(game.PlaceId))
    MM2Tab:AddLabel("Wymagane PlaceId: " .. tostring(MM2_PLACE_ID))
    MM2Tab:AddLabel("Wejdź do MM2, aby odblokować funkcje.")
end

MM2Tab:Section({ Title = "🎮 MM2 Script" })

local mm2LoadAttempted = false

local function loadMM2()
    if mm2LoadAttempted then
        warn("[QuantumX] mm2.lua już był ładowany w tej sesji.")
        return
    end
    if not isInMM2 then
        warn("[QuantumX] ⛔ Ładowanie MM2 zablokowane – zła gra.")
        return
    end

    mm2LoadAttempted = true
    print("[QuantumX] Pobieranie mm2.lua…")

    local okHttp, src = safeHttpGet(MM2_SCRIPT_URL)
    if not okHttp then
        warn("[QuantumX] ❌ Błąd HTTP mm2.lua: " .. tostring(src))
        MM2Tab:AddLabel("❌ Błąd pobierania mm2.lua!")
        mm2LoadAttempted = false
        return
    end

    local okLoad, err = safeLoadstring(src)
    if okLoad then
        print("[QuantumX] ✅ mm2.lua wykonany pomyślnie!")
        MM2Tab:AddLabel("✅ mm2.lua załadowany!")
    else
        warn("[QuantumX] ❌ Błąd wykonania mm2.lua: " .. tostring(err))
        MM2Tab:AddLabel("❌ Błąd: " .. tostring(err):sub(1, 70))
        mm2LoadAttempted = false
    end
end

MM2Tab:Button({
    Title    = isInMM2 and "▶ Załaduj MM2 Features" or "⛔ Tylko w Murder Mystery 2",
    Callback = loadMM2,
})

if isInMM2 then
    task.delay(3, function()
        if not getgenv().QuantumX_MM2_Loaded then
            loadMM2()
        end
    end)
end

-- ─────────────────────────────────────────────────────────
-- SEKCJA 11: ZAKŁADKA „Credits"
-- ─────────────────────────────────────────────────────────
local CreditsTab = Window:Tab({
    Title = "Credits",
    Icon  = "rbxassetid://4483362458",
})

CreditsTab:AddLabel("Quantum X  v" .. LOADER_VERSION)
CreditsTab:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
CreditsTab:AddLabel("Universal: Speed, Noclip, Dev Tools")
CreditsTab:AddLabel("MM2: ESP, Farm, Kill, Fling, CoinBag")
CreditsTab:AddLabel("UI: WindUI by Footagesus")
CreditsTab:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
CreditsTab:AddLabel("Developed by Quantum Team")
CreditsTab:AddLabel("Discord: discord.gg/quantumx")
CreditsTab:AddLabel("GitHub: shadeflux/QuantumX-MM2")

print("[QuantumX] ✅ Loader v" .. LOADER_VERSION .. " w pełni gotowy.")
