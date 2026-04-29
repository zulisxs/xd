local GameMode = {}

local Players    = game:GetService("Players")
local RepStorage = game:GetService("ReplicatedStorage")
local Omni       = require(RepStorage:WaitForChild("Omni"))
local PlayerStats = Omni.Utils.PlayerStats

local BRIDGE_NET   = RepStorage:WaitForChild("BridgeNet"):WaitForChild("dataRemoteEvent")
local RETRY_DELAY  = 1
local CONFIRM_WAIT = 4

-- ─── Estado central ──────────────────────────────────────────────────────────

local functionsRef    = nil
local savedEnemies    = nil
local savedPriority   = nil
local savedPositionRef = nil

-- Toggle states (cada toggle es independiente)
local trialEnabled   = false
local tempestEnabled = false
local dragonEnabled  = false

-- Parámetros por gamemode
local selectedTrialsRef = {}
local trialWaveTargets  = {}
local tempestWaveTarget = 25
local dragonWaveTarget  = 25

-- Scheduler
local schedulerRunning = false
local currentGamemode  = nil
local reentryTimers    = {}

-- AutoFarm
local autoFarmPaused = false

-- Tempest v2 (posición fija en el centro del mapa)
local tempestV2 = false
local TEMPEST_FIXED_CFRAME = CFrame.new(-2851.12109, 203.811783, -1679.35889, 0.999148726, -0, -0.0412531383, 0, 1, -0, 0.0412531383, 0, 0.999148726)

-- ─── BridgeNet ────────────────────────────────────────────────────────────────

local function fireJoin(gamemodeName)
    BRIDGE_NET:FireServer({
        {
            "General",
            "Gamemodes",
            "Join",
            gamemodeName,
            n = 4,
        },
        "\002",
    })
end

local function fireTeleport(worldName, zoneName)
    BRIDGE_NET:FireServer({
        {
            "Player",
            "Teleport",
            "Teleport",
            worldName,
            zoneName,
            n = 5,
        },
        "\002",
    })
end

-- ─── HUD ──────────────────────────────────────────────────────────────────────

local function getGamemodeFrame(gamemodeName)
    local ok, frame = pcall(function()
        return Players.LocalPlayer
            :WaitForChild("PlayerGui")
            :WaitForChild("UI")
            :WaitForChild("HUD")
            :WaitForChild("Gamemodes")
            :WaitForChild(gamemodeName)
    end)
    return ok and frame or nil
end

local function getWaveFromHUD(gamemodeName)
    local ok, wave, maxW = pcall(function()
        local frame = getGamemodeFrame(gamemodeName)
        local text = frame:WaitForChild("Main"):WaitForChild("Wave").Value.Text
        local w, m = text:match("(%d+)%s*/%s*(%d+)")
        return tonumber(w) or 0, tonumber(m) or 0
    end)
    if ok then
        return wave, maxW
    end
    return 0, 0
end

local function waitForEntry(gamemodeName)
    local deadline = tick() + CONFIRM_WAIT
    while tick() < deadline do
        local frame = getGamemodeFrame(gamemodeName)
        if frame and frame.Visible then
            return true
        end
        task.wait(0.5)
    end
    return false
end

-- ─── Gamemode info ────────────────────────────────────────────────────────────

local function getGamemodeData(gamemodeName)
    local ok, mod = pcall(function()
        return require(
            RepStorage:WaitForChild("Omni")
                :WaitForChild("Shared")
                :WaitForChild("Gamemodes")
                :WaitForChild(gamemodeName)
        )
    end)
    if ok and mod then return mod end
    return {}
end

local function getMaxWave(gamemodeName)
    return getGamemodeData(gamemodeName).MaxWave or math.huge
end

local function getEnterTime(gamemodeName)
    return getGamemodeData(gamemodeName).EnterTime or 30
end

local function getTrialOpenTimes(trialName)
    return getGamemodeData(trialName).OpenTimes or {}
end

local function getServerMinute()
    return math.floor(workspace:GetServerTimeNow() / 60) % 60
end

local function isTrialOpen(trialName)
    local m = getServerMinute()
    for _, t in ipairs(getTrialOpenTimes(trialName)) do
        if m == t then return true end
    end
    return false
