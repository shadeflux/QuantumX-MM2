--[[
    ╔══════════════════════════════════════════════╗
    ║         Quantum X  –  Universal Loader       ║
    ║   Obsługuje Speed Hack, Noclip zawsze,       ║
    ║   a MM2-features tylko w MM2 (PlaceId).      ║
    ╚══════════════════════════════════════════════╝

    Użycie (wklej w Executor):
        loadstring(game:HttpGet("https://raw.githubusercontent.com/shadeflux/QuantumX-MM2/main/loader.lua"))()

    mm2.lua pobierany z:
        https://raw.githubusercontent.com/shadeflux/QuantumX-MM2/main/mm2.lua
]]

-- ───────────────────────────────────────────
-- 1. ANTI-DUPLICATE GUARD
-- ───────────────────────────────────────────
if getgenv().QuantumX_Loader_Loaded then
    warn("[QuantumX Loader] Już załadowany – przerywam.")
    return
end
getgenv().QuantumX_Loader_Loaded = true

print("[QuantumX Loader] Uruchamianie…")

-- ───────────────────────────────────────────
-- 2. STAŁE
-- ───────────────────────────────────────────
local MM2_PLACE_ID   = 142823291
local MM2_SCRIPT_URL = "https://raw.githubusercontent.com/shadeflux/QuantumX-MM2/main/mm2.lua"

-- ───────────────────────────────────────────
-- 3. SERVICES
-- ───────────────────────────────────────────
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp         = Players.LocalPlayer

-- ───────────────────────────────────────────
-- 4. GLOBALNA KONFIGURACJA LOADERA
-- ───────────────────────────────────────────
getgenv().QuantumX_Config = {
    speedEnabled = false,
    speedValue   = 16,
    noclipEnabled = false,
}

-- ───────────────────────────────────────────
-- 5. UNIVERSAL HELPERS
-- ───────────────────────────────────────────
local function getChar()
    return lp.Character
end

local function getHumanoid()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- Speed loop (działa zawsze, niezależnie od gry)
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

-- Noclip loop (działa zawsze)
RunService.Stepped:Connect(function()
    if getgenv().QuantumX_Config.noclipEnabled then
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

-- ───────────────────────────────────────────
-- 6. ŁADOWANIE WINDUI
-- ───────────────────────────────────────────
local WindUI
local ok, err = pcall(function()
    WindUI = loadstring(game:HttpGet(
        "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
    ))()
end)

if not ok or not WindUI then
    warn("[QuantumX Loader] ❌ WindUI nie załadowało się: " .. tostring(err))
    -- Próba fallbacku bez GUI (skrypt dalej działa)
    return
end

print("[QuantumX Loader] ✅ WindUI załadowane.")

-- ───────────────────────────────────────────
-- 7. TWORZENIE GŁÓWNEGO OKNA
--    Zapisujemy je do getgenv(), żeby mm2.lua
--    mógł z niego korzystać zamiast tworzyć nowe.
-- ───────────────────────────────────────────
local Window = WindUI:CreateWindow({
    Title    = "Quantum X",
    SubTitle = "Universal Loader",
    Size     = UDim2.new(0, 580, 0, 520),
})

-- Udostępnij okno globalnie
getgenv().QuantumX_Window  = Window
getgenv().QuantumX_WindUI  = WindUI

print("[QuantumX Loader] ✅ Okno GUI utworzone.")

-- ───────────────────────────────────────────
-- 8. ZAKŁADKA "Universal"
-- ───────────────────────────────────────────
local UniversalTab = Window:Tab({
    Title = "Universal",
    Icon  = "rbxassetid://4483362458",
})

-- ── Movement ──
UniversalTab:Section({ Title = "⚡ Movement" })

UniversalTab:Toggle({
    Title    = "Speed Hack",
    Default  = false,
    Callback = function(v)
        getgenv().QuantumX_Config.speedEnabled = v
        print("[QuantumX] Speed Hack:", v)
    end,
})

UniversalTab:Slider({
    Title    = "Speed Value",
    Min      = 16,
    Max      = 350,
    Default  = 16,
    Callback = function(v)
        getgenv().QuantumX_Config.speedValue = v
        -- Synchronizuj z konfiguracją MM2, jeśli ta istnieje
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
        print("[QuantumX] Noclip:", v)
    end,
})

-- ── Misc / Anti-Error ──
UniversalTab:Section({ Title = "🛠 Misc" })

UniversalTab:Button({
    Title    = "No PC Error (Re-attach)",
    Callback = function()
        -- Usuwa typowe błędy "PC Error" przez wyczyszczenie
        -- błędnych EventListenerów i reset CharacterAdded
        pcall(function()
            for _, conn in ipairs(getconnections(lp.CharacterAdded)) do
                conn:Disconnect()
            end
        end)
        print("[QuantumX] No PC Error – połączenia wyczyszczone.")
    end,
})

UniversalTab:Button({
    Title    = "Rejoin Server",
    Callback = function()
        pcall(function()
            local TeleportService = game:GetService("TeleportService")
            TeleportService:Teleport(game.PlaceId, lp)
        end)
    end,
})

-- ── Narzędzia deweloperskie ──
UniversalTab:Section({ Title = "🔧 Dev Tools" })

UniversalTab:Button({
    Title    = "Infinite Yield",
    Callback = function()
        pcall(function()
            loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"
            ))()
        end)
    end,
})

