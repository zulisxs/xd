local UI = {}

function UI:Init(WindUI, Functions, GameMode)

    WindUI:AddTheme({
        Name = "NightSky",
        Accent = WindUI:Gradient({
            ["0"]   = { Color = Color3.fromHex("#0a0e1a"), Transparency = 0 },
            ["70"]  = { Color = Color3.fromHex("#0a0e1a"), Transparency = 0 },
            ["100"] = { Color = Color3.fromHex("#0d1b3e"), Transparency = 0 },
        }, { Rotation = 180 }),
        Background = WindUI:Gradient({
            ["0"]   = { Color = Color3.fromHex("#050810"), Transparency = 0 },
            ["100"] = { Color = Color3.fromHex("#0a1628"), Transparency = 0 },
        }, { Rotation = 90 }),
        Outline     = Color3.fromHex("#1a3a6e"),
        Text        = Color3.fromHex("#d0e8ff"),
        Placeholder = Color3.fromHex("#4a6fa5"),
        Button      = Color3.fromHex("#112244"),
        Icon        = Color3.fromHex("#7ab3e0"),
    })

    local Window = WindUI:CreateWindow({
        Title           = "World Fighter",
        Icon            = "panda",
        Author          = "G4B",
        Folder          = "G4B HUB",
        Size            = UDim2.fromOffset(500, 460),
        MinSize         = Vector2.new(450, 350),
        MaxSize         = Vector2.new(850, 860),
        ToggleKey       = Enum.KeyCode.K,
        Transparent     = false,
        Theme           = "NightSky",
        Resizable       = false,
        SideBarWidth    = 130,
        BackgroundImageTransparency = 0.3,
        HideSearchBar   = true,
        --Background      = "rbxassetid://82853802996092",
        ScrollBarEnable = true,
		    KeySystem = {
        Note = "Enter your key",
        API = {
            {
                Type      = "pandadevelopment",
                ServiceId = "g4bhub", -- tu identifier de Panda
            },
        },
    },
})
	
	Window:Tag({
    Title = "v1.1",
    Icon = "flame",
    Color = Color3.fromHex("#a200ff"),
    Radius = 13, -- from 0 to 13
   })
	Window:EditOpenButton({
        Title           = "G4B HUB",
        Icon            = "monitor",
        CornerRadius    = UDim.new(0, 16),
        StrokeThickness = 2,
        Color           = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
        OnlyMobile      = false,
        Enabled         = true,
        Draggable       = true,
    })
    local Omni = require(game:GetService("ReplicatedStorage"):WaitForChild("Omni"))

    -- ─── Tabs ─────────────────────────────────────────────────────────────────
    local Info        = Window:Tab({ Title = "Main",       Icon = "info",   IconThemed = true })
    Window:Divider()
    local Main        = Window:Tab({ Title = "Auto Farm",       Icon = "skull",  IconThemed = true })
    local GameModeTab = Window:Tab({ Title = "Game Modes", Icon = "swords", IconThemed = true })
    local AutoRename = Window:Tab({Title  = "Auto Rename",Icon   = "pen-line",Locked = false,}) 
    local Accesories = Window:Tab({Title = "Accesories",Icon = "shirt",Locked = false,})
    
    Info:Select()

    -- ─── Estado local de la UI ────────────────────────────────────────────────
    local selectedWorld    = nil
    local selectedZone     = nil
    local selectedEnemies  = {}
    local selectedPriority = "Strongest"

    -- ─── Dropdown: Mundo ──────────────────────────────────────────────────────
    local WorldDropdown = Main:Dropdown({
        Title     = "World",
        Desc      = "Select World",
        Values    = Functions:GetWorlds(),
        Multi     = false,
        AllowNone = true,
        Callback  = function(option)
            selectedWorld   = option
            selectedZone    = nil
            selectedEnemies = {}
            local zones = option and Functions:GetZones(option) or {}
            ZoneDropdown:Refresh(zones)
            EnemiesDropdown:Refresh({})
            Functions:SetZone(selectedWorld, selectedZone)
        end,
    })

    -- ─── Dropdown: Zona ───────────────────────────────────────────────────────
    ZoneDropdown = Main:Dropdown({
        Title     = "Zone",
        Desc      = "Select zone",
        Values    = {},
        Multi     = false,
        AllowNone = true,
        Callback  = function(option)
            selectedZone    = option
            selectedEnemies = {}
            local enemies = (selectedWorld and option)
                and Functions:GetEnemiesFromZone(selectedWorld, option)
                or {}
            EnemiesDropdown:Refresh(enemies)
            Functions:SetZone(selectedWorld, selectedZone)
        end,
    })

    -- ─── Dropdown: Enemigos ───────────────────────────────────────────────────
    EnemiesDropdown = Main:Dropdown({
        Title     = "Enemies",
        Desc      = "Select Enemies",
        Values    = {},
        Multi     = true,
        AllowNone = true,
        Callback  = function(option)
            selectedEnemies = option
        end,
    })

    -- ─── Dropdown: Prioridad ──────────────────────────────────────────────────
    Main:Dropdown({
        Title     = "Priority",
        Desc      = "Select Priority",
        Values    = { "Strongest", "Weakest" },
        Value     = "Strongest",
        Multi     = false,
        AllowNone = false,
        Callback  = function(option)
            selectedPriority = option
        end,
    })

    -- ─── Toggle: Auto Farm ────────────────────────────────────────────────────
    Main:Toggle({
        Title    = "Auto Farm",
        Icon     = "check",
        Type     = "Checkbox",
        Value    = false,
        Callback = function(state)
            GameMode:UpdateAutoFarmParams(selectedEnemies, selectedPriority)
            Functions:SetAutoFarm(state, selectedEnemies, selectedPriority)
        end,
    })
