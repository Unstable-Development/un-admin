local QBCore = exports['qb-core']:GetCoreObject()

-- Developer tool states
local noclipEnabled = false
local noclipSpeed = 1.0
local airwalkEnabled = false
local airwalkSpeed = 0.5
local godmodeEnabled = false
local invisibleEnabled = false
local coordsEnabled = false
local deleteLaserEnabled = false
local entityInfoEnabled = false

-- Noclip keybind
RegisterCommand('+toggleNoclip', function()
    noclipEnabled = not noclipEnabled
    
    if noclipEnabled then
        StartNoclip()
        QBCore.Functions.Notify('Noclip enabled', 'success')
    else
        StopNoclip()
        QBCore.Functions.Notify('Noclip disabled', 'error')
    end
end, false)

RegisterCommand('-toggleNoclip', function() end, false)
RegisterKeyMapping('+toggleNoclip', 'Toggle Noclip', 'keyboard', Config.NoclipKey or '')

-- Airwalk keybind
RegisterCommand('+toggleAirwalk', function()
    airwalkEnabled = not airwalkEnabled
    
    if airwalkEnabled then
        StartAirwalk()
        QBCore.Functions.Notify('Airwalk mode enabled', 'success')
    else
        StopAirwalk()
        QBCore.Functions.Notify('Airwalk mode disabled', 'error')
    end
end, false)

RegisterCommand('-toggleAirwalk', function() end, false)
RegisterKeyMapping('+toggleAirwalk', 'Toggle Airwalk Mode', 'keyboard', Config.AirwalkKey or '')

-- Noclip
RegisterNUICallback('toggleNoclip', function(data, cb)
    noclipEnabled = not noclipEnabled
    
    if noclipEnabled then
        StartNoclip()
        QBCore.Functions.Notify('Noclip enabled', 'success')
    else
        StopNoclip()
        QBCore.Functions.Notify('Noclip disabled', 'error')
    end
    
    cb('ok')
end)

function StartNoclip()
    CreateThread(function()
        local ped = PlayerPedId()
        
        -- Make entity invisible and freeze
        SetEntityVisible(ped, false, false)
        SetEntityInvincible(ped, true)
        SetEntityCollision(ped, false, false)
        FreezeEntityPosition(ped, true)
        
        -- Mouse wheel speed control
        CreateThread(function()
            while noclipEnabled do
                -- Mouse wheel up
                if IsControlJustPressed(0, 241) then
                    noclipSpeed = math.min(noclipSpeed + 0.5, 10.0)
                end
                
                -- Mouse wheel down
                if IsControlJustPressed(0, 242) then
                    noclipSpeed = math.max(noclipSpeed - 0.5, 0.1)
                end
                
                Wait(0)
            end
        end)
        
        while noclipEnabled do
            ped = PlayerPedId()
            local x, y, z = table.unpack(GetEntityCoords(ped, true))
            local dx, dy, dz = 0.0, 0.0, 0.0
            local speed = noclipSpeed
            
            -- Speed boost with Shift
            if IsControlPressed(0, 21) then
                speed = speed * 2.5
            end
            
            -- Get camera rotation for horizontal direction only
            local camRot = GetGameplayCamRot(0)
            local camHeading = camRot.z
            
            -- Forward/Backward movement (horizontal only, no pitch)
            if IsControlPressed(0, 32) then -- W
                dx = -math.sin(math.rad(camHeading)) * speed
                dy = math.cos(math.rad(camHeading)) * speed
            end
            
            if IsControlPressed(0, 33) then -- S
                dx = math.sin(math.rad(camHeading)) * speed
                dy = -math.cos(math.rad(camHeading)) * speed
            end
            
            -- Left/Right strafe
            if IsControlPressed(0, 34) then -- A
                dx = dx + (-math.sin(math.rad(camHeading + 90)) * speed)
                dy = dy + (math.cos(math.rad(camHeading + 90)) * speed)
            end
            
            if IsControlPressed(0, 35) then -- D
                dx = dx + (-math.sin(math.rad(camHeading - 90)) * speed)
                dy = dy + (math.cos(math.rad(camHeading - 90)) * speed)
            end
            
            -- Up/Down movement
            if IsControlPressed(0, 38) then -- E - Up
                dz = speed
            end
            
            if IsControlPressed(0, 44) then -- Q - Down
                dz = -speed
            end
            
            -- Apply movement
            x = x + dx
            y = y + dy
            z = z + dz
            
            SetEntityCoordsNoOffset(ped, x, y, z, true, true, true)
            
            Wait(0)
        end
    end)
