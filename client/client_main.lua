local QBCore = exports['qb-core']:GetCoreObject()
local menuOpen = false
local playerPermission = nil
local featureAccess = {}
local inventoryConfig = { inventory = 'qb-inventory', imagePath = 'nui://qb-inventory/html/images/%s' }
local detectedFuel = nil
local detectedKeys = nil
local detectedAmbulance = nil
local uiConfig = { theme = 'purple', colors = {}, serverName = 'Your Server' }

-- Universal fuel setter function
local function SetVehicleFuelUniversal(vehicle, amount)
    if not detectedFuel or not Config.Fuel.enabled then return false end
    
    local success = pcall(function()
        if detectedFuel == 'rcore_fuel' then
            exports['rcore_fuel']:SetFuel(vehicle, amount)
        elseif detectedFuel == 'lj-fuel' then
            exports['lj-fuel']:SetFuel(vehicle, amount)
        elseif detectedFuel == 'cdn-fuel' then
            exports['cdn-fuel']:SetFuel(vehicle, amount)
        elseif detectedFuel == 'ps-fuel' then
            exports['ps-fuel']:SetFuel(vehicle, amount)
        elseif detectedFuel == 'ox_fuel' then
            Entity(vehicle).state.fuel = amount
        elseif detectedFuel == 'qb-fuel' then
            exports['qb-fuel']:SetFuel(vehicle, amount)

        elseif detectedFuel == 'LegacyFuel' then
            exports['LegacyFuel']:SetFuel(vehicle, amount)

        elseif detectedFuel == 'Renewed-Fuel' then
            exports['Renewed-Fuel']:SetFuel(vehicle, amount)

        elseif detectedFuel == 'okokGasStation' then
            exports['okokGasStation']:SetFuel(vehicle, amount)

        elseif detectedFuel == 'ti_fuel' then
            exports['ti_fuel']:SetFuel(vehicle, amount)

        elseif detectedFuel == 'K4MB1_Fuel' then
            exports['K4MB1_Fuel']:SetFuel(vehicle, amount)

        elseif detectedFuel == 't1ger_fuel' then
            exports['t1ger_fuel']:SetFuel(vehicle, amount)

        elseif detectedFuel == 'myFuel' then
            exports['myFuel']:setFuel(vehicle, amount)

        elseif detectedFuel == 'qs-fuelstations' then
            exports['qs-fuelstations']:SetFuel(vehicle, amount)

        elseif detectedFuel == 'sadoj-fuel' then
            exports['sadoj-fuel']:SetFuel(vehicle, amount)

        elseif detectedFuel == 'gacha_fuel' then
            exports['gacha_fuel']:SetFuel(vehicle, amount)

        elseif detectedFuel == 'cd_fuel' then
            exports['cd_fuel']:SetFuel(vehicle, amount)
        end
    end)

    return success
end

