local paths = {}
paths['PDevs'] = utils.get_appdata_path('PopstarDevs', '')
paths['Menu'] = paths['PDevs'] .. '\\2Take1Menu'
paths['ScriptsFolder'] = paths['Menu'] .. '\\scripts'
paths['2Take1Script'] = paths['ScriptsFolder'] .. '\\2Take1Script'
paths['ScriptData'] = paths['2Take1Script'] .. '\\Data'
paths['ScriptMapper'] = paths['2Take1Script'] .. '\\Mapper'
paths['ScriptFunctions'] = paths['2Take1Script'] .. '\\Functions'
paths['ScriptLogs'] = paths['2Take1Script'] .. '\\Logs'
paths['ScriptSettings'] = paths['2Take1Script'] .. '\\Settings'

local files = {}
files['PlayerInfo'] = paths['ScriptFunctions'] .. '\\PlayerInfo.lua'
files['Utils'] = paths['ScriptFunctions'] .. '\\Utils.lua'
files['Math'] = paths['ScriptFunctions'] .. '\\Math.lua'
files['Spawn'] = paths['ScriptFunctions'] .. '\\Spawn.lua'
files['Threads'] = paths['ScriptFunctions'] .. '\\Threads.lua'
files['CustomData'] = paths['ScriptData'] .. '\\CustomData.lua'
files['StringData'] = paths['ScriptData'] .. '\\StringData.lua'
files['ScriptEvents'] = paths['ScriptData'] .. '\\ScriptEvents.lua'
files['Modderflags'] = paths['ScriptData'] .. '\\Modderflags.lua'
files['Natives'] = paths['ScriptData'] .. '\\Natives.lua'
files['NetEventMapper'] = paths['ScriptMapper'] .. '\\NetEventMapper.lua'
files['ObjectMapper'] = paths['ScriptMapper'] .. '\\ObjectMapper.lua'
files['VehicleMapper'] = paths['ScriptMapper'] .. '\\VehicleMapper.lua'
files['PedMapper'] = paths['ScriptMapper'] .. '\\PedMapper.lua'
files['WeaponMapper'] = paths['ScriptMapper'] .. '\\WeaponMapper.lua'
files['WorldobjectMapper'] = paths['ScriptMapper'] .. '\\WorldobjectMapper.lua'
files['Dev'] = paths['2Take1Script'] .. '\\dev.lua'

local function Setup()
    math.randomseed(utils.time_ms())

    if not utils.dir_exists(paths['2Take1Script']) then
        print('2Take1Script folder not found...')
        menu.notify('2Take1Script folder not found...\nRedownload the script and make sure you got everything!', '2Take1Script Setup', 8, 0x0000FF)
        return false

    elseif not utils.dir_exists(paths['ScriptData']) then
        print('2Take1Script/Data folder not found...')
        menu.notify('2Take1Script/Data folder not found...\nRedownload the script and make sure you got everything!', '2Take1Script Setup', 8, 0x0000FF)
        return false

    elseif not utils.dir_exists(paths['ScriptFunctions']) then
        print('2Take1Script/Functions folder not found...')
        menu.notify('2Take1Script/Functions folder not found...\nRedownload the script and make sure you got everything!', '2Take1Script Setup', 8, 0x0000FF)
        return false
        
    elseif not utils.dir_exists(paths['ScriptMapper']) then
        print('2Take1Script/Mapper folder not found...')
        menu.notify('2Take1Script/Mapper folder not found...\nRedownload the script and make sure you got everything!', '2Take1Script Setup', 8, 0x0000FF)
        return false
    end

    local missing = 0
    local stuff = {
        'PlayerInfo',
        'Utils',
        'Math',
        'Spawn',
        'Threads',
        'CustomData',
        'StringData',
        'ScriptEvents',
        'Modderflags',
        'Natives',
        'NetEventMapper',
        'ObjectMapper',
        'PedMapper',
        'WeaponMapper',
        'WorldobjectMapper',
    }

    for i =  1, #stuff do
        if not utils.file_exists(files[stuff[i]]) then
            print(stuff[i] .. '.lua  is missing...')
            menu.notify(stuff[i] .. '.lua is missing...', '2Take1Script Setup', 8, 0x0000FF)
            missing = missing + 1
        end
    end

    if missing > 0 then
        return false
    end

    if not utils.dir_exists(paths['ScriptLogs']) then
        utils.make_dir(paths['2Take1Script'] .. "\\Logs")
    end

    if not utils.dir_exists(paths['ScriptSettings']) then
        utils.make_dir(paths['2Take1Script'] .. "\\Settings")
    end

    return true
end

if not Setup() then
    menu.notify("Failed to load 2Take1Script.", '2Take1Script Setup', 8, 0x0000FF)
    print('Failed to load 2Take1Script.')
    return
end

menu.create_thread(function()
    require('2Take1Script.main')

    coroutine.yield(100)

    if utils.file_exists(files['Dev']) then
        require('2Take1Script.dev')
    end
end, nil)