Main:Toggle({
    Title    = "Fast Click",
    Icon     = "check",
    Type     = "Checkbox",
    Value    = false,
    Callback = function(state)
        activo = state

        if activo then
            task.spawn(function()
                local bridgeNet = game:GetService("ReplicatedStorage")
                    :WaitForChild("BridgeNet"):WaitForChild("dataRemoteEvent")
                local REQUEST_LIMIT = 200  -- requests antes de pausar
                local PAUSE_DURATION = 3   -- segundos de pausa
                local requestCount = 0

                while activo do
                    local ids = Omni.Cache:Get({"EnemiesOnRangeIds"})

                    if ids and next(ids) then
                        bridgeNet:FireServer({
                            {
                                "General",
                                "Attack",
                                "Click",
                                ids,
                                n = 4
                            },
                            "\002"
                        })
                        requestCount = requestCount + 1
                    end

                    if requestCount >= REQUEST_LIMIT then
                        requestCount = 0
                        task.wait(PAUSE_DURATION)
                    else
                        task.wait(0.1)
                    end
                end
            end)
        end
    end,
})

    -- ─── Tab Info ─────────────────────────────────────────────────────────────
    Info:Paragraph({
        Title = "G4B HUB Update log",
        Desc  = "Hey guys, if there are any errors with the script, let me know on Discord.\nV1.1: \n- Add fast atack speed \n- Fix Auto farm \n -Fix auto Farm game modes \nV1.0: \n - Release Script" ,
        Color = "Grey",
        Thumbnail = "rbxassetid://76454598364905",
        ThumbnailSize = 200,
    })

    Info:Button({
        Title    = "Discord Server",
        Desc     = "Click to copy invite link",
        Icon     = "link",
        Justify  = "Between",
        Callback = function()
            setclipboard("https://discord.gg/EkwvPJGFjv")
            WindUI:Notify({
                Title    = "Discord",
                Content  = "Link copied to clipboard!",
                Duration = 3,
                Icon     = "clipboard-check",
            })
        end,
    })

    -- ─── Tab Game Modes ───────────────────────────────────────────────────────
    GameModeTab:Section({
        Title          = "Game Modes",
        TextXAlignment = "Center",
    })
    GameModeTab:Divider()

    -- ─── Estado: posición guardada (tabla mutable para pasar por referencia) ──
    local savedPosition = {}

GameModeTab:Button({
    Title    = "Save Position",
    Desc     = "Save current CFrame, map and zone to return here after game mode",
    Icon     = "map-pin",
    Justify  = "Between",
    Callback = function()
        local char = game:GetService("Players").LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            WindUI:Notify({
                Title    = "Error",
                Content  = "Character not found!",
                Duration = 3,
                Icon     = "alert-triangle",
            })
            return
        end
        local Omni = require(game:GetService("ReplicatedStorage"):WaitForChild("Omni"))
        savedPosition.cframe = hrp.CFrame
        savedPosition.map    = Omni.Data.Map
        savedPosition.zone   = Omni.Data.Zone
        local pos = hrp.CFrame.Position
        WindUI:Notify({
            Title    = "Position Saved",
            Content  = string.format("%s | Zone %s | (%.1f, %.1f, %.1f)", tostring(Omni.Data.Map), tostring(Omni.Data.Zone), pos.X, pos.Y, pos.Z),
            Duration = 4,
            Icon     = "save",
        })
    end,
})

    GameModeTab:Divider()
    GameModeTab:Space()

-- ─── Trial ────────────────────────────────────────────────────────────────
GameModeTab:Section({ Title = "Trial", TextXAlignment = "Left" })
local selectedTrials = {}
local trialWaveTargets = {
    ["Trial Easy"]   = 25,
    ["Trial Medium"] = 25,
    ["Trial Hard"]   = 25,
}

GameModeTab:Dropdown({
    Title    = "Trials",
    Desc     = "Select Trials to farm",
    Values   = { "Trial Easy", "Trial Medium", "Trial Hard" },
    Multi    = true,
    AllowNone = true,
    Callback = function(option)
        selectedTrials = option
    end,
})

GameModeTab:Input({
    Title       = "Leave Trial Easy",
    Desc        = "Exit after completing the wave",
    InputIcon   = "undo-2",
    Type        = "Input",
    Placeholder = "Enter wave",
    Value       = "25",
    Callback    = function(input)
        local n = tonumber(input)
        if n then trialWaveTargets["Trial Easy"] = n end
    end,
})

GameModeTab:Input({
    Title       = "Leave Trial Medium",
    Desc        = "Exit after completing the wave",
    InputIcon   = "undo-2",
    Type        = "Input",
    Placeholder = "Enter wave",
    Value       = "25",
    Callback    = function(input)
        local n = tonumber(input)
        if n then trialWaveTargets["Trial Medium"] = n end
    end,
})

GameModeTab:Input({
    Title       = "Leave Trial Hard",
    Desc        = "Exit after completing the wave",
    InputIcon   = "undo-2",
    Type        = "Input",
    Placeholder = "Enter wave",
    Value       = "25",
    Callback    = function(input)
        local n = tonumber(input)
        if n then trialWaveTargets["Trial Hard"] = n end
    end,
})

