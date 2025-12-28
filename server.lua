local laptop = exports.fd_laptop

local function GetCharacterName(source)
    if GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        if QBCore then
            local Player = QBCore.Functions.GetPlayer(source)
            if Player and Player.PlayerData and Player.PlayerData.charinfo then
                return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
            end
        end
    end
    if GetResourceState('qbx_core') == 'started' then
    end
    
    -- Fallback
    return GetPlayerName(source) or ("Player " .. source)
end

-- Store for groups
---@type table<string, table>
local Groups = {}

-- Store player map for faster lookups: source -> groupId
local PlayerGroups = {}

-- Helper to find player's group
local function GetPlayerGroup(source)
    local groupId = PlayerGroups[source]
    if groupId and Groups[groupId] then
        return groupId, Groups[groupId]
    end
    return nil, nil
end

local function UpdateGroupUI(groupId)
    local group = Groups[groupId]
    if not group then return end
    
    for _, member in ipairs(group.members) do
        TriggerClientEvent('ferp_groups:updateUI', member.source, group)
    end
end

-- Create Group
local function CreateGroup(source)
    if PlayerGroups[source] then
        return false, "Already in a group"
    end

    local ownerName = GetCharacterName(source)
    local groupId = tostring(math.random(1000, 9999))
    
    -- Ensure unique ID
    while Groups[groupId] do
        groupId = tostring(math.random(1000, 9999))
    end

    Groups[groupId] = {
        id = groupId,
        ownerId = source,
        ownerName = ownerName,
        members = {
            { source = source, name = ownerName, isReady = false }
        },
        maxMembers = 6,
        state = 'assembling'
    }
    
    PlayerGroups[source] = groupId

    UpdateGroupUI(groupId)
    -- print(('[ferp_groups] Group Created: %s by %s'):format(groupId, ownerName))
    return true, groupId
end

-- Join Group
local function JoinGroup(source, groupId)
    if PlayerGroups[source] then
        return false, "Already in a group"
    end

    local group = Groups[groupId]
    if not group then
        return false, "Group not found"
    end

    if #group.members >= group.maxMembers then
        return false, "Group is full"
    end

    if group.state ~= 'assembling' then
        return false, "Activity already started"
    end

    table.insert(group.members, {
        source = source,
        name = GetCharacterName(source),
        isReady = false
    })

    PlayerGroups[source] = groupId

    UpdateGroupUI(groupId)
    return true
end

-- Leave Group
local function LeaveGroup(source)
    local groupId = PlayerGroups[source]
    if not groupId then return false, "Not in a group" end

    local group = Groups[groupId]
    if not group then
        PlayerGroups[source] = nil
        return false, "Group not found" 
    end

    -- Remove member from group
    for i, member in ipairs(group.members) do
        if member.source == source then
            table.remove(group.members, i)
            break
        end
    end

    -- Update player map
    PlayerGroups[source] = nil

    -- Handle Owner Leaving
    if group.ownerId == source then
        if #group.members > 0 then
            -- Promote new owner (first member in remaining list)
            local newOwner = group.members[1]
            group.ownerId = newOwner.source
            group.ownerName = newOwner.name
            
            -- Notify new owner and group
            TriggerClientEvent('ferp_groups:notification', newOwner.source, "You are now the group owner", 'success')
            UpdateGroupUI(groupId)
        else
            -- No members left, disband
            Groups[groupId] = nil
        end
    else
        -- Just a regular member left
        UpdateGroupUI(groupId)
    end

    -- Reset UI for the leaver
    TriggerClientEvent('ferp_groups:updateUI', source, nil)
    TriggerClientEvent('ferp_groups:notification', source, "Left Group", 'inform')

    return true
end

-- Kick Member
local function KickMember(source, targetSource)
    local groupId = PlayerGroups[source]
    local group = Groups[groupId]
    if not group then return end

    if group.ownerId ~= source then
        return false, "Not the owner"
    end

    if source == targetSource then
        return false, "Cannot kick yourself"
    end

    -- Find target in group
    local found = false
    for i, member in ipairs(group.members) do
        if member.source == targetSource then
            table.remove(group.members, i)
            found = true
            break
        end
    end

    if found then
        PlayerGroups[targetSource] = nil
        TriggerClientEvent('ferp_groups:kicked', targetSource)
        TriggerClientEvent('ferp_groups:updateUI', targetSource, nil)
        TriggerClientEvent('ferp_groups:notification', targetSource, "You were kicked from the group", 'error')
        UpdateGroupUI(groupId) 
        return true
    end

    return false, "Member not found"