-- Universal vehicle key granter for client-side key systems
local function GiveVehicleKeysClient(plate)
    if not plate then return end

    plate = string.upper(string.gsub(plate, '^%s*(.-)%s*$', '%1'))

    -- Fallback in case config sync hasn't arrived yet
    if not detectedKeys then
        local keyPriority = {
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

        for _, keyRes in ipairs(keyPriority) do
            if GetResourceState(keyRes) == 'started' then
                detectedKeys = keyRes
                break
            end
        end
    end

    if not detectedKeys then return end

    pcall(function()
        if detectedKeys == 'MrNewbVehicleKeys' then
            exports['MrNewbVehicleKeys']:GiveKeysByPlate(plate)

        elseif detectedKeys == 'ic3d_vehiclekeys' then
            exports['ic3d_vehiclekeys']:GiveKeys(plate)

        elseif detectedKeys == 'xd_locksystem_v2' then
            exports['xd_locksystem_v2']:addKey(plate)

        elseif detectedKeys == 'xd_locksystem' then
            exports['xd_locksystem']:addKey(plate)

        elseif detectedKeys == 'fivecode_carkeys' then
            exports['fivecode_carkeys']:GiveKeys(plate)

        elseif detectedKeys == 'cd_vehiclekeys' then
            exports['cd_vehiclekeys']:GiveKeys(plate)
        end
    end)
end

-- Receive keys grant from server (for client-side key systems)
RegisterNetEvent('un-admin:client:giveVehicleKeys', function(plate)
    GiveVehicleKeysClient(plate)
end)

-- Request inventory config from server on join
CreateThread(function()
    Wait(2000)
    TriggerServerEvent('un-admin:server:requestInventoryConfig')
end)

-- Receive inventory config from server
RegisterNetEvent('un-admin:client:receiveInventoryConfig', function(config)
    inventoryConfig = config
    detectedFuel = config.fuel
    detectedKeys = config.keys
    detectedAmbulance = config.ambulance
    uiConfig = {
        theme = config.uiTheme or 'purple',
        colors = config.themeColors or {},
        serverName = config.serverName or 'Your Server'
    }
    print('^5[un-admin]^7 Received config - Inventory: ^2' .. config.inventory .. '^7, Fuel: ^2' .. (config.fuel or 'none') .. '^7, Keys: ^2' .. (config.keys or 'none') .. '^7, Ambulance: ^2' .. (detectedAmbulance or 'fallback') .. '^7, Theme: ^2' .. uiConfig.theme .. '^7')
end)

-- Register command to open menu
RegisterCommand(Config.Command, function()
    QBCore.Functions.TriggerCallback('un-admin:server:checkPermission', function(hasPermission, permission, access)
        if hasPermission then
            playerPermission = permission
            featureAccess = access
            OpenAdminMenu()
        else
            QBCore.Functions.Notify('You do not have permission to use the admin menu', 'error')
        end
    end)
end, false)

-- Register key mapping so it shows in FiveM keybind settings
RegisterKeyMapping(Config.Command, 'Open un-admin Menu', 'keyboard', Config.OpenKey or '')

-- Open menu function
function OpenAdminMenu()
    if menuOpen then return end
    
    menuOpen = true
    SetNuiFocus(true, true)
    
    local PlayerData = QBCore.Functions.GetPlayerData()
    
    SendNUIMessage({
        action = 'openMenu',
        permission = playerPermission,
        adminName = PlayerData.charinfo.firstname .. ' ' .. PlayerData.charinfo.lastname,
        access = featureAccess,
        inventoryConfig = inventoryConfig,
        uiConfig = uiConfig,
        config = {
            quickActions = Config.QuickActions,
            categories = Config.ItemCategories,
            weatherTypes = Config.WeatherTypes
        }
    })
    
    -- Start coord update thread if developer tab is accessible
    if featureAccess.developer then
        CreateThread(function()
            while menuOpen do
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                
                SendNUIMessage({
                    action = 'updateCoords',
                    coords = {
                        x = coords.x,
                        y = coords.y,
                        z = coords.z,
                        h = heading
                    }
                })
                
                Wait(100)
            end
        end)
    end
    
    -- Update stats
    UpdateStats()
end

-- Close menu
RegisterNUICallback('closeUI', function(data, cb)
    cb('ok')
    CloseAdminMenu()
end)

function CloseAdminMenu()
    if not menuOpen then return end
    
    menuOpen = false
    
    SendNUIMessage({
        action = 'closeMenu'
    })
    
    -- Small delay to ensure NUI processes close before removing focus
    Wait(50)
    SetNuiFocus(false, false)
    
    -- Ensure player can move
    SetPedCanRagdoll(PlayerPedId(), true)
    FreezeEntityPosition(PlayerPedId(), false)
end

-- Request players
RegisterNUICallback('requestPlayers', function(data, cb)
    QBCore.Functions.TriggerCallback('un-admin:server:getPlayers', function(players)
        SendNUIMessage({
            action = 'updatePlayers',
            players = players
        })
    end)
    cb('ok')
end)

-- Request items
RegisterNUICallback('requestItems', function(data, cb)
    QBCore.Functions.TriggerCallback('un-admin:server:getItems', function(items)
        SendNUIMessage({
            action = 'updateItems',
            items = items
        })
    end)
    cb('ok')
end)

-- Request vehicles
RegisterNUICallback('requestVehicles', function(data, cb)
    TriggerServerEvent('un-admin:server:requestVehicles')
    cb('ok')
end)

-- Spawn vehicle for self (temporary)
RegisterNUICallback('spawnVehicle', function(data, cb)
    TriggerServerEvent('un-admin:server:spawnVehicle', data.vehicleModel)
    cb('ok')
end)

-- Spawn vehicle for self (with database)
RegisterNUICallback('spawnVehicleOwned', function(data, cb)
    TriggerServerEvent('un-admin:server:spawnVehicleOwned', data.vehicleModel)
    cb('ok')
end)

-- Give vehicle to player (temporary)
RegisterNUICallback('giveVehicleTemp', function(data, cb)
    TriggerServerEvent('un-admin:server:giveVehicleTemp', data.targetId, data.vehicleModel)
    cb('ok')
end)

-- Give vehicle to player (with database)
RegisterNUICallback('giveVehicleOwned', function(data, cb)
    TriggerServerEvent('un-admin:server:giveVehicleOwned', data.targetId, data.vehicleModel)
    cb('ok')
end)

-- Request logs
RegisterNUICallback('requestLogs', function(data, cb)
    -- Request logs from server
    TriggerServerEvent('un-admin:server:requestLogs')
    cb('ok')
end)

-- Update stats
function UpdateStats()
    CreateThread(function()
        while menuOpen do
            local players = GetActivePlayers()
            
            -- Get server uptime from server
            QBCore.Functions.TriggerCallback('un-admin:server:getUptime', function(uptime)
                SendNUIMessage({
                    action = 'updateStats',
                    stats = {
                        playerCount = #players,
                        uptime = uptime,
                        performance = 'Good'
                    }
                })
            end)
            
            Wait(5000)
        end
    end)
end

-- Player Actions
RegisterNUICallback('teleportToPlayer', function(data, cb)
    TriggerServerEvent('un-admin:server:teleportToPlayer', data.playerId)
    QBCore.Functions.Notify('Teleporting to player...', 'success')
    cb('ok')
end)

RegisterNUICallback('bringPlayer', function(data, cb)
    TriggerServerEvent('un-admin:server:bringPlayer', data.playerId)
    QBCore.Functions.Notify('Bringing player...', 'success')
    cb('ok')
end)

RegisterNUICallback('freezePlayer', function(data, cb)
    TriggerServerEvent('un-admin:server:freezePlayer', data.playerId)
    cb('ok')
end)

-- Client handler for freeze player
RegisterNetEvent('un-admin:client:freezePlayer', function()
    local ped = PlayerPedId()
    local isFrozen = IsEntityPositionFrozen(ped)
    FreezeEntityPosition(ped, not isFrozen)
    
    if isFrozen then
        QBCore.Functions.Notify('You have been unfrozen', 'success')
    else
        QBCore.Functions.Notify('You have been frozen', 'error')
    end
end)

-- Client handler for revive player
RegisterNetEvent('un-admin:client:revivePlayer', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    FreezeEntityPosition(ped, false)
    SetPedCanRagdoll(ped, true)
    ClearPedTasksImmediately(ped)

    -- NetworkResurrectLocalPlayer needs individual x, y, z floats
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, true)

    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 100)
