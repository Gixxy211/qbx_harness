local currentVehicle = nil
local harnessInstalled = false
local isWearingHarness = false
local harnessProgress = false

-- Function to check if player is in a valid vehicle
local function isInValidVehicle()
    local ped = cache.ped
    local vehicle = cache.vehicle
    
    if not vehicle then return false end
    
    -- Check if vehicle is valid (not a bike, bicycle, etc.)
    local vehicleClass = GetVehicleClass(vehicle)
    local invalidClasses = {
        8,  -- Motorcycles
        13, -- Bicycles
        14, -- Boats
        15, -- Helicopters
        16  -- Planes
    }
    
    for _, class in ipairs(invalidClasses) do
        if vehicleClass == class then
            return false
        end
    end
    
    return true
end

-- Install harness from inventory
RegisterNetEvent('harness:client:useHarness', function()
    local ped = cache.ped
    
    -- Check if in vehicle
    if not cache.vehicle then
        lib.notify({
            title = 'Harness',
            description = 'You must be in a vehicle to install a harness!',
            type = 'error'
        })
        return
    end
    
    -- Check if in valid vehicle
    if not isInValidVehicle() then
        lib.notify({
            title = 'Harness',
            description = 'You cannot install a harness in this type of vehicle!',
            type = 'error'
        })
        return
    end
    
    local vehicle = cache.vehicle
    local plate = GetVehicleNumberPlateText(vehicle):gsub("%s+", "")
    
    -- Check if harness already installed
    local hasHarness = lib.callback.await('harness:server:checkHarness', false, plate)
    
    if hasHarness then
        lib.notify({
            title = 'Harness',
            description = 'This vehicle already has a harness installed!',
            type = 'error'
        })
        return
    end
    
    -- Start installation progress
    local success = lib.progressCircle({
        duration = 5000,
        label = 'Installing Harness...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false
        },
        anim = {
            dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
            clip = 'machinic_loop_mechandplayer',
            flags = 16
        }
    })
    
    if success then
        -- Success
        TriggerServerEvent('harness:server:installHarness', plate, NetworkGetNetworkIdFromEntity(vehicle))
        
        lib.notify({
            title = 'Harness',
            description = 'Harness installed successfully!',
            type = 'success'
        })
    else
        -- Cancel
        lib.notify({
            title = 'Harness',
            description = 'Installation cancelled!',
            type = 'error'
        })
    end
end)

-- Put on harness (called when seatbelt is toggled ON)
local function putOnHarness()
    if harnessProgress then return end
    
    local ped = cache.ped
    local vehicle = cache.vehicle
    
    if not vehicle then
        lib.notify({
            title = 'Harness',
            description = 'You must be in a vehicle to use the harness!',
            type = 'error'
        })
        return false
    end
    
    if not harnessInstalled then
        -- No harness installed, let normal seatbelt handle it
        return false
    end
    
    harnessProgress = true
    
    local success = lib.progressCircle({
        duration = 2500,
        label = 'Putting on Racing Harness...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false
        },
        anim = {
            dict = 'mp_arresting',
            clip = 'a_uncuff',
            flags = 16
        }
    })
    
    if success then
        -- Success - harness is now on
        harnessProgress = false
        isWearingHarness = true
        
        -- Apply harness effects (enhanced seatbelt)
        SetPedConfigFlag(ped, 32, true) -- No fall damage
        SetPedCanBeKnockedOffVehicle(ped, 1) -- Harder to be knocked off
        SetPedCanRagdoll(ped, false)
        
        -- Add seatbelt sound effect
        TriggerServerEvent("InteractSound_SV:PlayOnSource", "buckle", 0.5)
        
        lib.notify({
            title = 'Harness',
            description = 'Racing harness secured!',
            type = 'success'
        })
        
        return true -- Harness handled the seatbelt
    else
        -- Cancel
        harnessProgress = false
        lib.notify({
            title = 'Harness',
            description = 'Harness cancelled!',
            type = 'error'
        })
        return false -- Let normal seatbelt handle it
    end
end