end

-- Toggle Ready
local function ToggleReady(source)
    local groupId = PlayerGroups[source]
    local group = Groups[groupId]
    if not group then return end

    for _, member in ipairs(group.members) do
        if member.source == source then
            member.isReady = not member.isReady
            break
        end
    end

    UpdateGroupUI(groupId)
end

-- Start Activity
local function StartActivity(source)
    local groupId, group = GetPlayerGroup(source)
    if not group then return end

    if group.ownerId ~= source then
        return false, "Not the owner"
    end

    -- Check all ready
    for _, member in ipairs(group.members) do
        if not member.isReady then
            return false, "Not all members are ready"
        end
    end

    group.state = 'waiting'
    UpdateGroupUI(groupId)
    
    return true
end

-- Cancel Activity (Stop waiting)
local function CancelActivity(source)
    local groupId, group = GetPlayerGroup(source)
    if not group then return end

    if group.ownerId ~= source then
        return false, "Not the owner"
    end

    if group.state ~= 'waiting' and group.state ~= 'started' then
        return false, "Not waiting or working"
    end

    local wasStarted = group.state == 'started'
    group.state = 'assembling'
    group.job = nil
    group.statusText = nil
    
    if wasStarted then
        TriggerEvent('ferp_groups:activityCancelled', groupId, group)
    end
    
    UpdateGroupUI(groupId)
    return true
end

-- Start Group Job (Called by external scripts)
local function StartGroupJob(groupId, jobName)
    local group = Groups[groupId]
    if not group then return false, "Group not found" end
    
    if group.state ~= 'waiting' then
        return false, "Group is not waiting for a job"
    end

    group.state = 'started'
    group.job = jobName

    -- Trigger event for all members to start logic
    for _, member in ipairs(group.members) do
        TriggerClientEvent('ferp_groups:startActivity', member.source, groupId)
    end
    
    -- Trigger Server Event for other resources
    TriggerEvent('ferp_groups:activityStarted', groupId, group)
    
    UpdateGroupUI(groupId)
    return true
end

-- Finish Group Job request
local function FinishGroupJob(groupId)
    local group = Groups[groupId]
    if not group then return false, "Group not found" end
    
    group.state = 'waiting'
    group.job = nil
    group.statusText = nil
    
    UpdateGroupUI(groupId)
    return true
end

-- Set Group Status Text/Progress
local function SetGroupStatus(groupId, text)
    local group = Groups[groupId]
    if not group then return false end
    
    group.statusText = text
    UpdateGroupUI(groupId)
    return true
end

-- ==========================================
--              EXPORTS API
-- ==========================================

-- Get Group ID of a player
local function ExportGetPlayerGroup(source)
    return PlayerGroups[source]
end
exports('GetPlayerGroup', ExportGetPlayerGroup)

-- Get all members (sources) of a group
local function ExportGetGroupMembers(groupId)
    local group = Groups[groupId]
    if not group then return {} end
    
    local sources = {}
    for _, member in ipairs(group.members) do
        table.insert(sources, member.source)
    end
    return sources
end
exports('GetGroupMembers', ExportGetGroupMembers)

-- Get full group data
local function ExportGetGroupData(groupId)
    return Groups[groupId]
end
exports('GetGroupData', ExportGetGroupData)

-- Trigger a client event for all group members
local function ExportTriggerGroupEvent(groupId, eventName, ...)
    local group = Groups[groupId]
    if not group then return false end
    
    for _, member in ipairs(group.members) do
        TriggerClientEvent(eventName, member.source, ...)
    end
    return true
end
exports('TriggerGroupEvent', ExportTriggerGroupEvent)