end)

RegisterNUICallback('revivePlayer', function(data, cb)
    TriggerServerEvent('un-admin:server:revivePlayer', data.playerId)
    QBCore.Functions.Notify('Reviving player...', 'success')
    cb('ok')
end)

RegisterNUICallback('giveArmor', function(data, cb)
    TriggerServerEvent('un-admin:server:giveArmor', data.playerId)
    cb('ok')
end)

-- Client handler for give armor
RegisterNetEvent('un-admin:client:setArmor', function(amount)
    local ped = PlayerPedId()
    SetPedArmour(ped, amount)
    QBCore.Functions.Notify('Armor set to ' .. amount .. '%', 'success')
end)

RegisterNUICallback('giveFuel', function(data, cb)
    TriggerServerEvent('un-admin:server:giveFuel', data.playerId, 100)
    QBCore.Functions.Notify('Giving fuel to player...', 'success')
    cb('ok')
end)

-- Client handler for give fuel
RegisterNetEvent('un-admin:client:setFuel', function(amount)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    
    if veh ~= 0 and Config.Fuel.enabled then
        if SetVehicleFuelUniversal(veh, amount) then
            QBCore.Functions.Notify('Vehicle refueled to ' .. amount .. '%', 'success')
        else
            QBCore.Functions.Notify('Failed to refuel vehicle', 'error')
        end
    else
        QBCore.Functions.Notify('Not in a vehicle or fuel system disabled', 'error')
    end
end)