end

function StopNoclip()
    local ped = PlayerPedId()
    
    -- Reset speed
    noclipSpeed = 1.0
    
    -- Keep frozen temporarily while we find ground
    FreezeEntityPosition(ped, true)
    
    -- Get current position
    local coords = GetEntityCoords(ped)
    
    -- Find ground below player
    local groundFound = false
    local groundZ = coords.z
    
    -- Try method 1: GetGroundZFor_3dCoord
    for i = 1, 10 do
        local found, safeZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + (i * 50.0), 0)
        if found then
            groundZ = safeZ
            groundFound = true
            break
        end
        Wait(10)
    end
    
    -- Try method 2: Raycast if first method failed
    if not groundFound then
        local rayHandle = StartShapeTestRay(coords.x, coords.y, coords.z + 1000.0, coords.x, coords.y, coords.z - 1000.0, -1, ped, 0)
        local _, hit, endCoords = GetShapeTestResult(rayHandle)
        if hit then
            groundZ = endCoords.z
            groundFound = true
        end
    end
    
    -- Place player on ground
    if groundFound then
        SetEntityCoordsNoOffset(ped, coords.x, coords.y, groundZ + 1.0, false, false, false)
    else
        -- Fallback: just use current Z if we can't find ground
        SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    end
    
    -- Reset velocity
    SetEntityVelocity(ped, 0.0, 0.0, 0.0)
    
    Wait(100)
    
    -- Restore entity state (only if not in invisible mode)
    if not invisibleEnabled then
        SetEntityVisible(ped, true, false)
    end
    
    SetEntityInvincible(ped, godmodeEnabled)
    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, false)
end

-- Airwalk Mode
RegisterNUICallback('toggleAirwalk', function(data, cb)
    airwalkEnabled = not airwalkEnabled
    
    if airwalkEnabled then
        StartAirwalk()
        QBCore.Functions.Notify('Airwalk mode enabled', 'success')
    else
        StopAirwalk()
        QBCore.Functions.Notify('Airwalk mode disabled', 'error')
    end
    
    cb('ok')
end)

function StartAirwalk()
    CreateThread(function()
        local ped = PlayerPedId()
        
        -- Setup airwalk mode
        SetPedCanRagdoll(ped, false)
        SetEntityInvincible(ped, true)
        
        -- Mouse wheel speed control
        CreateThread(function()
            while airwalkEnabled do
                if IsControlJustPressed(0, 241) then -- Mouse wheel up
                    airwalkSpeed = math.min(airwalkSpeed + 0.2, 5.0)
                end
                
                if IsControlJustPressed(0, 242) then -- Mouse wheel down
                    airwalkSpeed = math.max(airwalkSpeed - 0.2, 0.1)
                end
                
                Wait(0)
            end
        end)
        
        while airwalkEnabled do
            ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local speed = airwalkSpeed
            
            -- Shift speed boost (5x)
            if IsControlPressed(0, 21) then
                speed = speed * 5.0
            end
            
            -- Get camera direction
            local camRot = GetGameplayCamRot(0)
            local camHeading = camRot.z
            local camPitch = camRot.x
            
            -- Disable controls
            DisableControlAction(0, 21, true) -- Sprint
            DisableControlAction(0, 22, true) -- Jump
            DisableControlAction(0, 23, true) -- Enter vehicle
            DisableControlAction(0, 75, true) -- Exit vehicle
            
            -- Calculate movement
            local newX = coords.x
            local newY = coords.y
            local newZ = coords.z
            
            -- Forward/Backward (horizontal only)
            if IsControlPressed(0, 32) then -- W
                newX = newX + (-math.sin(math.rad(camHeading)) * speed)
                newY = newY + (math.cos(math.rad(camHeading)) * speed)
            end
            
            if IsControlPressed(0, 33) then -- S
                newX = newX - (-math.sin(math.rad(camHeading)) * speed * 0.6)
                newY = newY - (math.cos(math.rad(camHeading)) * speed * 0.6)
            end
            
            -- Strafe (horizontal only)
            if IsControlPressed(0, 34) then -- A
                newX = newX + (-math.sin(math.rad(camHeading + 90)) * speed * 0.8)
                newY = newY + (math.cos(math.rad(camHeading + 90)) * speed * 0.8)
            end
            
            if IsControlPressed(0, 35) then -- D
                newX = newX + (-math.sin(math.rad(camHeading - 90)) * speed * 0.8)
                newY = newY + (math.cos(math.rad(camHeading - 90)) * speed * 0.8)
            end
            
            -- Up/Down (only E/Q control vertical movement)
            if IsControlPressed(0, 38) then -- E
                newZ = newZ + (speed * 1.2)
            end
            
            if IsControlPressed(0, 44) then -- Q
                newZ = newZ - (speed * 1.2)
            end
            
            -- Apply movement
            SetEntityCoordsNoOffset(ped, newX, newY, newZ, true, true, true)
            SetEntityVelocity(ped, 0.0, 0.0, 0.0)
            
            Wait(0)
        end
    end)