-- Send notification to all group members
local function ExportNotifyGroup(groupId, message, type)
    local group = Groups[groupId]
    if not group then return false end
    
    for _, member in ipairs(group.members) do
        TriggerClientEvent('ferp_groups:notification', member.source, message, type or 'success')
    end
    return true
end
exports('NotifyGroup', ExportNotifyGroup)

-- Start a job for the group
exports('StartGroupJob', StartGroupJob)
exports('FinishGroupJob', FinishGroupJob)
exports('SetGroupStatus', SetGroupStatus)

-- ==========================================
--              NET EVENTS
-- ==========================================

RegisterNetEvent('ferp_groups:createGroup', function()
    local src = source
    local success, msg = CreateGroup(src)
    TriggerClientEvent('ferp_groups:notification', src, success and "Group Created" or msg)
end)

RegisterNetEvent('ferp_groups:joinGroup', function(filterName)
    local src = source
    
    if not filterName or filterName == "" then
        TriggerClientEvent('ferp_groups:notification', src, "Please enter a name")
        return
    end

    local foundGroupId = nil

    -- Check if it matches an ID directly
    if Groups[filterName] then
        foundGroupId = filterName
    else
        -- Search by Name
        local filter = string.lower(filterName)
        for groupId, group in pairs(Groups) do
            if string.find(string.lower(group.ownerName), filter) then
                foundGroupId = groupId
                break
            end
        end
    end

    if foundGroupId then
        local success, msg = JoinGroup(src, foundGroupId)
        TriggerClientEvent('ferp_groups:notification', src, success and "Joined Group" or msg)
    else
        TriggerClientEvent('ferp_groups:notification', src, "Group not found")
    end
end)

RegisterNetEvent('ferp_groups:leaveGroup', function()
    local src = source
    LeaveGroup(src)
end)

RegisterNetEvent('ferp_groups:kickMember', function(targetSrc)
    local src = source
    local target = tonumber(targetSrc)
    local success, msg = KickMember(src, target)
    if not success then
        TriggerClientEvent('ferp_groups:notification', src, msg or "Failed to kick")
    else
        TriggerClientEvent('ferp_groups:notification', src, "Member kicked")
    end
end)

RegisterNetEvent('ferp_groups:toggleReady', function()
    local src = source
    ToggleReady(src)
end)

RegisterNetEvent('ferp_groups:startGame', function()
    local src = source
    local success, msg = StartActivity(src)
    if not success then
         TriggerClientEvent('ferp_groups:notification', src, msg)
    end
end)

RegisterNetEvent('ferp_groups:cancelActivity', function()
    local src = source
    local success, msg = CancelActivity(src)
    if not success then
         TriggerClientEvent('ferp_groups:notification', src, msg)
    end
end)

-- Cancel a group job externally
local function ExportCancelGroupActivity(groupId)
    local group = Groups[groupId]
    if not group then return false end
    
    local wasStarted = group.state == 'started'
    group.state = 'assembling'
    group.job = nil
    group.statusText = nil
    
    if wasStarted then
        TriggerEvent('ferp_groups:activityCancelled', groupId, group)
    end
    
    UpdateGroupUI(groupId)
    return true
end
exports('CancelGroupActivity', ExportCancelGroupActivity)

-- Initial Sync
RegisterNetEvent('ferp_groups:requestState', function()
    local src = source
    local groupId = PlayerGroups[src]
    if groupId then
        TriggerClientEvent('ferp_groups:updateUI', src, Groups[groupId])
    end
end)


-- Register App with fd_laptop
    CreateThread(function()
        while GetResourceState('fd_laptop') ~= 'started' do 
            Wait(500) 
        end
    local success, error = exports.fd_laptop:addCustomApp({
        id = 'ferp_groups',
        name = 'Groups',
        icon = 'users',
        ui = 'https://cfx-nui-ferp_groups/web/dist/index.html',
        label = 'Groups',
        category = 'social',
        isDefaultApp = false,
        appstore = {
            description = 'Create and manage groups for various activities.',
            author = 'System',
            installTime = 2000
        }
    })

    if not success then
        print('Failed to register ferp_groups app:', error)
    else
        print('ferp_groups app registered successfully')
    end
end)