RegisterNUICallback('sendToMe', function(data, cb)
    TriggerServerEvent('un-admin:server:bringPlayer', data.playerId)
    QBCore.Functions.Notify('Bringing player...', 'success')
    cb('ok')
end)

RegisterNUICallback('killPlayer', function(data, cb)
    TriggerServerEvent('un-admin:server:killPlayer', data.playerId)
    cb('ok')
end)

-- Client handler for kill player
RegisterNetEvent('un-admin:client:killPlayer', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, 0)
end)

RegisterNUICallback('stripWeapons', function(data, cb)
    TriggerServerEvent('un-admin:server:stripWeapons', data.playerId)
    cb('ok')
end)

-- Client handler for strip weapons
RegisterNetEvent('un-admin:client:stripWeapons', function()
    RemoveAllPedWeapons(PlayerPedId(), true)
    QBCore.Functions.Notify('All weapons removed', 'error')
end)

-- Troll Actions
RegisterNUICallback('slapPlayer', function(data, cb)
    TriggerServerEvent('un-admin:server:slapPlayer', data.playerId)
    cb('ok')
end)

RegisterNUICallback('setOnFire', function(data, cb)
    TriggerServerEvent('un-admin:server:setOnFire', data.playerId)
    cb('ok')
end)

RegisterNUICallback('electrocute', function(data, cb)
    TriggerServerEvent('un-admin:server:electrocute', data.playerId)
    cb('ok')
end)

RegisterNUICallback('flingPlayer', function(data, cb)
    TriggerServerEvent('un-admin:server:flingPlayer', data.playerId)
    cb('ok')
end)

RegisterNUICallback('makeDrunk', function(data, cb)
    TriggerServerEvent('un-admin:server:makeDrunk', data.playerId)
    cb('ok')
end)

RegisterNUICallback('cagePlayer', function(data, cb)
    TriggerServerEvent('un-admin:server:cagePlayer', data.playerId)
    cb('ok')
end)

RegisterNUICallback('explodePlayer', function(data, cb)
    TriggerServerEvent('un-admin:server:explodePlayer', data.playerId)
    cb('ok')
end)

RegisterNUICallback('sendToOcean', function(data, cb)
    TriggerServerEvent('un-admin:server:sendToOcean', data.playerId)
    cb('ok')
end)

RegisterNUICallback('sendToSky', function(data, cb)
    TriggerServerEvent('un-admin:server:sendToSky', data.playerId)
    cb('ok')
end)

-- ============================================
-- CLIENT-SIDE TROLL ACTION HANDLERS
-- ============================================

-- Slap player (ragdoll)
RegisterNetEvent('un-admin:client:slapPlayer', function(force)
    local ped = PlayerPedId()
    SetPedToRagdoll(ped, 5000, 5000, 0, 0, 0, 0)
    local forward = GetEntityForwardVector(ped)
    SetEntityVelocity(ped, forward.x * force, forward.y * force, 5.0)
    QBCore.Functions.Notify('You got slapped!', 'error')
end)

-- Set on fire
RegisterNetEvent('un-admin:client:setOnFire', function()
    local ped = PlayerPedId()
    StartEntityFire(ped)
    QBCore.Functions.Notify('You are on fire!', 'error')
    
    -- Auto extinguish after configured duration
    SetTimeout(Config.TrollSettings.fireDuration, function()
        StopEntityFire(ped)
    end)
end)

-- Electrocute
RegisterNetEvent('un-admin:client:electrocute', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    -- Play effects
    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(1)
    end
    
    UseParticleFxAssetNextCall('core')
    StartParticleFxNonLoopedAtCoord('ent_dst_elec_fire_sp', coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 1.0, false, false, false)
    
    SetPedToRagdoll(ped, 3000, 3000, 0, 0, 0, 0)
    QBCore.Functions.Notify('⚡ ZZZZTTTT!', 'error')
end)

