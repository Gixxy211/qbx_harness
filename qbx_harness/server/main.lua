local harnessVehicles = {}

-- Load harness data on server start
CreateThread(function()
    Wait(1000)
    
    local result = MySQL.query.await('SELECT * FROM vehicle_harnesses WHERE installed = 1')
    
    if result then
        for _, data in ipairs(result) do
            harnessVehicles[data.plate] = true
        end
    end
    
    print('[harness] Loaded ' .. #result .. ' harness installations')
end)

-- Check if vehicle has harness
lib.callback.register('harness:server:checkHarness', function(source, plate)
    if not plate then return false end
    return harnessVehicles[plate] == true
end)

-- Install harness to vehicle
RegisterNetEvent('harness:server:installHarness', function(plate, vehicleNetId)
    local src = source
    
    if not plate then
        lib.notify(src, {
            title = 'Harness',
            description = 'Invalid vehicle!',
            type = 'error'
        })
        return
    end
    
    -- Check if player has harness
    local hasHarness = exports.ox_inventory:Search(src, 'count', 'harness') or 0
    
    if hasHarness < 1 then
        lib.notify(src, {
            title = 'Harness',
            description = 'You don\'t have a harness!',
            type = 'error'
        })
        return
    end
    
    -- Check if vehicle already has harness
    if harnessVehicles[plate] then
        lib.notify(src, {
            title = 'Harness',
            description = 'This vehicle already has a harness!',
            type = 'error'
        })
        return
    end
    
    -- Remove harness from player
    local success = exports.ox_inventory:RemoveItem(src, 'harness', 1)
    
    if not success then
        lib.notify(src, {
            title = 'Harness',
            description = 'Failed to remove harness!',
            type = 'error'
        })
        return
    end
    
    -- Save to database
    MySQL.insert('INSERT INTO vehicle_harnesses (plate, installed) VALUES (?, 1) ON DUPLICATE KEY UPDATE installed = 1', {plate}, function()
        harnessVehicles[plate] = true
        
        -- Notify client
        TriggerClientEvent('harness:client:harnessInstalled', src, vehicleNetId)
        
        lib.notify(src, {
            title = 'Harness',
            description = 'Harness installed successfully!',
            type = 'success'
        })
    end)
end)

-- Remove harness from vehicle
RegisterNetEvent('harness:server:removeHarness', function(plate)
    local src = source
    
    if not plate then return end
    
    -- Check if vehicle has harness
    if not harnessVehicles[plate] then
        lib.notify(src, {
            title = 'Harness',
            description = 'This vehicle doesn\'t have a harness!',
            type = 'error'
        })
        return
    end
    
    -- Add harness back to player
    local canCarry = exports.ox_inventory:CanCarryItem(src, 'harness', 1)
    
    if canCarry then
        exports.ox_inventory:AddItem(src, 'harness', 1)
        
        -- Remove from database
        MySQL.update('DELETE FROM vehicle_harnesses WHERE plate = ?', {plate}, function()
            harnessVehicles[plate] = nil
            
            lib.notify(src, {
                title = 'Harness',
                description = 'Harness removed from vehicle!',
                type = 'success'
            })
        end)
    else
        lib.notify(src, {
            title = 'Harness',
            description = 'Not enough inventory space!',
            type = 'error'
        })
    end
end)

-- Get all harness data
lib.callback.register('harness:server:getAllHarnesses', function(source)
    return harnessVehicles
end)

-- Register usable item
exports.ox_inventory:registerHook('useItem', function(payload)
    if payload.item.name == 'harness' then
        TriggerClientEvent('harness:client:useHarness', payload.source)
        return false -- Prevent default use
    end
end)

print('[harness] Server script loaded')