GameModeTab:Toggle({
    Title    = "Auto Farm Trial",
    Icon     = "check",
    Type     = "Checkbox",
    Value    = false,
    Callback = function(state)
        GameMode:Init(Functions, selectedEnemies, selectedPriority)
        if state then
            GameMode:StartTrial(trialWaveTargets, savedPosition, selectedTrials)
        else
            GameMode:StopTrial()
        end
    end,
})

    -- ─── Dragon Defense ───────────────────────────────────────────────────────
    GameModeTab:Section({ Title = "Dragon Defense", TextXAlignment = "Left" })

    local defenseWaveTarget = 25

    GameModeTab:Input({
        Title       = "Leave Dragon Defense",
        Desc        = "Exit after completing the wave",
        InputIcon   = "undo-2",
        Type        = "Input",
        Placeholder = "Enter wave",
        Value       = "25",
        Callback    = function(input)
            local n = tonumber(input)
            if n then defenseWaveTarget = n end
        end,
    })

    GameModeTab:Toggle({
        Title    = "Auto Farm Dragon Defense",
        Icon     = "check",
        Type     = "Checkbox",
        Value    = false,
        Callback = function(state)
            GameMode:Init(Functions, selectedEnemies, selectedPriority)
            if state then
                GameMode:StartDragonDefense(defenseWaveTarget, savedPosition)
            else
                GameMode:StopDragonDefense()
            end
        end,
    })

    -- ─── Tempest Invasion ─────────────────────────────────────────────────────
    GameModeTab:Section({ Title = "Tempest Invasion", TextXAlignment = "Left" })

    local tempestWaveTarget = 25

    GameModeTab:Input({
        Title       = "Leave Tempest Invasion",
        Desc        = "Exit after completing the wave",
        InputIcon   = "undo-2",
        Type        = "Input",
        Placeholder = "Enter wave",
        Value       = "25",
        Callback    = function(input)
            local n = tonumber(input)
            if n then tempestWaveTarget = n end
        end,
    })

    GameModeTab:Toggle({
        Title    = "Auto Farm Tempest Invasion",
        Icon     = "check",
        Type     = "Checkbox",
        Value    = false,
        Callback = function(state)
            GameMode:Init(Functions, selectedEnemies, selectedPriority)
            if state then
                GameMode:StartTempest(tempestWaveTarget, savedPosition)
            else
                GameMode:StopTempest()
            end
        end,
    })

    GameModeTab:Toggle({
        Title    = "Auto Farm Tempest Invasion v2",
        Desc     = "Stay at center of the map instead of chasing enemies",
        Icon     = "check",
        Type     = "Checkbox",
        Value    = false,
        Callback = function(state)
            GameMode:SetTempestV2(state)
        end,
    })
-------------------------------------Auto rename y auto sell no cambiar nada de aca para abajo------------------------------------


    local Section = AutoRename:Section({ 
    Title = "Auto Rename",
    TextXAlignment = "Center",
})

AutoRename:Divider()

local SectionAcc = Accesories:Section({ 
    Title = "Auto Sell",
    TextXAlignment = "Center",
})
Accesories:Divider()
-- ─── Estado ───────────────────────────────────────────────────────────────
local state = {
    unitQueue  = {},  -- cola de unitIds en orden de selección
    unitIndex  = 1,   -- índice de la unidad actual en la cola
    unitId     = "",  -- unidad actual procesándose
    name1      = "",
    name2      = "",
    power      = nil,
    crystal    = nil,
    damage     = nil,
    running    = false,
    nameIndex  = 1,
    
}
local sellRarities = {}
local autoSellActive = false
local autoSellConnection = nil
local soloEquipadas = false
local allTargetStop = true
-- ─── Helpers DataContainer ────────────────────────────────────────────────
local function getPlayerData()
    if not Omni or not Omni.Data then return nil end
    return { Data = Omni.Data }
end

local function getUnitList(soloEquipadas)
    local pd = getPlayerData()
    if not pd or not pd.Data then return {}, {} end

    local labels = {}
    local labelToId = {}

    -- Obtener IDs de unidades equipadas
    local equipadas = {}
    if soloEquipadas and pd.Data.UnitsEquipped then
        for unitId, _ in pairs(pd.Data.UnitsEquipped) do
            equipadas[unitId] = true
        end
    end

    for unitId, unit in pairs(pd.Data.Inventory.Units) do
        -- Si el filtro está activo, saltar las no equipadas
        if soloEquipadas and not equipadas[unitId] then
            continue
        end

        local label = unit.Name .. " #" .. tostring(unit.SerialNumber)
        if unit.CustomName and unit.CustomName ~= "" then
            label = label .. ' ["' .. unit.CustomName .. '"]'
        end

        table.insert(labels, label)
        labelToId[label] = unitId
    end

    table.sort(labels, function(a, b)
     local numA = tonumber(a:match("#(%d)"))
     local numB = tonumber(b:match("#(%d)"))
     return (numA or 0) < (numB or 0)
    end)
    return labels, labelToId
end

local function getUnitBuffs(unitId)
    local pd = getPlayerData()
    if not pd or not pd.Data then return nil end
    local unit = pd.Data.Inventory.Units[unitId]
    if not unit then return nil end
    return unit.RenameBuffs
end

local function buffsSatisfied()
    local buffs = getUnitBuffs(state.unitId)
    if not buffs then
        if state.power ~= nil or state.crystal ~= nil or state.damage ~= nil then
            return false
        end
        return true
    end

    if allTargetStop then
        -- Todos los targets configurados deben cumplirse
        if state.power ~= nil then
            if (buffs.Power or 0) < state.power then return false end
        end
        if state.damage ~= nil then
            if (buffs.Damage or 0) < state.damage then return false end
        end
        if state.crystal ~= nil then
            if (buffs.Crystals or 0) < state.crystal then return false end
        end
        return true
    else
        -- Basta con que al menos uno de los targets configurados se cumpla
        if state.power ~= nil and (buffs.Power or 0) >= state.power then
            return true
        end
        if state.damage ~= nil and (buffs.Damage or 0) >= state.damage then
            return true
        end
        if state.crystal ~= nil and (buffs.Crystals or 0) >= state.crystal then
            return true
        end
        return false
    end