-- Fling player
RegisterNetEvent('un-admin:client:flingPlayer', function()
    local ped = PlayerPedId()
    SetEntityVelocity(ped, 0.0, 0.0, 50.0)
    QBCore.Functions.Notify('WHEEEEE!', 'error')
end)

-- Make drunk
RegisterNetEvent('un-admin:client:makeDrunk', function()
    RequestAnimSet('move_m@drunk@verydrunk')
    while not HasAnimSetLoaded('move_m@drunk@verydrunk') do
        Wait(1)
    end
    
    SetPedMovementClipset(PlayerPedId(), 'move_m@drunk@verydrunk', 1.0)
    SetTimecycleModifier('spectator5')
    SetPedMotionBlur(PlayerPedId(), true)
    
    QBCore.Functions.Notify('You feel very drunk...', 'error')
    
    -- Reset after configured duration
    SetTimeout(Config.TrollSettings.drunkDuration, function()
        ResetPedMovementClipset(PlayerPedId(), 0.0)
        ClearTimecycleModifier()
        SetPedMotionBlur(PlayerPedId(), false)
    end)
end)

-- Cage player
RegisterNetEvent('un-admin:client:cagePlayer', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    local cage = CreateObject(GetHashKey('prop_fnclink_05crnr1'), coords.x, coords.y, coords.z - 1.0, true, true, false)
    PlaceObjectOnGroundProperly(cage)
    FreezeEntityPosition(cage, true)
    
    QBCore.Functions.Notify('You have been caged!', 'error')
    
    -- Remove cage after configured duration
    SetTimeout(Config.TrollSettings.cageDuration, function()
        if DoesEntityExist(cage) then
            DeleteEntity(cage)
        end
    end)
end)

-- Explode player
RegisterNetEvent('un-admin:client:explodePlayer', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    AddExplosion(coords.x, coords.y, coords.z, 2, 1.0, true, false, 1.0)
    QBCore.Functions.Notify('💣 BOOM!', 'error')
end)

-- Send to sky
RegisterNetEvent('un-admin:client:sendToSky', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    SetEntityCoords(ped, coords.x, coords.y, 1000.0, false, false, false, false)
    
    -- Give parachute
    GiveWeaponToPed(ped, GetHashKey('GADGET_PARACHUTE'), 1, false, false)
end)

-- ============================================

RegisterNUICallback('setJob', function(data, cb)
    -- Request jobs from server and open job selection modal
    QBCore.Functions.TriggerCallback('un-admin:server:getJobs', function(jobs)
        SendNUIMessage({
            action = 'openJobModal',
            jobs = jobs,
            playerId = data.playerId
        })
    end)
    cb('ok')
end)

RegisterNUICallback('submitJobChange', function(data, cb)
    TriggerServerEvent('un-admin:server:setJob', data.playerId, data.job, data.grade)
    QBCore.Functions.Notify('Job changed successfully', 'success')
    cb('ok')
end)

RegisterNUICallback('giveMoney', function(data, cb)
    local targetId = tonumber(data.playerId)
    local amount = tonumber(data.amount)
    local moneyType = data.moneyType

    if not targetId or targetId < 1 then
        QBCore.Functions.Notify('Invalid player ID', 'error')
        cb('ok')
        return
    end

    if not amount or amount < 1 then
        QBCore.Functions.Notify('Invalid money amount', 'error')
        cb('ok')
        return
    end

    if moneyType ~= 'cash' and moneyType ~= 'bank' then
        QBCore.Functions.Notify('Invalid account type', 'error')
        cb('ok')
        return
    end

    TriggerServerEvent('un-admin:server:giveMoney', targetId, moneyType, math.floor(amount))
    cb('ok')
end)

RegisterNUICallback('spectatePlayer', function(data, cb)
    TriggerServerEvent('un-admin:server:spectatePlayer', data.playerId)
    cb('ok')
end)

