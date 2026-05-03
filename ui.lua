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
		--    KeySystem = {
      --  Note = "Enter your key",
     --   API = {
       --     {
        --        Type      = "pandadevelopment",
         --       ServiceId = "g4bhub", -- tu identifier de Panda
        --    },
       -- },
  --  },
})
	
	Window:Tag({
    Title = "v1.2",
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
    local Loadouts = Window:Tab({Title = "Loadouts",Icon = "rocket",Locked = false,})
    
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
        Desc  = "Hey guys, if there are any errors with the script, let me know on Discord.\nV1.2:\n- Add Auto Global Boss \n- Add Auto Arise\nV1.1: \n- Add fast atack speed \n- Fix Auto farm \n -Fix auto Farm game modes \nV1.0: \n - Release Script" ,
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
        GameMode:UpdateAutoFarmParams(selectedEnemies, selectedPriority)  -- ← solo actualiza enemies/priority
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
        GameMode:UpdateAutoFarmParams(selectedEnemies, selectedPriority)
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
        GameMode:UpdateAutoFarmParams(selectedEnemies, selectedPriority)
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
	Opened = true,
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
	SearchBarEnabled = true,		
    Values   = labels,
	AllowNone = true,
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
 
-------------------------------------Auto Arise------------------------------------

local AriseSection = AutoRename:Section({ 
    Title = "Auto Arise",
    TextXAlignment = "Center",
})
AutoRename:Divider()

-- ─── Conversión letra → número ────────────────────────────────────────────
local rankToNumber = {
    ["E"] = 1,
    ["D"] = 2,
    ["C"] = 3,
    ["B"] = 4,
    ["A"] = 5,
    ["S"] = 6,
}

-- ─── Estado ───────────────────────────────────────────────────────────────
local ariseState = {
    unitQueue   = {},
    unitIndex   = 1,
    unitId      = "",
    targetRank  = nil,
    running     = false,
}
local ariseSoloEquipadas = false

-- ─── Helpers ──────────────────────────────────────────────────────────────
local function getAriseTokens()
    local pd = getPlayerData()
    if not pd or not pd.Data then return 0 end
    local tokens = pd.Data.Inventory.Items["Arise Token"]
    if not tokens then return 0 end
    return math.floor(tokens)
end

local function getUnitRank(unitId)
    local pd = getPlayerData()
    if not pd or not pd.Data then return nil end
    local unit = pd.Data.Inventory.Units[unitId]
    if not unit then return nil end
    return unit.Rank or 0
end

local function getTokensNeeded(currentRank)
    local ranksPrices = {10, 20, 35, 50, 75, 150}
    return ranksPrices[currentRank] or 10
end

local function sendArise(unitId)
    local args = {
        {
            {
                "General",
                "Units",
                "Arise",
                unitId,
                n = 4
            },
            "\002"
        }
    }
    game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet"):WaitForChild("dataRemoteEvent"):FireServer(unpack(args))
end

-- ─── UI ───────────────────────────────────────────────────────────────────
local ariseLabels, ariseLabelToId = getUnitList(false)

local AriseDropdown = AutoRename:Dropdown({
    Title    = "Select Unit",
    Desc     = "Select units to arise",
    Icon     = "layers",
    Multi    = true,
    Values   = ariseLabels,
	SearchBarEnabled = true,
    AllowNone = true,
    Callback = function(selected)
        ariseState.unitQueue = {}
        for _, label in ipairs(selected) do
            local id = ariseLabelToId[label]
            if id then
                table.insert(ariseState.unitQueue, id)
            end
        end
        -- Mostrar rank actual de la primera unidad
        if #ariseState.unitQueue > 0 then
            local firstId = ariseState.unitQueue[1]
            local rank = getUnitRank(firstId)
            local rankNames = {"E", "D", "C", "B", "A", "S"}
            WindUI:Notify({
                Title   = "Unit selected",
                Content = "Current Rank: " .. (rankNames[rank] or "None"),
                Icon    = "layers",
                Duration = 3,
            })
        end
    end
})

AutoRename:Button({
    Title    = "Refresh Units",
    Desc     = "First open inventory",
    Icon     = "refresh-cw",
    Callback = function()
        ariseLabels, ariseLabelToId = getUnitList(ariseSoloEquipadas)
        AriseDropdown:Refresh(ariseLabels)

        -- Actualizar seriales en la UI del juego
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
    Title    = "Only units equipped",
    Icon     = "shield",
    Type     = "Checkbox",
    Value    = false,
    Callback = function(active)
        ariseSoloEquipadas = active
        ariseLabels, ariseLabelToId = getUnitList(ariseSoloEquipadas)
        AriseDropdown:Refresh(ariseLabels)
    end
})

AutoRename:Divider()

local AriseTargetDropdown = AutoRename:Dropdown({
    Title    = "Target Rank",
    Desc     = "Select the rank you want to reach",
    Icon     = "target",
    Multi    = false,
    Values   = {"E", "D", "C", "B", "A", "S"},
    Callback = function(selected)
        ariseState.targetRank = rankToNumber[selected]
        WindUI:Notify({
            Title    = "Target set",
            Content  = "Target Rank: " .. selected,
            Icon     = "target",
            Duration = 3,
        })
    end
})

AutoRename:Divider()

-- ─── Loop principal ───────────────────────────────────────────────────────
local function runAriseLoop()
    if #ariseState.unitQueue == 0 then
        WindUI:Notify({
            Title    = "Error",
            Content  = "Select at least one unit.",
            Icon     = "alert-circle",
            Duration = 4,
        })
        ariseState.running = false
        return
    end

    if not ariseState.targetRank then
        WindUI:Notify({
            Title    = "Error",
            Content  = "Select a target rank.",
            Icon     = "alert-circle",
            Duration = 4,
        })
        ariseState.running = false
        return
    end

    ariseState.unitIndex = 1

    while ariseState.running and ariseState.unitIndex <= #ariseState.unitQueue do
        ariseState.unitId = ariseState.unitQueue[ariseState.unitIndex]

        local pd = getPlayerData()
        local unitData = pd and pd.Data and pd.Data.Inventory.Units[ariseState.unitId]
        local unitLabel = unitData and (unitData.Name .. " #" .. tostring(unitData.SerialNumber)) or ariseState.unitId
        local rankNames = {"E", "D", "C", "B", "A", "S"}

        WindUI:Notify({
            Title   = "Processing unit " .. ariseState.unitIndex .. "/" .. #ariseState.unitQueue,
            Content = unitLabel,
            Icon    = "layers",
            Duration = 4,
        })

        -- Loop de arise para la unidad actual
        while ariseState.running do
            local currentRank = getUnitRank(ariseState.unitId)

            -- ¿Ya alcanzó el target?
            if currentRank >= ariseState.targetRank then
                WindUI:Notify({
                    Title   = "Target reached! " .. ariseState.unitIndex .. "/" .. #ariseState.unitQueue,
                    Content = unitLabel .. " → Rank " .. (rankNames[currentRank] or "?"),
                    Icon    = "check-circle",
                    Duration = 8,
                })
                ariseState.unitIndex = ariseState.unitIndex + 1
                break
            end

            -- Verificar tokens
            local tokensNeeded = getTokensNeeded(currentRank)
            local tokensAvailable = getAriseTokens()

            if tokensAvailable < tokensNeeded then
                WindUI:Notify({
                    Title   = "Waiting for tokens",
                    Content = "Arise Tokens: " .. tokensAvailable .. "/" .. tokensNeeded,
                    Icon    = "clock",
                    Duration = 5,
                })
                while ariseState.running and getAriseTokens() < tokensNeeded do
                    task.wait(5)
                end
                if not ariseState.running then break end
                WindUI:Notify({
                    Title   = "Tokens available!",
                    Content = "Arise Tokens: " .. getAriseTokens(),
                    Icon    = "check-circle",
                    Duration = 4,
                })
            end

            -- Enviar arise
            sendArise(ariseState.unitId)
            task.wait(1.2)

            -- Notificar rank actual
            local newRank = getUnitRank(ariseState.unitId)
            WindUI:Notify({
                Title   = "Arise → " .. unitLabel,
                Content = "Rank: " .. (rankNames[newRank] or "?"),
                Icon    = "refresh-cw",
                Duration = 3,
            })
        end
    end

    -- Terminó todas las unidades
    if ariseState.unitIndex > #ariseState.unitQueue then
        WindUI:Notify({
            Title   = "All units done!",
            Content = "All " .. #ariseState.unitQueue .. " units have been arised.",
            Icon    = "check-circle",
            Duration = 8,
        })
    end

    ariseState.running = false
end

-- ─── Toggle activar ───────────────────────────────────────────────────────
AutoRename:Toggle({
    Title    = "Activate",
    Icon     = "check",
    Type     = "Checkbox",
    Value    = false,
    Callback = function(active)
        ariseState.running = active
        if active then
            task.spawn(runAriseLoop)
        end
    end
})	
	
	
--------------------------------Auto Sell-----------------------------------------------
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
print("[BOSS-DBG] Cargando módulo GlobalBosses...")
local GlobalBosses = require(game:GetService("ReplicatedStorage").Omni.Shared.GlobalBosses)
print("[BOSS-DBG] GlobalBosses cargado")
local templates = workspace:WaitForChild("Server")
    :WaitForChild("Enemies")
    :WaitForChild("Templates")
    :WaitForChild("Global Bosses")
print("[BOSS-DBG] Templates folder encontrado: " .. tostring(templates))

local ListBoss = {}
local InfoBoss = {}
local BossesElegidos = {}

for nombre, info in pairs(GlobalBosses.List) do
    table.insert(ListBoss, nombre)
    InfoBoss[nombre] = {
        MapName   = info.MapName,
        ZoneIndex = info.ZoneIndex
    }
    print("[BOSS-DBG] Boss registrado: " .. nombre .. " → " .. info.MapName .. " zona " .. tostring(info.ZoneIndex))
end
print("[BOSS-DBG] Total bosses: " .. #ListBoss)

-- ─── Funciones de tiempo ──────────────────────────────────────────────────
local function textoASegundos(texto)
    if texto == "0s" then return 0 end
    local lower = texto:lower()
    local minutos  = tonumber(lower:match("(%d+)m")) or 0
    local segundos = tonumber(lower:match("(%d+)s")) or 0
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

-- CFrames of each boss
local BossCFrames = {
    ["Sakana"] = CFrame.new(10572.9756, 659.354675, -5189.31104, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    ["Satoro"] = CFrame.new(10810.6367, 659.341309, -5019.60352, 0.682592869, 0, 0.73079896, 0, 1, 0, -0.73079896, 0, 0.682592869),
    ["Yuje"]   = CFrame.new(10873.502, 773.154114, -5159.50684, -1.1920929e-07, 0, 1.00000012, 0, 1, 0, -1.00000012, 0, -1.1920929e-07),
}

local LocalPlayer = game:GetService("Players").LocalPlayer

-- ─── Sistema de countdown local (sin UI) ──────────────────────────────────
local bossTimers = {} -- {bossName = {deadline = tick() + seconds, alive = bool}}

local function readBossTimer(bossName)
    local bf = templates:FindFirstChild(bossName)
    if not bf then return nil end
    local hud = bf:FindFirstChild("HUD")
    local t = hud and hud:FindFirstChild("Time")
    if not t then return nil end
    return t.Text
end

local function loadTemplatesRemote(bossName)
    local cf = BossCFrames[bossName]
    if not cf then return end
    local pos = cf.Position
    pcall(function()
        LocalPlayer:RequestStreamAroundAsync(pos)
    end)
    task.wait(1.5)
end

local function isOnBossMap(bossName)
    local info = InfoBoss[bossName]
    if not info then return false end
    return Omni.Data.Map == info.MapName and tostring(Omni.Data.Zone) == tostring(info.ZoneIndex)
end

local function initBossTimers(bossNames)
    bossTimers = {}
    for _, bossName in ipairs(bossNames) do
        -- Si no está en el mapa, usar RequestStreamAroundAsync
        if not isOnBossMap(bossName) then
            print("[BOSS] Loading template remote: " .. bossName)
            loadTemplatesRemote(bossName)
        end
        local timerText = readBossTimer(bossName)
        if timerText then
            local secs = textoASegundos(timerText)
            if secs <= 0 then
                bossTimers[bossName] = { deadline = 0, alive = true }
                print("[BOSS] " .. bossName .. " → ALIVE")
            else
                bossTimers[bossName] = { deadline = tick() + secs, alive = false }
                print("[BOSS] " .. bossName .. " → DEAD (" .. secs .. "s)")
            end
        else
            print("[BOSS] " .. bossName .. " template not found")
        end
    end
end

local function getAliveBossesFromTimers()
    local alive = {}
    local now = tick()
    for bossName, data in pairs(bossTimers) do
        if data.alive then
            table.insert(alive, bossName)
        elseif data.deadline > 0 and now >= data.deadline then
            -- Timer expired, confirm with RequestStreamAroundAsync
            if not isOnBossMap(bossName) then
                loadTemplatesRemote(bossName)
            end
            local timerText = readBossTimer(bossName)
            if timerText and timerText == "0s" then
                data.alive = true
                print("[BOSS] " .. bossName .. " timer reached 0 → CONFIRMED ALIVE")
                table.insert(alive, bossName)
            elseif timerText then
                local newSecs = textoASegundos(timerText)
                data.deadline = tick() + newSecs
                data.alive = false
                print("[BOSS] " .. bossName .. " still dead, new timer: " .. newSecs .. "s")
            end
        end
    end
    return alive
end

local function updateBossTimerAfterKill(bossName)
    -- Already on boss map, read directly
    local timerText = readBossTimer(bossName)
    if timerText then
        local secs = textoASegundos(timerText)
        bossTimers[bossName] = { deadline = tick() + secs, alive = false }
        print("[BOSS] " .. bossName .. " killed, new timer: " .. secs .. "s")
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
        print("[BOSS-DBG] Dropdown changed. BossesElegidos type: " .. type(BossesElegidos))
        for k, v in pairs(BossesElegidos) do
            print("[BOSS-DBG]   key=" .. tostring(k) .. " val=" .. tostring(v))
        end
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

-- ─── Toggles ──────────────────────────────────────────────────────────────
local bossAutoFarmActive = false

local FarmBoss = Main:Toggle({
    Title    = "Auto Farm Global Bosses",
    Icon     = "skull",
    Type     = "Checkbox",
    Value    = false,
    Callback = function(state)
        bossAutoFarmActive = state
        if state then
            local bossNames = {}
            for k, v in pairs(BossesElegidos) do
                if type(k) == "number" then
                    table.insert(bossNames, v)
                elseif type(k) == "string" and v then
                    table.insert(bossNames, k)
                end
            end

            if #bossNames == 0 then
                print("[BOSS] No bosses selected")
                bossAutoFarmActive = false
                return
            end

            print("[BOSS] Toggle ON - Bosses: " .. table.concat(bossNames, ", "))

            -- ═══ INIT: Load timers (RequestStreamAroundAsync if needed) ═══
            initBossTimers(bossNames)
            if not bossAutoFarmActive then return end

            -- ═══ FUNCIÓN: ejecutar ciclo de farm (llamada por scheduler) ═══
            local function ejecutarCicloBoss(shouldContinueFn)
                local aliveBosses = getAliveBossesFromTimers()
                if #aliveBosses == 0 then return end

                print("[BOSS] Farm cycle: " .. table.concat(aliveBosses, ", "))

                local returnMap  = Omni.Data.Map
                local returnZone = Omni.Data.Zone
                local char = LocalPlayer.Character
                local returnCFrame = char and char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart.CFrame

                for _, bossName in ipairs(aliveBosses) do
                    if not shouldContinueFn() then
                        print("[BOSS] Interrupted by Trial")
                        break
                    end

                    local info = InfoBoss[bossName]
                    if info and (Omni.Data.Map ~= info.MapName or tostring(Omni.Data.Zone) ~= tostring(info.ZoneIndex)) then
                        print("[BOSS] TP to map: " .. info.MapName)
                        fireTeleport(info.MapName, info.ZoneIndex)
                        task.wait(3)
                    end
                    if not shouldContinueFn() then break end

                    task.wait(1.5)
                    Functions:SetFloating(true)
                    if BossCFrames[bossName] then
                        local hrp = workspace:FindFirstChild(LocalPlayer.Name)
                            and workspace[LocalPlayer.Name]:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            print("[BOSS] Moving to " .. bossName)
                            hrp.CFrame = BossCFrames[bossName] + Vector3.new(0, 10, 0)
                        end
                    end
                    task.wait(1)

                    -- Verify alive (now on map, read directly)
                    local timerText = readBossTimer(bossName)
                    local isAlive = timerText and timerText == "0s"
                    print("[BOSS] " .. bossName .. " check: '" .. tostring(timerText) .. "' → " .. (isAlive and "ALIVE" or "DEAD"))

                    if isAlive then
                        print("[BOSS] " .. bossName .. " ALIVE → waiting for kill...")
                        while shouldContinueFn() do
                            local txt = readBossTimer(bossName)
                            if txt and txt ~= "0s" then
                                print("[BOSS] " .. bossName .. " killed! New timer: '" .. txt .. "'")
                                break
                            end
                            task.wait(0.5)
                        end
                        task.wait(1)
                        updateBossTimerAfterKill(bossName)
                    else
                        print("[BOSS] " .. bossName .. " already dead, updating timer...")
                        updateBossTimerAfterKill(bossName)
                    end

                    Functions:SetFloating(false)
                end

                -- Return to saved position
                print("[BOSS] Returning to " .. tostring(returnMap) .. " zone " .. tostring(returnZone))
                if returnMap then
                    fireTeleport(returnMap, returnZone)
                    task.wait(3)
                end
                if returnCFrame then
                    local c = LocalPlayer.Character
                    if c and c:FindFirstChild("HumanoidRootPart") then
                        c.HumanoidRootPart.CFrame = returnCFrame
                    end
                end
                task.wait(1.5)
                print("[BOSS] Farm cycle complete")
            end

            -- ═══ REGISTER IN SCHEDULER ═══
            GameMode:StartBossGlobal(getAliveBossesFromTimers, ejecutarCicloBoss)
        else
            -- Toggle OFF
            GameMode:StopBossGlobal()
            bossTimers = {}
        end
    end
}) 
    -- ─── Instancias PotionSystem por gamemode ─────────────────────────────────
    local trialPots   = Functions:NewPotionSystem()
    local tempestPots = Functions:NewPotionSystem()
    local dragonPots  = Functions:NewPotionSystem()
    local bossesPots  = Functions:NewPotionSystem()
    local SectionGeneral = Loadouts:Section({ Title = "Loadouts",TextXAlignment ="Center" })
    Loadouts:Divider()
    Loadouts:Space() 

    Loadouts:Toggle({
        Title    = "Auto Loadouts",
        Desc     = "Enable Loadouts system",
        Icon     = "check",
        Type     = "Checkbox",
        Value    = false,
        Callback = function(state)
       Functions:SetGlobalPotsEnabled(state)
        end,
    })

    Loadouts:Toggle({
        Title    = "Pause potions on exit",
        Desc     = "ON: pause on exit & resume on entry | OFF: simple mode",
        Icon     = "pause",
        Type     = "Checkbox",
        Value    = false,
        Callback = function(state)
       Functions:SetGlobalPauseMode(state)
        end,
    })

    -- ─── Tab Trial ────────────────────────────────────────────────────────────
    EquipBetter = {"Power","Damage","Drop","Crystals","Luck"}
    ListPotsInGame = {}
    PotsInGameSelect = {}
    local PotInGame = require(game:GetService("ReplicatedStorage").Omni.Shared.Items.Potion)
      for _, v2 in pairs (PotInGame) do
      table.insert(ListPotsInGame, v2.Name)
    end
    local GlobalBosses = Loadouts:Section({ Title = "Global Bosses",TextXAlignment ="Left" })
    
    Loadouts:Dropdown({
        Title            = "Potions",
        Desc             = "Potions to use when entering Global Boss",
        Values           = ListPotsInGame,
        Multi            = true,
        SearchBarEnabled = true,
        AllowNone        = true,
        Callback         = function(option)
       bossesPots:SetSelectedPots(option)
        end,
    })
    Loadouts:Dropdown({
        Title     = "Equip on entry",
        Desc      = "Equip best on Global Boss start",
        Values    = EquipBetter,
        Multi     = true,
        AllowNone = true,
        Callback  = function(option)
       bossesPots:SetEquipOnStart(option)
        end,
    })
    Loadouts:Dropdown({
        Title     = "Equip on exit",
        Desc      = "Equip best on Global Boss finish",
        Values    = EquipBetter,
        Multi     = true,
        AllowNone = true,
        Callback  = function(option)
       bossesPots:SetEquipOnFinish(option)
        end,
    })
    Loadouts:Divider() 
    local TrialSection = Loadouts:Section({ Title = "Trial",TextXAlignment ="Left" })
    
    Loadouts:Dropdown({
        Title            = "Potions",
        Desc             = "Potions to use when entering Trial",
        Values           = ListPotsInGame,
        Multi            = true,
        SearchBarEnabled = true,
        AllowNone        = true,
        Callback         = function(option)
       trialPots:SetSelectedPots(option)
        end,
    })
    Loadouts:Dropdown({
        Title     = "Equip on entry",
        Desc      = "Equip best on Trial start",
        Values    = EquipBetter,
        Multi     = true,
        AllowNone = true,
        Callback  = function(option)
       trialPots:SetEquipOnStart(option)
        end,
    })
    Loadouts:Dropdown({
        Title     = "Equip on exit",
        Desc      = "Equip best on Trial finish",
        Values    = EquipBetter,
        Multi     = true,
        AllowNone = true,
        Callback  = function(option)
       trialPots:SetEquipOnFinish(option)
        end,
    })
    Loadouts:Divider() 
    local TempestSection = Loadouts:Section({ Title = "Tempest Invasion",TextXAlignment ="Left" })
    Loadouts:Dropdown({
        Title            = "Potions",
        Desc             = "Potions to use when entering Tempest",
        Values           = ListPotsInGame,
        Multi            = true,
        SearchBarEnabled = true,
        AllowNone        = true,
        Callback         = function(option)
       tempestPots:SetSelectedPots(option)
        end,
    })
    Loadouts:Dropdown({
        Title     = "Equip on entry",
        Desc      = "Equip best on Tempest start",
        Values    = EquipBetter,
        Multi     = true,
        AllowNone = true,
        Callback  = function(option)
       tempestPots:SetEquipOnStart(option)
        end,
    })
    Loadouts:Dropdown({
        Title     = "Equip on exit",
        Desc      = "Equip best on Tempest finish",
        Values    = EquipBetter,
        Multi     = false,
        AllowNone = true,
        Callback  = function(option)
       tempestPots:SetEquipOnFinish(option)
        end,
    })

    Loadouts:Divider()
    local DefenseDragonSection = Loadouts:Section({ Title = "Dragon Defense",TextXAlignment ="Left" }) 
    Loadouts:Dropdown({
        Title            = "Potions",
        Desc             = "Potions to use when entering Dragon",
        Values           = ListPotsInGame,
        Multi            = true,
        SearchBarEnabled = true,
        AllowNone        = true,
        Callback         = function(option)
       dragonPots:SetSelectedPots(option)
        end,
    })
    Loadouts:Dropdown({
        Title     = "Equip on entry",
        Desc      = "Equip best on Dragon start",
        Values    = EquipBetter,
        Multi     = true,
        AllowNone = true,
        Callback  = function(option)
            dragonPots:SetEquipOnStart(option)
        end,
    })
    Loadouts:Dropdown({
        Title     = "Equip on exit",
        Desc      = "Equip best on Dragon finish",
        Values    = EquipBetter,
        Multi     = true,
        AllowNone = true,
        Callback  = function(option)
       dragonPots:SetEquipOnFinish(option)
        end,
    })
    GameMode:Init(Functions, nil, nil, {
        trial   = trialPots,
        tempest = tempestPots,
        dragon  = dragonPots,
        globalBosses= bossesPots
    })
-- ─── Auto Ores ────────────────────────────────────────────────────────────
local OresData = require(game:GetService("ReplicatedStorage").Omni.Shared.Ores)
local oresFolder = workspace:WaitForChild("Server"):WaitForChild("Enemies"):WaitForChild("Ores")
local ListOres = {}
local OresInfo = {} -- {oreName = {MapName, ZoneIndex}}
local SelectedOres = {}

for oreName, info in pairs(OresData.List or OresData) do
    if type(info) == "table" and info.MapName then
        if not table.find(ListOres, oreName) then
            table.insert(ListOres, oreName)
        end
        OresInfo[oreName] = {
            MapName   = info.MapName,
            ZoneIndex = info.ZoneIndex,
        }
    end
end
table.sort(ListOres)

local OreSection = Main:Section({ 
    Title = "Auto Ores",
})
Main:Divider()

Main:Dropdown({
    Title     = "Select Ores",
    Values    = ListOres,
    Multi     = true,
    AllowNone = true,
    Callback  = function(option)
        SelectedOres = option or {}
    end,
})

Main:Toggle({
    Title    = "Auto Farm Ores",
    Icon     = "pickaxe",
    Type     = "Checkbox",
    Value    = false,
    Callback = function(state)
        if state then
            -- Build list of selected ore names
            local oreNames = {}
            for k, v in pairs(SelectedOres) do
                if type(k) == "number" then
                    table.insert(oreNames, v)
                elseif type(k) == "string" and v then
                    table.insert(oreNames, k)
                end
            end
            if #oreNames == 0 then
                print("[ORES] No ores selected")
                return
            end
            print("[ORES] Toggle ON - Ores: " .. table.concat(oreNames, ", "))

-- Scan positions per zone for RequestStreamAroundAsync
-- Key = "MapName_ZoneIndex", value = Vector3 position to stream around
local OreScanPositions = {
    ["Leveling Verse_1"] = Vector3.new(1287.05652, 777.705383, 2677.90063, 1, 0, 0, 0, 1, 0, 0, 0, 1), -- TODO: replace with actual ore spawn area position
}

local function getOreScanPos(mapName, zoneIndex)
    local key = mapName .. "_" .. tostring(zoneIndex)
    return OreScanPositions[key]
end

            -- Check function: returns list of alive ore BaseParts matching selected names
            local function getAvailableOres()
                local available = {}
                -- Stream around ore zones if not on that map
                local scannedZones = {}
                for _, oreName in ipairs(oreNames) do
                    local info = OresInfo[oreName]
                    if info then
                        local zoneKey = info.MapName .. "_" .. tostring(info.ZoneIndex)
                        local onMap = Omni.Data.Map == info.MapName and tostring(Omni.Data.Zone) == tostring(info.ZoneIndex)
                        if not onMap and not scannedZones[zoneKey] then
                            scannedZones[zoneKey] = true
                            local scanPos = getOreScanPos(info.MapName, info.ZoneIndex)
                            if scanPos then
                                pcall(function()
                                    LocalPlayer:RequestStreamAroundAsync(scanPos)
                                end)
                                task.wait(1.5)
                            end
                        end
                    end
                end
                -- Read ores folder
                for _, child in ipairs(oresFolder:GetChildren()) do
                    for _, oreName in ipairs(oreNames) do
                        if child.Name == oreName then
                            table.insert(available, child)
                        end
                    end
                end
                return available
            end

            -- Farm callback
            local function farmOres(shouldContinueFn)
                local ores = getAvailableOres()
                if #ores == 0 then return end

                print("[ORES] Farm cycle: " .. #ores .. " ores")

                local returnMap  = Omni.Data.Map
                local returnZone = Omni.Data.Zone
                local char = LocalPlayer.Character
                local returnCFrame = char and char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart.CFrame

                for _, ore in ipairs(ores) do
                    if not shouldContinueFn() then
                        print("[ORES] Interrupted")
                        break
                    end
                    if not ore.Parent then continue end -- already dead

                    local oreName = ore.Name
                    local info = OresInfo[oreName]

                    -- TP to ore map if needed
                    if info and (Omni.Data.Map ~= info.MapName or tostring(Omni.Data.Zone) ~= tostring(info.ZoneIndex)) then
                        print("[ORES] TP to map: " .. info.MapName .. " zone " .. tostring(info.ZoneIndex))
                        fireTeleport(info.MapName, info.ZoneIndex)
                        task.wait(3)
                    end
                    if not shouldContinueFn() then break end

                    -- Move to ore
                    task.wait(1)
                    Functions:SetFloating(true)
                    local hrp = workspace:FindFirstChild(LocalPlayer.Name)
                        and workspace[LocalPlayer.Name]:FindFirstChild("HumanoidRootPart")
                    if hrp and ore.Parent then
                        print("[ORES] Moving to " .. oreName)
                        hrp.CFrame = ore.CFrame + Vector3.new(0, 5, 0)
                    end
                    task.wait(0.5)

                    -- Wait for ore to die (disappear from folder)
                    print("[ORES] " .. oreName .. " → waiting for death...")
                    while shouldContinueFn() and ore.Parent ~= nil do
                        task.wait(0.5)
                    end
                    if ore.Parent == nil then
                        print("[ORES] " .. oreName .. " killed!")
                    end

                    Functions:SetFloating(false)
                end

                -- Return
                print("[ORES] Returning to " .. tostring(returnMap) .. " zone " .. tostring(returnZone))
                if returnMap then
                    fireTeleport(returnMap, returnZone)
                    task.wait(3)
                end
                if returnCFrame then
                    local c = LocalPlayer.Character
                    if c and c:FindFirstChild("HumanoidRootPart") then
                        c.HumanoidRootPart.CFrame = returnCFrame
                    end
                end
                task.wait(1.5)
                print("[ORES] Farm cycle complete")
            end

            GameMode:StartOres(getAvailableOres, farmOres)
        else
            GameMode:StopOres()
        end
    end,
})

  
end

return UI