end

function StopAirwalk()
    local ped = PlayerPedId()
    
    -- Reset speed
    airwalkSpeed = 0.5
    
    -- Gently place player on ground (same as noclip)
    FreezeEntityPosition(ped, true)
    
    local coords = GetEntityCoords(ped)
    local groundFound = false
    local groundZ = coords.z
    
    for i = 1, 10 do
        local found, safeZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + (i * 50.0), 0)
        if found then
            groundZ = safeZ
            groundFound = true
            break
        end
        Wait(10)
    end
    
    if not groundFound then
        local rayHandle = StartShapeTestRay(coords.x, coords.y, coords.z + 1000.0, coords.x, coords.y, coords.z - 1000.0, -1, ped, 0)
        local _, hit, endCoords = GetShapeTestResult(rayHandle)
        if hit then
            groundZ = endCoords.z
            groundFound = true
        end
    end
    
    if groundFound then
        SetEntityCoordsNoOffset(ped, coords.x, coords.y, groundZ + 1.0, false, false, false)
    else
        SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    end
    
    SetEntityVelocity(ped, 0.0, 0.0, 0.0)
    
    Wait(100)
    
    -- Restore normal state
    SetPedCanRagdoll(ped, true)
    SetEntityInvincible(ped, godmodeEnabled)
    FreezeEntityPosition(ped, false)
end

-- God Mode
RegisterNUICallback('toggleGodmode', function(data, cb)
    godmodeEnabled = not godmodeEnabled
    
    if godmodeEnabled then
        StartGodmode()
        QBCore.Functions.Notify('God mode enabled', 'success')
    else
        QBCore.Functions.Notify('God mode disabled', 'error')
    end
    
    cb('ok')
end)

function StartGodmode()
    CreateThread(function()
        while godmodeEnabled do
            local ped = PlayerPedId()
            SetEntityInvincible(ped, true)
            SetPlayerInvincible(PlayerId(), true)
            
            if not godmodeEnabled then
                SetEntityInvincible(ped, false)
                SetPlayerInvincible(PlayerId(), false)
                break
            end
            
            Wait(0)
        end
    end)
end

-- Invisible
RegisterNUICallback('toggleInvisible', function(data, cb)
    invisibleEnabled = not invisibleEnabled
    local ped = PlayerPedId()
    
    SetEntityVisible(ped, not invisibleEnabled, false)
    
    if invisibleEnabled then
        QBCore.Functions.Notify('Invisible mode enabled', 'success')
    else
        QBCore.Functions.Notify('Invisible mode disabled', 'error')
    end
    
    cb('ok')
end)

-- Show Coordinates
RegisterNUICallback('toggleCoords', function(data, cb)
    coordsEnabled = not coordsEnabled
    
    if coordsEnabled then
        ShowCoords()
        QBCore.Functions.Notify('Coordinates display enabled', 'success')
    else
        QBCore.Functions.Notify('Coordinates display disabled', 'error')
    end
    
    cb('ok')
end)

