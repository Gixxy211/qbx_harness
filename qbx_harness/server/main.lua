-- VEHICLE OWNERSHIP CHECK
local function isVehicleOwned(plate)
    if Config.npFakePlate then
        local hasFakePlate = exports['np-fakeplates']:getPlateFromFakePlate(plate)
        if hasFakePlate then plate = hasFakePlate end
        Wait(100)
    end

    local result = MySQL.scalar.await(
        'SELECT plate FROM player_vehicles WHERE plate = ?',
        { plate }
    )

    return result and true or false
end


-- HARNESS CHECK
local function hasHarness(plate)
    if Config.npFakePlate then
        local hasFakePlate = exports['np-fakeplates']:getPlateFromFakePlate(plate)
        if hasFakePlate then plate = hasFakePlate end
        Wait(100)
    end

    local result = MySQL.scalar.await(
        'SELECT harness FROM player_vehicles WHERE plate = ?',
        { plate }
    )

    return result and true or false
end


-- ATTACH HARNESS
RegisterNetEvent('qbx_harness:server:attachHarness', function(plate, ItemData)
    local src = source
    if not src or not plate then return end

    if not isVehicleOwned(plate) then
        return TriggerClientEvent('seatbelt:client:UseHarness', src, ItemData, true)
    end

    if Config.UninstallHarnessWithItem and hasHarness(plate) then
        return TriggerClientEvent('qbx_harness:client:installHarness', src, plate, 'uninstall')
    end

    TriggerClientEvent('qbx_harness:client:installHarness', src, plate, 'install')
end)


-- INSTALL / UNINSTALL
RegisterNetEvent('qbx_harness:server:installHarness', function(plate, action)
    local src = source
    if not src or not plate or not action then return end

    if Config.npFakePlate then
        local hasFakePlate = exports['np-fakeplates']:getPlateFromFakePlate(plate)
        if hasFakePlate then plate = hasFakePlate end
        Wait(100)
    end

    if action == 'install' then
        exports.ox_inventory:RemoveItem(src, Config.Harness, 1)

        MySQL.update(
            'UPDATE player_vehicles SET harness = ? WHERE plate = ?',
            { true, plate }
        )

    elseif action == 'uninstall' then
        if not hasHarness(plate) then
            return TriggerClientEvent('ox_lib:notify', src, {
                description = Lang:t("error.no_harness"),
                type = "error"
            })
        end

        exports.ox_inventory:AddItem(src, Config.Harness, 1)

        -- ?? FIXED: write 0 instead of NULL
        MySQL.update(
            'UPDATE player_vehicles SET harness = ? WHERE plate = ?',
            { 0, plate }
        )
    end
end)


-- FORCE UNINSTALL (DB ONLY)
RegisterNetEvent('qbx_harness:server:uninstallHarness', function(plate)
    local src = source
    if not src or not plate then return end

    if Config.npFakePlate then
        local hasFakePlate = exports['np-fakeplates']:getPlateFromFakePlate(plate)
        if hasFakePlate then plate = hasFakePlate end
        Wait(100)
    end

    -- ?? FIXED: write 0 instead of NULL
    MySQL.update(
        'UPDATE player_vehicles SET harness = ? WHERE plate = ?',
        { 0, plate }
    )
end)


-- TOGGLE BELT
RegisterNetEvent('qbx_harness:server:toggleBelt', function(plate, ItemData)
    local src = source
    if not src then return end

    if not hasHarness(plate) then
        return TriggerClientEvent('seatbelt:client:UseSeatbelt', src)
    end

    TriggerClientEvent('seatbelt:client:UseHarness', src, ItemData, false)
end)