RegisterNUICallback('kickPlayer', function(data, cb)
    TriggerServerEvent('un-admin:server:kickPlayer', data.playerId, 'Kicked by admin')
    cb('ok')
end)

RegisterNUICallback('banPlayer', function(data, cb)
    TriggerServerEvent('un-admin:server:banPlayer', data.playerId, 'Banned by admin')
    cb('ok')
end)

-- Give Item
RegisterNUICallback('giveItem', function(data, cb)
    TriggerServerEvent('un-admin:server:giveItem', data.item, data.quantity, data.target)
    QBCore.Functions.Notify('Item given successfully', 'success')
    cb('ok')
end)

-- Quick Actions
RegisterNUICallback('fixVehicle', function(data, cb)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    
    if veh ~= 0 then
        SetVehicleFixed(veh)
        SetVehicleDeformationFixed(veh)
        SetVehicleUndriveable(veh, false)
        SetVehicleEngineOn(veh, true, true)
        QBCore.Functions.Notify('Vehicle fixed', 'success')
    else
        QBCore.Functions.Notify('You must be in a vehicle', 'error')
    end
    cb('ok')
end)

RegisterNUICallback('refuelVehicle', function(data, cb)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    
    if veh ~= 0 then
        -- Universal fuel system integration
        if Config.Fuel.enabled then
            SetVehicleFuelUniversal(veh, 100.0)
        end
        QBCore.Functions.Notify('Vehicle refueled to 100%', 'success')
    else
        QBCore.Functions.Notify('You must be in a vehicle', 'error')
    end
    cb('ok')
end)

RegisterNUICallback('clearArea', function(data, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local radius = 50.0
    
    -- Clear vehicles
    local vehicles = GetGamePool('CVehicle')
    local clearedCount = 0
    for _, vehicle in ipairs(vehicles) do
        if vehicle ~= GetVehiclePedIsIn(ped, false) then
            local vehCoords = GetEntityCoords(vehicle)
            local distance = #(coords - vehCoords)
            if distance <= radius then
                DeleteEntity(vehicle)
                clearedCount = clearedCount + 1
            end
        end
    end
    
    -- Clear peds (except player and other players)
    local peds = GetGamePool('CPed')
    for _, pedEntity in ipairs(peds) do
        if not IsPedAPlayer(pedEntity) and pedEntity ~= ped then
            local pedCoords = GetEntityCoords(pedEntity)
            local distance = #(coords - pedCoords)
            if distance <= radius then
                DeleteEntity(pedEntity)
                clearedCount = clearedCount + 1
            end
        end
    end
    
    -- Clear objects
    local objects = GetGamePool('CObject')
    for _, object in ipairs(objects) do
        local objCoords = GetEntityCoords(object)
        local distance = #(coords - objCoords)
        if distance <= radius then
            DeleteEntity(object)
            clearedCount = clearedCount + 1
        end
    end
    
    QBCore.Functions.Notify(string.format('Cleared %d entities in 50m radius', clearedCount), 'success')
    cb('ok')
end)

RegisterNUICallback('healSelf', function(data, cb)
    local ped = PlayerPedId()
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 100)
    QBCore.Functions.Notify('Healed successfully', 'success')
    cb('ok')
end)

RegisterNUICallback('freezeAllPlayers', function(data, cb)
    TriggerServerEvent('un-admin:server:freezeAllPlayers')
    cb('ok')
end)

RegisterNUICallback('reviveAllPlayers', function(data, cb)
    TriggerServerEvent('un-admin:server:reviveAllPlayers')
    cb('ok')
end)

RegisterNUICallback('deleteAllVehicles', function(data, cb)
    TriggerServerEvent('un-admin:server:deleteAllVehicles')
    cb('ok')
end)

