local function Notify(msg, type)
    lib.notify({
        description = msg,
        type = type or 'inform'
    })
end

local function validateClass()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then return nil end

    local plate = GetVehicleNumberPlateText(vehicle)
    local class = GetVehicleClass(vehicle)

    -- Motorcycle (8), Cycles (13), Boats (14)
    if class ~= 8 and class ~= 13 and class ~= 14 then
        return plate
    end

    return nil
end

-- ATTACH HARNESS ITEM USE
RegisterNetEvent("qbx_harness:client:attachHarness", function(ItemData)
    local ped = PlayerPedId()

    if not IsPedInAnyVehicle(ped, false) then
        return Notify(Lang:t("error.not_in_vehicle"), "error")
    end

    local plate = validateClass()
    if not plate then
        return Notify(Lang:t("error.wrong_class"), "error")
    end

    TriggerServerEvent('qbx_harness:server:attachHarness', plate, ItemData)
end)

-- INSTALL / UNINSTALL HARNESS
RegisterNetEvent('qbx_harness:client:installHarness', function(plate, action)
    local label = 'Installing Harness'
    if action == 'uninstall' then
        label = 'Uninstalling Harness'
    end

    local success = lib.progressBar({
        duration = Config.InstallTime,
        label = label,
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        }
    })

    if not success then
        return Notify(Lang:t("error.canceled_installation"), "error")
    end

    TriggerServerEvent("qbx_harness:server:installHarness", plate, action)
end)