UniversalTab:Button({
    Title    = "Dex Explorer",
    Callback = function()
        pcall(function()
            loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"
            ))()
        end)
    end,
})

UniversalTab:Button({
    Title    = "SimpleSpy",
    Callback = function()
        pcall(function()
            loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpyBeta.lua"
            ))()
        end)
    end,
})

-- ───────────────────────────────────────────
-- 9. ZAKŁADKA "MM2"
--    Pokazuje status oraz pozwala ręcznie/auto
--    załadować mm2.lua.
-- ───────────────────────────────────────────
local MM2Tab = Window:Tab({
    Title = "MM2",
    Icon  = "rbxassetid://4483362458",
})

-- Flaga wykrycia gry
local isInMM2 = (game.PlaceId == MM2_PLACE_ID)

-- Status label
if isInMM2 then
    MM2Tab:AddLabel("✅ Wykryto Murder Mystery 2!")
    MM2Tab:AddLabel("Funkcje MM2 są dostępne poniżej.")
else
    MM2Tab:AddLabel("⚠️ NIE jesteś w Murder Mystery 2.")
    MM2Tab:AddLabel("PlaceId: " .. tostring(game.PlaceId))
    MM2Tab:AddLabel("Oczekiwane PlaceId: " .. tostring(MM2_PLACE_ID))
    MM2Tab:AddLabel("Funkcje MM2 nie są dostępne w tej grze.")
end

MM2Tab:Section({ Title = "🎮 MM2 Script" })

-- Funkcja ładowania mm2.lua
local mm2Loaded = false
local function loadMM2Script()
    if mm2Loaded then
        print("[QuantumX Loader] mm2.lua już załadowany.")
        return
    end
    if not isInMM2 then
        warn("[QuantumX Loader] ⛔ Nie jesteś w MM2 – ładowanie zablokowane.")
        return
    end

    print("[QuantumX Loader] Pobieranie mm2.lua…")
    local success, result = pcall(function()
        local src = game:HttpGet(MM2_SCRIPT_URL)
        loadstring(src)()
    end)

    if success then
        mm2Loaded = true
        print("[QuantumX Loader] ✅ mm2.lua załadowany pomyślnie!")
    else
        warn("[QuantumX Loader] ❌ Błąd ładowania mm2.lua: " .. tostring(result))
        -- Wyświetl informację w GUI
        MM2Tab:AddLabel("❌ Błąd: " .. tostring(result):sub(1, 80))
    end
end

-- Przycisk ręcznego ładowania (zawsze widoczny, ale blokowany gdy nie MM2)
MM2Tab:Button({
    Title    = isInMM2 and "Załaduj MM2 Features" or "⛔ Dostępne tylko w MM2",
    Callback = function()
        loadMM2Script()
    end,
})

-- Auto-ładowanie jeśli w MM2
if isInMM2 then
    MM2Tab:AddLabel("⏳ Auto-ładowanie za 2 sekundy…")
    task.delay(2, function()
        loadMM2Script()
    end)
    print("[QuantumX Loader] Wykryto MM2 – auto-ładowanie mm2.lua za 2s.")
end

-- ───────────────────────────────────────────
-- 10. ZAKŁADKA "Credits"
-- ───────────────────────────────────────────
local CreditsTab = Window:Tab({
    Title = "Credits",
    Icon  = "rbxassetid://4483362458",
})

CreditsTab:AddLabel("Quantum X | Universal Loader + MM2")
CreditsTab:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
CreditsTab:AddLabel("Universal: Speed Hack, Noclip, Dev Tools")
CreditsTab:AddLabel("MM2: ESP, Gun ESP, Auto Farm, Kill All…")
CreditsTab:AddLabel("UI Library: WindUI by Footagesus")
CreditsTab:AddLabel("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
CreditsTab:AddLabel("Developed by Quantum Team")
CreditsTab:AddLabel("Discord: discord.gg/quantumx")
CreditsTab:AddLabel("GitHub: shadeflux/QuantumX-MM2")

print("[QuantumX Loader] ✅ Loader w pełni zainicjowany.")
