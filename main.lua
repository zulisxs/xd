-- ─── Anti AFK ─────────────────────────────────────────────────────────────────
local VirtualUser = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

local function safeLoad(url, name)
    local ok, content = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok then
        warn("❌ " .. name .. " falló al descargar")
        return nil
    end
    local fn, err = loadstring(content)
    if not fn then
        warn("❌ " .. name .. " falló al compilar: " .. tostring(err))
        return nil
    end
    local ok2, result = pcall(fn)
    if not ok2 then
        warn("❌ " .. name .. " falló al ejecutar: " .. tostring(result))
        return nil
    end
    print("✅ " .. name .. " cargó")
    return result
end

local WindUI    = safeLoad("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua", "WindUI")
local Functions = safeLoad("https://raw.githubusercontent.com/zulisxs/xd/refs/heads/main/functions.lua", "Functions")
local GameMode  = safeLoad("https://raw.githubusercontent.com/zulisxs/xd/refs/heads/main/GameMode.lua", "GameMode")
local UI        = safeLoad("https://raw.githubusercontent.com/zulisxs/xd/refs/heads/main/ui.lua", "UI")

if not WindUI    then warn("⛔ WindUI no cargó")    return end
if not Functions then warn("⛔ Functions no cargó") return end
if not GameMode  then warn("⛔ GameMode no cargó")  return end
if not UI        then warn("⛔ UI no cargó")        return end


UI:Init(WindUI, Functions, GameMode)
