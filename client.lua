local function ToggleApp(isOpen)
    SetNuiFocus(isOpen, isOpen)
    if isOpen then
        TriggerServerEvent('ferp_groups:requestState')
    end
end

-- Listen for UI events from React
RegisterNUICallback('createGroup', function(_, cb)
    TriggerServerEvent('ferp_groups:createGroup')
    cb(1)
end)

RegisterNUICallback('joinGroup', function(data, cb)
    TriggerServerEvent('ferp_groups:joinGroup', data.filterName)
    cb(1)
end)

RegisterNUICallback('leaveGroup', function(_, cb)
    TriggerServerEvent('ferp_groups:leaveGroup')
    cb(1)
end)

RegisterNUICallback('kickMember', function(data, cb)
    TriggerServerEvent('ferp_groups:kickMember', data.targetSource)
    cb(1)
end)

RegisterNUICallback('toggleReady', function(_, cb)
    TriggerServerEvent('ferp_groups:toggleReady')
    cb(1)
end)

RegisterNUICallback('startGame', function(_, cb)
    TriggerServerEvent('ferp_groups:startGame')
    cb(1)
end)

RegisterNUICallback('cancelActivity', function(_, cb)
    TriggerServerEvent('ferp_groups:cancelActivity')
    cb(1)
end)

RegisterNUICallback('hideFrame', function(_, cb)
    -- If the app has a close button that minimizes it
    -- exports.fd_laptop:closeApp('ferp_groups') -- Optional if needed
    cb(1)
end)

-- Receive updates from Server
RegisterNetEvent('ferp_groups:updateUI', function(groupData)
    -- print('[ferp_groups] Client received updateUI. Data:', json.encode(groupData))
    -- Use fd_laptop export to target the app iframe
    local status, err = pcall(function()
        exports.fd_laptop:sendAppMessage('ferp_groups', {
            action = 'updateGroup',
            data = {
                group = groupData,
                myId = GetPlayerServerId(PlayerId())
            }
        })
    end)
    if not status then
        print('[ferp_groups] ERROR sending app message:', err)
    else
        print('[ferp_groups] Export sent successfully')
    end
end)

RegisterNetEvent('ferp_groups:notification', function(msg, type)
    -- Using laptop notification system directly
    local notifType = 'inform'
    if type == 'error' then notifType = 'error' end
    if type == 'success' then notifType = 'success' end

    exports.fd_laptop:sendNotification({
        title = 'Groups',
        message = msg,
        type = notifType,
        app = 'ferp_groups',
        icon = 'users'
    })
end)

RegisterNetEvent('ferp_groups:startActivity', function(groupId)
    local status, err = pcall(function()
        exports.fd_laptop:sendAppMessage('ferp_groups', {
            action = 'activityStarted',
            data = groupId
        })
    end)
    if not status then
        print('[ferp_groups] ERROR sending activityStarted message:', err)
    end
    print('Activity Started for Group: ' .. groupId)
end)

RegisterNetEvent('ferp_groups:kicked', function()
end)