function ShowCoords()
    CreateThread(function()
        while coordsEnabled do
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            
            -- Draw text on screen
            SetTextFont(4)
            SetTextProportional(1)
            SetTextScale(0.35, 0.35)
            SetTextColour(255, 255, 255, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString(string.format("X: %.2f Y: %.2f Z: %.2f H: %.2f", coords.x, coords.y, coords.z, heading))
            DrawText(0.40, 0.90)
            
            if not coordsEnabled then
                break
            end
            
            Wait(0)
        end
    end)
end

-- Delete Laser
RegisterNUICallback('toggleDeleteLaser', function(data, cb)
    deleteLaserEnabled = not deleteLaserEnabled
    
    if deleteLaserEnabled then
        StartDeleteLaser()
        QBCore.Functions.Notify('Delete laser enabled - Aim and press E to delete', 'success')
    else
        QBCore.Functions.Notify('Delete laser disabled', 'error')
        -- Hide entity info overlay when disabled
        SendNUIMessage({
            action = 'hideEntityInfo'
        })
    end
    
    cb('ok')
end)

function StartDeleteLaser()
    CreateThread(function()
        local ignoredEntity = nil  -- Track last deleted entity handle to skip stale raycast hits
        while deleteLaserEnabled do
            local ped = PlayerPedId()
            local pedCoords = GetEntityCoords(ped)
            
            -- Use camera direction instead of ped forward vector
            local camRot = GetGameplayCamRot(2)
            local camCoords = GetGameplayCamCoord()
            
            -- Convert rotation to direction vector
            local camDir = RotationToDirection(camRot)
            local destination = vector3(
                camCoords.x + camDir.x * 200.0,
                camCoords.y + camDir.y * 200.0,
                camCoords.z + camDir.z * 200.0
            )
            
            -- Raycast from camera
            local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, destination.x, destination.y, destination.z, -1, ped, 0)
            local _, hit, hitCoords, _, entity = GetShapeTestResult(rayHandle)
            
            if hit then
                -- Draw laser line to hit point
                DrawLine(camCoords.x, camCoords.y, camCoords.z, hitCoords.x, hitCoords.y, hitCoords.z, 255, 0, 0, 255)
                
                -- Check if we hit a valid entity (not world/ground)
                if entity and entity ~= 0 and entity ~= -1 and entity ~= ignoredEntity and DoesEntityExist(entity) and entity ~= ped then
                    -- Get entity type first to validate it's a real entity
                    local entityType = GetEntityType(entity)
                    
                    -- Only proceed if it's a valid entity type (1=Ped, 2=Vehicle, 3=Object)
                    if entityType > 0 and entityType <= 3 then
                        -- Draw target marker at hit point
                        DrawMarker(28, hitCoords.x, hitCoords.y, hitCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 0, 0, 150, false, true, 2, false, nil, nil, false)
                        -- New valid entity found — clear the ignored handle so it can be re-used if needed
                        if entity ~= ignoredEntity then ignoredEntity = nil end
                        
                        -- Get entity information
                        local entityModel = GetEntityModel(entity)
                        local entityCoords = GetEntityCoords(entity)
                        local entityHeading = GetEntityHeading(entity)
                        local isNetworked = NetworkGetEntityIsNetworked(entity)
                        local networkId = isNetworked and NetworkGetNetworkIdFromEntity(entity) or nil
                    
                    local typeStr = "Unknown"
                    if entityType == 1 then 
                        typeStr = "Ped"
                    elseif entityType == 2 then 
                        typeStr = "Vehicle"
                    elseif entityType == 3 then 
                        typeStr = "Object"
                    end
                    
                    -- Get model name if available
                    local modelName = GetDisplayNameFromVehicleModel(entityModel)
                    if modelName == 'CARNOTFOUND' or modelName == '' then
                        modelName = tostring(entityModel)
                    end
                    
                    -- Send entity info to NUI overlay
                    SendNUIMessage({
                        action = 'updateEntityInfo',
                        entityData = {
                            type = typeStr,
                            model = modelName,
                            hash = entityModel,
                            coords = {
                                x = entityCoords.x,
                                y = entityCoords.y,
                                z = entityCoords.z
                            },
                            heading = entityHeading,
                            netId = networkId
                        }
                    })
                    
                    -- C key to copy entity info
                    if IsControlJustPressed(0, 46) then -- C key
                        SendNUIMessage({
                            action = 'triggerCopyEntityInfo'
                        })
                    end
                    
                    -- Delete on E press
                    if IsControlJustPressed(0, 38) then -- E key
                        if DoesEntityExist(entity) then
                            if isNetworked then
                                -- Request network control before deleting
                                NetworkRequestControlOfEntity(entity)
                                local timeout = 0
                                while not NetworkHasControlOfEntity(entity) and timeout < 100 do
                                    Wait(10)
                                    timeout = timeout + 1
                                end
                            end
                            -- Take full mission ownership so the entity isn't re-managed by the engine
                            SetEntityAsMissionEntity(entity, true, true)
                            DeleteEntity(entity)
                            ignoredEntity = entity  -- Ignore this handle until entity is fully gone
                            QBCore.Functions.Notify('Entity deleted', 'success')
                            
                            SendNUIMessage({
                                action = 'hideEntityInfo'
                            })
                            Wait(500)  -- Wait longer for entity to fully clear from scene
                        end
                    end
                    else
                        -- Entity type is 0 or invalid - not a real entity
                        SendNUIMessage({
                            action = 'hideEntityInfo'
                        })
                    end
                else
                    -- Hit something but not a valid entity (world/ground) - hide overlay
                    SendNUIMessage({
                        action = 'hideEntityInfo'
                    })
                end
            else
                -- No hit at all - hide overlay
                SendNUIMessage({
                    action = 'hideEntityInfo'
                })
            end
            
            if not deleteLaserEnabled then
                break
            end
            
            Wait(0)
        end
    end)
