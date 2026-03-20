-- Loader dla Quantum X MM2
local url = "https://raw.githubusercontent.com/shadeflux/QuantumX-MM2/refs/heads/main/mm2.lua?token=GHSAT0AAAAAADXFWBNSHHLXROEXOK742ICW2N5STXQ"
local success, result = pcall(function()
    return game:HttpGet(url)
end)
if success and result then
    loadstring(result)()
else
    warn("Nie udało się pobrać skryptu. Sprawdź URL.")
end