RegisterNUICallback('clearAreaPeds', function(data, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local radius = 100.0
    local peds = GetGamePool('CPed')
    local clearedCount = 0
    
    for _, pedEntity in ipairs(peds) do
        if not IsPedAPlayer(pedEntity) and pedEntity ~= ped then
            local pedCoords = GetEntityCoords(pedEntity)
            local distance = #(coords - pedCoords)
            if distance <= radius then
                DeleteEntity(pedEntity)
                clearedCount = clearedCount + 1
            end
        end
    end
    
    QBCore.Functions.Notify(string.format('Cleared %d peds in 100m radius', clearedCount), 'success')
    cb('ok')
end)

RegisterNUICallback('saveLocation', function(data, cb)
    TriggerServerEvent('un-admin:server:saveLocation', data.name, data.coords)
    cb('ok')
end)

RegisterNUICallback('tpWaypoint', function(data, cb)
    TeleportToWaypoint()
    cb('ok')
end)

-- Teleport to waypoint
function TeleportToWaypoint()
    local waypoint = GetFirstBlipInfoId(8)
    
    if not DoesBlipExist(waypoint) then
        QBCore.Functions.Notify('No waypoint set', 'error')
        return
    end
    
    local coords = GetBlipInfoIdCoord(waypoint)
    local ped = PlayerPedId()
    
    -- Get ground Z coordinate
    local groundZ = 0.0
    local foundGround, z = GetGroundZFor_3dCoord(coords.x, coords.y, 1000.0, false)
    
    if foundGround then
        groundZ = z
    else
        groundZ = coords.z
    end
    
    SetEntityCoords(ped, coords.x, coords.y, groundZ + 1.0, false, false, false, false)
    QBCore.Functions.Notify('Teleported to waypoint', 'success')
end

-- Teleport to coordinates
RegisterNUICallback('teleportToCoords', function(data, cb)
    local ped = PlayerPedId()
    SetEntityCoords(ped, data.x, data.y, data.z, false, false, false, false)
    QBCore.Functions.Notify('Teleported to coordinates', 'success')
    cb('ok')
end)

-- Server Controls
RegisterNUICallback('setWeather', function(data, cb)
    TriggerServerEvent('un-admin:server:setWeather', data.weather)
    cb('ok')
end)

RegisterNUICallback('setTime', function(data, cb)
    TriggerServerEvent('un-admin:server:setTime', data.hour)
    cb('ok')
end)

RegisterNUICallback('freezeTime', function(data, cb)
    TriggerServerEvent('un-admin:server:freezeTime')
    cb('ok')
end)

RegisterNUICallback('sendAnnouncement', function(data, cb)
    TriggerServerEvent('un-admin:server:sendAnnouncement', data.text)
    cb('ok')
end)

-- Resource Management
RegisterNUICallback('requestResources', function(data, cb)
    QBCore.Functions.TriggerCallback('un-admin:server:getResources', function(resources)
        cb('ok')
        SendNUIMessage({
            action = 'displayResources',
            resources = resources
        })
    end)
end)

RegisterNUICallback('startResource', function(data, cb)
    TriggerServerEvent('un-admin:server:startResource', data.resource)
    cb('ok')
end)

RegisterNUICallback('restartResource', function(data, cb)
    TriggerServerEvent('un-admin:server:restartResource', data.resource)
    cb('ok')
end)

RegisterNUICallback('stopResource', function(data, cb)
    TriggerServerEvent('un-admin:server:stopResource', data.resource)
    cb('ok')
end)

RegisterNetEvent('un-admin:client:refreshResources', function()
    SendNUIMessage({
        action = 'refreshResources'
    })
end)

-- Receive server responses
RegisterNetEvent('un-admin:client:teleportToCoords', function(coords)
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
end)

RegisterNetEvent('un-admin:client:notification', function(message, type)
    QBCore.Functions.Notify(message, type)
end)

RegisterNetEvent('un-admin:client:addLog', function(log)
    if menuOpen then
        SendNUIMessage({
            action = 'addLog',
            log = log
        })
    end
end)
-- =======================================
-- VEHICLE SPAWNING
-- =======================================

-- Receive vehicles list
RegisterNetEvent('un-admin:client:receiveVehicles', function(vehicles, categories)
    SendNUIMessage({
        action = 'receiveVehicles',
        vehicles = vehicles,
        categories = categories
    })
end)

-- Spawn vehicle
RegisterNetEvent('un-admin:client:spawnVehicle', function(vehicleModel, isOwned, plate)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    -- Load model with timeout
    local modelHash = GetHashKey(vehicleModel)
    if not IsModelInCdimage(modelHash) or not IsModelAVehicle(modelHash) then
        QBCore.Functions.Notify(string.format('Invalid vehicle model: %s', vehicleModel), 'error')
        return
    end
    
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
    
    if not HasModelLoaded(modelHash) then
        QBCore.Functions.Notify('Failed to load vehicle model', 'error')
        return
    end
    
    -- Find clear spawn location (5 units in front)
    local fwd = GetEntityForwardVector(ped)
    local spawnCoords = vector3(coords.x + fwd.x * 5.0, coords.y + fwd.y * 5.0, coords.z)
    
    local vehicle = CreateVehicle(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, heading, true, false)
    
    -- Wait for vehicle to exist
    timeout = 0
    while not DoesEntityExist(vehicle) and timeout < 1000 do
        Wait(10)
        timeout = timeout + 10
    end
    
    if not DoesEntityExist(vehicle) then
        SetModelAsNoLongerNeeded(modelHash)
        QBCore.Functions.Notify('Failed to spawn vehicle', 'error')
        return
    end
    
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehRadioStation(vehicle, 'OFF')
    SetVehicleFuelLevel(vehicle, 100.0)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetEntityAsMissionEntity(vehicle, true, true)
    
    -- Set plate and grant keys for all spawned vehicles
    if plate then
        SetVehicleNumberPlateText(vehicle, plate)
        -- Grant keys using detected key system
        GiveVehicleKeysClient(plate)
    end
    
    -- Put player in vehicle
    TaskWarpPedIntoVehicle(ped, vehicle, -1)
    
    -- Release model
    SetModelAsNoLongerNeeded(modelHash)
    
    QBCore.Functions.Notify(string.format('Vehicle spawned: %s%s', vehicleModel, isOwned and ' (Owned)' or ''), 'success')
end)

-- Delete all vehicles in the world
RegisterNetEvent('un-admin:client:deleteAllVehicles', function()
    local ped = PlayerPedId()
    local currentVehicle = GetVehiclePedIsIn(ped, false)
    local vehicles = GetGamePool('CVehicle')
    local deletedCount = 0
    
    for _, vehicle in ipairs(vehicles) do
        -- Don't delete the vehicle the player is currently in
        if vehicle ~= currentVehicle then
            DeleteEntity(vehicle)
            deletedCount = deletedCount + 1
        end
    end
    
    if deletedCount > 0 then
        QBCore.Functions.Notify(string.format('Deleted %d vehicles', deletedCount), 'primary')
    end
end)

-- ==============================================
-- REPORT SYSTEM
-- ==============================================

-- Register report command for players
RegisterCommand(Config.ReportSystem.command, function()
    if not Config.ReportSystem.enabled then
        QBCore.Functions.Notify('Report system is currently disabled', 'error')
        return
    end
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openReportModal'
    })
