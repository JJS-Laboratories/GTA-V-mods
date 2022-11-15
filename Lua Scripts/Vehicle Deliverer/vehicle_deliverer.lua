print("Vehicle Deliver mod initialized")
keys = require("Keys")

blip_list = {}

function log(text)
    print("[Vehicle Deliver] > "..text)
end

JM36.CreateThread(function()

    --[[ (Optionally) Localize the print function for faster access ]]
    local print = print

    local saved_vehicle = 0

    local saved_blip

    --[[ (Optionally) print something ]]
    log("Hello World!")
    print(" ")
    print("----------=====----------")
    print(" ")

    --[[ (Optionally) Make sure that our script/module will continue to loop/run forever (instead of just once) with a `while true do` loop ]]
    while true do
        if GetPauseMenuState() == 0 then
            if IsKeyPressed(keys.F11) then
                if f11_toggle then
                    if IsKeyPressed(keys.LControlKey) then
                        local player = GetPlayerPed(-1)
                        local current_vehicle = GetVehiclePedIsUsing(player)
                        saved_vehicle = current_vehicle

                        if saved_vehicle == 0 then
                            saved_vehicle = GetVehiclePedIsIn(player,true)
                        end

                        if saved_vehicle ~= 0 then
                            SetEntityAsMissionEntity(saved_vehicle,true,true)

                            if saved_blip ~= 0 and saved_blip ~= nil then
                                RemoveBlip(saved_blip)
                            end

                            saved_blip = AddBlipForEntity(saved_vehicle)
                            SetBlipSprite(saved_blip,225)
                            SetBlipNameToPlayerName(saved_blip,player)
                            table.insert(blip_list,saved_blip)

                            BeginTextCommandThefeedPost("STRING")
                            AddTextComponentSubstringPlayerName("Vehicle successfully saved!")
                            EndTextCommandThefeedPostTicker(true, true)
                            log("Saved Vehicle\n\n----------=====----------\n")
                        end
                        f11_toggle = false
                    else
                        local vehicle_prefix = "last"
                        local player = GetPlayerPed(-1)
                        local playerpos = GetEntityCoords(player,false)
                        local last_vehicle = GetVehiclePedIsIn(player,true)

                        if IsKeyPressed(keys.LShiftKey) then
                            if saved_vehicle ~= 0 then
                                last_vehicle = saved_vehicle
                                vehicle_prefix = "saved"
                            end
                        end

                        SetEntityAsMissionEntity(last_vehicle,true,true)
                        
                        RequestModel(988062523)
                        RequestModel(-1848994066)

                        local vehicle_coord = GetEntityCoords(last_vehicle,false)

                        BeginTextCommandThefeedPost("STRING")
                        AddTextComponentSubstringPlayerName("Hello " .. GetPlayerName(PlayerId()) .. ". Bringing your "..vehicle_prefix.." vehicle now! Distance is "..string.format("%.2f",(CalculateTravelDistanceBetweenPoints(
                            playerpos.x,
                            playerpos.y,
                            playerpos.z,
                            vehicle_coord.x,
                            vehicle_coord.y,
                            vehicle_coord.z
                        )/1000)).." km")
                        EndTextCommandThefeedPostTicker(true, true)

                        log("Delivering "..vehicle_prefix.." vehicle")
                        log("Distance: "..string.format("%.4f",(CalculateTravelDistanceBetweenPoints(
                            playerpos.x,
                            playerpos.y,
                            playerpos.z,
                            vehicle_coord.x,
                            vehicle_coord.y,
                            vehicle_coord.z
                        )/1000)).." km")

                        local driver_ped = CreatePedInsideVehicle(last_vehicle,1,988062523,-1,true,true)
                        SetEntityAsMissionEntity(driver_ped,true,true)
                        GiveWeaponToPed(driver_ped,-538741184,100,true,false)
                        SetPedCanSwitchWeapon(driver_ped,false)

                        local vehicle_blip = AddBlipForEntity(last_vehicle)
                        SetBlipSprite(vehicle_blip,225)


                        local dest_blip = AddBlipForRadius(playerpos.x, playerpos.y, playerpos.z ,15)
                        SetBlipColour(dest_blip, 57)
                        SetBlipAlpha(dest_blip, 128)

                        table.insert(blip_list,vehicle_blip)
                        table.insert(blip_list,dest_blip)

                        TaskVehicleDriveToCoordLongrange(driver_ped, last_vehicle, playerpos.x, playerpos.y, playerpos.z, 30, 5, 10)

                        local failed = false

                        local enter_fails = 0
                        local enter_success = 600

                        local fail_reason = ""
                        
                        while true do
                            local vehiclepos = GetEntityCoords(last_vehicle,false)
                            local dist_x = math.abs(playerpos.x - vehiclepos.x)
                            local dist_y = math.abs(playerpos.y - vehiclepos.y)
                            local dist_z = math.abs(playerpos.z - vehiclepos.z)
                            local dist_full = dist_x+dist_y

                            if dist_full < 20 then
                                break
                            end

                            if IsEntityDead(driver_ped) or enter_fails > 10 then
                                RemoveBlip(dest_blip)
                                RemoveBlip(vehicle_blip)
                                failed = true
                                JM36.yield(1000)
                                drived_ped = DeletePed(driver_ped)
                                if enter_fails > 10 then
                                    fail_reason = "Unable to enter vehicle."
                                end
                                break
                            end

                            local road_distance = string.format("%.2f",(CalculateTravelDistanceBetweenPoints(
                                playerpos.x,
                                playerpos.y,
                                playerpos.z,
                                vehiclepos.x,
                                vehiclepos.y,
                                vehiclepos.z
                            )/1000))

                            if GetVehiclePedIsUsing(driver_ped) ~= last_vehicle then
                                log("Fell out of vehicle!")
                                enter_success = 0
                                TaskEnterVehicle(
                                    driver_ped,
                                    last_vehicle,
                                    10000,
                                    -1,
                                    2,
                                    1,
                                    0
                                )
                                repeat
                                    log("Trying to enter vehicle")
                                    enter_fails = enter_fails+1
                                    local driver_ped_vehicle = GetVehiclePedIsUsing(driver_ped)
                                    if enter_fails == 6 then
                                        log("Changed vehicle rotation to be correct")
                                        SetEntityCoords(last_vehicle, vehiclepos.x, vehiclepos.y, vehiclepos.z+1, false, true, false, false)
                                        SetEntityRotation(last_vehicle,0,0,0,0,true)
                                    end
                                    JM36.yield(1000)
                                until driver_ped_vehicle == last_vehicle or IsEntityDead(driver_ped) or enter_fails > 10
                                TaskVehicleDriveToCoordLongrange(driver_ped, last_vehicle, playerpos.x, playerpos.y, playerpos.z, 30, 5, 10)
                            else
                                if enter_success < 600 then
                                    enter_success = enter_success+1
                                elseif enter_fails ~= 0 then
                                    log("Successfully got back in vehicle!")
                                    enter_fails = 0
                                end
                            end
                            DrawRect(
                                0.1645+(0.1911/2),
                                0.9388+(0.0277/2),
                                0.1911,
                                0.0277,
                                25,
                                26,
                                25,
                                128
                            )

                            BeginTextCommandDisplayText("STRING")
                            SetTextScale(0.4,0.4)
                            AddTextComponentSubstringPlayerName(vehicle_prefix.." vehicle distance: "..road_distance.." km")
                            EndTextCommandDisplayText(0.166,0.937)

                            JM36.yield()
                        end

                        if not failed then
                            log("Successfully delivered vehicle!")
                            RemoveBlip(dest_blip)

                            SetVehicleFixed(last_vehicle)
                            TaskLeaveVehicle(driver_ped,last_vehicle,256)

                            repeat
                                local driver_ped_vehicle = GetVehiclePedIsUsing(driver_ped)
                                JM36.yield(1000)
                            until driver_ped_vehicle == 0

                            if IsVehicleAConvertible(last_vehicle,false) then
                                RaiseConvertibleRoof(
                                    last_vehicle,
                                    false
                                )
                            end

                            TaskSmartFleePed(driver_ped,player,120,4000,true,true)
                            RemoveBlip(vehicle_blip)

                            JM36.yield(1000)

                            JM36.yield(3000)

                            local driver_pos = GetEntityCoords(driver_ped,true)

                            local escape_vehicle_rng = math.random(0,100)
                            local escape_vehicle = 1489874736
                            if escape_vehicle_rng > 50 then
                                escape_vehicle = -1984275979
                            end


                            RequestModel(escape_vehicle)
                            JM36.yield(100)

                            log("Driver Escaping")

                            local driver_vehicle = CreateVehicle(
                                escape_vehicle,
                                driver_pos.x,
                                driver_pos.y,
                                driver_pos.z,
                                0,
                                true,
                                false
                            )
                            SetVehicleWindowTint(driver_vehicle,1)
                            SetVehicleColours(driver_vehicle,2,70)

                            -- local pilot_ped = CreatePedInsideVehicle(driver_vehicle,1,988062523,-1,false,true)

                            TaskEnterVehicle(
                                driver_ped,
                                driver_vehicle,
                                10000,
                                -1,
                                2,
                                16,
                                0
                            )
                            local escape_failed = false
                            repeat
                                local isInVehicle = GetVehiclePedIsIn(driver_ped,false)
                                if IsEntityDead(driver_ped) then
                                    escape_failed = true
                                    driver_ped = DeletePed(driver_ped)
                                    driver_vehicle = DeleteEntity(driver_vehicle)
                                    log("Escape failed: Dead\n\n----------=====----------\n")
                                    break
                                end
                                JM36.yield()
                            until isInVehicle == driver_vehicle

                            if not escape_failed then
                                JM36.yield(200)
                                SetVehicleMod(driver_vehicle,10,0,false)

                                -- TaskVehicleDriveWander(
                                --     pilot_ped,
                                --     driver_vehicle,
                                --     40,
                                --     44
                                -- )
                                local driver_pos = GetEntityCoords(driver_ped,true)
                                TaskHeliMission(
                                    driver_ped,
                                    driver_vehicle,
                                    0,
                                    0,
                                    driver_pos.x+800,
                                    driver_pos.y+800,
                                    driver_pos.z+100,
                                    4,
                                    20,
                                    -1,
                                    -1,
                                    10,
                                    10,
                                    5.0,
                                    0
                                )
                                JM36.CreateThread(function()
                                    local player = GetPlayerPed(-1)
                                    while true do
                                        local vehiclepos = GetEntityCoords(driver_vehicle,false)
                                        local playerpos = GetEntityCoords(player,false)

                                        local dist_x = math.abs(playerpos.x - vehiclepos.x)
                                        local dist_y = math.abs(playerpos.y - vehiclepos.y)
                                        local dist_z = math.abs(playerpos.z - vehiclepos.z)

                                        local dist_full = dist_x+dist_y+dist_z

                                        if dist_full > 1000 then
                                            log("Escape success!\n\n----------=====----------\n")
                                            driver_ped = DeletePed(driver_ped)
                                            -- pilot_ped = DeletePed(pilot_ped)
                                            driver_vehicle = DeleteEntity(driver_vehicle)
                                            break
                                        end

                                        if IsEntityDead(driver_ped) then
                                            log("Escape failed: Dead\n\n----------=====----------\n")
                                            JM36.yield(5000)
                                            driver_ped = DeletePed(driver_ped)
                                            -- pilot_ped = DeletePed(pilot_ped)
                                            driver_vehicle = DeleteEntity(driver_vehicle)
                                            break
                                        end
                                        JM36.yield()
                                    end
                                end)
                            end

                        else
                            log("Failed to deliver!")
                            BeginTextCommandThefeedPost("STRING")
                            AddTextComponentSubstringPlayerName("Failed to deliver vehicle!")
                            EndTextCommandThefeedPostTicker(true, true)
                            if fail_reason ~= "" then
                                log("Reason: "..fail_reason)
                                BeginTextCommandThefeedPost("STRING")
                                AddTextComponentSubstringPlayerName("Reason: "..fail_reason)
                                EndTextCommandThefeedPostTicker(true, true)
                            end
                        end
                    end
                    
                    f11_toggle = false
                end
            else
                f11_toggle = true
            end
            -- if IsKeyPressed(keys.NumPad0) then
            --     if num0_toggle then
            --         num0_toggle = false
            --     end
            -- else
            --     num0_toggle = true
            -- end
        end
        JM36.yield()
    end

    --[[ (Optionally) print something, except this'll never run unless you `break` out of the `while true do` loop ]]
    log("Hello World! This will run never.")

end)

function unload()
    for k,v in pairs(blip_list) do
        RemoveBlip(v)
    end
end