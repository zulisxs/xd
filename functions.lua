local Functions = {}
local Players    = game:GetService("Players")
local RepStorage = game:GetService("ReplicatedStorage")
-- Al inicio del archivo
local Omni = require(game:GetService("ReplicatedStorage"):WaitForChild("Omni"))
local PlayerStats = Omni.Utils.PlayerStats
local autoFarmRunning = false

-- ─── Estado actual de mundo/zona ─────────────────────────────────────────────
local currentWorld = nil
local currentZone  = nil

-- ─── Dificultad para prioridad ────────────────────────────────────────────────
local difficultyOrder = {
    ["very easy"] = 1,
    ["easy"]      = 2,
    ["medium"]    = 3,
    ["hard"]      = 4,
    ["insane"]    = 5,
    ["boss"]      = 6,
    ["godlike"]   = 7,
    ["secret"]    = 8,
}

-- ─── Helpers internos ─────────────────────────────────────────────────────────
function Functions:SetFloating(state)
    local hrp = workspace:FindFirstChild(Players.LocalPlayer.Name)
        and workspace[Players.LocalPlayer.Name]:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if state then
        -- Solo crear si no existe ya
        if hrp:FindFirstChild("G4B HUB") then return end
        local bv = Instance.new("BodyVelocity")
        bv.Name = "G4B HUB"
        bv.MaxForce = Vector3.new(100000, 100000, 100000)
        bv.P = 1250
        bv.Velocity = Vector3.zero
        bv.Parent = hrp
    else
        local bv = hrp:FindFirstChild("G4B HUB")
        if bv then bv:Destroy() end
    end
end
-- El enemigo en workspace es un BasePart directo (ej: Guy).
-- El atributo "Died" vive en ese mismo BasePart.
local function isEnemyAlive(enemy)
    if enemy == nil or enemy.Parent == nil then return false end
    if enemy:GetAttribute("Died") then return false end
    local health = enemy:GetAttribute("Health") or 0
    if health <= 0 then return false end
    return true
end

-- La dificultad también es un atributo del BasePart del enemigo.
local function getEnemyDifficulty(enemy)
    local diff = enemy:GetAttribute("Difficulty") or "Very Easy"
    return difficultyOrder[diff:lower()] or 0
end

-- Teleport usando el CFrame del BasePart directamente.
local function teleportTo(enemyCFrame)
    local hrp = workspace:FindFirstChild(Players.LocalPlayer.Name)
        and workspace[Players.LocalPlayer.Name]:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = enemyCFrame + Vector3.new(0, 10, 0)
    end
end

-- Obtiene la carpeta del workspace según mundo y zona actuales.
-- Ruta: workspace.Server.Enemies.World[currentWorld][currentZone]
local function getEnemyFolder()
    if not currentWorld or not currentZone then return nil end
    local s = workspace:FindFirstChild("Server")         if not s then return nil end
    local e = s:FindFirstChild("Enemies")                if not e then return nil end
    local w = e:FindFirstChild("World")                  if not w then return nil end
    local m = w:FindFirstChild(currentWorld)             if not m then return nil end
    return m:FindFirstChild(currentZone)
end

-- Construye lista ordenada de todos los enemigos vivos que coinciden con la selección.
local function buildEnemyList(selectedEnemies, priority)
    local folder = getEnemyFolder()
    if not folder then return {} end

    local enemyList = {}

    for _, enemy in ipairs(folder:GetChildren()) do
        if enemy:IsA("BasePart") then
            for _, selectedName in ipairs(selectedEnemies) do
                if enemy.Name == selectedName and isEnemyAlive(enemy) then
                    table.insert(enemyList, {
                        instance   = enemy,
                        difficulty = getEnemyDifficulty(enemy),
                    })
                    break
                end
            end
        end
    end

    table.sort(enemyList, function(a, b)
        if priority == "Strongest" then
            return a.difficulty > b.difficulty
        else
            return a.difficulty < b.difficulty
        end
    end)

    return enemyList
end