end, false)

-- Handle report submission
RegisterNUICallback('submitReport', function(data, cb)
    cb('ok')
    TriggerServerEvent('un-admin:server:submitReport', data.message)
    
    -- If admin menu is not open, close NUI focus (modal was opened via /report command)
    if not menuOpen then
        SetNuiFocus(false, false)
    end
end)

-- Handle report modal close (cancel button)
RegisterNUICallback('closeReportModal', function(data, cb)
    cb('ok')
    
    -- If admin menu is not open, close NUI focus (modal was opened via /report command)
    if not menuOpen then
        SetNuiFocus(false, false)
    end
end)

-- Request reports (admin only)
RegisterNUICallback('requestReports', function(data, cb)
    QBCore.Functions.TriggerCallback('un-admin:server:getReports', function(reports)
        SendNUIMessage({
            action = 'displayReports',
            reports = reports
        })
    end)
    cb('ok')
end)

-- Resolve report
RegisterNUICallback('resolveReport', function(data, cb)
    TriggerServerEvent('un-admin:server:resolveReport', data.reportId)
    cb('ok')
end)

-- Update report count badge
RegisterNetEvent('un-admin:client:updateReportCount', function(count)
    SendNUIMessage({
        action = 'updateReportCount',
        count = count
    })
end)

-- ==============================================
-- END REPORT SYSTEM
-- ==============================================