end

-- Helper function to convert rotation to direction
function RotationToDirection(rotation)
    local adjustedRotation = vector3(
        (math.pi / 180) * rotation.x,
        (math.pi / 180) * rotation.y,
        (math.pi / 180) * rotation.z
    )
    local direction = vector3(
        -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.sin(adjustedRotation.x)
    )
    return direction
end

-- Entity Info
RegisterNUICallback('toggleEntityInfo', function(data, cb)
    entityInfoEnabled = not entityInfoEnabled
    
    if entityInfoEnabled then
        ShowEntityInfo()
        QBCore.Functions.Notify('Entity info enabled', 'success')
    else
        QBCore.Functions.Notify('Entity info disabled', 'error')
        -- Hide entity info overlay when disabled
        SendNUIMessage({
            action = 'hideEntityInfo'
        })
    end
    
    cb('ok')
end)

function ShowEntityInfo()
    CreateThread(function()
        while entityInfoEnabled do
            local ped = PlayerPedId()
            
            -- Use camera direction instead of ped forward vector
            local camRot = GetGameplayCamRot(2)
            local camCoords = GetGameplayCamCoord()
            
            -- Convert rotation to direction vector
            local camDir = RotationToDirection(camRot)
            local destination = vector3(
                camCoords.x + camDir.x * 50.0,
                camCoords.y + camDir.y * 50.0,
                camCoords.z + camDir.z * 50.0
            )
            
            -- Raycast from camera
            local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, destination.x, destination.y, destination.z, -1, ped, 0)
            local _, hit, hitCoords, _, entity = GetShapeTestResult(rayHandle)
            
            if hit and entity and entity ~= 0 and entity ~= -1 and DoesEntityExist(entity) and entity ~= ped then
                -- Get entity type first to validate it's a real entity
                local entityType = GetEntityType(entity)
                
                -- Only proceed if it's a valid entity type (1=Ped, 2=Vehicle, 3=Object)
                if entityType > 0 and entityType <= 3 then
                    local entityModel = GetEntityModel(entity)
                    local entityCoords = GetEntityCoords(entity)
                    local entityHeading = GetEntityHeading(entity)
                    local isNetworked = NetworkGetEntityIsNetworked(entity)
                    local networkId = isNetworked and NetworkGetNetworkIdFromEntity(entity) or nil
                    
                    local typeStr = "Unknown"
                    if entityType == 1 then 
                        typeStr = "Ped"
                    elseif entityType == 2 then 
                        typeStr = "Vehicle"
                    elseif entityType == 3 then 
                        typeStr = "Object"
                    end
                    
                    -- Get model name if available
                    local modelName = GetDisplayNameFromVehicleModel(entityModel)
                    if modelName == 'CARNOTFOUND' or modelName == '' then
                        modelName = tostring(entityModel)
                    end
                    
                    -- Draw visual indicator
                    DrawMarker(28, hitCoords.x, hitCoords.y, hitCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 0, 200, 255, 150, false, true, 2, false, nil, nil, false)
                    
                    -- Send entity info to NUI overlay
                    SendNUIMessage({
                        action = 'updateEntityInfo',
                        entityData = {
                            type = typeStr,
                            model = modelName,
                            hash = entityModel,
                            coords = {
                                x = entityCoords.x,
                                y = entityCoords.y,
                                z = entityCoords.z
                            },
                            heading = entityHeading,
                            netId = networkId
                        }
                    })
                else
                    -- Invalid entity type - hide overlay
                    SendNUIMessage({
                        action = 'hideEntityInfo'
                    })
                end
            else
                -- Hide entity info when not aiming at anything
                SendNUIMessage({
                    action = 'hideEntityInfo'
                })
            end
            
            if not entityInfoEnabled then
                break
            end
            
            Wait(0)
        end
    end)
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        local ped = PlayerPedId()
        
        -- Disable all tools
        if noclipEnabled then
            SetEntityVisible(ped, true, false)
            SetEntityInvincible(ped, false)
            SetEntityCollision(ped, true, true)
            FreezeEntityPosition(ped, false)
        end
        
        if godmodeEnabled then
            SetEntityInvincible(ped, false)
            SetPlayerInvincible(PlayerId(), false)
        end
        
        if invisibleEnabled then
            SetEntityVisible(ped, true, false)
        end
    end
end)