-- Loop principal del autofarm (secuencial con timer paralelo)
local function killLoop(selectedEnemies, priority, isRunningFn)
    while isRunningFn() do
        if not selectedEnemies or #selectedEnemies == 0 then
            task.wait(1)
            continue
        end

        local enemyList = buildEnemyList(selectedEnemies, priority)
        if #enemyList == 0 then
            task.wait(0.5)
            continue
        end

        local firstEnemy = enemyList[1].instance
        local firstEnemyRespawnTime = nil

        -- Watcher paralelo: detecta cuando enemy 1 respawnea (mismo BasePart siempre)
        local watcher = task.spawn(function()
            -- Esperar a que muera (Died=true O Health<=0)
            while firstEnemy and firstEnemy.Parent do
                local died = firstEnemy:GetAttribute("Died")
                local hp = firstEnemy:GetAttribute("Health") or 0
                if died or hp <= 0 then break end
                task.wait(0.05)
            end
            -- Esperar a que respawnee (Died=false Y Health>0)
            while firstEnemy and firstEnemy.Parent do
                local died = firstEnemy:GetAttribute("Died")
                local hp = firstEnemy:GetAttribute("Health") or 0
                if not died and hp > 0 then
                    firstEnemyRespawnTime = tick()
                    return
                end
                task.wait(0.05)
            end
        end)

        -- Recorrer la lista en orden
        for i, entry in ipairs(enemyList) do
            if not isRunningFn() then break end
            local enemy = entry.instance
            if not isEnemyAlive(enemy) then continue end

            teleportTo(enemy.CFrame)

            local _, finalDamage = PlayerStats.Damage(Omni.Data, Omni.Instance)
            local enemyHealth = enemy:GetAttribute("Health") or 0

            if finalDamage >= enemyHealth then
                task.wait(0.3)
            else
                -- Esperar a que muera (sin timeout, auto-attack lo matará)
                while isRunningFn() and isEnemyAlive(enemy) do
                    task.wait(0.1)
                end
                task.wait(0.3)
            end

            -- Después de cada kill (excepto enemy 1), verificar si enemy 1 ya está listo
            if i > 1 and firstEnemyRespawnTime and (tick() - firstEnemyRespawnTime >= 1.5) then
                break -- Volver a enemy 1
            end
        end

        -- Si la lista terminó pero enemy 1 aún no está listo, esperar
        if isRunningFn() then
            if not firstEnemyRespawnTime then
                -- Aún no respawneó, esperar con timeout de 15s
                local waitStart = tick()
                while isRunningFn() and not firstEnemyRespawnTime do
                    task.wait(0.1)
                    if tick() - waitStart > 0.1 then
                       -- print("[FARM-DBG] Timeout 15s esperando respawn de enemy 1, reiniciando ciclo")
                        break
                    end
                end
            end
            -- Esperar cooldown restante
            if firstEnemyRespawnTime then
                local remaining = 1.5 - (tick() - firstEnemyRespawnTime)
                if remaining > 0 then
                    task.wait(remaining)
                end
            end
        end

        task.cancel(watcher)
    end
end
-- ─── API pública ──────────────────────────────────────────────────────────────
function Functions:IsAutoFarmRunning()
    return autoFarmRunning
end
-- Devuelve los mundos disponibles (hijos de Shared.Enemies)
function Functions:GetWorlds()
    local worlds = {}
    local base = RepStorage:FindFirstChild("Omni")
    if not base then return worlds end
    base = base:FindFirstChild("Shared")
    if not base then return worlds end
    base = base:FindFirstChild("Enemies")
    if not base then return worlds end

    for _, child in ipairs(base:GetChildren()) do
        if child:IsA("ModuleScript") or child:IsA("Folder") then
            table.insert(worlds, child.Name)
        end
    end
    return worlds
end

-- Devuelve las zonas de un mundo
function Functions:GetZones(worldName)
    local zones = {}
    local base = RepStorage:FindFirstChild("Omni")
    if not base then return zones end
    base = base:FindFirstChild("Shared")
    if not base then return zones end
    base = base:FindFirstChild("Enemies")
    if not base then return zones end

    local worldNode = base:FindFirstChild(worldName)
    if not worldNode then return zones end

    for _, child in ipairs(worldNode:GetChildren()) do
        if child:IsA("ModuleScript") or child:IsA("Folder") then
            table.insert(zones, child.Name)
        end
    end
    return zones
end

-- Carga los nombres de enemigos desde el ModuleScript de la zona
function Functions:GetEnemiesFromZone(worldName, zoneName)
    local names = {}
    local base = RepStorage:FindFirstChild("Omni")
    if not base then return names end
    base = base:FindFirstChild("Shared")
    if not base then return names end
    base = base:FindFirstChild("Enemies")
    if not base then return names end

    local worldNode = base:FindFirstChild(worldName)
    if not worldNode then return names end

    local zoneNode = worldNode:FindFirstChild(zoneName)
    if not zoneNode or not zoneNode:IsA("ModuleScript") then return names end

    local ok, data = pcall(require, zoneNode)
    if not ok or type(data) ~= "table" then return names end

    for enemyName in pairs(data) do
        table.insert(names, enemyName)
    end

    table.sort(names)
    return names
end

-- Guarda el mundo y zona actuales (llamado desde la UI al cambiar dropdown)
function Functions:SetZone(worldName, zoneName)
    currentWorld = worldName
    currentZone  = zoneName
end

-- Inicia o detiene el autofarm
function Functions:SetAutoFarm(state, selectedEnemies, priority)
    autoFarmRunning = state

    if state then
        task.spawn(function()
            Functions:SetFloating(true)
            killLoop(selectedEnemies, priority, function()
                return autoFarmRunning
            end)
        end)
    else
        Functions:SetFloating(false)  -- ← aquí
    end
end
return Functions