end

local function getOpenTrial()
    for _, trialName in ipairs(selectedTrialsRef) do
        if isTrialOpen(trialName) then
            return trialName
        end
    end
    return nil
end

-- ─── Auto Farm (simplificado) ─────────────────────────────────────────────────

local function pauseAutoFarm()
    if functionsRef and not autoFarmPaused then
        if functionsRef:IsAutoFarmRunning() then
            autoFarmPaused = true
            functionsRef:SetAutoFarm(false, savedEnemies, savedPriority)
            print("[PAUSE] AutoFarm paused")
        end
    end
end

local function resumeAutoFarm()
    if functionsRef and autoFarmPaused then
        autoFarmPaused = false
        functionsRef:SetAutoFarm(true, savedEnemies, savedPriority)
        print("[RESUME] AutoFarm resumed")
    end
end

-- ─── Enemy helpers ────────────────────────────────────────────────────────────

local function isEnemyAlive(enemy)
    if enemy == nil or enemy.Parent == nil then return false end
    if enemy:GetAttribute("Died") then return false end
    local health = enemy:GetAttribute("Health") or 0
    if health <= 0 then return false end
    return true
end

local function teleportTo(cf)
    local hrp = workspace:FindFirstChild(Players.LocalPlayer.Name)
        and workspace[Players.LocalPlayer.Name]:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = cf + Vector3.new(0, 10, 0)
    end
end

local function getGamemodeEnemyFolder(gamemodeName)
    local s = workspace:FindFirstChild("Server")  if not s then return nil end
    local e = s:FindFirstChild("Enemies")         if not e then return nil end
    local g = e:FindFirstChild("Gamemodes")       if not g then return nil end
    return g:FindFirstChild(gamemodeName)
end

local function farmEnemiesInGamemode(gamemodeName, isRunningFn)
    if functionsRef then functionsRef:SetFloating(true) end
    while isRunningFn() do
        local folder = getGamemodeEnemyFolder(gamemodeName)
        if folder then
            local enemy = nil
            for _, e in ipairs(folder:GetChildren()) do
                if e:IsA("BasePart") and isEnemyAlive(e) then
                    enemy = e
                    break
                end
            end
            if enemy then
                teleportTo(enemy.CFrame)
                local _, finalDamage = PlayerStats.Damage(Omni.Data, Omni.Instance)
                local enemyHealth = enemy:GetAttribute("Health") or 0
                if finalDamage < enemyHealth then
                    local died = false
                    local conn1 = enemy:GetAttributeChangedSignal("Died"):Connect(function()
                        died = true
                    end)
                    local conn2 = enemy:GetAttributeChangedSignal("Health"):Connect(function()
                        if (enemy:GetAttribute("Health") or 0) <= 0 then
                            died = true
                        end
                    end)
                    while isRunningFn() and not died and isEnemyAlive(enemy) do
                        task.wait(0.05)
                    end
                    conn1:Disconnect()
                    conn2:Disconnect()
                end
                task.wait(0.05)
            else
                task.wait(0.1)
            end
        else
            task.wait(0.1)
        end
    end
end

local function holdFixedPosition(fixedCFrame, isRunningFn)
    if functionsRef then functionsRef:SetFloating(true) end
    -- Teleport inicial al CFrame fijo
    local hrp = workspace:FindFirstChild(Players.LocalPlayer.Name)
        and workspace[Players.LocalPlayer.Name]:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = fixedCFrame
    end
    -- Mantener posición re-teleportando periódicamente
    while isRunningFn() do
        hrp = workspace:FindFirstChild(Players.LocalPlayer.Name)
            and workspace[Players.LocalPlayer.Name]:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = fixedCFrame
        end
        task.wait(1)
    end
end

-- ─── Exit ─────────────────────────────────────────────────────────────────────

local function exitGamemode(savedMap, savedZone, savedPosition)
    if functionsRef then functionsRef:SetFloating(false) end
    print("[EXIT] Teleport to Map: " .. tostring(savedMap) .. " | Zone: " .. tostring(savedZone))
    fireTeleport(savedMap, savedZone)
    task.wait(3)
    if savedPosition and savedPosition.cframe then
        local char = Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = savedPosition.cframe
            print("[EXIT] CFrame completed")
        end
    end
    task.wait(2)