-- Take off harness (called when seatbelt is toggled OFF)
local function takeOffHarness()
    if harnessProgress then return end
    
    harnessProgress = true
    
    local success = lib.progressCircle({
        duration = 2000,
        label = 'Taking off Racing Harness...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false
        },
        anim = {
            dict = 'mp_arresting',
            clip = 'b_uncuff',
            flags = 16
        }
    })
    
    if success then
        -- Success - harness is now off
        harnessProgress = false
        isWearingHarness = false
        
        -- Remove harness effects
        local ped = cache.ped
        SetPedConfigFlag(ped, 32, false) -- Allow fall damage
        SetPedCanBeKnockedOffVehicle(ped, 2) -- Normal ejection
        SetPedCanRagdoll(ped, true)
        
        -- Add seatbelt sound effect
        TriggerServerEvent("InteractSound_SV:PlayOnSource", "unbuckle", 0.5)
        
        lib.notify({
            title = 'Harness',
            description = 'Harness removed!',
            type = 'success'
        })
        
        return true -- Harness handled removing
    else
        -- Cancel - keep harness on
        harnessProgress = false
        lib.notify({
            title = 'Harness',
            description = 'Harness removal cancelled!',
            type = 'error'
        })
        return false
    end
end

-- Override seatbelt toggle when harness is installed
local function overrideSeatbeltToggle()
    if not harnessInstalled or not currentVehicle then
        -- No harness installed, let normal seatbelt handle it
        return false
    end
    
    if isWearingHarness then
        -- Taking off harness (which also removes seatbelt)
        return takeOffHarness()
    else
        -- Putting on harness (which also acts as seatbelt)
        return putOnHarness()
    end
end

-- Check vehicle harness status
local function checkVehicleHarness()
    local vehicle = cache.vehicle
    
    if vehicle then
        local plate = GetVehicleNumberPlateText(vehicle):gsub("%s+", "")
        
        -- Check if vehicle has harness
        local hasHarness = lib.callback.await('harness:server:checkHarness', false, plate)
        
        if hasHarness then
            currentVehicle = vehicle
            harnessInstalled = true
            
            -- If wearing harness but switched to different vehicle with harness, keep it on
            if not isWearingHarness then
                lib.notify({
                    title = 'Harness',
                    description = 'This vehicle has a racing harness installed.',
                    type = 'inform',
                    duration = 3000
                })
            end
        else
            currentVehicle = nil
            harnessInstalled = false
            
            -- Remove harness effects if wearing (shouldn't happen but safety)
            if isWearingHarness then
                local ped = cache.ped
                isWearingHarness = false
                SetPedConfigFlag(ped, 32, false)
                SetPedCanBeKnockedOffVehicle(ped, 2)
                SetPedCanRagdoll(ped, true)
            end
        end
    else
        currentVehicle = nil
        harnessInstalled = false
        
        -- Remove harness effects if not in vehicle
        if isWearingHarness then
            local ped = cache.ped
            isWearingHarness = false
            SetPedConfigFlag(ped, 32, false)
            SetPedCanBeKnockedOffVehicle(ped, 2)
            SetPedCanRagdoll(ped, true)
        end
    end
end

-- Listen for seatbelt toggle events
RegisterNetEvent('seatbelt:client:ToggleSeatbelt', function()
    -- This event is triggered by the seatbelt system
    local wasHandled = overrideSeatbeltToggle()
    
    -- If harness handled it, cancel the normal seatbelt toggle
    if wasHandled then
        CancelEvent()
    end
end)

-- Thread to check vehicle changes
CreateThread(function()
    local lastVehicle = nil
    
    while true do
        Wait(1000)
        
        local vehicle = cache.vehicle
        
        -- Vehicle changed
        if vehicle ~= lastVehicle then
            lastVehicle = vehicle
            checkVehicleHarness()
        end
    end
end)

-- Handle vehicle damage with harness
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        
        if victim == cache.ped and isWearingHarness then
            -- Player with harness took damage
            if cache.vehicle then
                local vehicle = cache.vehicle
                
                -- Drastically reduce ejection force when harness is on
                SetVehicleEjectVelocity(vehicle, 2.0)
                
                -- Reduce damage by 50% when harness is on
                local currentHealth = GetEntityHealth(victim)
                SetEntityHealth(victim, currentHealth + 15)
                
                -- Restore ejection force after a moment
                CreateThread(function()
                    Wait(500)
                    SetVehicleEjectVelocity(vehicle, 45.0)
                end)
            end
        end
    end
end)

-- Export for other resources to check harness state
exports('IsWearingHarness', function()
    return isWearingHarness
end)

exports('HasHarnessInstalled', function()
    return harnessInstalled
end)

-- Register usable item
exports('useHarness', function()
    TriggerEvent('harness:client:useHarness')
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        local ped = cache.ped
        SetPedConfigFlag(ped, 32, false)
        SetPedCanBeKnockedOffVehicle(ped, 2)
        SetPedCanRagdoll(ped, true)
    end
end)

print('[harness] Client script loaded')