local QBCore = exports['qb-core']:GetCoreObject()
local MySQL = exports['oxmysql']

-- Track server start time for uptime calculation
local serverStartTime = os.time()

-- ==============================================
-- AUTO-DETECTION SYSTEM
-- ==============================================

local DetectedInventory = nil
local DetectedFuel = nil
local DetectedKeys = nil
local DetectedAmbulance = nil

-- Send admin webhook log (defined early so all handlers can safely call it)
local function SendWebhook(title, description, color)
    if not Config.Webhook or Config.Webhook == '' then
        return
    end

    local embed = {
        {
            ['title'] = tostring(title or 'Admin Action'),
            ['description'] = tostring(description or 'No description provided'),
            ['color'] = tonumber(color) or 3447003,
            ['footer'] = {
                ['text'] = (Config.ServerName or 'un-admin') .. ' | un-admin'
            },
            ['timestamp'] = os.date('!%Y-%m-%dT%H:%M:%SZ')
        }
    }

    PerformHttpRequest(Config.Webhook, function(err)
        if err and err ~= 200 and err ~= 204 then
            print('^1[un-admin]^7 Webhook request failed with status: ' .. tostring(err))
        end
    end, 'POST', json.encode({
        username = 'un-admin Logs',
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- Keep compatibility for any global calls
_G.SendWebhook = SendWebhook

-- Build a set of actual started resources by iterating loaded resources.
-- This avoids false positives from fxmanifest `provide` aliases.
local function GetStartedResourceSet()
    local startedSet = {}
    local resourceCount = GetNumResources()

    for i = 0, resourceCount - 1 do
        local resName = GetResourceByFindIndex(i)
        if resName and GetResourceState(resName) == 'started' then
            startedSet[string.lower(resName)] = resName
        end
    end

    return startedSet
end

local function FindStartedResource(candidates, startedSet)
    for _, name in ipairs(candidates) do
        local realName = startedSet[string.lower(name)]
        if realName then
            return realName
        end
    end
    return nil
end

local function IsResourceActuallyRunning(resourceName)
    local startedSet = GetStartedResourceSet()
    if startedSet[string.lower(resourceName)] then
        return true
    end

    local dashed = string.gsub(resourceName, '_', '-')
    if startedSet[string.lower(dashed)] then
        return true
    end

    local underscored = string.gsub(resourceName, '-', '_')
    if startedSet[string.lower(underscored)] then
        return true
    end

    return false
end

-- Detect inventory system on resource start
local function DetectInventorySystem()
    if Config.Inventory.system ~= 'auto' then
        DetectedInventory = Config.Inventory.system
        print('^5[un-admin]^7 Using configured inventory: ^3' .. DetectedInventory .. '^7')
        return DetectedInventory
    end

    local inventories = (Config.Inventory and Config.Inventory.priority) or {
        'codem-inventory',
        'ox_inventory',
        'ak47_qb_inventory',
        'qs-inventory',
        'ps-inventory',
        'tgiann-inventory',
        'origen_inventory',
        'core_inventory',
        'mf-inventory',
        'linden_inventory',
        'qb-inventory',
    }

    local startedSet = GetStartedResourceSet()
    local detected = FindStartedResource(inventories, startedSet)
    if detected then
        DetectedInventory = detected
        print('^5[un-admin]^7 Auto-detected inventory: ^2' .. DetectedInventory .. '^7')
        return DetectedInventory
    end

    -- Final fallback: tolerate dash/underscore mismatch
    for _, inv in ipairs(inventories) do
        if IsResourceActuallyRunning(inv) then
            DetectedInventory = inv
            print('^5[un-admin]^7 Auto-detected inventory (variant match): ^2' .. DetectedInventory .. '^7')
            return DetectedInventory
        end
    end

    DetectedInventory = 'qb-inventory'
    print('^5[un-admin]^7 No inventory detected, using default: ^3' .. DetectedInventory .. '^7')
    return DetectedInventory
end

-- Detect fuel system on resource start
local function DetectFuelSystem()
    if not Config.Fuel.enabled then
        print('^5[un-admin]^7 Fuel system disabled in config')
        return nil
    end

    if Config.Fuel.system ~= 'auto' then
        DetectedFuel = Config.Fuel.system
        print('^5[un-admin]^7 Using configured fuel: ^3' .. DetectedFuel .. '^7')
        return DetectedFuel
    end

    local fuelSystems = (Config.Fuel and Config.Fuel.priority) or {
        'rcore_fuel',
        'Renewed-Fuel',
        'LegacyFuel',
        'ox_fuel',
        'lj-fuel',
        'cdn-fuel',
        'ps-fuel',
        'qb-fuel',
        'okokGasStation',
        'ti_fuel',
        'K4MB1_Fuel',
        't1ger_fuel',
        'myFuel',
        'qs-fuelstations',
        'sadoj-fuel',
        'gacha_fuel',
        'cd_fuel',
    }

    local startedSet = GetStartedResourceSet()
    local detected = FindStartedResource(fuelSystems, startedSet)
    if detected then
        DetectedFuel = detected
        print('^5[un-admin]^7 Auto-detected fuel: ^2' .. DetectedFuel .. '^7')
        return DetectedFuel
    end

    for _, fuel in ipairs(fuelSystems) do
        if IsResourceActuallyRunning(fuel) then
            DetectedFuel = fuel
            print('^5[un-admin]^7 Auto-detected fuel (variant match): ^2' .. DetectedFuel .. '^7')
            return DetectedFuel
        end
    end

    print('^5[un-admin]^7 No fuel system detected')
    return nil
end

-- Detect vehicle key system on resource start
local function DetectKeysSystem()
    if Config.Keys and Config.Keys.system ~= 'auto' then
        DetectedKeys = Config.Keys.system
        print('^5[un-admin]^7 Using configured keys: ^3' .. DetectedKeys .. '^7')
        return DetectedKeys
    end

    local keySystems = (Config.Keys and Config.Keys.priority) or {
        'MrNewbVehicleKeys',
        'qb-vehiclekeys',
        'qbx_vehiclekeys',
        'wasabi_carlock',
        'qs-vehiclekeys',
        'Renewed-Vehiclekeys',
        'ps-vehiclekeys',
        'mk_vehiclekeys',
        't1ger_keys',
        'okokVehicleKeys',
        'ic3d_vehiclekeys',
        'xd_locksystem_v2',
        'xd_locksystem',
        'fivecode_carkeys',
        'cd_vehiclekeys',
    }

    local startedSet = GetStartedResourceSet()
    local detected = FindStartedResource(keySystems, startedSet)
    if detected then
        DetectedKeys = detected
        print('^5[un-admin]^7 Auto-detected keys: ^2' .. DetectedKeys .. '^7')
        return DetectedKeys
    end

    for _, keys in ipairs(keySystems) do
        if IsResourceActuallyRunning(keys) then
            DetectedKeys = keys
            print('^5[un-admin]^7 Auto-detected keys (variant match): ^2' .. DetectedKeys .. '^7')
            return DetectedKeys
        end
    end

    print('^5[un-admin]^7 No vehicle key system detected')
    return nil
end

-- Detect ambulance/death system on resource start
local function DetectAmbulanceSystem()
    local configuredSystem = (Config.Ambulance and Config.Ambulance.system) or 'auto'

    if configuredSystem == 'none' then
        DetectedAmbulance = nil
        print('^5[un-admin]^7 Ambulance auto-integration disabled (Config.Ambulance.system = none)')
        return nil
    end

    if configuredSystem ~= 'auto' then
        DetectedAmbulance = configuredSystem
        print('^5[un-admin]^7 Using configured ambulance system: ^3' .. DetectedAmbulance .. '^7')
        return DetectedAmbulance
    end

    local ambulanceSystems = (Config.Ambulance and Config.Ambulance.priority) or {
        'wasabi_ambulance',
        'qb-ambulancejob',
        'ars_ambulancejob',
        'ak47_ambulancejob',
        'rcore_ambulance',
    }

    local startedSet = GetStartedResourceSet()
    local detected = FindStartedResource(ambulanceSystems, startedSet)
    if detected then
        DetectedAmbulance = detected
        print('^5[un-admin]^7 Auto-detected ambulance system: ^2' .. DetectedAmbulance .. '^7')
        return DetectedAmbulance
    end

    for _, ambulance in ipairs(ambulanceSystems) do
        if IsResourceActuallyRunning(ambulance) then
            DetectedAmbulance = ambulance
            print('^5[un-admin]^7 Auto-detected ambulance system (variant match): ^2' .. DetectedAmbulance .. '^7')
            return DetectedAmbulance
        end
    end

    print('^5[un-admin]^7 No ambulance system detected, using un-admin fallback revive')
    return nil
end

local function TriggerReviveEvents(targetId, eventList)
    for _, eventData in ipairs(eventList) do
        local args = eventData.args or {}
        TriggerClientEvent(eventData.name, targetId, table.unpack(args))
    end
end

local function RevivePlayerUniversal(targetId)
    local Player = QBCore.Functions.GetPlayer(targetId)
    if not Player then
        return false
    end

    local reviveEventMap = {
        ['qb-ambulancejob'] = {
            { name = 'hospital:client:Revive' },
            { name = 'hospital:client:HealInjuries', args = { 'full' } },
        },
        ['wasabi_ambulance'] = {
            { name = 'wasabi_ambulance:revive' },
            { name = 'wasabi_ambulance:client:revive' },
            { name = 'wasabi_ambulance:client:Revive' },
            { name = 'wasabi_ambulance:client:RevivePlayer' },
        },
        ['ars_ambulancejob'] = {
            { name = 'ars_ambulancejob:revive' },
            { name = 'ars_ambulancejob:client:revive' },
        },
        ['ak47_ambulancejob'] = {
            { name = 'ak47_ambulancejob:revive' },
            { name = 'ak47_ambulancejob:client:revive' },
        },
        ['rcore_ambulance'] = {
            { name = 'rcore_ambulance:client:revive' },
        },
    }

    local usedFrameworkRevive = false
    local eventList = DetectedAmbulance and reviveEventMap[DetectedAmbulance]
    if eventList then
        usedFrameworkRevive = true
        TriggerReviveEvents(targetId, eventList)
    end

    Player.Functions.SetMetaData('isdead', false)
    Player.Functions.SetMetaData('inlaststand', false)

    local runFallback = false
    if not usedFrameworkRevive then
        runFallback = true
    elseif DetectedAmbulance ~= 'qb-ambulancejob' then
        -- Non-qb ambulance resources vary a lot; keep fallback enabled by default.
        runFallback = true
    end

    if Config.Ambulance and Config.Ambulance.forceFallback ~= nil then
        runFallback = Config.Ambulance.forceFallback
    end

    if runFallback then
        TriggerClientEvent('un-admin:client:revivePlayer', targetId)
    end

    return true
end

-- Get items from any inventory system
local function GetItemList()
    if not DetectedInventory then return {} end
    
    local success, items = pcall(function()
        if DetectedInventory == 'codem-inventory' then
            return exports['codem-inventory']:GetItemList()
            
        elseif DetectedInventory == 'qb-inventory' then
            -- QBCore shared items work for qb-inventory
            return QBCore.Shared.Items
            
        elseif DetectedInventory == 'qs-inventory' then
            local itemList = exports['qs-inventory']:GetItemList()
            return itemList or QBCore.Shared.Items
            
        elseif DetectedInventory == 'ps-inventory' then
            -- ps-inventory uses QBCore shared items
            return QBCore.Shared.Items
            
        elseif DetectedInventory == 'ox_inventory' then
            local itemList = exports.ox_inventory:Items()
            local converted = {}
            for itemName, itemData in pairs(itemList) do
                converted[itemName] = {
                    name = itemName,
                    label = itemData.label,
                    weight = itemData.weight,
                    type = itemData.type or 'item',
                    image = itemData.client and itemData.client.image or itemName .. '.png',
                    description = itemData.description or ''
                }
            end
            return converted

        elseif DetectedInventory == 'tgiann-inventory' then
            return exports['tgiann-inventory']:GetItemList() or QBCore.Shared.Items

        elseif DetectedInventory == 'origen_inventory' then
            return exports['origen_inventory']:GetItemList() or QBCore.Shared.Items

        elseif DetectedInventory == 'core_inventory' then
            return exports['core_inventory']:getItemList() or QBCore.Shared.Items

        elseif DetectedInventory == 'mf-inventory' then
            return QBCore.Shared.Items -- MF inventory uses QBCore shared items

        elseif DetectedInventory == 'linden_inventory' then
            return QBCore.Shared.Items -- Linden inventory uses QBCore shared items

        elseif DetectedInventory == 'ak47_qb_inventory' then
            return QBCore.Shared.Items -- ak47_qb_inventory uses QBCore shared items
        end

        -- Fallback to QBCore shared items
        return QBCore.Shared.Items
    end)
    
    if not success then
        print('^1[un-admin Error]^7 Failed to get items from ' .. DetectedInventory)
        return QBCore.Shared.Items or {}
    end
    
    return items or {}
end

-- Set vehicle fuel using detected fuel system
local function SetVehicleFuel(vehicle, amount)
    if not DetectedFuel then return false end
    
    local success = pcall(function()
        if DetectedFuel == 'rcore_fuel' then
            exports['rcore_fuel']:SetFuel(vehicle, amount)
            
        elseif DetectedFuel == 'lj-fuel' then
            exports['lj-fuel']:SetFuel(vehicle, amount)
            
        elseif DetectedFuel == 'cdn-fuel' then
            exports['cdn-fuel']:SetFuel(vehicle, amount)
            
        elseif DetectedFuel == 'ps-fuel' then
            exports['ps-fuel']:SetFuel(vehicle, amount)
            
        elseif DetectedFuel == 'ox_fuel' then
            Entity(vehicle).state.fuel = amount
            
        elseif DetectedFuel == 'qb-fuel' then
            exports['qb-fuel']:SetFuel(vehicle, amount)

        elseif DetectedFuel == 'LegacyFuel' then
            exports['LegacyFuel']:SetFuel(vehicle, amount)

        elseif DetectedFuel == 'Renewed-Fuel' then
            exports['Renewed-Fuel']:SetFuel(vehicle, amount)

        elseif DetectedFuel == 'okokGasStation' then
            exports['okokGasStation']:SetFuel(vehicle, amount)

        elseif DetectedFuel == 'ti_fuel' then
            exports['ti_fuel']:SetFuel(vehicle, amount)

        elseif DetectedFuel == 'K4MB1_Fuel' then
            exports['K4MB1_Fuel']:SetFuel(vehicle, amount)

        elseif DetectedFuel == 't1ger_fuel' then
            exports['t1ger_fuel']:SetFuel(vehicle, amount)

        elseif DetectedFuel == 'myFuel' then
            exports['myFuel']:setFuel(vehicle, amount)

        elseif DetectedFuel == 'qs-fuelstations' then
            exports['qs-fuelstations']:SetFuel(vehicle, amount)

        elseif DetectedFuel == 'sadoj-fuel' then
            exports['sadoj-fuel']:SetFuel(vehicle, amount)

        elseif DetectedFuel == 'gacha_fuel' then
            exports['gacha_fuel']:SetFuel(vehicle, amount)

        elseif DetectedFuel == 'cd_fuel' then
            exports['cd_fuel']:SetFuel(vehicle, amount)
        end
    end)

    return success
end

-- Give vehicle keys to player using detected key system (server-side)
local function GiveKeysToPlayer(src, plate)
    if not DetectedKeys or not plate then return end

    plate = string.upper(string.gsub(plate, '^%s*(.-)%s*$', '%1'))

    pcall(function()
        if DetectedKeys == 'qb-vehiclekeys' then
            TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)

        elseif DetectedKeys == 'qbx_vehiclekeys' then
            exports.qbx_vehiclekeys:GiveKeys(src, plate)

        elseif DetectedKeys == 'wasabi_carlock' then
            exports['wasabi_carlock']:GiveKeys(src, plate)

        elseif DetectedKeys == 'qs-vehiclekeys' then
            exports['qs-vehiclekeys']:GiveKeys(src, plate)

        elseif DetectedKeys == 'Renewed-Vehiclekeys' then
            exports['Renewed-Vehiclekeys']:GiveKeys(src, plate)

        elseif DetectedKeys == 'ps-vehiclekeys' then
            TriggerClientEvent('ps-vehiclekeys:client:GiveKeys', src, plate)

        elseif DetectedKeys == 'mk_vehiclekeys' then
            exports['mk_vehiclekeys']:GiveKeys(src, plate)

        elseif DetectedKeys == 't1ger_keys' then
            exports['t1ger_keys']:giveKeys(src, plate)

        elseif DetectedKeys == 'okokVehicleKeys' then
            exports['okokVehicleKeys']:GiveVehicleKey(src, plate)

        else
            -- Client-side key systems (MrNewbVehicleKeys, ic3d, xd_locksystem, etc.)
            TriggerClientEvent('un-admin:client:giveVehicleKeys', src, plate)
        end
    end)
end

-- Initialize detection on resource start
CreateThread(function()
    Wait(1000) -- Wait for other resources to load
    DetectInventorySystem()
    DetectFuelSystem()
    DetectKeysSystem()
    DetectAmbulanceSystem()
end)

-- Send inventory config to client
RegisterNetEvent('un-admin:server:requestInventoryConfig', function()
    local src = source
    TriggerClientEvent('un-admin:client:receiveInventoryConfig', src, {
        inventory = DetectedInventory,
        imagePath = Config.Inventory.imagePaths[DetectedInventory] or 'nui://qb-inventory/html/images/%s',
        fuel = DetectedFuel,
        keys = DetectedKeys,
        ambulance = DetectedAmbulance,
        uiTheme = Config.UITheme or 'purple',
        themeColors = Config.ThemeColors[Config.UITheme or 'purple'],
        serverName = Config.ServerName or 'Your Server'
    })
end)

-- ==============================================
-- END AUTO-DETECTION SYSTEM
-- ==============================================

-- ==============================================
-- REPORT SYSTEM
-- ==============================================

local ActiveReports = {}
local ReportIdCounter = 1
local PlayerReportCooldowns = {}

-- Send Discord webhook for report
local function SendReportWebhook(report)
    if not Config.ReportSystem.webhook or Config.ReportSystem.webhook == '' then
        return
    end
    
    local embed = {
        {
            ['title'] = '📋 New Player Report #' .. report.id,
            ['color'] = Config.ReportSystem.embedColor,
            ['fields'] = {
                {['name'] = 'Reporter', ['value'] = report.playerName .. ' (' .. report.playerSteam .. ')', ['inline'] = true},
                {['name'] = 'Server ID', ['value'] = tostring(report.playerId), ['inline'] = true},
                {['name'] = 'Report Time', ['value'] = os.date('%Y-%m-%d %H:%M:%S', report.timestamp), ['inline'] = false},
                {['name'] = 'Report Message', ['value'] = '```' .. report.message .. '```', ['inline'] = false},
                {['name'] = 'Status', ['value'] = report.status, ['inline'] = true},
            },
            ['footer'] = {
                ['text'] = 'un-admin Report System'
            },
            ['timestamp'] = os.date('!%Y-%m-%dT%H:%M:%SZ', report.timestamp)
        }
    }
    
    PerformHttpRequest(Config.ReportSystem.webhook, function(err, text, headers) end, 'POST', json.encode({
        username = 'un-admin Reports',
        embeds = embed
    }), {['Content-Type'] = 'application/json'})
end

-- Get active reports
local function GetActiveReports()
    local reports = {}
    for id, report in pairs(ActiveReports) do
        if report.status == 'open' then
            table.insert(reports, report)
        end
    end
    
    -- Sort by timestamp (newest first)
    table.sort(reports, function(a, b) return a.timestamp > b.timestamp end)
    
    return reports
end

-- Submit a new report
RegisterNetEvent('un-admin:server:submitReport', function(message)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    if not Config.ReportSystem.enabled then
        TriggerClientEvent('QBCore:Notify', src, 'Report system is currently disabled', 'error')
        return
    end
    
    -- Check cooldown
    local identifier = Player.PlayerData.license
    if PlayerReportCooldowns[identifier] and (os.time() - PlayerReportCooldowns[identifier]) < Config.ReportSystem.cooldown then
        local remaining = Config.ReportSystem.cooldown - (os.time() - PlayerReportCooldowns[identifier])
        TriggerClientEvent('QBCore:Notify', src, 'Please wait ' .. remaining .. ' seconds before submitting another report', 'error')
        return
    end
    
    -- Validate message
    if not message or message == '' then
        TriggerClientEvent('QBCore:Notify', src, 'Report message cannot be empty', 'error')
        return
    end
    
    if #message < Config.ReportSystem.minReportLength then
        TriggerClientEvent('QBCore:Notify', src, 'Report must be at least ' .. Config.ReportSystem.minReportLength .. ' characters', 'error')
        return
    end
    
    if #message > Config.ReportSystem.maxReportLength then
        TriggerClientEvent('QBCore:Notify', src, 'Report cannot exceed ' .. Config.ReportSystem.maxReportLength .. ' characters', 'error')
        return
    end
    
    -- Create report
    local report = {
        id = ReportIdCounter,
        playerId = src,
        playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        playerSteam = Player.PlayerData.steam or 'Unknown',
        playerLicense = Player.PlayerData.license or 'Unknown',
        message = message,
        timestamp = os.time(),
        status = 'open',
        resolvedBy = nil,
        resolvedAt = nil
    }
    
    ActiveReports[ReportIdCounter] = report
    ReportIdCounter = ReportIdCounter + 1
    
    -- Set cooldown
    PlayerReportCooldowns[identifier] = os.time()
    
    -- Send to Discord
    SendReportWebhook(report)
    
    -- Notify admins
    if Config.ReportSystem.notifyAdmins then
        for _, playerId in ipairs(GetPlayers()) do
            local targetId = tonumber(playerId)
            if QBCore.Functions.HasPermission(targetId, 'admin') or QBCore.Functions.HasPermission(targetId, 'god') then
                TriggerClientEvent('QBCore:Notify', targetId, '📋 New report received from ' .. report.playerName .. ' (#' .. report.id .. ')', 'primary')
                TriggerClientEvent('un-admin:client:updateReportCount', targetId, #GetActiveReports())
            end
        end
    end
    
    TriggerClientEvent('QBCore:Notify', src, 'Your report has been submitted successfully (#' .. report.id .. ')', 'success')
    
    print(string.format('^5[un-admin]^7 Report #%d submitted by %s: %s', report.id, report.playerName, message))
end)

-- Get all reports (including resolved)
QBCore.Functions.CreateCallback('un-admin:server:getReports', function(source, cb)
    local reports = {}
    
    for id, report in pairs(ActiveReports) do
        table.insert(reports, report)
    end
    
    -- Sort by timestamp (newest first)
    table.sort(reports, function(a, b) return a.timestamp > b.timestamp end)
    
    cb(reports)
end)

-- Resolve a report
RegisterNetEvent('un-admin:server:resolveReport', function(reportId)
    local src = source
    reportId = tonumber(reportId)

    if not reportId then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid report ID', 'error')
        return
    end
    
    if not HasPermission(src, 'reports') then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to resolve reports', 'error')
        return
    end
    
    local report = ActiveReports[reportId]
    if not report then
        TriggerClientEvent('QBCore:Notify', src, 'Report not found', 'error')
        return
    end
    
    if report.status == 'resolved' then
        TriggerClientEvent('QBCore:Notify', src, 'This report is already resolved', 'error')
        return
    end
    
    local Admin = QBCore.Functions.GetPlayer(src)
    if not Admin then
        TriggerClientEvent('QBCore:Notify', src, 'Unable to resolve report right now', 'error')
        return
    end

    report.status = 'resolved'
    report.resolvedBy = Admin.PlayerData.charinfo.firstname .. ' ' .. Admin.PlayerData.charinfo.lastname
    report.resolvedAt = os.time()
    
    TriggerClientEvent('QBCore:Notify', src, 'Report #' .. reportId .. ' has been resolved', 'success')
    
    -- Notify the reporter if they're online
    if GetPlayerPing(report.playerId) > 0 then
        TriggerClientEvent('QBCore:Notify', report.playerId, 'Your report (#' .. reportId .. ') has been reviewed by an administrator', 'success')
    end
    
    -- Update all admins
    for _, playerId in ipairs(GetPlayers()) do
        local targetId = tonumber(playerId)
        if QBCore.Functions.HasPermission(targetId, 'admin') or QBCore.Functions.HasPermission(targetId, 'god') then
            TriggerClientEvent('un-admin:client:updateReportCount', targetId, #GetActiveReports())
        end
    end
    
    LogAction(src, string.format('Resolved report #%s from %s', reportId, report.playerName))
    print(string.format('^5[un-admin]^7 Report #%s resolved by %s', reportId, report.resolvedBy))
end)

-- Get report count for badge
QBCore.Functions.CreateCallback('un-admin:server:getReportCount', function(source, cb)
    cb(#GetActiveReports())
end)

-- ==============================================
-- END REPORT SYSTEM
-- ==============================================

-- Get server uptime callback
QBCore.Functions.CreateCallback('un-admin:server:getUptime', function(source, cb)
    local currentTime = os.time()
    local uptimeSeconds = currentTime - serverStartTime
    
    local hours = math.floor(uptimeSeconds / 3600)
    local minutes = math.floor((uptimeSeconds % 3600) / 60)
    local seconds = uptimeSeconds % 60
    
    local uptimeString = string.format('%02d:%02d:%02d', hours, minutes, seconds)
    cb(uptimeString)
end)

-- Check permission callback
QBCore.Functions.CreateCallback('un-admin:server:checkPermission', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        cb(false, nil, nil)
        return
    end
    
    local permission = nil
    local hasPermission = false
    
    -- Check permissions in order of hierarchy using QBCore's permission system
    if QBCore.Functions.HasPermission(src, 'god') then
        permission = 'god'
        hasPermission = true
    elseif QBCore.Functions.HasPermission(src, 'admin') then
        permission = 'admin'
        hasPermission = true
    elseif QBCore.Functions.HasPermission(src, 'mod') then
        permission = 'mod'
        hasPermission = true
    end
    
    local access = hasPermission and Config.FeatureAccess[permission] or nil
    
    cb(hasPermission, permission, access)
end)

-- Get online players
QBCore.Functions.CreateCallback('un-admin:server:getPlayers', function(source, cb)
    local players = {}
    
    for _, playerId in ipairs(GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(tonumber(playerId))
        
        if Player then
            table.insert(players, {
                id = playerId,
                name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                citizenid = Player.PlayerData.citizenid,
                job = Player.PlayerData.job.label,
                cash = Player.PlayerData.money.cash or 0,
                bank = Player.PlayerData.money.bank or 0,
                ping = GetPlayerPing(playerId)
            })
        end
    end
    
    cb(players)
end)

-- Get items from codem-inventory
QBCore.Functions.CreateCallback('un-admin:server:getItems', function(source, cb)
    local itemList = GetItemList()
    local items = {}
    
    for itemName, itemData in pairs(itemList) do
        table.insert(items, {
            name = itemName,
            label = itemData.label,
            weight = itemData.weight,
            image = itemData.image,
            type = itemData.type or 'item',
            description = itemData.description or ''
        })
    end
    
    cb(items)
end)

-- Get jobs from QBCore
QBCore.Functions.CreateCallback('un-admin:server:getJobs', function(source, cb)
    local jobs = {}
    
    for jobName, jobData in pairs(QBCore.Shared.Jobs) do
        local grades = {}
        
        for gradeLevel, gradeData in pairs(jobData.grades) do
            table.insert(grades, {
                level = tonumber(gradeLevel),
                name = gradeData.name,
                payment = gradeData.payment,
                isboss = gradeData.isboss or false
            })
        end
        
        -- Sort grades by level
        table.sort(grades, function(a, b) return a.level < b.level end)
        
        table.insert(jobs, {
            name = jobName,
            label = jobData.label,
            type = jobData.type or 'none',
            grades = grades
        })
    end
    
    -- Sort jobs alphabetically by label
    table.sort(jobs, function(a, b) return a.label < b.label end)
    
    cb(jobs)
end)

-- Give item
RegisterNetEvent('un-admin:server:giveItem', function(item, quantity, target)
    local src = source
    
    if not HasPermission(src, 'items') then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to give items', 'error')
        return
    end
    
    local targetId = target == 'self' and src or tonumber(target)
    local Player = QBCore.Functions.GetPlayer(targetId)
    
    if not Player then
        TriggerClientEvent('QBCore:Notify', src, 'Player not found', 'error')
        return
    end
    
    Player.Functions.AddItem(item, quantity)
    TriggerClientEvent('inventory:client:ItemBox', targetId, QBCore.Shared.Items[item], 'add', quantity)
    
    -- Log action
    local AdminPlayer = QBCore.Functions.GetPlayer(src)
    LogAction(src, string.format('Gave %dx %s to %s', quantity, item, Player.PlayerData.charinfo.firstname))
    SendWebhook('Item Given', string.format('%s gave %dx %s to %s', GetPlayerName(src), quantity, item, Player.PlayerData.charinfo.firstname))
end)

-- Teleport to player
RegisterNetEvent('un-admin:server:teleportToPlayer', function(targetId)
    local src = source
    
    if not HasPermission(src, 'players') then return end
    
    local targetPed = GetPlayerPed(targetId)
    local targetCoords = GetEntityCoords(targetPed)
    
    TriggerClientEvent('un-admin:client:teleportToCoords', src, {
        x = targetCoords.x,
        y = targetCoords.y,
        z = targetCoords.z
    })
    
    LogAction(src, string.format('Teleported to player ID %s', targetId))
end)

-- Bring player
RegisterNetEvent('un-admin:server:bringPlayer', function(targetId)
    local src = source
    
    if not HasPermission(src, 'players') then return end
    
    local adminPed = GetPlayerPed(src)
    local adminCoords = GetEntityCoords(adminPed)
    
    TriggerClientEvent('un-admin:client:teleportToCoords', targetId, {
        x = adminCoords.x,
        y = adminCoords.y,
        z = adminCoords.z
    })
    
    LogAction(src, string.format('Brought player ID %s', targetId))
end)

-- Freeze player
RegisterNetEvent('un-admin:server:freezePlayer', function(targetId)
    local src = source
    
    if not HasPermission(src, 'players') then return end
    
    TriggerClientEvent('un-admin:client:freezePlayer', targetId)
    LogAction(src, string.format('Froze player ID %s', targetId))
end)

-- Revive player
RegisterNetEvent('un-admin:server:revivePlayer', function(targetId)
    local src = source
    
    if not HasPermission(src, 'players') then return end
    
    if RevivePlayerUniversal(targetId) then
        TriggerClientEvent('QBCore:Notify', targetId, 'You have been revived by an admin', 'success')
        LogAction(src, string.format('Revived player ID %s', targetId))
    end
end)

-- Give armor
RegisterNetEvent('un-admin:server:giveArmor', function(targetId)
    local src = source
    
    if not HasPermission(src, 'players') then return end
    
    TriggerClientEvent('un-admin:client:setArmor', targetId, 100)
    LogAction(src, string.format('Gave armor to player ID %s', targetId))
end)

-- Set job
RegisterNetEvent('un-admin:server:setJob', function(targetId, job, grade)
    local src = source
    
    if not HasPermission(src, 'jobs') then return end
    
    local Player = QBCore.Functions.GetPlayer(targetId)
    if Player then
        Player.Functions.SetJob(job, grade)
        TriggerClientEvent('QBCore:Notify', targetId, string.format('Your job was set to %s', job), 'success')
        LogAction(src, string.format('Set player ID %s job to %s grade %s', targetId, job, grade))
    end
end)

-- Give money
RegisterNetEvent('un-admin:server:giveMoney', function(targetId, moneyType, amount)
    local src = source
    
    if not HasPermission(src, 'economy') then return end
    
    targetId = tonumber(targetId)
    amount = tonumber(amount)

    if not targetId or targetId < 1 then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid player ID', 'error')
        return
    end

    if moneyType ~= 'cash' and moneyType ~= 'bank' then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid money type', 'error')
        return
    end

    if not amount or amount < 1 then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid amount', 'error')
        return
    end

    amount = math.floor(amount)

    local Player = QBCore.Functions.GetPlayer(targetId)
    if Player then
        Player.Functions.AddMoney(moneyType, amount)
        TriggerClientEvent('QBCore:Notify', targetId, string.format('You received $%s %s', amount, moneyType), 'success')
        TriggerClientEvent('QBCore:Notify', src, string.format('Gave $%s %s to player ID %s', amount, moneyType, targetId), 'success')
        LogAction(src, string.format('Gave player ID %s $%s %s', targetId, amount, moneyType))
        SendWebhook('Money Given', string.format('%s gave $%s %s to player ID %s', GetPlayerName(src), amount, moneyType, targetId))
    else
        TriggerClientEvent('QBCore:Notify', src, 'Player not found', 'error')
    end
end)

-- Kick player
RegisterNetEvent('un-admin:server:kickPlayer', function(targetId, reason)
    local src = source
    
    if not HasPermission(src, 'players') then return end
    
    DropPlayer(targetId, reason)
    LogAction(src, string.format('Kicked player ID %s - Reason: %s', targetId, reason))
    SendWebhook('Player Kicked', string.format('%s kicked player ID %s - Reason: %s', GetPlayerName(src), targetId, reason))
end)

-- Ban player
RegisterNetEvent('un-admin:server:banPlayer', function(targetId, reason)
    local src = source
    
    if not HasPermission(src, 'players') then return end
    
    local Player = QBCore.Functions.GetPlayer(targetId)
    if Player then
        MySQL:insert('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)', {
            GetPlayerName(targetId),
            Player.PlayerData.license,
            Player.PlayerData.discord or 'N/A',
            Player.PlayerData.ip or 'N/A',
            reason,
            2147483647, -- Permanent
            GetPlayerName(src)
        })
        
        DropPlayer(targetId, 'You have been banned: ' .. reason)
        LogAction(src, string.format('Banned player ID %s - Reason: %s', targetId, reason))
        SendWebhook('Player Banned', string.format('%s banned player ID %s - Reason: %s', GetPlayerName(src), targetId, reason))
    end
end)

-- Kill player
RegisterNetEvent('un-admin:server:killPlayer', function(targetId)
    local src = source
    
    if not HasPermission(src, 'players') then return end
    
    local Player = QBCore.Functions.GetPlayer(targetId)
    if Player then
        TriggerClientEvent('un-admin:client:killPlayer', targetId)
        LogAction(src, string.format('Killed player ID %s', targetId))
    end
end)

-- Strip weapons
RegisterNetEvent('un-admin:server:stripWeapons', function(targetId)
    local src = source
    
    if not HasPermission(src, 'players') then return end
    
    TriggerClientEvent('un-admin:client:stripWeapons', targetId)
    TriggerClientEvent('QBCore:Notify', targetId, 'Your weapons have been removed by an admin', 'error')
    LogAction(src, string.format('Stripped weapons from player ID %s', targetId))
end)

-- TROLL ACTIONS

-- Slap player (ragdoll)
RegisterNetEvent('un-admin:server:slapPlayer', function(targetId)
    local src = source
    
    if not HasPermission(src, 'players') then return end
    
    TriggerClientEvent('un-admin:client:slapPlayer', targetId, Config.TrollSettings.slapForce)
    LogAction(src, string.format('Slapped player ID %s', targetId))
end)

-- Set on fire
RegisterNetEvent('un-admin:server:setOnFire', function(targetId)
    local src = source
    
    if not HasPermission(src, 'players') then return end
    
    TriggerClientEvent('un-admin:client:setOnFire', targetId)
    LogAction(src, string.format('Set player ID %s on fire', targetId))
end)

-- Electrocute
RegisterNetEvent('un-admin:server:electrocute', function(targetId)
    local src = source
    
    if not HasPermission(src, 'players') then return end
    
    TriggerClientEvent('un-admin:client:electrocute', targetId)
    LogAction(src, string.format('Electrocuted player ID %s', targetId))
end)

-- Fling player
RegisterNetEvent('un-admin:server:flingPlayer', function(targetId)
    local src = source
    
    if not HasPermission(src, 'players') then return end
    
    TriggerClientEvent('un-admin:client:flingPlayer', targetId)
    LogAction(src, string.format('Flung player ID %s', targetId))
end)

-- Make drunk
RegisterNetEvent('un-admin:server:makeDrunk', function(targetId)
    local src = source
    
    if not HasPermission(src, 'players') then return end
    
    TriggerClientEvent('un-admin:client:makeDrunk', targetId)
    LogAction(src, string.format('Made player ID %s drunk', targetId))
end)

-- Cage player
RegisterNetEvent('un-admin:server:cagePlayer', function(targetId)
    local src = source
    
    if not HasPermission(src, 'players') then return end
    
    TriggerClientEvent('un-admin:client:cagePlayer', targetId)
    LogAction(src, string.format('Caged player ID %s', targetId))
end)

-- Explode player
RegisterNetEvent('un-admin:server:explodePlayer', function(targetId)
    local src = source
    
    if not HasPermission(src, 'players') then return end
    
    TriggerClientEvent('un-admin:client:explodePlayer', targetId)
    LogAction(src, string.format('Exploded player ID %s', targetId))
end)

-- Send to ocean
RegisterNetEvent('un-admin:server:sendToOcean', function(targetId)
    local src = source
    
    if not HasPermission(src, 'players') then return end
    
    TriggerClientEvent('un-admin:client:teleportToCoords', targetId, {
        x = Config.OceanCoords.x,
        y = Config.OceanCoords.y,
        z = Config.OceanCoords.z
    })
    TriggerClientEvent('QBCore:Notify', targetId, '🌊 You have been sent to the ocean!', 'error')
    LogAction(src, string.format('Sent player ID %s to ocean', targetId))
end)

-- Send to sky
RegisterNetEvent('un-admin:server:sendToSky', function(targetId)
    local src = source
    
    if not HasPermission(src, 'players') then return end
    
    TriggerClientEvent('un-admin:client:sendToSky', targetId)
    TriggerClientEvent('QBCore:Notify', targetId, '☁️ You have been sent to the sky!', 'error')
    LogAction(src, string.format('Sent player ID %s to sky', targetId))
end)

-- Weather control
RegisterNetEvent('un-admin:server:setWeather', function(weather)
    local src = source
    
    if not HasPermission(src, 'server') then return end
    
    exports['night_natural_disasters']:SetWeather(weather)
    TriggerClientEvent('QBCore:Notify', -1, string.format('Weather changed to %s by an admin', weather), 'primary')
    LogAction(src, string.format('Changed weather to %s', weather))
end)

-- Time control
RegisterNetEvent('un-admin:server:setTime', function(hour)
    local src = source
    
    if not HasPermission(src, 'server') then return end
    
    exports['night_natural_disasters']:SetTime(hour, 0)
    LogAction(src, string.format('Changed time to %s:00', hour))
end)

-- Freeze time
RegisterNetEvent('un-admin:server:freezeTime', function()
    local src = source
    
    if not HasPermission(src, 'server') then return end
    
    exports['night_natural_disasters']:ToggleFreezeTime()
    LogAction(src, 'Toggled time freeze')
end)

-- Send announcement
RegisterNetEvent('un-admin:server:sendAnnouncement', function(text)
    local src = source
    
    if not HasPermission(src, 'server') then 
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to send announcements', 'error')
        return 
    end
    
    if not text or text == '' then
        TriggerClientEvent('QBCore:Notify', src, 'Announcement text cannot be empty', 'error')
        return
    end
    
    -- Send to all players via chat
    TriggerClientEvent('chat:addMessage', -1, {
        template = '<div class="chat-message admin"><b>SERVER ANNOUNCEMENT:</b> {0}</div>',
        args = { text }
    })
    
    -- Also send as notification to all players
    TriggerClientEvent('QBCore:Notify', -1, text, 'primary', 8000)
    
    -- Confirm to sender
    TriggerClientEvent('QBCore:Notify', src, 'Announcement sent to all players', 'success')
    
    LogAction(src, string.format('Sent announcement: %s', text))
    
    print(string.format('[un-admin] %s sent announcement: %s', GetPlayerName(src), text))
end)

-- Resource management
-- Get all resources
QBCore.Functions.CreateCallback('un-admin:server:getResources', function(source, cb)
    if not HasPermission(source, 'resources') then 
        cb({})
        return 
    end
    
    local resources = {}
    local numResources = GetNumResources()
    
    for i = 0, numResources - 1 do
        local resName = GetResourceByFindIndex(i)
        if resName and resName ~= '_cfx_internal' then
            local state = GetResourceState(resName)
            table.insert(resources, {
                name = resName,
                state = state,
                author = GetResourceMetadata(resName, 'author', 0) or 'Unknown',
                description = GetResourceMetadata(resName, 'description', 0) or 'No description',
                version = GetResourceMetadata(resName, 'version', 0) or '1.0.0'
            })
        end
    end
    
    cb(resources)
end)

RegisterNetEvent('un-admin:server:startResource', function(resource)
    local src = source
    
    if not HasPermission(src, 'resources') then return end
    
    if GetResourceState(resource) == 'missing' then
        TriggerClientEvent('QBCore:Notify', src, 'Resource not found', 'error')
        return
    end
    
    StartResource(resource)
    TriggerClientEvent('QBCore:Notify', src, string.format('Started resource: %s', resource), 'success')
    TriggerClientEvent('un-admin:client:refreshResources', src)
    LogAction(src, string.format('Started resource: %s', resource))
end)

RegisterNetEvent('un-admin:server:restartResource', function(resource)
    local src = source
    
    if not HasPermission(src, 'resources') then return end
    
    if GetResourceState(resource) == 'missing' then
        TriggerClientEvent('QBCore:Notify', src, 'Resource not found', 'error')
        return
    end
    
    StopResource(resource)
    Wait(100)
    StartResource(resource)
    TriggerClientEvent('QBCore:Notify', src, string.format('Restarted resource: %s', resource), 'success')
    TriggerClientEvent('un-admin:client:refreshResources', src)
    LogAction(src, string.format('Restarted resource: %s', resource))
end)

RegisterNetEvent('un-admin:server:stopResource', function(resource)
    local src = source
    
    if not HasPermission(src, 'resources') then return end
    
    StopResource(resource)
    TriggerClientEvent('QBCore:Notify', src, string.format('Stopped resource: %s', resource), 'success')
    TriggerClientEvent('un-admin:client:refreshResources', src)
    LogAction(src, string.format('Stopped resource: %s', resource))
end)

-- Permission check function
function HasPermission(src, feature)
    local permission = nil
    
    -- Use QBCore's permission system
    if QBCore.Functions.HasPermission(src, 'god') then
        permission = 'god'
    elseif QBCore.Functions.HasPermission(src, 'admin') then
        permission = 'admin'
    elseif QBCore.Functions.HasPermission(src, 'mod') then
        permission = 'mod'
    end
    
    if not permission then return false end
    if not Config.FeatureAccess[permission] then return false end
    
    return Config.FeatureAccess[permission][feature] == true
end

-- Log action
function LogAction(src, action)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local log = {
        admin = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        action = action,
        time = os.date('%Y-%m-%d %H:%M:%S')
    }
    
    TriggerClientEvent('un-admin:client:addLog', src, log)
    
    print(string.format('[ADMIN ACTION] %s - %s', log.admin, action))
end

-- Save location
RegisterNetEvent('un-admin:server:saveLocation', function(name, coords)
    local src = source
    
    if not HasPermission(src, 'developer') then return end
    
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Save to a file or database (simplified here - prints to console)
    local coordString = string.format("vector4(%.2f, %.2f, %.2f, %.2f)", coords.x, coords.y, coords.z, coords.h)
    print(string.format('[SAVED LOCATION] %s - %s = %s', 
        Player.PlayerData.charinfo.firstname, 
        name, 
        coordString
    ))
    
    -- You can also append to a file
    local file = io.open('saved_locations.txt', 'a')
    if file then
        file:write(string.format("{name = '%s', coords = %s}, -- Saved by %s on %s\n", 
            name, 
            coordString, 
            Player.PlayerData.charinfo.firstname,
            os.date('%Y-%m-%d %H:%M:%S')
        ))
        file:close()
    end
    
    TriggerClientEvent('QBCore:Notify', src, string.format('Location \"%s\" saved to file', name), 'success')
    LogAction(src, string.format('Saved location: %s at %s', name, coordString))
end)

-- Give fuel to player's vehicle
RegisterNetEvent('un-admin:server:giveFuel', function(targetId, amount)
    local src = source
    
    if not HasPermission(src, 'vehicles') then return end
    
    TriggerClientEvent('un-admin:client:setFuel', targetId, amount or 100)
    LogAction(src, string.format('Gave %d%% fuel to player ID %s', amount or 100, targetId))
end)

-- Freeze all players
RegisterNetEvent('un-admin:server:freezeAllPlayers', function()
    local src = source
    
    if not HasPermission(src, 'god') then
        TriggerClientEvent('QBCore:Notify', src, 'Only GOD permission can freeze all players', 'error')
        return
    end
    
    local count = 0
    for _, playerId in ipairs(GetPlayers()) do
        local targetId = tonumber(playerId)
        if targetId ~= src then
            TriggerClientEvent('un-admin:client:freezePlayer', targetId)
            count = count + 1
        end
    end
    
    TriggerClientEvent('QBCore:Notify', src, string.format('Froze %d players', count), 'success')
    LogAction(src, string.format('Froze all players (%d total)', count))
end)

-- Revive all players
RegisterNetEvent('un-admin:server:reviveAllPlayers', function()
    local src = source
    
    if not QBCore.Functions.HasPermission(src, 'god') then
        TriggerClientEvent('QBCore:Notify', src, 'Only GOD permission can revive all players', 'error')
        return
    end
    
    local count = 0
    for _, playerId in ipairs(GetPlayers()) do
        local targetId = tonumber(playerId)
        if RevivePlayerUniversal(targetId) then
            TriggerClientEvent('QBCore:Notify', targetId, 'You have been revived by an admin', 'success')
            count = count + 1
        end
    end
    
    TriggerClientEvent('QBCore:Notify', src, string.format('Revived %d players', count), 'success')
    LogAction(src, string.format('Revived all players (%d total)', count))
end)

-- Delete all vehicles
RegisterNetEvent('un-admin:server:deleteAllVehicles', function()
    local src = source
    
    if not HasPermission(src, 'god') then
        TriggerClientEvent('QBCore:Notify', src, 'Only GOD permission can delete all vehicles', 'error')
        return
    end
    
    -- Broadcast to all clients to delete vehicles
    TriggerClientEvent('un-admin:client:deleteAllVehicles', -1)
    TriggerClientEvent('QBCore:Notify', src, 'Deleted all vehicles in server', 'success')
    LogAction(src, 'Deleted all vehicles in server')
end)

-- ============================================
-- VEHICLE SPAWNING SYSTEM
-- ============================================

-- Request vehicle list
RegisterNetEvent('un-admin:server:requestVehicles', function()
    local src = source
    
    if not HasPermission(src, 'vehicles') then return end
    
    -- Get vehicles from QBCore shared data instead of Config
    local QBCore = exports['qb-core']:GetCoreObject()
    local allVehicles = QBCore.Shared.Vehicles
    
    -- Organize vehicles by category
    local organizedVehicles = {}
    for model, data in pairs(allVehicles) do
        local category = data.category or 'other'
        
        if not organizedVehicles[category] then
            organizedVehicles[category] = {}
        end
        
        table.insert(organizedVehicles[category], {
            model = data.model or model,
            name = data.name or model,
            brand = data.brand or 'Unknown'
        })
    end
    
    TriggerClientEvent('un-admin:client:receiveVehicles', src, organizedVehicles, Config.VehicleCategories)
end)

-- Spawn vehicle for self (temporary)
RegisterNetEvent('un-admin:server:spawnVehicle', function(vehicleModel)
    local src = source
    
    if not HasPermission(src, 'vehicles') then return end
    
    -- Generate plate for keys
    local plate = GeneratePlate()
    
    TriggerClientEvent('un-admin:client:spawnVehicle', src, vehicleModel, false, plate)
    GiveKeysToPlayer(src, plate)
    LogAction(src, string.format('Spawned temporary vehicle: %s (Plate: %s)', vehicleModel, plate))
end)

-- Spawn vehicle for self (with database)
RegisterNetEvent('un-admin:server:spawnVehicleOwned', function(vehicleModel)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not HasPermission(src, 'vehicles') then return end
    if not Player then return end
    
    -- Generate plate
    local plate = GeneratePlate()
    
    -- Add vehicle to database (oxmysql syntax)
    MySQL:insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        Player.PlayerData.license,
        Player.PlayerData.citizenid,
        vehicleModel,
        GetHashKey(vehicleModel),
        '{}',
        plate,
        'pillboxgarage',
        0
    }, function(id)
        if id then
            TriggerClientEvent('un-admin:client:spawnVehicle', src, vehicleModel, true, plate)
            GiveKeysToPlayer(src, plate)
            TriggerClientEvent('QBCore:Notify', src, string.format('Vehicle %s added to your garage!', vehicleModel), 'success')
            LogAction(src, string.format('Spawned owned vehicle: %s (Plate: %s)', vehicleModel, plate))
        else
            TriggerClientEvent('QBCore:Notify', src, 'Failed to add vehicle to database', 'error')
        end
    end)
end)

-- Give vehicle to player (temporary)
RegisterNetEvent('un-admin:server:giveVehicleTemp', function(targetId, vehicleModel)
    local src = source
    
    if not HasPermission(src, 'vehicles') then return end
    
    -- Generate plate for keys
    local plate = GeneratePlate()
    
    TriggerClientEvent('un-admin:client:spawnVehicle', targetId, vehicleModel, false, plate)
    GiveKeysToPlayer(tonumber(targetId), plate)
    TriggerClientEvent('QBCore:Notify', src, string.format('Spawned vehicle for player ID %s', targetId), 'success')
    TriggerClientEvent('QBCore:Notify', targetId, string.format('An admin spawned a vehicle for you: %s', vehicleModel), 'primary')
    LogAction(src, string.format('Spawned temporary vehicle %s for player ID %s (Plate: %s)', vehicleModel, targetId, plate))
end)

-- Give vehicle to player (with database)
RegisterNetEvent('un-admin:server:giveVehicleOwned', function(targetId, vehicleModel)
    local src = source
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    
    if not HasPermission(src, 'vehicles') then return end
    if not TargetPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'Player not found', 'error')
        return
    end
    
    -- Generate plate
    local plate = GeneratePlate()
    
    -- Add vehicle to database (oxmysql syntax)
    MySQL:insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        TargetPlayer.PlayerData.license,
        TargetPlayer.PlayerData.citizenid,
        vehicleModel,
        GetHashKey(vehicleModel),
        '{}',
        plate,
        'pillboxgarage',
        0
    }, function(id)
        if id then
            TriggerClientEvent('un-admin:client:spawnVehicle', targetId, vehicleModel, true, plate)
            GiveKeysToPlayer(tonumber(targetId), plate)
            TriggerClientEvent('QBCore:Notify', src, string.format('Gave vehicle to player ID %s', targetId), 'success')
            TriggerClientEvent('QBCore:Notify', targetId, string.format('An admin gave you a vehicle: %s', vehicleModel), 'success')
            LogAction(src, string.format('Gave owned vehicle %s to player ID %s (Plate: %s)', vehicleModel, targetId, plate))
        else
            TriggerClientEvent('QBCore:Notify', src, 'Failed to add vehicle to database', 'error')
        end
    end)
end)

-- Generate unique plate
function GeneratePlate()
    local plate = QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(2)
    plate = plate:upper()
    
    -- Ensure plate is exactly 8 characters
    if #plate > 8 then
        plate = plate:sub(1, 8)
    elseif #plate < 8 then
        plate = plate .. string.rep('X', 8 - #plate)
    end
    
    -- Check if plate exists (oxmysql syntax)
    local result = MySQL:scalar('SELECT plate FROM player_vehicles WHERE plate = ?', {plate})
    
    if result then
        return GeneratePlate() -- Recursively generate until unique
    else
        return plate
    end
end