end

-- ─── Scheduler helpers ────────────────────────────────────────────────────────

local function hasHigherPriorityTrial()
    return trialEnabled and getOpenTrial() ~= nil
end

local function getHighestPriorityActivity()
    local now = workspace:GetServerTimeNow()

    -- Prioridad 1: Trials
    if trialEnabled then
        local openTrial = getOpenTrial()
        if openTrial and now >= (reentryTimers[openTrial] or 0) then
            return openTrial
        end
    end

    -- Prioridad 2: Tempest (bloquea Dragon si está activo)
    if tempestEnabled then
        if now >= (reentryTimers["Tempest Invasion"] or 0) then
            return "Tempest Invasion"
        end
    end

    -- Prioridad 3: Dragon (solo si Tempest NO está activo)
    if dragonEnabled and not tempestEnabled then
        if now >= (reentryTimers["Dragon Defense"] or 0) then
            return "Dragon Defense"
        end
    end

    return nil
end

local function getWaveTargetFor(activity)
    if activity == "Tempest Invasion" then
        return tempestWaveTarget
    elseif activity == "Dragon Defense" then
        return dragonWaveTarget
    else
        return trialWaveTargets[activity] or 25
    end
end

local function isToggleOnFor(activity)
    if activity == "Tempest Invasion" then
        return tempestEnabled
    elseif activity == "Dragon Defense" then
        return dragonEnabled
    else
        return trialEnabled
    end
end

local function shouldInterruptFor(activity)
    if activity:find("Trial") then
        return false -- Trials nunca se interrumpen
    elseif activity == "Tempest Invasion" then
        return hasHigherPriorityTrial()
    elseif activity == "Dragon Defense" then
        return tempestEnabled or hasHigherPriorityTrial()
    end
    return false
end

-- ─── Run gamemode ─────────────────────────────────────────────────────────────

local function runGamemode(gamemodeName, waveTarget, savedPosition)
    local savedMap  = (savedPosition and savedPosition.map) or Omni.Data.Map
    local savedZone = (savedPosition and savedPosition.zone) or Omni.Data.Zone
    local entryTime = workspace:GetServerTimeNow()

    currentGamemode = gamemodeName

    local finished    = false
    local interrupted = false
    local lastWave    = -1
    local waitForEnd  = false -- se determina dinámicamente desde el HUD

    local useFixedPos = (gamemodeName == "Tempest Invasion" and tempestV2)
    local farmTask = task.spawn(function()
        local runCheck = function()
            return isToggleOnFor(gamemodeName) and not finished and not interrupted
        end
        if useFixedPos then
            holdFixedPosition(TEMPEST_FIXED_CFRAME, runCheck)
        else
            farmEnemiesInGamemode(gamemodeName, runCheck)
        end
    end)

    while isToggleOnFor(gamemodeName) and not finished and not interrupted do
        if shouldInterruptFor(gamemodeName) then
            interrupted = true
            --print("[RUN] " .. gamemodeName .. " interrumpido por prioridad mayor")
            break
        end

        local wave, hudMaxWave = getWaveFromHUD(gamemodeName)

        -- Determinar dinámicamente si debemos esperar al final del gamemode
        if hudMaxWave > 0 and waveTarget >= hudMaxWave then
            waitForEnd = true
        end

        if wave ~= lastWave then
            lastWave = wave
            local displayMax = waitForEnd and tostring(hudMaxWave) or tostring(waveTarget)
            print("[WAVE] " .. gamemodeName .. " - Wave: " .. tostring(wave) .. "/" .. displayMax .. (waitForEnd and " (waiting for end)" or ""))
        end

        if waitForEnd then
            local frame = getGamemodeFrame(gamemodeName)
            if frame and not frame.Visible then
                print("[WAVE] Gamemode complete")
                finished = true
            end
        else
            -- wave muestra la wave actual en curso; cuando wave > waveTarget,
            -- significa que waveTarget ya se completó y la siguiente empezó
            if wave > waveTarget then
                print("[WAVE] Target wave reached")
                finished = true
            end
        end
        task.wait(1)
    end

    task.cancel(farmTask)
    currentGamemode = nil
    if functionsRef then functionsRef:SetFloating(false) end

    -- Teleport solo si terminó naturalmente o fue interrumpido (NO si toggle off)
    local toggleStillOn = isToggleOnFor(gamemodeName)
    if finished or interrupted then
        exitGamemode(savedMap, savedZone, savedPosition)
    end

   -- print("[RUN] runGamemode retornó | finished: " .. tostring(finished) .. " | interrupted: " .. tostring(interrupted))
    return finished, interrupted, entryTime