end
-- ─── Helper Rename Tokens ─────────────────────────────────────────────────
local function getRenameTokens()
    local pd = getPlayerData()
    if not pd or not pd.Data then return 0 end
    local tokens = pd.Data.Inventory.Items["Rename Token"]
    if not tokens then return 0 end
    return math.floor(tokens)
end
-- ─── Helper Auto Sell ─────────────────────────────────────────────────────
local function sellAccessoriesByRarity()
    local pd = getPlayerData()
    if not pd or not pd.Data then return end

    -- Obtener accesorios equipados
    local equipados = {}
    if pd.Data.AccessoriesEquipped then
        for _, accId in pairs(pd.Data.AccessoriesEquipped) do
            equipados[accId] = true
        end
    end

    local toSell = {}
    for accId, acc in pairs(pd.Data.Inventory.Accessories) do
        -- Ignorar equipados
        if not equipados[accId] and sellRarities[acc.Rarity] then
            table.insert(toSell, accId)
        end
    end

    if #toSell == 0 then return end

    local args = {
        {
            {
                "General",
                "Accessories",
                "Delete",
                toSell,
                n = 4
            },
            "\002"
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet"):WaitForChild("dataRemoteEvent"):FireServer(unpack(args))

    WindUI:Notify({
        Title   = "Auto Sell",
        Content = "Sold " .. #toSell .. " accessories.",
        Icon    = "shopping-cart",
        Duration = 4,
    })
end
-- ─── UI: Dropdown de unidades ─────────────────────────────────────────────
local labels, labelToId = getUnitList(false)

local UnitDropdown = AutoRename:Dropdown({
    Title    = "Select Unit",
    Desc     = "Select units in order to rename",
    Icon     = "layers",
    Multi    = true,
    Values   = labels,
    Callback = function(selected)
        -- selected es una tabla con los labels seleccionados
        -- pero Multi no garantiza orden, así que lo manejamos manualmente
        state.unitQueue = {}
        for _, label in ipairs(selected) do
            local id = labelToId[label]
            if id then
                table.insert(state.unitQueue, id)
            end
        end
        -- Mostrar buffs de la primera unidad seleccionada
        if #state.unitQueue > 0 then
            state.unitId = state.unitQueue[1]
            local buffs = getUnitBuffs(state.unitId)
            if buffs then
                local parts = {}
                if buffs.Power    then table.insert(parts, "Power: "    .. tostring(buffs.Power))    end
                if buffs.Damage   then table.insert(parts, "Damage: "   .. tostring(buffs.Damage))   end
                if buffs.Crystals then table.insert(parts, "Crystals: " .. tostring(buffs.Crystals)) end
                WindUI:Notify({
                    Title    = "Unit selected",
                    Content  = table.concat(parts, " | "),
                    Icon     = "layers",
                    Duration = 3,
                })
            end
        end
    end
})

-- Botón para refrescar la lista de unidades
AutoRename:Button({
    Title    = "Refresh Units",
	Desc = "First open inventory",
    Icon     = "refresh-cw",
    Callback = function()
	    local pd = getPlayerData()
 
        labels, labelToId = getUnitList(soloEquipadas)
        UnitDropdown:Refresh(labels)

        local pd = getPlayerData()
        if pd and pd.Data then
            local unitFrames = game:GetService("Players").LocalPlayer.PlayerGui.UI.Frames.Units.Background.Main.Canvas.List
            for unitId, unit in pairs(pd.Data.Inventory.Units) do
                local frame = unitFrames:FindFirstChild(unitId)
                if frame then
                    local bg = frame:FindFirstChild("Background")
				    if bg then
                       local titleFrame = bg:FindFirstChild("Title")
					    if titleFrame then
                          local frontTitle = titleFrame:FindFirstChild("FrontTitle")
                           if frontTitle then
                               frontTitle.Text = "#" .. tostring(unit.SerialNumber)
							end
					    end
                    end 
                end
            end
        end
    end
})

 

AutoRename:Toggle({
    Title    = "Only unit equiped ",
    Icon     = "shield",
    Type     = "Checkbox",
    Value    = false,
    Callback = function(active)
        soloEquipadas = active

        -- Refrescar dropdown automáticamente al cambiar el toggle
        labels, labelToId = getUnitList(soloEquipadas)
        UnitDropdown:Refresh(labels)
    end
})
AutoRename:Divider()

local Name1 = AutoRename:Input({
    Title       = "Name 1",
    Desc        = "Select the name 1",
    InputIcon   = "text-cursor",
    Type        = "Input",
    Placeholder = "Enter name...",
    Callback    = function(input)
        state.name1 = input
    end
})

local Name2 = AutoRename:Input({
    Title       = "Name 2",
    Desc        = "Select the name 2",
    InputIcon   = "text-cursor",
    Type        = "Input",
    Placeholder = "Enter name...",
    Callback    = function(input)
        state.name2 = input
    end
})

AutoRename:Divider()

local PowerInput = AutoRename:Input({
    Title       = "Power",
	Desc ="leave empty = ignore",
    Placeholder = "Ej: 1.75",
    Callback    = function(input)
        state.power = tonumber(input)
    end
})

local CrystalInput = AutoRename:Input({
    Title       = "Crystal",
	Desc ="leave empty = ignore",
    Placeholder = "Ej: 0.75",
    Callback    = function(input)
        state.crystal = tonumber(input)
    end
})

local DamageInput = AutoRename:Input({
    Title       = "Damage",
	Desc ="leave empty = ignore",
    Placeholder = "Ej: 0.75",
    Callback    = function(input)
        state.damage = tonumber(input)
    end
})

AutoRename:Divider()

-- ─── Helpers rename ───────────────────────────────────────────────────────
local function sendRename(unitId, name)
    local args = {
        {
            {
                "General",
                "Units",
                "Rename",
                unitId,
                name,
                n = 5
            },
            "\002"
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet"):WaitForChild("dataRemoteEvent"):FireServer(unpack(args))
end
-- ─── Loop principal ───────────────────────────────────────────────────────
local function runLoop()
    if #state.unitQueue == 0 then
        WindUI:Notify({
            Title    = "Error",
            Content  = "Select at least one unit before activating.",
            Icon     = "alert-circle",
            Duration = 4,
        })
        return
    end
    if state.name1 == "" or state.name2 == "" then
        WindUI:Notify({
            Title    = "Error",
            Content  = "Enter Name 1 and Name 2 before activating.",
            Icon     = "alert-circle",
            Duration = 4,
        })
        return
    end
    if state.power == nil and state.crystal == nil and state.damage == nil then
        WindUI:Notify({
            Title    = "Error",
            Content  = "Enter at least one buff target.",
            Icon     = "alert-circle",
            Duration = 4,
        })
        return
    end

    state.unitIndex = 1

    while state.running and state.unitIndex <= #state.unitQueue do
        state.unitId  = state.unitQueue[state.unitIndex]
        state.nameIndex = 1

     local pd = getPlayerData()
     local unitData = pd and pd.Data and pd.Data.Inventory.Units[state.unitId]
     local unitLabel = unitData and (unitData.Name .. " #" .. tostring(unitData.SerialNumber)) or state.unitId

     WindUI:Notify({
          Title    = "Processing unit " .. state.unitIndex .. "/" .. #state.unitQueue,
          Content  = unitLabel,
         Icon     = "layers",
         Duration = 4,
        })

        -- Loop de rename para la unidad actual
        while state.running do
            -- Verificar tokens
            local tokens = getRenameTokens()
            if tokens < 10 then
                WindUI:Notify({
                    Title    = "Waiting for tokens",
                    Content  = "Rename Tokens: " .. tostring(tokens) .. "/10",
                    Icon     = "clock",
                    Duration = 5,
                })
                while state.running and getRenameTokens() < 10 do
                    task.wait(5)
                end
                if not state.running then break end
                WindUI:Notify({
                    Title    = "Tokens available!",
                    Content  = "Rename Tokens: " .. tostring(getRenameTokens()),
                    Icon     = "check-circle",
                    Duration = 4,
                })
            end

          local currentName = (state.nameIndex == 1) and state.name1 or state.name2

          -- Verificar si la unidad ya tiene ese nombre, si es así alternar primero
          local pd = getPlayerData()
          local unitData = pd and pd.Data and pd.Data.Inventory.Units[state.unitId]
          if unitData and unitData.CustomName == currentName then
            -- Saltar al otro nombre directamente
            state.nameIndex = (state.nameIndex == 1) and 2 or 1
            currentName = (state.nameIndex == 1) and state.name1 or state.name2
          end

          sendRename(state.unitId, currentName)
 
            task.wait(1.2)

            local buffs = getUnitBuffs(state.unitId)
            local buffText = "No buffs yet"
            if buffs then
                local parts = {}
                if buffs.Power    then table.insert(parts, "Power: "    .. tostring(buffs.Power))    end
                if buffs.Damage   then table.insert(parts, "Damage: "   .. tostring(buffs.Damage))   end
                if buffs.Crystals then table.insert(parts, "Crystals: " .. tostring(buffs.Crystals)) end
                if #parts > 0 then buffText = table.concat(parts, " | ") end
            end

            WindUI:Notify({
                Title    = "Rename → " .. currentName,
                Content  = buffText,
                Icon     = "refresh-cw",
                Duration = 5,
            })

            if buffsSatisfied() then
                WindUI:Notify({
                    Title    = "Buffs achieved! " .. state.unitIndex .. "/" .. #state.unitQueue,
                    Content  = buffText,
                    Icon     = "check-circle",
                    Duration = 8,
                })
                -- Pasar a la siguiente unidad
                state.unitIndex = state.unitIndex + 1
                break
            end

            state.nameIndex = (state.nameIndex == 1) and 2 or 1
            task.wait(0.5)
        end
    end

    -- Terminó todas las unidades
    if state.unitIndex > #state.unitQueue then
        WindUI:Notify({
            Title    = "All units done!",
            Content  = "All " .. #state.unitQueue .. " units have been renamed.",
            Icon     = "check-circle",
            Duration = 8,
        })
    end

    state.running = false
end
-- ─── Toggle ───────────────────────────────────────────────────────────────
local AutoName = AutoRename:Toggle({
    Title    = "Activate",
    Icon     = "check",
    Type     = "Checkbox",
    Value    = false,
    Callback = function(active)
        state.running = active
        if active then
            state.nameIndex = 1
            task.spawn(runLoop)
        end
    end
})
 

AutoRename:Toggle({
    Title    = "All target stop",
    Desc = "If you want the script to search for all the buffs you entered, leave this enabled. Otherwise, disable it.",
    Icon     = "target",
    Type     = "Checkbox",
    Value    = true, -- por defecto busca todos
    Callback = function(active)
        allTargetStop = active
    end
})

local SelectAccesories = Accesories:Dropdown({
    Title    = "Select accesories",
    Desc     = "Accessories of the selected rarity will be sold",
    Icon     = "shopping-cart",
    Values   = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Secret"},
    Multi    = true,
    AllowNone = true,
    Callback = function(option)
        -- Resetear y reconstruir la tabla de rarezas seleccionadas
        sellRarities = {}
        for _, rarity in ipairs(option) do
            sellRarities[rarity] = true
        end
    end
})

local ActiveSell = Accesories:Toggle({
    Title    = "Auto Sell",
    Desc     = "Active for auto sell accesories",
    Icon     = "check",
    Type     = "Checkbox",
    Value    = false,
    Callback = function(active)
        autoSellActive = active

        if active then
            -- Vender los que ya están en el inventario al activar
            sellAccessoriesByRarity()

            -- Loop cada 10 segundos
            autoSellConnection = task.spawn(function()
                while autoSellActive do
                    task.wait(10)
                    if autoSellActive then
                        sellAccessoriesByRarity()
                    end
                end
            end)
        else
            autoSellActive = false
            -- task.spawn no tiene Disconnect, se detiene solo con autoSellActive = false
        end
    end
})

------------------AUTO FARM BOSS--------------

-- ─── Data de bosses ───────────────────────────────────────────────────────
local GlobalBosses = require(game:GetService("ReplicatedStorage").Omni.Shared.GlobalBosses)
local templates = workspace:WaitForChild("Server")
    :WaitForChild("Enemies")
    :WaitForChild("Templates")
    :WaitForChild("Global Bosses")

local ListBoss = {}
local InfoBoss = {}
local BossesElegidos = {}

for nombre, info in pairs(GlobalBosses.List) do
    table.insert(ListBoss, nombre)
    InfoBoss[nombre] = {
        MapName   = info.MapName,
        ZoneIndex = info.ZoneIndex
    }
end

-- ─── Funciones de tiempo ──────────────────────────────────────────────────
local function textoASegundos(texto)
    if texto == "0s" then return 0 end
    local minutos  = tonumber(texto:match("(%d+)m")) or 0
    local segundos = tonumber(texto:match("(%d+)s")) or 0
    return (minutos * 60) + segundos
end

local function segundosATexto(segundos)
    if segundos <= 0 then return "Boss Alive" end
    local m = math.floor(segundos / 60)
    local s = segundos % 60
    if m > 0 then
        return m .. "m " .. s .. "s"
    else
        return s .. "s"
    end
end

-- ─── UI del timer ─────────────────────────────────────────────────────────
 
local playerGui = Omni.Instance.PlayerGui
local frames    = playerGui:WaitForChild("UI"):WaitForChild("Frames")
local contadores = {}

local function limpiarUI()
    -- elimina el frame anterior y cancela los contadores activos
    -- es como vaciar la pizarra antes de escribir de nuevo
    for nombreBoss, hilo in pairs(contadores) do
        task.cancel(hilo)
    end
    contadores = {}
    local frameAnterior = frames:FindFirstChild("BossTimer")
    if frameAnterior then frameAnterior:Destroy() end
end

local function crearUI()
    limpiarUI()

    local bossTimer = Instance.new("Frame")
    bossTimer.Name = "BossTimer"
    bossTimer.Size = UDim2.fromOffset(350, #BossesElegidos * 100 + 10)
    bossTimer.Position = UDim2.fromScale(0.01, 0.3)
    bossTimer.BackgroundTransparency = 1
    bossTimer.Parent = frames

    local fondo = Instance.new("ImageLabel")
    fondo.Size = UDim2.fromScale(1, 1)
    fondo.Image = "rbxassetid://94934733101179"
    fondo.BackgroundTransparency = 1
    fondo.Parent = bossTimer

    -- UICorner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 25)
    corner.Parent = fondo

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = fondo

    -- Drag
    local dragging = false
    local dragStart = nil
    local startPos = nil

    fondo.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = bossTimer.Position
        end
    end)

    fondo.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            bossTimer.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    for _, nombreBoss in pairs(BossesElegidos) do
        local bossFolder = templates:FindFirstChild(nombreBoss)
        if not bossFolder then continue end

        local hud = bossFolder:FindFirstChild("HUD")
        if not hud then continue end

        local timeLabel = hud:FindFirstChild("Time")
        if not timeLabel then continue end

        local tiempo = textoASegundos(timeLabel.Text)

        local nombreLabel = Instance.new("TextLabel")
        nombreLabel.Name = nombreBoss
        nombreLabel.Size = UDim2.new(1, 0, 0, 60)
        nombreLabel.BackgroundTransparency = 1
        nombreLabel.Text = nombreBoss
        nombreLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nombreLabel.TextScaled = true
        nombreLabel.TextXAlignment = Enum.TextXAlignment.Left  -- ✅
        nombreLabel.Parent = fondo

        local timerLabel = Instance.new("TextLabel")
        timerLabel.Name = "Timer"
        timerLabel.Size = UDim2.new(1, 0, 0, 25)
        timerLabel.Position = UDim2.fromOffset(0, 24)
        timerLabel.BackgroundTransparency = 1
        timerLabel.TextScaled = true
        timerLabel.TextXAlignment = Enum.TextXAlignment.Right  -- ✅
        timerLabel.Parent = nombreLabel
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(0, 0, 0)
        stroke.Thickness = 3
        stroke.Parent = timerLabel

        if tiempo <= 0 then
            timerLabel.Text = "Boss Alive"
            timerLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        else
            timerLabel.Text = segundosATexto(tiempo)
            timerLabel.TextColor3 = Color3.fromRGB(255, 220, 0)
        end

        contadores[nombreBoss] = task.spawn(function()
            while tiempo > 0 do
                task.wait(1)
                tiempo = tiempo - 1
                timerLabel.Text = segundosATexto(tiempo)
                if tiempo <= 0 then
                    timerLabel.Text = "Boss Alive"
                    timerLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                end
            end
        end)
    end
end
local BossSection = Main:Section({ 
    Title = "Global Bosses",
})
Main:Divider()
-- ─── Dropdown ─────────────────────────────────────────────────────────────
local GlobalBoss = Main:Dropdown({
    Title     = "Boss",
    Desc      = "Select boss",
    Values    = ListBoss,
    Multi     = true,
    AllowNone = true,
    Callback  = function(option)
        BossesElegidos = option or {}
    end
})

-- ─── BridgeNet ────────────────────────────────────────────────────────────
local BRIDGE_NET = game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet"):WaitForChild("dataRemoteEvent")

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

-- ─── Botón de teleport ────────────────────────────────────────────────────
Main:Button({
    Title    = "Teleport & Track",
    Desc     = "Teleport al boss y activa el timer",
    Icon     = "map-pin",
    Callback = function()
        if #BossesElegidos == 0 then return end

        -- Crear la UI con los contadores
        crearUI()

        -- Teleport al primer boss elegido (solo si no está en su mapa/zona)
        local primerBoss = BossesElegidos[1]
        if InfoBoss[primerBoss] then
            local info = InfoBoss[primerBoss]
            if Omni.Data.Map ~= info.MapName or tostring(Omni.Data.Zone) ~= tostring(info.ZoneIndex) then
                fireTeleport(info.MapName, info.ZoneIndex)
            end
        end
    end
})

-- ─── Toggles ──────────────────────────────────────────────────────────────
local bossAutoFarmActive = false
local PlayerStatsBoss = Omni.Utils.PlayerStats

-- CFrames conocidos de cada boss (fallback si no cargó el BasePart)
local BossCFrames = {
    ["Sakana"] = CFrame.new(10572.9756, 659.354675, -5189.31104, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    ["Satoro"] = CFrame.new(10810.6367, 659.341309, -5019.60352, 0.682592869, 0, 0.73079896, 0, 1, 0, -0.73079896, 0, 0.682592869),
    ["Yuje"]   = CFrame.new(10873.502, 773.154114, -5159.50684, -1.1920929e-07, 0, 1.00000012, 0, 1, 0, -1.00000012, 0, -1.1920929e-07),
}

local function isGlobalBossAlive(boss)
    if boss == nil or boss.Parent == nil then return false end
    local health = boss:GetAttribute("Health") or 0
    return health > 0
end

local LocalPlayer = game:GetService("Players").LocalPlayer

local FarmBoss = Main:Toggle({
    Title    = "Auto Farm Global Bosses",
    Icon     = "skull",
    Type     = "Checkbox",
    Value    = false,
    Callback = function(state)
        bossAutoFarmActive = state
        if state then
            -- Solo crear UI si no existe
            if not frames:FindFirstChild("BossTimer") then
                crearUI()
            end
            print("[BOSS] Toggle ON - BossesElegidos type: " .. type(BossesElegidos))
            -- Debug: mostrar contenido de BossesElegidos
            for k, v in pairs(BossesElegidos) do
                print("[BOSS]   key=" .. tostring(k) .. " value=" .. tostring(v))
            end
            task.spawn(function()
                while bossAutoFarmActive do
                    -- 1. Recolectar TODOS los bosses alive
                    local aliveBosses = {}

                    -- Extraer nombres (soporta array y dict)
                    local bossNames = {}
                    for k, v in pairs(BossesElegidos) do
                        if type(k) == "number" then
                            table.insert(bossNames, v)
                        elseif type(k) == "string" and v then
                            table.insert(bossNames, k)
                        end
                    end

                    -- Verificar timers desde templates
                    for _, bossName in ipairs(bossNames) do
                        if not bossAutoFarmActive then break end

                        local bossFolder = templates:FindFirstChild(bossName)

                        -- Si template no existe, viajar para cargarlo
                        if not bossFolder then
                            print("[BOSS] Template '" .. bossName .. "' no cargado, viajando...")
                            local info = InfoBoss[bossName]
                            if info then
                                fireTeleport(info.MapName, info.ZoneIndex)
                                task.wait(3)
                                if BossCFrames[bossName] then
                                    local hrp = workspace:FindFirstChild(LocalPlayer.Name)
                                        and workspace[LocalPlayer.Name]:FindFirstChild("HumanoidRootPart")
                                    if hrp then
                                        hrp.CFrame = BossCFrames[bossName] + Vector3.new(0, 10, 0)
                                    end
                                    task.wait(2)
                                end
                                bossFolder = templates:FindFirstChild(bossName)
                            end
                        end

                        if bossFolder then
                            local hud = bossFolder:FindFirstChild("HUD")
                            local timeLabel = hud and hud:FindFirstChild("Time")
                            if timeLabel then
                                local timerText = timeLabel.Text
                                print("[BOSS] " .. bossName .. " timer: '" .. timerText .. "'")
                                if timerText == "0s" then
                                    table.insert(aliveBosses, bossName)
                                end
                            end
                        end
                    end

                    if #aliveBosses > 0 then
                        print("[BOSS] Bosses alive: " .. table.concat(aliveBosses, ", "))

                        -- 2. Esperar a que salga del gamemode
                        while bossAutoFarmActive and GameMode:IsInGamemode() do
                            task.wait(1)
                        end
                        if not bossAutoFarmActive then break end

                        -- 3. Pausar autofarm
                        local wasAutoFarming = Functions:IsAutoFarmRunning()
                        if wasAutoFarming then
                            Functions:SetAutoFarm(false, selectedEnemies, selectedPriority)
                        end

                        -- 4. Guardar posición de retorno
                        local returnMap, returnZone, returnCFrame
                        if savedPosition.cframe then
                            returnMap    = savedPosition.map
                            returnZone   = savedPosition.zone
                            returnCFrame = savedPosition.cframe
                        else
                            returnMap  = Omni.Data.Map
                            returnZone = Omni.Data.Zone
                            local char = LocalPlayer.Character
                            returnCFrame = char and char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart.CFrame
                        end

                        -- 5. Matar TODOS los bosses alive en un viaje
                        for _, bossName in ipairs(aliveBosses) do
                            if not bossAutoFarmActive then break end

                            print("[BOSS] Preparando " .. bossName .. "...")

                            -- PASO 1: Teleport al mapa del boss
                            local info = InfoBoss[bossName]
                            if info and (Omni.Data.Map ~= info.MapName or tostring(Omni.Data.Zone) ~= tostring(info.ZoneIndex)) then
                                print("[BOSS] Teleportando al mapa: " .. info.MapName .. " zona " .. tostring(info.ZoneIndex))
                                fireTeleport(info.MapName, info.ZoneIndex)
                                task.wait(3)
                            end

                            -- PASO 2: Flotar + ir al CFrame conocido del boss
                            Functions:SetFloating(true)
                            if BossCFrames[bossName] then
                                local hrp = workspace:FindFirstChild(LocalPlayer.Name)
                                    and workspace[LocalPlayer.Name]:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                    print("[BOSS] Yendo a CFrame de " .. bossName)
                                    hrp.CFrame = BossCFrames[bossName] + Vector3.new(0, 10, 0)
                                end
                            end
                            task.wait(1)

                            -- PASO 3: Buscar el BasePart del boss
                            local boss = nil
                            local bossEnemyFolder = workspace:FindFirstChild("Server")
                                and workspace.Server:FindFirstChild("Enemies")
                                and workspace.Server.Enemies:FindFirstChild("Global Bosses")

                            if bossEnemyFolder then
                                for _, e in ipairs(bossEnemyFolder:GetChildren()) do
                                    if e:IsA("BasePart") and e.Name == bossName and isGlobalBossAlive(e) then
                                        boss = e
                                        break
                                    end
                                end
                            end

                            if boss then
                                -- Teleportar al BasePart real
                                print("[BOSS] Encontrado " .. bossName .. " → atacando")
                                local hrp = workspace:FindFirstChild(LocalPlayer.Name)
                                    and workspace[LocalPlayer.Name]:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                    hrp.CFrame = boss.CFrame + Vector3.new(0, 10, 0)
                                end
                            else
                                -- Esperar a que aparezca en la ubicación conocida
                                print("[BOSS] " .. bossName .. " no cargó, esperando en CFrame conocido...")
                                while bossAutoFarmActive and not boss do
                                    task.wait(0.5)
                                    bossEnemyFolder = workspace:FindFirstChild("Server")
                                        and workspace.Server:FindFirstChild("Enemies")
                                        and workspace.Server.Enemies:FindFirstChild("Global Bosses")
                                    if bossEnemyFolder then
                                        for _, e in ipairs(bossEnemyFolder:GetChildren()) do
                                            if e:IsA("BasePart") and e.Name == bossName and isGlobalBossAlive(e) then
                                                boss = e
                                                break
                                            end
                                        end
                                    end
                                end
                                if boss then
                                    print("[BOSS] " .. bossName .. " apareció!")
                                    local hrp2 = workspace:FindFirstChild(LocalPlayer.Name)
                                        and workspace[LocalPlayer.Name]:FindFirstChild("HumanoidRootPart")
                                    if hrp2 then
                                        hrp2.CFrame = boss.CFrame + Vector3.new(0, 10, 0)
                                    end
                                end
                            end

                            -- PASO 4: Esperar a que muera (BasePart se borra)
                            if boss then
                                while bossAutoFarmActive and boss and boss.Parent ~= nil do
                                    task.wait(0.1)
                                end
                                print("[BOSS] " .. bossName .. " killed!")
                            end

                            Functions:SetFloating(false)
                        end

                        -- 6. Esperar y refrescar timers
                        task.wait(3)
                        crearUI()

                        -- 7. Volver a savedPosition o posición anterior
                        if returnMap then
                            fireTeleport(returnMap, returnZone)
                            task.wait(3)
                        end
                        if returnCFrame then
                            local char2 = LocalPlayer.Character
                            if char2 and char2:FindFirstChild("HumanoidRootPart") then
                                char2.HumanoidRootPart.CFrame = returnCFrame
                            end
                        end
                        task.wait(2)

                        -- 8. Reanudar autofarm
                        if wasAutoFarming then
                            Functions:SetAutoFarm(true, selectedEnemies, selectedPriority)
                        end
                    end

                    task.wait(2) -- Revisar cada 2 segundos
                end
            end)
        else
            limpiarUI()
        end
    end
})

local UIBoss = Main:Toggle({
    Title    = "Hiden UI",
    Icon     = "eye-closed",
    Type     = "Checkbox",
    Value    = false,
    Callback = function(state)
        if state then
            local frame = frames:FindFirstChild("BossTimer")
            if frame then frame.Visible = false end
        else
            local frame = frames:FindFirstChild("BossTimer")
            if frame then frame.Visible = true end
        end
    end
}) 

end

return UI
