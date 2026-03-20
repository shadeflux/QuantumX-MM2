-- Loader dla Quantum X MM2
local url = "https://raw.githubusercontent.com/shadeflux/QuantumX-MM2/main/mm2.lua"
local success, result = pcall(function()
    return game:HttpGet(url)
end)
if success and result then
    loadstring(result)()
else
    warn("Nie udało się pobrać skryptu. Sprawdź URL.")
end