end

-- ─── Scheduler ────────────────────────────────────────────────────────────────

local function anyToggleOn()
    return trialEnabled or tempestEnabled or dragonEnabled
end

local function ensureSchedulerRunning()
    if schedulerRunning then return end
    schedulerRunning = true

    task.spawn(function()
       -- print("[SCHEDULER] Iniciado")

        while anyToggleOn() do
            local activity = getHighestPriorityActivity()

            if activity == nil then
                -- Nada que hacer (cooldown o no hay trial abierto)
                if autoFarmPaused then
                    resumeAutoFarm()
                end
                task.wait(2)
            else
                -- Intentar unirse
                print("[SCHEDULER] Trying to join: " .. activity)
                fireJoin(activity)
                local entered = waitForEntry(activity)

                if entered then
                    -- Pausar autofarm SOLO después de confirmar entrada
                    pauseAutoFarm()

                    local waveTarget = getWaveTargetFor(activity)
                    local finished, interrupted, entryTime = runGamemode(
                        activity, waveTarget, savedPositionRef
                    )

                    -- Resumir autofarm al salir del gamemode
                    resumeAutoFarm()

                    -- Guardar timer de re-entry si terminó naturalmente
                    if finished then
                        reentryTimers[activity] = entryTime + getEnterTime(activity)
                        print("[SCHEDULER] Re-entry timer para " .. activity .. ": " .. getEnterTime(activity) .. "s")
                        task.wait(2)
                    elseif interrupted then
                        -- Fue interrumpido, no guardar cooldown largo, volver al loop rápido
                        task.wait(1)
                    else
                        -- Toggle fue apagado, continuar loop (se saldrá si no hay más toggles)
                        task.wait(0.5)
                    end
                else
                    print("[SCHEDULER] Could not enter: " .. activity)
                    task.wait(RETRY_DELAY)
                end
            end
        end

        -- Todos los toggles apagados
        resumeAutoFarm()
        schedulerRunning = false
        print("[SCHEDULER] Stopped")
    end)
end

-- ─── API pública ──────────────────────────────────────────────────────────────

function GameMode:Init(functions, enemies, priority)
    functionsRef  = functions
    savedEnemies  = enemies
    savedPriority = priority
end

function GameMode:UpdateAutoFarmParams(enemies, priority)
    savedEnemies  = enemies
    savedPriority = priority
end

function GameMode:StartTrial(waveTargets, savedPosition, selectedTrials)
    selectedTrialsRef  = selectedTrials or {}
    trialWaveTargets   = waveTargets or {}
    savedPositionRef   = savedPosition
    trialEnabled       = true
    ensureSchedulerRunning()
end

function GameMode:StopTrial()
    trialEnabled = false
end

function GameMode:StartTempest(waveTarget, savedPosition)
    tempestWaveTarget = waveTarget or 25
    savedPositionRef  = savedPosition
    tempestEnabled    = true
    ensureSchedulerRunning()
end

function GameMode:StopTempest()
    tempestEnabled = false
end

function GameMode:SetTempestV2(state)
    tempestV2 = state
end

function GameMode:StartDragonDefense(waveTarget, savedPosition)
    dragonWaveTarget = waveTarget or 25
    savedPositionRef = savedPosition
    dragonEnabled    = true
    ensureSchedulerRunning()
end

function GameMode:StopDragonDefense()
    dragonEnabled = false
end

function GameMode:StopAll()
    trialEnabled   = false
    tempestEnabled = false
    dragonEnabled  = false
    currentGamemode = nil
    autoFarmPaused  = false
    reentryTimers   = {}
    if functionsRef then
        functionsRef:SetFloating(false)
    end
end

return GameMode