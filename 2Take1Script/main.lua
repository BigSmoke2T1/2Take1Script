local Version = "2.7.0"

local paths = {}
paths['PDevs'] = utils.get_appdata_path('PopstarDevs', '')
paths['Menu'] = paths['PDevs'] .. '\\2Take1Menu'
paths['ModdedOutfits'] = paths['Menu'] .. '\\moddedOutfits'
paths['ModdedVehicles'] = paths['Menu'] .. '\\moddedVehicles'
paths['ConfigFolder'] = paths['Menu'] .. '\\cfg'
paths['ScriptsFolder'] = paths['Menu'] .. '\\scripts'
paths['2Take1Script'] = paths['ScriptsFolder'] .. '\\2Take1Script'
paths['ScriptData'] = paths['2Take1Script'] .. '\\Data'
paths['ScriptMapper'] = paths['2Take1Script'] .. '\\Mapper'
paths['ScriptFunctions'] = paths['2Take1Script'] .. '\\Functions'
paths['ScriptLogs'] = paths['2Take1Script'] .. '\\Logs'
paths['ScriptSettings'] = paths['2Take1Script'] .. '\\Settings'
paths['Event-Logger'] = paths['2Take1Script'] .. '\\Event-Logger'

local files = {}
files['MenuMainLog'] = paths['Menu'] .. '\\2Take1Menu.log'
files['MenuPrepLog'] = paths['Menu'] .. '\\2Take1Prep.log'
files['MenuNetLog'] = paths['Menu'] .. '\\net_event.log'
files['MenuNotifLog'] = paths['Menu'] .. '\\notification.log'
files['MenuPlayerLog'] = paths['Menu'] .. '\\player.log'
files['MenuScriptLog'] = paths['Menu'] .. '\\script_event.log'
files['MainLog'] = paths['ScriptLogs'] .. '\\2Take1Script.log'
files['ChatLog'] = paths['ScriptLogs'] .. '\\Chat.log'
files['Modder'] = paths['ScriptLogs'] .. '\\Modder.cfg'
files['Blacklist'] = paths['ScriptLogs'] .. '\\blacklist.cfg'
files['FakeFriends'] = paths['ConfigFolder'] .. '\\scid.cfg'
files['DefaultConfig'] = paths['ScriptSettings'] .. '\\Default.ini'

local settings = {['2Take1Script Parent'] = {Enabled = true}, ['Enable Vehicle Spawner'] = {Enabled = false}}
local customflags = require('2Take1Script.Data.Modderflags')
local setup = {}
local get = require('2Take1Script.Functions.PlayerInfo')
local utility = require('2Take1Script.Functions.Utils')
local Math = require('2Take1Script.Functions.Math')
local Spawn = require('2Take1Script.Functions.Spawn')
local Threads = require('2Take1Script.Functions.Threads')
local customData = require('2Take1Script.Data.CustomData')
local stringData = require('2Take1Script.Data.StringData')
local scriptevent = require('2Take1Script.Data.ScriptEvents')
local N = require('2Take1Script.Data.Natives')
local mapper = {
    net = require('2Take1Script.Mapper.NetEventMapper'),
    ped = require('2Take1Script.Mapper.PedMapper'),
    veh = require('2Take1Script.Mapper.VehicleMapper'),
    obj = require('2Take1Script.Mapper.ObjectMapper'),
    world = require('2Take1Script.Mapper.WorldObjectMapper'),
    weapons = require('2Take1Script.Mapper.WeaponMapper')
}

local Script = {
    Parent = {},
    Feature = {},
    PlayerFeature = {}
}

local function IsFeatOn(f)
    if not f or not Script.Feature[f] then
        return false
    end

    return Script.Feature[f].on
end


local function NotifColor(Version)
    local NotificationColors = {0x00FF00, 0x00A2FF, 0x0000FF, 0xFF0000, 0x6C3570, 0x0062FF, 0xCCFF00}

    if Script.Feature[Version .. ' Notification Color'] then
        return NotificationColors[Script.Feature[Version .. ' Notification Color'].value + 1]
    else
        return 0x00FF00
    end
end

local function Notify(Text, Version, Header)
    if not Text or not IsFeatOn('Enable Script Notifications') then
        return
    end

    Header = Header or '2Take1Script'

    local Color = NotifColor(Version or "Error")

    menu.notify(Text, Header, Script.Feature['Notification Duration'].value, Color)
end

local function Log(Text, Prefix)
    if not Text or not IsFeatOn('Enable Script logs') then
        return
    end

    Prefix = Prefix or ' '
    utility.write(io.open(files['MainLog'], 'a'), Math.TimePrefix() .. ' ' .. Text)
end

local function IsFakeFriend(ID)
    local FakeFriends = {}

    for Line in io.lines(files['FakeFriends']) do
        local parts = {}
        for part in Line:gmatch("[^:]+") do
            parts[#parts + 1] = part
        end
        if #parts >= 2 then
            local name = parts[1]
            local scid = tonumber(parts[2], 16)
            FakeFriends[scid] = {Name=name}
        end
    end

    if FakeFriends[get.SCID(ID)] then
        return true
    end

    return false
end

function setup.SaveSettings(File)
    if not File then
        File = files['DefaultConfig']
    end
    
    local SafeFiles = io.open(File, 'w+')
    io.output(SafeFiles)

    local Files = {}
    for Name, Data in pairs(settings) do
        Files[#Files + 1] = tostring(Name) .. ':'.. tostring(Data.Enabled) .. ':' .. tostring(Data.Value) .. '\n'
    end

    table.sort(Files)
    for i = 1, #Files do
        io.write(Files[i])
    end

    io.close(SafeFiles)
end

local FeatTypes = {
    ["toggle"] = 1,
    ["slider"] = 7,
    ["value_i"] = 11,
    ["value_str"] = 35,
    ["value_f"] = 131,
    ["action"] = 512,
    ["action_slider"] = 518,
    ["action_value_i"] = 522,
    ["action_value_str"] = 546,
    ["action_value_f"] = 642,
    ["autoaction_slider"] = 1030,
    ["autoaction_value_i"] = 1034,
    ["autoaction_value_str"] = 1058,
    ["autoaction_value_f"] = 1154,
    ["parent"] = 2048,
}

function setup.LoadSettings(File)
    if not File then
        File = files['DefaultConfig']
    end

    local StB={
        ["true"] = true,
        ["false"] = false
    }

    for Line in io.lines(File) do
        local Parts = {}
        for Part in Line:gmatch("[^:]+") do
            Parts[#Parts + 1] = Part
        end

        if #Parts == 3 then
            local Name = Parts[1] or "Invalid"
            local Toggle = Parts[2] or "nil"
            local Value = Parts[3] or "nil"

            if Script.Feature[Name] and Script.Feature[Name].type then

                if Name == "Change Force Plate Text" and Script.Feature[Name] then
                    Script.Feature[Name]:set_str_data({Value})
                else
                    local Type = Script.Feature[Name].type

                    if (Type ~= 512 and Type ~= 2048) then

                        if (Type == 1 or Type == 7 or Type == 11 or Type == 35 or Type == 131) and Toggle ~= "nil" then
                            Script.Feature[Name].on = StB[Toggle]
                        end
                        
                        if Type ~= 1 and Value ~= "nil" then
                            Script.Feature[Name].value = tonumber(Value)
                        end
                    end
                end
            end
        end
    end
end

local neon_lights_rgb = {
    {222, 222, 255},
    {2, 21, 255},
    {3, 83, 255},
    {0, 255, 140},
    {94, 255, 1},
    {255, 255, 0},
    {255, 150, 5},
    {255, 62, 0},
    {255, 1, 1},
    {255, 50, 100},
    {255, 5, 190},
    {35, 1, 255},
    {15, 3, 255}
}
local cmds = {
    {'cmd_clearwanted', '/clearwanted'},
    {'cmd_giveweapons', '/giveweapons'},
    {'cmd_rpdrop', '/rpdrop <on/off>'},
    {'cmd_removeweapons', '/removeweapons <playername>'},
    {'cmd_setbounty', '/setbounty <playername>'},
    {'cmd_explode', '/explode <playername>'},
    {'cmd_trap', '/trap <playername>'},
    {'cmd_kick', '/kick <playername>'},
    {'cmd_crash', '/crash <playername>'},
    {'cmd_spawn', '/spawn <NAME>'},
    {'cmd_vehiclegod', '/vehiclegod <on/off>'},
    {'cmd_upgrade', '/upgrade'},
    {'cmd_repair', '/repair'},
    {'cmd_explode_all', '/explodeall'},
    {'cmd_scriptkick_all', '/scriptkickall'},
    {'cmd_desynckick_all', '/desynckickall'},
    {'cmd_crash_all', '/crashall'},
}
local entitys = {
    ['bl_objects'] = {},
    ['peds'] = {},
    ['asteroids'] = {},
    ['entity_spam'] = {},
    ['Custom Vehicles'] = {},
    ['preview_veh'] = {},
    ['temp_veh'] = {},
    ['shooting'] = {},
    ['bodyguards'] = {},
    ['robot_weapon_left'] = {},
    ['robot_weapon_right'] = {}
}
local outfits = {
    ['police_outfit'] = {
        ['female'] = {
            ['clothes'] = {
                {0, 0},
                {0, 6},
                {0, 14},
                {0, 34},
                {0, 0},
                {0, 25},
                {0, 0},
                {0, 35},
                {0, 0},
                {0, 0},
                {0, 48}
            },
            ['props'] = {
                {0, 45, 0},
                {1, 11, 0},
                {2, 4294967295, 0},
                {6, 4294967295, -1},
                {7, 4294967295, -1}
            }
        },
        ['male'] = {
            ['clothes'] = {
                {0, 0},
                {0, 0},
                {0, 0},
                {0, 35},
                {0, 0},
                {0, 25},
                {0, 0},
                {0, 58},
                {0, 0},
                {0, 0},
                {0, 55}
            },
            ['props'] = {
                {0, 46, 0},
                {1, 13, 0},
                {2, 4294967295, 0},
                {6, 4294967295, -1},
                {7, 4294967295, -1}
            }
        }
    }
}
local stathashes = {
    ['ceo_earnings'] = {
        {'LIFETIME_BUY_COMPLETE', 2000},
        {'LIFETIME_BUY_UNDERTAKEN', 2000},
        {'LIFETIME_SELL_COMPLETE', 2000},
        {'LIFETIME_SELL_UNDERTAKEN', 2000},
        {'LIFETIME_CONTRA_EARNINGS', 20000000}
    },
    ['mc_earnings'] ={
        {'LIFETIME_BIKER_BUY_COMPLET', 2000},
        {'LIFETIME_BIKER_BUY_UNDERTA', 2000},
        {'LIFETIME_BIKER_SELL_COMPLET', 2000},
        {'LIFETIME_BIKER_SELL_UNDERTA', 2000},
        {'LIFETIME_BIKER_BUY_COMPLET1', 2000},
        {'LIFETIME_BIKER_BUY_UNDERTA1', 2000},
        {'LIFETIME_BIKER_SELL_COMPLET1', 2000},
        {'LIFETIME_BIKER_SELL_UNDERTA1', 2000},
        {'LIFETIME_BIKER_BUY_COMPLET2', 2000},
        {'LIFETIME_BIKER_BUY_UNDERTA2', 2000},
        {'LIFETIME_BIKER_SELL_COMPLET2', 2000},
        {'LIFETIME_BIKER_SELL_UNDERTA2', 2000},
        {'LIFETIME_BIKER_BUY_COMPLET3', 2000},
        {'LIFETIME_BIKER_BUY_UNDERTA3', 2000},
        {'LIFETIME_BIKER_SELL_COMPLET3', 2000},
        {'LIFETIME_BIKER_SELL_UNDERTA3', 2000},
        {'LIFETIME_BIKER_BUY_COMPLET4', 2000},
        {'LIFETIME_BIKER_BUY_UNDERTA4', 2000},
        {'LIFETIME_BIKER_SELL_COMPLET4', 2000},
        {'LIFETIME_BIKER_SELL_UNDERTA4', 2000},
        {'LIFETIME_BIKER_BUY_COMPLET5', 2000},
        {'LIFETIME_BIKER_BUY_UNDERTA5', 2000},
        {'LIFETIME_BIKER_SELL_COMPLET5', 2000},
        {'LIFETIME_BIKER_SELL_UNDERTA5', 2000},
        {'LIFETIME_BKR_SELL_EARNINGS0', 20000000},
        {'LIFETIME_BKR_SELL_EARNINGS1', 20000000},
        {'LIFETIME_BKR_SELL_EARNINGS2', 20000000},
        {'LIFETIME_BKR_SELL_EARNINGS3', 20000000},
        {'LIFETIME_BKR_SELL_EARNINGS4', 20000000},
        {'LIFETIME_BKR_SELL_EARNINGS5', 20000000}
    },
    ['snacks_and_armor'] = {
        {'NO_BOUGHT_YUM_SNACKS', 30},
        {'NO_BOUGHT_HEALTH_SNACKS', 15},
        {'NO_BOUGHT_EPIC_SNACKS', 5},
        {'NUMBER_OF_ORANGE_BOUGHT', 10},
        {'NUMBER_OF_BOURGE_BOUGHT', 10},
        {'NUMBER_OF_CHAMP_BOUGHT', 5},
        {'CIGARETTES_BOUGHT', 20},
        {'MP_CHAR_ARMOUR_1_COUNT', 10},
        {'MP_CHAR_ARMOUR_2_COUNT', 10},
        {'MP_CHAR_ARMOUR_3_COUNT', 10},
        {'MP_CHAR_ARMOUR_4_COUNT', 10},
        {'MP_CHAR_ARMOUR_5_COUNT', 10}
    },
    ['xmas'] = {
        {'MPPLY_XMASLIVERIES0'},
        {'MPPLY_XMASLIVERIES1'},
        {'MPPLY_XMASLIVERIES2'},
        {'MPPLY_XMASLIVERIES3'},
        {'MPPLY_XMASLIVERIES4'},
        {'MPPLY_XMASLIVERIES5'},
        {'MPPLY_XMASLIVERIES6'},
        {'MPPLY_XMASLIVERIES7'},
        {'MPPLY_XMASLIVERIES8'},
        {'MPPLY_XMASLIVERIES9'},
        {'MPPLY_XMASLIVERIES10'},
        {'MPPLY_XMASLIVERIES11'},
        {'MPPLY_XMASLIVERIES12'},
        {'MPPLY_XMASLIVERIES13'},
        {'MPPLY_XMASLIVERIES14'},
        {'MPPLY_XMASLIVERIES15'},
        {'MPPLY_XMASLIVERIES16'},
        {'MPPLY_XMASLIVERIES17'},
        {'MPPLY_XMASLIVERIES18'},
        {'MPPLY_XMASLIVERIES19'},
        {'MPPLY_XMASLIVERIES20'}
    },
    ['kills_deaths'] = {
        'MPPLY_KILLS_PLAYERS',
        'MPPLY_DEATHS_PLAYER'
    },
    ['fast_run'] = {
        'CHAR_FM_ABILITY_1_UNLCK',
        'CHAR_FM_ABILITY_2_UNLCK',
        'CHAR_FM_ABILITY_3_UNLCK',
        'CHAR_ABILITY_1_UNLCK',
        'CHAR_ABILITY_2_UNLCK',
        'CHAR_ABILITY_3_UNLCK'
    },
    ['chc'] = {
        ['misc'] = {
            {'Remove Repeat Cooldown (-1)', 'H3_COMPLETEDPOSIX', 0, -1},
            {'Last Approach Completed (1 2 3)', 'H3_LAST_APPROACH', 0, -1, 3},
            {'Confirm First Board', 'H3OPT_BITSET1', 0, -1},
            {'Confirm Second Board', 'H3OPT_BITSET0', 0, -1}
        },
        ['board1'] = {
            {'1:Silent, 2:BigCon, 3:Aggressive', 'H3OPT_APPROACH', 0, 1, 3, 1},
            {'1:Hard, 2:Difficulty, 3:Approach', 'H3_HARD_APPROACH', 0, 1, 3, 1},
            {'0:Money, 1:Gold, 2:Art, 3:Diamond', 'H3OPT_TARGET', 0, 0, 3, 3},
            {'Unlock Points of Interests', 'H3OPT_POI', 0, 1023},
            {'Unlock Access Points', 'H3OPT_ACCESSPOINTS', 0, 2047}
        },
        ['board2'] = {
            {'1:5%, 2:9%, 3:7%, 4:10%, 5:10%', 'H3OPT_CREWWEAP', 0, 1, 5, 1},
            {'1:5%, 2:7%, 3:9%, 4:6%, 5:10%', 'H3OPT_CREWDRIVER', 0, 1, 5, 1},
            {'1:3%, 2:7%, 3:5%, 4:10%, 5:9%', 'H3OPT_CREWHACKER', 0, 1, 5, 1},
            {'Weapon Variation (0 1)', 'H3OPT_WEAPS', 0, 0, 1},
            {'Vehicle Variation (0 1 2 3)', 'H3OPT_VEHS', 0, 0, 3},
            {'Remove Duggan Heavy Guards', 'H3OPT_DISRUPTSHIP', 0, 3},
            {'Equip Heavy Armor', 'H3OPT_BODYARMORLVL', 0, 3},
            {'Scan Card Level', 'H3OPT_KEYLEVELS', 0, 2},
            {'Mask Variation (0 till 12)', 'H3OPT_MASKS', 0, 0, 12}
        }
    },
    ['perico'] = {
        {'Unlock Points of Interests', 'H4CNF_BS_GEN', 0, 131071},
        {'Redoubt Entry Points', 'H4CNF_BS_ENTR', 0, 63},
        {'Unlock Support Team', 'H4CNF_BS_ABIL', 0, 63},
        {'Weapon Variation', 'H4CNF_WEAPONS', 0, 1, 5, 5},
        {'Disruption - Unmarked Weapon', 'H4CNF_WEP_DISRP', 0, 3},
        {'Disruption - Armor Disruption', 'H4CNF_ARM_DISRP', 0, 3},
        {'Disruption - Air Support', 'H4CNF_HEL_DISRP', 0, 3},
        {'Primary Target', 'H4CNF_TARGET', 0, 1, 5, 5},
        {'Truck - Spawn Place', 'H4CNF_TROJAN', 0, 1, 5, 3},
        {'Infiltration - Escape Points', 'H4CNF_APPROACH', 0, -1},
        {'Set Missions as completed', 'H4_MISSIONS', 0, 65535},
        {'Set Difficulty (Normal or Hard)', 'H4_PROGRESS', 0, 126823, 130667},
        {'Gold Inside  Compound', 'H4LOOT_GOLD_C_SCOPED', 0, 192, 255},
        {'Paint Inside  Compound', 'H4LOOT_PAINT_SCOPED', 0, 120, 127},
        {'Gold_C Loot Price', 'H4LOOT_GOLD_C', 0, 192, 255},
        {'Gold_V Loot Price', 'H4LOOT_GOLD_V', 0, 471000, 126000, 1373000, 1598000},
        {'Paint Loot Price', 'H4LOOT_PAINT', 0, 120, 127},
        {'Paint_V Loot Price', 'H4LOOT_PAINT_V', 0, 353000, 948000, 1030000, 1198000}
    }
}

local Self = player.player_id
local modelList = mapper.ped.GetAllPedModels()
local random_colors = {'Random Primary Color', 'Random Secondary Color', 'Random Pearlescent Color', 'Random Neon Color', 'Random Smoke Color', 'Random Xenon Color', 'Random Wheel Color'}
local rainbow_colors = {'Rainbow Primary Color', 'Rainbow Secondary Color', 'Rainbow Pearlescent Color', 'Rainbow Neon Color', 'Rainbow Smoke Color', 'Rainbow Xenon Color', 'Rainbow Wheel Color'}
local offset_height, config_preview, offset_distance = 0, false, 0
local rot_veh = v3()
local hash_c
local explosion_blame = 0
local antispam = {}
local playerlogging = {}
local playerblamekill = {}
local localResult = {}
local playerResult = {}
local hooks = {script = {}, net = {}}
local model_gun, apply_invisible, balll, OceanEntity, HeightEntity, FixedHeight
local robot_objects = {}
local bad_net_events = {12, 13, 14, 43, 66, 74, 78, 83}
local OTRBlip = {}
local ptfxs = { ['flamethrower'] = nil, ['flamethrower_green'] = nil, ['alien'] = nil}
local miscdata = {
    smslocations = {
        math.random(22, 41), math.random(60, 69), math.random(70, 80), 81, math.random(83, 87), 88, math.random(89, 97), math.random(102, 111), 117, 122, 124,
        math.random(128, 133), 147, 148, math.random(149, 153), 154, math.random(155, 158), 159, 160, 161, 42
    },
    ceomoney = {
        {'10K Work Payout', 10000, -1292453789, 0, 120000},
        {'10K Special Cargo', 10000, -1292453789, 1, 60000},
        {'10K Vehicle Cargo', 10000, 4213353345, 1, 60000},
        {'30K Cargo', 30000, 198210293, 1, 120000},
    },
    hudcomponents = {
        {'Wanted Stars', 1}, {'Bank Money', 3}, {'Wallet Money', 4}, {'Vehicle Name', 6}, {'Area Name', 7},
        {'Street Name', 9}, {'Weapon Wheel', 19}, {'Weapon Wheel Stats', 20}, {'Radio Stations', 16}, {'Aim Dot', 14}
    },
    ramps = {
        2934970695,
        3233397978,
        1290523964,
        versions = {
            {'Front', v3(0, 6, 0.2), v3(0, 0, 180)},
            {'Back', v3(0, -6, 0.2), v3(0, 0, 0)},
            {'Left', v3(-5, 0, 0.2), v3(0, 0, 270)},
            {'Right', v3(5, 0, 0.2), v3(0, 0, 90)}
        }
    },
    VehicleCategories = {
        'Compacts', 'Sedans', 'SUVs', 'Coupes', 'Muscle', 'Sports Classics', 'Sports', 'Super', 'Motorcycles',
        'Off-Road', 'Industrial', 'Utility', 'Vans', 'Cycles', 'Boats', 'Helicopters', 'Planes', 'Service',
        'Emergency', 'Military', 'Commercial', 'Open Wheel'
    }
}

local function SelectFeat(f)
    if f.parent then
        f.parent:toggle()
    end

    f:select()
end

local function DeleteFeature(Feat)
    if Feat.type == 2048 then
        for i=1,Feat.child_count do
            DeleteFeature(Feat.children[1])
        end
    end
    menu.delete_feature(Feat.id)
end

local function Randomize(Table)
    for i = #Table, 2, -1 do
        local j = math.random(i)
        Table[i], Table[j] = Table[j], Table[i]
    end
    
    return Table
end


local function change_model(hash, water, isinvisible, isdown, ignore)
    if ignore or not IsFeatOn('Safe Model Change') or (IsFeatOn('Safe Model Change') and not ped.is_ped_in_any_vehicle(get.OwnPed())
    and (water and entity.is_entity_in_water(get.OwnPed()) or (not water and not entity.is_entity_in_water(get.OwnPed())))) then
        if isdown then
            utility.tp(get.OwnCoords(), 1.5)
        end
        utility.request_model(hash)
        player.set_player_model(hash)
        streaming.set_model_as_no_longer_needed(hash)
        if isinvisible then
            coroutine.yield(0)
            ped.set_ped_component_variation(get.OwnPed(), 4, 0, 0, 2)
        end
        if IsFeatOn('Revert Outfit') then
            if hash == 0x9C9EFFD8 or hash == 0x705E61F2 then
                local gender = 'male'
                if player.is_player_female(Self()) then
                    gender = 'female'
                end
            end
        end
    else
        Notify('Model Change not possible.', "Error")
    end
end


local function ToggleOff(Features)
    for i = 1, #Features do
        if IsFeatOn(Features[i]) then
            Script.Feature[Features[i]].on = false
        end

    end
end


local function IsEntitled(Player, Target, Command, Feat)
    local Name = get.Name(Player)
    local SCID = get.SCID(Player)
    Log('Detected Chat-Command ' .. Command .. ' from Player ' .. Name .. ' [' .. get.SCID(Player) .. ']')

    if Script.Feature[Feat].value == 0 or (Script.Feature[Feat].value == 1 and player.is_player_friend(Player)) or (Player == Self()) then
        
        if not Target then
            Log('Executing Chat Command "' .. Command .. '" for Player "' .. Name .. '"')
            Notify('Executed Command: ' .. Command .. '\nPlayer: ' .. Name, "Neutral", '2Take1Script Chat Commands')
            return true, nil
        end

        local TargetID = get.IDFromName(Target)
 
        if not player.is_player_valid(TargetID) then
            Log('Target doesnt exist')
            Notify('Error executing Command: ' .. Command .. '\nPlayer: ' .. Name .. '\nReason: Target not found', "Error", '2Take1Script Chat Commands')
            return false
        end

        if (TargetID == Self() and Player ~= Self()) then
            Log('Blocking Chat Command "' .. Command .. '" for Player "' .. Name .. '" with you as Target')
            Notify('Blocked Command: ' .. Command .. '\nPlayer: ' .. Name .. '\nTarget: You', "Neutral", '2Take1Script Chat Commands')
            return false

        elseif (player.is_player_friend(TargetID) and IsFeatOn('Block Friends as Target') and Player ~= Self()) then
            Log('Blocking Chat Command "' .. Command .. '" for Player "' .. Name .. '" with a Friend as Target')
            Notify('Blocked Command: ' .. Command .. '\nPlayer: ' .. Name .. '\nTarget: "' .. Target .. '" (Friend)', "Neutral", '2Take1Script Chat Commands')
            return false

        else
            Log('Executing Chat Command "' .. Command .. '" for Player "' .. Name .. '" on Target: "' .. Target .. '"')
            Notify('Executed Command: ' .. Command .. '\nPlayer: ' .. Name .. '\nTarget: "' .. Target .. '"', "Neutral", '2Take1Script Chat Commands')
            return true, TargetID
        end

    end
    return false
end


local function BlockArea(Feature)
	assert(Feature.data, "Feature needs data object with area information.")
	
	Log("Blocking Area.")
	
	for i=1,#Feature.data.Objects do
		local Object = Feature.data.Objects[i]
		
		local ent = Spawn.Object(Object.Hash)
		entitys["bl_objects"][#entitys["bl_objects"] + 1] = ent
		
		local pos = Object.Position
		if Object.Position2 then
			pos.x = math.random(pos.x, Object.Position2.x)
			pos.y = math.random(pos.y, Object.Position2.y)
			pos.z = math.random(pos.z, Object.Position2.z)
		end
		utility.set_coords(ent, pos)
		
		entity.set_entity_rotation(ent, Object.Rotation)
		
		if Object.Freeze then
			entity.freeze_entity(ent, true)
		end
		
		if Object.Invisible then
			entity.set_entity_visible(ent, false)
		end
	end
	
	if IsFeatOn("Teleport to Block") then
		utility.tp(Feature.data.Teleport, nil, Feature.data.Heading)
	end
	
	Log("Blocking Done.")
end


--[[ patched
local function fix_crash_screen()
    if not hash_c then
        return
    end

    change_model(hash_c)
    coroutine.yield(250)

    ped.set_ped_health(get.OwnPed(), 0)
    coroutine.yield(3500)
    
    local clothes = outfits['session_crash']['clothes']
    local textures = outfits['session_crash']['textures']
    
    for i = 1, 11 do
        ped.set_ped_component_variation(get.OwnPed(), i, clothes[i], textures[i], 2)
    end

    local loop = {0, 1, 2, 6, 7}
    local h_prop_ind = outfits['session_crash']['prop_ind']
    local h_prop_text = outfits['session_crash']['prop_text']

    for z = 1, #loop do
        ped.set_ped_prop_index(get.OwnPed(), loop[z], h_prop_ind[z], h_prop_text[z], 0)
    end
end
]]


local function clear_legs_movement()
    local left = robot_objects['llbone']
    local right = robot_objects['rlbone']
    local main = robot_objects['tampa']

    local offsetL = v3(-4.25, 0, 12.5)
    local offsetR = v3(4.25, 0, 12.5)

    if left and right and main then
        if entity.is_an_entity(left) and entity.is_an_entity(right) and entity.is_an_entity(main) then
            utility.request_ctrl(left)
            utility.request_ctrl(right)
            utility.request_ctrl(main)
            
            entity.attach_entity_to_entity(left, main, 0, offsetL, v3(), true, IsFeatOn('Robot Collision'), false, 2, true)
            entity.attach_entity_to_entity(right, main, 0, offsetR, v3(), true, IsFeatOn('Robot Collision'), false, 2, true)
        end

    end

end


local function spawn_custom_vehicle(data, place)
    Log('Attempt to spawn Custom Vehicle.')
    menu.set_menu_can_navigate(false)
    local temp_veh = {}
    local pos = v3()
    local rot = v3()
    local BONE_ID = 0
    local attach_to = 0
    local heading = 0
    local skip_upg = false
    local cur_veh = get.OwnVehicle()

    if IsFeatOn('Custom Vehicles Preview') and entitys['preview_veh'][1] then
        utility.clear(entitys['preview_veh'])
        entitys['preview_veh'] = {}
        config_preview = false
        coroutine.yield(250)
    end

    for i = 1, #data[1] do
        utility.request_model(data[1][i])
    end

    for i = 2, #data do
        pos = get.OwnCoords()

        if data[i][6] and i == 2 then
            pos.z = pos.z + data[i][6]
        end

        if i > 2 then
            pos.z = pos.z + 25
        end

        if IsFeatOn('Use Own Vehicles') and i == 2 and entity.get_entity_model_hash(cur_veh) == data[i][1] or data[2][1] == 0 and i == 2 and IsFeatOn('Use Own Vehicles') and cur_veh ~= 0 then
            Log('Detected Own Vehicle, using it.')
            temp_veh[i - 1] = cur_veh
            skip_upg = true

        elseif data[2][1] == 0 and not IsFeatOn('Use Own Vehicles') then
            Log('Failed at spawning Custom Vehicle.')
            Notify('No Vehicle found, get in a valid Vehicle', "Error")
            menu.set_menu_can_navigate(true)
            return

        else
            if streaming.is_model_a_vehicle(data[i][1]) then
                if i == 2 then
                    heading = get.OwnHeading()

                    if data[i][11] then
                        offset_distance = data[i][11]
                    else
                        offset_distance = 5
                    end

                    if data[i][12] then
                        offset_height = data[i][12]
                    else
                        offset_height = 1
                    end

                    pos = utility.OffsetCoords(pos, heading, offset_distance)
                end

                temp_veh[i - 1] = Spawn.Vehicle(data[i][1], pos, heading)
                decorator.decor_set_int(temp_veh[i - 1], 'MPBitset', 1 << 10)

                local color = math.random(0, 16777215)
                if data[i][4] then
                    color = data[i][4][1]
                end

                vehicle.set_vehicle_custom_primary_colour(temp_veh[i - 1], color)
                if data[i][4] then
                    color = data[i][4][2]
                end

                vehicle.set_vehicle_custom_secondary_colour(temp_veh[i - 1], color)
                if data[i][4] then
                    color = data[i][4][3]
                end

                vehicle.set_vehicle_custom_pearlescent_colour(temp_veh[i - 1], color)
                if data[i][4] then
                    color = data[i][4][4]
                end

                vehicle.set_vehicle_custom_wheel_colour(temp_veh[i - 1], color)
                color = math.random(0, 4)
                if data[i][4] then
                    color = data[i][4][5]
                end

                vehicle.set_vehicle_window_tint(temp_veh[i - 1], color)
                if streaming.is_model_a_plane(data[i][1]) and i > 2 then
                    vehicle.control_landing_gear(temp_veh[i - 1], 3)
                end
            else
                temp_veh[i - 1] = Spawn.Object(data[i][1], pos)
            end
        end

        if i > 2 then
            pos.z = pos.z - 25
        end

        if IsFeatOn('Custom Vehicles Godmode') then
            entity.set_entity_god_mode(temp_veh[i - 1], true)
        end

        if data[i][5] then
            entity.set_entity_visible(temp_veh[i - 1], false)
        end

        if data[i][13] then
            entity.set_entity_alpha(temp_veh[i - 1], data[i][13], false)
        end

        if i > 2 then
            BONE_ID = 0
            if data[i][7] then
                BONE_ID = data[i][7]
            end

            attach_to = temp_veh[1]
            if data[i][8] then
                attach_to = temp_veh[data[i][8]]
            end

            local set_collision = data[i][10]
            if set_collision then
                entity.set_entity_collision(temp_veh[i - 1], false, false, false)
            else
                set_collision = false
            end

            pos = v3()
            if data[i][2] then
                pos = v3(data[i][2][1], data[i][2][2], data[i][2][3])
            end

            rot = v3()
            if data[i][3] then
                rot = v3(data[i][3][1], data[i][3][2], data[i][3][3])
            end

            if data[i][1] ~= 0 then
                entity.attach_entity_to_entity(temp_veh[i - 1], attach_to, BONE_ID, pos, rot, false, not set_collision, false, 2, true)
            end

            if data[i][9] then
                local spawned_ped
                pos = get.OwnCoords()
                spawned_ped = Spawn.Ped(data[i][9], pos)
                coroutine.yield(0)

                if IsFeatOn('Custom Vehicles Godmode') then
                    ped.set_ped_max_health(spawned_ped, 25000000.0)
                    ped.set_ped_health(spawned_ped, 25000000.0)
                    ped.set_ped_can_ragdoll(spawned_ped, false)
                    entity.set_entity_god_mode(spawned_ped, true)
                end

                streaming.set_model_as_no_longer_needed(data[i][9])

                if data[i][1] ~= 0 then
                    ped.set_ped_into_vehicle(spawned_ped, temp_veh[i - 1], -1)
                    vehicle.set_vehicle_doors_locked(temp_veh[i - 1], 2)

                else
                    pos = v3()
                    if data[i][2] then
                        pos = v3(data[i][2][1], data[i][2][2], data[i][2][3])
                    end

                    rot = v3()
                    if data[i][3] then
                        rot = v3(data[i][3][1], data[i][3][2], data[i][3][3])
                    end

                    entity.attach_entity_to_entity(spawned_ped, attach_to, BONE_ID, pos, rot, false, not set_collision, true, 2, true)
                end

            end

        end

        if IsFeatOn('Custom Vehicles Preview') then
            entitys['preview_veh'][#entitys['preview_veh'] + 1] = temp_veh[i - 1]

        elseif place then
            entitys[place][#entitys[place] + 1] = temp_veh[i - 1]

        else
            entitys['Custom Vehicles'][#entitys['Custom Vehicles'] + 1] = temp_veh[i - 1]
        end
    end

    if not IsFeatOn('Custom Vehicles Preview') then
        if IsFeatOn('Spawn in Custom Vehicle') then
            ped.set_ped_into_vehicle(get.OwnPed(), temp_veh[1], -1)
            vehicle.set_vehicle_engine_on(temp_veh[1], true, true, false)
        end
    end

    if not skip_upg then
        utility.MaxVehicle(temp_veh[1], 2)
    end

    menu.set_menu_can_navigate(true)
    Log('Spawn Custom Vehicle Done.')
end

local function SmartKick(pid)
    if network.network_is_host() then
        network.network_session_kick_player(pid)
        --network.force_remove_player(pid, false)
        --menu.get_feature_by_hierarchy_key('online.online_players.player_' .. pid .. '.ho_kick'):toggle()

    --[[
    elseif player.is_player_host(pid) then
        network.force_remove_player(pid, false)
    ]]

    else
        scriptevent.kick(pid)
        --network.force_remove_player(pid, true)
        
    end
end

local function VBCheck(target)
    if not target then
        return
    end

    local name = get.Name(target)
    local veh = get.PlayerVehicle(target)
    if veh ~= 0 then
        local guilty = false
        local detected_veh
        local model = entity.get_entity_model_hash(veh)
        local checkset
        local reactions = {'Delete', 'Explode', 'Vehicle Kick', 'Script Kick', 'Desync Kick', 'Script Crash'}

        if streaming.is_model_a_car(model) or streaming.is_model_a_bike(model) then
            checkset = customData.vehicle_blacklist[1].Children
        elseif streaming.is_model_a_plane(model) or streaming.is_model_a_heli(model) then
            checkset = customData.vehicle_blacklist[2].Children
        else
            checkset = customData.vehicle_blacklist[3].Children
        end

        for i = 1, #checkset do
            if IsFeatOn('VB ' .. checkset[i].Name) and model == checkset[i].Hash then
                guilty = true
                detected_veh = checkset[i].Name
                goto continue
            end
        end

        ::continue::
        if guilty then
            Log('Player: ' .. name .. '\nVehicle: ' .. detected_veh, '[Vehicle Blacklist]')

            if Script.Feature['Vehicle Blacklist Reaction'].value == 0 then
                utility.clear(get.PlayerVehicle(target))
                
            elseif Script.Feature['Vehicle Blacklist Reaction'].value == 1 then
                utility.request_ctrl(veh, 100)
                entity.set_entity_god_mode(veh, false)
                entity.set_entity_velocity(veh, v3())
                fire.add_explosion(get.PlayerCoords(target), 59, false, true, 1, get.PlayerPed(target))

            elseif Script.Feature['Vehicle Blacklist Reaction'].value == 2 then
                scriptevent.Send('Destroy Personal Vehicle', {Self(), target}, target)
                scriptevent.Send('Vehicle Kick', {Self(), 4294967295, 4294967295, 4294967295}, target)

            elseif Script.Feature['Vehicle Blacklist Reaction'].value == 3 then
                scriptevent.kick(target)

            elseif Script.Feature['Vehicle Blacklist Reaction'].value == 4 then
                SmartKick(target)

            elseif Script.Feature['Vehicle Blacklist Reaction'].value == 5 then
                scriptevent.crash(target)
            end

            Notify('Player: ' .. name .. '\nVehicle: ' .. detected_veh .. '\nReaction: ' .. reactions[Script.Feature['Vehicle Blacklist Reaction'].value + 1], "Neutral", '2Take1Script Vehicle Blacklist')

            coroutine.yield(10000)
        end

        coroutine.yield(1000)
    end
end


local function WBCheck(target)
    if not target then
        return
    end

    local Ped = get.PlayerPed(target)
    local currentWep = ped.get_current_ped_weapon(Ped)
    local wepName = mapper.weapons.GetNameFromHash(currentWep)
    local reactions = {'Remove Weapon', 'Script Kick', 'Desync Kick', 'Script Crash'}
    
    if wepName ~= 0 then
        if IsFeatOn('Blacklist ' .. wepName) then
            if Script.Feature['Weapon Blacklist Reaction'].value == 0 then
                weapon.remove_weapon_from_ped(Ped, currentWep)

            elseif Script.Feature['Weapon Blacklist Reaction'].value == 1 then
                scriptevent.kick(target)

            elseif Script.Feature['Weapon Blacklist Reaction'].value == 2 then
                SmartKick(target)

            elseif Script.Feature['Weapon Blacklist Reaction'].value == 3 then
                scriptevent.crash(target)
            end

            Notify('Player: ' .. get.Name(target) .. '\nWeapon: ' .. wepName .. '\nReaction: ' .. reactions[Script.Feature['Weapon Blacklist Reaction'].value + 1], "Neutral", '2Take1Script Weapon Blacklist')
            
        end
    end

    coroutine.yield(1000)
end


local function CreatePlayerSearch(id)
    if not Script.Parent['Player Feature Search'] then
        return
    end

    if not get.Name then
        return
    end

    Script.Parent['PFS ' .. id] = menu.add_feature(get.Name(id), 'parent', Script.Parent['Player Feature Search'].id)
    playerResult[id] = {}

    Script.Feature['Player Search' .. id] = menu.add_feature('Search Player Features', 'action_value_str', Script.Parent['PFS ' .. id].id, function(f)
        local search = get.Input('Enter Feature Keyword', 25, 0, '')

        if not search then
            Notify('Input canceled.', "Error", 'Feature Search')
            return
        end

        SelectFeat(f)

        if #playerResult[id] > 0 then
            for i = 1, #playerResult[id] do
                if playerResult[id][i].id then
                    menu.delete_feature(playerResult[id][i].id)
                    playerResult[id][i] = nil
                end
            end
        end

        coroutine.yield(100)

        for k in pairs(Script.PlayerFeature) do
            local features = Script.PlayerFeature[k].feats
            local name = features[id].name
            if name and string.find(name:lower(), search:lower()) then
                if features[id].parent then
                    name = features[id].parent.name .. ' -> ' .. name
                end

                playerResult[id][#playerResult[id] + 1] = menu.add_feature(name, 'action', Script.Parent['PFS ' .. id].id, function(f)
                    SelectFeat(features[id])
                end)
            end
        end

        if #playerResult[id] > 0 then
            Notify(#playerResult[id] .. ' results\nClick on any feature to be navigated.', 'Success', 'Feature Search')
        else
            Notify('No features found.', 'Error', 'Feature Search')
        end

        f:set_str_data({search})
    end)
    Script.Feature['Player Search'..id]:set_str_data({' '})


    Script.Feature['Player Reset Search' .. id] = menu.add_feature('Reset Search', 'action', Script.Parent['PFS ' .. id].id, function()
        if #playerResult[id] > 0 then
            for i = 1, #playerResult[id] do
                if playerResult[id][i].id then
                    menu.delete_feature(playerResult[id][i].id)
                    playerResult[id][i] = nil
                end
            end
            Notify('Search cleared.', 'Success', 'Feature Search')
        end
        Script.Feature['Player Search' .. id]:set_str_data({' '})
    end)
end


local chatevents = {}
function chatevents.LogChat(args)
    if not args or not args.player or not args.body then
        return
    end

    if args.player ~= args.sender then
        utility.write(io.open(files['ChatLog'], 'a'), Math.TimePrefix() .. ' ' .. get.Name(args.sender) .. ' [' .. get.SCID(args.sender) .. '] writing as ' .. get.Name(args.player) .. ': ' .. args.body)
    else
        utility.write(io.open(files['ChatLog'], 'a'), Math.TimePrefix() .. ' ' .. get.Name(args.player) .. ' [' .. get.SCID(args.player) .. ']: ' .. args.body)
    end
end


function chatevents.PrintChat(args)
    if not args or not args.player or not args.body then
        return
    end

    if args.player ~= args.sender then
        print('[Chat] ' .. get.Name(args.sender) .. ' [' .. get.SCID(args.sender) .. '] writing as ' .. get.Name(args.player) .. ': "' .. args.body .. '"')
    else
        print('[Chat] ' .. get.Name(args.player) .. ' [' .. get.SCID(args.player) .. ']: "' .. args.body .. '"')
    end
end


function chatevents.AntiChatSpam(args)
    if not args or not args.player or not args.body then
        return
    end

    if args.player ~= args.sender then
        return
    end

    if utility.valid_player(args.player, IsFeatOn('Exclude Friends')) then
        local detected

        if not antispam[args.player] then
            antispam[args.player] = {
                Content = {},
                Times = 0,
                Thread = nil
            }
        end

        antispam[args.player].Content[#antispam[args.player].Content + 1] = args.body
        antispam[args.player].Times = antispam[args.player].Times + 1

        if not antispam[args.player].Thread or menu.has_thread_finished(antispam[args.player].Thread) then
            antispam[args.player].Thread = menu.create_thread(function()
                coroutine.yield(5000)

                if antispam[args.player] then
                    antispam[args.player].Times = 0
                end
            end, nil)
        end

        if #antispam[args.player].Content >= 3 then
            if (antispam[args.player].Content[1] == antispam[args.player].Content[2]) and (antispam[args.player].Content[1] == antispam[args.player].Content[3]) then
                antispam[args.player] = nil
                detected = true
            else
                antispam[args.player].Content = {}
            end

        elseif antispam[args.player].Times >= 4 then
            antispam[args.player] = nil
            detected = true
        end
        

        if detected then
            local name = get.Name(args.player)
            if Script.Feature['Anti Chat Spam'].value == 0 then
                Notify('Player: ' .. name .. '\nReason: Chat Spam\nReaction: Script Kick', "Neutral", '2Take1Script Automod')
                scriptevent.kick(args.player)

            elseif Script.Feature['Anti Chat Spam'].value == 1 then
                Notify('Player: ' .. name .. '\nReason: Chat Spam\nReaction: Desync Kick', "Neutral", '2Take1Script Automod')
                SmartKick(args.player)

            else
                Notify('Player: ' .. name .. '\nReason: Chat Spam\nReaction: Crash', "Neutral", '2Take1Script Automod')
                scriptevent.crash(args.player)
            end
        end
    end
end


function chatevents.PunishRussian(args)
    if not args or not args.player or not args.body then
        return
    end

    if args.player ~= args.sender then
        return
    end

    if utility.valid_player(args.player, IsFeatOn('Exclude Friends')) then
        for i = 1, #stringData.russian_characters do
            if string.find(args.body, stringData.russian_characters[i], 1) then
                if Script.Feature['GEO-Block Russia'].value == 0 then
                    scriptevent.kick(args.player)

                elseif Script.Feature['GEO-Block Russia'].value == 1 then
                    SmartKick(args.player)

                elseif Script.Feature['GEO-Block Russia'].value == 2 then
                    scriptevent.crash(args.player)

                elseif Script.Feature['GEO-Block Russia'].value == 3 then
                    fire.add_explosion(get.PlayerCoords(args.player), 27, true, false, 1, 0)

                end

                Log('Player: ' .. get.Name(args.player) .. '\nReason: Talking Russian\nDetected String: ' .. stringData.russian_characters[i])
                Notify('Player: ' .. get.Name(args.player) .. '\nReason: Talking Russian', "Neutral", '2Take1Script Automod')

                return
            end
        end
    end
end


function chatevents.PunishChinese(args)
    if not args or not args.player or not args.body then
        return
    end

    if args.player ~= args.sender then
        return
    end

    if utility.valid_player(args.player, IsFeatOn('Exclude Friends')) then
        for i = 1, #stringData.chinese_characters do
            if string.find(args.body, stringData.chinese_characters[i], 1) then
                if Script.Feature['GEO-Block China'].value == 0 then
                    scriptevent.kick(args.player)

                elseif Script.Feature['GEO-Block China'].value == 1 then
                    SmartKick(args.player)

                elseif Script.Feature['GEO-Block China'].value == 2 then
                    scriptevent.crash(args.player)

                elseif Script.Feature['GEO-Block China'].value == 3 then
                    fire.add_explosion(get.PlayerCoords(args.player), 27, true, false, 1, 0)

                end

                Log('Player: ' .. get.Name(args.player) .. '\nReason: Talking Chinese\nDetected String: ' .. stringData.chinese_characters[i])
                Notify('Player: ' .. get.Name(args.player) .. '\nReason: Talking Chinese', "Neutral", '2Take1Script Automod')

                return
            end
        end
    end
end


function chatevents.DetectByMessage(args)
    if not args or not args.player or not args.body then
        return
    end

    if args.player ~= args.sender then
        return
    end

    if utility.valid_player(args.player, IsFeatOn('Exclude Friends')) then
        local detected = false
        local dtcstring
        local stringset = stringData.ChatStrings.Safe

        if Script.Feature['Ad Blacklist Chat Strings'].value == 1 then
            stringset = stringData.ChatStrings.Aggressive
        end

        for i = 1, #stringset do
            if string.find(args.body:lower(), stringset[i], 1, true) then
                dtcstring = stringset[i]
                detected = true
            end

        end

        if detected then
            if not IsFeatOn('Ad Blacklist Disable Notifications') then
                Notify('Player: ' .. get.Name(args.player) .. '\nReason: Chat Blacklist\nReaction: Kick', "Neutral", '2Take1Script Automod')
            end

            Log('Player: ' .. get.Name(args.player) .. '\nReason: Chat Blacklist\nReaction: Kick\nDetails: ' .. dtcstring, '[Automod]')

            if IsFeatOn('Ad Blacklist Fake Friends') then
                if IsFakeFriend(args.player) then
                    Log('Player already exists in Blacklist')
                else
                    utility.write(io.open(files['FakeFriends'], 'a'), get.Name(args.player) .. ':' .. Math.DecToHex(get.SCID(args.player)) .. ":c")
                end

            end

            SmartKick(args.player)

            detected = false
        end
    end
end


function chatevents.ChatCommands(args)
    if not args or not args.player or not args.body then
        return
    end

    if args.player ~= args.sender then
        return
    end

    local id = args.player
    local text = args.body

    if IsFeatOn('cmd_clearwanted') and string.find(text, '/clearwanted', 1) then
        local entitled, pl_id = IsEntitled(id, nil, 'Clear Wanted', 'cmd_clearwanted')

        if entitled then
            scriptevent.Send('Remove Wanted', {Self(), scriptevent.MainGlobal(id)}, id)
        end

    end

    if IsFeatOn('cmd_giveweapons') and string.find(text, '/giveweapons', 1) then
        local entitled, pl_id = IsEntitled(id, nil, 'Give Weapons', 'cmd_giveweapons')

        if entitled then
            local all_weapons = weapon.get_all_weapon_hashes()

            for i = 1, #all_weapons do
                if not weapon.has_ped_got_weapon(get.PlayerPed(id), all_weapons[i]) then
                    weapon.give_delayed_weapon_to_ped(get.PlayerPed(id), all_weapons[i], 0, 0)
                end

            end

        end

    end

    if IsFeatOn('cmd_rpdrop') and string.find(text, '/rpdrop', 1) then
        local entitled, pl_id = IsEntitled(id, nil, 'RP Drop', 'cmd_rpdrop')

        if entitled then
            text = string.gsub(text, '/rpdrop ', '')

            if text == 'on' and not Script.PlayerFeature['RP Drop'].on[id] then
                menu.get_feature_by_hierarchy_key('online.online_players.player_' .. id .. '.script_features.2take1script.friendly.rp_drop'):toggle()
            elseif text == 'off' and Script.PlayerFeature['RP Drop'].on[id] then
                menu.get_feature_by_hierarchy_key('online.online_players.player_' .. id .. '.script_features.2take1script.friendly.rp_drop'):toggle()
            end  

        end

    end

    if IsFeatOn('cmd_removeweapons') and string.find(text, '/removeweapons ', 1) then
        text = string.gsub(text, '/removeweapons ', '')
        local entitled, pl_id = IsEntitled(id, text, 'Remove Weapons', 'cmd_removeweapons')

        if entitled then
            weapon.remove_all_ped_weapons(get.PlayerPed(pl_id))
        end

    end

    if IsFeatOn('cmd_setbounty') and string.find(text, '/setbounty ', 1) then
        text = string.gsub(text, '/setbounty ', '')
        local entitled, pl_id = IsEntitled(id, text, 'Set Bounty', 'cmd_setbounty')

        if entitled then
            scriptevent.Send('Bounty', {Self(), pl_id, 1, 10000, 0, 1,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, scriptevent.GlobalPair()}, script.get_host_of_this_script())
        end

    end

    if IsFeatOn('cmd_explode') and string.find(text, '/explode ', 1) then
        text = string.gsub(text, '/explode ', '')
        local entitled, pl_id = IsEntitled(id, text, 'Explode', 'cmd_explode')

        if entitled then
            fire.add_explosion(get.PlayerCoords(pl_id), 59, false, true, 1, get.PlayerPed(id))
            fire.add_explosion(get.PlayerCoords(pl_id), 8, false, true, 1, get.PlayerPed(id))
            fire.add_explosion(get.PlayerCoords(pl_id), 59, false, true, 1, get.PlayerPed(id))
        end

    end

    if IsFeatOn('cmd_trap') and string.find(text, '/trap ', 1) then
        text = string.gsub(text, '/trap ', '')
        local entitled, pl_id = IsEntitled(id, text, 'Trap', 'cmd_trap')

        if entitled then
            local pos = get.PlayerCoords(pl_id)
            entity.set_entity_rotation(Spawn.Object(1125864094, v3(pos.x, pos.y, pos.z - 5)), v3(0, 90, 0))
        end

    end

    if IsFeatOn('cmd_kick') and string.find(text, '/kick ', 1) then
        text = string.gsub(text, '/kick ', '')
        local entitled, pl_id = IsEntitled(id, text, 'Kick', 'cmd_kick')

        if entitled then
            SmartKick(pl_id)
        end

    end
    
    if IsFeatOn('cmd_crash') and string.find(text, '/crash ', 1) then
        text = string.gsub(text, '/crash ', '')
        local entitled, pl_id = IsEntitled(id, text, 'Crash', 'cmd_crash')

        if entitled then
            scriptevent.crash(pl_id)
        end

    end

    if IsFeatOn('cmd_spawn') and string.find(text, '/spawn ', 1) then
        text = string.gsub(text, '/spawn ', '')
        local entitled, pl_id = IsEntitled(id, nil, 'Spawn', 'cmd_spawn')

        if entitled then
            local hash = gameplay.get_hash_key(text)

            if hash == 956849991 or hash == 1133471123 or hash == 2803699023 or hash == 386089410 or hash == 1549009676 then
                return
            end

            if streaming.is_model_a_vehicle(hash) then
                local spawned_veh = Spawn.Vehicle(hash, utility.OffsetCoords(get.PlayerCoords(id), player.get_player_heading(id), 10), player.get_player_heading(id))

                if utility.request_ctrl(spawned_veh) then
                    vehicle.set_vehicle_window_tint(spawned_veh, 1)
                    decorator.decor_set_int(spawned_veh, 'MPBitset', 1 << 10)
                    utility.MaxVehicle(spawned_veh, 2)
                end

            end

        end

    end
    
    if IsFeatOn('cmd_vehiclegod') and string.find(text, '/vehiclegod ', 1) then
        local entitled, pl_id = IsEntitled(id, nil, 'VehicleGod', 'cmd_vehiclegod')

        if entitled then
            local veh = get.PlayerVehicle(id)

            if veh ~= 0 then
                text = string.gsub(text, '/vehiclegod ', '')
                local toggle

                if text == 'off' then
                    toggle = false
                end

                if text == 'on' then
                    toggle = true
                end

                if not utility.request_ctrl(veh, 5000) then
                    Notify('Failed to gain control over the Players vehicle.\nThe command might not have worked.', "Error")
                end

                if toggle ~= nil then
                    entity.set_entity_god_mode(veh, toggle)
                end
            else
                Notify('Couldnt find the Players vehicle, they might be too far away.', "Error")
            end

        end

    end

    if IsFeatOn('cmd_upgrade') and string.find(text, '/upgrade', 1) then
        local entitled, pl_id = IsEntitled(id, nil, 'Upgrade', 'cmd_upgrade')

        if entitled then
            local veh = get.PlayerVehicle(id)

            if veh ~= 0 then
                if not utility.request_ctrl(veh, 5000) then
                    Notify('Failed to gain control over the Players vehicle.\nThe command might not have worked.', "Error")
                end
                utility.MaxVehicle(veh)
            else
                Notify('Couldnt find the Players vehicle, they might be too far away.', "Error")
            end

        end

    end

    if IsFeatOn('cmd_repair') and string.find(text, '/repair', 1) then
        local entitled, pl_id = IsEntitled(id, nil, 'Repair', 'cmd_repair')

        if entitled then
            local veh = get.PlayerVehicle(id)

            if veh ~= 0 then
                if not utility.request_ctrl(veh, 5000) then
                    Notify('Failed to gain control over the Players vehicle.\nThe command might not have worked.', "Error")
                end
                utility.RepairVehicle(veh)
            else
                Notify('Couldnt find the Players vehicle, they might be too far away.', "Error")
            end

        end

    end

    if IsFeatOn('cmd_explode_all') and string.find(text, '/explodeall', 1) and id == Self() then
        local entitled, pl_id = IsEntitled(id, nil, 'Explode All', 'cmd_explode_all')

        if entitled then
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Block Friends as Target')) then
                    fire.add_explosion(get.PlayerCoords(id), 59, true, false, 1, get.OwnPed())
                end

            end
            
        end

    end

    if IsFeatOn('cmd_scriptkick_all') and string.find(text, '/scriptkickall', 1) and id == Self() then
        local entitled, pl_id = IsEntitled(id, nil, 'Scriptkick All', 'cmd_scriptkick_all')

        if entitled then
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Block Friends as Target')) then
                    scriptevent.kick(id)
                end

                coroutine.yield(0)
            end

        end

    end

    if IsFeatOn('cmd_desynckick_all') and string.find(text, '/desynckickall', 1) and id == Self() then
        local entitled, pl_id = IsEntitled(id, nil, 'Desynckick All', 'cmd_desynckick_all')

        if entitled then
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Block Friends as Target')) then
                    SmartKick(id)
                end

                coroutine.yield(0)
            end

        end

    end

    if IsFeatOn('cmd_crash_all') and string.find(text, '/crashall', 1) and id == Self() then
        local entitled, pl_id = IsEntitled(id, nil, 'Crash All', 'cmd_crash_all')

        if entitled then
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Block Friends as Target')) then
                    scriptevent.crash(id)
                end

                coroutine.yield(0)
            end
        end
    end
end


function chatevents.EchoChat(args)
    if not args or not args.player or not args.body then
        return
    end

    if args.player ~= Self() then
        for i = 1, Script.Feature['Echo Chat'].value do
            network.send_chat_message(args.body, false)
        end
    end
end


--[[
function chatevents.Profanityfilter(args)
    if not args or not args.player or not args.body then
        return
    end

    if utility.valid_modder(args.player) then
        for i = 1, #stringData.profanity do
            if string.find(args.body, stringData.profanity[i], -1) then
                if Script.Feature['Modder Detection Profanity'].value == 0 then
                    Log('Player: ' .. get.Name(args.player) .. '\nReason: Profanity Filter Bypass\nDetected String: ' .. stringData.profanity[i], '[Modder Detection]')
                    Notify('Player: ' .. get.Name(args.player) .. '\nReason: Profanity Filter Bypass\nReaction: Notify', "Neutral", '2Take1Script Modder Detection')
                    coroutine.yield(60000)
                else
                    Log('Player: ' .. get.Name(args.player) .. '\nReason: Profanity Filter Bypass\nDetected String: ' .. stringData.profanity[i], '[Modder Detection]')
                    player.mark_as_modder(args.player, customflags['Profanity Filter Bypass'])
                end
            end
        end
    end
end
]]


local playerevents = {}
function playerevents.DetectByName(target)
    if not target then
        return
    end

    if utility.valid_player(target.player, IsFeatOn('Exclude Friends')) then
        local detected = false
        local dtcstring

        local stringset = stringData.NameStrings.Safe
        if Script.Feature['Ad Blacklist Name Strings'].value == 1 then
            stringset = stringData.NameStrings.Aggressive
        end

        for i = 1, #stringset do
            if string.find(get.Name(target.player), stringset[i]) then
                dtcstring = stringset[i]
                detected = true
            end
        end

        if detected then
            if not IsFeatOn('Ad Blacklist Disable Notifications') then
                Notify('Player: ' .. get.Name(target.player) .. '\nReason: Name Blacklist\nReaction: Kick', "Neutral", '2Take1Script Automod')
            end

            Log('Player: ' .. get.Name(target.player) .. '\nReason: Name Blacklist\nReaction: Kick\nDetails: ' .. dtcstring, '[Automod]')

            if IsFeatOn('Ad Blacklist Fake Friends') then
                if IsFakeFriend(target.player) then
                    Log('Player already exists in Blacklist')
                else
                    utility.write(io.open(files['FakeFriends'], 'a'), get.Name(target.player) .. ':' .. Math.DecToHex(get.SCID(target.player)) .. ":c")
                end
            end

            SmartKick(target.player)
        end
    end
end


function playerevents.PunishChinese(target)
    if not target then
        return
    end

    if utility.valid_player(target.player, IsFeatOn('Exclude Friends')) then

        local IP = get.IP(target.player)
        local State, Result = web.get("http://ip-api.com/csv/" .. IP)

        if State ~= 200 then
            return
        end

        local parts = {}
        for part in Result:gmatch("[^,]+") do
            parts[#parts + 1] = part
        end

        local Success = parts[1]
        if Success == 'fail' then
            return
        end

        if string.find(parts[2], 'China', 1) and Script.Feature['GEO-Block China'].value ~= 3 then
            if Script.Feature['GEO-Block China'].value == 0 then
                coroutine.yield(5000)
                scriptevent.kick(target.player)

            elseif Script.Feature['GEO-Block China'].value == 1 then
                SmartKick(target.player)

            elseif Script.Feature['GEO-Block China'].value == 2 then
                coroutine.yield(5000)
                scriptevent.crash(target.player)
            end

            Log('Player: ' .. get.Name(target.player) .. '\nReason: Chinese IP')
            Notify('Player: ' .. get.Name(target.player) .. '\nReason: Chinese IP', "Neutral", '2Take1Script Automod')

            return
        end
    end
end


function playerevents.PunishRussian(target)
    if not target then
        return
    end

    if utility.valid_player(target.player, IsFeatOn('Exclude Friends')) then

        local IP = get.IP(target.player)
        local State, Result = web.get("http://ip-api.com/csv/" .. IP)

        if State ~= 200 then
            return
        end

        local parts = {}
        for part in Result:gmatch("[^,]+") do
            parts[#parts + 1] = part
        end

        local Success = parts[1]
        if Success == 'fail' then
            return
        end

        if string.find(parts[2], 'Russia', 1) and Script.Feature['GEO-Block Russia'].value ~= 3 then
            if Script.Feature['GEO-Block Russia'].value == 0 then
                coroutine.yield(5000)
                scriptevent.kick(target.player)

            elseif Script.Feature['GEO-Block Russia'].value == 1 then
                SmartKick(target.player)

            elseif Script.Feature['GEO-Block Russia'].value == 2 then
                coroutine.yield(5000)
                scriptevent.crash(target.player)
            end

            Log('Player: ' .. get.Name(target.player) .. '\nReason: Russian IP')
            Notify('Player: ' .. get.Name(target.player) .. '\nReason: Russian IP', "Neutral", '2Take1Script Automod')

            return
        end
    end
end


function playerevents.remember(target)
    if not target or not utils.file_exists(files['Modder']) then
        return
    end
    
    local id = target.player
    local remembered = {}

    if not player.can_player_be_modder(id) then
        return
    end

    for line in io.lines(files['Modder']) do
        local parts = {}
        for part in line:gmatch("[^:]+") do
            parts[#parts + 1] = part
        end
        if #parts >= 3 then
            local name = parts[1]
            local scid = tonumber(parts[2])
            local reason = parts[3]
            remembered[scid] = {Name=name, Flag=reason}
        end
    end

    
    local scid = get.SCID(id)

    if remembered[scid] then
        local name = get.Name(id)

        Log('Player: ' .. name .. '\nReason: Remembered\nModderflag: ' .. remembered[scid].Flag, '[Modder Detection]')
        player.mark_as_modder(id, customflags['Remembered'])
    end
end


local modderevents = {}
function modderevents.godmode(target)
    if not target then
        return
    end
    
    local rate = 1
    local InitialPos = get.PlayerCoords(target)
    coroutine.yield(20000)

    local NewPos = get.PlayerCoords(target)
    if utility.valid_modder(target) and get.GodmodeState(target) and InitialPos:magnitude(NewPos) > 20 then
        rate = rate + 1
    end
    coroutine.yield(20000)

    InitialPos = get.PlayerCoords(target)
    if utility.valid_modder(target) and get.GodmodeState(target) and InitialPos:magnitude(NewPos) > 20 then
        rate = rate + 1
    end
    coroutine.yield(20000)
    
    NewPos = get.PlayerCoords(target)
    if utility.valid_modder(target) and get.GodmodeState(target) and InitialPos:magnitude(NewPos) > 20 then
        rate = rate + 1
    end
    
    if utility.valid_modder(target) and rate > 3 then
        local Name = get.Name(target)

        if Script.Feature['Modder Detection Player Godmode'].value == 0 then
            Notify('Player: ' .. Name .. '\nReason: Player Godmode\nReaction: Notify', "Neutral", '2Take1Script Modder Detection')
            coroutine.yield(60000)

        else
            Log('Player: ' .. Name .. '\nReason: Player Godmode', '[Modder Detection]')
            player.mark_as_modder(target, customflags['Player Godmode'])

        end

    end
end


function modderevents.vehiclegodmode(target)
    if not target then
        return
    end

    local rate = 1
    local InitialPos = get.PlayerCoords(target)
    coroutine.yield(20000)
    
    local NewPos = get.PlayerCoords(target)
    if utility.valid_modder(target) and get.VehicleGodmodeState(target) and InitialPos:magnitude(NewPos) > 20 then
        rate = rate + 1
    end
    coroutine.yield(20000)

    local InitialPos = get.PlayerCoords(target)
    if utility.valid_modder(target) and get.VehicleGodmodeState(target) and InitialPos:magnitude(NewPos) > 20 then
        rate = rate + 1
    end
    coroutine.yield(20000)

    local NewPos = get.PlayerCoords(target)
    if utility.valid_modder(target) and get.VehicleGodmodeState(target) and InitialPos:magnitude(NewPos) > 20 then
        rate = rate + 1
    end
    
    if utility.valid_modder(target) and rate > 3 then
        local Name = get.Name(target)

        if Script.Feature['Modder Detection Vehicle Godmode'].value == 0 then
            Notify('Player: ' .. Name .. '\nReason: Vehicle Godmode\nReaction: Notify', "Neutral", '2Take1Script Modder Detection')
            coroutine.yield(60000)

        else
            Log('Player: ' .. Name .. '\nReason: Vehicle Godmode', '[Modder Detection]')
            player.mark_as_modder(target, customflags['Vehicle Godmode'])
            
        end

    end
end


function modderevents.autokick(target)
    if not target then
        return
    end

    local id = target.player
    local flag = target.flag
    local name = player.get_modder_flag_text(flag)
    local playername = get.Name(id)
    local responses = {'Kick', 'Kick & Blacklist'}

    if utility.valid_player(id, (Script.Feature['Enable Auto Kick Modder'].value == 1)) then
        Log('Player: ' .. playername .. '\nReason: ' .. name .. '\nReaction: ' .. responses[Script.Feature['Autokick ' .. name].value + 1], '[Autokick Modder]')
        Notify('Player: ' .. playername .. '\nReason: ' .. name .. '\nReaction: ' .. responses[Script.Feature['Autokick ' .. name].value + 1], "Neutral", '2Take1Script Autokick Modder')
            
        if Script.Feature['Autokick ' .. name].value == 1 and not IsFakeFriend(id) then
            utility.write(io.open(files['FakeFriends'], 'a'), playername .. ':' .. Math.DecToHex(get.SCID(id)) .. ":c")
        end

        SmartKick(id)
    end

end


function modderevents.remember(target)
    if not target then
        return
    end

    local id = target.player
    local flag = target.flag
    local text = player.get_modder_flag_text(flag)
    local name = get.Name(id)
    local scid = get.SCID(id)
    
    if not utils.file_exists(files['Modder']) then
        utility.write(io.open(files['Modder'], 'a'), name .. ':' .. scid .. ':' ..  text)
        if Script.Parent['Remember Modder Profiles'] then
            Script.Feature[name .. '/' .. text] = menu.add_feature(name, 'action_value_str',  Script.Parent['Remember Modder Profiles'].id, function(f)
                if f.value == 0 then
                    Notify('Name: ' .. name .. '\nSCID: ' .. scid .. '\nReason: ' .. text, "Neutral", '2Take1Script Remember Modder')
                elseif f.value == 1 then
                    local remembered = {}
                    for line2 in io.lines(files['Modder']) do
                        remembered[line2] = true
                    end

                    remembered[name .. ':' .. scid .. ':' .. text] = nil
        
                    utility.write(io.open(files['Modder'], 'w'))
                    for k in pairs(remembered) do
                        utility.write(io.open(files['Modder'], 'a'), k)
                    end

                    menu.delete_feature(f.id)
                    Notify('Entry Deleted', "Success", '2Take1Script Remember Modder')
                else
                    utils.to_clipboard(scid)
                    Notify('SCID copied to clipboard', "Success", '2Take1Script Remember Modder')
                end
            end)
            Script.Feature[name .. '/' .. text]:set_str_data({'Show Info', 'Delete', 'Copy SCID'})
        end
        return
    end

    local remembered = {}
    for line in io.lines(files['Modder']) do
        local parts = {}
        for part in line:gmatch("[^:]+") do
            parts[#parts + 1] = part
        end
        if #parts >= 3 then
            local name = parts[1]
            local scid = tonumber(parts[2])
            local reason = parts[3]
            remembered[scid] = {Name=name}
        end
    end

    if not remembered[scid] then
        utility.write(io.open(files['Modder'], 'a'), name .. ':' .. scid .. ':' ..  text)

        if Script.Parent['Remember Modder Profiles'] then
            Script.Feature[name .. '/' .. text] = menu.add_feature(name, 'action_value_str',  Script.Parent['Remember Modder Profiles'].id, function(f)
                if f.value == 0 then
                    Notify('Name: ' .. name .. '\nSCID: ' .. scid .. '\nReason: ' .. text, "Neutral", '2Take1Script Remember Modder')
                elseif f.value == 1 then
                    local remembered = {}
                    for line2 in io.lines(files['Modder']) do
                        remembered[line2] = true
                    end

                    remembered[name .. ':' .. scid .. ':' .. text] = nil
        
                    utility.write(io.open(files['Modder'], 'w'))
                    for k in pairs(remembered) do
                        utility.write(io.open(files['Modder'], 'a'), k)
                    end

                    menu.delete_feature(f.id)
                    Notify('Entry Deleted', "Success", '2Take1Script Remember Modder')
                else
                    utils.to_clipboard(scid)
                    Notify('SCID copied to clipboard', "Success", '2Take1Script Remember Modder')
                end
            end)
            Script.Feature[name .. '/' .. text]:set_str_data({'Show Info', 'Delete', 'Copy SCID'})
        end
    end
end

chatevents.listener =  event.add_event_listener('chat', function(message)
    if IsFeatOn('Log Chat') then
        menu.create_thread(chatevents.LogChat, message)
    end

    if IsFeatOn('Ad Blacklist Chat Strings') then
        menu.create_thread(chatevents.DetectByMessage, message)
    end

    if IsFeatOn('GEO-Block Russia') then
        menu.create_thread(chatevents.PunishRussian, message)
    end

    if IsFeatOn('GEO-Block China') then
        menu.create_thread(chatevents.PunishChinese, message)
    end

    if IsFeatOn('Enable Commands') then
        menu.create_thread(chatevents.ChatCommands, message)
    end

    if IsFeatOn('Echo Chat') then
        menu.create_thread(chatevents.EchoChat, message)
    end

    --[[
    if IsFeatOn('Modder Detection Profanity') then
        menu.create_thread(chatevents.Profanityfilter, message)
    end
    ]]

    if IsFeatOn('Anti Chat Spam') then
        menu.create_thread(chatevents.AntiChatSpam, message)
    end
end)


playerevents.joinlistener = event.add_event_listener('player_join', function(target)
    playerlogging[target.player] = {ID = target.player, Name = get.Name(target.player)}

    if Script.Parent['Player Blame Kill'] and not playerblamekill[target.player] then
        playerblamekill[target.player] = menu.add_player_feature(get.Name(target.player), 'action', Script.Parent['Player Blame Kill'].id, function(f, id)
            ped.clear_ped_tasks_immediately(get.PlayerPed(target.player))
            fire.add_explosion(get.PlayerCoords(target.player), 5, false, true, 1, get.PlayerPed(id))
        end)

    end

    if IsFeatOn('Modder Detection Remember') then
        menu.create_thread(playerevents.remember, target)
    end

    if IsFeatOn('Ad Blacklist Name Strings') then
        menu.create_thread(playerevents.DetectByName, target)
    end

    if IsFeatOn('GEO-Block Russia') and menu.is_trusted_mode_enabled(1 << 3) then
        menu.create_thread(playerevents.PunishRussian, target)
    end

    if IsFeatOn('GEO-Block China') and menu.is_trusted_mode_enabled(1 << 3) then
        menu.create_thread(playerevents.PunishChinese, target)
    end

    if not Script.Parent['PFS ' .. target.player] then
        CreatePlayerSearch(target.player)
    end
end)


playerevents.leavelistener = event.add_event_listener('player_leave', function(target)
    if Script.Parent['PFS ' .. target.player] then
        DeleteFeature(Script.Parent['PFS ' .. target.player])
        Script.Parent['PFS ' .. target.player] = nil
        playerResult[target.player] = nil
    end

    if Script.Parent['Player Blame Kill'] and playerblamekill[target.player] then
        menu.delete_player_feature(playerblamekill[target.player].id)
        playerblamekill[target.player] = nil
    end

    if antispam[target] then
        antispam[target] = nil
    end
end)


modderevents.listener = event.add_event_listener('modder', function(target)
    local name = get.Name(target.player)
    local text = player.get_modder_flag_text(target.flag)

    if IsFeatOn('Log Modder Detections') then
        Log('[Modder Detection] Player: ' .. name .. ' [' .. get.SCID(target.player) .. ']\nReason: ' .. text)
    end

    if IsFeatOn('Modder Detection Announce') then
        local team
        if Script.Feature['Modder Detection Announce'].value == 0 then
            team = false
        else
            team = true
        end

        network.send_chat_message("Detected '" .. name .. "' as Modder with the Reason '" .. text .. "'", team)
    end

    if IsFeatOn('Announce Crash Attempts') and string.find(text:lower(), 'crash') then
        local menunames = {'2Take1', 'Modest Menu', 'Cherax', 'Stand', 'Terror'}
        local menuname = menunames[Script.Feature['Announce Crash Attempts'].value + 1]

        network.send_chat_message(name .. " failed to crash a " .. menuname .. " user", false)
    end

    if IsFeatOn('Modder Detection Remember') and IsFeatOn('Remember ' .. text) then
        menu.create_thread(modderevents.remember, target)
    end

    if IsFeatOn('Enable Auto Kick Modder') and IsFeatOn('Autokick ' .. text) then
        menu.create_thread(modderevents.autokick, target)
    end
end)

local typingplayers = {}
local mainscripthook = hook.register_script_event_hook(function(source, target, params, count)
    if target ~= Self() then
        return
    end

    local name = get.Name(source)

    if params[1] == scriptevent['Typing Begin'] then
        for i = 1, #typingplayers do
            if typingplayers[i] == name then
                return
            end
        end

        typingplayers[#typingplayers + 1] = name

        menu.create_thread(function(ID)
            local Name = get.Name(ID)
            local Time = utils.time_ms() + 10000

            while Time > utils.time_ms() and player.is_player_valid(ID) do
                coroutine.yield(100)
            end

            for i = 1, #typingplayers do
                if typingplayers[i] == Name then
                    typingplayers[i] = nil
                end
            end
        end, source)
        
    elseif params[1] == scriptevent['Typing Stop'] then
        for i = 1, #typingplayers do
            if typingplayers[i] == name then
                typingplayers[i] = nil
            end
        end

    elseif IsFeatOn('Modder Detection Script Events') and utility.valid_modder(source) then
        local guilty = false
        for i = 2, #params do
            params[i] = params[i] & 0xFFFFFFFF
        end

        if #params < 2 then
            guilty = true
            goto continue
        end

        if source ~= params[2] then
            guilty = true
            goto continue
        end

        if Script.Feature['Modder Detection Script Events'].value == 0 then
            goto continue
        end
            
        if params[1] == scriptevent['CEO Money'] and (scriptevent.CEOID(Self()) ~= source) then
            guilty = true

        elseif params[1] == scriptevent['Apartment Invite'] and (params[6] == 115 or params[6] > 128) then
            guilty = true

        elseif params[1] == scriptevent['Destroy Personal Vehicle'] then
            guilty = true

        elseif params[1] == scriptevent['Passive Mode'] and params[3] == 1 then
            guilty = true

        --[[
        elseif params[1] == scriptevent['Transaction Error'] and params[3] == 5000 then
            guilty = true

        elseif params[1] == scriptevent['Force To Island'] then
            guilty = true
        ]]

        elseif params[1] == scriptevent['Force To Mission'] then
            guilty = true

        --[[
        elseif params[1] == scriptevent['Casino Cutscene'] then
            guilty = true
        ]]

        elseif params[1] == scriptevent['SMS'] then
            guilty = true

        elseif params[1] == scriptevent['Vehicle Kick'] then
            local Veh = get.OwnVehicle()

            if Veh ~= 0 and Veh ~= scriptevent.GetPersonalVehicle(source) then
                return true
            end

        end

        ::continue::
        if guilty then
            local se = params[1] .. ', {'
            for i = 2, #params do
                se = se .. params[i]
                if i ~= #params then
                    se = se .. ', '
                end
            end
            se = se .. '}'
            Log('Player: ' .. name .. '\nReason: Modded Script Event\nDetected Script Event: ' .. se, '[Modder Detection]')
            player.mark_as_modder(source, customflags['Modded Script Event'])

            return true
        end
    end
end)

local mainnethook = hook.register_net_event_hook(function(source, target, eventId)
    if target ~= Self() then
        return
    end

    local name = get.Name(source)

    if IsFeatOn('Modder Detection Net Events') and utility.valid_modder(source) then
        local guilty = false

        for i = 1, #bad_net_events do
            if eventId == bad_net_events[i] then
                guilty = true
            end
        end

        if guilty then
            if Script.Feature['Modder Detection Net Events'].value == 0 then
                Notify('Player: ' .. name .. '\nReason: Bad Net Event\nReaction: Notify', "Neutral", '2Take1Script Modder Detection')
                coroutine.yield(60000)
            else
                Log('Player: ' .. name .. '\nReason: Bad Net Event\nDetected Net Event: ' .. mapper.net.GetEventName(eventId), '[Modder Detection]')
                player.mark_as_modder(source, customflags['Bad Net Event'])
            end

            return false
        end
    end

    if IsFeatOn('Kick Vote-Kicker') and utility.valid_player(source, IsFeatOn('Exclude Friends')) and eventId == 64 then
        Log('Player: ' .. name .. '\nReason: Kick Votes\nReaction: Kick', '[Automod]')
        if Script.Feature['Kick Vote-Kicker'].value == 0 then
            Notify('Player: ' .. name .. '\nReason: Kick Votes\nReaction: Script Kick', "Neutral", '2Take1Script Automod')
            scriptevent.kick(source)

        elseif Script.Feature['Kick Vote-Kicker'].value == 1 then
            Notify('Player: ' .. name .. '\nReason: Kick Votes\nReaction: Desync Kick', "Neutral", '2Take1Script Automod')
            SmartKick(source)
        end
    end
end)

local exitlistener = event.add_event_listener('exit', function()
    for i in pairs(robot_objects) do
        utility.clear({robot_objects[i]})
    end

    for i in pairs(entitys) do
        utility.clear(entitys[i])
    end

    utility.clear({model_gun, balll})

    if ptfxs['flamethrower'] then
        graphics.remove_particle_fx(ptfxs['flamethrower'], true)
    end

    if ptfxs['flamethrower_green'] then
        graphics.remove_particle_fx(ptfxs['flamethrower_green'], true)
    end

    -- stop ai driving
    if IsFeatOn('AI Driving Start') then
        local veh = get.OwnVehicle()
        ped.clear_ped_tasks_immediately(get.OwnPed())
        ped.set_ped_into_vehicle(get.OwnPed(), veh, -1)
    end

    -- remove player blips
    for i = 0, 31 do
        if OTRBlip[i] then
            ui.remove_blip(OTRBlip[i])
        end
    end

    local commands = {'tp', 'anticrashcam', 'crashlobby', 'kicklobby', 'iplookup', 'modelchange', 'copy'}
    for i = 1, #commands do
        console.remove_command(commands[i])
    end

    -- remove event hooks (likely not needed anymore)
    for i = 0, 31 do
        if hooks.script[i] then
            hook.remove_script_event_hook(hooks.script[i])
        end
    end

    for i = 0, 31 do
        if hooks.net[i] then
            hook.remove_net_event_hook(hooks.net[i])
        end
    end

    hook.remove_script_event_hook(mainscripthook)
    hook.remove_net_event_hook(mainnethook)

    -- remove event listeners (likely not needed anymore)
    event.remove_event_listener('chat', chatevents.listener)
    event.remove_event_listener('modder', modderevents.listener)
    event.remove_event_listener('player_join', playerevents.joinlistener)
    event.remove_event_listener('player_leave', playerevents.leavelistener)

    print('2Take1Script unloaded, goodbye :wave:')
    Log('2Take1Script unloaded, goodbye :wave:')
    Notify('2Take1Script unloaded\nGoodbye :wave:', "Success")
end)

if utils.file_exists(files['DefaultConfig']) then
    for line in io.lines(files['DefaultConfig']) do
        local parts = {}
        for part in line:gmatch("[^:]+") do
            parts[#parts + 1] = part
        end
        local name = parts[1]
        if name == '2Take1Script Parent' then
            if tostring(parts[2]) == 'nil' then
                settings[name].Enabled = true
            elseif parts[2] == 'true' then
                settings[name].Enabled = true
            elseif parts[2] == 'false' then
                settings[name].Enabled = false
            end

        elseif name == 'Enable Vehicle Spawner' then
            if tostring(parts[2]) == 'nil' then
                settings[name].Enabled = false
            elseif parts[2] == 'true' then
                settings[name].Enabled = true
            elseif parts[2] == 'false' then
                settings[name].Enabled = false
            end
        end
    end
end


local function PlayerAutocomplete(s, e, t)
    local args = {}
    local argsN = 0
    for arg in s:gmatch("[^ ]+") do
        argsN = argsN + 1
        args[argsN] = arg
    end
    
    local retVal = {}
    if argsN == 1 then
        for pid = 0, 31 do
            if player.is_player_valid(pid) or (pid == Self() and not e) then
                retVal[#retVal + 1] = string.format("%s %s", args[1], player.get_player_name(pid))
            end
        end
    else
        local filter = args[2]:lower()
        for pid = 0, 31 do
            if player.is_player_valid(pid) or (pid == Self() and not e) then
                local name = player.get_player_name(pid)
                if name:lower():find(filter, 1, true) then
                    retVal[#retVal + 1] = string.format("%s %s", args[1], name)
                end
            end
        end
    end

    return retVal
end


local function CheckArgs(s, t)
    for i = 1, #t do
        if s == t[i] then
            return true
        end
    end

    return false
end


local function TripleArgResult(s, t, e)
    local args = {}
    local argsN = 0
    for arg in s:gmatch("[^ ]+") do
        argsN = argsN + 1
        args[argsN] = arg
    end
    
    local retVal = {}
    if argsN == 1 then
        for i = 1, #t do
            retVal[#retVal + 1] = string.format("%s %s", args[1], t[i])
        end

    elseif argsN == 2 and not CheckArgs(args[2], t) then
        for i = 1, #t do
            if t[i]:lower():find(args[2], 1, true) then
                retVal[#retVal + 1] = string.format("%s %s", args[1], t[i])
            end
        end

    elseif argsN == 2 then
        for pid = 0, 31 do
            if player.is_player_valid(pid) and (pid == Self() and not e) then
                retVal[#retVal + 1] = string.format("%s %s", args[1] .. ' ' .. args[2], player.get_player_name(pid))
            end
        end

    else
        local filter = args[3]:lower()
        for pid = 0, 31 do
            if player.is_player_valid(pid) and (pid == Self() and not e) then
                local name = player.get_player_name(pid)
                if name:lower():find(filter, 1, true) then
                    retVal[#retVal + 1] = string.format("%s %s", args[1] .. ' ' .. args[2], name)
                end
            end
        end
    end

    return retVal
end


local function AutoResult(s, t)
    local args = {}
    local argsN = 0
    for arg in s:gmatch("[^ ]+") do
        argsN = argsN + 1
        args[argsN] = arg
    end
    
    local retVal = {}
    if argsN == 1 then
        for i = 1, #t do
            retVal[#retVal + 1] = string.format("%s %s", args[1], t[i])
        end
    else
        local filter = args[2]:lower()
        for i = 1, #t do
            local name = t[i]
            if name:lower():find(filter, 1, true) then
                retVal[#retVal + 1] = string.format("%s %s", args[1], name)
            end
        end
    end

    return retVal
end

local function ArgVerify(s)
    local args = {}
    local argsN = 0
    for arg in s:gmatch("[^ ]+") do
        argsN = argsN + 1
        args[argsN] = arg
    end
    
    if argsN == 1 then
        print('no args provided.')
        return false
    end

    return true
end

--Menu Main Parents
local MainThread1 = menu.create_thread(function()
    if settings['2Take1Script Parent'].Enabled then
        Script.Parent['Main Parent'] = menu.add_feature('2Take1Script', 'parent', 0)
        Script.Parent['Player Parent'] = menu.add_player_feature('2Take1Script', 'parent', 0)
    else
        Script.Parent['Main Parent'] = {id = 0}
        Script.Parent['Player Parent'] = {id = 0}
    end

    Script.Parent['local_player'] = menu.add_feature('Player Options', 'parent', Script.Parent['Main Parent'].id)
    Script.Parent['local_vehicle'] = menu.add_feature('Vehicle Options','parent', Script.Parent['Main Parent'].id)
    Script.Parent['local_lobby'] = menu.add_feature('Lobby Options', 'parent', Script.Parent['Main Parent'].id)
    Script.Parent['local_automod'] = menu.add_feature('Auto Moderation', 'parent', Script.Parent['Main Parent'].id)
    Script.Parent['local_modderdetection'] = menu.add_feature('Modder Detection', 'parent', Script.Parent['Main Parent'].id)
    Script.Parent['local_world'] = menu.add_feature('World', 'parent', Script.Parent['Main Parent'].id)
    Script.Parent['local_stats'] = menu.add_feature('Recovery & Stats', 'parent', Script.Parent['Main Parent'].id)
    Script.Parent['local_misc'] = menu.add_feature('Miscellaneous', 'parent', Script.Parent['Main Parent'].id)
    Script.Parent['local_settings'] = menu.add_feature('Settings', 'parent', Script.Parent['Main Parent'].id)


    Script.Parent['Player Godmode v2'] = menu.add_feature('Customizable Godmode', 'parent', Script.Parent['local_player'].id)


    Script.Feature['Enable Godmode'] = menu.add_feature('Enable Godmode', 'toggle', Script.Parent['Player Godmode v2'].id, function(f)
        if not menu.is_trusted_mode_enabled(1 << 2) then
            Notify('Not available while trusted mode for natives is turned off', 'Error', 'Enable Godmode')
            f.on = false
            return
        end

        settings['Enable Godmode'] = {Enabled = f.on}
        while f.on do
            if not menu.is_trusted_mode_enabled(1 << 2) then
                f.on = false
            end

            N.ENTITY.SET_ENTITY_PROOFS(get.OwnPed(), Script.Feature['Godmode Bullet Proof'].on, Script.Feature['Godmode Fire Proof'].on, Script.Feature['Godmode Explosion Proof'].on, Script.Feature['Godmode Collision Proof'].on, Script.Feature['Godmode Melee Proof'].on, Script.Feature['Godmode Steam Proof'].on, 1, 0)
    
            settings['Enable Godmode'].Enabled = f.on
            coroutine.yield(0)
        end
    
        N.ENTITY.SET_ENTITY_PROOFS(get.OwnPed(), 0, 0, 0, 0, 0, 0, 1, 0)
        settings['Enable Godmode'].Enabled = f.on
    end)

    local proofs = {'Bullet Proof', 'Fire Proof', 'Explosion Proof', 'Collision Proof', 'Melee Proof', 'Steam Proof'}
    for i = 1, #proofs do
        local name = proofs[i]
        Script.Feature['Godmode ' .. name] = menu.add_feature(name, 'toggle', Script.Parent['Player Godmode v2'].id, function(f)
            settings['Godmode ' .. name] = {Enabled = f.on}
        end)
    end


    Script.Parent['Health Features'] = menu.add_feature('Health Modifier', 'parent', Script.Parent['local_player'].id, nil)


    Script.Feature['Fill Health'] = menu.add_feature('Fill Health', 'action', Script.Parent['Health Features'].id, function()
        local maxhealth = player.get_player_max_health(Self())
        if player.get_player_max_health(Self()) ~= player.get_player_health(Self()) then
            ped.set_ped_health(get.OwnPed(), maxhealth)
            Notify('Filled health.', "Success")
        end
    end)


    Script.Feature['Quick Regeneration'] = menu.add_feature('Quick Regeneration', 'toggle', Script.Parent['Health Features'].id, function(f)
        settings['Quick Regeneration'] = {Enabled = f.on}
        while f.on do
            local max = player.get_player_max_health(Self())
            local current = player.get_player_health(Self())
            if max > current then
                ped.set_ped_health(get.OwnPed(), current + 1)
            end
            coroutine.yield(0)
        end
        settings['Quick Regeneration'].Enabled = f.on
    end)


    Script.Feature['Set Health'] = menu.add_feature('Set Health: Input', 'action_value_str', Script.Parent['Health Features'].id, function(f)
        local health = get.Input('Enter Custom Health Value (100 - 1000000000)', 10, 3)
        if not health then
            Notify('Input canceled.', "Error", '')
            return
        end
        if tonumber(health) < 100 or tonumber(health) > 1000000000 then
            Notify('Value must be between 100 and 1000000000', "Error", '')
            return
        end

        if f.value == 0 then
            ped.set_ped_health(get.OwnPed(), health)
        elseif f.value == 1 then
            ped.set_ped_max_health(get.OwnPed(), health)
        else
            ped.set_ped_health(get.OwnPed(), health)
            ped.set_ped_max_health(get.OwnPed(), health)
        end

        Notify('Health successfully set to: ' .. health, "Success")
    end)
    Script.Feature['Set Health']:set_str_data({'Current Health', 'Max Health', 'Both'})


    Script.Feature['Set Armor'] = menu.add_feature('Set Armor: Input', 'action', Script.Parent['Health Features'].id, function(f)
        local armor = get.Input('Enter Custom Armor Value (0 - 1000000000)', 10, 3)
        if not armor then

            Notify('Input canceled.', "Error", '')
            return
        end

        if tonumber(armor) < 0 or tonumber(armor) > 1000000000 then
            Notify('Value must be between 0 and 1000000000', "Error", '')
            return
        end

        player.set_player_armor(armor)

        Notify('Armor successfully set to: ' .. armor, "Success")
    end)


    Script.Feature['Unlimited Regeneration'] = menu.add_feature('Unlimited Regeneration', 'value_str', Script.Parent['Health Features'].id, function(f)
        settings['Unlimited Regeneration'] = {Enabled = f.on}
        while f.on do
            local current = player.get_player_health(Self())
            local new_health = current + current * 0.005
            if new_health < 1000000000 then
                ped.set_ped_health(get.OwnPed(), new_health)
                ped.set_ped_max_health(get.OwnPed(), new_health)
            end
            coroutine.yield(0)
        end
        settings['Unlimited Regeneration'].Enabled = f.on

        if f.value == 1 then
            ped.set_ped_max_health(get.OwnPed(), 328)
            ped.set_ped_health(get.OwnPed(), 328)
        end
    end)
    Script.Feature['Unlimited Regeneration']:set_str_data({'Keep on Disabling', 'Revert on Disabling'})


    Script.Feature['Undead OTR'] = menu.add_feature('Undead OTR', 'toggle', Script.Parent['Health Features'].id, function(f)
        settings['Undead OTR'] = {Enabled = f.on}
        while f.on do
            local max = player.get_player_max_health(Self())
            if max ~= 0 then
                ped.set_ped_max_health(get.OwnPed(), 0)
            end
            coroutine.yield(0)
        end
        settings['Undead OTR'].Enabled = f.on
        ped.set_ped_max_health(get.OwnPed(), 328)
    end)


    Script.Parent['Player Outfitter'] = menu.add_feature('Outfitter', 'parent', Script.Parent['local_player'].id)


    Script.Feature['Random Outfit Components'] = menu.add_feature('Random Outfit Components', 'action_value_str', Script.Parent['Player Outfitter'].id, function(f)
        local values = {1, 3, 11, 8, 4, 6, 9, 5, 10, 7}
        
        if f.value == 10 then
            ped.set_ped_random_component_variation(get.OwnPed())
        else
            utility.random_outfit(get.OwnPed(), values[f.value + 1])
        end
    end)
    Script.Feature['Random Outfit Components']:set_str_data({'Mask', 'Gloves', 'Torso', 'Undershirt', 'Pants', 'Shoes', 'Armor', 'Parachute', 'Decal', 'Accessory', 'All'})


    Script.Feature['Random Outfit Properties'] = menu.add_feature('Random Outfit Properties', 'action_value_str', Script.Parent['Player Outfitter'].id, function(f)
        if f.value == 0 then
            ped.set_ped_prop_index(get.OwnPed(), 0, math.random(0, 162), 0, false)

        elseif f.value == 1 then
            ped.set_ped_prop_index(get.OwnPed(), 1, math.random(0, 41), 0, false)

        elseif f.value == 2 then
            ped.set_ped_prop_index(get.OwnPed(), 2, math.random(0, 21), 0, false)

        elseif f.value == 3 then
            ped.set_ped_prop_index(get.OwnPed(), 6, math.random(0, 20), 0, false)

        elseif f.value == 4 then
            ped.set_ped_prop_index(get.OwnPed(), 7, math.random(0, 20), 0, false)

        else
            ped.set_ped_prop_index(get.OwnPed(), 0, math.random(0, 162), 0, false)
            ped.set_ped_prop_index(get.OwnPed(), 1, math.random(0, 41), 0, false)
            ped.set_ped_prop_index(get.OwnPed(), 2, math.random(0, 21), 0, false)
            ped.set_ped_prop_index(get.OwnPed(), 6, math.random(0, 20), 0, false)
            ped.set_ped_prop_index(get.OwnPed(), 7, math.random(0, 20), 0, false)
        end
    end)
    Script.Feature['Random Outfit Properties']:set_str_data({'Hat', 'Glasses', 'Ear', 'Watch', 'Bracelet', 'All'})


    Script.Feature['Force Police Outfit'] = menu.add_feature('Force Police Outfit', 'toggle', Script.Parent['Player Outfitter'].id, function(f)
        settings['Force Police Outfit'] = {Enabled = f.on}
        while f.on do
            local Gender = 'male'
            if player.is_player_female(Self()) then
                Gender = 'female'
            end

            local Outfit = outfits['police_outfit'][Gender]
            for i = 1, #Outfit['clothes'] do
                ped.set_ped_component_variation(get.OwnPed(), i, Outfit['clothes'][i][2], Outfit['clothes'][i][1], 2)
            end

            for i = 1, #Outfit['props'] do
                ped.set_ped_prop_index(get.OwnPed(), Outfit['props'][i][1], Outfit['props'][i][2], Outfit['props'][i][3], 0)
            end
            
            coroutine.yield(250)
        end
        settings['Force Police Outfit'].Enabled = f.on
    end)


    Script.Feature['Lock Current Outfit'] = menu.add_feature('Lock Current Outfit', 'toggle', Script.Parent['Player Outfitter'].id, function(f)
        settings['Lock Current Outfit'] = {Enabled = f.on}

        local lock = {
            ['textures'] = {},
            ['clothes'] = {},
            ['prop_ind'] = {},
            ['prop_text'] = {}
        }

        local Ped = get.OwnPed()

        for i = 1, 11 do
            lock['textures'][i] = ped.get_ped_texture_variation(Ped, i)
            lock['clothes'][i] = ped.get_ped_drawable_variation(Ped, i)
        end

        local props = {0, 1, 2, 6, 7}
        for i = 1, #props do
            lock['prop_ind'][i] = ped.get_ped_prop_index(Ped, props[i])
            lock['prop_text'][i] = ped.get_ped_prop_texture_index(Ped, props[i])
        end

        while f.on do
            if network.is_session_started() and player.is_player_playing(Self()) then
                for i = 1, 11 do
                    if ped.get_ped_texture_variation(Ped, i) ~= lock['textures'][i] or ped.get_ped_drawable_variation(Ped, i) ~= lock['clothes'][i] then
                        ped.set_ped_component_variation(get.OwnPed(), i, lock['clothes'][i], lock['textures'][i], 2)
                    end
                end

                for i = 1, #props do
                    if ped.get_ped_prop_index(Ped, props[i]) ~= lock['prop_ind'][i] or ped.get_ped_prop_texture_index(Ped, props[i]) ~= lock['prop_text'][i] then
                        ped.set_ped_prop_index(get.OwnPed(), 0, 120, 0, 0)
                        ped.set_ped_prop_index(get.OwnPed(), 1, 13, 0, 0)
                        
                        ped.set_ped_prop_index(get.OwnPed(), props[i], lock['prop_ind'][i], lock['prop_text'][i], 0)
                    end
                end
            end

            coroutine.yield(0)
        end
        settings['Lock Current Outfit'].Enabled = f.on
    end)


    Script.Parent['Weapon Loadout'] = menu.add_feature('Weapon Loadout', 'parent', Script.Parent['local_player'].id, nil)

    Script.Feature['Enable Weapon Loadout'] = menu.add_feature('Enable Weapon Loadout', 'toggle', Script.Parent['Weapon Loadout'].id, function(f)
        settings['Enable Weapon Loadout'] = {Enabled = f.on}
        while f.on do
            for i = 1, #mapper.weapons do
                local WeaponCategory = mapper.weapons[i]

                for j = 1, #WeaponCategory.Children do
                    local CurrentWeapon = WeaponCategory.Children[j]

                    if Script.Feature['Equip ' .. CurrentWeapon.Name].on and not weapon.has_ped_got_weapon(get.OwnPed(), CurrentWeapon.Hash) then
                        weapon.give_delayed_weapon_to_ped(get.OwnPed(), CurrentWeapon.Hash, 0, 0)
                        weapon.set_ped_ammo(get.OwnPed(), CurrentWeapon.Hash, 9999)

                    elseif not Script.Feature['Equip ' .. CurrentWeapon.Name].on and Script.Feature['Weapon Loadout Remove'].on and weapon.has_ped_got_weapon(get.OwnPed(), CurrentWeapon.Hash) then
                        weapon.remove_weapon_from_ped(get.OwnPed(), CurrentWeapon.Hash)
                    end

                    if CurrentWeapon.Components then
                        for k = 1, #CurrentWeapon.Components do
                            local CurrentComponent = CurrentWeapon.Components[k]

                            if Script.Feature['Equip ' .. CurrentWeapon.Name .. ' ' .. CurrentComponent.Name].on then
                                if weapon.has_ped_got_weapon(get.OwnPed(), CurrentWeapon.Hash) and not weapon.has_ped_got_weapon_component(get.OwnPed(), CurrentWeapon.Hash, CurrentComponent.Hash) then
                                    weapon.give_weapon_component_to_ped(get.OwnPed(), CurrentWeapon.Hash, CurrentComponent.Hash)
                                end

                            else
                                if weapon.has_ped_got_weapon(get.OwnPed(), CurrentWeapon.Hash) and weapon.has_ped_got_weapon_component(get.OwnPed(),CurrentWeapon.Hash, CurrentComponent.Hash) then
                                    weapon.remove_weapon_component_from_ped(get.OwnPed(),CurrentWeapon.Hash, CurrentComponent.Hash)
                                end
                            end

                        end

                    end

                end

            end

            coroutine.yield(0)
        end
        settings['Enable Weapon Loadout'].Enabled = f.on
    end)


    Script.Feature['Weapon Loadout Remove'] = menu.add_feature('Remove Not Selected Weapons', 'toggle', Script.Parent['Weapon Loadout'].id, function(f)
        settings['Weapon Loadout Remove'] = {Enabled = f.on}
    end)


    Script.Feature['Weapon Loadout Set All'] = menu.add_feature('Set All', 'action_value_str', Script.Parent['Weapon Loadout'].id, function(f)
        if f.value == 0 then
            for i = 1, #mapper.weapons do
                local WeaponCategory = mapper.weapons[i]

                for j = 1, #WeaponCategory.Children do
                    local CurrentWeapon = WeaponCategory.Children[j]

                    Script.Feature['Equip ' .. CurrentWeapon.Name].on = true
                end

            end
        elseif f.value == 1 then
            for i = 1, #mapper.weapons do
                local WeaponCategory = mapper.weapons[i]

                for j = 1, #WeaponCategory.Children do
                    local CurrentWeapon = WeaponCategory.Children[j]

                    Script.Feature['Equip ' .. CurrentWeapon.Name].on = false
                end

            end

        end
    end)
    Script.Feature['Weapon Loadout Set All']:set_str_data({'Equip', 'Unequip'})


    for i = 1, #mapper.weapons do
        local WeaponCategory = mapper.weapons[i]
        Script.Parent[WeaponCategory] = menu.add_feature(WeaponCategory.Name, "parent", Script.Parent['Weapon Loadout'].id)

        for j = 1, #WeaponCategory.Children do
            local CurrentWeapon = WeaponCategory.Children[j]

            if CurrentWeapon.Components then
                Script.Parent[CurrentWeapon] = menu.add_feature(CurrentWeapon.Name, "parent", Script.Parent[WeaponCategory].id, nil)

                Script.Feature['Equip ' .. CurrentWeapon.Name] = menu.add_feature("Equip", 'toggle', Script.Parent[CurrentWeapon].id, function(f)
                    settings['Equip ' .. CurrentWeapon.Name] = {Enabled = f.on}
                end)

                for k = 1, #CurrentWeapon.Components do
                    local CurrentComponent = CurrentWeapon.Components[k]

                    Script.Feature['Equip ' .. CurrentWeapon.Name .. ' ' .. CurrentComponent.Name] = menu.add_feature(CurrentComponent.Name, 'toggle', Script.Parent[CurrentWeapon].id, function(f)
                        settings['Equip ' .. CurrentWeapon.Name .. ' ' .. CurrentComponent.Name] = {Enabled = f.on}
                    end)

                end

            else
                Script.Feature['Equip ' .. CurrentWeapon.Name] = menu.add_feature(CurrentWeapon.Name, "toggle", Script.Parent[WeaponCategory].id, function(f)
                    settings['Equip ' .. CurrentWeapon.Name] = {Enabled = f.on}
                end)
            end 

        end

    end

    Script.Parent['Weapon Modifier'] = menu.add_feature('Weapon Modifier', 'parent', Script.Parent['local_player'].id, nil)


    Script.Parent['Flamethrower'] = menu.add_feature('Flamethrower', 'parent', Script.Parent['Weapon Modifier'].id, nil)


    Script.Feature['Flamethrower Scale'] = menu.add_feature('Flamethrower Scale', 'autoaction_value_i', Script.Parent['Flamethrower'].id, function(f)
        settings['Flamethrower Scale'] = {Value = f.value}
    end)
    Script.Feature['Flamethrower Scale'].min = 1
    Script.Feature['Flamethrower Scale'].max = 25


    Script.Feature['Flamethrower'] = menu.add_feature('Flamethrower - Normal', 'toggle', Script.Parent['Flamethrower'].id, function(f)
        settings['Flamethrower'] = {Enabled = f.on}
        while f.on do
            if player.is_player_free_aiming(Self()) then
                graphics.set_next_ptfx_asset('weap_xs_vehicle_weapons')
                while not graphics.has_named_ptfx_asset_loaded('weap_xs_vehicle_weapons') do
                    graphics.request_named_ptfx_asset('weap_xs_vehicle_weapons')
                    coroutine.yield(0)
                end

                if not ptfxs['alien'] then
                    ptfxs['alien'] = Spawn.Object(1803116220, get.OwnCoords())
                    entity.set_entity_collision(ptfxs['alien'], false, false, false)
                    entity.set_entity_visible(ptfxs['alien'], false)
                end

                local pos_h = Math.GetPedBoneCoords(get.OwnPed(), 0xdead)
                utility.set_coords(ptfxs['alien'], pos_h)
                entity.set_entity_rotation(ptfxs['alien'], cam.get_gameplay_cam_rot())

                if not ptfxs['flamethrower'] then
                    ptfxs['flamethrower'] = graphics.start_networked_ptfx_looped_on_entity('muz_xs_turret_flamethrower_looping', ptfxs['alien'], v3(), v3(), Script.Feature['Flamethrower Scale'].value)
                    graphics.set_particle_fx_looped_scale(ptfxs['flamethrower'], Script.Feature['Flamethrower Scale'].value)
                end
            else
                if ptfxs['flamethrower'] then
                    graphics.remove_particle_fx(ptfxs['flamethrower'], true)
                    ptfxs['flamethrower'] = nil
                    utility.clear({ptfxs['alien']})
                    ptfxs['alien'] = nil
                end
            end
            coroutine.yield(0)
        end
        if ptfxs['flamethrower'] then
            graphics.remove_particle_fx(ptfxs['flamethrower'], true)
            ptfxs['flamethrower'] = nil
            utility.clear({ptfxs['alien']})
            ptfxs['alien'] = nil
        end
        settings['Flamethrower'].Enabled = f.on
    end)


    Script.Feature['Flamethrower Green'] = menu.add_feature('Flamethrower - Green', 'toggle', Script.Parent['Flamethrower'].id, function(f)
        settings['Flamethrower Green'] = {Enabled = f.on}
        while f.on do
            if player.is_player_free_aiming(Self()) then
                graphics.set_next_ptfx_asset('weap_xs_vehicle_weapons')
                while not graphics.has_named_ptfx_asset_loaded('weap_xs_vehicle_weapons') do
                    graphics.request_named_ptfx_asset('weap_xs_vehicle_weapons')
                    coroutine.yield(0)
                end
                if not ptfxs['alien'] then
                    ptfxs['alien'] = Spawn.Object(1803116220, get.OwnCoords())
                    entity.set_entity_collision(ptfxs['alien'], false, false, false)
                    entity.set_entity_visible(ptfxs['alien'], false)
                end
                local pos_h = Math.GetPedBoneCoords(get.OwnPed(), 0xdead)
                utility.set_coords(ptfxs['alien'], pos_h)
                entity.set_entity_rotation(ptfxs['alien'], cam.get_gameplay_cam_rot())
                if not ptfxs['flamethrower_green'] then
                    ptfxs['flamethrower_green'] =
                    graphics.start_networked_ptfx_looped_on_entity('muz_xs_turret_flamethrower_looping_sf', ptfxs['alien'], v3(), v3(), Script.Feature['Flamethrower Scale'].value)
                end
            else
                if ptfxs['flamethrower_green'] then
                    graphics.remove_particle_fx(ptfxs['flamethrower_green'], true)
                    ptfxs['flamethrower_green'] = nil
                    utility.clear({ptfxs['alien']})
                    ptfxs['alien'] = nil
                end
            end
            coroutine.yield(0)
        end
        if ptfxs['flamethrower_green'] then
            graphics.remove_particle_fx(ptfxs['flamethrower_green'], true)
            ptfxs['flamethrower_green'] = nil
            utility.clear({ptfxs['alien']})
            ptfxs['alien'] = nil
        end
        settings['Flamethrower Green'].Enabled = f.on
    end)


    
    Script.Parent['Shoot Objects'] = menu.add_feature('Shoot Objects', 'parent', Script.Parent['Weapon Modifier'].id, nil)


    Script.Feature['Shoot Objects'] = menu.add_feature('Enable Object Shoot', 'toggle', Script.Parent['Shoot Objects'].id, function(f)
        settings['Shoot Objects'] = {Enabled = f.on}
        while f.on do
            for i = 1, #customData.shoot_entitys do
                if Script.Feature['Shoot Object ' .. customData.shoot_entitys[i].Name].on and ped.is_ped_shooting(get.OwnPed()) then
                    if #entitys['shooting'] > 128 then
                        utility.clear(entitys['shooting'])
                        entitys['shooting'] = {}
                    end
                    local pos = get.OwnCoords()
                    local dir = cam.get_gameplay_cam_rot()
                    dir:transformRotToDir()
                    dir = dir * 8
                    pos = pos + dir
                    if streaming.is_model_an_object(customData.shoot_entitys[i].Hash) then
                        entitys['shooting'][#entitys['shooting'] + 1] = Spawn.Object(customData.shoot_entitys[i].Hash, pos)
                    end
                    dir = nil
                    local pos_target = get.OwnCoords()
                    dir = cam.get_gameplay_cam_rot()
                    dir:transformRotToDir()
                    dir = dir * 100
                    pos_target = pos_target + dir
                    local vectorV3 = pos_target - pos
                    entity.apply_force_to_entity(entitys['shooting'][#entitys['shooting']], 3, vectorV3.x, vectorV3.y, vectorV3.z, 0.0, 0.0, 0.0, true, true)
                end
            end
            coroutine.yield(0)
        end
        utility.clear(entitys['shooting'])
        entitys['shooting'] = {}
        settings['Shoot Objects'].Enabled = f.on
    end)


    Script.Feature['Delete Shot Objects'] = menu.add_feature('Delete Objects', 'action', Script.Parent['Shoot Objects'].id, function()
        utility.clear(entitys['shooting'])
        entitys['shooting'] = {}
    end)
    


    for i = 1, #customData.shoot_entitys do
        if streaming.is_model_an_object(customData.shoot_entitys[i].Hash) then
            Script.Feature['Shoot Object ' .. customData.shoot_entitys[i].Name] = menu.add_feature('Shoot ' .. customData.shoot_entitys[i].Name, 'toggle', Script.Parent['Shoot Objects'].id, function(f)
                settings['Shoot Object ' .. customData.shoot_entitys[i].Name] = {Enabled = f.on}
            end)
        else
            print('Shoot Objects preset ' .. customData.shoot_entitys[i].Name .. ' is invalid.')
        end
    end
    


    Script.Parent['Model Gun'] = menu.add_feature('Model Gun', 'parent', Script.Parent['Weapon Modifier'].id, nil)


    Script.Feature['Model Gun'] = menu.add_feature('Standard Model Gun (Peds)', 'toggle', Script.Parent['Model Gun'].id, function(f)
        settings['Model Gun'] = {Enabled = f.on}
        while f.on do
            if apply_invisible then
                entity.set_entity_visible(get.OwnPed(), false)
                if model_gun then
                    entity.set_entity_visible(model_gun, true)
                end
            else
                entity.set_entity_visible(get.OwnPed(), true)
            end
            if player.is_player_free_aiming(Self()) then
                local new_model = player.get_entity_player_is_aiming_at(Self())
                if new_model ~= 0 then
                    new_model = entity.get_entity_model_hash(new_model)
                    if streaming.is_model_a_ped(new_model) then
                        if model_gun then
                            utility.clear({model_gun})
                            model_gun = nil
                        end
                        local pl_model = entity.get_entity_model_hash(get.OwnPed())
                        if new_model ~= pl_model then
                            apply_invisible = false
                            coroutine.yield(50)
                            local c_weapon = ped.get_current_ped_weapon(get.OwnPed())
                            change_model(new_model)
                            coroutine.yield(25)
                            weapon.give_delayed_weapon_to_ped(get.OwnPed(), c_weapon, 0, 1)
                        end
                    elseif streaming.is_model_a_vehicle(new_model) and Script.Feature['Model Gun Include All'].on then
                        utility.clear({model_gun})
                        model_gun = nil
                        apply_invisible = true
                        model_gun = Spawn.Vehicle(new_model, get.OwnCoords())
                        entity.attach_entity_to_entity(model_gun, get.OwnPed(), 0, v3(), v3(), true, true, false, 0, true)
                    elseif streaming.is_model_an_object(new_model) and Script.Feature['Model Gun Include All'].on then
                        utility.clear({model_gun})
                        model_gun = nil
                        model_gun = Spawn.Object(new_model, get.OwnCoords())
                        apply_invisible = true
                        entity.attach_entity_to_entity(model_gun, get.OwnPed(), 0, v3(), v3(), true, true, false, 0, true)
                    end
                end
            end
            coroutine.yield(0)
        end
        utility.clear({model_gun})
        model_gun = nil
        entity.set_entity_visible(get.OwnPed(), true)
        settings['Model Gun'].Enabled = f.on
    end)


    Script.Feature['Model Gun Include All'] = menu.add_feature('Include All Entities', 'toggle', Script.Parent['Model Gun'].id, function(f)
        settings['Model Gun Include All'] = {Enabled = f.on}
    end)


    Script.Feature['Sniper Vision'] = menu.add_feature('Sniper Vision', 'value_str', Script.Parent['Weapon Modifier'].id, function(f)
        if not menu.is_trusted_mode_enabled(1 << 2) then
            Notify('Not available while trusted mode for natives is turned off', 'Error', 'Sniper Vision')
            f.on = false
            return
        end

        while f.on do
            if not menu.is_trusted_mode_enabled(1 << 2) then
                f.on = false
            end

            if player.is_player_free_aiming(Self()) then
                local currentwep = ped.get_current_ped_weapon(get.OwnPed())
                if currentwep == 0x5FC3C11 or currentwep == 0xC472FE2 or currentwep == 0xA914799 or currentwep == 0xC734385A then
                    if f.value == 0 then
                        N.GRAPHICS.SET_NIGHTVISION(true)
                        N.GRAPHICS.SET_SEETHROUGH(false)
                    else
                        N.GRAPHICS.SET_NIGHTVISION(false)
                        N.GRAPHICS.SET_SEETHROUGH(true)
                    end
                    
                end

            end
            coroutine.yield(0)
        end
    end)
    Script.Feature['Sniper Vision']:set_str_data({'Night', 'Thermal'})


    Script.Feature['Delete Gun'] = menu.add_feature('Delete Gun', 'toggle', Script.Parent['Weapon Modifier'].id, function(f)
        settings['Delete Gun'] = {Enabled = f.on}
        while f.on do
            if ped.is_ped_shooting(get.OwnPed()) then
                local delete = player.get_entity_player_is_aiming_at(Self())
                if delete then
                    if entity.is_entity_a_ped(delete) then
                        local veh = ped.get_vehicle_ped_is_using(delete)
                        if veh ~= 0 then
                            ped.clear_ped_tasks_immediately(delete)
                            delete = veh
                        end
                    end
                    
                    if not ped.is_ped_a_player(delete) then
                        utility.clear({delete})
                    end
                end
            end
            coroutine.yield(0)
        end
        settings['Delete Gun'].Enabled = f.on
    end)


    Script.Feature['Kick Gun'] = menu.add_feature('Kick Gun', 'toggle', Script.Parent['Weapon Modifier'].id, function(f)
        settings['Kick Gun'] = {Enabled = f.on}
        while f.on do
            if ped.is_ped_shooting(get.OwnPed()) then
                local pl = player.get_entity_player_is_aiming_at(Self())
                if ped.is_ped_a_player(pl) then
                    Notify('Kick-Gun hit: ' .. get.Name(player.get_player_from_ped(pl)), "Neutral")
                    SmartKick(player.get_player_from_ped(pl))
                end
            end
            coroutine.yield(0)
        end
        settings['Kick Gun'].Enabled = f.on
    end)


    Script.Feature['Drive it Gun'] = menu.add_feature('Drive it Gun', 'toggle', Script.Parent['Weapon Modifier'].id, function(f)
        settings['Drive it Gun'] = {Enabled = f.on}

        while f.on do
            local OwnPed = get.OwnPed()
            if ped.is_ped_shooting(OwnPed) then
                local Entity = player.get_entity_player_is_aiming_at(Self())
                
                if Entity ~= 0 then
                    if entity.is_entity_a_ped(Entity) then
                        local Vehicle = ped.get_vehicle_ped_is_using(Entity)

                        if Vehicle ~= 0 then
                            ped.clear_ped_tasks_immediately(Entity)
                            Entity = Vehicle
                        end

                    end

                    if entity.is_entity_a_vehicle(Entity) then
                        ped.set_ped_into_vehicle(OwnPed, Entity, -1)
                    end

                end

            end

            coroutine.yield(0)
        end

        settings['Drive it Gun'].Enabled = f.on
    end)


    Script.Feature['Anti Gravity Gun'] = menu.add_feature('Anti Gravity Gun', 'value_str', Script.Parent['Weapon Modifier'].id, function(f)
        settings['Anti Gravity Gun'] = {Enabled = f.on, Value = f.value}
        local gravity = {0, -10, 10}

        while f.on do
            local OwnPed = get.OwnPed()
            if ped.is_ped_shooting(OwnPed) then
                local Entity = player.get_entity_player_is_aiming_at(Self())
                
                if Entity ~= 0 then
                    if entity.is_entity_a_ped(Entity) then
                        local Vehicle = ped.get_vehicle_ped_is_using(Entity)

                        if Vehicle ~= 0 then
                            Entity = Vehicle
                        end

                    end

                    utility.request_ctrl(Entity, 100)

                    entity.freeze_entity(Entity, false)

                    if entity.is_entity_a_vehicle(Entity) then
                        entity.set_entity_gravity(Entity, false)
                        vehicle.set_vehicle_gravity_amount(Entity, gravity[f.value + 1])
                    end

                end

            end

            settings['Anti Gravity Gun'].Value = f.value
            coroutine.yield(0)
        end

        settings['Anti Gravity Gun'].Enabled = f.on
    end)
    Script.Feature['Anti Gravity Gun']:set_str_data({'Remove', 'Reverse', 'Normalise'})


    Script.Feature['Force Gun'] = menu.add_feature('Force Gun', 'slider', Script.Parent['Weapon Modifier'].id, function(f)
        settings['Force Gun'] = {Enabled = f.on}

        while f.on do
            local OwnPed = get.OwnPed()
            if ped.is_ped_shooting(OwnPed) then
                local Entity = player.get_entity_player_is_aiming_at(Self())
                
                if Entity ~= 0 then
                    if entity.is_entity_a_ped(Entity) then
                        local Vehicle = ped.get_vehicle_ped_is_using(Entity)

                        if Vehicle ~= 0 then
                            Entity = Vehicle
                        end

                    end

                    entity.freeze_entity(Entity, false)

                    local Position = entity.get_entity_coords(Entity)
                    local OwnPosition = player.get_player_coords(Self())
                    local Magnitude = OwnPosition:magnitude(Position)
                
                    local Velocity = (Position - OwnPosition) * (f.value / Magnitude)
                    utility.request_ctrl(Entity, 100)
                
                    entity.set_entity_velocity(Entity, Velocity)

                end

            end

            coroutine.yield(0)
        end

        settings['Force Gun'].Enabled = f.on
    end)
    Script.Feature['Force Gun'].min = 100
    Script.Feature['Force Gun'].max = 1000
    Script.Feature['Force Gun'].mod = 100


    Script.Feature['Airstrike Gun'] = menu.add_feature('Airstrike Gun', 'toggle', Script.Parent['Weapon Modifier'].id, function(f)
        settings['Airstrike Gun'] = {Enabled = f.on}

        while f.on do
            local OwnPed = get.OwnPed()
            if ped.is_ped_shooting(OwnPed) then
                
                local whash = gameplay.get_hash_key('weapon_airstrike_rocket')
                local pos = get.OwnCoords()
                local dir = cam.get_gameplay_cam_rot()
                dir:transformRotToDir()
                dir = dir * 1000
                pos = pos + dir
                local hit, hitpos, hitsurf, hash, ent = worldprobe.raycast((utility.OffsetCoords(get.OwnCoords(), get.OwnHeading(), 1) + v3(0, 0, 1)), pos, -1, 0)
                while not hit do
                    pos = get.OwnCoords()
                    dir = cam.get_gameplay_cam_rot()
                    dir:transformRotToDir()
                    dir = dir * 1000
                    pos = pos + dir
                    hit, hitpos, hitsurf, hash, ent = worldprobe.raycast((utility.OffsetCoords(get.OwnCoords(), get.OwnHeading(), 1) + v3(0, 0, 1)), pos, -1, 0)
                    coroutine.yield(0)
                end

                local start = hitpos + v3(0, 0, 50)
                gameplay.shoot_single_bullet_between_coords(start, hitpos, 1000, whash, get.OwnPed(), true, false, 5000)

            end

            coroutine.yield(0)
        end

        settings['Airstrike Gun'].Enabled = f.on
    end)


    Script.Feature['Rapid Fire'] = menu.add_feature('Rapid Fire', 'value_str', Script.Parent['Weapon Modifier'].id, function(f)
        settings['Rapid Fire'] = {Enabled = f.on, Value = f.value}

        while f.on do
            if f.value == 0 and player.is_player_free_aiming(Self()) then
                if ped.is_ped_shooting(get.OwnPed()) then
                    for i = 1, 25 do
                        local v3_start = Math.GetPedBoneCoords(get.OwnPed(), 0x67f2)
                        local dir = cam.get_gameplay_cam_rot()
                        dir:transformRotToDir()
                        dir = dir * 1.5
                        v3_start = v3_start + dir
                        dir = nil
                        local v3_end = get.OwnCoords()
                        dir = cam.get_gameplay_cam_rot()
                        dir:transformRotToDir()
                        dir = dir * 1500
                        v3_end = v3_end + dir
                        local hash_weapon = ped.get_current_ped_weapon(get.OwnPed())
                        gameplay.shoot_single_bullet_between_coords(v3_start, v3_end, 1, hash_weapon, get.OwnPed(), true, false, 1000)
                        coroutine.yield(0)
                    end
                end
            elseif f.value == 1 and get.OwnVehicle() == 0 then
                if ped.is_ped_shooting(get.OwnPed()) then
                    for i = 1, 25 do
                        local v3_start = Math.GetPedBoneCoords(get.OwnPed(), 0x67f2)
                        local dir = cam.get_gameplay_cam_rot()
                        dir:transformRotToDir()
                        dir = dir * 1.5
                        v3_start = v3_start + dir
                        dir = nil
                        local v3_end = get.OwnCoords()
                        dir = cam.get_gameplay_cam_rot()
                        dir:transformRotToDir()
                        dir = dir * 1500
                        v3_end = v3_end + dir
                        local hash_weapon = ped.get_current_ped_weapon(get.OwnPed())
                        gameplay.shoot_single_bullet_between_coords(v3_start, v3_end, 1, hash_weapon, get.OwnPed(), true, false, 1000)
                        coroutine.yield(0)
                    end
                end
            end
            settings['Rapid Fire'].Value = f.value
            coroutine.yield(0)
        end
        settings['Rapid Fire'].Enabled = f.on
    end)
    Script.Feature['Rapid Fire']:set_str_data({'v1', 'v2'})


    Script.Feature['Model Change Input'] = menu.add_feature('Model Change: Input', 'action', Script.Parent['local_player'].id, function(f)
        local _input = get.Input("Enter Ped Model Name or Hash")
        if not _input then
            Notify('Input canceled.', "Error", '')
            return
        end
        local hash = _input
        if not tonumber(_input) then
            hash = gameplay.get_hash_key(_input)
        end
        if not streaming.is_model_a_ped(hash) then
            Notify('Input is not a valid ped.', "Error", '')
            return
        end
        change_model(hash, nil, true)
    end)


    Script.Feature['Ragdoll Self'] = menu.add_feature('Ragdoll Self', 'value_str', Script.Parent['local_player'].id, function(f)
        if f.value == 0 then
            ped.set_ped_to_ragdoll(get.OwnPed(), 2500, 0, 0)
            f.on = false
            return
        end

        while f.on do
            if f.value == 0 then
                f.on = false
                return
            end
            ped.set_ped_to_ragdoll(get.OwnPed(), 2500, 0, 0)
            coroutine.yield(0)
        end
    end)
    Script.Feature['Ragdoll Self']:set_str_data({'Once', 'Loop'})


    Script.Feature['Fake Wanted Level'] = menu.add_feature('Fake Wanted Level', 'value_i', Script.Parent['local_player'].id, function(f)
        if not menu.is_trusted_mode_enabled(1 << 2) then
            Notify('Not available while trusted mode for natives is turned off', 'Error', 'Fake Wanted Level')
            f.on = false
            return
        end

        while f.on do
            if not menu.is_trusted_mode_enabled(1 << 2) then
                f.on = false
            end

            N.MISC.SET_FAKE_WANTED_LEVEL(f.value)

            coroutine.yield(0)
        end

        N.MISC.SET_FAKE_WANTED_LEVEL(0)
    end)
    Script.Feature['Fake Wanted Level'].min = 1
    Script.Feature['Fake Wanted Level'].max = 6


    Script.Feature['Respawn at Position of Death'] = menu.add_feature('Respawn at Position of Death', 'toggle', Script.Parent['local_player'].id, function(f)
        settings['Respawn at Position of Death'] = {Enabled = f.on}
        while f.on do
            local pos = get.OwnCoords()

            if player.get_player_health(Self()) == 0 then
                while player.get_player_health(Self()) ~= player.get_player_max_health(Self()) do
                    coroutine.yield(0)
                end

                pos.z = Math.GetGroundZ(pos.x, pos.y) + 1
                utility.tp(pos)
            end
            coroutine.yield(0)
        end
        settings['Respawn at Position of Death'].Enabled = f.on
    end)


    Script.Parent['Aim Protection'] = menu.add_feature('Aim Protection', 'parent', Script.Parent['local_player'].id, nil)


    Script.Feature['Enable Aim Protection'] = menu.add_feature('Enable Aim Protection', 'value_str', Script.Parent['Aim Protection'].id, function(f)
        settings['Enable Aim Protection'] = {Enabled = f.on, Value = f.value}

        while f.on do
            local exclude
            if f.value == 0 then
                exclude = false
            else
                exclude = true
            end

            for id = 0, 31 do
                if utility.valid_player(id, exclude) then
                    local target = player.get_entity_player_is_aiming_at(id)
                    if target ~= 0 then
                        if target == get.OwnPed() then
                            if Script.Feature['Aim Protection Notify'].on then                                
                                Notify('Player: ' .. get.Name(id), "Neutral", '2Take1Script Aim Protection')
                            end

                            if Script.Feature['Aim Protection Anonymous Explosion'].on then
                                fire.add_explosion(get.PlayerCoords(id), 8, false, true, 0, get.PlayerPed(id))
                                coroutine.yield(75)
                            end

                            if Script.Feature['Aim Protection Named Explosion'].on then
                                fire.add_explosion(get.PlayerCoords(id), 8, false, true, 0, get.OwnPed())
                                coroutine.yield(75)
                            end

                            if Script.Feature['Aim Protection Freeze'].on then
                                ped.clear_ped_tasks_immediately(get.PlayerPed(id))
                                coroutine.yield(0)
                            end

                            if Script.Feature['Aim Protection Ragdoll'].on then
                                fire.add_explosion(get.PlayerCoords(id), 13, false, true, 0, 0)
                                coroutine.yield(75)
                            end

                            if Script.Feature['Aim Protection Set on Fire'].on then
                                graphics.set_next_ptfx_asset('scr_recrash_rescue')
                                while not graphics.has_named_ptfx_asset_loaded('scr_recrash_rescue') do
                                    graphics.request_named_ptfx_asset('scr_recrash_rescue')
                                    coroutine.yield(0)
                                end
                                graphics.start_networked_ptfx_looped_on_entity('scr_recrash_rescue_fire', get.PlayerPed(id), v3(), v3(), 1)
                                coroutine.yield(75)
                            end

                            if Script.Feature['Aim Protection Remove Weapon'].on then
                                local playerped = get.PlayerPed(id)
                                ped.set_ped_can_switch_weapons(playerped, false)
                                weapon.remove_weapon_from_ped(playerped, ped.get_current_ped_weapon(playerped))
                                ped.set_ped_can_switch_weapons(playerped, false)
                                coroutine.yield(75)
                            end

                            --[[
                            if Script.Feature['Aim Protection Transaction Error'].on then
                                scriptevent.Send('Transaction Error', {Self(), 50000, 0, 1, scriptevent.MainGlobal(id), scriptevent.GlobalPair()}, id)
                                coroutine.yield(75)
                            end
                            ]]

                            if Script.Feature['Aim Protection Warehouse Invite'].on then
                                scriptevent.Send('Warehouse Invite', {Self(), 0, 1, math.random(1, 22)}, id)
                                coroutine.yield(75)
                            end

                            if Script.Feature['Aim Protection Apartment Invite'].on then
                                scriptevent.Send('Apartment Invite', {Self(), id, 4294967295, 1, math.random(1, 113), 0, 0, 0}, id)
                                coroutine.yield(75)
                            end

                            if Script.Feature['Aim Protection Taze'].on then
                                if get.PlayerVehicle(id) ~= 0 then
                                    local pos = get.PlayerCoords(id)
                                    gameplay.shoot_single_bullet_between_coords(pos + v3(0, 0, 2), pos, 0, 0x3656C8C1, get.OwnPed(), true, false, 10000)
                                    coroutine.yield(75)
                                end
                            end

                            if Script.Feature['Aim Protection Kick'].on then
                                if Script.Feature['Aim Protection Kick'].value == 0 then
                                    scriptevent.kick(id)
                                else
                                    SmartKick(id)
                                end
                                coroutine.yield(500)
                            end

                            if Script.Feature['Aim Protection Crash'].on then
                                scriptevent.crash(id)
                                coroutine.yield(500)
                            end
                        end
                    end
                end
            end
            settings['Enable Aim Protection'].Value = f.value
            coroutine.yield(0)
        end
        settings['Enable Aim Protection'].Enabled = f.on
    end)
    Script.Feature['Enable Aim Protection']:set_str_data({'All Players', 'Exclude Friends'})

    local protections = {'Notify', 'Anonymous Explosion', 'Named Explosion', 'Freeze', 'Ragdoll', 'Set on Fire', 'Remove Weapon', 'Apartment Invite', 'Warehouse Invite', 'Taze'}
    for i = 1, #protections do
        local name = protections[i]
        Script.Feature['Aim Protection ' .. name] = menu.add_feature(name, 'toggle', Script.Parent['Aim Protection'].id, function(f)
            settings['Aim Protection ' .. name] = {Enabled = f.on}
        end)
    end
    

    Script.Feature['Aim Protection Kick'] = menu.add_feature('Kick', 'value_str', Script.Parent['Aim Protection'].id, function(f)
        settings['Aim Protection Kick'] = {Enabled = f.on, Value = f.value}
    end)
    Script.Feature['Aim Protection Kick']:set_str_data({'Script Kick', 'Desync Kick'})


    Script.Feature['Aim Protection Crash'] = menu.add_feature('Crash', 'toggle', Script.Parent['Aim Protection'].id, function(f)
        settings['Aim Protection Crash'] = {Enabled = f.on}
    end)
    

    Script.Parent['Bodyguards'] = menu.add_feature('Bodyguards', 'parent', Script.Parent['local_player'].id, nil)

    Script.Parent['Bodyguard Spawn Settings'] = menu.add_feature('Spawn Settings', 'parent', Script.Parent['Bodyguards'].id, nil)

    Script.Parent['Bodyguard Set All'] = menu.add_feature('All Bodyguards', 'parent', Script.Parent['Bodyguard Spawn Settings'].id, nil)


    Script.Feature['Bodyguard Godmode All'] = menu.add_feature('Godmode', 'autoaction_value_str', Script.Parent['Bodyguard Set All'].id, function(f)
        if f.value == 0 then
            for i = 1, 7 do
                Script.Feature['Bodyguard' .. i .. ' Godmode'].on = true
            end
        else
            for i = 1, 7 do
                Script.Feature['Bodyguard' .. i .. ' Godmode'].on = false
            end
        end
    end)
    Script.Feature['Bodyguard Godmode All']:set_str_data({'On', 'Off'})


    Script.Feature['Bodyguard No Ragdoll All'] = menu.add_feature('Disable Ragdoll', 'autoaction_value_str', Script.Parent['Bodyguard Set All'].id, function(f)
        if f.value == 0 then
            for i = 1, 7 do
                Script.Feature['Bodyguard' .. i .. ' No Ragdoll'].on = true
            end
        else
            for i = 1, 7 do
                Script.Feature['Bodyguard' .. i .. ' No Ragdoll'].on = false
            end
        end
    end)
    Script.Feature['Bodyguard No Ragdoll All']:set_str_data({'On', 'Off'})


    Script.Feature['Bodyguard Marker All'] = menu.add_feature('Add Map Marker', 'autoaction_value_str', Script.Parent['Bodyguard Set All'].id, function(f)
        if f.value == 0 then
            for i = 1, 7 do
                Script.Feature['Bodyguard' .. i .. ' Marker'].on = true
            end
        else
            for i = 1, 7 do
                Script.Feature['Bodyguard' .. i .. ' Marker'].on = false
            end
        end
    end)
    Script.Feature['Bodyguard Marker All']:set_str_data({'On', 'Off'})


    Script.Feature['Bodyguard Health All'] = menu.add_feature('Health', 'action_value_i', Script.Parent['Bodyguard Set All'].id, function(f)
        local health = tonumber(get.Input('Enter Bodyguards Health Value (100 - 1000000)', 7, 3))
        if not health then
            Notify('Input canceled.', "Error", '')
            return
        end

        if health < 100 or health > 1000000 then
            Notify('Value must be between 100 and 1000000', "Error", '')
            return
        end

        for i = 1, 7 do
            Script.Feature['Bodyguard' .. i .. ' Health'].value = health
            settings['Bodyguard' .. i .. ' Health'] = {Value = f.value}
        end

        f.value = health
        Notify('Bodyguards Health set to: ' .. f.value, "Success")
    end)
    Script.Feature['Bodyguard Health All'].min = 100
    Script.Feature['Bodyguard Health All'].max = 1000000


    for i = 1, #customData.Bodyguards do
        local name = customData.Bodyguards[i].Name
        local stringdata = {}
        for j = 1, #customData.Bodyguards[i].Children do
            stringdata[j] = customData.Bodyguards[i].Children[j].Name
        end

        Script.Feature['Bodyguard ' .. name .. ' All'] = menu.add_feature(name, 'autoaction_value_str', Script.Parent['Bodyguard Set All'].id, function(f)
            for i = 1, 7 do
                Script.Feature['Bodyguard ' .. i .. ' ' .. name].value = f.value
                settings['Bodyguard ' .. i .. ' ' .. name] = {Value = f.value}
            end
        end)
        Script.Feature['Bodyguard ' .. name .. ' All']:set_str_data(stringdata)
    end


    for nr = 1, 7 do
        Script.Parent['Bodyguard ' .. nr] = menu.add_feature('Bodyguard ' .. nr, 'parent', Script.Parent['Bodyguard Spawn Settings'].id, nil)

        Script.Feature['Bodyguard' .. nr .. ' Godmode'] = menu.add_feature('Godmode', 'toggle', Script.Parent['Bodyguard ' .. nr].id, function(f)
            settings['Bodyguard' .. nr .. ' Godmode'] = {Enabled = f.on}
        end)
    
    
        Script.Feature['Bodyguard' .. nr .. ' No Ragdoll'] = menu.add_feature('Disable Ragdoll', 'toggle', Script.Parent['Bodyguard ' .. nr].id, function(f)
            settings['Bodyguard' .. nr .. ' No Ragdoll'] = {Enabled = f.on}
        end)
    
    
        Script.Feature['Bodyguard' .. nr .. ' Marker'] = menu.add_feature('Add Map Marker', 'toggle', Script.Parent['Bodyguard ' .. nr].id, function(f)
            settings['Bodyguard' .. nr .. ' Marker'] = {Enabled = f.on}
        end)
    
    
        Script.Feature['Bodyguard' .. nr .. ' Health'] = menu.add_feature('Health', 'action_value_i', Script.Parent['Bodyguard ' .. nr].id, function(f)
            local health = tonumber(get.Input('Enter Bodyguards Health Value (100 - 1000000)', 7, 3))
            if not health then
                Notify('Input canceled.', "Error", '')
                return
            end
    
            if health < 100 or health > 1000000 then
                Notify('Value must be between 100 and 1000000', "Error", '')
                return
            end
    
            f.value = health
            Notify('Bodyguards Health set to: ' .. f.value, "Success")
            settings['Bodyguard' .. nr .. ' Health'] = {Value = f.value}
        end)
        Script.Feature['Bodyguard' .. nr .. ' Health'].min = 100
        Script.Feature['Bodyguard' .. nr .. ' Health'].max = 1000000

        for i = 1, #customData.Bodyguards do
            local name = customData.Bodyguards[i].Name
            local stringdata = {}
            for j = 1, #customData.Bodyguards[i].Children do
                stringdata[j] = customData.Bodyguards[i].Children[j].Name
            end
    
            Script.Feature['Bodyguard ' .. nr .. ' ' .. name] = menu.add_feature(name, 'autoaction_value_str', Script.Parent['Bodyguard ' .. nr].id, function(f)
                settings['Bodyguard ' .. nr .. ' ' .. name] = {Value = f.value}
            end)
            Script.Feature['Bodyguard ' .. nr .. ' ' .. name]:set_str_data(stringdata)
        end
    end


    Script.Feature['Bodyguard Combat Behavior'] = menu.add_feature('Combat Behavior', 'autoaction_value_str', Script.Parent['Bodyguards'].id, function(f)
        settings['Bodyguard Combat Behavior'] = {Value = f.value}
    end)
    Script.Feature['Bodyguard Combat Behavior']:set_str_data({'Stationary', 'Defensive', 'Offensive'})


    Script.Feature['Bodyguard Max Distance'] = menu.add_feature('Max Distance To Player', 'autoaction_value_i', Script.Parent['Bodyguards'].id, function(f)
        settings['Bodyguard Max Distance'] = {Value = f.value}
    end)
    Script.Feature['Bodyguard Max Distance'].min = 50
    Script.Feature['Bodyguard Max Distance'].max = 500
    Script.Feature['Bodyguard Max Distance'].mod = 50


    Script.Feature['Bodyguard Formation'] = menu.add_feature('Bodyguard Formation', 'autoaction_value_str', Script.Parent['Bodyguards'].id, function(f)
        settings['Bodyguard Formation'] = {Value = f.value}
    end)
    Script.Feature['Bodyguard Formation']:set_str_data({'Nothing', 'Circle 1', 'Circle 2', 'Line'})


    Script.Feature['Amount of Bodyguards'] = menu.add_feature('Amount of Bodyguards', 'autoaction_value_i', Script.Parent['Bodyguards'].id, function(f)
        settings['Amount of Bodyguards'] = {Value = f.value}
    end)
    Script.Feature['Amount of Bodyguards'].min = 1
    Script.Feature['Amount of Bodyguards'].max = 7


    Script.Feature['Enable Bodyguards'] = menu.add_feature('Enable Bodyguards', 'toggle', Script.Parent['Bodyguards'].id, function(f)
        while f.on do
            local ped_group = player.get_player_group(Self())

            local running = {}

            for i = 1, #entitys['bodyguards'] do
                if i > Script.Feature['Amount of Bodyguards'].value then
                    utility.clear(entitys['bodyguards'][i])
                    entitys['bodyguards'][i] = nil
                end
            end

            for i = 1, Script.Feature['Amount of Bodyguards'].value do
                if not entitys['bodyguards'][i] or entity.is_entity_dead(entitys['bodyguards'][i]) then
                    if entitys['bodyguards'][i] and entity.is_entity_dead(entitys['bodyguards'][i]) then
                        utility.clear({entitys['bodyguards'][i]})
                    end

                    local pedhash = customData.Bodyguards[1].Children[Script.Feature['Bodyguard ' .. i .. ' Ped Type'].value + 1].Hash
                    local weaponhash = customData.Bodyguards[2].Children[Script.Feature['Bodyguard ' .. i .. ' Primary Weapon'].value + 1].Hash
                    local weaponhash2 = customData.Bodyguards[3].Children[Script.Feature['Bodyguard ' .. i .. ' Secondary Weapon'].value + 1].Hash

                    local pos = get.OwnCoords()
                    pos.x = pos.x + math.random(-5, 5)
                    pos.y = pos.y + math.random(-5, 5)
                    pos.z = Math.GetGroundZ(pos.x, pos.y)

                    if pedhash == -1 then
                        local ownped = get.OwnPed()
                        local ownhash = entity.get_entity_model_hash(ownped)

                        if ownhash ~= 2627665880 and ownhash ~= 1885233650 then
                            Notify('Clones are disabled for non player models', 'Error', '')
                            f.on = false
                            return
                        end

                        entitys['bodyguards'][i] = ped.clone_ped(ownped)
                        utility.set_coords(entitys['bodyguards'][i], pos)

                    elseif pedhash == -2 then
                        local hash = mapper.ped.GetRandomPed()

                        entitys['bodyguards'][i] = Spawn.Ped(hash, pos, 29)
                        if hash == 2633130371 or hash == 0x81441B71 then
                            ped.set_ped_component_variation(entitys['bodyguards'][i], 8, 1, 1, 1)
                        end
                    else
                        entitys['bodyguards'][i] = Spawn.Ped(pedhash, pos, 29)
                        if pedhash == 2633130371 or pedhash == 0x81441B71 then
                            ped.set_ped_component_variation(entitys['bodyguards'][i], 8, 1, 1, 1)
                        end
                    end

                    if Script.Feature['Bodyguard' .. i .. ' Godmode'].on then
                        entity.set_entity_god_mode(entitys['bodyguards'][i], true)
                    else
                        ped.set_ped_max_health(entitys['bodyguards'][i], Script.Feature['Bodyguard' .. i .. ' Health'].value)
                        ped.set_ped_health(entitys['bodyguards'][i], Script.Feature['Bodyguard' .. i .. ' Health'].value)
                    end

                    if Script.Feature['Bodyguard' .. i .. ' No Ragdoll'].on then
                        for j = 1, 26 do
                            ped.set_ped_ragdoll_blocking_flags(entitys['bodyguards'][i], j)
                        end
                    end

                    if Script.Feature['Bodyguard' .. i .. ' Marker'].on then
                        local blip = ui.add_blip_for_entity(entitys['bodyguards'][i])
                        ui.set_blip_sprite(blip, 310)
                        ui.set_blip_colour(blip, 80)
                    end

                    
                    --[[ useless
                    if menu.is_trusted_mode_enabled(1 << 2) then
                        N.HUD.CREATE_FAKE_MP_GAMER_TAG(entitys['bodyguards'][i], 'Bodguard', false, false, 'Bodyguards', 8000)
                    end
                    ]]

                    if weaponhash ~= -1 then
                        if weaponhash == -2 then
                            local hash = customData.Bodyguards[2].Children[math.random(#customData.Bodyguards[2].Children)].Hash

                            while hash == -1 or hash == -2 do
                                hash = customData.Bodyguards[2].Children[math.random(#customData.Bodyguards[2].Children)].Hash
                            end

                            weapon.give_delayed_weapon_to_ped(entitys['bodyguards'][i], hash, 0, 1)
                        else
                            weapon.give_delayed_weapon_to_ped(entitys['bodyguards'][i], weaponhash, 0, 1)
                        end
                    end

                    if weaponhash2 ~= -1 then
                        if weaponhash2 == -2 then
                            local hash = customData.Bodyguards[3].Children[math.random(#customData.Bodyguards[3].Children)].Hash

                            while hash == -1 or hash == -2 do
                                hash = customData.Bodyguards[3].Children[math.random(#customData.Bodyguards[3].Children)].Hash
                            end

                            weapon.give_delayed_weapon_to_ped(entitys['bodyguards'][i], hash, 0, 1)
                        else
                            weapon.give_delayed_weapon_to_ped(entitys['bodyguards'][i], weaponhash2, 0, 1)
                        end
                    end

                    ped.set_ped_combat_ability(entitys['bodyguards'][i], 100)
                    ped.set_can_attack_friendly(entitys['bodyguards'][i], false, false)
                    entity.set_entity_as_mission_entity(entitys['bodyguards'][i], 1, 1)
                end
                -- AI
                if not running[i] or menu.has_thread_finished(running[i]) then
                    running[i] = menu.create_thread(function(bodyguard)
                        if not entity.is_entity_dead(bodyguard) then
                            utility.request_ctrl(bodyguard)

                            if ped.get_ped_group(bodyguard) ~= ped_group then
                                ped.set_ped_as_group_member(bodyguard, ped_group)
                                ped.set_ped_never_leaves_group(bodyguard, true)
                            end

                            ped.set_ped_combat_movement(bodyguard, Script.Feature['Bodyguard Combat Behavior'].value)
                            ped.set_group_formation(ped_group, Script.Feature['Bodyguard Formation'].value)

                            -- TP Bodyguards back to Player
                            if get.OwnCoords():magnitude(entity.get_entity_coords(bodyguard)) > Script.Feature['Bodyguard Max Distance'].value then
                                utility.set_coords(bodyguard, utility.OffsetCoords(get.OwnCoords(), get.OwnHeading(), -5))
                            end
                        end
                        coroutine.yield(100)
                    end, entitys['bodyguards'][i])
                end
            end
            coroutine.yield(200)
        end
        utility.clear(entitys['bodyguards'])
        entitys['bodyguards'] = {}
    end)

    Script.Parent['Personal Vehicle'] = menu.add_feature('Personal Vehicle', 'parent', Script.Parent['local_vehicle'].id, nil)


    Script.Feature['Teleport To Personal Vehicle'] = menu.add_feature('Teleport to Personal Vehicle', 'action', Script.Parent['Personal Vehicle'].id, function(f)
        local veh = player.get_personal_vehicle()
        local veh2 = get.OwnVehicle()
        if veh ~= 0 then
            if veh2 ~= veh then
                utility.tp(utility.OffsetCoords(entity.get_entity_coords(veh), entity.get_entity_heading(veh), -5), 0, entity.get_entity_heading(veh))
            end
        else
            Notify('No Personal Vehicle found.', "Error", '')
        end
    end)


    Script.Feature['Drive Personal Vehicle'] = menu.add_feature('Drive Personal Vehicle', 'action', Script.Parent['Personal Vehicle'].id, function()
        local veh = player.get_personal_vehicle()
        local veh2 = get.OwnVehicle()
        if veh ~= 0 then
            if veh2 ~= veh then
                ped.set_ped_into_vehicle(get.OwnPed(), veh, -1)
            end
        else
            Notify('No Personal Vehicle found.', "Error", '')
        end
    end)


    Script.Feature['Teleport Personal Vehicle To Me'] = menu.add_feature('Teleport Personal Vehicle to me', 'action', Script.Parent['Personal Vehicle'].id, function()
        local veh = player.get_personal_vehicle()
        local veh2 = get.OwnVehicle()
        if veh ~= 0 then
            if veh2 ~= veh then
                utility.set_coords(veh, utility.OffsetCoords(get.OwnCoords(), get.OwnHeading(), 5))
                entity.set_entity_heading(veh, get.OwnHeading())
            end
        else
            Notify('No Personal Vehicle found.', "Error", '')
        end
    end)


    Script.Feature['TP Personal Vehicle To Me And Drive'] = menu.add_feature('Teleport Personal Vehicle to me and drive', 'action', Script.Parent['Personal Vehicle'].id, function()
        local veh = player.get_personal_vehicle()
        local veh2 = get.OwnVehicle()
        if veh ~= 0 then
            if veh2 ~= veh then
                utility.set_coords(veh, get.OwnCoords())
                entity.set_entity_heading(veh, get.OwnHeading())
                ped.set_ped_into_vehicle(get.OwnPed(), veh, -1)
            end
        else
            Notify('No Personal Vehicle found.', "Error", '')
        end
    end)


    Script.Parent['Vehice Colors'] = menu.add_feature('Vehicle Colors', 'parent', Script.Parent['local_vehicle'].id, nil)


    Script.Feature['Vehicle Colors Speed'] = menu.add_feature('Speed', 'autoaction_slider', Script.Parent['Vehice Colors'].id, function(f)
        settings['Vehicle Colors Speed'] = {Value = f.value}
    end)
    Script.Feature['Vehicle Colors Speed'].min = 0
    Script.Feature['Vehicle Colors Speed'].max = 10000
    Script.Feature['Vehicle Colors Speed'].mod = 250


    Script.Parent['Random Colors'] = menu.add_feature('Random Colors', 'parent', Script.Parent['Vehice Colors'].id, nil)

    
    Script.Feature['Random Primary Color'] = menu.add_feature('Random Primary', 'toggle', Script.Parent['Random Colors'].id, function(f)
        ToggleOff({'Synced Colors', 'Rainbow Primary Color', '100 Black'})
        settings['Random Primary Color'] = {Enabled = f.on}

        while f.on do
            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) then
                utility.request_ctrl(veh)

                vehicle.set_vehicle_custom_primary_colour(veh, math.random(0, 0xffffff))
                coroutine.yield(10000 - math.floor(Script.Feature['Vehicle Colors Speed'].value))
            end

            coroutine.yield(0)
        end
        settings['Random Primary Color'].Enabled = f.on
    end)

    
    Script.Feature['Random Secondary Color'] = menu.add_feature('Random Secondary', 'toggle', Script.Parent['Random Colors'].id, function(f)
        ToggleOff({'Synced Colors', 'Rainbow Secondary Color', '100 Black'})
        settings['Random Secondary Color'] = {Enabled = f.on}

        while f.on do
            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) then
                utility.request_ctrl(veh)

                vehicle.set_vehicle_custom_secondary_colour(veh, math.random(0, 0xffffff))
                coroutine.yield(10000 - math.floor(Script.Feature['Vehicle Colors Speed'].value))
            end

            coroutine.yield(0)
        end
        settings['Random Secondary Color'].Enabled = f.on
    end)


    Script.Feature['Random Wheel Color'] = menu.add_feature('Random Wheel', 'toggle', Script.Parent['Random Colors'].id, function(f)
        ToggleOff({'Synced Colors', 'Rainbow Wheel Color', '100 Black'})
        settings['Random Wheel Color'] = {Enabled = f.on}

        while f.on do
            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) then
                utility.request_ctrl(veh)

                vehicle.set_vehicle_custom_wheel_colour(veh, math.random(0, 0xffffff))
                coroutine.yield(10000 - math.floor(Script.Feature['Vehicle Colors Speed'].value))
            end

            coroutine.yield(0)
        end
        settings['Random Wheel Color'].Enabled = f.on
    end)


    Script.Feature['Random Pearlescent Color'] = menu.add_feature('Random Pearlescent', 'toggle', Script.Parent['Random Colors'].id, function(f)
        ToggleOff({'Synced Colors', 'Rainbow Pearlescent Color', '100 Black'})
        settings['Random Pearlescent Color'] = {Enabled = f.on}

        while f.on do
            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) then
                utility.request_ctrl(veh)

                vehicle.set_vehicle_custom_pearlescent_colour(veh, math.random(0, 0xffffff))
                coroutine.yield(10000 - math.floor(Script.Feature['Vehicle Colors Speed'].value))
            end

            coroutine.yield(0)
        end
        settings['Random Pearlescent Color'].Enabled = f.on
    end)


    Script.Feature['Random Neon Color'] = menu.add_feature('Random Neon Lights', 'toggle', Script.Parent['Random Colors'].id, function(f)
        ToggleOff({'Synced Colors', 'Rainbow Neon Color', '100 Black'})
        settings['Random Neon Color'] = {Enabled = f.on}

        while f.on do
            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) then
                utility.request_ctrl(veh)

                local color = math.random(0, 0xffffff)

                vehicle.set_vehicle_neon_lights_color(veh, color)
                coroutine.yield(10000 - math.floor(Script.Feature['Vehicle Colors Speed'].value))
            end

            coroutine.yield(0)
        end
        settings['Random Neon Color'].Enabled = f.on
    end)


    Script.Feature['Random Smoke Color'] = menu.add_feature('Random Smoke', 'toggle', Script.Parent['Random Colors'].id, function(f)
        ToggleOff({'Synced Colors', 'Rainbow Smoke Color', '100 Black'})
        settings['Random Smoke Color'] = {Enabled = f.on}

        while f.on do
            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) then
                utility.request_ctrl(veh)

                local colorR = math.random(0, 255)
                local colorG = math.random(0, 255)
                local colorB = math.random(0, 255)

                vehicle.set_vehicle_tire_smoke_color(veh, colorR, colorG, colorB)
                coroutine.yield(10000 - math.floor(Script.Feature['Vehicle Colors Speed'].value))
            end

            coroutine.yield(0)
        end
        settings['Random Smoke Color'].Enabled = f.on
    end)


    Script.Feature['Random Xenon Color'] = menu.add_feature('Random Xenon', 'toggle', Script.Parent['Random Colors'].id, function(f)
        ToggleOff({'Synced Colors', 'Rainbow Xenon Color', '100 Black'})
        settings['Random Xenon Color'] = {Enabled = f.on}

        while f.on do
            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) then
                utility.request_ctrl(veh)

                vehicle.set_vehicle_headlight_color(veh, math.random(0, 12))
                coroutine.yield(10000 - math.floor(Script.Feature['Vehicle Colors Speed'].value))
            end

            coroutine.yield(0)
        end
        settings['Random Xenon Color'].Enabled = f.on
    end)


    Script.Parent['Rainbow Colors'] = menu.add_feature('Rainbow Colors', 'parent', Script.Parent['Vehice Colors'].id, nil)


    Script.Feature['Rainbow Primary Color'] = menu.add_feature('Rainbow Primary', 'toggle', Script.Parent['Rainbow Colors'].id, function(f)
        ToggleOff({'Synced Colors', 'Random Primary Color', '100 Black'})
        settings['Rainbow Primary Color'] = {Enabled = f.on}

        while f.on do
            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) then
                utility.request_ctrl(veh)

                for i = 1, #neon_lights_rgb do
                    vehicle.set_vehicle_custom_primary_colour(veh, Math.RGBToHex({neon_lights_rgb[i][1], neon_lights_rgb[i][2], neon_lights_rgb[i][3]}))
                    coroutine.yield(10000 - math.floor(Script.Feature['Vehicle Colors Speed'].value))
                end

            end

            coroutine.yield(0)
        end
        settings['Rainbow Primary Color'].Enabled = f.on
    end)


    Script.Feature['Rainbow Secondary Color'] = menu.add_feature('Rainbow Secondary', 'toggle', Script.Parent['Rainbow Colors'].id, function(f)
        ToggleOff({'Synced Colors', 'Random Secondary Color', '100 Black'})
        settings['Rainbow Secondary Color'] = {Enabled = f.on}

        while f.on do
            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) then
                utility.request_ctrl(veh)

                for i = 1, #neon_lights_rgb do
                    vehicle.set_vehicle_custom_secondary_colour(veh, Math.RGBToHex({neon_lights_rgb[i][1], neon_lights_rgb[i][2], neon_lights_rgb[i][3]}))
                    coroutine.yield(10000 - math.floor(Script.Feature['Vehicle Colors Speed'].value))
                end

            end

            coroutine.yield(0)
        end
        settings['Rainbow Secondary Color'].Enabled = f.on
    end)


    Script.Feature['Rainbow Wheel Color'] = menu.add_feature('Rainbow Wheel', 'toggle', Script.Parent['Rainbow Colors'].id, function(f)
        ToggleOff({'Synced Colors', 'Random Wheel Color', '100 Black'})
        settings['Rainbow Wheel Color'] = {Enabled = f.on}

        while f.on do
            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) then
                utility.request_ctrl(veh)

                for i = 1, #neon_lights_rgb do
                    vehicle.set_vehicle_custom_wheel_colour(veh, Math.RGBToHex({neon_lights_rgb[i][1], neon_lights_rgb[i][2], neon_lights_rgb[i][3]}))
                    coroutine.yield(10000 - math.floor(Script.Feature['Vehicle Colors Speed'].value))
                end

            end

            coroutine.yield(0)
        end
        settings['Rainbow Wheel Color'].Enabled = f.on
    end)


    Script.Feature['Rainbow Pearlescent Color'] = menu.add_feature('Rainbow Pearlescent', 'toggle', Script.Parent['Rainbow Colors'].id, function(f)
        ToggleOff({'Synced Colors', 'Random Pearlescent Color', '100 Black'})
        settings['Rainbow Pearlescent Color'] = {Enabled = f.on}

        while f.on do
            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) then
                utility.request_ctrl(veh)

                for i = 1, #neon_lights_rgb do
                    vehicle.set_vehicle_custom_pearlescent_colour(veh, Math.RGBToHex({neon_lights_rgb[i][1], neon_lights_rgb[i][2], neon_lights_rgb[i][3]}))
                    coroutine.yield(10000 - math.floor(Script.Feature['Vehicle Colors Speed'].value))
                end

            end

            coroutine.yield(0)
        end
        settings['Rainbow Pearlescent Color'].Enabled = f.on
    end)


    Script.Feature['Rainbow Neon Color'] = menu.add_feature('Rainbow Neon Lights', 'toggle', Script.Parent['Rainbow Colors'].id, function(f)
        ToggleOff({'Synced Colors', 'Random Neon Color', '100 Black'})
        settings['Rainbow Neon Color'] = {Enabled = f.on}

        while f.on do
            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) then
                utility.request_ctrl(veh)

                for i = 1, #neon_lights_rgb do
                    vehicle.set_vehicle_neon_lights_color(veh, Math.RGBToHex({neon_lights_rgb[i][1], neon_lights_rgb[i][2], neon_lights_rgb[i][3]}))
                    coroutine.yield(10000 - math.floor(Script.Feature['Vehicle Colors Speed'].value))
                end

            end

            coroutine.yield(0)
        end
        settings['Rainbow Neon Color'].Enabled = f.on
    end)


    Script.Feature['Rainbow Smoke Color'] = menu.add_feature('Rainbow Smoke', 'toggle', Script.Parent['Rainbow Colors'].id, function(f)
        ToggleOff({'Synced Colors', 'Random Smoke Color', '100 Black'})
        settings['Rainbow Smoke Color'] = {Enabled = f.on}

        while f.on do
            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) then
                utility.request_ctrl(veh)

                for i = 1, #neon_lights_rgb do
                    local c = neon_lights_rgb[i]
                    vehicle.set_vehicle_tire_smoke_color(veh, c[1], c[2], c[3])
                    coroutine.yield(10000 - math.floor(Script.Feature['Vehicle Colors Speed'].value))
                end

            end

            coroutine.yield(0)
        end
        settings['Rainbow Smoke Color'].Enabled = f.on
    end)


    Script.Feature['Rainbow Xenon Color'] = menu.add_feature('Rainbow Xenon', 'toggle', Script.Parent['Rainbow Colors'].id, function(f)
        ToggleOff({'Synced Colors', 'Random Xenon Color', '100 Black'})
        settings['Rainbow Xenon Color'] = {Enabled = f.on}

        while f.on do
            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) then
                utility.request_ctrl(veh)

                for i = 0, 12 do
                    vehicle.set_vehicle_headlight_color(veh, i)
                    coroutine.yield(10000 - math.floor(Script.Feature['Vehicle Colors Speed'].value))
                end

            end

            coroutine.yield(0)
        end
        settings['Rainbow Xenon Color'].Enabled = f.on
    end)


    Script.Feature['Synced Colors'] = menu.add_feature('Synced Colors', 'value_str', Script.Parent['Vehice Colors'].id, function(f)
        ToggleOff(rainbow_colors)
        ToggleOff(random_colors)
        ToggleOff({'100 Black'})
        settings['Synced Colors'] = {Enabled = f.on, Value = f.value}

        while f.on do
            if f.value == 0 then
                local veh = get.OwnVehicle()

                if utility.valid_vehicle(veh) then
                    utility.color_veh(veh, {math.random(0, 255), math.random(0, 255), math.random(0, 255)})
                    coroutine.yield(10000 - math.floor(Script.Feature['Vehicle Colors Speed'].value))
                end
            end
            if f.value == 1 then
                local veh = get.OwnVehicle()

                if utility.valid_vehicle(veh) then
                    for i = 1, #neon_lights_rgb do
                        if veh ~= get.OwnVehicle() or f.value ~= 1 then
                            break
                        end

                        if not f.on then
                            settings['Synced Colors'].Enabled = f.on
                            return
                        end

                        local c = neon_lights_rgb[i]

                        utility.color_veh(veh, {c[1], c[2], c[3]}, i)
                        coroutine.yield(10000 - math.floor(Script.Feature['Vehicle Colors Speed'].value))
                    end
                end
            end
            if f.value == 2 then
                local veh = get.OwnVehicle()

                if utility.valid_vehicle(veh) then
                    local step

                    step = math.floor((101 - (Script.Feature['Vehicle Colors Speed'].value / 25)) / 2)
                    if step < 1 then
                        step = 1
                    end
                    for i = 0, 255, step do
                        if not f.on then
                            settings['Synced Colors'].Enabled = f.on
                            return
                        end

                        utility.color_veh(veh, {255, i, 0})
                    end

                    step = math.floor((101 - (Script.Feature['Vehicle Colors Speed'].value / 25)) / 2)
                    if step < 1 then
                        step = 1
                    end
                    for i = 255, 0, -step do
                        if not f.on then
                            settings['Synced Colors'].Enabled = f.on
                            return
                        end
                        utility.color_veh(veh, {i, 255, 0})
                    end
                    
                    step = math.floor((101 - (Script.Feature['Vehicle Colors Speed'].value / 25)) / 2)
                    if step < 1 then
                        step = 1
                    end
                    for i = 0, 255, step do
                        if not f.on then
                            settings['Synced Colors'].Enabled = f.on
                            return
                        end
                        utility.color_veh(veh, {0, 255, i})
                    end
                    step = math.floor((101 - (Script.Feature['Vehicle Colors Speed'].value / 25)) / 2)
                    if step < 1 then
                        step = 1
                    end
                    for i = 255, 0, -step do
                        if not f.on then
                            settings['Synced Colors'].Enabled = f.on
                            return
                        end
                        utility.color_veh(veh, {0, i, 255})
                    end
                    step = math.floor((101 - (Script.Feature['Vehicle Colors Speed'].value / 25)) / 2)
                    if step < 1 then
                        step = 1
                    end
                    for i = 0, 255, step do
                        if not f.on then
                            settings['Synced Colors'].Enabled = f.on
                            return
                        end
                        utility.color_veh(veh, {i, 0, 255})
                    end
                    step = math.floor((101 - (Script.Feature['Vehicle Colors Speed'].value / 25)) / 2)
                    if step < 1 then
                        step = 1
                    end
                    for i = 255, 0, -step do
                        if not f.on then
                            settings['Synced Colors'].Enabled = f.on
                            return
                        end
                        utility.color_veh(veh, {255, 0, i})
                    end
                end
            end
            settings['Synced Colors'].Value = f.value
            coroutine.yield(0)
        end
        settings['Synced Colors'].Enabled = f.on
    end)
    Script.Feature['Synced Colors']:set_str_data({'Random', 'Rainbow', 'Smooth Rainbow'})


    Script.Feature['100 Black'] = menu.add_feature('100% Black', 'value_str', Script.Parent['Vehice Colors'].id, function(f)
        if f.value == 0 then
            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) then
                utility.color_veh(veh, {0, 0, 0}, 0)
                vehicle.set_vehicle_tire_smoke_color(veh, 1, 1, 1)
            else
                Notify('No valid vehicle found.', "Error", '100% Black')
            end

            f.on = false
            return
        end

        settings['100 Black'] = {Enabled = f.on}
        ToggleOff(rainbow_colors)
        ToggleOff(random_colors)
        ToggleOff({'Synced Colors'})

        while f.on do
            if f.value == 0 then
                f.on = false
                return
            end
            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) then
                utility.color_veh(veh, {0, 0, 0}, 0)
                vehicle.set_vehicle_tire_smoke_color(veh, 1, 1, 1)
            end

            coroutine.yield(0)
        end
        settings['100 Black'].Enabled = f.on
    end)
    Script.Feature['100 Black']:set_str_data({'Once', 'Loop'})


    Script.Parent['Explosive Horn Beam'] = menu.add_feature('Explosive Horn Beam', 'parent', Script.Parent['local_vehicle'].id, nil)
    

    Script.Feature['Enable Horn Beam'] = menu.add_feature('Enable Horn Beam', 'toggle', Script.Parent['Explosive Horn Beam'].id, function(f)
        settings['Enable Horn Beam'] = {Enabled = f.on}
        while f.on do
            local user = Self()
            if get.SCID(Script.Feature['Horn Beam For Others'].value) ~= -1 then
                user = Script.Feature['Horn Beam For Others'].value
            end
            local veh, pos, pos2, einheitsvektor, modifikator
            local vectorV3 = v3()
            local pxmin, pxmax, pymin, pymax, pzmin, pzmax
            if player.is_player_pressing_horn(user) then
                veh = get.PlayerVehicle(user)
                for i = 0, 5 do
                    pos = entity.get_entity_coords(veh)
                    coroutine.yield(5)
                    if i > 0 then
                        pos2 = entity.get_entity_coords(veh)
                        vectorV3.x = pos2.x - pos.x
                        vectorV3.y = pos2.y - pos.y
                        vectorV3.z = pos2.z - pos.z
                        if vectorV3.x ~= 0 and vectorV3.y ~= 0 and vectorV3.z ~= 0 then
                            einheitsvektor =
                                1 /
                                (((vectorV3.x * vectorV3.x) + (vectorV3.y * vectorV3.y) + (vectorV3.z * vectorV3.z)) ^
                                    0.5)
                            modifikator = math.random(Script.Feature['Horn Beam Min Range'].value, Script.Feature['Horn Beam Max Range'].value)
                            pos2.x = pos2.x + (modifikator * einheitsvektor * vectorV3.x)
                            pos2.y = pos2.y + (modifikator * einheitsvektor * vectorV3.y)
                            pos2.z = pos2.z + (modifikator * einheitsvektor * vectorV3.z)
                            pxmin = math.floor(pos2.x - Script.Feature['Horn Beam Radius'].value)
                            pxmax = math.floor(pos2.x + Script.Feature['Horn Beam Radius'].value)
                            pymin = math.floor(pos2.y - Script.Feature['Horn Beam Radius'].value)
                            pymax = math.floor(pos2.y + Script.Feature['Horn Beam Radius'].value)
                            pzmin = math.floor(pos2.z - Script.Feature['Horn Beam Radius'].value)
                            pzmax = math.floor(pos2.z + Script.Feature['Horn Beam Radius'].value)
                            pos2.x = math.random(pxmin, pxmax)
                            pos2.y = math.random(pymin, pymax)
                            pos2.z = math.random(pzmin, pzmax)
                            fire.add_explosion(pos2, Script.Feature['Horn Beam Type'].value, true, false, 0.1, 0)
                            pos2.x = math.random(pxmin, pxmax)
                            pos2.y = math.random(pymin, pymax)
                            pos2.z = math.random(pzmin, pzmax)
                            fire.add_explosion(pos2, Script.Feature['Horn Beam Type 2'].value, true, false, 0.1, 0)
                        end
                    end
                end
            end
            coroutine.yield(0)
        end
        settings['Enable Horn Beam'].Enabled = f.on
    end)


    Script.Feature['Horn Beam Type'] = menu.add_feature('Select Explosion', 'action_value_i', Script.Parent['Explosive Horn Beam'].id, function(f)
        settings['Horn Beam Type'] = {Value = f.value}
        Notify('Beam Explosion Type 1: ' .. f.value, "Success")
    end)
    Script.Feature['Horn Beam Type'].max = 74
    Script.Feature['Horn Beam Type'].min = 0


    Script.Feature['Horn Beam Type 2'] = menu.add_feature('Select Explosion 2', 'action_value_i', Script.Parent['Explosive Horn Beam'].id, function(f)
        settings['Horn Beam Type 2'] = {Value = f.value}
        Notify('Beam Explosion Type 2: ' .. f.value, "Success")
    end)
    Script.Feature['Horn Beam Type 2'].max = 74
    Script.Feature['Horn Beam Type 2'].min = 0


    Script.Feature['Horn Beam Radius'] = menu.add_feature('Select Scattering', 'action_value_i', Script.Parent['Explosive Horn Beam'].id, function(f)
        settings['Horn Beam Radius'] = f.value
        Notify('Beam Radius: ' .. f.value, "Success")
    end)
    Script.Feature['Horn Beam Radius'].max = 10
    Script.Feature['Horn Beam Radius'].min = 1


    Script.Feature['Horn Beam Min Range'] = menu.add_feature('Select Min Range', 'action_value_i', Script.Parent['Explosive Horn Beam'].id, function(f)
        settings['Horn Beam Min Range'] = {Value = f.value}
        Notify('Beam Min Range: ' .. f.value, "Success")
    end)
    Script.Feature['Horn Beam Min Range'].max = 100
    Script.Feature['Horn Beam Min Range'].min = 10
    Script.Feature['Horn Beam Min Range'].mod = 5


    Script.Feature['Horn Beam Max Range'] = menu.add_feature('Select Max Range', 'action_value_i', Script.Parent['Explosive Horn Beam'].id, function(f)
        settings['Horn Beam Max Range'] = {Value = f.value}
        Notify('Beam Max Range: ' .. f.value, "Success")
    end)
    Script.Feature['Horn Beam Max Range'].max = 300
    Script.Feature['Horn Beam Max Range'].min = 100
    Script.Feature['Horn Beam Max Range'].mod = 5


    Script.Feature['Horn Beam For Others'] = menu.add_feature('Enable Horn for Player', 'action_value_i', Script.Parent['Explosive Horn Beam'].id, function(f)
        if get.SCID(f.value) ~= -1 then
            Notify('Selected Player: ' .. get.Name(f.value), "Success")
        else
            Notify('Invalid Player.', "Error")
        end
    end)
    Script.Feature['Horn Beam For Others'].max = 31
    Script.Feature['Horn Beam For Others'].min = -1
    Script.Feature['Horn Beam For Others'].value = -1


    Script.Parent['License Plates'] = menu.add_feature('License Plates', 'parent', Script.Parent['local_vehicle'].id, nil)


    Script.Feature['Change Force Plate Text'] = menu.add_feature('Change Text', 'action_value_str', Script.Parent['License Plates'].id, function(f)
        local text = get.Input('Enter License Plate Text', 8, 0)
        if not text then
            Notify('Input canceled.', "Error", '')
            return
        end

        f:set_str_data({text})
        settings['Change Force Plate Text'] = {Value = f:get_str_data()[1]}
    end)
    Script.Feature['Change Force Plate Text']:set_str_data({'2Take1'})


    Script.Feature['Force Plate Text'] = menu.add_feature('Force License Plate', 'toggle', Script.Parent['License Plates'].id, function(f)
        ToggleOff({'Animated License Plate', 'License Speedometer', 'Empty Plate Text'})
        settings['Force Plate Text'] = {Enabled = f.on}

        while f.on do
            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) then
                utility.request_ctrl(veh)

                vehicle.set_vehicle_number_plate_text(veh, Script.Feature['Change Force Plate Text']:get_str_data()[1])
            end
            
            coroutine.yield(0)
        end
        settings['Force Plate Text'].Enabled = f.on
    end)


    Script.Feature['Empty Plate Text'] = menu.add_feature('Empty License Plate', 'toggle', Script.Parent['License Plates'].id, function(f)
        ToggleOff({'Animated License Plate', 'License Speedometer', 'Force Plate Text'})
        settings['Empty Plate Text'] = {Enabled = f.on}

        while f.on do
            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) then
                utility.request_ctrl(veh)

                entity.set_entity_as_mission_entity(veh, true, true)
                vehicle.set_vehicle_number_plate_text(veh, " ")
            end
            
            coroutine.yield(0)
        end
        settings['Empty Plate Text'].Enabled = f.on
    end)


    Script.Feature['Animated License Plate'] = menu.add_feature('Animated License Plate', 'value_str', Script.Parent['License Plates'].id, function(f)
        ToggleOff({'Force Plate Text', 'License Speedometer', 'Empty Plate Text'})
        settings['Animated License Plate'] = {Enabled = f.on, Value = f.value}
        local anim_plate = {
            {"       2", "      2T", "     2TA", "    2TAK", "   2TAKE", "  2TAKE1", " 2TAKE1 ", "2TAKE1 M", "TAKE1 ME", "AKE1 MEN", "KE1 MENU", "E1 MENU ",
            "1 MENU  ", " MENU   ", "MENU    ", "ENU     ", "NU      ", "U      ", " "
            },

            {"       2", "      2T", "     2TA", "    2TAK", "   2TAKE", "  2TAKE1", " 2TAKE1 ", "2TAKE1 M", "TAKE1 ME", "AKE1 MEN", "KE1 MENU", "E1 MENU ",
            "1 MENU  ", " MENU   ", "MENU    ", "ENU     ", "NU      ", "U      ", " ", " 2Take1 ", " ", " 2Take1 ", " ", " 2Take1 ", " ", " 2Take1 ", " ", " 2Take1 ", " "
            }
        }
        
        while f.on do
            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) then
                utility.request_ctrl(veh)

                local text = anim_plate[f.value + 1]
                for i = 1, #text do
                    if f.on and veh == get.OwnVehicle() then
                        vehicle.set_vehicle_number_plate_text(veh, text[i])
                        coroutine.yield(200)
                    else
                        settings['Animated License Plate'].Enabled = f.on
                        break
                    end

                end

            end

            settings['Animated License Plate'].Value = f.value
            coroutine.yield(0)
        end
        settings['Animated License Plate'].Enabled = f.on
    end)
    Script.Feature['Animated License Plate']:set_str_data({'Slide', 'Slide & Flash'})


    Script.Feature['License Speedometer'] = menu.add_feature('License Plate Speedometer', 'value_str', Script.Parent['License Plates'].id, function(f)
        ToggleOff({'Force Plate Text', 'Animated License Plate', 'Empty Plate Text'})
        settings['License Speedometer'] = {Enabled = f.on, Value = f.value}

        while f.on do
            local speedovalue
            local speedoname
            
            if f.value == 0 then
                speedovalue = 3.6
                speedoname = 'KMH'
            end

            if f.value == 1 then
                speedovalue = 2.23694
                speedoname = 'MPH'
            end

            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) then
                local speed = entity.get_entity_speed(veh) * speedovalue
                if speed < 10 and speed > 0.01 then
                    speed = string.format('%.2f', speed)

                elseif speed >= 10 and speed < 100 then
                    speed = string.format('%.1f', speed)

                elseif speed < 0.01 and f.value == 7 then
                    speed = string.format('%.5f', speed)

                else
                    speed = math.floor(speed)
                end

                utility.request_ctrl(veh)
                vehicle.set_vehicle_number_plate_text(veh, tostring(speed) .. speedoname)

            end

            settings['License Speedometer'].Value = f.value
            coroutine.yield(0)
        end
        settings['License Speedometer'].Enabled = f.on
    end)
    Script.Feature['License Speedometer']:set_str_data({'KMH', 'MPH'})


    Script.Parent['AI Driving'] = menu.add_feature('AI Driving', 'parent', Script.Parent['local_vehicle'].id, nil)


    Script.Feature['AI Driving Style'] = menu.add_feature('Driving Style', 'autoaction_value_str', Script.Parent['AI Driving'].id)
    Script.Feature['AI Driving Style']:set_str_data({'Normal', 'Avoid Traffic', 'Rushed', 'Extremly Rushed', 'Backwards'})
    

    Script.Feature['AI Driving Start'] = menu.add_feature('Enable AI Driving', 'value_str', Script.Parent['AI Driving'].id, function(f)
        local drivingstyle = {786859, 572, 786469, 786980, 263595}
        local veh = 0
        local driving

        while f.on do
            if vehicle.is_vehicle_stuck_on_roof(veh) then
                vehicle.set_vehicle_on_ground_properly(veh)
            end

            if get.OwnVehicle() ~= veh then
                driving = false
            end
            
            veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) then
                if driving then
                    goto continue
                end

                if f.value == 0 then
                    ai.task_vehicle_drive_wander(get.OwnPed(), veh, 100, drivingstyle[Script.Feature['AI Driving Style'].value  + 1])
                    driving = true

                else
                    local waypoint = ui.get_waypoint_coord()
                    if waypoint.x == 16000 then
                        goto continue
                    end

                    while f.on and f.value == 1 and waypoint.x ~= 16000 do
                        waypoint = ui.get_waypoint_coord()
                        local veh2 = entity.get_entity_model_hash(veh)
                        ai.task_vehicle_drive_to_coord(get.OwnPed(), veh, v3(waypoint.x, waypoint.y, 0), 100, 10, veh2, drivingstyle[Script.Feature['AI Driving Style'].value  + 1], 1, 1)
                        coroutine.yield(500)
                    end
                    
                    local veh = get.OwnVehicle()
                    ped.clear_ped_tasks_immediately(get.OwnPed())
                    ped.set_ped_into_vehicle(get.OwnPed(), veh, -1)
                end

            end

            ::continue::
            coroutine.yield(2500)
        end

        local veh = get.OwnVehicle()
        ped.clear_ped_tasks_immediately(get.OwnPed())
        ped.set_ped_into_vehicle(get.OwnPed(), veh, -1)
    end)
    Script.Feature['AI Driving Start']:set_str_data({'Wander Around', 'To Waypoint'})


    Script.Feature['AI Driving Stop'] = menu.add_feature('Force Stop', 'action', Script.Parent['AI Driving'].id, function(f)
        local veh = get.OwnVehicle()
        if utility.valid_vehicle(veh) then
            ToggleOff({'AI Driving Start'})
            ped.clear_ped_tasks_immediately(get.OwnPed())
            ped.set_ped_into_vehicle(get.OwnPed(), veh, -1)
        end
    end)


    Script.Parent['Vehicle Boosts'] = menu.add_feature('Boosts', 'parent', Script.Parent['local_vehicle'].id, nil)


    Script.Feature['Infinite F1 Boost'] = menu.add_feature('Infinite F1 Boost', 'toggle', Script.Parent['Vehicle Boosts'].id, function(f)
        settings['Infinite F1 Boost'] = {Enabled = f.on}
        while f.on do
            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) then
                if entity.get_entity_model_hash(veh) == 0x1446590A or entity.get_entity_model_hash(veh) == 0x8B213907 or entity.get_entity_model_hash(veh) == 0x58F77553 or entity.get_entity_model_hash(veh) == 0x4669D038 then
                    local speed = entity.get_entity_speed(veh)

                    utility.request_ctrl(veh)
                    vehicle.set_vehicle_fixed(veh)

                    if speed > 75.0 then
                        vehicle.set_vehicle_forward_speed(veh, speed)
                    end

                end

            end 

            coroutine.yield(500)
        end
        settings['Infinite F1 Boost'].Enabled = f.on
    end)


    Script.Feature['Infinite Rocket Boost'] = menu.add_feature('Infinite Rocket Boost', 'toggle', Script.Parent['Vehicle Boosts'].id, function(f)
        settings['Infinite Rocket Boost'] = {Enabled = f.on}
        while f.on do
            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) and vehicle.is_vehicle_rocket_boost_active(veh) then
                vehicle.set_vehicle_rocket_boost_percentage(veh, 100.0)

            end

            coroutine.yield(100)
        end
        settings['Infinite Rocket Boost'].Enabled = f.on
    end)


    Script.Feature['Instant Horn Boost'] = menu.add_feature('Instant Horn Boost', 'slider', Script.Parent['Vehicle Boosts'].id, function(f)
        ToggleOff({'Extreme Horn Boost'})
        settings['Instant Horn Boost'] = {Enabled = f.on, Value = f.value}

        while f.on do
            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) and player.is_player_pressing_horn(Self()) then
                local speed = entity.get_entity_speed(veh)
                    
                if speed < f.value then
                    utility.request_ctrl(veh)
                    vehicle.set_vehicle_forward_speed(veh, f.value)
                end

            end

            settings['Instant Horn Boost'].Value = f.value
            coroutine.yield(0)
        end
        settings['Instant Horn Boost'].Enabled = f.on
    end)
    Script.Feature['Instant Horn Boost'].max = 150
    Script.Feature['Instant Horn Boost'].min = 25
    Script.Feature['Instant Horn Boost'].mod = 25


    Script.Feature['Extreme Horn Boost'] = menu.add_feature('Extreme Horn Boost', 'slider', Script.Parent['Vehicle Boosts'].id, function(f)
        ToggleOff({'Instant Horn Boost'})
        settings['Extreme Horn Boost'] = {Enabled = f.on, Value = f.value}

        while f.on do
            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) and player.is_player_pressing_horn(Self()) then
                utility.request_ctrl(veh)

                entity.set_entity_max_speed(veh, f.value)
                vehicle.set_vehicle_forward_speed(veh, f.value)
            end

            settings['Extreme Horn Boost'].Value = f.value
            coroutine.yield(0)
        end
        settings['Extreme Horn Boost'].Enabled = f.on
    end)
    Script.Feature['Extreme Horn Boost'].max = 5000
    Script.Feature['Extreme Horn Boost'].min = 250
    Script.Feature['Extreme Horn Boost'].mod = 250


    Script.Feature['Upgrade Vehicle'] = menu.add_feature('Upgrade Modifier', 'action_value_str', Script.Parent['local_vehicle'].id, function(f)
        local veh = get.OwnVehicle()
        if not utility.valid_vehicle(veh) then
            Notify('No valid vehicle found.', "Error", '')
            return
        end

        if f.value == 0 then
            utility.MaxVehicle(veh)

        elseif f.value == 1 then
            utility.MaxVehicle(veh, 3)

        elseif f.value == 2 then
            vehicle.set_vehicle_mod_kit_type(veh, 0)
            for i = 0, 47 do
                vehicle.set_vehicle_mod(veh, i, -1, false)
                vehicle.toggle_vehicle_mod(veh, i, false)
            end
    
            vehicle.set_vehicle_bulletproof_tires(veh, false)
            vehicle.set_vehicle_window_tint(veh, 0)
            vehicle.set_vehicle_number_plate_index(veh, 0)
        end
    end)
    Script.Feature['Upgrade Vehicle']:set_str_data({'Full Upgrade', 'Random Upgrades', 'Full Downgrade'})


    Script.Feature['Set Custom Tires'] = menu.add_feature('Custom Tires', 'toggle', Script.Parent['local_vehicle'].id, function(f)
        local veh

        while f.on do
            veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) then
                local wheel = vehicle.get_vehicle_mod(veh, 23)
                local wheeltype = vehicle.get_vehicle_wheel_type(veh)

                if wheel ~= -1 and wheeltype <= 7 then
                    vehicle.set_vehicle_mod_kit_type(veh, 0)
                    vehicle.set_vehicle_mod(veh, 23, wheel, true)
                end

            end

            coroutine.yield(0)
        end

        if utility.valid_vehicle(veh) then
            local wheel = vehicle.get_vehicle_mod(veh, 23)
            local wheeltype = vehicle.get_vehicle_wheel_type(veh)

            if wheel ~= -1 and wheeltype <= 7 then
                vehicle.set_vehicle_mod_kit_type(veh, 0)
                vehicle.set_vehicle_mod(veh, 23, wheel, false)
            end
            
        end
    end)


    Script.Feature['Set Drift Tires'] = menu.add_feature('Drift Tires', 'toggle', Script.Parent['local_vehicle'].id, function(f)
        local veh

        while f.on do
            veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) and not vehicle.get_vehicle_drift_tires(veh) then
                vehicle.set_vehicle_drift_tires(veh, true)
            end
            
            coroutine.yield(0)
        end

        if utility.valid_vehicle(veh) and vehicle.get_vehicle_drift_tires(veh) then
            vehicle.set_vehicle_drift_tires(veh, false)
        end
    end)


    Script.Feature['Vehicle Parachute'] = menu.add_feature('Parachute on all Cars', 'toggle', Script.Parent['local_vehicle'].id, function(f)
        local hash
        local veh

        while f.on do
            veh = get.OwnVehicle()

            if not utility.valid_vehicle(veh) then
                goto continue
            end

            hash = entity.get_entity_model_hash(veh)

            if not streaming.is_model_a_car(hash) then
                goto continue
            end

            if not streaming.does_vehicle_model_have_parachute(hash) then
                streaming.set_vehicle_model_has_parachute(hash, true)
            end

            ::continue::
            coroutine.yield(500)
        end

        if utility.valid_vehicle(veh) then
            while not vehicle.is_vehicle_on_all_wheels(veh) do
                coroutine.yield(0)
            end
            streaming.set_vehicle_model_has_parachute(hash, false)
        end
    end)


    Script.Feature['Vehicle Godmode v2'] = menu.add_feature('Vehicle Godmode v2', 'toggle', Script.Parent['local_vehicle'].id, function(f)
        if not menu.is_trusted_mode_enabled(1 << 2) then
            Notify('Not available while trusted mode for natives is turned off', 'Error', 'Vehicle Godmode v2')
            f.on = false
            return
        end

        settings['Vehicle Godmode v2'] = {Enabled = f.on}
        while f.on do
            if not menu.is_trusted_mode_enabled(1 << 2) then
                f.on = false
            end

            local veh = get.OwnVehicle()
            if utility.valid_vehicle(veh) then
                
                N.ENTITY.SET_ENTITY_PROOFS(veh, 1, 1, 1, 1, 1, 1, 1, 1)
            end
    
            settings['Vehicle Godmode v2'].Enabled = f.on
            coroutine.yield(500)
        end
    
        local veh = get.OwnVehicle()
        if utility.valid_vehicle(veh) then
            N.ENTITY.SET_ENTITY_PROOFS(veh, 0, 0, 0, 0, 0, 0, 1, 0)
        end
    
        settings['Vehicle Godmode v2'].Enabled = f.on
    end)


    Script.Feature['Auto Repair Vehicle'] = menu.add_feature('Auto Repair Vehicle', 'toggle', Script.Parent['local_vehicle'].id, function(f)
        settings['Auto Repair Vehicle'] = {Enabled = f.on}
        while f.on do
            local veh = get.OwnVehicle()

            if utility.valid_vehicle(veh) then
                utility.request_ctrl(veh)

                utility.RepairVehicle(veh)
            end

            coroutine.yield(2000)
        end
        settings['Auto Repair Vehicle'].Enabled = f.on
    end)


    Script.Feature['Instantly Enter Vehicles'] = menu.add_feature('Skip Enter/Exit Animation', 'toggle', Script.Parent['local_vehicle'].id, function(f)
        if not menu.is_trusted_mode_enabled(1 << 2) then
            Notify('Not available while trusted mode for natives is turned off', 'Error', 'Skip Enter/Exit Animation')
            f.on = false
            return
        end

        settings['Instantly Enter Vehicles'] = {Enabled = f.on}
        while f.on do
            if not menu.is_trusted_mode_enabled(1 << 2) then
                f.on = false
            end

            if controls.is_control_pressed(2, 75) and get.OwnVehicle() == 0 then
                local Ped = get.OwnPed()
                local veh = N.PED.GET_VEHICLE_PED_IS_ENTERING(Ped)
                if veh ~= 0 then
                    local driver = vehicle.get_ped_in_vehicle_seat(veh, -1)
                    if driver ~= 0 then
                        ped.clear_ped_tasks_immediately(driver)
                    end

                    ped.set_ped_into_vehicle(Ped, veh, -1)
                end

            elseif controls.is_control_pressed(2, 75) and get.OwnVehicle() ~= 0 then
                ped.clear_ped_tasks_immediately(get.OwnPed())
            end

            coroutine.yield(0)
        end
        settings['Instantly Enter Vehicles'].Enabled = f.on
    end)


    Script.Feature['Swap Vehicle Seats'] = menu.add_feature('Swap Vehicle Seat', 'action_value_i', Script.Parent['local_vehicle'].id, function(f)
        local veh = get.OwnVehicle()
        if veh ~= 0 then
            ped.set_ped_into_vehicle(get.OwnPed(), veh, Script.Feature['Swap Vehicle Seats'].value)
        end
    end)
    Script.Feature['Swap Vehicle Seats'].min = -1
    Script.Feature['Swap Vehicle Seats'].value = -1
    Script.Feature['Swap Vehicle Seats'].max = 15


    Script.Feature['Delete Current Vehicle'] = menu.add_feature('Delete Current Vehicle', 'action', Script.Parent['local_vehicle'].id, function()
        local veh = get.OwnVehicle()
        if utility.valid_vehicle(veh) then
            utility.request_ctrl(veh)
            entity.delete_entity(veh)
        else
            Notify('No vehicle found.', "Error")
        end
    end)

    Script.Parent['Custom Vehicles'] = menu.add_feature('Custom Vehicles', 'parent', Script.Parent['local_vehicle'].id, nil)


    Script.Parent['Moveable Robot'] = menu.add_feature('Moveable Robot', 'parent', Script.Parent['Custom Vehicles'].id, nil)


    Script.Feature['Enable Robot'] = menu.add_feature('Enable Robot', 'toggle', Script.Parent['Moveable Robot'].id, function(f)
        if f.on then
            if not robot_objects['tampa'] then
                local spawn_it = true
                local veh = get.OwnVehicle()
                if veh ~= 0 then
                    if 3084515313 == entity.get_entity_model_hash(veh) then
                        robot_objects['tampa'] = veh
                        spawn_it = false
                    end
                end
                if spawn_it then
                    robot_objects['tampa'] = Spawn.Vehicle(3084515313, get.OwnCoords(), get.OwnHeading())
                    decorator.decor_set_int(robot_objects['tampa'], 'MPBitset', 1 << 10)
                    entity.set_entity_god_mode(robot_objects['tampa'], true)
                    utility.MaxVehicle(veh)
                    if Script.Feature['Spawn in Custom Vehicle'].on then
                        ped.set_ped_into_vehicle(get.OwnPed(), robot_objects['tampa'], -1)
                    end
                    vehicle.set_vehicle_mod_kit_type(robot_objects['tampa'], 0)
                    for i = 0, 18 do
                        local mod = vehicle.get_num_vehicle_mods(robot_objects['tampa'], i)-1
                        vehicle.set_vehicle_mod(robot_objects['tampa'], i, mod, true)
                        vehicle.toggle_vehicle_mod(robot_objects['tampa'], mod, true)
                    end
                    vehicle.set_vehicle_bulletproof_tires(robot_objects['tampa'], true)
                    vehicle.set_vehicle_window_tint(robot_objects['tampa'], 1)
                    vehicle.set_vehicle_number_plate_index(veh, 1)
                    vehicle.set_vehicle_number_plate_text(robot_objects['tampa'], '2Take1')
                end
            end
            if robot_objects['ppdump'] == nil then
                robot_objects['ppdump'] = Spawn.Vehicle(0x810369E2)
                entity.set_entity_god_mode(robot_objects['ppdump'], true)
                entity.attach_entity_to_entity(robot_objects['ppdump'], robot_objects['tampa'], 0, v3(0, 0, 12.5), v3(), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            if robot_objects['llbone'] == nil then
                robot_objects['llbone'] = Spawn.Object(1803116220)
                entity.attach_entity_to_entity(robot_objects['llbone'], robot_objects['tampa'], 0, v3(-4.25, 0, 12.5), v3(), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            if robot_objects['rlbone'] == nil then
                robot_objects['rlbone'] = Spawn.Object(1803116220)
                entity.attach_entity_to_entity(robot_objects['rlbone'], robot_objects['tampa'], 0, v3(4.25, 0, 12.5), v3(), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            if robot_objects['lltrain'] == nil then
                robot_objects['lltrain'] = Spawn.Vehicle(1030400667)
                entity.set_entity_god_mode(robot_objects['lltrain'], true)
                entity.attach_entity_to_entity(robot_objects['lltrain'], robot_objects['llbone'], 0, v3(0, 0, -5), v3(90), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            if robot_objects['lfoot'] == nil then
                robot_objects['lfoot'] = Spawn.Vehicle(782665360)
                entity.set_entity_god_mode(robot_objects['lfoot'], true)
                entity.attach_entity_to_entity(robot_objects['lfoot'], robot_objects['llbone'], 0, v3(0, 2, -12.5), v3(), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            if robot_objects['rltrain'] == nil then
                robot_objects['rltrain'] = Spawn.Vehicle(1030400667)
                entity.set_entity_god_mode(robot_objects['rltrain'], true)
                entity.attach_entity_to_entity(robot_objects['rltrain'], robot_objects['rlbone'], 0, v3(0, 0, -5), v3(90), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            if robot_objects['rfoot'] == nil then
                robot_objects['rfoot'] = Spawn.Vehicle(782665360)
                entity.set_entity_god_mode(robot_objects['rfoot'], true)
                entity.attach_entity_to_entity(robot_objects['rfoot'], robot_objects['rlbone'], 0, v3(0, 2, -12.5), v3(), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            if robot_objects['body'] == nil then
                robot_objects['body'] = Spawn.Vehicle(1030400667)
                entity.set_entity_god_mode(robot_objects['body'], true)
                entity.attach_entity_to_entity(robot_objects['body'], robot_objects['tampa'], 0, v3(0, 0, 22.5), v3(90), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            if robot_objects['shoulder'] == nil then
                robot_objects['shoulder'] = Spawn.Vehicle(0x810369E2)
                entity.set_entity_god_mode(robot_objects['shoulder'], true)
                entity.attach_entity_to_entity(robot_objects['shoulder'], robot_objects['tampa'], 0, v3(0, 0, 27.5), v3(), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            if robot_objects['lheadbone'] == nil then
                robot_objects['lheadbone'] = Spawn.Object(1803116220)
                entity.attach_entity_to_entity(robot_objects['lheadbone'], robot_objects['tampa'], 0, v3(-3.25, 0, 27.5), v3(), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            if robot_objects['rheadbone'] == nil then
                robot_objects['rheadbone'] = Spawn.Object(1803116220)
                entity.attach_entity_to_entity(robot_objects['rheadbone'], robot_objects['tampa'], 0, v3(3.25, 0, 27.5), v3(), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            if robot_objects['lheadtrain'] == nil then
                robot_objects['lheadtrain'] = Spawn.Vehicle(1030400667)
                entity.set_entity_god_mode(robot_objects['lheadtrain'], true)
                entity.attach_entity_to_entity(robot_objects['lheadtrain'], robot_objects['lheadbone'], 0, v3(-3, 4, -5), v3(325, 0, 45), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            if robot_objects['lhand'] == nil then
                robot_objects['lhand'] = Spawn.Vehicle(782665360)
                entity.set_entity_god_mode(robot_objects['lhand'], true)
                entity.attach_entity_to_entity(robot_objects['lhand'], robot_objects['lheadtrain'], 0, v3(0, 7.5, 0), v3(), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            if robot_objects['rheadtrain'] == nil then
                robot_objects['rheadtrain'] = Spawn.Vehicle(1030400667)
                entity.set_entity_god_mode(robot_objects['rheadtrain'], true)
                entity.attach_entity_to_entity(robot_objects['rheadtrain'], robot_objects['rheadbone'], 0, v3(3, 4, -5), v3(325, 0, 315), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            if robot_objects['rhand'] == nil then
                robot_objects['rhand'] = Spawn.Vehicle(782665360)
                entity.set_entity_god_mode(robot_objects['rhand'], true)
                entity.attach_entity_to_entity(robot_objects['rhand'], robot_objects['rheadtrain'], 0, v3(0, 7.5, 0), v3(), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            if robot_objects['head'] == nil then
                robot_objects['head'] = Spawn.Object(-543669801)
                entity.attach_entity_to_entity(robot_objects['head'], robot_objects['tampa'], 0, v3(0, 0, 35), v3(), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            return HANDLER_CONTINUE
        end
        if not f.on then
            for i in pairs(robot_objects) do
                utility.clear({robot_objects[i]})
                robot_objects[i] = nil
            end
            if #entitys['robot_weapon_left'] ~= 0 then
                utility.clear(entitys['robot_weapon_left'])
                entitys['robot_weapon_left'] = {}
            end
            if #entitys['robot_weapon_right'] ~= 0 then
                utility.clear(entitys['robot_weapon_right'])
                entitys['robot_weapon_right'] = {}
            end
        end
    end)


    Script.Feature['Controllable Blasts'] = menu.add_feature('Controllable Blasts', 'toggle', Script.Parent['Moveable Robot'].id, function(f)
        if f.on then
            if not Script.Feature['Enable Robot'].on then
                coroutine.yield(2500)
            end
            local whash = gameplay.get_hash_key('weapon_airstrike_rocket')
            local pos = get.OwnCoords()
            local dir = cam.get_gameplay_cam_rot()
            dir:transformRotToDir()
            dir = dir * 1000
            pos = pos + dir
            local hit, hitpos, hitsurf, hash, ent = worldprobe.raycast((utility.OffsetCoords(get.OwnCoords(), get.OwnHeading(), 2) + v3(0, 0, 4)), pos, -1, 0)
            while not hit do
                pos = get.OwnCoords()
                dir = cam.get_gameplay_cam_rot()
                dir:transformRotToDir()
                dir = dir * 1000
                pos = pos + dir
                hit, hitpos, hitsurf, hash, ent = worldprobe.raycast((utility.OffsetCoords(get.OwnCoords(), get.OwnHeading(), 2) + v3(0, 0, 4)), pos, -1, 0)
                coroutine.yield(0)
            end
            if ped.is_ped_shooting(get.OwnPed()) and get.OwnVehicle() == robot_objects['tampa'] then
                if Script.Feature['Robot Equip Weapons'].on then
                    local lobj = entitys['robot_weapon_left'][1]
                    local lheading = entity.get_entity_heading(lobj)
                    local lpos = utility.OffsetCoords(entity.get_entity_coords(lobj), lheading, 12) + v3(0, 0, 3)
                    gameplay.shoot_single_bullet_between_coords(lpos, hitpos, 1000, whash, get.OwnPed(), true, false, 50000)
                    coroutine.yield(100)
                    local robj = entitys['robot_weapon_right'][1]
                    local rheading = entity.get_entity_heading(robj)
                    local rpos = utility.OffsetCoords(entity.get_entity_coords(robj), rheading, 12) + v3(0, 0, 3)
                    gameplay.shoot_single_bullet_between_coords(rpos, hitpos, 1000, whash, get.OwnPed(), true, false, 50000)
                else
                    local start = utility.OffsetCoords(get.OwnCoords(), get.OwnHeading(), 8) + v3(0, 0, 15)
                    gameplay.shoot_single_bullet_between_coords(start, hitpos, 1000, whash, get.OwnPed(), true, false, 10000)
                end
            end
        end
        settings['Controllable Blasts'] = {Enabled = f.on}
        return HANDLER_CONTINUE
    end)


    Script.Feature['Moveable Legs'] = menu.add_feature('Moveable Legs', 'toggle', Script.Parent['Moveable Robot'].id, function(f)
        settings['Moveable Legs'] = {Enabled = f.on}
        if f.on then
            if robot_objects['llbone'] and robot_objects['rlbone'] and robot_objects['tampa'] then
                local speed
                local left = robot_objects['llbone']
                local right = robot_objects['rlbone']
                local main = robot_objects['tampa']
                local offsetL = v3(-4.25, 0, 12.5)
                local offsetR = v3(4.25, 0, 12.5)
                for i = 0, 50 do
                    if robot_objects['tampa'] then
                        speed = entity.get_entity_speed(robot_objects['tampa'])
                        if not f.on or speed < 2.5 then
                            clear_legs_movement()
                            return HANDLER_CONTINUE
                        end
                        utility.request_ctrl(left)
                        utility.request_ctrl(right)
                        utility.request_ctrl(main)
                        entity.attach_entity_to_entity(left, main, 0, offsetL, v3(i, 0, 0), true, Script.Feature['Robot Collision'].on, false, 2, true)
                        entity.attach_entity_to_entity(right, main, 0, offsetR, v3(360 - i, 0, 0), true, Script.Feature['Robot Collision'].on, false, 2, true)
                        local wait = math.floor(51 - (speed / 1))
                        if wait < 1 then
                            wait = 0
                        end
                        coroutine.yield(wait)
                    end
                end
                for i = 50, -50, -1 do
                    if robot_objects['tampa'] then
                        speed = entity.get_entity_speed(robot_objects['tampa'])
                        if not f.on or speed < 2.5 then
                            clear_legs_movement()
                            return HANDLER_CONTINUE
                        end
                        utility.request_ctrl(left)
                        utility.request_ctrl(right)
                        utility.request_ctrl(main)
                        entity.attach_entity_to_entity(left, main, 0, offsetL, v3(i, 0, 0), true, Script.Feature['Robot Collision'].on, false, 2, true)
                        entity.attach_entity_to_entity(right, main, 0, offsetR, v3(360 - i, 0, 0), true, Script.Feature['Robot Collision'].on, false, 2, true)
                        local wait = math.floor(51 - (speed / 1))
                        if wait < 1 then
                            wait = 0
                        end
                        coroutine.yield(wait)
                    end
                end
                for i = -50, 0 do
                    if robot_objects['tampa'] then
                        speed = entity.get_entity_speed(robot_objects['tampa'])
                        if not f.on or speed < 2.5 then
                            clear_legs_movement()
                            return HANDLER_CONTINUE
                        end
                        utility.request_ctrl(left)
                        utility.request_ctrl(right)
                        utility.request_ctrl(main)
                        entity.attach_entity_to_entity(left, main, 0, offsetL, v3(i, 0, 0), true, Script.Feature['Robot Collision'].on, false, 2, true)
                        entity.attach_entity_to_entity(right, main, 0, offsetR, v3(360 - i, 0, 0), true, Script.Feature['Robot Collision'].on, false, 2, true)
                        local wait = math.floor(51 - (speed / 1))
                        if wait < 1 then
                            wait = 0
                        end
                        coroutine.yield(wait)
                    end
                end
            end
            return HANDLER_CONTINUE
        end
        if not f.on then
            clear_legs_movement()
        end
    end)


    Script.Feature['Robot Collision'] = menu.add_feature('Collision', 'toggle', Script.Parent['Moveable Robot'].id, function(f)
        settings['Robot Collision'] = {Enabled = f.on}
        if get.OwnVehicle() == robot_objects['tampa'] then
            Notify('Re-enable Robot to take effect of collision.', "Neutral")
        end
    end)


    Script.Feature['Rocket Propulsion'] = menu.add_feature('Rocket Propulsion (Visual)', 'toggle', Script.Parent['Moveable Robot'].id, function(f)
        if f.on and robot_objects['body'] then
            if robot_objects['spinning_1'] == nil then
                robot_objects['spinning_1'] = Spawn.Vehicle(0xFB133A17, get.OwnCoords())
                entity.set_entity_god_mode(robot_objects['spinning_1'], true)
                entity.set_entity_visible(robot_objects['spinning_1'], false)
                entity.attach_entity_to_entity(robot_objects['spinning_1'], robot_objects['body'], 0, v3(0, -5, 0), v3(-180, 0, 0), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            vehicle.set_heli_blades_speed(robot_objects['spinning_1'], 100)
            if robot_objects['spinning_middle'] == nil then
                robot_objects['spinning_middle'] = Spawn.Object(94602826)
                entity.set_entity_god_mode(robot_objects['spinning_middle'], true)
                entity.attach_entity_to_entity(robot_objects['spinning_middle'], robot_objects['spinning_1'], 0, v3(0, 0, 0), v3(0, 0, 0), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            if robot_objects['spinning_middle2'] == nil then
                robot_objects['spinning_middle2'] = Spawn.Object(94602826)
                entity.set_entity_god_mode(robot_objects['spinning_middle2'], true)
                entity.attach_entity_to_entity(robot_objects['spinning_middle2'], robot_objects['spinning_1'], 0, v3(0, 0, 1.5), v3(0, 0, 0), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            if robot_objects['spinning_middle3'] == nil then
                robot_objects['spinning_middle3'] = Spawn.Object(94602826)
                entity.set_entity_god_mode(robot_objects['spinning_middle3'], true)
                entity.attach_entity_to_entity(robot_objects['spinning_middle3'], robot_objects['spinning_1'], 0, v3(0, 0, 3), v3(0, 0, 0), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            local index = entity.get_entity_bone_index_by_name(robot_objects['spinning_1'], 'rotor_main')
            if robot_objects['glow_1'] == nil then
                robot_objects['glow_1'] = Spawn.Object(2655881418)
                entity.set_entity_god_mode(robot_objects['glow_1'], true)
                entity.attach_entity_to_entity(robot_objects['glow_1'], robot_objects['spinning_1'], index, v3(2, 3, 3), v3(0, 0, 0), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            if robot_objects['glow_2'] == nil then
                robot_objects['glow_2'] = Spawn.Object(2655881418)
                entity.set_entity_god_mode(robot_objects['glow_2'], true)
                entity.attach_entity_to_entity(robot_objects['glow_2'], robot_objects['spinning_1'], index, v3(2, -3, 3), v3(0, 0, 0), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            if robot_objects['glow_3'] == nil then
                robot_objects['glow_3'] = Spawn.Object(2655881418)
                entity.set_entity_god_mode(robot_objects['glow_3'], true)
                entity.attach_entity_to_entity(robot_objects['glow_3'], robot_objects['spinning_1'], index, v3(4, 0, 3), v3(0, 0, 0), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            if robot_objects['glow_4'] == nil then
                robot_objects['glow_4'] = Spawn.Object(2655881418)
                entity.set_entity_god_mode(robot_objects['glow_4'], true)
                entity.attach_entity_to_entity(robot_objects['glow_4'], robot_objects['spinning_1'], index, v3(-2, 3, 3), v3(0, 0, 0), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            if robot_objects['glow_5'] == nil then
                robot_objects['glow_5'] = Spawn.Object(2655881418)
                entity.set_entity_god_mode(robot_objects['glow_5'], true)
                entity.attach_entity_to_entity(robot_objects['glow_5'], robot_objects['spinning_1'], index, v3(-2, -3, 3), v3(0, 0, 0), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            if robot_objects['glow_6'] == nil then
                robot_objects['glow_6'] = Spawn.Object(2655881418)
                entity.set_entity_god_mode(robot_objects['glow_6'], true)
                entity.attach_entity_to_entity(robot_objects['glow_6'], robot_objects['spinning_1'], index, v3(-4, 0, 3), v3(0, 0, 0), true, Script.Feature['Robot Collision'].on, false, 2, true)
            end
            return HANDLER_CONTINUE
        end
        if not f.on then
        local delete_propulsion = {'spinning_1', 'glow_1', 'glow_2', 'glow_3', 'glow_4', 'glow_5', 'glow_6', 'spinning_middle', 'spinning_middle2', 'spinning_middle3' }
            for i = 1, #delete_propulsion do
                if robot_objects[delete_propulsion[i]] then
                    utility.clear({robot_objects[delete_propulsion[i]]})
                    robot_objects[delete_propulsion[i]] = nil
                end
            end
            return
        end
        settings['Rocket Propulsion'] = {Enabled = f.on}
    end)


    Script.Feature['Robot Equip Weapons'] = menu.add_feature('Equip Miniguns on hands', 'toggle', Script.Parent['Moveable Robot'].id, function(f)
        settings['Robot Equip Weapons'] = {Enabled = f.on}
        if f.on and robot_objects['lheadtrain'] and robot_objects['rheadtrain'] then
            if #entitys['robot_weapon_left'] == 0 and #entitys['robot_weapon_right'] == 0 then
                local toggle_preview = false
                if Script.Feature['Custom Vehicles Preview'].on then
                    toggle_preview = true
                    settings['Custom Vehicles Preview'] = {Enabled = false}
                end
                local toggle_spawn_in = false
                if Script.Feature['Spawn in Custom Vehicle'].on then
                    toggle_spawn_in = true
                    settings['Spawn in Custom Vehicle'] = {Enabled = false}
                end
                local data = customData.custom_vehicles[1][2]
                spawn_custom_vehicle(data, 'robot_weapon_left')
                spawn_custom_vehicle(data, 'robot_weapon_right')
                local w1 = entitys['robot_weapon_left'][1]
                local w2 = entitys['robot_weapon_right'][1]
                local a1 = robot_objects['lheadtrain']
                local a2 = robot_objects['rheadtrain']
                utility.request_ctrl(w1)
                utility.request_ctrl(w2)
                utility.request_ctrl(a1)
                utility.request_ctrl(a2)
                entity.attach_entity_to_entity(w1, a1, 0, v3(0, 5, 0), v3(), true, Script.Feature['Robot Collision'].on, false, 2, true)
                entity.attach_entity_to_entity(w2, a2, 0, v3(0, 5, 0), v3(), true, Script.Feature['Robot Collision'].on, false, 2, true)
                if toggle_preview then
                    Script.Feature['Custom Vehicles Preview'].on = true
                end
                if toggle_spawn_in then
                    Script.Feature['Spawn in Custom Vehicle'].on = true
                end
            end
            return HANDLER_CONTINUE
        end
        if not f.on then
            if #entitys['robot_weapon_left'] ~= 0 then
                utility.clear(entitys['robot_weapon_left'])
                entitys['robot_weapon_left'] = {}
            end
            if #entitys['robot_weapon_right'] ~= 0 then
                utility.clear(entitys['robot_weapon_right'])
                entitys['robot_weapon_right'] = {}
            end
            return
        end
    end)


    Script.Feature['Drive Robot'] = menu.add_feature('Drive Robot', 'action', Script.Parent['Moveable Robot'].id, function()
        if robot_objects['tampa'] then
            ped.set_ped_into_vehicle(get.OwnPed(), robot_objects['tampa'], -1)
        end
    end)


    Script.Feature['Self Destruction'] = menu.add_feature('Self Destruction', 'action', Script.Parent['Moveable Robot'].id, function()
        if robot_objects['tampa'] then
            for i = 1, #entitys['robot_weapon_left'] do
                entity.detach_entity(entitys['robot_weapon_left'][i])
                entity.freeze_entity(entitys['robot_weapon_left'][i], false)
                entity.set_entity_god_mode(entitys['robot_weapon_left'][i], false)
                coroutine.yield(0)
            end
            for i = 1, #entitys['robot_weapon_right'] do
                entity.detach_entity(entitys['robot_weapon_right'][i])
                entity.freeze_entity(entitys['robot_weapon_right'][i], false)
                entity.set_entity_god_mode(entitys['robot_weapon_right'][i], false)
                coroutine.yield(0)
            end
            for i in pairs(robot_objects) do
                entity.detach_entity(robot_objects[i])
                entity.freeze_entity(robot_objects[i], false)
                entity.set_entity_god_mode(robot_objects[i], false)
                coroutine.yield(0)
            end
            for i = 1, #entitys['robot_weapon_left'] do
                fire.add_explosion(entity.get_entity_coords(entitys['robot_weapon_left'][i]), 8, true, false, 0, 0)
                coroutine.yield(33)
            end
            for i = 1, #entitys['robot_weapon_right'] do
                fire.add_explosion(entity.get_entity_coords(entitys['robot_weapon_right'][i]), 8, true, false, 0, 0)
                coroutine.yield(33)
            end
            for i in pairs(robot_objects) do
                fire.add_explosion(entity.get_entity_coords(robot_objects[i]), 8, true, false, 0, 0)
                coroutine.yield(33)
             end
            entitys['robot_weapon_left'] = {}
            entitys['robot_weapon_right'] = {}
            robot_objects = {}
            Script.Feature['Enable Robot'].on = false
        end
    end)


    Script.Parent['Custom Vehicles Spawner'] = menu.add_feature('Custom Vehicles', 'parent', Script.Parent['Custom Vehicles'].id, nil)


    Script.Feature['Custom Vehicles Preview'] = menu.add_feature('Preview Custom Vehicles', 'toggle', Script.Parent['Custom Vehicles Spawner'].id, function(f)
            if #entitys['preview_veh'] > 0 and f.on then
                if ped.is_ped_in_any_vehicle(get.OwnPed()) then
                    ped.clear_ped_tasks_immediately(get.OwnPed())
                end
                local pos = get.OwnCoords()
                if not config_preview then
                    for i = 1, #entitys['preview_veh'] do
                        entity.set_entity_no_collsion_entity(entitys['preview_veh'][i], get.OwnPed(), true)
                    end
                    config_preview = true
                end
                pos.z = pos.z + offset_height
                local heading = get.OwnHeading()
                pos = utility.OffsetCoords(pos, heading, offset_distance)
                utility.set_coords(entitys['preview_veh'][1], pos)
                entity.set_entity_rotation(entitys['preview_veh'][1], rot_veh)
                rot_veh.z = rot_veh.z + 1
                if rot_veh.z > 360 then
                    rot_veh.z = 0
                end
                return HANDLER_CONTINUE
            end
            if not f.on then
                utility.clear(entitys['preview_veh'])
                entitys['preview_veh'] = {}
                config_preview = false
                return
            end
    end)


    menu.add_feature('Delete Custom Vehicles', 'action', Script.Parent['Custom Vehicles Spawner'].id, function()
        Log('Clearing Custom Vehicles.')
        utility.clear(entitys['Custom Vehicles'])
        entitys['Custom Vehicles'] = {}
        utility.clear(entitys['preview_veh'])
        entitys['preview_veh'] = {}
        config_preview = false
        Notify('Cleared Custom Vehicles.', "Success")
    end)


    for i = 1, #customData.custom_vehicles do
        menu.add_feature(customData.custom_vehicles[i][1], 'action', Script.Parent['Custom Vehicles Spawner'].id, function()
            local data = customData.custom_vehicles[i][2]
            spawn_custom_vehicle(data)
        end)
    end


    Script.Parent['Custom Vehicles Options'] = menu.add_feature('Options', 'parent', Script.Parent['Custom Vehicles'].id, nil)


    Script.Feature['Spawn in Custom Vehicle'] = menu.add_feature('Spawn in Custom Vehicle', 'toggle', Script.Parent['Custom Vehicles Options'].id, function(f)
        settings['Spawn in Custom Vehicle'] = {Enabled = f.on}
    end)


    Script.Feature['Use Own Vehicles'] = menu.add_feature('Use Own Vehicle for Custom ones', 'toggle', Script.Parent['Custom Vehicles Options'].id, function(f)
        settings['Use Own Vehicles'] = {Enabled = f.on}
    end)


    Script.Feature['Custom Vehicles Godmode'] = menu.add_feature('Godmode on Custom Vehicles', 'toggle', Script.Parent['Custom Vehicles Options'].id, function(f)
        settings['Custom Vehicles Godmode'] = {Enabled = f.on}
    end)


    Script.Parent['Block Areas'] = menu.add_feature('Block Areas', 'parent', Script.Parent['local_lobby'].id, nil)


    Script.Feature['Teleport to Block'] = menu.add_feature('Teleport to Block', 'toggle', Script.Parent['Block Areas'].id, function(f)
        settings['Teleport to Block'] = {Enabled = f.on}
    end)
    

    Script.Feature['Clear blocking Objects'] = menu.add_feature('Clear blocking Objects', 'action', Script.Parent['Block Areas'].id, function()
        utility.clear(entitys['bl_objects'])
        entitys['bl_objects'] = {}
    end)


    for i=1,#customData.block_locations do
        local location = customData.block_locations[i]
        local parent = menu.add_feature(location.Name, "parent", Script.Parent['Block Areas'].id)
        
        for j=1,#location.Children do
            local area = location.Children[j]
            
            menu.add_feature(area.Name, "action", parent.id, BlockArea).data = area
        end
    end



    Script.Parent['Lobby Trolling'] = menu.add_feature('Trolling', 'parent', Script.Parent['local_lobby'].id, nil)

    
    Script.Feature['Lobby Fake Typing Indicator'] = menu.add_feature('Fake Typing Indicator', 'toggle', Script.Parent['Lobby Trolling'].id, function(f)
        while f.on do
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                    scriptevent.Send('Typing Begin', {Self(), 0, math.random(0, 10000)}, id)
                end

            end

            coroutine.yield(2000)
        end

        for id = 0, 31 do
            if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                scriptevent.Send('Typing Stop', {Self(), 0, math.random(0, 10000)}, id)
            end

        end

    end)


    Script.Parent['Lobby Notifications'] = menu.add_feature('Notifications', 'parent', Script.Parent['Lobby Trolling'].id, nil)


    Script.Feature['Lobby Job Notification'] = menu.add_feature('Job Notification: Input', 'action', Script.Parent['Lobby Notifications'].id, function(f, id)
        local jobname = get.Input('Enter Job Name', 100)

        if not jobname then
            Notify('Input canceled.', "Error", '')
            return
        end

        local Table = utils.str_to_vecu64(jobname)
        local newTable = {Self()}

        for i = 1, #Table do
            newTable[i + 1] = Table[i]
        end

        for id = 0, 31 do
            if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                scriptevent.Send('Job Join Notification', newTable, id)
            end

        end
    end)

    
    Script.Feature['Lobby Cash Removed'] = menu.add_feature('Cash Removed', 'action_value_str', Script.Parent['Lobby Notifications'].id, function(f)
        
        if f.value == 0 then
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                    scriptevent._notification(id, 1, math.random(1, 100000))
                end

            end
            
            return
        end

        local amount = get.Input('Enter The Amount Of Money (0 - 2147483647)', 10, 3)
        if not amount then
            Notify('Input canceled.', "Error", '')
            return
        end

        for id = 0, 31 do
            if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                scriptevent._notification(id, 1, amount)
            end

        end
    end)
    Script.Feature['Lobby Cash Removed']:set_str_data({'Random Amount', 'Input'})

    
    Script.Feature['Lobby Cash Stolen'] = menu.add_feature('Cash Stolen', 'action_value_str', Script.Parent['Lobby Notifications'].id, function(f)
        if f.value == 0 then
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                    scriptevent._notification(id, 2, math.random(1, 100000))
                end

            end

            return
        end

        local amount = get.Input('Enter The Amount Of Money (0 - 2147483647)', 10, 3)
        if not amount then
            Notify('Input canceled.', "Error", '')
            return
        end

        for id = 0, 31 do
            if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                scriptevent._notification(id, 2, amount)
            end

        end
    end)
    Script.Feature['Lobby Cash Stolen']:set_str_data({'Random Amount', 'Input'})

    
    Script.Feature['Lobby Cash Banked'] = menu.add_feature('Cash Banked', 'action_value_str', Script.Parent['Lobby Notifications'].id, function(f)
        if f.value == 0 then
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                    scriptevent._notification(id, 3, math.random(1, 100000))
                end

            end

            return
        end

        local amount = get.Input('Enter The Amount Of Money (0 - 2147483647)', 10, 3)
        if not amount then
            Notify('Input canceled.', "Error", '')
            return
        end

        for id = 0, 31 do
            if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                scriptevent._notification(id, 3, amount)
            end

        end
    end)
    Script.Feature['Lobby Cash Banked']:set_str_data({'Random Amount', 'Input'})

    
    Script.Feature['Lobby Insurance Notification'] = menu.add_feature('Insurance Notification', 'action_value_str', Script.Parent['Lobby Notifications'].id, function(f)
        if f.value == 0 then
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                    scriptevent.Send('Insurance Notification', {Self(), math.random(1, 20000)}, id)
                end

            end

            return
        end

        local amount = get.Input('Enter The Amount Of Money (0 - 2147483647)', 10, 3)
        if not amount then
            Notify('Input canceled.', "Error", '')
            return
        end

        for id = 0, 31 do
            if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                scriptevent.Send('Insurance Notification', {Self(), amount}, id)
            end

        end
    end)
    Script.Feature['Lobby Insurance Notification']:set_str_data({'Random Amount', 'Input'})

    
    Script.Feature['Lobby Notification Spam'] = menu.add_feature('Notification Spam', 'toggle', Script.Parent['Lobby Notifications'].id, function(f)
        while f.on do
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                    scriptevent._notification(id, 1, math.random(1, 100000))
                    scriptevent._notification(id, 2, math.random(1, 100000))
                    scriptevent._notification(id, 3, math.random(1, 100000))
                end

                coroutine.yield(0)
            end

            coroutine.yield(200)
        end
    end)


    Script.Parent['Lobby Teleports'] = menu.add_feature('Teleports', 'parent', Script.Parent['Lobby Trolling'].id, nil)


    Script.Feature['Lobby Random Apartment Invite'] = menu.add_feature('Random Apartment Invite', 'action', Script.Parent['Lobby Teleports'].id, function()
        for id = 0, 31 do
            if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                scriptevent.Send('Apartment Invite', {Self(), id, 4294967295, 1, math.random(1, 114), 0, 0, 0}, id)
            end

        end
    end)

    
    Script.Feature['Lobby Apartment Invite Loop'] = menu.add_feature('Apartment Invite Loop', 'toggle', Script.Parent['Lobby Teleports'].id, function(f)
        while f.on do
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                    scriptevent.Send('Apartment Invite', {Self(), id, 4294967295, 1, math.random(1, 114), 0, 0, 0}, id)
                end

            end

            coroutine.yield(500)
        end
    end)

    
    Script.Feature['Lobby Warehouse Invite'] = menu.add_feature('Warehouse Invite', 'action_value_str', Script.Parent['Lobby Teleports'].id, function(f, id)
        if f.value == 22 then
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                    scriptevent.Send('Warehouse Invite', {Self(), 0, 1, math.random(1, 22)}, id)
                end
                
            end

            return
        end

        for id = 0, 31 do
            if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                scriptevent.Send('Warehouse Invite', {Self(), 0, 1, f.value + 1}, id)
            end

        end
    end)
	Script.Feature['Lobby Warehouse Invite']:set_str_data({
    'Elysian Island North',
    'La Puerta North',
    'La Mesa Mid',
    'Rancho West',
    'West Vinewood',
    'LSIA North',
    'Del Perro',
    'LSIA South',
    'Elysian Island South',
    'El Burro Heights',
    'Elysian Island West',
    'Textile City',
    'La Puerta South',
    'Strawberry',
    'Downtown Vinewood North',
    'La Mesa South',
    'La Mesa North',
    'Cypress Flats North',
    'Cypress Flats South',
    'West Vinewood West',
    'Rancho East',
    'Banning',
    'Random'
    })

    
    Script.Feature['Lobby Warehouse Invite Loop'] = menu.add_feature('Warehouse Invite Loop', 'toggle', Script.Parent['Lobby Teleports'].id, function(f, id)
        while f.on do
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                    scriptevent.Send('Warehouse Invite', {Self(), 0, 1, math.random(1, 22)}, id)
                end

            end

            coroutine.yield(500)
        end
    end)


    --[[
    Script.Feature['Lobby Force Island'] = menu.add_feature('Send to Cayo Perico', 'action', Script.Parent['Lobby Teleports'].id, function()
        for id = 0, 31 do
            if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                scriptevent.Send('Force To Island', {Self(), 1}, id)
            end

        end
    end)


    Script.Feature['Lobby Force Island 2'] = menu.add_feature('Send to Cayo Perico v2', 'action_value_str', Script.Parent['Lobby Teleports'].id, function(f)
        for id = 0, 31 do
            if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                if f.value == 0 then
                    scriptevent.Send('Force To Island 2', {Self(), 0, 0, 3, 1}, id)

                elseif f.value == 1 then
                    scriptevent.Send('Force To Island 2', {Self(), 0, 0, 4, 1}, id)

                elseif f.value == 2 then
                    scriptevent.Send('Force To Island 2', {Self(), 0, 0, 3, 0}, id)

                elseif f.value == 3 then
                    scriptevent.Send('Force To Island 2', {Self(), 0, 0, 4, 0}, id)
                end
            end
        end
    end)
    Script.Feature['Lobby Force Island 2']:set_str_data({'Via Plane', 'Instant', 'Back Home', 'Kicked Out'})
    ]]


    Script.Feature['Lobby Force Mission'] = menu.add_feature("Force to Mission", "action_value_str", Script.Parent['Lobby Teleports'].id, function(f)
        for id = 0, 31 do
            if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                scriptevent.Send('Force To Mission', {Self(), f.value}, id)
            end
        end
    end)
	Script.Feature['Lobby Force Mission']:set_str_data({'Severe Weather Patterns', 'Half-track Bully', 'Exit Strategy', 'Offshore Assets', 'Cover Blown', 'Mole Hunt', 'Data Breach', 'Work Dispute'})


    Script.Parent['Sound Spam'] = menu.add_feature('Sound Spam', 'parent', Script.Parent['Lobby Trolling'].id, nil)

    
    Script.Feature['Sound Spam Speed'] = menu.add_feature('Spam Speed', 'autoaction_slider', Script.Parent['Sound Spam'].id, function(f)
        settings['Sound Spam Speed'] = {Value = f.value}
    end)
    Script.Feature['Sound Spam Speed'].min = 0
    Script.Feature['Sound Spam Speed'].max = 10000
    Script.Feature['Sound Spam Speed'].mod = 250

    
    Script.Feature['Sound Rape 1'] = menu.add_feature('Sound Rape', 'toggle', Script.Parent['Sound Spam'].id, function(f)
        while f.on do
            audio.play_sound_from_coord(-1, '07', v3(75, 2000, 150), 'DLC_GR_CS2_Sounds', true, 10000, false)
            coroutine.yield(10000 - math.floor(Script.Feature['Sound Spam Speed'].value))
        end
    end)

    
    Script.Feature['Sound Short Transition In'] = menu.add_feature('Short Transition In', 'toggle', Script.Parent['Sound Spam'].id, function(f)
        while f.on do
            audio.play_sound_from_coord(-1, 'Short_Transition_In', v3(75, 2000, 150), 'PLAYER_SWITCH_CUSTOM_SOUNDSET', true, 10000, false)
            coroutine.yield(10000 - math.floor(Script.Feature['Sound Spam Speed'].value))
        end
    end)

    
    Script.Feature['Sound 1st Person Transition'] = menu.add_feature('1st Person Transition', 'toggle', Script.Parent['Sound Spam'].id, function(f)
        while f.on do
            audio.play_sound_from_coord(-1, '1st_Person_Transition', v3(75, 2000, 150), 'PLAYER_SWITCH_CUSTOM_SOUNDSET', true, 10000, false)
            coroutine.yield(10000 - math.floor(Script.Feature['Sound Spam Speed'].value))
        end
    end)

    
    Script.Feature['Sound Mission Pass Notify'] = menu.add_feature('Mission Pass Notify', 'toggle', Script.Parent['Sound Spam'].id, function(f)
        while f.on do
            audio.play_sound_from_coord(-1, 'Mission_Pass_Notify', v3(75, 2000, 150), 'DLC_HEISTS_GENERAL_FRONTEND_SOUNDS', true, 10000, false)
            coroutine.yield(10000 - math.floor(Script.Feature['Sound Spam Speed'].value))
        end
    end)

    
    Script.Feature['Sound MP Impact'] = menu.add_feature('MP Impact', 'toggle', Script.Parent['Sound Spam'].id, function(f)
        while f.on do
            audio.play_sound_from_coord(-1, 'MP_Impact', v3(75, 2000, 150), 'WastedSounds', true, 10000, false)
            coroutine.yield(10000 - math.floor(Script.Feature['Sound Spam Speed'].value))
        end
    end)

    
    Script.Feature['Sound Wasted'] = menu.add_feature('Wasted', 'toggle', Script.Parent['Sound Spam'].id, function(f)
        while f.on do
            audio.play_sound_from_coord(-1, 'Wasted', v3(75, 2000, 150), 'DLC_IE_VV_General_Sounds', true, 10000, false)
            coroutine.yield(10000 - math.floor(Script.Feature['Sound Spam Speed'].value))
        end
    end)

    
    Script.Feature['Sound Wasted 2'] = menu.add_feature('Wasted 2', 'toggle', Script.Parent['Sound Spam'].id, function(f)
        while f.on do
            audio.play_sound_from_coord(-1, 'Bed', v3(75, 2000, 150), 'WastedSounds', true, 10000, false)
            coroutine.yield(10000 - math.floor(Script.Feature['Sound Spam Speed'].value))
        end
    end)

    
    Script.Feature['Sound 10 Second Countdown'] = menu.add_feature('10 Second Countdown', 'toggle', Script.Parent['Sound Spam'].id, function(f)
        while f.on do
            audio.play_sound_from_coord(-1, '10s', v3(75, 2000, 150), 'MP_MISSION_COUNTDOWN_SOUNDSET', true, 10000, false)
            coroutine.yield(10000 - math.floor(Script.Feature['Sound Spam Speed'].value))
        end
    end)

    
    Script.Feature['Sound 5 Second Warning'] = menu.add_feature('5 Second Warning', 'toggle', Script.Parent['Sound Spam'].id, function(f)
        while f.on do
            audio.play_sound_from_coord(-1, '5_SEC_WARNING', v3(75, 2000, 150), 'HUD_MINI_GAME_SOUNDSET', true, 10000, false)
            coroutine.yield(10000 - math.floor(Script.Feature['Sound Spam Speed'].value))
        end
    end)

    
    Script.Feature['Sound 5 Second Event Start'] = menu.add_feature('5 Second Event Start Countdown', 'toggle', Script.Parent['Sound Spam'].id, function(f)
        while f.on do
            audio.play_sound_from_coord(-1, '5s_To_Event_Start_Countdown', v3(75, 2000, 150), 'GTAO_FM_Events_Soundset', true, 10000, false)
            coroutine.yield(10000 - math.floor(Script.Feature['Sound Spam Speed'].value))
        end
    end)
    
    
    Script.Feature['Sound Arming Countdown'] = menu.add_feature('Arming Countdown', 'toggle', Script.Parent['Sound Spam'].id, function(f)
        while f.on do
            audio.play_sound_from_coord(-1, 'Arming_Countdown', v3(75, 2000, 150), 'GTAO_Speed_Convoy_Soundset', true, 10000, false)
            coroutine.yield(10000 - math.floor(Script.Feature['Sound Spam Speed'].value))
        end
    end)

    
    Script.Feature['Sound Click Special'] = menu.add_feature('Click Special', 'toggle', Script.Parent['Sound Spam'].id, function(f)
        while f.on do
            audio.play_sound_from_coord(-1, 'Click_Special', v3(75, 2000, 150), 'WEB_NAVIGATION_SOUNDS_PHONE', true, 10000, false)
            coroutine.yield(10000 - math.floor(Script.Feature['Sound Spam Speed'].value))
        end
    end)

    
    Script.Feature['Sound Base Jump Passed'] = menu.add_feature('Base Jump Passed', 'toggle', Script.Parent['Sound Spam'].id, function(f)
        while f.on do
            audio.play_sound_from_coord(-1, 'BASE_JUMP_PASSED', v3(75, 2000, 150), 'HUD_AWARDS', true, 10000, false)
            coroutine.yield(10000 - math.floor(Script.Feature['Sound Spam Speed'].value))
        end
    end)

    
    Script.Feature['Sound Put Phone Away'] = menu.add_feature('Put Phone Away', 'toggle', Script.Parent['Sound Spam'].id, function(f)
        while f.on do
            audio.play_sound_from_coord(-1, 'Put_Away', v3(75, 2000, 150), 'Phone_SoundSet_Michael', true, 10000, false)
            coroutine.yield(10000 - math.floor(Script.Feature['Sound Spam Speed'].value))
        end
    end)

    
    Script.Feature['Sound Rank Up'] = menu.add_feature('Rank Up', 'toggle', Script.Parent['Sound Spam'].id, function(f)
        while f.on do
            audio.play_sound_from_coord(-1, 'RANK_UP', v3(75, 2000, 150), 'HUD_AWARDS', true, 10000, false)
            coroutine.yield(10000 - math.floor(Script.Feature['Sound Spam Speed'].value))
        end
    end)

    
    Script.Feature['Sound Waypoint Set'] = menu.add_feature('Waypoint Set', 'toggle', Script.Parent['Sound Spam'].id, function(f)
        while f.on do
            audio.play_sound_from_coord(-1, 'WAYPOINT_SET', v3(75, 2000, 150), 'HUD_FRONTEND_DEFAULT_SOUNDSET', true, 10000, false)
            coroutine.yield(10000 - math.floor(Script.Feature['Sound Spam Speed'].value))
        end
    end)

    
    Script.Feature['Sound Strong Wind'] = menu.add_feature('Strong Wind', 'toggle', Script.Parent['Sound Spam'].id, function(f)
        while f.on do
            audio.play_sound_from_coord(-1, 'Whoosh_1s_L_to_R', v3(75, 2000, 150), 'MP_LOBBY_SOUNDS', true, 10000, false)
            audio.play_sound_from_coord(-1, 'Whoosh_1s_R_to_L', v3(75, 2000, 150), 'MP_LOBBY_SOUNDS', true, 10000, false)
            coroutine.yield(10000 - math.floor(Script.Feature['Sound Spam Speed'].value))
        end
    end)

    
    Script.Feature['Sound Phone Ringing'] = menu.add_feature('Infinite Phone Ringing', 'action', Script.Parent['Sound Spam'].id, function(f)
        audio.play_sound_from_coord(-1, 'Remote_Ring', v3(75, 2000, 150), 'Phone_SoundSet_Michael', true, 10000, false)
    end)


    Script.Feature['Lobby Fake Invite'] = menu.add_feature('Fake Invite', 'action_value_str', Script.Parent['Lobby Trolling'].id, function(f)
        for id = 0, 31 do
            if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                scriptevent.Send('Fake Invite', {Self(), math.random(0, 190), miscdata.smslocations[f.value + 1]}, id)
            end

        end
    end)
    Script.Feature['Lobby Fake Invite']:set_str_data({
        'Business',
        'Vehicle Warehouse',
        'Bunker',
        'Mobile Operations Center',
        'Hangar',
        'Avenger',
        'Facility',
        'Nightclub',
        'Terrorbyte',
        'Arena Workshop',
        'Penthouse',
        'Arcade',
        'Kosatka',
        'Record A Studios',
        'Auto Shop',
        'LS Car Meet',
        'Agency',
        'Acid Lab',
        'The Freakshop',
        'Eclipse Blvd Garage',
        'ERROR'
    })

    
    Script.Feature['Lobby Fake Invite Spam'] = menu.add_feature('Fake Invite Spam', 'toggle', Script.Parent['Lobby Trolling'].id, function(f)
        while f.on do
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                    scriptevent.Send('Fake Invite', {Self(), math.random(0, 190), miscdata.smslocations[math.random(#miscdata.smslocations)]}, id)
                end

            end

            coroutine.yield(200)
        end
    end)

    
    Script.Feature['Lobby Script Freeze'] = menu.add_feature('Script Freeze', 'toggle', Script.Parent['Lobby Trolling'].id, function(f, id)
        while f.on do
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                    scriptevent.Send('Warehouse Invite', {Self(), 0, 1, 0}, id)
                end

            end

            coroutine.yield(500)
        end
    end)


    --[[
    Script.Feature['Lobby Start Cutscene'] = menu.add_feature('Start Casino Cutscene', 'action', Script.Parent['Lobby Trolling'].id, function()
        for id = 0, 31 do
            if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                scriptevent.Send('Casino Cutscene', {Self()}, id)
            end

        end
    end)
    ]]

    
    Script.Feature['Lobby Force Camera Forward'] = menu.add_feature('Force Camera Forward', 'toggle', Script.Parent['Lobby Trolling'].id, function(f)
        while f.on do
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                    scriptevent.Send('Camera Manipulation', {Self(), -970603040, 0}, id)
                end

            end

            coroutine.yield(200)
        end
    end)

    
    --[[
    Script.Feature['Lobby Transaction Error'] = menu.add_feature('Transaction Error', 'toggle', Script.Parent['Lobby Trolling'].id, function(f)
        while f.on do
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                    scriptevent.Send('Transaction Error', {Self(), 50000, 0, 1, scriptevent.MainGlobal(id), scriptevent.GlobalPair()}, id)
                end

            end
            
            coroutine.yield(1000)
        end
    end)
    ]]

    
    Script.Feature['Lobby Vehicle Kick'] = menu.add_feature('Vehicle Kick', 'action', Script.Parent['Lobby Trolling'].id, function()
        for id = 0, 31 do
            if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                scriptevent.Send('Vehicle Kick', {Self(), 4294967295, 4294967295, 4294967295}, id)
            end

        end
    end)


    Script.Feature['Disable Ability to Drive'] = menu.add_feature('Disable Ability to Drive', 'action', Script.Parent['Lobby Trolling'].id, function()
        for i = 0, 31 do
            if not player.is_player_valid(i) then
                for id = 0, 31 do
                    if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                        scriptevent.Send('Apartment Invite', {Self(), i, 4294967295, 1, 115, 0, 0, 0}, id)
                    end
                end

                return
            end

        end
    end)

    
    Script.Feature['Lobby Vehicle EMP'] = menu.add_feature('Vehicle EMP', 'action', Script.Parent['Lobby Trolling'].id, function()
        for id = 0, 31 do
            if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                local pos = get.PlayerCoords(id)
                scriptevent.Send('Vehicle EMP', {Self(), math.floor(pos.x), math.floor(pos.y), math.floor(pos.z), 0}, id)
            end

        end
    end)

    
    Script.Feature['Lobby Destroy Personal Vehicle'] = menu.add_feature('Destroy Personal Vehicle', 'action', Script.Parent['Lobby Trolling'].id, function()
        for id = 0, 31 do
            if scriptevent.GetPersonalVehicle(id) == 0 or not utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                goto continue
            end

            scriptevent.Send('Destroy Personal Vehicle', {Self(), id}, id)
            scriptevent.Send('Vehicle Kick', {Self(), 4294967295, 4294967295, 4294967295}, id)

            ::continue::
        end
    end)


    Script.Parent['Lobby Griefing'] = menu.add_feature('Griefing', 'parent', Script.Parent['local_lobby'].id, nil)

    
    Script.Feature['Explosion Blame'] = menu.add_feature('Player Blame', 'action_value_str', Script.Parent['Lobby Griefing'].id, function(f)
        if f.value == 0 then
            explosion_blame = 0
            Notify('Explosion Kills are now anonymous.', "Success", '')

        elseif f.value == 1 then
            explosion_blame = get.OwnPed()
            Notify('You are now earning the blame for any Explosion Kills.', "Success", '')

        elseif f.value == 2 then
            Notify('Explosion Kill blame is now random.', "Success", '')

        else
            local id = get.Input('Enter the Targets Player ID', 2, 3)
            if not id then
                Notify('Input canceled.', "Error", '')
                return
            end

            if not player.is_player_valid(id) then
                Notify('Invalid Player.', "Error", '')
                return
            end

            explosion_blame = get.PlayerPed(id)
            Notify('Now blaming ' .. get.Name(id) .. ' for any Kills.', "Success", '')  
        end
    end)
    Script.Feature['Explosion Blame']:set_str_data({'Anonymous', 'Self', 'Random', 'ID Input'})

    
    Script.Parent['Explosion Settings'] = menu.add_feature('Custom Explosion', 'parent', Script.Parent['Lobby Griefing'].id, nil)

    
    Script.Feature['Explosion Delay'] = menu.add_feature('Explosion Spam Speed', 'autoaction_slider', Script.Parent['Explosion Settings'].id, function(f)
        settings['Explosion Delay'] = {Value = f.value}
    end)
    Script.Feature['Explosion Delay'].min = 250
    Script.Feature['Explosion Delay'].max = 10000
    Script.Feature['Explosion Delay'].mod = 250

    
    Script.Feature['Explosion Invisibility'] = menu.add_feature('Invisible Explosions ', 'toggle', Script.Parent['Explosion Settings'].id, function(f)
        settings['Explosion Invisibility'] = {Enabled = f.on}
    end)

    
    Script.Feature['Explosion Silent'] = menu.add_feature('Silent Explosions', 'toggle', Script.Parent['Explosion Settings'].id, function(f)
        settings['Explosion Silent'] = {Enabled = f.on}
    end)

    
    Script.Feature['Explosion Camshake'] = menu.add_feature('Cam Shake Intensity', 'autoaction_value_i', Script.Parent['Explosion Settings'].id, function(f)
        settings['Explosion Camshake'] = {Value = f.value}
    end)
    Script.Feature['Explosion Camshake'].min = 0.00
    Script.Feature['Explosion Camshake'].max = 100.00
    Script.Feature['Explosion Camshake'].mod = 5.00
    
    
    Script.Feature['Explosion Custom'] = menu.add_feature('Explode Lobby', 'value_str', Script.Parent['Explosion Settings'].id, function(f)
        while f.on do
            local sounds =  true
            if Script.Feature['Explosion Silent'].on then
                sounds = false
            end

            local blame = explosion_blame

            for id = 0, 31 do
                if Script.Feature['Explosion Blame'].value == 2 then
                    local id = -1
                    while not utility.valid_player(id) do
                        id = math.random(0, 31)
                        coroutine.yield(0)
                    end
                    blame = get.PlayerPed(id)
                end

                if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                    fire.add_explosion(get.PlayerCoords(id), f.value, sounds, Script.Feature['Explosion Invisibility'].on, Script.Feature['Explosion Camshake'].value, blame)
                end

            end

            coroutine.yield(10000 -  math.floor(Script.Feature['Explosion Delay'].value))
        end
    end)
    Script.Feature['Explosion Custom']:set_str_data({
        'Grenade',
        'Grenade Launcher',
        'Stickybomb',
        'Molotov',
        'Rocket',
        'Tankshell',
        'Octane',
        'Car',
        'Plane',
        'Petrol Pump',
        'Bike',
        'Water',
        'Flame',
        'Water Hydrant',
        'Flame Canister',
        'Boat',
        'Ship Destroy',
        'Truck',
        'Bullet',
        'Smoke Launcher',
        'Smoke Grenade',
        'BZ Gas',
        'Flase',
        'Gas Canister 2',
        'Extinguisher',
        'Programmable AR',
        'Train',
        'Barrel',
        'Propane',
        'Blimp',
        'Flame 2',
        'Tanker',
        'Plane Rocket',
        'Vehicle Bullet',
        'Gas Tank',
        'Bird Crap',
        'Railgun',
        'Blimp 2',
        'Firework',
        'Snowball',
        'Proxmine',
        'Valkyrie Cannon',
        'Air Defence',
        'Pipe Bomb',
        'Vehicle Mine',
        'Explosive Ammo',
        'APC Shell',
        'Bomb Cluster',
        'Bomb Gas',
        'Bomb Incendiary',
        'Bomb Standard',
        'Torpedo',
        'Torpedo Underwater',
        'Bombushka Canon',
        'Bomb Cluster Secondary',
        'Hunter Barrage',
        'Hunter Cannon',
        'Rogue Cannon',
        'Mine Underwater',
        'Orbital Canon',
        'Bomb Std Wide',
        'Explosive Shotgun',
        'Oppressor MK II Cannon',
        'Mortar Kinetic',
        'Vehicle Mine Kinetic',
        'Vehicle Mine EMP',
        'Vehicle Mine Spike',
        'Vehicle Mine Slick',
        'Vehicle Mine Tar',
        'Script Drone',
        'Up-n-Atomizer',
        'Buried Mine',
        'Script Missile',
        'RC Tank Rocket',
        'Bomb Water',
        'Bomb Water Secondary',
        'Extinguisher 2',
        'Extinguisher 3',
        'Extinguisher 4',
        'Extinguisher 5',
        'Extinguisher 6',
        'Script Missile Large',
        'Submarine Big',
        'EMP',
    })


    local lobbyexplosions = {
        {Name = 'Explode Lobby', Type = 27, Camshake = 1},
        {Name = 'Set Lobby on Fire', Type = 14, Camshake = 0},
        {Name = 'Orbital Cannon Spam', Type = 59, Camshake = 10},
        {Name = 'Water Hydrant Spam', Type = 13, Camshake = 0}
    }


    for i = 1, #lobbyexplosions do
        local Name = lobbyexplosions[i].Name
        local Type = lobbyexplosions[i].Type
        local Camshake = lobbyexplosions[i].Camshake

        Script.Feature[Name] = menu.add_feature(Name, 'toggle', Script.Parent['Lobby Griefing'].id, function(f)
            local blame = explosion_blame
    
            if Script.Feature['Explosion Blame'].value == 2 then
                local id = -1
                while not utility.valid_player(id) do
                    id = math.random(0, 31)
                    coroutine.yield(0)
                end
    
                blame = get.PlayerPed(id)
            end
    
            while f.on do
                for id = 0, 31 do
                    if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                        fire.add_explosion(get.PlayerCoords(id), Type, true, false, Camshake, blame)
    
                    end
    
                end
    
                coroutine.yield(500)
            end

        end)
    end


    Script.Feature['Freeze Lobby'] = menu.add_feature('Freeze Lobby', 'toggle', Script.Parent['Lobby Griefing'].id, function(f)
        while f.on do
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                    ped.clear_ped_tasks_immediately(get.PlayerPed(id))
                end

            end

            coroutine.yield(0)
        end
    end)


    Script.Feature['Lobby Infinite Apartment Invite'] = menu.add_feature('Infinite Loading Screen', 'action_value_str', Script.Parent['Lobby Griefing'].id, function(f)
        if f.value == 0 then
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                    scriptevent.Send('Apartment Invite', {Self(), id, 4294967295, 1, 115, 0, 0, 0}, id)
                end

            end

        else
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                    scriptevent.Send('Force on Death Bike', {Self(), 1, 32, network.network_hash_from_player(id), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1}, id)
                end

            end
            
        end
    end)
    Script.Feature['Lobby Infinite Apartment Invite']:set_str_data({'v1', 'v2'})
    

    Script.Feature['CEO Kick'] = menu.add_feature("CEO Kick", "action", Script.Parent['Lobby Griefing'].id, function(f)
        for id = 0, 31 do
            if utility.valid_player(id, IsFeatOn('Exclude Friends')) and scriptevent.IsPlayerAssociate(id) then
                scriptevent.Send('CEO Kick', {Self(), 1, 5}, id)
            end
            
        end
    end)


    Script.Feature['Lobby Set Bounty'] = menu.add_feature("Set Bounty: Input", "action_value_str", Script.Parent['Lobby Griefing'].id, function(f)
        local amount = tonumber(get.Input('Enter Bounty Value (0 - 10000)', 5, 3, "10000"))
        if not amount then
            Notify('Input canceled.', "Error", '')
            return
        end

        if amount > 10000 or amount < 0 then
            Notify('Value must be between 0 and 10000.', "Error", '')
            return
        end

        for id = 0, 31 do
            if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                scriptevent.Send('Bounty', {Self(), id, 1, amount, 0, f.value,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, scriptevent.GlobalPair()}, script.get_host_of_this_script())
            end
        end
    end)
	Script.Feature['Lobby Set Bounty']:set_str_data({"Named", "Anonymous"})

    
    Script.Feature['Lobby Bounty After Death'] = menu.add_feature("Reapply Bounty after Death", "value_str", Script.Parent['Lobby Griefing'].id, function(f)
        local bounty_value = get.Input('Enter Bounty Value (0 - 10000)', 5, 3, "10000")
        if not bounty_value then
            Notify('Input canceled.', "Error", '')
            f.on = false
            return
        end

        if tonumber(bounty_value) > 10000 then
            Notify('Value cannot be more than 10000.', "Error", '')
            f.on = false
            return
        end

        local threads = {}
        while f.on do
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) and entity.is_entity_dead(get.PlayerPed(id)) then
                    if not threads[id] or menu.has_thread_finished(threads[id]) then
                        threads[id] = menu.create_thread(function(target)
                            Notify(get.Name(target) .. ' is dead.\nReapplying bounty...', "Neutral")
                            Log(get.Name(target) .. ' is dead.\nReapplying bounty...')
        
                            scriptevent.Send('Bounty', {Self(), target, 1, bounty_value, 0, f.value,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, scriptevent.GlobalPair()}, script.get_host_of_this_script())
                            while player.get_player_health(target) == 0 do
                                coroutine.yield(0)
                            end
                        end, id)
                    end

                end

            end

            coroutine.yield(0)
        end
    end)
	Script.Feature['Lobby Bounty After Death']:set_str_data({"Named", "Anonymous"})

    
    Script.Feature['Lobby Passive Mode'] = menu.add_feature("Block Passive Mode", "toggle", Script.Parent['Lobby Griefing'].id, function(f)
        while f.on do
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                    scriptevent.Send('Passive Mode', {Self(), 1}, id)
                end

            end

            coroutine.yield(200)
        end

        for id = 0, 31 do
            if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                scriptevent.Send('Passive Mode', {Self(), 0}, id)
            end
        end
    end)


    Script.Parent['Lobby Friendly'] = menu.add_feature('Friendly', 'parent', Script.Parent['local_lobby'].id, nil)

    if settings['Enable Vehicle Spawner'].Enabled then
        Script.Parent['Lobby Spawn Vehicles'] = menu.add_feature('Spawn Vehicles', 'parent', Script.Parent['Lobby Friendly'].id, nil)

        Script.Parent['Lobby Spawn Vehicle Settings'] = menu.add_feature('Spawn Settings', 'parent', Script.Parent['Lobby Spawn Vehicles'].id, nil)

        Script.Feature['Lobby Spawn Vehicle Upgraded'] = menu.add_feature('Upgraded', 'value_str', Script.Parent['Lobby Spawn Vehicle Settings'].id, function(f)
            settings['Lobby Spawn Vehicle Upgraded'] = {Enabled = f.on, Value = f.value}
        end)
        Script.Feature['Lobby Spawn Vehicle Upgraded']:set_str_data({'Max', 'Performance'})

        Script.Feature['Lobby Spawn Vehicle Godmode'] = menu.add_feature('Godmode', 'toggle', Script.Parent['Lobby Spawn Vehicle Settings'].id, function(f)
            settings['Lobby Spawn Vehicle Godmode'] = {Enabled = f.on}
        end)

        Script.Feature['Lobby Spawn Vehicle Lockon'] = menu.add_feature('Lock-on Disabled', 'toggle', Script.Parent['Lobby Spawn Vehicle Settings'].id, function(f)
            settings['Lobby Spawn Vehicle Lockon'] = {Enabled = f.on}
        end)

        Script.Feature['Spawn Vehicle for All'] = menu.add_feature('Model/Hash Input', 'action', Script.Parent['Lobby Spawn Vehicles'].id, function()
            local _input = get.Input("Enter Vehicle Name, Model Name or Hash")
            if not _input then
                Notify('Input canceled.', "Error", '')
                return
            end

            local hash = _input
            if not tonumber(_input) then
                if mapper.veh.GetHashFromName(_input) ~= nil then
                    hash = mapper.veh.GetHashFromName(_input)
                else
                    hash = gameplay.get_hash_key(_input)
                end
            end

            if not streaming.is_model_a_vehicle(hash) then
                Notify('Input is not a valid vehicle.', "Error", '')
                return
            end

            for id = 0, 31 do
                if player.is_player_valid(id) and id ~= Self() and not get.GodmodeState(id) then
                    local pos = get.PlayerCoords(id)
                    pos.z = Math.GetGroundZ(pos.x, pos.y)

                    local veh = Spawn.Vehicle(hash, utility.OffsetCoords(pos, get.PlayerHeading(id), 10))

                    if not veh then
                        Notify('Failed to spawn vehicle for player ' .. get.Name(id), 'Error', 'Vehicle Spawner')
                    
                    else
                        utility.request_ctrl(veh)
                        decorator.decor_set_int(veh, 'MPBitset', 1 << 10)
    
                        if Script.Feature['Lobby Spawn Vehicle Upgraded'].on then
                            utility.MaxVehicle(veh, Script.Feature['Lobby Spawn Vehicle Upgraded'].value + 1)
                        end
    
                        if Script.Feature['Lobby Spawn Vehicle Godmode'].on then
                            entity.set_entity_god_mode(veh, true)
                        end
    
                        if Script.Feature['Lobby Spawn Vehicle Lockon'].on then
                            vehicle.set_vehicle_can_be_locked_on(veh, false, false)
                        end
                    end
                end
            end
        end)
    end


    Script.Parent['Lobby CEO Money'] = menu.add_feature('CEO Money', 'parent', Script.Parent['Lobby Friendly'].id, function()
        if not Script.Feature['Disable Warning Messages'].on then
            Notify('Only Players who are an associate in any Organisation will receive the Money.\nEnabling multiple Loops at once can cause Transaction Errors.', "Neutral")
            coroutine.yield(5000)
        end
    end)

    Script.Feature['Lobby CEO Loop Preset'] = menu.add_feature('Preset', 'toggle', Script.Parent['Lobby CEO Money'].id, function(f)
        menu.create_thread(function()
            while f.on do
                for id = 0, 31 do
                    if utility.valid_player(id, false) and scriptevent.IsPlayerAssociate(id) then
                        scriptevent.Send('CEO Money', {Self(), 10000, -1292453789, 1, scriptevent.MainGlobal(id), scriptevent.GlobalPair()}, id)
                    end

                end

                coroutine.yield(40000)
            end
        end, nil)
    
        coroutine.yield(5000)
        while f.on do
            for id = 0, 31 do
                if utility.valid_player(id, false) and scriptevent.IsPlayerAssociate(id) then
                    scriptevent.Send('CEO Money', {Self(), 30000, 198210293, 1, scriptevent.MainGlobal(id), scriptevent.GlobalPair()}, id)
                end

            end
    
            coroutine.yield(150000)
        end
    end)

    for i = 1, #miscdata.ceomoney do
        Script.Feature['Lobby CEO Loop ' .. i] = menu.add_feature(miscdata.ceomoney[i][1] .. ' (ms)', 'value_i', Script.Parent['Lobby CEO Money'].id, function(f)
            settings['Lobby CEO Loop ' .. i] = {Value = f.value}
            while f.on do
                for id = 0, 31 do
                    if utility.valid_player(id, false) and scriptevent.IsPlayerAssociate(id) then
                        scriptevent.Send('CEO Money', {Self(), miscdata.ceomoney[i][2], miscdata.ceomoney[i][3], miscdata.ceomoney[i][4], scriptevent.MainGlobal(id), scriptevent.GlobalPair()}, id)
                    end

                end

                settings['Lobby CEO Loop ' .. i].Value = f.value
                coroutine.yield(f.value)
            end

        end)
        Script.Feature['Lobby CEO Loop ' .. i].min = 10000
        Script.Feature['Lobby CEO Loop ' .. i].max = 300000
        Script.Feature['Lobby CEO Loop ' .. i].mod = 10000
        Script.Feature['Lobby CEO Loop ' .. i].value = miscdata.ceomoney[i][5]
    end

    Script.Feature['Give Collectibles'] = menu.add_feature('Give Collectibles', 'action_value_str', Script.Parent['Lobby Friendly'].id, function(f)
        local data = {
            ["Movie Props"] = {ID = 0, Times = 9},
            ["Hidden Caches"] = {ID = 1, Times = 9},
            ["Treasure Chests"] = {ID = 2, Times = 1},
            ["Radio Antennas"] = {ID = 3, Times = 9},
            ["Media USBs"] = {ID = 4, Times = 19},
            ["Shipwreck"] = {ID = 5, Times = 0},
            ["Burried Stashes"] = {ID = 6, Times = 9},
            ["Halloween T-Shirt"] = {ID = 7, Times = 0},
            ["Jack O' Lanterns"] = {ID = 8, Times = 9},
            ["LD Organics Product"] = {ID = 9, Times = 99},
            ["Junk Energy Skydives"] = {ID = 10, Times = 9},
        }

        local selection =  data[f:get_str_data()[f.value + 1]]
        if selection.Times == 0 then
            for id = 0, 31 do
                if utility.valid_player(id, false) then
                    scriptevent.Send('Collectibles', {Self(), selection.ID, 0, 1, 1, 1}, id)
                end

                coroutine.yield(100)
            end

        else
            for id = 0, 31 do
                if utility.valid_player(id, false) then
                    for i = 0, selection.Times do
                        scriptevent.Send('Collectibles', {Self(), selection.ID, i, 1, 1, 1}, id)
        
                        if i == 25 or i == 50 or i == 75 then
                            coroutine.yield(10)
                        end

                    end

                    coroutine.yield(100)
                end

            end
            
        end
        
        Notify('Gave collectibles to lobby.', 'Success', 'Give Collectibles')
    end)
    Script.Feature['Give Collectibles']:set_str_data({'Movie Props', 'Hidden Caches', 'Treasure Chests', 'Radio Antennas', 'Media USBs', 'Shipwreck', 'Burried Stashes', 'Halloween T-Shirt', "Jack O' Lanterns", 'LD Organics Product', 'Junk Energy Skydives'})


    Script.Feature['RP Drop'] = menu.add_feature("RP Drop (Nearby)", "slider", Script.Parent['Lobby Friendly'].id, function(f)
        if not menu.is_trusted_mode_enabled(1 << 2) then
            Notify('Not available while trusted mode for natives is turned off', 'Error', 'RP Drop (Nearby)')
            f.on = false
            return
        end

        local hashes = {1298470051, 446117594, 1025210927, 437412629}

        while f.on do
            if not menu.is_trusted_mode_enabled(1 << 2) then
                f.on = false
            end

            local Hash = hashes[math.random(#hashes)]
            utility.request_model(Hash)

            local random = (math.random() + math.random(-80, 80)) / 100
            local ownpos = get.OwnCoords()

            for id = 0, 31 do
                if utility.valid_player(id, false) then
                    local pos = player.get_player_coords(id)
                    if ownpos:magnitude(pos) < 500 then
                        N.OBJECT.CREATE_AMBIENT_PICKUP(0x2C014CA6, pos + v3(random, random, 1), 0, 1, Hash, 0, 1)
                    end
                end
            end
    
            coroutine.yield(1000 - math.floor(f.value))
        end

        for i = 1, #hashes do
            streaming.set_model_as_no_longer_needed(hashes[i])
        end
    end)
    Script.Feature['RP Drop'].min = 0
    Script.Feature['RP Drop'].max = 1000
    Script.Feature['RP Drop'].mod = 100


    Script.Feature['Off The Radar'] = menu.add_feature('Off The Radar', 'value_str', Script.Parent['Lobby Friendly'].id, function(f)
        if f.value == 0 then
            for id = 0, 31 do
                if utility.valid_player(id, false) and not scriptevent.IsPlayerOTR(id) then
                    scriptevent.Send('Off The Radar', {Self(), utils.time() - 60, utils.time(), 1, 1, scriptevent.MainGlobal(id)}, id)
                end
    
            end

            f.on = false
        end

        while f.on do
            if f.value == 0 then
                f.on = false
            end
            
            for id = 0, 31 do
                if utility.valid_player(id, false) and not scriptevent.IsPlayerOTR(id) then
                    scriptevent.Send('Off The Radar', {Self(), utils.time() - 60, utils.time(), 1, 1, scriptevent.MainGlobal(id)}, id)
                end

            end

            coroutine.yield(500)
        end
    end)
    Script.Feature['Off The Radar']:set_str_data({'Once', 'Loop'})


    Script.Feature['Lobby Bribe Authorities'] = menu.add_feature('Bribe Authorities', 'toggle', Script.Parent['Lobby Friendly'].id, function(f)
        while f.on do
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                    scriptevent.Send('Bribe Authorities', {Self(), 0, 0, utils.time_ms(), 0, scriptevent.MainGlobal(id)}, id)
                end

            end

            coroutine.yield(500)
        end
    end)


    Script.Feature['Lobby Remove Wanted'] = menu.add_feature('Remove Wanted', 'toggle', Script.Parent['Lobby Friendly'].id, function(f)
        while f.on do
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) and player.get_player_wanted_level(id) > 0 then
                    scriptevent.Send('Remove Wanted', {Self(), scriptevent.MainGlobal(id)}, id)
                end

            end

            coroutine.yield(0)
        end
    end)


    Script.Parent['Chat Commands'] = menu.add_feature('Chat Commands', 'parent', Script.Parent['local_lobby'].id, nil)


    Script.Feature['Enable Commands'] = menu.add_feature('Enable Chat Commands', 'toggle', Script.Parent['Chat Commands'].id, function(f)
        settings['Enable Commands'] = {Enabled = f.on}
    end)


    Script.Feature['Block Friends as Target'] = menu.add_feature('Block Friends as Target', 'toggle', Script.Parent['Chat Commands'].id, function(f)
        settings['Block Friends as Target'] = {Enabled = f.on}
    end)


    Script.Parent['Command List'] = menu.add_feature('Command List', 'parent', Script.Parent['Chat Commands'].id, nil)


    for i = 1, #cmds do
        Script.Feature[cmds[i][1]] = menu.add_feature(cmds[i][2], 'value_str', Script.Parent['Command List'].id, function(f)
            settings[cmds[i][1]] = {Enabled = f.on, Value = f.value}
            while f.on do
                settings[cmds[i][1]].Value = f.value
                coroutine.yield(0)
            end
            settings[cmds[i][1]].Enabled = f.on
        end)
        Script.Feature[cmds[i][1]]:set_str_data({'All Players', 'Friends Only', 'Self Only'})
    end
     

    Script.Feature['Send Chat Commands'] = menu.add_feature('Notify Lobby', 'value_str', Script.Parent['Chat Commands'].id, function(f)
        while f.on do
            if not Script.Feature['Enable Commands'].on then
                Notify('Chat Commands are not enabled.', "Error", 'Notify Lobby')
                f.on = false
                return
            end

            local commands = ''
            for i = 1, #cmds do
                if Script.Feature[cmds[i][1]].on then
                    commands = commands .. cmds[i][2] .. '\n'
                end
            end

            if #commands == 0 then
                Notify('No active Commands.', "Error", '')
                f.on = false
                return
            end

            network.send_chat_message('Active Chat Commands for this Session:\n' .. commands, false)

            if f.value == 0 then
                f.on = false
                return
            end

            coroutine.yield(300000)

            if f.value == 0 then
                f.on = false
                return
            end
        end
    end)
    Script.Feature['Send Chat Commands']:set_str_data({'Once', 'Every 5 Min'})


    Script.Parent['Chat Spam'] = menu.add_feature('Chat Spam', 'parent', Script.Parent['local_lobby'].id, nil)


    Script.Feature['Disable Chat'] = menu.add_feature('Disable Chat via Spam', 'toggle', Script.Parent['Chat Spam'].id, function(f)
        while f.on do
            network.send_chat_message(' ', false)
            coroutine.yield(0)
        end
    end)


    Script.Feature['Chat Spam Delay'] = menu.add_feature('Spam Speed', 'autoaction_slider', Script.Parent['Chat Spam'].id, function(f)
        settings['Chat Spam Delay'] = {Value = f.value}
    end)
    Script.Feature['Chat Spam Delay'].min = 250
    Script.Feature['Chat Spam Delay'].max = 10000
    Script.Feature['Chat Spam Delay'].mod = 250


    Script.Feature['Chat Spamer'] = menu.add_feature('Chat Spam', 'toggle', Script.Parent['Chat Spam'].id, function(f)
        local msg = get.Input('Enter message to spam', 250)
        if not msg then
            Notify('Input canceled.', "Error", '')
            f.on = false
            return
        end

        while f.on do
            network.send_chat_message(msg, false)

            coroutine.yield(10000 - math.floor(Script.Feature['Chat Spam Delay'].value))
        end
    end)


    Script.Feature['Spam Text from Clipboard'] = menu.add_feature('Spam Text from Clipboard', 'toggle', Script.Parent['Chat Spam'].id, function(f)
        while f.on do
            network.send_chat_message(utils.from_clipboard(), false)
            coroutine.yield(10000 - math.floor(Script.Feature['Chat Spam Delay'].value))
        end
    end)


    Script.Feature['Send Text from Clipboard'] = menu.add_feature('Paste Text from Clipboard', 'action', Script.Parent['Chat Spam'].id, function()
        network.send_chat_message(utils.from_clipboard(), false)
    end)


    Script.Feature['Echo Chat'] = menu.add_feature('Echo Chat X times', 'value_i', Script.Parent['Chat Spam'].id, function(f)
        settings['Echo Chat'] = {Enabled = f.on, Value = f.value}
    end)
    Script.Feature['Echo Chat'].min = 1
    Script.Feature['Echo Chat'].max = 10


    Script.Parent['Lobby SMS Sender'] = menu.add_feature('SMS Sender', 'parent', Script.Parent['local_lobby'].id)


    Script.Feature['Lobby Send Custom SMS'] = menu.add_feature('Send SMS: Input', 'action', Script.Parent['Lobby SMS Sender'].id, function(f)
        local Message = get.Input('Enter message to send')
        if not Message then
            Notify('Input canceled.', "Error", '')
            return
        end

        for id = 0, 31 do
            if utility.valid_player(id) then
                player.send_player_sms(id, Message)
            end

            coroutine.yield(0)
        end
    end)


    Script.Feature['Lobby Send SCID And IP'] = menu.add_feature('Send their SCID & IP', 'action', Script.Parent['Lobby SMS Sender'].id, function(f)
        for id = 0, 31 do
            if utility.valid_player(id) then
                player.send_player_sms(id, 'Name: ' .. get.Name(id) .. '\nR*SCID: ' .. tostring(get.SCID(id)) .. '\nIP: ' .. get.IP(id))
            end

            coroutine.yield(0)
        end
    end)


    Script.Feature['SMS Delay'] = menu.add_feature('Spam Speed', 'autoaction_slider', Script.Parent['Lobby SMS Sender'].id, function(f)
        settings['SMS Delay'] = {Value = f.value}
    end)
    Script.Feature['SMS Delay'].min = 250
    Script.Feature['SMS Delay'].max = 10000
    Script.Feature['SMS Delay'].mod = 250


    Script.Feature['Lobby Spam Custom SMS'] = menu.add_feature('Spam SMS: Input', 'toggle', Script.Parent['Lobby SMS Sender'].id, function(f)
        local msg = get.Input('Enter message to spam')
        if not msg then
            Notify('Input canceled.', "Error", '')
            f.on = false
            return
        end

        while f.on do
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                    player.send_player_sms(id, msg)
                end
            end
            coroutine.yield(10000 - math.floor(Script.Feature['SMS Delay'].value))
        end
    end)
    

    Script.Feature['Lobby Spam SCID And IP'] = menu.add_feature('Spam their SCID & IP', 'toggle', Script.Parent['Lobby SMS Sender'].id, function(f)
        while f.on do
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                    player.send_player_sms(id, 'Name: ' .. get.Name(id) .. '\nR*SCID: ' .. tostring(get.SCID(id)) .. '\nIP: ' .. get.IP(id))
                end

            end

            coroutine.yield(10000 - math.floor(Script.Feature['SMS Delay'].value))
        end
    end)


    Script.Parent['Lobby Miscellaneous'] = menu.add_feature('Miscellaneous', 'parent', Script.Parent['local_lobby'].id, nil)


    local TextFlags = {
        ["NONE"] = 0,
        ["CENTER"] = 1 << 0,
        ["SHADOW"] = 1 << 1,
        ["VCENTER"] = 1 << 2,
        ["BOTTOM"] = 1 << 3,
        ["JUSTIFY_RIGHT"] = 1 << 4,
    }


    Script.Parent['Player Bar v2'] = menu.add_feature('Player Bar', 'parent', Script.Parent['Lobby Miscellaneous'].id, nil)

    local newFont = scriptdraw.register_font(paths['ScriptData'] .. '\\Playerbar.spritefont')
    Script.Feature['Enable Player Bar v2'] = menu.add_feature('Enable', 'value_str', Script.Parent['Player Bar v2'].id, function(f)
        settings['Enable Player Bar v2'] = {Enabled = f.on, Value = f.value}

        while f.on do
            if player.player_count() < 16 and f.value == 0 then
                scriptdraw.draw_rect(v2(1, 1), v2(5, 0.075), Math.RGBAToInt(10, 10, 10, 220))
                scriptdraw.draw_text(Math.TimePrefix(), v2(-0.5, 0.955), v2(1, 1), 0.55, Math.RGBAToInt(255, 255, 255, 255), TextFlags["CENTER"], newFont)
            else
                scriptdraw.draw_rect(v2(1, 1), v2(5, 0.155), Math.RGBAToInt(10, 10, 10, 220))
                scriptdraw.draw_text(Math.TimePrefix(), v2(-0.5, 0.918), v2(1, 1), 0.55, Math.RGBAToInt(255, 255, 255, 255), TextFlags["CENTER"], newFont)
            end

            local pos = v2(-0.99, 0.992)
            local done = 0

            for i = 0, 31 do
                if player.is_player_valid(i) then
                    local Name = get.Name(i)
                    if Name == " " then
                        Name = "Invalid Name"
                    end
                    
                    local isTyping
                    for i = 1, #typingplayers do
                        if typingplayers[i] == Name then
                            isTyping = true
                        end
                    end

                    local color
                    if isTyping then
                        color = Math.RGBAToInt(183, 152, 61, 255)

                    elseif player.get_player_health(i) == 0 or not player.is_player_playing(i) then
                        color = Math.RGBAToInt(128, 128, 128, 255)

                    elseif i == script.get_host_of_this_script() then
                        color = Math.RGBAToInt(15, 150, 200, 255)

                    elseif i == Self() then
                        color = Math.RGBAToInt(35, 150, 80, 255)

                    elseif player.is_player_friend(i) then
                        color = Math.RGBAToInt(106, 82, 182, 255)

                    elseif player.is_player_modder(i, -1) then
                        color = Math.RGBAToInt(189, 43, 43, 255)

                    else
                        color = Math.RGBAToInt(255, 255, 255, 255)
                        
                    end

                    scriptdraw.draw_text(Name, pos, v2(1, 1), 0.55, color, TextFlags["SHADOW"], newFont)
                    if player.is_player_host(i) then
                        scriptdraw.draw_text(Name, pos + v2(-0.001, 0.001), v2(1, 1), 0.55, color, TextFlags["SHADOW"], newFont)
                    end
                    
                end
                if player.is_player_valid(i) or f.value ~= 0 then
                    pos.x = pos.x + 0.122
                    done = done + 1
                    if done == 16 then
                        pos.x = -0.99
                        pos.y = 0.955
                    end
                end
            end

            settings['Enable Player Bar v2'].Value = f.value
            coroutine.yield(0)
        end

        settings['Enable Player Bar v2'].Enabled = f.on
    end)
    Script.Feature['Enable Player Bar v2']:set_str_data({'Dynamic', 'Static'})


    Script.Parent['Player Bar v2 Tags'] = menu.add_feature('Player Colors', 'parent', Script.Parent['Player Bar v2'].id, nil)

    
    Script.Feature['Player Bar White'] = menu.add_feature('White = Regular Player', 'action', Script.Parent['Player Bar v2 Tags'].id)
    Script.Feature['Player Bar Thick'] = menu.add_feature('Thick = Session Host', 'action', Script.Parent['Player Bar v2 Tags'].id)
    Script.Feature['Player Bar Blue'] = menu.add_feature('Blue = Script Host', 'action', Script.Parent['Player Bar v2 Tags'].id)
    Script.Feature['Player Bar Green'] = menu.add_feature('Green = Yourself', 'action', Script.Parent['Player Bar v2 Tags'].id)
    Script.Feature['Player Bar Purple'] = menu.add_feature('Purple = Friends', 'action', Script.Parent['Player Bar v2 Tags'].id)
    Script.Feature['Player Bar Gray'] = menu.add_feature('Gray = Dead/Inactive', 'action', Script.Parent['Player Bar v2 Tags'].id)
    Script.Feature['Player Bar Yellow'] = menu.add_feature('Yellow = Typing/Talking', 'action', Script.Parent['Player Bar v2 Tags'].id)
    Script.Feature['Player Bar Red'] = menu.add_feature('Red = Modder', 'action', Script.Parent['Player Bar v2 Tags'].id)


    Script.Feature['Laser Beam Waypoint'] = menu.add_feature('Laser Beam Explode Waypoint', 'action', Script.Parent['Lobby Miscellaneous'].id, function()
        local wp = ui.get_waypoint_coord()
        if wp.x == 16000 then
            Notify('No Waypoint found.', "Error", '')
            return
        end

        local maxz = get.OwnCoords().z + 175

        for i = maxz, -50, -2 do
            local pos = v3(wp.x, wp.y, i)
            pos.x = math.floor(pos.x)
            pos.y = math.floor(pos.y)

            fire.add_explosion(pos, 59, true, false, 0, 0)

            for x = 1, 2 do
                pos.x = math.random(pos.x - 3, pos.x + 3)
                pos.y = math.random(pos.y - 3, pos.y + 3)
                fire.add_explosion(pos, 59, true, false, 0, 0)
            end

            pos.x = math.random(pos.x - 6, pos.x + 6)
            pos.y = math.random(pos.y - 6, pos.y + 6)

            fire.add_explosion(pos, 8, true, false, 0, 0)

            coroutine.yield(0)
        end
    end)


    Script.Feature['Lobby Shake Cam'] = menu.add_feature('Shake Cam', 'toggle', Script.Parent['Lobby Miscellaneous'].id, function(f)
        while f.on do
            local pos = v3()

            for i = 1, 10 do
                pos.x = math.random(-2700, 2700)
                pos.y = math.random(-3300, 7500)
                pos.z = Math.GetGroundZ(pos.x, pos.y) + math.random(30, 90)

                fire.add_explosion(pos, 8, false, true, 20, 0)

            end

            coroutine.yield(0)
        end
    end)


    Script.Feature['Appear as Ghost'] = menu.add_feature('Appear as Ghost', 'toggle', Script.Parent['Lobby Miscellaneous'].id, function(f)
        if not menu.is_trusted_mode_enabled(1 << 2) then
            Notify('Not available while trusted mode for natives is turned off', 'Error', 'Appear as Ghost')
            f.on = false
            return
        end

        while f.on do
            if not menu.is_trusted_mode_enabled(1 << 2) then
                f.on = false
            end

            for id = 0, 31 do
                if utility.valid_player(id, false) then
                    N.NETWORK._SET_RELATIONSHIP_TO_PLAYER(id, true)
                end

            end

            coroutine.yield(1000)
        end

        for id = 0, 31 do
            if utility.valid_player(id, false) and not Script.PlayerFeature['Player Appear As Ghost'].on[id] then
                N.NETWORK._SET_RELATIONSHIP_TO_PLAYER(id, false)
            end
        end
    end)


    Script.Feature['Mark OTR Blip'] = menu.add_feature('Mark OTR Players On Map', 'toggle', Script.Parent['Lobby Miscellaneous'].id, function(f)
        settings['Mark OTR Blip'] = {Enabled = f.on}
        local running = {}

        while f.on do
            for id = 0, 31 do
                if utility.valid_player(id, false) and (scriptevent.IsPlayerOTR(id) or player.get_player_max_health(id) <= 100) then
                    if (not running[id] or menu.has_thread_finished(running[id])) then

                        running[id] = menu.create_thread(function(source)
                            OTRBlip[source] = ui.add_blip_for_entity(get.PlayerPed(source))
                            ui.set_blip_sprite(OTRBlip[source], 484)
                            ui.set_blip_colour(OTRBlip[source], 0)

                            while player.is_player_valid(source) and (scriptevent.IsPlayerOTR(source) or player.get_player_max_health(id) <= 100) and f.on do
                                coroutine.yield(0)
                            end
    
                            if OTRBlip[source] then
                                ui.remove_blip(OTRBlip[source])
                                OTRBlip[source] = nil
                            end
                        end, id)

                    end
                    
                end

            end

            coroutine.yield(0)
        end
        settings['Mark OTR Blip'].Enabled = f.on
    end)


    Script.Feature['Teleport Watcher'] = menu.add_feature('Teleport Watcher', 'toggle', Script.Parent['Lobby Miscellaneous'].id, function(f)
        settings['Teleport Watcher'] = {Enabled = f.on}
        local running = {}

        while f.on do
            for id = 0, 31 do
                if utility.valid_player(id, false) and get.PlayerCoords(id) ~= v3(0, 0, 0) then
                    if not running[id] or menu.has_thread_finished(running[id]) then
                        running[id] =  menu.create_thread(function()
                            while f.on and player.is_player_valid(id) do
                                local pos1 = get.PlayerCoords(id)
                                pos1.z = 0

                                coroutine.yield(100)
                                if not f.on or not player.is_player_valid(id) then
                                    return
                                end

                                local pos2 = get.PlayerCoords(id)
                                pos2.z = 0

                                local distance = pos1:magnitude(pos2)
                                if distance > 100 then
                                    Notify(get.Name(id) .. ' teleported ' .. math.floor(distance) .. 'm away.', 'Neutral', 'Teleport Watcher')
                                end

                                coroutine.yield(0)
                            end
                        end, nil)

                    end

                end

            end

            coroutine.yield(0)
        end
        settings['Teleport Watcher'].Enabled = f.on
    end)


    Script.Feature['Notify Spectating Players'] = menu.add_feature('Spectate Watcher', 'toggle', Script.Parent['Lobby Miscellaneous'].id, function(f)
        settings['Notify Spectating Players'] = {Enabled = f.on}
        local running = {}

        while f.on do
            for id = 0, 31 do
                if player.is_player_valid(id) and not id == Self() and network.get_player_player_is_spectating(id) ~= nil then
                    if not running[id] or menu.has_thread_finished(running[id]) then
                        running[id] = menu.create_thread(function(source)
                            local spectating = network.get_player_player_is_spectating(source)
                            local name = get.Name(source)
    
                            Notify(name .. ' started spectating ' .. get.Name(spectating), "Neutral", '')
    
                            while player.is_player_valid(source) and network.get_player_player_is_spectating(source) ~= nil do
                                coroutine.yield(0)
                            end
    
                            Notify(name .. ' stopped spectating ' .. get.Name(spectating), "Neutral", '')
                        end, id) 

                    end
                    
                end

            end

            coroutine.yield(0)
        end
        settings['Notify Spectating Players'].Enabled = f.on
    end)


    Script.Feature['Auto Force Script Host'] = menu.add_feature('Auto Force Script Host', 'value_str', Script.Parent['Lobby Miscellaneous'].id, function(f)
        settings['Auto Force Script Host'] = {Enabled = f.on, Value =  f.value}
        while f.on do
            if network.is_session_started() then
                coroutine.yield(1000)
                local lobbyID = Self()

                if f.value == 1 and script.get_host_of_this_script() ~= Self() then
                    menu.get_feature_by_hierarchy_key('online.lobby.force_script_host'):toggle()

                elseif f.value == 0 and script.get_host_of_this_script() ~= Self() then
                    coroutine.yield(2000)

                    menu.get_feature_by_hierarchy_key('online.lobby.force_script_host'):toggle()
                    while lobbyID == Self() and f.value == 0 and network.is_session_started() do
                        coroutine.yield(0)
                    end

                end

            end

            settings['Auto Force Script Host'].Value = f.value
            coroutine.yield(2000)
        end
        settings['Auto Force Script Host'].Enabled = f.on
    end)
    Script.Feature['Auto Force Script Host']:set_str_data({'Upon Joining', 'Always'})


    Script.Feature['Notify Script-Host Migrations'] = menu.add_feature('Notify Script Host Migrations', 'toggle', Script.Parent['Lobby Miscellaneous'].id, function(f)
        settings['Notify Script-Host Migrations'] = {Enabled = f.on}
        while f.on do
            local scripthost = script.get_host_of_this_script()
            local name = get.Name(scripthost)
            local extracheck = name

            while scripthost == script.get_host_of_this_script() do
                coroutine.yield(500)
            end

            local newhost = script.get_host_of_this_script()
            local newname = get.Name(newhost)
            
            while newname == 'Invalid Player' do
                newname = get.Name(script.get_host_of_this_script())
                coroutine.yield(0)
            end

            if newname == extracheck then
                return
            end

            if name == 'Invalid Player' then
                Log('Script Host migrated to ' .. newname)
                Notify('Script Host migrated to ' .. newname, "Neutral", '')
            else
                Log('Script Host migrated from ' .. name .. ' to ' .. newname .. '.')
                Notify('Script Host migrated from ' .. name .. ' to ' .. newname .. '.', "Neutral", '')
            end

            coroutine.yield(0)
        end
        settings['Notify Script-Host Migrations'].Enabled = f.on
    end)


    Script.Feature['Notify Host Migrations'] = menu.add_feature('Notify Session Host Migrations', 'toggle', Script.Parent['Lobby Miscellaneous'].id, function(f)
        settings['Notify Host Migrations'] = {Enabled = f.on}
        while f.on do
            local scripthost = player.get_host()
            local name = get.Name(scripthost)
            local extracheck = name

            while scripthost == player.get_host() do
                coroutine.yield(500)
            end

            local newhost = player.get_host()
            local newname = get.Name(newhost)
            
            while newname == 'Invalid Player' do
                newname = get.Name(player.get_host())
                coroutine.yield(0)
            end

            if newname == extracheck then
                return
            end

            if name == 'Invalid Player' then
                Log('Session Host migrated to ' .. newname)
                Notify('Session Host migrated to ' .. newname, "Neutral", '')
            else
                Log('Session Host migrated from ' .. name .. ' to ' .. newname .. '.')
                Notify('Session Host migrated from ' .. name .. ' to ' .. newname .. '.', "Neutral", '')
            end
            
            coroutine.yield(0)
        end
        settings['Notify Host Migrations'].Enabled = f.on
    end)


    Script.Parent['Lobby Malicious'] = menu.add_feature('Malicious', 'parent', Script.Parent['local_lobby'].id, nil)


    Script.Feature['Force Host'] = menu.add_feature('Force Host', 'toggle', Script.Parent['Lobby Malicious'].id, function(f)
        if network.network_is_host() then
            Notify('You are already Session Host.', "Error", '')
            f.on = false
            return
        end

        while f.on do
            local host = player.get_host()
            if host == Self() then
                Notify('You are now Session Host.\nTurning off Feature.', "Success", '2Take1Script Force Host')
                f.on = false
                return

            elseif player.is_player_friend(host) and IsFeatOn('Exclude Friends') then
                Notify('One of your Friends is Session Host.\nTurning off Feature.', "Success", '2Take1Script Force Host')
                f.on = false
                return

            else
                if f.value == 0 then
                    scriptevent.kick(host)
                else
                    SmartKick(host)
                end
            end

            coroutine.yield(0)
        end
    end)


    Script.Feature['Kick Random Player'] = menu.add_feature('Kick Random Player', 'action', Script.Parent['Lobby Malicious'].id, function(f)
        local valid_players = {}
        local kicked = false

        for id = 0, 31 do
            if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                valid_players[#valid_players + 1] = id
            end
        end

        if #valid_players == 0 then
            Notify('No valid Players found.', "Error", '')
            return
        end

        while not kicked do
            local playerid = valid_players[math.random(#valid_players)]

            if utility.valid_player(playerid, IsFeatOn('Exclude Friends')) then
                Notify(get.Name(playerid) .. ' has been chosen as random player and got kicked.', "Success")

                if f.value == 0 then
                    scriptevent.kick(playerid)
                else
                    SmartKick(playerid)
                end

                kicked = true
            end

            coroutine.yield(0)
        end
    end)


    Script.Feature['Kick Lobby'] = menu.add_feature('Kick Lobby', 'action_value_str', Script.Parent['Lobby Malicious'].id, function(f)
        if f.value == 0 then
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                    scriptevent.kick(id)
                    coroutine.yield(0)
                end
            end

        elseif f.value == 1 then
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) and not player.is_player_host(id) then
                    SmartKick(id)
                end

                coroutine.yield(0)
            end

            SmartKick(player.get_host())

        elseif f.value == 2 then
            if not network.network_is_host() then
                Notify('You are not Session Host.', "Error", 'Kick Lobby')
                return
            end

            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                    network.network_session_kick_player(id)
                end
            end
        end
    end)
    Script.Feature['Kick Lobby']:set_str_data({'Script Event', 'Desync Kick', 'Host Kick'})


    Script.Feature['Lobby Script Host Curse'] = menu.add_feature('Script Host Curse', 'action', Script.Parent['Lobby Malicious'].id, function(f)
        if script.get_host_of_this_script() == Self() then
            Notify('This doesnt work while you are Script Host.', "Error", '')
            return
        end

        for i = 1, 5 do
            scriptevent.curse()
        end
    end)


    Script.Feature['Break Lobby'] = menu.add_feature('Break Lobby', 'action_value_str', Script.Parent['Lobby Malicious'].id, function(f)
        if script.get_host_of_this_script() == Self() then
            Notify('This doesnt work while you are Script Host.', "Error", 'Break Lobby')
            return
        end
        
        if f.value == 0 then
            for id = 0, 31 do
                if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                    scriptevent.Send('Start CEO Mission', {Self(), 0, 1}, id)
                end

            end

            return
        end

        scriptevent.Send('Start CEO Mission', {Self(), 0, 1}, Self())
    end)
    Script.Feature['Break Lobby']:set_str_data({'Normal', 'Stealth'})


    Script.Feature['Script Event Crash'] = menu.add_feature('Script Event Crash', 'action', Script.Parent['Lobby Malicious'].id, function(f)
        for id = 0, 31 do
            if utility.valid_player(id, IsFeatOn('Exclude Friends')) then
                scriptevent.crash(id)
                coroutine.yield(0)
            end

        end

        Notify('Crash done.', "Success", 'Crash Lobby')
    end)

    Script.Feature['Sound Spam Crash'] = menu.add_feature('Sound Spam Crash', 'action', Script.Parent['Lobby Malicious'].id, function(f)
        local sounds = {
            {Name = 'ROUND_ENDING_STINGER_CUSTOM', Ref = 'CELEBRATION_SOUNDSET'},
            {Name = 'Object_Dropped_Remote', Ref = 'GTAO_FM_Events_Soundset'},
            {Name = 'Oneshot_Final', Ref = 'MP_MISSION_COUNTDOWN_SOUNDSET'},
            {Name = '5s', Ref = 'MP_MISSION_COUNTDOWN_SOUNDSET'}
        }

        local sound = sounds[math.random(#sounds)]
        local time = utils.time_ms() + 2000

        while time > utils.time_ms() do
            local pos = player.get_player_coords(Self())

            for i = 1, 10 do
                audio.play_sound_from_coord(-1, sound.Name, pos, sound.Ref, true, 999999, false)
            end
            
            coroutine.yield(0)
        end

        Notify('Crash done.', "Success", 'Crash Lobby')
    end)


    Script.Feature['Parachute Crash'] = menu.add_feature('Parachute Crash', 'action', Script.Parent['Lobby Malicious'].id, function(f, id)
        for i = 1, 2 do
            local chimp = Spawn.Ped(0xA8683715, v3(0, 0, 500))
            local targetpos = get.OwnCoords()
            targetpos.z = targetpos.z + 1500
        
            local crashent = Spawn.Vehicle(0x381E10BD, targetpos)
            ped.set_ped_into_vehicle(chimp, crashent, -1)
            vehicle.set_vehicle_parachute_model(crashent, 0x7FFBC1E2)
            N.VEHICLE._SET_VEHICLE_PARACHUTE_TEXTURE_VARIATION(crashent, 0.1)
            system.wait(10)
            vehicle.set_vehicle_parachute_active(crashent, true)
            system.wait(100)
            utility.clear({crashent, chimp})

            coroutine.yield(500)
        end
    
        Notify('Crash done.', "Success", 'Crash Lobby')
    end)


    Script.Feature['Bad Rope Attachment'] = menu.add_feature('Bad Rope Attachment', 'action', Script.Parent['Lobby Malicious'].id, function(f)
        local Position = v3(-70.31, -819.29, 327.60)
        local Position2 = v3(-75.31, -819.29, 321.60)
    
        local Vehicle = Spawn.Vehicle(2132890591, Position)
    
        local Dummy = Spawn.Ped(2727244247, Position2, 26)
    
        entity.set_entity_god_mode(Dummy, true)
    
        local Rope = rope.add_rope(Position, v3(0,0,0), 1, 1, 0.0000000000000000000000000000000000001, 1, 1, true, true, true, 1.0, true)
    
        rope.attach_entities_to_rope(Rope, Vehicle, Dummy, entity.get_entity_coords(Vehicle), entity.get_entity_coords(Dummy), 2 , 0, 0, "Center", "Center")
    
        Notify('Crash sent, attemping cleanup in 5 seconds...', 'Success', 'Crash Lobby')
    
        coroutine.yield(5000)
    
        rope.delete_rope(Rope)
        utility.clear({Vehicle, Dummy})
    
        if entity.is_an_entity(Vehicle) or entity.is_an_entity(Dummy) or rope.does_rope_exist(Rope) then
            Notify('Cleanup failed.', 'Error', 'Crash Lobby')
        else
            Notify('Cleanup successful.', 'Success', 'Crash Lobby')
        end
    end)


    Script.Feature['Crash Host'] = menu.add_feature('Crash Host', 'action', Script.Parent['Lobby Malicious'].id, function(f)
        if network.network_is_host() then
            Notify('This cannot be used while you are Session Host.', "Error", '')
            return
        end
    
        local Position = get.OwnCoords()
        local Ped = get.OwnPed()
    
        entity.set_entity_coords_no_offset(Ped, v3(-6170, 10837, 40))
        coroutine.yield(500)
        entity.set_entity_coords_no_offset(Ped, v3(10841, -6928, 1))
        coroutine.yield(500)
    
        entity.set_entity_coords_no_offset(Ped, Position)

        Notify('Crash done.', "Success", 'Crash Host')
    end)


    --[[ patched
    Script.Feature['Model Change Crash'] = menu.add_feature('Model Change Crash', 'action_value_str', Script.Parent['Lobby Malicious'].id, function(f)
        if f.value == 4 then
            fix_crash_screen()
            return
        end

        local pos = get.OwnCoords()
        hash_c = entity.get_entity_model_hash(get.OwnPed())

        local hash1 = 2627665880
        local hash2 = 1885233650
        if player.is_player_female(Self()) then
            local hashswap = hash1
            hash1 = hash2
            hash2 = hashswap
        end
    
        for i = 1, 11 do
            outfits['session_crash']['textures'][i] = ped.get_ped_texture_variation(get.OwnPed(), i)
            outfits['session_crash']['clothes'][i] = ped.get_ped_drawable_variation(get.OwnPed(), i)
        end

        local loop = {0, 1, 2, 6, 7}
        for z = 1, #loop do
            outfits['session_crash']['prop_ind'][z] = ped.get_ped_prop_index(get.OwnPed(), loop[z])
            outfits['session_crash']['prop_text'][z] = ped.get_ped_prop_texture_index(get.OwnPed(), loop[z])
        end

        if f.value == 0 then
            change_model(0x471BE4B2, nil, nil, nil)
            coroutine.yield(5000)

        elseif f.value == 1 then
            for i = 1, 32 do
                entity.set_entity_coords_no_offset(get.OwnPed(), v3(460.586, 5571.714, 781.179))

                change_model(hash1, nil, nil, nil)
            
                coroutine.yield(100)
                ped.set_ped_health(get.OwnPed(), 0)
                coroutine.yield(100)
                ped.resurrect_ped(get.OwnPed())
                coroutine.yield(300)
            
                change_model(hash2, nil, nil, nil)
            
                coroutine.yield(100)
                ped.set_ped_health(get.OwnPed(), 0)
                coroutine.yield(200)
                ped.resurrect_ped(get.OwnPed())
            end

        elseif f.value == 2 then
            local player_ped = get.OwnPed()
            for i = 1, 15 do
                entity.set_entity_coords_no_offset(get.OwnPed(), v3(-76.101, -819.124, 326.175))

                change_model(hash1, nil, nil, nil)
            
                coroutine.yield(100)
                ped.set_ped_health(get.OwnPed(), 0)
                coroutine.yield(100)
                ped.resurrect_ped(get.OwnPed())
                coroutine.yield(300)
            
                change_model(hash2, nil, nil, nil)
            
                coroutine.yield(100)
                ped.set_ped_health(get.OwnPed(), 0)
                coroutine.yield(200)
                ped.resurrect_ped(get.OwnPed())
            end
            ped.clone_ped(player_ped)
            
        elseif f.value == 3 then
            if network.network_is_host() then
                Notify('This cannot be used while you are Session Host.', "Error", '')
                return
            end

            for i = 1, 20 do
                utility.tp(v3(-6170,10837,40))

                change_model(hash1, nil, nil, nil)

                coroutine.yield(10)
                ped.set_ped_health(get.OwnPed(), 0)
                coroutine.yield(10)
                ped.resurrect_ped(get.OwnPed())
                coroutine.yield(30)

                change_model(hash2, nil, nil, nil)

                coroutine.yield(10)
                ped.set_ped_health(get.OwnPed(), 0)
                coroutine.yield(10)
                ped.resurrect_ped(get.OwnPed())
                coroutine.yield(30)
            end
            utility.tp(pos)
        end
    
        fix_crash_screen()
        utility.tp(pos)

        coroutine.yield(500)
        Notify('Crash Complete.', "Success")
    end)
    Script.Feature['Model Change Crash']:set_str_data({'v1', 'v2', 'v3', 'v4', 'Fix loading screen'})
    ]]

    Script.Parent['Auto Kick Modder'] = menu.add_feature('Auto Kick Modder', 'parent', Script.Parent['local_automod'].id, nil)


    Script.Feature['Enable Auto Kick Modder'] = menu.add_feature('Enable Auto Kick', 'value_str', Script.Parent['Auto Kick Modder'].id, function(f)
        while f.on do
            settings['Enable Auto Kick Modder'] = {Enabled = f.on, Value = f.value}
            coroutine.yield(0)
        end
    end)
    Script.Feature['Enable Auto Kick Modder']:set_str_data({'All Players', 'Exclude Friends'})


    local flagcheck = 1
    while flagcheck < player.get_modder_flag_ends() do
        local name = player.get_modder_flag_text(flagcheck)

        Script.Feature['Autokick ' .. name] = menu.add_feature(name, 'value_str', Script.Parent['Auto Kick Modder'].id, function(f)
            settings['Autokick ' .. name] = {Enabled = f.on, Value = f.value}

        end)
        Script.Feature['Autokick ' .. name]:set_str_data({'Kick', 'Kick & Blacklist'})

        flagcheck = flagcheck * 2
    end
    

    Script.Parent['Anti Advertisement Tool'] = menu.add_feature('Anti Advertisement', 'parent', Script.Parent['local_automod'].id, nil)


    Script.Feature['Ad Blacklist Name Strings'] = menu.add_feature('Name String Blacklist', 'value_str', Script.Parent['Anti Advertisement Tool'].id, function(f)
        settings['Ad Blacklist Name Strings'] = {Enabled = f.on, Value = f.value}
    end)
    Script.Feature['Ad Blacklist Name Strings']:set_str_data({'Safe', 'Aggressive'})


    Script.Feature['Ad Blacklist Chat Strings'] = menu.add_feature('Chat String Blacklist', 'value_str', Script.Parent['Anti Advertisement Tool'].id, function(f)
        settings['Ad Blacklist Chat Strings'] = {Enabled = f.on, Value = f.value}
    end)
    Script.Feature['Ad Blacklist Chat Strings']:set_str_data({'Safe', 'Aggressive'})


    Script.Feature['Ad Blacklist Fake Friends'] = menu.add_feature('Add to Fake Friends Blacklist', 'toggle', Script.Parent['Anti Advertisement Tool'].id, function(f)
        settings['Ad Blacklist Fake Friends'] = {Enabled = f.on}
    end)


    Script.Feature['Ad Blacklist Disable Notifications'] = menu.add_feature('Disable Notifications', 'toggle', Script.Parent['Anti Advertisement Tool'].id, function(f)
        settings['Ad Blacklist Disable Notifications'] = {Enabled = f.on}
    end)


    Script.Parent['Vehicle Blacklist'] = menu.add_feature('Vehicle Blacklist', 'parent', Script.Parent['local_automod'].id, nil)


    Script.Feature['Enable Vehicle Blacklist'] = menu.add_feature('Enable Blacklist', 'value_str', Script.Parent['Vehicle Blacklist'].id, function(f)
        settings['Enable Vehicle Blacklist'] = {Enabled = f.on, Value = f.value}
        local detected = {}
        while f.on do

            local exclude
            if f.value == 0 then
                exclude = false
            else
                exclude = true
            end

            for id = 0, 31 do
                if utility.valid_player(id, exclude) then
                    if not detected[id] or menu.has_thread_finished(detected[id]) then
                        detected[id] = menu.create_thread(VBCheck, id)
                    end
                end

                coroutine.yield(0)
            end
            settings['Enable Vehicle Blacklist'].Value = f.value
            coroutine.yield(1000)
        end
        settings['Enable Vehicle Blacklist'].Enabled = f.on
    end)
    Script.Feature['Enable Vehicle Blacklist']:set_str_data({'All Players', 'Exclude Friends'})


    Script.Feature['Vehicle Blacklist Reaction'] = menu.add_feature('Chosen Reaction', 'autoaction_value_str', Script.Parent['Vehicle Blacklist'].id, function(f)
        settings['Vehicle Blacklist Reaction'] = {Value = f.value}
    end)
    Script.Feature['Vehicle Blacklist Reaction']:set_str_data({'Delete Vehicle', 'Explode', 'Vehicle Kick', 'Script Kick', 'Desync Kick', 'Script Crash'})


    for i = 1, #customData.vehicle_blacklist do
        local parent = customData.vehicle_blacklist[i].Name
        Script.Parent['VB ' .. parent] = menu.add_feature(parent, 'parent', Script.Parent['Vehicle Blacklist'].id, nil)

        for j = 1, #customData.vehicle_blacklist[i].Children do
            if streaming.is_model_a_vehicle(customData.vehicle_blacklist[i].Children[j].Hash) then
                local name = customData.vehicle_blacklist[i].Children[j].Name
                Script.Feature['VB ' .. name] = menu.add_feature(name, 'toggle', Script.Parent['VB ' .. parent].id, function(f)
                    settings['VB ' .. name] = {Enabled = f.on}

                end)
            else
                print('Vehicle Blacklist preset ' .. customData.vehicle_blacklist[i].Children[j].Name .. ' is invalid.')
            end
        end
    end


    Script.Parent['Weapon Blacklist'] = menu.add_feature('Weapon Blacklist', 'parent', Script.Parent['local_automod'].id, nil)


    Script.Feature['Enable Weapon Blacklist'] = menu.add_feature('Enable Blacklist', 'value_str', Script.Parent['Weapon Blacklist'].id, function(f)
        settings['Enable Weapon Blacklist'] = {Enabled = f.on, Value = f.value}
        local detected = {}

        while f.on do
            local exclude
            if f.value == 0 then
                exclude = false
            else
                exclude = true
            end

            for id = 0, 31 do
                if utility.valid_player(id, exclude) and (not detected[id] or menu.has_thread_finished(detected[id])) then
                    detected[id] = menu.create_thread(WBCheck, id)
                end

                coroutine.yield(0)
            end

            settings['Enable Weapon Blacklist'].Value = f.value
            coroutine.yield(0)
        end
        settings['Enable Weapon Blacklist'].Enabled = f.on
    end)
    Script.Feature['Enable Weapon Blacklist']:set_str_data({'All Players', 'Exclude Friends'})


    Script.Feature['Weapon Blacklist Reaction'] = menu.add_feature('Chosen Reaction', 'autoaction_value_str', Script.Parent['Weapon Blacklist'].id, function(f)
        settings['Weapon Blacklist Reaction'] = {Value = f.value}
    end)
    Script.Feature['Weapon Blacklist Reaction']:set_str_data({'Remove Weapon', 'Script Kick', 'Desync Kick', 'Script Crash'})


    for i = 1, #mapper.weapons do
        local WeaponCategory = mapper.weapons[i]
        Script.Parent[WeaponCategory] = menu.add_feature(WeaponCategory.Name, "parent", Script.Parent['Weapon Blacklist'].id)

        for j = 1, #WeaponCategory.Children do
            local CurrentWeapon = WeaponCategory.Children[j]
            
            Script.Feature['Blacklist ' .. CurrentWeapon.Name] = menu.add_feature(CurrentWeapon.Name, "toggle", Script.Parent[WeaponCategory].id, function(f)
                settings['Blacklist ' .. CurrentWeapon.Name] = {Enabled = f.on}
            end)

        end

    end


    Script.Feature['Anti Chat Spam'] =  menu.add_feature('Anti Chat Spam', 'value_str', Script.Parent['local_automod'].id, function(f)
        settings['Anti Chat Spam'] = {Enabled = f.on, Value = f.value}
    end)
    Script.Feature['Anti Chat Spam']:set_str_data({'Script Kick', 'Desync Kick', 'Script Crash'})


    Script.Feature['Kick Vote-Kicker'] = menu.add_feature('Kick Vote-Kicker', 'value_str', Script.Parent['local_automod'].id, function(f)
        settings['Kick Vote-Kicker'] = {Enabled = f.on, Value = f.value}
    end)
    Script.Feature['Kick Vote-Kicker']:set_str_data({'Script Kick', 'Desync Kick'})


    Script.Feature['GEO-Block Russia'] = menu.add_feature('Punish Russians', "value_str", Script.Parent['local_automod'].id, function(f)
        settings['GEO-Block Russia'] = {Enabled = f.on, Value = f.value}
    end)
    Script.Feature['GEO-Block Russia']:set_str_data({'Script Kick', 'Desync Kick', 'Script Crash', 'Explode'})


    Script.Feature['GEO-Block China'] = menu.add_feature('Punish Chinese', 'value_str', Script.Parent['local_automod'].id, function(f)
        settings['GEO-Block China'] = {Enabled = f.on, Value = f.value}
    end)
    Script.Feature['GEO-Block China']:set_str_data({'Script Kick', 'Desync Kick', 'Script Crash', 'Explode'})


    Script.Feature['Modder Detection Announce'] = menu.add_feature('Announce Detections in Chat', 'value_str', Script.Parent['local_modderdetection'].id, function(f)
        settings['Modder Detection Announce'] = {Enabled = f.on, Value = f.value}
    end)
    Script.Feature['Modder Detection Announce']:set_str_data({'Global', 'Team'})


    Script.Feature['Announce Crash Attempts'] = menu.add_feature('Announce Crash Attempts', 'value_str', Script.Parent['local_modderdetection'].id, function(f)
        settings['Announce Crash Attempts'] = {Enabled = f.on, Value = f.value}
    end)
    Script.Feature['Announce Crash Attempts']:set_str_data({'2Take1 User', 'Modest Menu User', 'Cherax User', 'Stand User', 'Terror User'})


    Script.Parent['Remember Modder'] = menu.add_feature('Remember every Modder', 'parent', Script.Parent['local_modderdetection'].id, nil)

    Script.Feature['Modder Detection Remember'] = menu.add_feature('Enable', 'toggle', Script.Parent['Remember Modder'].id, function(f)
        settings['Modder Detection Remember'] = {Enabled = f.on}
    end)


    Script.Parent['Remember Modder Profiles'] = menu.add_feature('Detected Modder', 'parent', Script.Parent['Remember Modder'].id, nil)


    if utils.file_exists(files['Modder']) then
        menu.create_thread(function()
            local done = 0
            for line in io.lines(files['Modder']) do

                local parts = {}
                for part in line:gmatch("[^:]+") do
                    parts[#parts + 1] = part
                end

                if #parts == 3 then
                    local name = parts[1]
                    local scid = parts[2]
                    local reason = parts[3]
    
                    Script.Feature[name .. '/' .. reason] = menu.add_feature(name, 'action_value_str',  Script.Parent['Remember Modder Profiles'].id, function(f)
                        if f.value == 0 then
                            Notify('Name: ' .. name .. '\nSCID: ' .. scid .. '\nReason: ' .. reason, "Neutral", '2Take1Script Remember Modder')
                        elseif f.value == 1 then
                            local remembered = {}
                            for line2 in io.lines(files['Modder']) do
                                remembered[line2] = true
                            end
                            remembered[name .. ':' .. scid .. ':' .. reason] = nil
                
                            utility.write(io.open(files['Modder'], 'w'))
                            for k in pairs(remembered) do
                                utility.write(io.open(files['Modder'], 'a'), k)
                            end

                            menu.delete_feature(f.id)
                            Notify('Entry Deleted', "Success", '2Take1Script Remember Modder')
                        else
                            utils.to_clipboard(scid)
                            Notify('SCID copied to clipboard', "Success", '2Take1Script Remember Modder')
                        end
                    end)
                    Script.Feature[name .. '/' .. reason]:set_str_data({'Show Info', 'Delete', 'Copy SCID'})
                end

                done = done + 1
                if done == 50 then
                    done = 0
                    coroutine.yield(0)
                end
            end
        end, nil)
    end


    Script.Parent['Remember Modder Flag Selection'] = menu.add_feature('Flag Selection', 'parent', Script.Parent['Remember Modder'].id, nil)


    flagcheck = 1
    while flagcheck < player.get_modder_flag_ends() do
        local name = player.get_modder_flag_text(flagcheck)

        if name ~= 'Remembered' then
            Script.Feature['Remember ' .. name] = menu.add_feature(name, 'toggle', Script.Parent['Remember Modder Flag Selection'].id, function(f)
                settings['Remember ' .. name] = {Enabled = f.on}
            end)
        end

        flagcheck = flagcheck * 2
    end


    Script.Feature['Modder Detection Mark All'] = menu.add_feature('Mark all as Modder', 'action', Script.Parent['local_modderdetection'].id, function()
        for id = 0, 31 do
            if utility.valid_modder(id) then
                player.set_player_as_modder(id, 1)
            end
        end
    end)


    Script.Feature['Modder Detection Unmark All'] = menu.add_feature('Unmark all Modder', 'action', Script.Parent['local_modderdetection'].id, function()
        for id = 0, 31 do
            if utility.valid_player(id, false) then
                player.unset_player_as_modder(id, -1)
            end
        end
    end)


    Script.Feature['Modder Detection Health'] = menu.add_feature('Modded Health', 'value_str', Script.Parent['local_modderdetection'].id, function(f)
        settings['Modder Detection Health'] = {Enabled = f.on, Value = f.value}
        while f.on do
            for id = 0, 31 do
                if utility.valid_modder(id) then
                    coroutine.yield(1000)
                    local health = player.get_player_health(id)
                    local maxhealth = player.get_player_max_health(id)
                    if (health > 328 or maxhealth > 328) and maxhealth ~= 2500 or health > maxhealth then
                        if f.value == 0 then
                            Notify('Player: ' .. get.Name(id) .. '\nReason: Modded Health\nReaction: Notify', "Neutral", '2Take1Script Modder Detection')
                            coroutine.yield(60000)
                        else
                            Log('Player: ' .. get.Name(id) .. '\nReason: Modded Health\nPlayer Health: ' .. health .. ' Max Health: ' .. maxhealth, '[Modder Detection]')
                            player.mark_as_modder(id, customflags['Modded Health/Armor'])
                        end
                    end
                end
            end

            settings['Modder Detection Health'].Value = f.value
            coroutine.yield(500)
        end
        settings['Modder Detection Health'].Enabled = f.on
    end)
    Script.Feature['Modder Detection Health']:set_str_data({'Notify', 'Mark as Modder'})


    Script.Feature['Modder Detection Armor'] = menu.add_feature('Modded Armor', 'value_str', Script.Parent['local_modderdetection'].id, function(f)
        settings['Modder Detection Armor'] = {Enabled = f.on, Value = f.value}
        while f.on do
            for id = 0, 31 do
                coroutine.yield(25)
                if utility.valid_modder(id) then
                    local armor = player.get_player_armor(id)
                    if armor > 100 then
                        if f.value == 0 then
                            Notify('Player: ' .. get.Name(id) .. '\nReason: Modded Armor\nReaction: Notify', "Neutral", '2Take1Script Modder Detection')
                            coroutine.yield(60000)
                        else
                            Log('Player: ' .. get.Name(id) .. '\nReason: Modded Armor\nDetected Armor: ' .. armor, '[Modder Detection]')
                            player.mark_as_modder(id, customflags['Modded Health/Armor'])
                        end
                    end
                end
            end

            settings['Modder Detection Armor'].Value = f.value
            coroutine.yield(500)
        end
        settings['Modder Detection Armor'].Enabled = f.on
    end)
    Script.Feature['Modder Detection Armor']:set_str_data({'Notify', 'Mark as Modder'})


    Script.Feature['Modder Detection Player Godmode'] = menu.add_feature('Player Godmode', 'value_str', Script.Parent['local_modderdetection'].id, function(f)
        settings['Modder Detection Player Godmode'] = {Enabled = f.on, Value = f.value}
        local running = {}

        while f.on do
            for id = 0, 31 do
                if utility.valid_modder(id) and get.GodmodeState(id) then
                    if not running[id] or menu.has_thread_finished(running[id]) then
                        running[id] = menu.create_thread(modderevents.godmode, id)

                    end

                end

            end

            settings['Modder Detection Player Godmode'].Value = f.value
            coroutine.yield(500)
        end
        settings['Modder Detection Player Godmode'].Enabled = f.on
    end)
    Script.Feature['Modder Detection Player Godmode']:set_str_data({'Notify', 'Mark as Modder'})


    Script.Feature['Modder Detection Vehicle Godmode'] = menu.add_feature('Vehicle Godmode', 'value_str', Script.Parent['local_modderdetection'].id, function(f)
        settings['Modder Detection Vehicle Godmode'] = {Enabled = f.on, Value = f.value}
        local running = {}

        while f.on do
            for id = 0, 31 do
                if utility.valid_modder(id) and get.VehicleGodmodeState(id) then
                    if not running[id] or menu.has_thread_finished(running[id]) then
                        running[id] = menu.create_thread(modderevents.vehiclegodmode, id)

                    end

                end

            end

            settings['Modder Detection Vehicle Godmode'].Value = f.value
            coroutine.yield(500)
        end
        settings['Modder Detection Vehicle Godmode'].Enabled = f.on
    end)
    Script.Feature['Modder Detection Vehicle Godmode']:set_str_data({'Notify', 'Mark as Modder'})


    Script.Feature['Modder Detection Extended OTR'] = menu.add_feature('Extended Off The Radar', 'value_str', Script.Parent['local_modderdetection'].id, function(f)
        settings['Modder Detection Extended OTR'] = {Enabled = f.on, Value = f.value}
        local detected = {}

        while f.on do
            for id = 0, 31 do
                if utility.valid_modder(id) and get.PlayerCoords(id) ~= v3(0, 0, 0) and detected[id] == nil then
                    if scriptevent.IsPlayerOTR(id) and scriptevent.CEOID(id) == -1 then
                        detected[id] = true
                        menu.create_thread(function(target)
                            local time = utils.time_ms() + 70000
                            while time > utils.time_ms() and scriptevent.IsPlayerOTR(target) do
                                coroutine.yield(0)
                            end

                            if time < utils.time_ms() and utility.valid_modder(target) and scriptevent.IsPlayerOTR(target) and f.on then
                                if f.value == 0 then
                                    Notify('Player: ' .. get.Name(id) .. '\nReason: Extended Off The Radar\nReaction: Notify', "Neutral", '2Take1Script Modder Detection')
                                    coroutine.yield(60000)
                                else
                                    Log('Player: ' .. get.Name(target) .. '\nReason: Extended Off The Radar', '[Modder Detection]')
                                    player.mark_as_modder(target, customflags['Modded Off The Radar'])
                                end
                            end

                            detected[id] = nil
                        end, id)

                    elseif scriptevent.IsPlayerOTR(id) and scriptevent.CEOID(id) ~= -1 then
                        detected[id] = true
                        menu.create_thread(function(target)
                            local time = utils.time_ms() + 190000
                            while time > utils.time_ms() and scriptevent.IsPlayerOTR(target) do
                                coroutine.yield(0)
                            end

                            if time < utils.time_ms() and utility.valid_modder(target) and scriptevent.IsPlayerOTR(target) and f.on then
                                if f.value == 0 then
                                    Notify('Player: ' .. get.Name(id) .. '\nReason: Extended Off The Radar\nReaction: Notify', "Neutral", '2Take1Script Modder Detection')
                                    coroutine.yield(60000)
                                else
                                    Log('Player: ' .. get.Name(target) .. '\nReason: Extended Off The Radar', '[Modder Detection]')
                                    player.mark_as_modder(target, customflags['Modded Off The Radar'])
                                end
                            end
                            detected[id] = nil
                        end, id)
                    end
                end
            end

            settings['Modder Detection Extended OTR'].Value = f.value
            coroutine.yield(500)
        end
        settings['Modder Detection Extended OTR'].Enabled = f.on
    end)
    Script.Feature['Modder Detection Extended OTR']:set_str_data({'Notify', 'Mark as Modder'})


    Script.Feature['Modder Detection Undead OTR'] = menu.add_feature('Undead Off The Radar', 'value_str', Script.Parent['local_modderdetection'].id, function(f)
        settings['Modder Detection Undead OTR'] = {Enabled = f.on, Value = f.value}
        local detected = {}

        while f.on do
            for id = 0, 31 do
                if utility.valid_modder(id) and get.PlayerCoords(id) ~= v3(0, 0, 0) and detected[id] == nil then
                    if player.get_player_max_health(id) <= 100 then
                        detected[id] = true
                        menu.create_thread(function(target)
                            local time = utils.time_ms() + 60000
                            while time > utils.time_ms() and player.get_player_max_health(target) <= 100 do
                                coroutine.yield(0)
                            end

                            if time < utils.time_ms() and utility.valid_modder(target) and player.get_player_max_health(target) <= 100 and get.PlayerCoords(target) ~= v3(0, 0, 0) and f.on then
                                if f.value == 0 then
                                    Notify('Player: ' .. get.Name(id) .. '\nReason: Undead Off The Radar\nReaction: Notify', "Neutral", '2Take1Script Modder Detection')
                                    coroutine.yield(60000)
                                else
                                    Log('Player: ' .. get.Name(target) .. '\nReason: Undead Off The Radar', '[Modder Detection]')
                                    player.mark_as_modder(target, customflags['Modded Off The Radar'])
                                end
                            end
                            detected[id] = nil
                        end, id)
                    end
                end
            end

            settings['Modder Detection Undead OTR'].Value = f.value
            coroutine.yield(500)
        end
        settings['Modder Detection Undead OTR'].Enabled = f.on
    end)
    Script.Feature['Modder Detection Undead OTR']:set_str_data({'Notify', 'Mark as Modder'})


    Script.Feature['Modder Detection Max Speed'] = menu.add_feature('Max Speed Bypass', 'value_str', Script.Parent['local_modderdetection'].id, function(f)
        settings['Modder Detection Max Speed'] = {Enabled = f.on, Value = f.value}
        while f.on do
            for id = 0, 31 do
                if utility.valid_modder(id) then
                    local Entity
                    local MaxSpeed = 150
                    local Vehicle = get.PlayerVehicle(id)

                    if Vehicle ~= 0 then
                        Entity = Vehicle
                    else
                        Entity = get.PlayerPed(id)
                    end

                    local Speed = entity.get_entity_speed(Entity)

                    if Speed > MaxSpeed then
                        if f.value == 0 then
                            Notify('Player: ' .. get.Name(id) .. '\nReason: Max Speed Bypass\nReaction: Notify', "Neutral", '2Take1Script Modder Detection')
                            coroutine.yield(60000)
                        else
                            Log('Player: ' .. get.Name(id) .. '\nReason: Max Speed Bypass\nPlayer Speed: ' .. Speed * 3.6 .. 'Km/H', '[Modder Detection]')
                            player.mark_as_modder(id, customflags['Max Speed Bypass'])
                        end
                        
                    end

                end

            end

            settings['Modder Detection Max Speed'].Value = f.value
            coroutine.yield(0)
        end
        settings['Modder Detection Max Speed'].Enabled = f.on
    end)
    Script.Feature['Modder Detection Max Speed']:set_str_data({'Notify', 'Mark as Modder'})


    Script.Feature['Modder Detection Script Events'] = menu.add_feature('Modded Script Events', 'value_str', Script.Parent['local_modderdetection'].id, function(f)
        settings['Modder Detection Script Events'] = {Enabled = f.on, Value = f.value}
    end)
    Script.Feature['Modder Detection Script Events']:set_str_data({'v1', 'v2'})


    Script.Feature['Modder Detection Net Events'] = menu.add_feature('Bad Net Events', 'value_str', Script.Parent['local_modderdetection'].id, function(f)
        settings['Modder Detection Net Events'] = {Enabled = f.on, Value = f.value}
        while f.on do
            settings['Modder Detection Net Events'].Value = f.value
            coroutine.yield(100)
        end
        settings['Modder Detection Net Events'].Enabled = f.on
    end)
    Script.Feature['Modder Detection Net Events']:set_str_data({'Notify', 'Mark as Modder'})


    --[[
    Script.Feature['Modder Detection Profanity'] = menu.add_feature('Profanity Filter Bypass', 'value_str', Script.Parent['local_modderdetection'].id, function(f)
        settings['Modder Detection Profanity'] = {Enabled = f.on, Value = f.value}
        while f.on do
            settings['Modder Detection Profanity'].Value = f.value
            coroutine.yield(100)
        end
        settings['Modder Detection Profanity'].Enabled = f.on
    end)
    Script.Feature['Modder Detection Profanity']:set_str_data({'Notify', 'Mark as Modder'})
    ]]

    
    Script.Feature['Real Time'] = menu.add_feature('Real Time (Clientside)', 'toggle', Script.Parent['local_world'].id, function(f)
        settings['Real Time'] = {Enabled = f.on}
        while f.on do
            local Time = os.date('*t')

            time.set_clock_time(Time.hour, Time.min, Time.sec)
            gameplay.clear_cloud_hat()

            coroutine.yield(0)
        end
        settings['Real Time'].Enabled = f.on
    end)


    Script.Parent['Kill Aura'] = menu.add_feature('Kill Aura/Force Field', 'parent', Script.Parent['local_world'].id, nil)


    Script.Feature['Kill Aura Enable'] = menu.add_feature('Enable Kill Aura', 'value_str', Script.Parent['Kill Aura'].id, function(f)
        local running = {}
        local Done = 0

        while f.on do
            local Peds = ped.get_all_peds()
            for i = 1, #Peds do
                if (Peds[i] == get.OwnPed()) or (f.value == 1 and ped.is_ped_a_player(Peds[i])) or (f.value == 2 and not ped.is_ped_a_player(Peds[i])) then
                    goto continue
                end

                if not running[Peds[i]] or menu.has_thread_finished(running[Peds[i]]) then
                    running[Peds[i]] = menu.create_thread(Threads.Killaura, {Peds[i], Script.Feature['Kill Aura Range'].value, Script.Feature['Kill Aura Option'].value})
                end

                ::continue::

                Done = Done + 1
                if Done == 25 then
                    Done = 0
                    coroutine.yield(0)
                end
            end
            coroutine.yield(100)
        end
    end)
    Script.Feature['Kill Aura Enable']:set_str_data({'All Peds', 'Exclude Players', 'Players Only'})


    Script.Feature['Kill Aura Range'] = menu.add_feature('Range', 'autoaction_slider', Script.Parent['Kill Aura'].id, function(f)
        settings['Kill Aura Range'] = {Value = f.value}
    end)
    Script.Feature['Kill Aura Range'].min = 10
    Script.Feature['Kill Aura Range'].max = 100
    Script.Feature['Kill Aura Range'].mod = 5


    Script.Feature['Kill Aura Option'] = menu.add_feature('Option', 'autoaction_value_str', Script.Parent['Kill Aura'].id, function(f)
        settings['Kill Aura Option'] = {Value = f.value}
    end)
    Script.Feature['Kill Aura Option']:set_str_data({'Shoot', 'Explode'})


    Script.Feature['Force Field Enable'] = menu.add_feature('Enable Force Field', 'toggle', Script.Parent['Kill Aura'].id, function(f)
        settings['Force Field Enable'] = {Enabled = f.on}
        local running = {}
        local Done = 0

        while f.on do
            local Vehicles = vehicle.get_all_vehicles()

            for i = 1, #Vehicles do
                if Vehicles[i] == get.OwnVehicle() then
                    goto continue
                end

                if not running[Vehicles[i]] or menu.has_thread_finished(running[Vehicles[i]]) then
                    running[Vehicles[i]] = menu.create_thread(Threads.Forcefield, {Vehicles[i], Script.Feature['Force Field Range'].value, Script.Feature['Force Field Strength'].value})
                end

                ::continue::

                Done = Done + 1
                if Done == 25 then
                    Done = 0
                    coroutine.yield(0)
                end
            end

            coroutine.yield(0)
        end

        settings['Force Field Enable'].Enabled = f.on
    end)


    Script.Feature['Force Field Range'] = menu.add_feature('Range', 'autoaction_slider', Script.Parent['Kill Aura'].id, function(f)
        settings['Force Field Range'] = {Value = f.value}
    end)
    Script.Feature['Force Field Range'].min = 10
    Script.Feature['Force Field Range'].max = 100
    Script.Feature['Force Field Range'].mod = 5


    Script.Feature['Force Field Strength'] = menu.add_feature('Strength', 'autoaction_slider', Script.Parent['Kill Aura'].id, function(f)
        settings['Force Field Strength'] = {Value = f.value}
    end)
    Script.Feature['Force Field Strength'].min = 10
    Script.Feature['Force Field Strength'].max = 100
    Script.Feature['Force Field Strength'].mod = 5


    Script.Parent['Clear Area'] = menu.add_feature('Clear Area', 'parent', Script.Parent['local_world'].id, nil)


    Script.Feature['Delete All Peds'] = menu.add_feature('Clear Peds', 'slider', Script.Parent['Clear Area'].id, function(f)
        local running
        while f.on do
            
            if not running or menu.has_thread_finished(running) then
                menu.create_thread(Threads.Clearpeds, {ped.get_all_peds(), f.value})
            end

            coroutine.yield(0)
        end
    end)
    Script.Feature['Delete All Peds'].min = 50
    Script.Feature['Delete All Peds'].max = 500
    Script.Feature['Delete All Peds'].mod = 50


    Script.Feature['Delete All Vehicles'] = menu.add_feature('Clear Vehicles', 'slider', Script.Parent['Clear Area'].id, function(f)
        local running

        while f.on do
            if not running or menu.has_thread_finished(running) then
                running = menu.create_thread(Threads.Clearvehicles, {vehicle.get_all_vehicles(), f.value})

            end

            coroutine.yield(0)
        end
    end)
    Script.Feature['Delete All Vehicles'].min = 50
    Script.Feature['Delete All Vehicles'].max = 500
    Script.Feature['Delete All Vehicles'].mod = 50


    Script.Feature['Delete All Objects'] = menu.add_feature('Clear Objects', 'slider', Script.Parent['Clear Area'].id, function(f)
        ToggleOff({'Drive On Ocean', 'Drive This Height'})

        local running
        while f.on do
            if not running or menu.has_thread_finished(running) then
                running = menu.create_thread(Threads.Clearobjects, {object.get_all_objects(), f.value})
            end

            coroutine.yield(0)
        end
    end)
    Script.Feature['Delete All Objects'].min = 50
    Script.Feature['Delete All Objects'].max = 500
    Script.Feature['Delete All Objects'].mod = 50


    Script.Feature['Clear Area'] = menu.add_feature('Clear All Entities', 'slider', Script.Parent['Clear Area'].id, function(f)
        ToggleOff({'Drive On Ocean', 'Drive This Height'})

        local PedThread, VehicleThread, ObjectThread
        while f.on do

            if not PedThread or menu.has_thread_finished(PedThread) then
                PedThread = menu.create_thread(Threads.Clearpeds, {ped.get_all_peds(), f.value})

            end

            if not VehicleThread or menu.has_thread_finished(VehicleThread) then
                VehicleThread = menu.create_thread(Threads.Clearvehicles, {vehicle.get_all_vehicles(), f.value})

            end

            if not ObjectThread or menu.has_thread_finished(ObjectThread) then
                ObjectThread = menu.create_thread(Threads.Clearobjects, {object.get_all_objects(), f.value})

            end

            coroutine.yield(0)
        end
    end)
    Script.Feature['Clear Area'].min = 50
    Script.Feature['Clear Area'].max = 500
    Script.Feature['Clear Area'].mod = 50


    Script.Parent['Ped Manager'] = menu.add_feature('Ped Manager', 'parent', Script.Parent['local_world'].id, nil)


    Script.Feature['Explode All Peds'] = menu.add_feature('Explode All Peds', 'toggle', Script.Parent['Ped Manager'].id, function(f)
        while f.on do
            local AllPeds = ped.get_all_peds()

            for i = 1, #AllPeds do
                if not ped.is_ped_a_player(AllPeds[i]) and not entity.is_entity_dead(AllPeds[i]) then
                    local Position = entity.get_entity_coords(AllPeds[i])

                    fire.add_explosion(Position, 5, true, false, 0, 0)
                end

                coroutine.yield(25)
            end

            coroutine.yield(500)
        end
    end)


    Script.Feature['Kill All Peds'] = menu.add_feature('Kill All Peds', 'toggle', Script.Parent['Ped Manager'].id, function(f)
        while f.on do
            local AllPeds = ped.get_all_peds()

            for i = 1, #AllPeds do
                if not ped.is_ped_a_player(AllPeds[i]) and not entity.is_entity_dead(AllPeds[i]) then
                    utility.request_ctrl(AllPeds[i])

                    ped.set_ped_health(AllPeds[i], 0)
                end

            end

            coroutine.yield(500)
        end
    end)


    Script.Feature['Shoot All Peds'] = menu.add_feature('Shoot All Peds', 'toggle', Script.Parent['Ped Manager'].id, function(f)
        while f.on do
            local AllPeds = ped.get_all_peds()

            for i = 1, #AllPeds do
                if not ped.is_ped_a_player(AllPeds[i]) and not entity.is_entity_dead(AllPeds[i]) then
                    if ped.get_vehicle_ped_is_using(AllPeds[i]) ~= 0 then
                        ped.clear_ped_tasks_immediately(AllPeds[i])
                    end
                    local Position = entity.get_entity_coords(AllPeds[i])

                    gameplay.shoot_single_bullet_between_coords(Position + v3(0, 0, 1), Position, 1000, 0xC472FE2, get.OwnPed(), false, true, 1000)
                end

            end

            coroutine.yield(500)
        end
    end)


    Script.Feature['Freeze All Peds'] = menu.add_feature('Freeze All Peds', 'toggle', Script.Parent['Ped Manager'].id, function(f)
        while f.on do
            local AllPeds = ped.get_all_peds()

            for i = 1, #AllPeds do
                if not ped.is_ped_a_player(AllPeds[i]) then
                    utility.request_ctrl(AllPeds[i])

                    entity.freeze_entity(AllPeds[i], true)
                end

            end

            coroutine.yield(500)
        end

        local AllPeds = ped.get_all_peds()

        for i = 1, #AllPeds do
            if not ped.is_ped_a_player(AllPeds[i]) then
                utility.request_ctrl(AllPeds[i])

                entity.freeze_entity(AllPeds[i], false)
            end

        end
    end)


    Script.Feature['Turn All Peds Invisible'] = menu.add_feature('Turn All Peds Invisible', 'toggle', Script.Parent['Ped Manager'].id, function(f)
        while f.on do
            local AllPeds = ped.get_all_peds()

            for i = 1, #AllPeds do
                if not ped.is_ped_a_player(AllPeds[i]) then
                    utility.request_ctrl(AllPeds[i])

                    entity.set_entity_visible(AllPeds[i], false)
                end

            end

            coroutine.yield(500)
        end

        local AllPeds = ped.get_all_peds()

        for i = 1, #AllPeds do
            if not ped.is_ped_a_player(AllPeds[i]) then
                utility.request_ctrl(AllPeds[i])

                entity.set_entity_visible(AllPeds[i], true)
            end

        end
    end)


    Script.Feature['Turn All Peds Invincible'] = menu.add_feature('Turn All Peds Invincible', 'toggle', Script.Parent['Ped Manager'].id, function(f)
        while f.on do
            local AllPeds = ped.get_all_peds()

            for i = 1, #AllPeds do
                if not ped.is_ped_a_player(AllPeds[i]) then
                    utility.request_ctrl(AllPeds[i])

                    entity.set_entity_god_mode(AllPeds[i], true)
                end

            end

            coroutine.yield(500)
        end
        
        local AllPeds = ped.get_all_peds()

        for i = 1, #AllPeds do
            if not ped.is_ped_a_player(AllPeds[i]) then
                utility.request_ctrl(AllPeds[i])

                entity.set_entity_god_mode(AllPeds[i], false)
            end

        end
    end)


    Script.Feature['Street War'] = menu.add_feature('Street War', 'toggle', Script.Parent['Ped Manager'].id, function(f)
        if not menu.is_trusted_mode_enabled(1 << 2) then
            Notify('Not available while trusted mode for natives is turned off', 'Error', 'Street War')
            f.on = false
            return
        end

        while f.on do
            if not menu.is_trusted_mode_enabled(1 << 2) then
                f.on = false
            end

            N.MISC.SET_RIOT_MODE_ENABLED(true)

            coroutine.yield(100)
        end

        N.MISC.SET_RIOT_MODE_ENABLED(false)
    end)


    Script.Feature['Kick All Peds from Vehicle'] = menu.add_feature('Kick All Peds from Vehicle', 'action', Script.Parent['Ped Manager'].id, function(f)
        local AllPeds = ped.get_all_peds()

        for i = 1, #AllPeds do
            if not ped.is_ped_a_player(AllPeds[i]) and ped.get_vehicle_ped_is_using(AllPeds[i]) ~= 0 then
                utility.request_ctrl(AllPeds[i])

                ped.clear_ped_tasks_immediately(AllPeds[i])
            end

        end
    end)


    Script.Parent['Vehicle Manager'] = menu.add_feature('Vehicle Manager', 'parent', Script.Parent['local_world'].id, nil)


    Script.Feature['Explode All Vehicles'] = menu.add_feature('Explode All Vehicles', 'toggle', Script.Parent['Vehicle Manager'].id, function(f)
        while f.on do
            local AllVehicles = vehicle.get_all_vehicles()

            for i = 1, #AllVehicles do
                local Ped = vehicle.get_ped_in_vehicle_seat(AllVehicles[i], -1)

                if not ped.is_ped_a_player(Ped) and not vehicle.is_vehicle_damaged(AllVehicles[i]) then
                    local pos = entity.get_entity_coords(AllVehicles[i])

                    fire.add_explosion(pos, 5, true, false, 0, 0)
                end

                coroutine.yield(50)
            end

            coroutine.yield(500)
        end
    end)


    Script.Feature['Freeze All Vehicles'] = menu.add_feature('Freeze All Vehicles', 'toggle', Script.Parent['Vehicle Manager'].id, function(f)
        while f.on do
            local AllVehicles = vehicle.get_all_vehicles()

            for i = 1, #AllVehicles do
                local Ped = vehicle.get_ped_in_vehicle_seat(AllVehicles[i], -1)

                if not ped.is_ped_a_player(Ped) then
                    utility.request_ctrl(AllVehicles[i])

                    entity.freeze_entity(AllVehicles[i], true)
                end

            end

            coroutine.yield(500)
        end

        local AllVehicles = vehicle.get_all_vehicles()

        for i = 1, #AllVehicles do
            utility.request_ctrl(AllVehicles[i])

            entity.freeze_entity(AllVehicles[i], false)
        end
    end)


    Script.Feature['Turn All Vehicles Invisible'] = menu.add_feature('Turn All Vehicles Invisible', 'toggle', Script.Parent['Vehicle Manager'].id, function(f)
        while f.on do
            local AllVehicles = vehicle.get_all_vehicles()

            for i = 1, #AllVehicles do
                local Ped = vehicle.get_ped_in_vehicle_seat(AllVehicles[i], -1)

                if not ped.is_ped_a_player(Ped) then
                    utility.request_ctrl(AllVehicles[i])

                    entity.set_entity_visible(AllVehicles[i], false)
                end

            end

            coroutine.yield(500)
        end

        local AllVehicles = vehicle.get_all_vehicles()

        for i = 1, #AllVehicles do
            utility.request_ctrl(AllVehicles[i])

            entity.set_entity_visible(AllVehicles[i], true)
        end
    end)


    Script.Feature['Turn All Vehicles Invincible'] = menu.add_feature('Turn All Vehicles Invincible', 'toggle', Script.Parent['Vehicle Manager'].id, function(f)
        while f.on do
            local AllVehicles = vehicle.get_all_vehicles()

            for i = 1, #AllVehicles do
                local Ped = vehicle.get_ped_in_vehicle_seat(AllVehicles[i], -1)

                if not ped.is_ped_a_player(Ped) then
                    utility.request_ctrl(AllVehicles[i])

                    entity.set_entity_god_mode(AllVehicles[i], true)
                end

            end

            coroutine.yield(500)
        end

        local AllVehicles = vehicle.get_all_vehicles()

        for i = 1, #AllVehicles do
            utility.request_ctrl(AllVehicles[i])

            entity.set_entity_god_mode(AllVehicles[i], false)
        end
    end)


    Script.Feature['Upgrade Nearby Vehicles'] = menu.add_feature('Upgrade Nearby Vehicles', 'toggle', Script.Parent['Vehicle Manager'].id, function(f)
        local running = {}
        while f.on do
            local AllVehicles = vehicle.get_all_vehicles()

            for i = 1, #AllVehicles do
                local Ped = vehicle.get_ped_in_vehicle_seat(AllVehicles[i], -1)

                if not ped.is_ped_a_player(Ped) then
                    if not running[AllVehicles[i]] or menu.has_thread_finished(running[AllVehicles[i]]) then
                        if not vehicle.is_toggle_mod_on(AllVehicles[i], 18) then
                            running[AllVehicles[i]] = menu.create_thread(Threads.Upgradevehicles, AllVehicles[i])

                        end

                    end

                end

                coroutine.yield(0)
            end

            coroutine.yield(500)
        end
    end)
    

    Script.Feature['Display Vehicle Speed'] = menu.add_feature("Display Vehicle Speed", "value_str", Script.Parent['Vehicle Manager'].id, function(f)
        settings['Display Vehicle Speed'] = {Enabled = f.on, Value = f.value}
        while f.on do
            local AllVehicles = vehicle.get_all_vehicles()
            local OwnPosition = player.get_player_coords(Self())

            for i=1,#AllVehicles do
                if AllVehicles[i] ~= get.OwnVehicle() then
                    local Vehicle = AllVehicles[i]
                    local VehiclePosition = entity.get_entity_coords(Vehicle)
                    local Magnitude = OwnPosition:magnitude(VehiclePosition)

                    if Magnitude < 50 then
                        local Success, ScreenPos = graphics.project_3d_coord(VehiclePosition)

                        if Success then
                            ScreenPos.x = scriptdraw.pos_pixel_to_rel_x(ScreenPos.x)
                            ScreenPos.y = scriptdraw.pos_pixel_to_rel_y(ScreenPos.y)
                            
                            local Speed = entity.get_entity_speed(Vehicle)
                            local Type
                            local Text

                            if f.value == 0 then
                                Type = Speed * 3.6
                                Text = ' KM/H'

                            elseif f.value == 1 then
                                Type = Speed * 2.23694
                                Text = ' MP/H'
                            end

                            if Math.Round(Type, 2) ~= 0.0 then
                                scriptdraw.draw_text(Math.Round(Type, 2) .. Text, ScreenPos, v2(), 0.8 - 0.5 * (Magnitude / 50), 0xFFFFFFFF, 1 << 0 | 1 << 2, newFont)
                            end
                        end
                    end
                end
            end
            settings['Display Vehicle Speed'].Value = f.value
            coroutine.yield(0)
        end
        settings['Display Vehicle Speed'].Enabled = f.on
    end)
    Script.Feature['Display Vehicle Speed']:set_str_data({'KM/H', 'MP/H'})


    Script.Feature['Change Gravity'] = menu.add_feature('Change Gravity', 'slider', Script.Parent['Vehicle Manager'].id, function(f)
        while f.on do
            local AllVehicles = vehicle.get_all_vehicles()
            
            for i = 1, #AllVehicles do
                local Ped = vehicle.get_ped_in_vehicle_seat(AllVehicles[i], -1)

                if not ped.is_ped_a_player(Ped) then
                    utility.request_ctrl(AllVehicles[i])

                    vehicle.set_vehicle_gravity_amount(AllVehicles[i], f.value)

                    if entity.get_entity_speed(AllVehicles[i]) == 0 then
                        vehicle.set_vehicle_forward_speed(AllVehicles[i], 1)
                    end
                end

            end
            
            coroutine.yield(500)
        end

        local AllVehicles = vehicle.get_all_vehicles()

        for i = 1, #AllVehicles do
            utility.request_ctrl(AllVehicles[i])

            vehicle.set_vehicle_gravity_amount(AllVehicles[i], 10)
        end
    end)
    Script.Feature['Change Gravity'].min = -100
    Script.Feature['Change Gravity'].max = 100
    Script.Feature['Change Gravity'].mod = 25
    Script.Feature['Change Gravity'].value = 0


    Script.Feature['Disable Collision with Vehicles'] = menu.add_feature('Disable Collision with Vehicles', 'toggle', Script.Parent['Vehicle Manager'].id, function(f)
        local running
        while f.on do
            local Entity
            local OwnVehicle = get.OwnVehicle()
            
            if OwnVehicle ~= 0 then
                Entity = OwnVehicle
            else
                Entity = get.OwnPed()
            end

            if not running or menu.has_thread_finished(running) then
                running =  menu.create_thread(Threads.Vehiclecollision, {vehicle.get_all_vehicles(), Entity})

            end

            coroutine.yield(0)
        end
    end)


    Script.Feature['Set Traffic Out Of Control'] = menu.add_feature('Set Traffic Out Of Control', 'toggle', Script.Parent['Vehicle Manager'].id, function(f)
        while f.on do
            local AllVehicles = vehicle.get_all_vehicles()

            for i = 1, #AllVehicles do
                local Ped = vehicle.get_ped_in_vehicle_seat(AllVehicles[i], -1)

                if not ped.is_ped_a_player(Ped) then
                    utility.request_ctrl(AllVehicles[i])

                    vehicle.set_vehicle_forward_speed(AllVehicles[i], 40)
                    vehicle.set_vehicle_out_of_control(AllVehicles[i], false, false)
                end

            end

            coroutine.yield(100)
        end
    end)


    Script.Parent['Object Manager'] = menu.add_feature('Object Manager', 'parent', Script.Parent['local_world'].id, nil)


    Script.Feature['Turn All Objects Invisible'] = menu.add_feature('Turn All Objects Invisible', 'toggle', Script.Parent['Object Manager'].id, function(f)
        while f.on do
            local AllObjects = object.get_all_objects()

            for i = 1, #AllObjects do
                utility.request_ctrl(AllObjects[i])

                entity.set_entity_visible(AllObjects[i], false)
            end

            coroutine.yield(500)
        end

        local AllObjects = object.get_all_objects()

        for i = 1, #AllObjects do
            utility.request_ctrl(AllObjects[i])

            entity.set_entity_visible(AllObjects[i], true)
        end
    end)


    Script.Feature['Make All Objects Indestructible'] = menu.add_feature('Make All Objects Indestructible', 'toggle', Script.Parent['Object Manager'].id, function(f)
        while f.on do
            local AllObjects = object.get_all_objects()

            for i = 1, #AllObjects do
                utility.request_ctrl(AllObjects[i])

                entity.set_entity_god_mode(AllObjects[i], true)
                entity.freeze_entity(AllObjects[i], true)
            end

            coroutine.yield(500)
        end

        local AllObjects = object.get_all_objects()

        for i = 1, #AllObjects do
            utility.request_ctrl(AllObjects[i])

            entity.set_entity_god_mode(AllObjects[i], false)
            entity.freeze_entity(AllObjects[i], false)
        end
    end)


    Script.Feature['Disable Collision with Objects'] = menu.add_feature('Disable Collision with Objects', 'toggle', Script.Parent['Object Manager'].id, function(f)
        local running
        while f.on do
            local Entity
            local OwnVehicle = get.OwnVehicle()

            if OwnVehicle ~= 0 then
                Entity = OwnVehicle
            else
                Entity = get.OwnPed()
            end

            if not running or menu.has_thread_finished(running) then
                running =  menu.create_thread(Threads.Objectcollision, {object.get_all_objects(), Entity})

            end

            coroutine.yield(0)
        end
    end)


    Script.Feature['Auto Collect Pickups'] = menu.add_feature('Auto Collect Pickups', 'toggle', Script.Parent['Object Manager'].id, function(f)
        settings['Auto Collect Pickups'] = {Enabled = f.on}
        while f.on do
            local AllPickups = object.get_all_pickups()

            for i = 1, #AllPickups do
                entity.set_entity_coords_no_offset(AllPickups[i], get.OwnCoords())

                coroutine.yield(0)
            end

            coroutine.yield(500)
        end
        settings['Auto Collect Pickups'].Enabled = f.on
    end)


    Script.Feature['Collect all Pickups'] = menu.add_feature('Collect all Pickups', 'action', Script.Parent['Object Manager'].id, function() 
        local AllPickups = object.get_all_pickups()

        if #AllPickups == 0 then
            Notify('No Pickups found.', "Error", '')

        else
            for i = 1, #AllPickups do
                entity.set_entity_coords_no_offset(AllPickups[i], get.OwnCoords())

                coroutine.yield(0)
            end

        end
    end)


    Script.Feature['Remove all Pickups'] = menu.add_feature('Remove all Pickups', 'action', Script.Parent['Object Manager'].id, function()
        local AllPickups = object.get_all_pickups()

        if #AllPickups == 0 then
            Notify('No Pickups found.', "Error", '')

        else
            utility.clear(AllPickups)
        end
    end)
    

    Script.Feature['Disable Collision with Entites'] = menu.add_feature('Disable Collision with Entites', 'toggle', Script.Parent['local_world'].id, function(f)
        ToggleOff({'Disable Collision with Vehicles', 'Disable Collision with Objects', 'Drive On Ocean', 'Drive This Height'})
        settings['Disable Collision with Entites'] = {Enabled = f.on}

        local running1, running2

        while f.on do
            local Entity
            local OwnVehicle = get.OwnVehicle()
            if OwnVehicle ~= 0 then
                Entity = OwnVehicle
            else
                Entity = get.OwnPed()
            end
            
            if not running1 or menu.has_thread_finished(running1) then
                running1 = menu.create_thread(Threads.Vehiclecollision, {vehicle.get_all_vehicles(), Entity})

            end

            if not running2 or menu.has_thread_finished(running2) then
                running2 = menu.create_thread(Threads.Objectcollision, {object.get_all_objects(), Entity})

            end
            
            coroutine.yield(0)
        end
        settings['Disable Collision with Entites'].Enabled = f.on
    end)


    Script.Feature['Bouncy Water'] = menu.add_feature('Bouncy Water', 'toggle', Script.Parent['local_world'].id, function(f)
        settings['Bouncy Water'] = {Enabled = f.on}
        while f.on do
            local ent = get.OwnVehicle()
            if utility.valid_vehicle(ent) then
                
                if entity.is_entity_in_water(ent) then
                    local rotation = entity.get_entity_rotation(ent)

                    if (rotation.y > 90 or rotation.y < -90) and (rotation.x > 90 or rotation.x < -90) then
                        entity.set_entity_rotation(ent, v3(math.random(-50, 50), math.random(-50, 50), rotation.z))
                        
                    elseif (rotation.y > 90 or rotation.y < -90)  then
                        entity.set_entity_rotation(ent, v3(rotation.x, math.random(-50, 50), rotation.z))

                    elseif (rotation.x > 90 or rotation.x < -90) then
                        entity.set_entity_rotation(ent, v3(math.random(-50, 50), rotation.y, rotation.z))

                    end
                    entity.apply_force_to_entity(ent, 1, 0, 0, 5.0, 0, 0, 0, true, true, true, true, false, true)
                end
            else
                ent = get.OwnPed()
                if entity.is_entity_in_water(ent) then
                    ped.set_ped_to_ragdoll(get.OwnPed(), 1, 1, 0)
                    entity.apply_force_to_entity(ent, 1, math.random(-2, 2), math.random(-2, 2), 5.0, 0, 0, 0, true, true, true, true, false, true)
                end
            end

            coroutine.yield(0)
        end
        settings['Bouncy Water'].Enabled = f.on
    end)


    Script.Feature['Drive On Ocean'] = menu.add_feature('Drive / Walk on the Ocean', 'toggle', Script.Parent['local_world'].id, function(f)
        if Script.Feature['Disable Collision with Entites'].on or Script.Feature['Disable Collision with Objects'].on then
            Notify('This doesnt work while disabling collision with objects.', nil, '')
            f.on = false
            return
        end

        if Script.Feature['Clear Area'].on or Script.Feature['Delete All Objects'].on then
            Notify('This doesnt work while constantly deleting all objects.', nil, '')
            f.on = false
            return
        end

        settings['Drive On Ocean'] = {Enabled = f.on}
        while f.on do
            local Position = get.OwnCoords()

            if OceanEntity == nil then
                OceanEntity = Spawn.Object(1822550295, v3(Position.x, Position.y, -4))

                entity.set_entity_visible(OceanEntity, false)
            end

            water.set_waves_intensity(-100000000)

            Position.z = -5
            utility.set_coords(OceanEntity, Position)

            coroutine.yield(0)
        end

        if OceanEntity then
            water.reset_waves_intensity()

            utility.clear({OceanEntity})
            OceanEntity = nil
        end

        settings['Drive On Ocean'].Enabled = f.on
    end)


    Script.Feature['Drive This Height'] = menu.add_feature('Drive / Walk this Height', 'toggle', Script.Parent['local_world'].id, function(f)
        if Script.Feature['Disable Collision with Entites'].on or Script.Feature['Disable Collision with Objects'].on then
            Notify('This doesnt work while disabling collision with objects.', nil, '')
            f.on = false
            return
        end

        if Script.Feature['Clear Area'].on or Script.Feature['Delete All Objects'].on then
            Notify('This doesnt work while constantly deleting all objects.', nil, '')
            f.on = false
            return
        end

        settings['Drive This Height'] = {Enabled = f.on}
        while f.on do
            local Position, Offset

            if ped.is_ped_in_any_vehicle(get.OwnPed()) then
                local veh = get.OwnVehicle()

                Position = entity.get_entity_coords(veh)
                Offset = 5.25

            else
                Position = get.OwnCoords()
                Offset = 5.85
            end

            if HeightEntity == nil then
                FixedHeight = Position.z - Offset
                HeightEntity = Spawn.Object(1822550295, v3(Position.x, Position.y, FixedHeight))

                entity.set_entity_visible(HeightEntity, false)
            end

            water.set_waves_intensity(-100000000)

            Position.z = FixedHeight
            utility.set_coords(HeightEntity, Position)

            coroutine.yield(0)
        end
        
        if HeightEntity then
            water.reset_waves_intensity()

            utility.clear({HeightEntity})
            HeightEntity = nil
            FixedHeight = nil
        end

        settings['Drive This Height'].Enabled = f.on
    end)


    Script.Feature['Reset Orbital-Cannon Cooldown'] = menu.add_feature('Reset Orbital-Cannon Cooldown', 'action', Script.Parent['local_stats'].id, function()
        Math.SetIntStat('ORBITAL_CANNON_COOLDOWN', true, 0)
    end)


    Script.Feature['Disable Orbital-Cannon Cooldown'] = menu.add_feature('Disable Orbital-Cannon Cooldown', 'toggle', Script.Parent['local_stats'].id, function(f)
        settings['Disable Orbital-Cannon Cooldown'] = {Enabled = f.on}

        while f.on do
            Math.SetIntStat('ORBITAL_CANNON_COOLDOWN', true, 0)

            coroutine.yield(2000)
        end

        settings['Disable Orbital-Cannon Cooldown'].Enabled = f.on
    end)


    Script.Feature['Unlock all Achievements'] = menu.add_feature('Unlock all Achievements', 'action', Script.Parent['local_stats'].id, function()
        if not menu.is_trusted_mode_enabled(1 << 2) then
            Notify('Not available while trusted mode for natives is turned off', 'Error', 'Unlock Achievements')
            return
        end

        for i = 0, 77 do
            N.PLAYER.GIVE_ACHIEVEMENT_TO_PLAYER(i)
        end
        Notify('Unlocked all Achievements.', "Success", 'Unlock Achievements')
        Log('Unlocked all Achievements.')
    end)

    
    Script.Feature['Transfer Money'] = menu.add_feature('Transfer Money', 'action_value_str', Script.Parent['local_stats'].id, function(f)
        if not menu.is_trusted_mode_enabled(1 << 2) then
            Notify('Not available while trusted mode for natives is turned off', 'Error', 'Transfer Money')
            return
        end

        local slot, wallet, bank
        if N.NETSHOPPING._NET_GAMESERVER_IS_SESSION_VALID(0) then
            slot = 0

        elseif N.NETSHOPPING._NET_GAMESERVER_IS_SESSION_VALID(1) then
            slot = 1

        else
            Notify('Cant transfer money at the moment.', 'Error', 'Transfer Money')
            return
        end
        
        wallet = tonumber(N.MONEY.NETWORK_GET_STRING_WALLET_BALANCE(slot):sub(2))
        bank = tonumber(N.MONEY.NETWORK_GET_STRING_BANK_BALANCE():sub(2))

        if f.value == 0 then
            if wallet == 0 then
                Notify('Nothing to deposit', 'Error', 'Transfer Money')
                return
            end

            N.NETSHOPPING._NET_GAMESERVER_TRANSFER_WALLET_TO_BANK(slot, wallet)
        elseif f.value == 1 then
            if bank == 0 then
                Notify('Nothing to withdraw', 'Error', 'Transfer Money')
                return
            end

            N.NETSHOPPING._NET_GAMESERVER_TRANSFER_BANK_TO_WALLET(slot, bank)

        elseif f.value == 2 then
            local value = tonumber(get.Input('Enter the amount of money you want to deposit', 10, 3))

            if not value then
                Notify('Input canceled.', "Error", 'Transfer Money')
                return
            end

            if value == 0 then
                Notify('Cant deposit 0', "Error", 'Transfer Money')
                return
            end

            if value > wallet then
                Notify('Cant deposit more than you have.', "Error", 'Transfer Money')
                return
            end

            N.NETSHOPPING._NET_GAMESERVER_TRANSFER_WALLET_TO_BANK(slot, value)

        elseif f.value == 3 then
            local value = tonumber(get.Input('Enter the amount of money you want to withdraw', 10, 3))

            if not value then
                Notify('Input canceled.', "Error", 'Transfer Money')
                return
            end

            if value == 0 then
                Notify('Cant withdraw 0', "Error", 'Transfer Money')
                return
            end

            if value > bank then
                Notify('Cant withdraw more than you have.', "Error", 'Transfer Money')
                return
            end

            N.NETSHOPPING._NET_GAMESERVER_TRANSFER_BANK_TO_WALLET(slot, value)
        end
    end)
    Script.Feature['Transfer Money']:set_str_data({'All to Bank', 'All to Wallet', 'Input to Bank', 'Input to Wallet'})


    --[[
    Script.Feature['Bounty Claim Loop'] = menu.add_feature('Bounty Claim Loop', 'toggle', Script.Parent['local_stats'].id, function(f)
        while f.on do
            scriptevent.Send('Bounty', {Self(), Self(), 1, 10000, 0, f.value,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, scriptevent.GlobalPair()}, script.get_host_of_this_script())
            
            coroutine.yield(1000)
            menu.get_feature_by_hierarchy_key('online.services.claim_own_bounty'):toggle()

            coroutine.yield(15000)
        end
    end)
    ]]
    

    Script.Feature['Ped Dropper'] = menu.add_feature('Ped Dropper (Delay in ms)', 'slider', Script.Parent['local_stats'].id, function(f)
        if not menu.is_trusted_mode_enabled(1 << 2) then
            Notify('Not available while trusted mode for natives is turned off', 'Error', 'Ped Dropper')
            f.on = false
            return
        end

        while f.on do
            if not menu.is_trusted_mode_enabled(1 << 2) then
                f.on = false
            end

            local Coords = get.OwnCoords()
            local Ped = Spawn.Ped(695248020, Coords + v3(0, 0, 1))
            N.PED.SET_PED_MONEY(Ped, 2000)
        
            entity.set_entity_visible(Ped, false)
            ped.set_ped_health(Ped, 0)
        
            coroutine.yield(100)
            utility.clear({Ped})

            coroutine.yield(1000 - math.floor(f.value))
        end
    end)
    Script.Feature['Ped Dropper'].min = 0
    Script.Feature['Ped Dropper'].max = 1000
    Script.Feature['Ped Dropper'].mod = 100


    Script.Feature['Fill Snacks and Armor'] = menu.add_feature('Fill Snacks and Armor', 'action', Script.Parent['local_stats'].id, function()
        local Hashes = stathashes['snacks_and_armor']

        for i = 1, #Hashes do
            Math.SetIntStat(Hashes[i][1], true, Hashes[i][2])
        end

        Notify('Filled Inventory with Snacks and Armor.', "Success")
        Log('Filled Inventory with Snacks and Armor.')
    end)


    Script.Feature['Fill Business Clutter'] = menu.add_feature('Fill Business Clutter', 'action_value_str', Script.Parent['local_stats'].id, function(f)
        if f.value == 0 then
            local Hashes = stathashes['ceo_earnings']

            for i = 1, #Hashes do
                Math.SetIntStat(Hashes[i][1], true, Hashes[i][2])
            end
        else
            local Hashes = stathashes['mc_earnings']

            for i = 1, #Hashes do
                Math.SetIntStat(Hashes[i][1], true, Hashes[i][2])
            end
        end

        Notify('Filled Business with Clutter\nFinish a legit Sell Mission to show Effect.', "Success")
    end)
    Script.Feature['Fill Business Clutter']:set_str_data({'CEO', 'MC'})


    Script.Feature['Set KD (Kills / Death)'] = menu.add_feature('Set KD (Kills / Death)', 'action', Script.Parent['local_stats'].id, function()
        local KD = get.Input('Enter KD (Kills / Death)', 10, 5)

        if not KD then
            Notify('Input canceled.', "Error", '')
            return
        end

        KD = tonumber(KD)
        local Hashes = stathashes['kills_deaths']
        local Multiplier = math.random(1000, 2000)
        local Kills = math.floor(KD * Multiplier)
        local Deaths = math.floor(Kills / KD)

        Log('Setting Stat ' .. Hashes[1] .. ' to: ' .. Kills .. '\nSetting Stat ' .. Hashes[2] .. ' to: ' .. Deaths)

        Math.SetIntStat(Hashes[1], false, Kills)
        Math.SetIntStat(Hashes[2], false, Deaths)

        Notify('New KD set. To update the KD, earn a legit kill or death.', "Success")
    end)


    Script.Feature['Unlock Xmas Liveries'] = menu.add_feature('Unlock Xmas Liveries', 'action', Script.Parent['local_stats'].id, function()
        local Hashes = stathashes['xmas']

        for i = 1, #Hashes do
            Math.SetIntStat(Hashes[i][1], false, -1)
        end

        Notify('Xmas Liveries Unlocked.', "Success")
    end)


    Script.Feature['Unlock Fast-Run Ability'] = menu.add_feature('Unlock Fast-Run Ability', 'action', Script.Parent['local_stats'].id, function()
        local Hashes = stathashes['fast_run']

        for i = 1, #Hashes do
            Math.SetIntStat(Hashes[i], true, -1)
        end

        Notify('New Ability set, Change Lobby to show Effect.', "Success")
    end)


    local pericostats = stathashes['perico']

    Script.Parent['Casino Heist Stats'] = menu.add_feature('Casino Heist', 'parent', Script.Parent['local_stats'].id, nil)


    Script.Feature['Reset Heist'] = menu.add_feature('Reset Heist', 'action', Script.Parent['Casino Heist Stats'].id, function()
        local Hashes = stathashes['chc']['board2']
        for i = 1, #Hashes do
            Math.SetIntStat(Hashes[i][2], true, Hashes[i][3])
        end
        
        Hashes = stathashes['chc']['board1']
        for i = 1, #Hashes do
            Math.SetIntStat(Hashes[i][2], true, Hashes[i][3])
        end

        Hashes = stathashes['chc']['misc']
        for i = 1, #Hashes do
            Math.SetIntStat(Hashes[i][2], true, Hashes[i][3])
        end

        Notify('Casino Heist reset.', "Success")
    end)


    Script.Feature['Heist Quick Start'] = menu.add_feature('Quick Start', 'action_value_str', Script.Parent['Casino Heist Stats'].id, function(f)
        local Hashes = stathashes['chc']['misc']

        if f.value == 0 then
            Math.SetIntStat(Hashes[1][2], true, Hashes[1][4])
            Math.SetIntStat(Hashes[2][2], true, Hashes[2][4])

            Hashes = stathashes['chc']['board1']
            for i = 1, #Hashes do
                local value = Hashes[i][4]
                if Hashes[i][5] then
                    value = math.random(Hashes[i][4], Hashes[i][5])
                end
                Math.SetIntStat(Hashes[i][2], true, value)
            end

            Hashes = stathashes['chc']['misc']
            Math.SetIntStat(Hashes[3][2], true, Hashes[3][4])

            Hashes = stathashes['chc']['board2']
            for i = 1, #Hashes do
                local value = Hashes[i][4]
                if Hashes[i][5] then
                    value = math.random(Hashes[i][4], Hashes[i][5])
                end
                Math.SetIntStat(Hashes[i][2], true, value)
            end

            Hashes = stathashes['chc']['misc']
            Math.SetIntStat(Hashes[4][2], true, Hashes[4][4])
            Notify('Casino Heist set up with random execution. If you dont like it, Reset Heist and try again.', "Success")
        else
            Math.SetIntStat(Hashes[1][2], true, Hashes[1][4])
            Math.SetIntStat(Hashes[2][2], true, Hashes[2][4])

            Hashes = stathashes['chc']['board1']
            for i = 1, #Hashes do
                local value = Hashes[i][6] or Hashes[i][4]
                Math.SetIntStat(Hashes[i][2], true, value)
            end

            Hashes = stathashes['chc']['misc']
            Math.SetIntStat(Hashes[3][2], true, Hashes[3][4])

            Hashes = stathashes['chc']['board2']
            for i = 1, #Hashes do
                local value = Hashes[i][6] or Hashes[i][4]
                if #Hashes[i] == 5 then
                    value = math.random(Hashes[i][4], Hashes[i][5])
                end
                Math.SetIntStat(Hashes[i][2], true, Hashes[i][4])
            end

            Hashes = stathashes['chc']['misc']
            Math.SetIntStat(Hashes[4][2], true, Hashes[4][4])

            Notify('Casino Heist set up with highest Payout. If you dont like it, Reset Heist and try again.', "Success")
        end
    end)
    Script.Feature['Heist Quick Start']:set_str_data({'Random', 'Highest Payout'})


    Script.Parent['First Board'] = menu.add_feature('First Board', 'parent', Script.Parent['Casino Heist Stats'].id, nil)


    Script.Feature['Reset last Approach'] = menu.add_feature('Reset last Approach', 'action', Script.Parent['First Board'].id, function()
        local Hashes = stathashes['chc']['misc']
        Math.SetIntStat(Hashes[1][2], true, Hashes[1][4])
        Math.SetIntStat(Hashes[2][2], true, Hashes[2][4])
    end)


    Script.Feature['Unlock Casino POI'] = menu.add_feature('Unlock Points of Interests', 'action', Script.Parent['First Board'].id, function()
        local Hashes = stathashes['chc']['board1']
        Math.SetIntStat(Hashes[4][2], true, Hashes[4][4])
    end)


    Script.Feature['Unlock Access Points'] = menu.add_feature('Unlock Access Points', 'action', Script.Parent['First Board'].id, function()
        local Hashes = stathashes['chc']['board1']
        Math.SetIntStat(Hashes[5][2], true, Hashes[5][4])
    end)


    Script.Feature['Set Approach'] = menu.add_feature('Set Approach', 'action_value_str', Script.Parent['First Board'].id, function(f)
        local Hashes = stathashes['chc']['board1']

        if f.value == 0 then
            Math.SetIntStat(Hashes[1][2], true, f.value + 1)
        end

        if f.value == 1 then
            Math.SetIntStat(Hashes[1][2], true, f.value + 1)
        end

        if f.value == 2 then
            Math.SetIntStat(Hashes[1][2], true, f.value + 1)
        end
    end)
    Script.Feature['Set Approach']:set_str_data({'Silent', 'Big Con', 'Aggressive'})


    Script.Feature['Set Last Approach'] = menu.add_feature('Set Last Approach', 'action_value_str', Script.Parent['First Board'].id, function(f)
        local Hashes = stathashes['chc']['board1']

        Math.SetIntStat(Hashes[2][2], true, f.value + 1)
    end)
    Script.Feature['Set Last Approach']:set_str_data({'Silent', 'Big Con', 'Aggressive'})


    Script.Feature['Set Target'] = menu.add_feature('Set Target', 'action_value_str', Script.Parent['First Board'].id, function(f)
        local Hashes = stathashes['chc']['board1']
        Math.SetIntStat(Hashes[3][2], true, f.value)
    end)
    Script.Feature['Set Target']:set_str_data({'Money', 'Gold', 'Art', 'Diamonds'})


    Script.Feature['Confirm First Board'] = menu.add_feature('Confirm First Board', 'action', Script.Parent['First Board'].id, function()
        local Hashes = stathashes['chc']['misc']
        Math.SetIntStat(Hashes[3][2], true, Hashes[3][4])
    end)


    Script.Parent['Second Board'] = menu.add_feature('Second Board', 'parent', Script.Parent['Casino Heist Stats'].id, nil)


    Script.Feature['Weapon Member Payout'] = menu.add_feature('Choose Gunman', 'action_value_str', Script.Parent['Second Board'].id, function(f)
        local Hashes = stathashes['chc']['board2']
        Math.SetIntStat(Hashes[1][2], true, f.value + 1)
    end)
    Script.Feature['Weapon Member Payout']:set_str_data({'Karl Abolaji (5%)', 'Gustavo Mota (9%)', 'Charlie Reed (7%)', 'Chester Mccoy (10%)', 'Patrick Mcreary (8%)'})


    Script.Feature['Driver Payout'] = menu.add_feature('Choose Driver', 'action_value_str', Script.Parent['Second Board'].id, function(f)
        local Hashes = stathashes['chc']['board2']
        Math.SetIntStat(Hashes[2][2], true, f.value + 1)
    end)
    Script.Feature['Driver Payout']:set_str_data({'Karim Denz (5%)', 'Taliana Martinez (7%)', 'Eddie Toh (9%)', 'Zach Nelson (6%)', 'Chester Mccoy (10%)'})


    Script.Feature['Hacker Payout'] = menu.add_feature('Choose Hacker', 'action_value_str', Script.Parent['Second Board'].id, function(f)
        local Hashes = stathashes['chc']['board2']
        Math.SetIntStat(Hashes[3][2], true, f.value + 1)
    end)
    Script.Feature['Hacker Payout']:set_str_data({'Rickie Lukens (3%)', 'Christian Feltz (7%)', 'Yohan Blair (5%)', 'Avi Schwartzman (10%)', 'Paige Harris (9%)'})


    Script.Feature['Weapon Variation'] = menu.add_feature('Weapon Variation', 'action_value_str', Script.Parent['Second Board'].id, function(f)
        local Hashes = stathashes['chc']['board2']
        Math.SetIntStat(Hashes[4][2], true, f.value)
    end)
    Script.Feature['Weapon Variation']:set_str_data({'01/02', '02/02'})


    Script.Feature['Vehicle Variation'] = menu.add_feature('Vehicle Variation', 'action_value_str', Script.Parent['Second Board'].id, function(f)
        local Hashes = stathashes['chc']['board2']
        Math.SetIntStat(Hashes[5][2], true, f.value)
    end)
    Script.Feature['Vehicle Variation']:set_str_data({'01/04', '02/04', '03/04', '04/04'})


    Script.Feature['Remove Duggan Heavy Guards'] = menu.add_feature('Remove Duggan Heavy Guards', 'action', Script.Parent['Second Board'].id, function()
        local Hashes = stathashes['chc']['board2']
        Math.SetIntStat(Hashes[6][2], true, Hashes[6][4])
    end)


    Script.Feature['Equip Heavy Armor'] = menu.add_feature('Equip Heavy Armor', 'action', Script.Parent['Second Board'].id, function()
        local hashes = stathashes['chc']['board2']
        Math.SetIntStat(hashes[7][2], true, hashes[7][4])
    end)


    Script.Feature['Unlock Scan Cards'] = menu.add_feature('Unlock Scan Cards', 'action', Script.Parent['Second Board'].id, function()
        local Hashes = stathashes['chc']['board2']
        Math.SetIntStat(Hashes[8][2], true, Hashes[8][4])
    end)


    Script.Feature['Confirm Second Board'] = menu.add_feature('Confirm Second Board', 'action', Script.Parent['Second Board'].id, function()
        local Hashes = stathashes['chc']['misc']
        Math.SetIntStat(Hashes[4][2], true, Hashes[4][4])
    end)


    Script.Parent['Cayo Perico Stats'] = menu.add_feature('Cayo Perico Heist', 'parent', Script.Parent['local_stats'].id, nil)


    Script.Feature['Reset Perico Heist'] = menu.add_feature('Reset Heist', 'action', Script.Parent['Cayo Perico Stats'].id, function()
        local Hashes = pericostats

        for i = 4, 18 do
            Math.SetIntStat(Hashes[i][2], true, 0)
        end

        Math.SetIntStat(Hashes[12][2], true, 110154)
        Notify('Perico Heist has been reset.', "Success")
    end)


    Script.Feature['Perico Heist Unlocks'] = menu.add_feature('Unlocks', 'action_value_str', Script.Parent['Cayo Perico Stats'].id, function(f)
        local hashes = pericostats
        if f.value == 0 then
            Math.SetIntStat(hashes[1][2], true, hashes[1][4])
        elseif f.value == 1 then
            Math.SetIntStat(hashes[2][2], true, hashes[2][4])
        elseif f.value == 2 then
            Math.SetIntStat(hashes[10][2], true, hashes[10][4])
        else
            Math.SetIntStat(hashes[3][2], true, hashes[3][4])
        end
    end)
    Script.Feature['Perico Heist Unlocks']:set_str_data({'Points of Interests', 'Entry Points', 'Escape Points', 'Support Team'})

    
    Script.Feature['Perico Primary Target'] = menu.add_feature('Primary Target', 'action_value_str', Script.Parent['Cayo Perico Stats'].id, function(f)
        local hashes = pericostats
        Math.SetIntStat(hashes[8][2], true, f.value)
    end)
    Script.Feature['Perico Primary Target']:set_str_data({'Tequila', 'Ruby', 'Bearer Bonds', 'Pink Diamond', 'Madrazo Files', 'Panther Statue'})


    Script.Feature['Perico Secondary Loot'] = menu.add_feature('Mansion Loot', 'action_value_str', Script.Parent['Cayo Perico Stats'].id, function(f)
        local hashes = pericostats

        if f.value == 0 then
            Math.SetIntStat(hashes[13][2], true, hashes[13][4])
            Math.SetIntStat(hashes[14][2], true, hashes[14][4])
            Math.SetIntStat(hashes[15][2], true, hashes[15][4])
            Math.SetIntStat(hashes[16][2], true, hashes[16][4])
            Math.SetIntStat(hashes[17][2], true, hashes[17][4])
            Math.SetIntStat(hashes[18][2], true, hashes[18][4])
            Notify('Secondary Loot set for 1 Player', "Success")

        elseif f.value == 1 then
            Math.SetIntStat(hashes[13][2], true, hashes[13][5])
            Math.SetIntStat(hashes[14][2], true, hashes[14][5])
            Math.SetIntStat(hashes[15][2], true, hashes[15][5])
            Math.SetIntStat(hashes[16][2], true, hashes[16][5])
            Math.SetIntStat(hashes[17][2], true, hashes[17][5])
            Math.SetIntStat(hashes[18][2], true, hashes[18][5])
            Notify('Secondary Loot set for 2 Players.\nPlayer Cuts: 50% Each', "Success")

        elseif f.value == 2 then
            Math.SetIntStat(hashes[13][2], true, hashes[13][5])
            Math.SetIntStat(hashes[14][2], true, hashes[14][5])
            Math.SetIntStat(hashes[15][2], true, hashes[15][5])
            Math.SetIntStat(hashes[16][2], true, hashes[16][6])
            Math.SetIntStat(hashes[17][2], true, hashes[17][5])
            Math.SetIntStat(hashes[18][2], true, hashes[18][6])
            Notify('Secondary Loot set for 3 Players.\nPlayer Cuts: Host 30%, Other Players 35%', "Success")

        elseif f.value == 3 then
            Math.SetIntStat(hashes[13][2], true, hashes[13][5])
            Math.SetIntStat(hashes[14][2], true, hashes[14][5])
            Math.SetIntStat(hashes[15][2], true, hashes[15][5])
            Math.SetIntStat(hashes[16][2], true, hashes[16][7])
            Math.SetIntStat(hashes[17][2], true, hashes[17][5])
            Math.SetIntStat(hashes[18][2], true, hashes[18][7])
            Notify('Secondary Loot set for 4 Players.\nPlayer Cuts: 25% Each', "Success")
        end
    end)
    Script.Feature['Perico Secondary Loot']:set_str_data({'1 Player', '2 Players', '3 Players', '4 Players'})


    Script.Feature['Perico Weapon Variation'] = menu.add_feature('Weapon Variation', 'action_value_str', Script.Parent['Cayo Perico Stats'].id, function(f)
        local hashes = pericostats
        Math.SetIntStat(hashes[4][2], true, f.value + 1)
    end)
    Script.Feature['Perico Weapon Variation']:set_str_data({'Aggressor', 'Conspirator', 'Crackshot', 'Saboteur', 'Marksman'})


    Script.Feature['Perico Disruptions'] = menu.add_feature('Enable Disruptions', 'action', Script.Parent['Cayo Perico Stats'].id, function(f)
        local hashes = pericostats

        Math.SetIntStat(hashes[5][2], true, hashes[5][4])
        Math.SetIntStat(hashes[6][2], true, hashes[6][4])
        Math.SetIntStat(hashes[7][2], true, hashes[7][4])
    end)


    Script.Feature['Truck Spawn Place'] = menu.add_feature('Truck Spawn Place', 'action_value_str', Script.Parent['Cayo Perico Stats'].id, function(f)
        local hashes = pericostats
        Math.SetIntStat(hashes[9][2], true, f.value + 1)
    end)
    Script.Feature['Truck Spawn Place']:set_str_data({'Airport', 'North Dock', 'East Main Dock', 'West Main Dock', 'Compound'})


    Script.Feature['Perico Difficulty'] = menu.add_feature('Set Difficulty', 'action_value_str', Script.Parent['Cayo Perico Stats'].id, function(f)
        local hashes = pericostats
        local dif

        if f.value == 0 then
            dif = hashes[12][4]
        else
            dif = hashes[12][5]
        end

        Math.SetIntStat(hashes[12][2], true, dif)
    end)
    Script.Feature['Perico Difficulty']:set_str_data({'Normal', 'Hard'})


    Script.Feature['Perico Missions Completed'] = menu.add_feature('Set Missions as completed', 'action', Script.Parent['Cayo Perico Stats'].id, function()
        local hashes = pericostats
        Math.SetIntStat(hashes[11][2], true, hashes[11][4])
    end)


    Script.Parent['Delete Outifts'] = menu.add_feature('Delete Custom Outfits', 'parent', Script.Parent['local_misc'].id, function()
        if not Script.Feature['Disable Warning Messages'].on then
            Notify('Be aware that deleting the outfits cant be reverted.', "Neutral")
        end

        local outfits = utils.get_all_files_in_directory(paths['ModdedOutfits'] .. '\\', 'ini')
        local entries = Script.Parent['Delete Outifts'].children

        for i = 1, #outfits do
            local add = true
            for y = 1, #entries do
                if entries[y].name == outfits[i] then
                    add = false
                end
            end
            if add then
                menu.add_feature(outfits[i], 'action', Script.Parent['Delete Outifts'].id, function(f)
                        if utils.file_exists(paths['ModdedOutfits'] .. '\\' .. outfits[i]) then
                            if io.remove(paths['ModdedOutfits'] .. '\\' .. outfits[i]) then
                                Log('Deleted Outfit: ' .. outfits[i])
                                return HANDLER_CONTINUE
                            end
                            Notify('ERROR deleting the file, try again.', "Error")
                            return
                        end
                    menu.delete_feature(f.id)
                end)
            end
        end
    end)
    
    Script.Parent['Delete Vehicles'] = menu.add_feature('Delete Custom Vehicles', 'parent', Script.Parent['local_misc'].id, function()
        if not Script.Feature['Disable Warning Messages'].on then
            Notify('Be aware that deleting the vehicles cant be reverted.', "Neutral")
        end

        local vehicles = utils.get_all_files_in_directory(paths['ModdedVehicles'] .. '\\', 'ini')
        local entries = Script.Parent['Delete Vehicles'].children

        for i = 1, #vehicles do
            local add = true
            for y = 1, #entries do
                if entries[y].name == vehicles[i] then
                    add = false
                end
            end
            if add then
                menu.add_feature(vehicles[i], 'action', Script.Parent['Delete Vehicles'].id, function(f)
                        if utils.file_exists(paths['ModdedVehicles'] .. '\\' .. vehicles[i]) then
                            if io.remove(paths['ModdedVehicles'] .. '\\' .. vehicles[i]) then
                                Log('Deleted Vehicle: ' .. vehicles[i])
                                return HANDLER_CONTINUE
                            end
                            Notify('ERROR deleting the file, try again.', "Error")
                            return
                        end
                    menu.delete_feature(f.id)
                end)
            end
        end
    end)


    Script.Parent['Heist Helper'] = menu.add_feature('Heist Helper', 'parent', Script.Parent['local_misc'].id, nil)
    

    Script.Feature['Remove Heist Enemies'] = menu.add_feature('Remove Enemies', 'value_str', Script.Parent['Heist Helper'].id, function(f)
        while f.on do
            local AllPeds = ped.get_all_peds()

            for i = 1, #AllPeds do
                local Hash = entity.get_entity_model_hash(AllPeds[i])

                if Hash == 0x1EEAAD1F or Hash == 0x8D8F1B10 or Hash == 0xBEC82CA5 or Hash == 0xA217F345 or Hash == 0x1422D45B or Hash == 2127932792 or Hash == 1821116645 or Hash == 193469166 then
                    if f.value == 1 and not entity.is_entity_dead(AllPeds[i]) then
                        ped.set_ped_health(AllPeds[i], 0)

                    elseif f.value == 2 and not entity.is_entity_dead(AllPeds[i]) then
                        local Position = entity.get_entity_coords(AllPeds[i])

                        ped.clear_ped_tasks_immediately(AllPeds[i])
                        gameplay.shoot_single_bullet_between_coords(Position + v3(0, 0, 1), Position, 1000, 0xC472FE2, get.OwnPed(), false, true, 1000)
                    else
                        utility.clear({AllPeds[i]})
                    end
                end

                coroutine.yield(0)
            end

            coroutine.yield(250)
        end
    end)
    Script.Feature['Remove Heist Enemies']:set_str_data({'Delete', 'Kill', 'Shoot'})


    Script.Feature['Remove Heist Cameras'] = menu.add_feature("Remove Cameras", 'toggle', Script.Parent['Heist Helper'].id, function(f)
        while f.on do
            local AllCams = object.get_all_objects()

            for i = 1, #AllCams do
                local Hash = entity.get_entity_model_hash(AllCams[i])

                if Hash == 4121760380 or Hash == 3061645218 or Hash == 548760764 or Hash == 2135655372 then
                    utility.clear({AllCams[i]})
                end

                coroutine.yield(0)
            end

            coroutine.yield(250)
        end
    end)


    Script.Parent['Casino Heist Helper'] = menu.add_feature('Casino Heist', 'parent', Script.Parent['Heist Helper'].id, nil)


    Script.Feature['Teleport to Boards'] = menu.add_feature('Teleport to Boards', 'action', Script.Parent['Casino Heist Helper'].id, function()
        utility.tp(v3(2712.885, -369.604, -54.781), 1, -173.626159)
    end)


    Script.Feature['Teleport to Arcade'] = menu.add_feature('Teleport in front of Arcade', 'action_value_str', Script.Parent['Casino Heist Helper'].id, function(f)
        if f.value == 0 then
            utility.tp(v3(-618.422, 282.105, 81.661), 1, 0)

        elseif f.value == 1 then
            utility.tp(v3(-240.276, 6231.523, 31.5), 1, 0)

        elseif f.value == 2 then
            utility.tp(v3(1710.239, 4755.552, 41.968), 1, 0)

        elseif f.value == 3 then
            utility.tp(v3(-1289.597, -272.637, 38.934), 1, 0)

        elseif f.value == 4 then
            utility.tp(v3(-101.949, -1774.834, 29.503), 1, 0)

        else
            utility.tp(v3(722.069, -822.387, 24.694), 1, 0)
        end
    end)
    Script.Feature['Teleport to Arcade']:set_str_data({'West Vinewood', 'Paleto Bay', 'Grapeseed', 'Rockford Hills', 'Davis', 'La Mesa'})


    Script.Feature['Teleport to Casino Entrance'] = menu.add_feature('Teleport to Casino Entrance', 'action_value_str', Script.Parent['Casino Heist Helper'].id, function(f)
        if f.value == 0 then
            utility.tp(v3(915.411, 52.702, 80.899), 1, -106.415)

        elseif f.value == 1 then
            utility.tp(v3(977.744, 3.755, 81.149), 1, -4.723)

        elseif f.value == 2 then
            utility.tp(v3(1002.153, 86.149, 80.990), 1, 142.887)

        elseif f.value == 3 then
            utility.tp(v3(1031.371, -268.223, 50.855), 1, -1.479)

            coroutine.yield(2000)

            utility.tp(v3(995.416, -149.775, 34.597), 1, -1.479)

        elseif f.value == 4 then
            utility.tp(v3(998.007, -56.651, 74.959), 1, -1.479)
        end
    end)
    Script.Feature['Teleport to Casino Entrance']:set_str_data({'Main Door', 'Staff Lobby', 'Waste Disposal', 'Sewer Tunnel', 'Security Tunnel'})


    Script.Feature['Casino Vault Teleports'] = menu.add_feature('Vault Teleports', 'action_value_str', Script.Parent['Casino Heist Helper'].id, function(f)
        if f.value == 0 then
            utility.tp(v3(2467.166, -279.148, -70.694), 1, 0)

        elseif f.value == 1 then
            utility.tp(v3(2498.584, -238.633, -70.737), 1, 0)

        elseif f.value == 2 then
            utility.tp(v3(2516.404, -238.635, -70.737), 1, 0)
        end
    end)
    Script.Feature['Casino Vault Teleports']:set_str_data({'Key Card Door', 'Vault Entrance', 'Inside Vault'})


    Script.Parent['Perico Heist Helper'] = menu.add_feature('Cayo Perico Heist', 'parent', Script.Parent['Heist Helper'].id, nil)


    Script.Feature['Teleport To Submarine'] = menu.add_feature("Teleport to own Submarine", 'action', Script.Parent['Perico Heist Helper'].id, function()
        local AllVehicles = vehicle.get_all_vehicles()

        for i = 1, #AllVehicles do
            local Vehicle = AllVehicles[i]
            local Interior = decorator.decor_get_int(Vehicle, "Player_Submarine")

            if Interior ~= 0 then
                local Position = entity.get_entity_coords(Vehicle)
                Position.z = 2

                local Heading = entity.get_entity_heading(Vehicle)
                utility.tp(utility.OffsetCoords(Position, Heading, 40), 3, Heading - 180)

                return
            end

        end

        Notify('Submarine not found.', "Error")
    end)


    Script.Feature['Teleport To Heist Table'] = menu.add_feature("Teleport to Heist-Table", 'action', Script.Parent['Perico Heist Helper'].id, function()
        utility.tp(v3(1561.042, 385.902, -49.685), 1, -178.7576)
    end)


    Script.Feature['Perico Entrance Points'] = menu.add_feature('Mansion Entrance Points', 'action_value_str', Script.Parent['Perico Heist Helper'].id, function(f)
        if f.value == 0 then
            utility.tp(v3(4964.224, -5691.346, 20.114), 1, -149.524)

        elseif f.value == 1 then
            utility.tp(v3(5034.285, -5682.308, 19.877), 1, 141.606)

        elseif f.value == 2 then
            utility.tp(v3(5087.291, -5729.972, 15.772), 1, 138.499)

        elseif f.value == 3 then
            utility.tp(v3(4991.473, -5811.451, 20.881), 1, -18.034)

        elseif f.value == 4 then
            utility.tp(v3(4957.278, -5784.729, 20.838), 1, -91.732)

        else
            utility.tp(v3(5044.107, -5816.188, -11.397), 1, 34.794)
        end
    end)
    Script.Feature['Perico Entrance Points']:set_str_data({'Main Gate', 'North Wall', 'North Gate', 'South Wall', 'South Gate', 'Drainage Tunnel'})


    Script.Feature['Perico Mansion Loot Locations'] = menu.add_feature('Mansion Loot Locations', 'action_value_str', Script.Parent['Perico Heist Helper'].id, function(f)
        if f.value == 0 then
            utility.tp(v3(5006.799, -5756.157, 15.484), 1, 140.548)

        elseif f.value == 1 then
            utility.tp(v3(5082.638, -5756.555, 15.829), 1, 48.199)

        elseif f.value == 2 then
            utility.tp(v3(5008.708, -5786.344, 17.831), 1, 97.236)
            
        elseif f.value == 3 then
            utility.tp(v3(5029.218, -5735.711, 17.865), 1, 137.546)

        elseif f.value == 4 then
            utility.tp(v3(5000.238, -5749.091, 14.840), 1, 123.632)

        else
            utility.tp(v3(5009.167, -5752.860, 28.845), 1, -122.300)
        end
    end)
    Script.Feature['Perico Mansion Loot Locations']:set_str_data({'Main Target', 'House 1', 'House 2', 'House 3', 'Underground Loot', 'El Rubios Office'})


    Script.Feature['Perico Mansion Escape Points'] = menu.add_feature('Mansion Escape Points', 'action_value_str', Script.Parent['Perico Heist Helper'].id, function(f)
        if f.value == 0 then
            utility.tp(v3(4991.798, -5719.567, 19.880), 1, 41.611)

        elseif f.value == 1 then
            utility.tp(v3(5029.085, -5688.222, 19.877), 1, -48.452)

        elseif f.value == 2 then
            utility.tp(v3(5084.531, -5738.770, 15.677), 1, 54.853)

        elseif f.value == 3 then
            utility.tp(v3(4995.140, -5803.547, 20.877), 1, 139.820)

        elseif f.value == 4 then
            utility.tp(v3(4965.731, -5786.062, 20.877), 1, 155.017)
        end
    end)
    Script.Feature['Perico Mansion Escape Points']:set_str_data({'Main Gate', 'North Wall', 'North Gate', 'South Wall', 'South Gate'})


    Script.Feature['Perico Escape Points'] = menu.add_feature('Perico Escape Points', 'action_value_str', Script.Parent['Perico Heist Helper'].id, function(f)
        if f.value == 0 then
            utility.tp(v3(4947.979, -5169.805, 2.526), 1, -23.566)

        elseif f.value == 1 then
            utility.tp(v3(5130.842, -4632.660, 1.442), 1, 173.827)

        elseif f.value == 2 then
            utility.tp(v3(4488.520, -4466.0366, 4.225), 1, 59.993)

        else
            utility.tp(v3(4321.404, -3933.961, -20.377), 1, 49.476)
        end
    end)
    Script.Feature['Perico Escape Points']:set_str_data({'Main Dock', 'North Dock', 'Airstrip', 'Kosatka'})


    Script.Feature['Perico Misc Locations'] = menu.add_feature('Misc Locations', 'action_value_str', Script.Parent['Perico Heist Helper'].id, function(f)
        if f.value == 0 then
            utility.tp(v3(4477.896, -4579.448, 5.567), 1, -172.023)

        elseif f.value == 1 then
            utility.tp(v3(4363.452, -4566.825, 4.207), 1, -157.731)
        end
    end)
    Script.Feature['Perico Misc Locations']:set_str_data({'Power Station', 'Control Tower'})


    Script.Parent['Disable Stuff'] = menu.add_feature('Disable Stuff', 'parent', Script.Parent['local_misc'].id, nil)


    Script.Feature['Disable Stunt Jumps'] = menu.add_feature('Disable Stunt Jumps', 'toggle', Script.Parent['Disable Stuff'].id, function(f)
        if not menu.is_trusted_mode_enabled(1 << 2) then
            Notify('Not available while trusted mode for natives is turned off', 'Error', 'Disable Stunt Jumps')
            f.on = false
            return
        end

        settings['Disable Stunt Jumps'] = {Enabled = f.on}
        while f.on do
            if not menu.is_trusted_mode_enabled(1 << 2) then
                f.on = false
            end

            N.MISC.SET_STUNT_JUMPS_CAN_TRIGGER(0)
        
            coroutine.yield(1000)
        end

        N.MISC.SET_STUNT_JUMPS_CAN_TRIGGER(1)
        settings['Disable Stunt Jumps'].Enabled = f.on
    end)


    Script.Feature['Disable Shark Card Store'] = menu.add_feature('Disable Shark Card Store', 'toggle', Script.Parent['Disable Stuff'].id, function(f)
        if not menu.is_trusted_mode_enabled(1 << 2) then
            Notify('Not available while trusted mode for natives is turned off', 'Error', 'Disable Shark Card Store')
            f.on = false
            return
        end

        settings['Disable Shark Card Store'] = {Enabled = f.on}
        while f.on do
            if not menu.is_trusted_mode_enabled(1 << 2) then
                f.on = false
            end

            N.NETWORK.SET_STORE_ENABLED(0)
        
            coroutine.yield(1000)
        end

        N.NETWORK.SET_STORE_ENABLED(1)
        settings['Disable Shark Card Store'].Enabled = f.on
    end)


    Script.Feature['Disable First Person Mode'] = menu.add_feature('Disable First Person Mode', 'toggle', Script.Parent['Disable Stuff'].id, function(f)
        if not menu.is_trusted_mode_enabled(1 << 2) then
            Notify('Not available while trusted mode for natives is turned off', 'Error', 'Disable First Person')
            f.on = false
            return
        end

        settings['Disable First Person Mode'] = {Enabled = f.on}
        while f.on do
            if not menu.is_trusted_mode_enabled(1 << 2) then
                f.on = false
            end

            N.CAM._DISABLE_FIRST_PERSON_CAM_THIS_FRAME()
            N.CAM._DISABLE_VEHICLE_FIRST_PERSON_CAM_THIS_FRAME()

            coroutine.yield(0)
        end
        settings['Disable First Person Mode'].Enabled = f.on
    end)


    Script.Feature['Disable Multiplayer Chat'] = menu.add_feature('Disable Multiplayer Chat', 'toggle', Script.Parent['Disable Stuff'].id, function(f)
        if not menu.is_trusted_mode_enabled(1 << 2) then
            Notify('Not available while trusted mode for natives is turned off', 'Error', 'Disable Multiplayer Chat')
            f.on = false
            return
        end

        settings['Disable Multiplayer Chat'] = {Enabled = f.on}
        while f.on do
            if not menu.is_trusted_mode_enabled(1 << 2) then
                f.on = false
            end

            N.HUD._DISABLE_MULTIPLAYER_CHAT(true)

            coroutine.yield(0)
        end
        settings['Disable Multiplayer Chat'].Enabled = f.on
    end)


    Script.Parent['Entity Spawner'] = menu.add_feature('Entity Spawner', 'parent', Script.Parent['local_misc'].id, nil)


    Script.Parent['Spawn Ped'] = menu.add_feature('Spawn Ped', 'action', Script.Parent['Entity Spawner'].id, function()
        local _input = get.Input("Enter ped model name or hash")
        if not _input then
            Notify('Input canceled.', 'Error', 'Entity Spawner')
            return 
        end
        local hash = _input
        if not tonumber(_input) then
            hash = gameplay.get_hash_key(_input)
        end
        if not streaming.is_model_a_ped(hash) then
            Notify('Invalid Input!', 'Error', 'Entity Spawner')
            return 
        end
        local pos = get.OwnCoords()
        Spawn.Ped(hash, utility.OffsetCoords(pos, get.OwnHeading(), 5))
    end)
    

    Script.Parent['Spawn Vehicle'] = menu.add_feature('Spawn Vehicle', 'action', Script.Parent['Entity Spawner'].id, function()
        local _input = get.Input("Enter vehicle model name or hash")
        if not _input then
            Notify('Input canceled.', 'Error', 'Entity Spawner')
            return 
        end
        local hash = _input
        if not tonumber(_input) then
            hash = gameplay.get_hash_key(_input)
        end
        if not streaming.is_model_a_vehicle(hash) then
            Notify('Invalid Input!', 'Error', 'Entity Spawner')
            return 
        end
        local pos = get.OwnCoords()
        local veh = Spawn.Vehicle(hash, utility.OffsetCoords(pos, get.OwnHeading(), 5))
        utility.request_ctrl(veh)
        decorator.decor_set_int(veh, 'MPBitset', 1 << 10)
    end)


    Script.Parent['Spawn Object'] = menu.add_feature('Spawn Object', 'action', Script.Parent['Entity Spawner'].id, function()
        local _input = get.Input("Enter object model name or hash")
        if not _input then
            Notify('Input canceled.', 'Error', 'Entity Spawner')
            return 
        end
        local hash = _input
        if not tonumber(_input) then
            hash = gameplay.get_hash_key(_input)
        end
        if not streaming.is_model_an_object(hash) then
            Notify('Invalid Input!', 'Error', 'Entity Spawner')
            return 
        end
        local pos = get.OwnCoords()
        Spawn.Object(hash, utility.OffsetCoords(pos, get.OwnHeading(), 5))
    end)


    Script.Parent['Spawn World Object'] = menu.add_feature('Spawn World Object', 'action', Script.Parent['Entity Spawner'].id, function()
        local _input = get.Input("Enter world object model name or hash")
        if not _input then
            Notify('Input canceled.', 'Error', 'Entity Spawner')
            return 
        end
        local hash = _input
        if not tonumber(_input) then
            hash = gameplay.get_hash_key(_input)
        end
        if not streaming.is_model_a_world_object(hash) then
            Notify('Invalid Input!', 'Error', 'Entity Spawner')
            return 
        end
        local pos = get.OwnCoords()
        Spawn.Worldobject(hash, utility.OffsetCoords(pos, get.OwnHeading(), 5))
    end)


    Script.Parent['Disable HUD Components'] = menu.add_feature('Hide HUD Elements', 'parent', Script.Parent['local_misc'].id, nil)


    Script.Feature['Disable Mini-Map'] = menu.add_feature('Disable All + Minimap', 'toggle', Script.Parent['Disable HUD Components'].id, function(f)
        while f.on do
            ui.hide_hud_and_radar_this_frame()

            coroutine.yield(0)
        end
    end)


    for i = 1, #miscdata.hudcomponents do
        Script.Feature[miscdata.hudcomponents[i][1]] = menu.add_feature(miscdata.hudcomponents[i][1], 'toggle', Script.Parent['Disable HUD Components'].id, function(f)
            while f.on do
                ui.hide_hud_component_this_frame(miscdata.hudcomponents[i][2])

                coroutine.yield(0)
            end
        end)
    end


    Script.Feature['Teleport High In Air'] = menu.add_feature('Teleport High in Air', 'action', Script.Parent['local_misc'].id, function()
        local pos = get.OwnCoords() + v3(0, 0, 5000)
        
        utility.tp(pos)
    end)


    Script.Feature['Teleport Forward'] = menu.add_feature('Teleport Forward', 'action', Script.Parent['local_misc'].id, function()
        local veh = get.OwnVehicle()
        if veh ~= 0 then
            local speed = entity.get_entity_speed(veh)
            utility.set_coords(veh, utility.OffsetCoords(get.OwnCoords(), get.OwnHeading(), 8))
            vehicle.set_vehicle_forward_speed(veh, speed)
        else
            utility.set_coords(get.OwnPed(), utility.OffsetCoords(get.OwnCoords(), get.OwnHeading(), 8))
        end
    end)


    Script.Feature['Auto TP Waypoint'] = menu.add_feature('Auto TP to Waypoint', 'toggle', Script.Parent['local_misc'].id, function(f)
        settings['Auto TP Waypoint'] = {Enabled = f.on}
        while f.on do
            local waypoint = ui.get_waypoint_coord()
            if waypoint.x ~= 16000 then
                if not network.is_session_started() then
                    local pos = get.OwnCoords()
                    local v2pos = v2()
                    v2pos.x = pos.x
                    v2pos.y = pos.y
                    if waypoint:magnitude(v2pos) > 35 then
                        local ground = Math.GetGroundZ(waypoint.x, waypoint.y)
                        utility.tp(v3(waypoint.x, waypoint.y, ground))
                    end
                    return
                end
                local target = get.OwnPed()
                if get.OwnVehicle() ~= 0 then
                    target = get.OwnVehicle()
                end
                local height = 1000
                entity.set_entity_coords_no_offset(target, v3(waypoint.x, waypoint.y, height))
                local success, ground = gameplay.get_ground_z(v3(waypoint.x, waypoint.y, height))
                while not success and height > 100 do
                    height = height - 5
                    entity.set_entity_coords_no_offset(target, v3(waypoint.x, waypoint.y, height))
                    success, ground = gameplay.get_ground_z(v3(waypoint.x, waypoint.y, height))
                end
                if height <= 100 then
                    height = 0
                    local success, ground = gameplay.get_ground_z(v3(waypoint.x, waypoint.y, height))
                    while not success and height < 1000 do
                        height = height + 10
                        success, ground = gameplay.get_ground_z(v3(waypoint.x, waypoint.y, height))
                    end
                end
                if utility.request_ctrl(target, 5000) then
                    entity.set_entity_coords_no_offset(target, v3(waypoint.x, waypoint.y, ground + 1))
                end
            end
            coroutine.yield(0)
        end
        settings['Auto TP Waypoint'].Enabled = f.on
    end)


    Script.Feature['Weird Entity'] = menu.add_feature('Weird Entity', 'toggle', Script.Parent['local_misc'].id, function(f)
        settings['Weird Entity'] = {Enabled = f.on}

        while f.on do
            local veh = get.OwnVehicle()
            local ent = get.OwnPed()

            if utility.valid_vehicle(veh) and not balll then
                local hash = entity.get_entity_model_hash(veh)

                balll = Spawn.Vehicle(hash, get.OwnCoords())

                utility.SetVehicleMods(balll, utility.GetVehicleMods(veh))

                ent = veh

            elseif not balll then
                balll = ped.clone_ped(get.OwnPed())
            end

            entity.set_entity_visible(ent, false)
            entity.set_entity_collision(balll, false, false, false)
            entity.set_entity_rotation(balll, v3(math.random(-180, 180), math.random(-180, 180), math.random(-180, 180)))
            utility.set_coords(balll, get.OwnCoords())

            coroutine.yield(0)
        end
        
        utility.clear({balll})
        balll = nil

        entity.set_entity_visible(get.OwnPed(), true)
        entity.set_entity_visible(get.OwnVehicle(), true)
        settings['Weird Entity'].Enabled = f.on
    end)


    Script.Feature['Anti-Crash Cam'] = menu.add_feature('Anti-Crash Cam', 'toggle', Script.Parent['local_misc'].id, function(f)
        settings['Anti-Crash Cam'] = {Enabled = f.on}
        local pos = get.OwnCoords()

        while f.on do
            entity.set_entity_coords_no_offset(get.OwnPed(), v3(-8292.664, -4596.8257, 14358.0))

            coroutine.yield(0)
        end
        
        entity.set_entity_coords_no_offset(get.OwnPed(), pos)
        settings['Anti-Crash Cam'].Enabled = f.on
    end)
    

    Script.Feature['Leave Online'] = menu.add_feature('Leave Online', 'action', Script.Parent['local_misc'].id, function()
        if not menu.is_trusted_mode_enabled(1 << 2) then
            Notify('Not available while trusted mode for natives is turned off', 'Error', 'Leave Online')
            return
        end

        if not N.NETWORK.NETWORK_CAN_BAIL() then
            Notify('Cant bail right now.', 'Error', '')
            return
        end

        N.NETWORK.NETWORK_BAIL()
    end)


    Script.Feature['Lag out of Session'] = menu.add_feature('Lag out of Session', 'action', Script.Parent['local_misc'].id, function()
        if not network.is_session_started() then
            local time = utils.time_ms() + 8500
            while time > utils.time_ms() do
            end
        end
        
    end)


    Script.Parent['Session Display'] = menu.add_feature('Session Info Display', 'parent', Script.Parent['local_settings'].id)


    Script.Parent['Session Display Settings'] = menu.add_feature('Settings', 'parent', Script.Parent['Session Display'].id)


    Script.Feature['Session Display X'] = menu.add_feature('Position X', 'autoaction_slider', Script.Parent['Session Display Settings'].id, function(f)

    end)
    Script.Feature['Session Display X'].min = -1
    Script.Feature['Session Display X'].max = 1
    Script.Feature['Session Display X'].mod = 0.01
    Script.Feature['Session Display X'].value = -0.99


    Script.Feature['Session Display Y'] = menu.add_feature('Position Y', 'autoaction_slider', Script.Parent['Session Display Settings'].id, function(f)

    end)
    Script.Feature['Session Display Y'].min = -1
    Script.Feature['Session Display Y'].max = 1
    Script.Feature['Session Display Y'].mod = 0.01
    Script.Feature['Session Display Y'].value = 0.8


    Script.Feature['Session Display Size'] = menu.add_feature('Size', 'autoaction_slider', Script.Parent['Session Display Settings'].id, function(f)

    end)
    Script.Feature['Session Display Size'].min = 0
    Script.Feature['Session Display Size'].max = 1
    Script.Feature['Session Display Size'].mod = 0.05
    Script.Feature['Session Display Size'].value = 0.7


    Script.Feature['Session Display Enable'] = menu.add_feature('Enable', 'toggle', Script.Parent['Session Display'].id, function(f)
        settings['Session Display Enable'] = {Enabled = f.on}
        while f.on do
            if network.is_session_started() then
                local modders = 0
                for i = 0, 31 do
                    if player.is_player_valid(i) and player.is_player_modder(i, -1) then
                        modders = modders + 1
                    end
                end

                local friends = 0
                for i = 0, 31 do
                    if player.is_player_valid(i) and player.is_player_friend(i) then
                        friends = friends + 1
                    end
                end

                local content = ""
                if Script.Feature['Session Display General'].on then
                    content = content .. "Players: " .. player.player_count() .. "\n"..
                    "Modders: " .. modders .. "\n" ..
                    "Friends: " .. friends .. "\n" ..
                    "Session Host: " .. get.Name(player.get_host()) .. "\n" ..
                    "Script Host: " .. get.Name(script.get_host_of_this_script()) .. "\n"
                end

                if Script.Feature['Session Display Typing'].on then
                    content = content .. "\nTyping: \n"
                    for i = 0, 31 do
                        if player.is_player_valid(i) then
                            local name = get.Name(i)
                            local isTyping
                            for i = 1, #typingplayers do
                                if typingplayers[i] == name then
                                    isTyping = true
                                end
                            end
                            if isTyping then
                                content = content .. name .. "\n"
                            end
                        end
                    end
                end

                if Script.Feature['Session Display Spectating'].on then
                    content = content .. "\nSpectating: \n"
                    for i = 0, 31 do
                        if player.is_player_valid(i) and network.get_player_player_is_spectating(i) ~= nil then
                            local name = get.Name(i)
                            content = content .. name .. " -> " .. get.Name(network.get_player_player_is_spectating(i)) .. "\n"
                        end
                    end
                end

                scriptdraw.draw_text(content, v2(Script.Feature['Session Display X'].value, Script.Feature['Session Display Y'].value), v2(1, 1), Script.Feature['Session Display Size'].value, Math.RGBAToInt(255, 255, 255, 255), TextFlags["SHADOW"], newFont)
            end
            
            coroutine.yield(0)
        end
        settings['Session Display Enable'].Enabled = f.on
    end)


    Script.Feature['Session Display General'] = menu.add_feature('General Info', 'toggle', Script.Parent['Session Display'].id, function(f)
        settings['Session Display General'] = {Enabled = f.on}
    end)


    Script.Feature['Session Display Typing'] = menu.add_feature('Typing Players', 'toggle', Script.Parent['Session Display'].id, function(f)
        settings['Session Display Typing'] = {Enabled = f.on}
    end)


    Script.Feature['Session Display Spectating'] = menu.add_feature('Spectating Players', 'toggle', Script.Parent['Session Display'].id, function(f)
        settings['Session Display Spectating'] = {Enabled = f.on}
    end)


    Script.Parent['Log Settings'] = menu.add_feature('Log Settings', 'parent', Script.Parent['local_settings'].id, nil)


    Script.Feature['Enable Script logs'] = menu.add_feature('Enable Script logs', 'toggle', Script.Parent['Log Settings'].id, function(f)
        settings['Enable Script logs'] = {Enabled = f.on}
        if not f.on then
            ToggleOff({'Log Modder Detections', 'Log Chat'})
        end
    end)
    Script.Feature['Enable Script logs'].on = true


    Script.Feature['Log Modder Detections'] = menu.add_feature('Log Modder Detections', 'toggle', Script.Parent['Log Settings'].id, function(f)
        settings['Log Modder Detections'] = {Enabled = f.on}
    end)


    Script.Feature['Log Chat'] = menu.add_feature('Log Chat', 'toggle', Script.Parent['Log Settings'].id, function(f)
        settings['Log Chat'] = {Enabled = f.on}
    end)


    Script.Feature['Clear Script Logs'] = menu.add_feature('Clear Script Logs', 'action_value_str', Script.Parent['Log Settings'].id, function(f)
        local filename
        if f.value == 0 then
            filename = 'MainLog'
        else
            filename = 'ChatLog'
        end

        if utils.file_exists(files[filename]) then
            utility.write(io.open(files[filename], 'w'), 'File cleared')
            Notify('Log File cleared.', "Success", '')
        else
            Notify('Log File not found.', "Error", '')
        end
    end)
    Script.Feature['Clear Script Logs']:set_str_data({'2Take1Script.log', 'Chat.log'})


    Script.Feature['Clear Menu Logs'] = menu.add_feature('Clear Menu Logs', 'action_value_str', Script.Parent['Log Settings'].id, function(f)
        local filename
        if f.value == 0 then
            filename = 'MenuMainLog'
        elseif f.value == 1 then
            filename = 'MenuPrepLog'
        elseif f.value == 2 then
            filename = 'MenuNetLog'
        elseif f.value == 3 then
            filename = 'MenuNotifLog'
        elseif f.value == 4 then
            filename = 'MenuPlayerLog'
        else
            filename = 'MenuScriptLog'
        end

        if utils.file_exists(files[filename]) then
            utility.write(io.open(files[filename], 'w'), 'File cleared by 2Take1Script')
            Notify('Log File cleared.', "Success", '')
            Log('Log File "' .. filename ..'" cleared.')
        else
            Notify('Log File not found.', "Error", '')
        end
    end)
    Script.Feature['Clear Menu Logs']:set_str_data({'2Take1Menu.log', '2Take1Prep.log', 'net_events.log', 'notification.log', 'player.log', 'script_event.log'})


    Script.Parent['Notification Settings'] = menu.add_feature('Notification Settings', 'parent', Script.Parent['local_settings'].id, nil)


    Script.Feature['Enable Script Notifications'] = menu.add_feature('Enable Script Notifications', 'toggle', Script.Parent['Notification Settings'].id, function(f)
        settings['Enable Script Notifications'] = {Enabled = f.on}
    end)
    Script.Feature['Enable Script Notifications'].on = true


    Script.Feature['Notification Duration'] = menu.add_feature('Notification Duration (sec)', 'autoaction_value_i', Script.Parent['Notification Settings'].id, function(f)
        settings['Notification Duration'] = {Value = f.value}
    end)
    Script.Feature['Notification Duration'].min = 1
    Script.Feature['Notification Duration'].max = 10
    Script.Feature['Notification Duration'].value = 8


    Script.Feature['Success Notification Color'] = menu.add_feature('Success Notification Color', 'autoaction_value_str', Script.Parent['Notification Settings'].id, function(f)
        settings['Success Notification Color'] = {Value = f.value}
    end)
    Script.Feature['Success Notification Color']:set_str_data({'Green', 'Yellow', 'Red', 'Blue', 'Purple', 'Orange', 'Cyan'})
    Script.Feature['Success Notification Color'].value = 0


    Script.Feature['Neutral Notification Color'] = menu.add_feature('Neutral Notification Color', 'autoaction_value_str', Script.Parent['Notification Settings'].id, function(f)
        settings['Neutral Notification Color'] = {Value = f.value}
    end)
    Script.Feature['Neutral Notification Color']:set_str_data({'Green', 'Yellow', 'Red', 'Blue', 'Purple', 'Orange', 'Cyan'})
    Script.Feature['Neutral Notification Color'].value = 1


    Script.Feature['Error Notification Color'] = menu.add_feature('Error Notification Color', 'autoaction_value_str', Script.Parent['Notification Settings'].id, function(f)
        settings['Error Notification Color'] = {Value = f.value}
    end)
    Script.Feature['Error Notification Color']:set_str_data({'Green', 'Yellow', 'Red', 'Blue', 'Purple', 'Orange', 'Cyan'})
    Script.Feature['Error Notification Color'].value = 2


    Script.Parent['Player Feature Settings'] = menu.add_feature('Player Feature Settings', 'parent', Script.Parent['local_settings'].id)
    

    Script.Feature['Teleport Player Method'] = menu.add_feature('Teleport Player Method', 'autoaction_value_str', Script.Parent['Player Feature Settings'].id, function(f)
        settings['Teleport Player Method'] = {Value = f.value}
        if f.value == 1 then
            Notify('This method requires the target to be in a vehicle.', 'Neutral', 'Teleport Player')
        end
    end)
    Script.Feature['Teleport Player Method']:set_str_data({'v1', 'v2'})

    
    Script.Feature['Ramp Builder Invisible'] = menu.add_feature('Spawn Ramps Invisible', 'toggle', Script.Parent['Player Feature Settings'].id, function(f)
        settings['Ramp Builder Invisible'] = {Enabled = f.on}
    end)


    Script.Feature['Player Cages Invisible'] = menu.add_feature('Spawn Cages Invisible', 'toggle', Script.Parent['Player Feature Settings'].id, function(f)
        settings['Player Cages Invisible'] = {Enabled = f.on}
    end)


    Script.Feature['Godmode Assassins'] = menu.add_feature('Godmode Ped Assassins', 'toggle', Script.Parent['Player Feature Settings'].id, function(f)
        settings['Godmode Assassins'] = {Enabled = f.on}
    end)


    Script.Feature['Amount of Assassins'] = menu.add_feature('Ped Assassin Amount', 'autoaction_value_i', Script.Parent['Player Feature Settings'].id, function(f)
        settings['Amount of Assassins'] = {Value = f.value}
    end)
    Script.Feature['Amount of Assassins'].max = 10
    Script.Feature['Amount of Assassins'].min = 1


    Script.Feature['Entity Spam Amount'] = menu.add_feature('Entity Spam Amount', 'autoaction_value_i', Script.Parent['Player Feature Settings'].id, function(f)
        settings['Entity Spam Amount'] = {Value = f.value}
    end)
    Script.Feature['Entity Spam Amount'].max = 160
    Script.Feature['Entity Spam Amount'].min = 10
    Script.Feature['Entity Spam Amount'].mod = 10


    Script.Feature['Entity Spam Location'] = menu.add_feature('Entity Spam Loaction', 'autoaction_value_str', Script.Parent['Player Feature Settings'].id, function(f)
        settings['Entity Spam Location'] = {Value = f.value}
    end)
    Script.Feature['Entity Spam Location']:set_str_data({'Around Player', 'Above Player', 'On top of Player'})


    Script.Feature['Entity Spam Cleanup'] = menu.add_feature('Entity Spam Automatic Cleanup', 'toggle', Script.Parent['Player Feature Settings'].id, function(f)
        settings['Entity Spam Cleanup'] = {Enabled = f.on}
    end)


    Script.Feature['Exclude Friends'] = menu.add_feature('Exclude Friends', 'toggle', Script.Parent['local_settings'].id, function(f)
        settings['Exclude Friends'] = {Enabled = f.on}
    end)


    Script.Feature['Override Commands'] = menu.add_feature('Force Override Commands', 'toggle', Script.Parent['local_settings'].id, function(f)
        settings['Override Commands'] = {Enabled = f.on}
    end)
    
    
    Script.Feature['Disable Warning Messages'] = menu.add_feature('Disable Warning Messages', 'toggle', Script.Parent['local_settings'].id, function(f)
        settings['Disable Warning Messages'] = {Enabled = f.on}
    end)


    Script.Feature['2Take1Script Parent'] = menu.add_feature('2Take1Script Parent', 'toggle', Script.Parent['local_settings'].id, function(f)
        settings['2Take1Script Parent'] = {Enabled = f.on}
    end)
    Script.Feature['2Take1Script Parent'].on = true
    

    Script.Feature['Enable Vehicle Spawner'] = menu.add_feature('Enable Vehicle Spawner', 'toggle', Script.Parent['local_settings'].id, function(f)
        if not settings['Enable Vehicle Spawner'].Enabled then
            Notify('Vehicle Spawner has been enabled. Save settings and reload the script to use it.\nNote that having this enabled will result in a crash upon unloading the menu.', 'Neutral')
        end
        settings['Enable Vehicle Spawner'] = {Enabled = f.on}
    end)


    Script.Parent['Setting Profiles'] = menu.add_feature('Setting Profiles', 'parent', Script.Parent['local_settings'].id, nil)


    Script.Feature['Add Profile'] = menu.add_feature('Add Profile', 'action', Script.Parent['Setting Profiles'].id, function()
        local Name = get.Input('Enter Profile Name', 25, 2, 'Name')

        if not Name then
            Notify('Input canceled.', "Error", '')
            return
        end

        local File = paths['ScriptSettings'] .. '\\' .. Name .. '.ini'
        setup.SaveSettings(File)

        Log('Profile ' .. Name ..  ' Successfully created.')
        Notify('Profile ' .. Name ..  ' Successfully created.', "Success")

        Script.Feature['Profile ' .. Name] = menu.add_feature(Name, 'action_value_str', Script.Parent['Setting Profiles'].id, function(f)
            local FPath = paths['ScriptSettings'] .. '\\' .. f.name .. '.ini'
            if f.value == 0 then
                setup.LoadSettings(FPath)

                Log('Settings Successfully Loaded.')
                Notify('Settings Successfully Loaded.', "Success")

            elseif f.value == 1 then
                setup.SaveSettings(FPath)

                Log('Settings saved to File.')
                Notify('Settings saved to File.', "Success")
                
                
            elseif f.value == 2 then
                local NewName = get.Input('Enter Profile Name', 25, 2, 'Name')

                if not NewName then
                    Notify('Input canceled.')
                    return
                end

                io.rename(FPath, paths['ScriptSettings'] .. '\\' .. NewName .. '.ini')
                f.name = NewName
            else
                io.remove(FPath)
                menu.delete_feature(f.id)
            end
        end)
        Script.Feature['Profile ' .. Name]:set_str_data({'Load', 'Save', 'Rename', 'Delete'})
    end)


    Script.Feature['Save Default'] = menu.add_feature('Default', 'action_value_str', Script.Parent['Setting Profiles'].id, function(f)
        if f.value == 0 then
            setup.LoadSettings()
            Log('Settings Successfully Loaded.')
            Notify('Settings Successfully Loaded.', "Success")
        else
            setup.SaveSettings()
            Log('Settings saved to File.')
            Notify('Settings saved to File.', "Success")
            
        end
    end)
    Script.Feature['Save Default']:set_str_data({'Load', 'Save'})


    local configfiles = utils.get_all_files_in_directory(paths['ScriptSettings'], 'ini')
    for i = 1, #configfiles do
        if configfiles[i] ~= 'Default.ini' then
            local Name = configfiles[i]:sub(1, -5)

            Script.Feature['Profile ' .. Name] = menu.add_feature(Name, 'action_value_str', Script.Parent['Setting Profiles'].id, function(f)
                local File = paths['ScriptSettings'] .. '\\' .. f.name .. '.ini'
                print(File)
                if f.value == 0 then
                    setup.LoadSettings(File)
                    Log('Settings Successfully Loaded.')
                    Notify('Settings Successfully Loaded.', "Success")

                elseif f.value == 1 then
                    setup.SaveSettings(File)
                    Log('Settings saved to File.')
                    Notify('Settings saved to File.', "Success")
                    
                elseif f.value == 2 then
                    local NewName = get.Input('Enter Profile Name', 25, 2, 'Name')
    
                    if not NewName then
                        Notify('Input canceled.')
                        return
                    end
    
                    io.rename(File, paths['ScriptSettings'] .. '\\' .. NewName .. '.ini')
                    f.name = NewName
                else
                    io.remove(File)
                    menu.delete_feature(f.id)
                end
            end)
            Script.Feature['Profile ' .. Name]:set_str_data({'Load', 'Save', 'Rename', 'Delete'})
        end
    end


    Script.Parent['Feature Search'] = menu.add_feature('Local Feature Search', 'parent', Script.Parent['Main Parent'].id)


    Script.Feature['Local Search'] = menu.add_feature('Search Local Features', 'action_value_str', Script.Parent['Feature Search'].id, function(f)
        local search = get.Input('Enter Feature Keyword', 25, 0, '')

        if not search then
            Notify('Input canceled.', "Error", 'Feature Search')
            return
        end

        SelectFeat(f)

        if #localResult > 0 then
            for i = 1, #localResult do
                if localResult[i].id then
                    menu.delete_feature(localResult[i].id)
                    localResult[i] = nil
                end
            end
        end

        coroutine.yield(100)

        for k in pairs(Script.Feature) do
            local name = Script.Feature[k].name
            if Script.Feature[k].hidden or (Script.Feature[k].parent and Script.Feature[k].parent.hidden) or (Script.Feature[k].parent and Script.Feature[k].parent.parent and Script.Feature[k].parent.parent.hidden) then
                goto skip
            end

            if name and string.find(name:lower(), search:lower()) then
                if Script.Feature[k].parent then
                    name = Script.Feature[k].parent.name .. ' -> ' .. name
                end

                localResult[#localResult + 1] = menu.add_feature(name, 'action', Script.Parent['Feature Search'].id, function(f)
                    SelectFeat(Script.Feature[k])
                end)
            end
            ::skip::
        end

        if #localResult > 0 then
            Notify(#localResult .. ' results\nClick on any feature to be navigated.', 'Success', 'Feature Search')
        else
            Notify('No features found.', 'Error', 'Feature Search')
        end
        f:set_str_data({search})
    end)
    Script.Feature['Local Search']:set_str_data({' '})


    Script.Feature['Reset Search'] = menu.add_feature('Reset Search', 'action', Script.Parent['Feature Search'].id, function()
        if #localResult > 0 then
            for i = 1, #localResult do
                if localResult[i].id then
                    menu.delete_feature(localResult[i].id)
                    localResult[i] = nil
                end
            end
            Notify('Search cleared.', 'Success', 'Feature Search')
        end
        Script.Feature['Local Search']:set_str_data({' '})
    end)


    Script.Parent['Player Feature Search'] = menu.add_feature('Player Feature Search', 'parent', Script.Parent['Main Parent'].id)

    for id = 0, 31 do
        if player.is_player_valid(id) and not Script.Parent['PFS ' .. id] then
            CreatePlayerSearch(id)
            
        end

    end
end, nil)

-- Player Features
local MainThread2 = menu.create_thread(function()
    Script.Parent['Player Utils'] = menu.add_player_feature('Player Utils', 'parent', Script.Parent['Player Parent'].id, nil)
    
    Script.PlayerFeature['Player Waypoint'] = menu.add_player_feature('Waypoint Player', 'toggle', Script.Parent['Player Utils'].id, function(f, id)
        if id == Self() then
            Notify('No need to do that on yourself.', "Error", 'Waypoint Player')
            f.on = false
            return
        end
        
        while f.on do
            local pos = get.PlayerCoords(id)
            ui.set_new_waypoint(v2(pos.x, pos.y))
            coroutine.yield(500)
        end

       ui.set_waypoint_off()
    end)


    Script.PlayerFeature['Player Appear As Ghost'] = menu.add_player_feature('Appear as Ghost', 'toggle', Script.Parent['Player Utils'].id, function(f, id)
        if not menu.is_trusted_mode_enabled(1 << 2) then
            Notify('Not available while trusted mode for natives is turned off', 'Error', 'Appear as Ghost')
            f.on = false
            return
        end

        if id == Self() then
            Notify('No need to do that on yourself.', "Error", 'Appear as Ghost')
            f.on = false
            return
        end

        if f.on then
            N.NETWORK._SET_RELATIONSHIP_TO_PLAYER(id, true)
        else
            N.NETWORK._SET_RELATIONSHIP_TO_PLAYER(id, false)
        end
    end)


    Script.PlayerFeature['Player Teleport'] = menu.add_player_feature('TP to Player', 'action_value_str', Script.Parent['Player Utils'].id, function(f, id)
        if id == Self() then
            Notify('No need to teleport to yourself.', "Error", 'TP to Player')
            return
        end

        local coords = utility.OffsetCoords(get.PlayerCoords(id), get.PlayerHeading(id), -2)

        if f.value == 0 then
            utility.set_coords(get.OwnPed(), coords)
            return
        end

        local veh = get.OwnVehicle()

        if veh ~= 0 then
            if not utility.request_ctrl(veh, 5000) then
                Notify('Failed to gain control over the vehicle.\nThe feature might not have worked.', "Error", 'TP to Player')
            end

            utility.set_coords(veh, coords)
        else
            utility.set_coords(get.OwnPed(), coords)
        end
            
    end)
    Script.PlayerFeature['Player Teleport']:set_str_data({'v1', 'v2'})


    Script.PlayerFeature['Teleport Player'] = menu.add_player_feature('Teleport Player', 'action_value_str', Script.Parent['Player Utils'].id, function(f, id)
        if id == Self() then
            Notify('No need to teleport yourself.', "Error", 'Teleport Player')
            return
        end

        local origin = get.OwnCoords() + v3(0, 0, 1)
        local coords
        local sent
        
        if f.value == 0 then
            coords = utility.OffsetCoords(get.OwnCoords(), get.OwnHeading(), 5) + v3(0, 0, 1)

        elseif f.value == 1 then
            local wp = ui.get_waypoint_coord()
            if wp.x ~= 16000 then
                coords = v3(wp.x, wp.y, Math.GetGroundZ(wp.x, wp.y))
            else
                Notify('No waypoint found.', 'Error', 'Teleport Player')
                return
            end

        else
            local _input1 = tonumber(get.Input('Enter X coordinate', 20, 3))
            if not _input1 then
                Notify('Input canceled.', "Error", 'Teleport Player')
                return
            end

            local _input2 = tonumber(get.Input('Enter Y coordinate', 20, 3))
            if not _input2 then
                Notify('Input canceled.', "Error", 'Teleport Player')
                return
            end

            local _input3 = tonumber(get.Input('Enter Z coordinate', 20, 3))
            if not _input3 then
                Notify('Input canceled.', "Error", 'Teleport Player')
                return
            end
            
            coords = v3(_input1, _input2, _input3)
        end

        local veh = get.PlayerVehicle(id)
        if veh == 0 then
            local time1 = utils.time_ms() + 2000
            local time2 = utils.time_ms() + 8000

            while time2 > utils.time_ms() and veh == 0 do
                local coords2 = utility.OffsetCoords(get.PlayerCoords(id), get.PlayerHeading(id), -5)
                coords2.z = coords2.z + 5
                utility.tp(coords2)

                veh = get.PlayerVehicle(id)
                if time1 < utils.time_ms() and veh == 0 then
                    if Script.Feature['Teleport Player Method'].value == 1 then
                        Notify('Target is not in a vehicle', 'Error', 'Teleport Player')
                        utility.tp(origin)
                        return
                    end

                    if not sent then
                        scriptevent.Send('Force on Death Bike', {Self(), 1, 32, network.network_hash_from_player(id), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1}, id)
                        sent = true
                    end
                end
                coroutine.yield(0)
            end
        end

        if veh == 0 and Script.Feature['Teleport Player Method'].value == 0 then
            Notify('Failed to force the target into a vehicle', 'Error', 'Teleport Player')
            utility.tp(origin)
            return
        end

        if not utility.request_ctrl(veh, 5000) then
            Notify('Failed to gain control over the Players vehicle.\nThe feature might not have worked.', "Error", 'Teleport Player')
        end

        for i = 1, 50 do
            utility.request_ctrl(veh)
            entity.set_entity_coords_no_offset(veh, coords)
        end

        utility.tp(coords)

        coroutine.yield(500)

        if sent then
            ped.clear_ped_tasks_immediately(get.PlayerPed(id))
            coroutine.yield(500)

            local time = utils.time_ms() + 5000
            while time > utils.time_ms() do
                if entity.is_an_entity(veh) then
                    utility.request_ctrl(veh)
                    entity.set_entity_coords_no_offset(veh, v3(8000, 8000, -1000))
                    entity.set_entity_visible(veh, false)
                    entity.delete_entity(veh)
                end                                         
                coroutine.yield(0)
            end
        end

        utility.tp(origin)
    end)
    Script.PlayerFeature['Teleport Player']:set_str_data({'To Me', 'Waypoint', 'Custom Coords'})


    Script.PlayerFeature['IP Lookup'] = menu.add_player_feature("IP Lookup", "action_value_str", Script.Parent['Player Utils'].id, function(f, id)
        if not menu.is_trusted_mode_enabled(1 << 3) then
            Notify('Not available while trusted mode for http is turned off', 'Error', 'IP Lookup')
            return
        end
        
        local IP = get.IP(id)
        local State, Result = web.get("http://ip-api.com/csv/" .. IP)

        if State ~= 200 then
            Notify('IP lookup failed. Error code: ' .. State, 'Error', 'IP Lookup')
            return
        end

        local parts = {}
        for part in Result:gmatch("[^,]+") do
            parts[#parts + 1] = part
        end

        local Success = parts[1]
        if Success == 'fail' then
            Notify('IP lookup failed', 'Error', '')
            return
        end

        local Data = 'Country : ' .. parts[2] .. ' [' .. parts[3] .. ']\n' ..
        'Region: ' .. parts[5] .. ' [' .. parts[4] .. ']\n' ..
        'City: ' .. parts[6] .. '\n' ..
        'Zip Code: ' .. parts[7] .. '\n' ..
        'Coords: ' .. parts[8] .. '/' .. parts[9] .. '\n' ..
        'Continent: ' .. parts[10] .. '\n' ..
        'ISP: ' .. parts[11]
        
        if f.value == 0 then
            Notify('IP Address : ' .. IP .. '\n' .. Data, 'Success', 'IP Lookup for ' .. get.Name(id))
        elseif f.value == 1 then
            utils.to_clipboard('IP Lookup for ' .. get.Name(id) .. '\nIP Address : ' .. IP .. '\n' .. Data)
        elseif f.value == 2 then
            network.send_chat_message('IP Lookup for ' .. get.Name(id) .. '\nIP Address : ' .. IP .. '\n' .. Data, false)
        end
    end)
    Script.PlayerFeature['IP Lookup']:set_str_data({'Notify', 'Copy to Clipboard', 'Send in Chat'})

    
    Script.PlayerFeature['Copy to Clipboard'] = menu.add_player_feature('Copy Info to Clipboard', 'action_value_str', Script.Parent['Player Utils'].id, function(f, id)
        if f.value == 0 then
            utils.to_clipboard(tostring(get.Name(id)))
        elseif f.value == 1 then
            utils.to_clipboard(get.SCID(id))
        elseif f.value == 2 then
            utils.to_clipboard(tostring(get.IP(id)))
        elseif f.value == 3 then
            utils.to_clipboard(Math.DecToHex2(get.HostToken(id)))
        end
        
        Notify('Info copied to clipboard', "Success", '')
    end)
    Script.PlayerFeature['Copy to Clipboard']:set_str_data({'Name', 'SCID', 'IP', 'Host Token'})

    
    Script.PlayerFeature['Player Add Fake Friends'] = menu.add_player_feature("Add to Fake Friends", "action_value_str", Script.Parent['Player Utils'].id, function(f, id)
        if id == Self() then
            Notify('No need to do that.', "Error", 'Add to Fake Friends')
            return
        end

        if IsFakeFriend(id) then
            Notify('Player already exists in your Fake Friends.', "Error", 'Add to Fake Friends')
        else
            if f.value == 0 then
                utility.write(io.open(files['FakeFriends'], 'a'), get.Name(id) .. ':' .. Math.DecToHex(get.SCID(id)) .. ":c")
                Notify("Added " .. get.Name(id) .. " to the Fake Friends\nReinject the Menu for it to take effect", "Success", 'Add to Fake Friends')
            end
            if f.value == 1 then
                utility.write(io.open(files['FakeFriends'], 'a'), get.Name(id) .. ':' .. Math.DecToHex(get.SCID(id)) .. ":11")
                Notify("Added " .. get.Name(id) .. " to the Fake Friends\nReinject the Menu for it to take effect", "Success", 'Add to Fake Friends')
            end
            if f.value == 2 then
                utility.write(io.open(files['FakeFriends'], 'a'), get.Name(id) .. ':' .. Math.DecToHex(get.SCID(id)) .. ":1")
                Notify("Added " .. get.Name(id) .. " to the Fake Friends\nReinject the Menu for it to take effect", "Success", 'Add to Fake Friends')
            end
        end
    end)
	Script.PlayerFeature['Player Add Fake Friends']:set_str_data({"Blacklist + Hidden", "Friend List + Stalk", "Stalk"})


    Script.Parent['Player Vehicle'] = menu.add_player_feature('Vehicle Options', 'parent', Script.Parent['Player Parent'].id, nil)

    
    Script.PlayerFeature['Remote Control'] = menu.add_player_feature('Remote Control Vehicle', 'toggle', Script.Parent['Player Vehicle'].id, function(f, id)
        if id == Self() then
            Notify('No point in doing this on yourself', "Error", 'Remote Control Vehicle')
            f.on = false
            return
        end

        for i = 0, 31 do
            if i ~= id and player.is_player_valid(i) and Script.PlayerFeature['Remote Control'].on[i] then
                Notify('Feature is already on for another Player.', "Error", 'Remote Control Vehicle')
                f.on = false
                return
            end
        end

        if network.get_player_player_is_spectating(Self()) ~= nil then
            Notify('This doesnt work properly while specating someone', "Error", 'Remote Control Vehicle')
            f.on = false
            return
        end

        local Ped = get.OwnPed()
        if interior.get_interior_from_entity(Ped) ~= 0 then
            Notify('This doesnt work while inside of a building', "Error", 'Remote Control Vehicle')
            f.on = false
            return
        end

        local Target = get.PlayerVehicle(id)
        if Target == 0 then
            Notify('No vehicle found.', "Error", 'Remote Control Vehicle')
            f.on = false
            return
        end

        if not utility.request_ctrl(Target, 5000) then
            Notify('Failed to gain control over the Players vehicle.', "Error", 'Remote Control Vehicle')
            f.on = false
            return
        end

        local Hash = entity.get_entity_model_hash(Target)
        local Vehicle = Spawn.Vehicle(Hash, get.OwnCoords())

        decorator.decor_set_int(Vehicle, 'MPBitset', 1 << 10)
        utility.SetVehicleMods(Vehicle, utility.GetVehicleMods(Target))
        vehicle.set_vehicle_number_plate_index(Vehicle, 0)
        vehicle.set_vehicle_number_plate_text(Vehicle, ' ')

        ped.set_ped_into_vehicle(Ped, Vehicle, -1)
        utility.request_ctrl(Vehicle, 100)

        utility.set_coords(Vehicle, entity.get_entity_coords(Target))
        entity.set_entity_rotation(Vehicle, entity.get_entity_rotation(Target))
        entity.set_entity_collision(Vehicle, false, false, 0)
        entity.attach_entity_to_entity(Target, Vehicle, 0, v3(), v3(), true, false, false, 0, true)
        entity.set_entity_collision(Vehicle, true, true, 0)

        while f.on do
            utility.request_ctrl(Target)
            vehicle.set_vehicle_number_plate_text(Target, ' ')
            coroutine.yield(0)
        end

        local Speed = entity.get_entity_speed(Vehicle)
        local Coords = entity.get_entity_coords(Vehicle)
        
        ped.clear_ped_tasks_immediately(Ped)
        utility.clear(Vehicle)
        coroutine.yield(200)

        entity.set_entity_coords_no_offset(Target, Coords + v3(0, 0, 2))
        coroutine.yield(200)

        vehicle.set_vehicle_forward_speed(Target, Speed)
        entity.set_entity_collision(Vehicle, true, true, 0)
    end)


    --[[
    Script.PlayerFeature['Remote Control v2'] = menu.add_player_feature('Remote Control Vehicle v2', 'toggle', Script.Parent['Player Vehicle'].id, function(f, id)
        if id == Self() then
            Notify('No point in doing this on yourself', "Error", 'Remote Control Vehicle')
            f.on = false
            return
        end

        for i = 0, 31 do
            if i ~= id and player.is_player_valid(i) and Script.PlayerFeature['Remote Control v2'].on[i] then
                Notify('Feature is already on for another Player.', "Error", 'Remote Control Vehicle')
                f.on = false
                return
            end
        end

        local Veh = get.PlayerVehicle(id)
        if Veh == 0 then
            Notify('No vehicle found.', "Error", 'Remote Control Vehicle')
            f.on = false
            return
        end

        entity.freeze_entity(get.OwnPed(), true)
        entity.set_entity_visible(get.OwnPed(), false)
        menu.get_feature_by_hierarchy_key('online.online_players.player_' .. id .. '.spectate_player'):toggle()

        while f.on and get.PlayerVehicle(id) ~= 0 do
            if controls.is_control_pressed(0, 32) then
                while native.call(0x648EE3E7F38877DD, 0, 32):__tonumber() == 0 do
                    N.TASK.TASK_VEHICLE_TEMP_ACTION(get.PlayerPed(id), Veh, 23, 100)
                    coroutine.yield(0)
                end

                coroutine.yield(100)
                N.TASK.TASK_VEHICLE_TEMP_ACTION(get.PlayerPed(id), Veh, 27, 1)

            elseif controls.is_control_pressed(0, 33) then
                while native.call(0x648EE3E7F38877DD, 0, 33):__tonumber() == 0 do
                    N.TASK.TASK_VEHICLE_TEMP_ACTION(get.PlayerPed(id), Veh, 28, 100)
                    coroutine.yield(0)
                end

                coroutine.yield(100)
                N.TASK.TASK_VEHICLE_TEMP_ACTION(get.PlayerPed(id), Veh, 27, 1)

            elseif controls.is_control_pressed(0, 34) then
                while native.call(0x648EE3E7F38877DD, 0, 34):__tonumber() == 0 do
                    N.TASK.TASK_VEHICLE_TEMP_ACTION(get.PlayerPed(id), Veh, 7, 100)
                    coroutine.yield(0)
                end

                coroutine.yield(100)
                N.TASK.TASK_VEHICLE_TEMP_ACTION(get.PlayerPed(id), Veh, 27, 1)

            elseif controls.is_control_pressed(0, 35) then
                while native.call(0x648EE3E7F38877DD, 0, 35):__tonumber() == 0 do
                    N.TASK.TASK_VEHICLE_TEMP_ACTION(get.PlayerPed(id), Veh, 8, 100)
                    coroutine.yield(0)
                end

                coroutine.yield(100)
                N.TASK.TASK_VEHICLE_TEMP_ACTION(get.PlayerPed(id), Veh, 27, 1)

            end

            coroutine.yield(0)
        end

        entity.freeze_entity(get.OwnPed(), false)
        entity.set_entity_visible(get.OwnPed(), true)
        menu.get_feature_by_hierarchy_key('online.online_players.player_' .. id .. '.spectate_player'):toggle()
    end)
    ]]

    
    Script.Parent['Ramp Builder'] = menu.add_player_feature('Ramp Spawner', 'parent', Script.Parent['Player Vehicle'].id, nil)

    
    Script.PlayerFeature['Ramp Builder Remove'] = menu.add_player_feature('Delete Ramps', 'action', Script.Parent['Ramp Builder'].id, function(f, id)
        local veh = get.PlayerVehicle(id)

        if veh == 0 then
            Notify('No vehicle found.', "Error", '')
            return
        end

        local objects = object.get_all_objects()
        for i = 1, #objects do
            if entity.get_entity_attached_to(objects[i]) == veh then
                local hash = entity.get_entity_model_hash(objects[i])
                if hash == 2934970695 or hash == 3233397978 or hash == 1290523964 then
                    utility.clear(objects[i])
                end
            end
        end
    end)

    
    for ramps = 1, #miscdata.ramps.versions do
        Script.PlayerFeature['Ramp Builder ' .. miscdata.ramps.versions[ramps][1]] = menu.add_player_feature(miscdata.ramps.versions[ramps][1] .. ' Ramp', 'action_value_str', Script.Parent['Ramp Builder'].id, function(f, id)
            local hash = miscdata.ramps[f.value + 1]
            local veh = get.PlayerVehicle(id)

            if veh == 0 then
                Notify('No vehicle found.', "Error", '')
                return
            end

            if not utility.request_ctrl(veh, 5000) then
                Notify('Failed to gain control over the Players vehicle.\nThe feature might not have worked.', "Error", '')
                return
            end

            local ramp = Spawn.Object(hash, v3())
            entity.attach_entity_to_entity(ramp, veh, 0, miscdata.ramps.versions[ramps][2], miscdata.ramps.versions[ramps][3], true, true, false, 0, true)
            if Script.Feature['Ramp Builder Invisible'].on then
                entity.set_entity_visible(ramp, false)
            end 
        end)
        Script.PlayerFeature['Ramp Builder ' .. miscdata.ramps.versions[ramps][1]]:set_str_data({'Small', 'Medium', 'Big'})
    end
    

    
    Script.PlayerFeature['Vehicle Godmode'] = menu.add_player_feature("Vehicle Godmode", "value_str", Script.Parent['Player Vehicle'].id, function(f, id)
        if f.value == 1 and not menu.is_trusted_mode_enabled(1 << 2) then
            Notify('Not available while trusted mode for natives is turned off', 'Error', 'Vehicle Godmode')
            f.on = false
            return
        end

        local veh
        while f.on do
            if f.value == 1 and not menu.is_trusted_mode_enabled(1 << 2) then
                f.on = false
                return
            end

            veh = get.PlayerVehicle(id)
            if veh ~= 0 then
                utility.request_ctrl(veh)

                if f.value == 0 then
                    entity.set_entity_god_mode(veh, true)
                else
                    N.ENTITY.SET_ENTITY_PROOFS(veh, 1, 1, 1, 1, 1, 1, 1, 1)
                end
            end

            coroutine.yield(1000)
        end

        entity.set_entity_god_mode(veh, false)
        if menu.is_trusted_mode_enabled(1 << 2) then
            N.ENTITY.SET_ENTITY_PROOFS(veh, 0, 0, 0, 0, 0, 0, 1, 0)
        end
    end)
	Script.PlayerFeature['Vehicle Godmode']:set_str_data({"v1", "v2"})

    
    Script.PlayerFeature['Prevent Lock-On'] = menu.add_player_feature('Prevent Lock-On', 'toggle', Script.Parent['Player Vehicle'].id, function(f, id)
        local veh

        while f.on do
            veh = get.PlayerVehicle(id)
            if veh ~= 0 then
                utility.request_ctrl(veh)
                vehicle.set_vehicle_can_be_locked_on(veh, false, false)
            end

            coroutine.yield(1000)

        end

        vehicle.set_vehicle_can_be_locked_on(veh, true, true)
    end)

    
    Script.PlayerFeature['Upgrade Vehicle'] = menu.add_player_feature("Upgrade Vehicle", "action_value_str", Script.Parent['Player Vehicle'].id, function(f, id)
        local veh = get.PlayerVehicle(id)
        if veh == 0 then
            Notify('No vehicle found.', "Error", '')
            return
        end

        if not utility.request_ctrl(veh, 5000) then
            Notify('Failed to gain control over the Players vehicle.\nThe feature might not have worked.', "Error", '')
        end

        if f.value == 3 then
            vehicle.set_vehicle_mod_kit_type(veh, 0)
            for i = 0, 47 do
                vehicle.set_vehicle_mod(veh, i, -1, false)
                vehicle.toggle_vehicle_mod(veh, i, false)
            end
    
            vehicle.set_vehicle_bulletproof_tires(veh, false)
            vehicle.set_vehicle_window_tint(veh, 0)
            vehicle.set_vehicle_number_plate_index(veh, 0)

            return

        elseif f.value == 4 then
            vehicle.set_vehicle_mod_kit_type(veh, 0)
            local upgrades = {11, 12, 13, 15, 16}
            for i = 1, #upgrades do
                vehicle.set_vehicle_mod(veh, upgrades[i], -1, false)
            end

            vehicle.toggle_vehicle_mod(veh, 18, false)
            vehicle.set_vehicle_bulletproof_tires(veh, false)

            return
        end

        utility.MaxVehicle(veh, f.value + 1)
    end)
    Script.PlayerFeature['Upgrade Vehicle']:set_str_data({'Full', 'Performance', 'Random', 'Downgrade', 'Performance Downgrade'})

    

    
    Script.PlayerFeature['Clone Vehicle'] = menu.add_player_feature("Clone Vehicle", "action_value_str", Script.Parent['Player Vehicle'].id, function(f, id)
        local veh
        if f.value == 0 then
            veh = get.PlayerVehicle(id)
        else
            veh = scriptevent.GetPersonalVehicle(id)
        end

        if not veh or veh == 0 then
            Notify('No vehicle found.', "Error", '')
            return
        end
        
        local vehiclehash = entity.get_entity_model_hash(veh)

        local clone = Spawn.Vehicle(vehiclehash, utility.OffsetCoords(get.OwnCoords(), get.OwnHeading(), 10))
        if not clone then
            Notify('Failed to clone Vehicle, couldnt get the Vehicles Hash', "Error", '')
            return
        end

        utility.SetVehicleMods(clone, utility.GetVehicleMods(veh))
    end)
    Script.PlayerFeature['Clone Vehicle']:set_str_data({'Current Vehicle', 'Personal Vehicle'})

    
    Script.PlayerFeature['Repair Vehicle'] = menu.add_player_feature("Repair Vehicle", "action", Script.Parent['Player Vehicle'].id, function(f, id)
        local veh = get.PlayerVehicle(id)
        if veh == 0 then
            Notify('No vehicle found.', "Error", '')
            return
        end
        
        if not utility.request_ctrl(veh, 5000) then
            Notify('Failed to gain control over the Players vehicle.\nThe feature might not have worked.', "Error", '')
        end

        utility.RepairVehicle(veh) 
    end)


    Script.PlayerFeature['Engine Manipulation'] = menu.add_player_feature('Engine Manipulation', 'action_value_str', Script.Parent['Player Vehicle'].id, function(f, id)
        if not menu.is_trusted_mode_enabled(1 << 2) then
            Notify('Not available while trusted mode for natives is turned off', 'Error', 'Engine Manipulation')
            return
        end

        local veh = get.PlayerVehicle(id)
        if veh == 0 then
            Notify('No vehicle found.', "Error", '')
            return
        end

        if not utility.request_ctrl(veh, 5000) then
            Notify('Failed to gain control over the Players vehicle.\nThe feature might not have worked.', "Error", '')
        end
        
        if f.value == 2 then
            N.VEHICLE.SET_VEHICLE_ENGINE_HEALTH(veh, -4000.0)

        elseif f.value == 3 then
            utility.RepairVehicle(veh)
        else
            N.VEHICLE.SET_VEHICLE_ENGINE_ON(veh, f.value, true, true)
        end
    end)
    Script.PlayerFeature['Engine Manipulation']:set_str_data({'Turn Off', 'Turn On', 'Destroy', 'Revive'})

    
    Script.PlayerFeature['Delete Vehicle'] = menu.add_player_feature("Delete Vehicle", "action", Script.Parent['Player Vehicle'].id, function(f, id)
        local veh = get.PlayerVehicle(id)
        if veh == 0 then
            Notify('No vehicle found.', "Error", '')
            return
        end

        if not utility.request_ctrl(veh, 5000) then
            Notify('Failed to gain control over the Players vehicle.\nThe feature might not have worked.', "Error", '')
        end

        entity.delete_entity(veh)
    end)

    
    Script.PlayerFeature['Freeze Vehicle'] = menu.add_player_feature('Freeze Vehicle', 'toggle', Script.Parent['Player Vehicle'].id, function(f, id)
        local veh

        while f.on do
            veh = get.PlayerVehicle(id)

            if veh ~= 0 then
                utility.request_ctrl(veh)

                entity.freeze_entity(veh, true)
            end

            coroutine.yield(1000)
        end

        entity.freeze_entity(veh, false)
    end)

    
    Script.PlayerFeature['Vehicle Kick'] = menu.add_player_feature('Vehicle Kick', 'action_value_str', Script.Parent['Player Vehicle'].id, function(f, id)
        if f.value == 0 then
            scriptevent.Send('Vehicle Kick', {Self(), 4294967295, 4294967295, 4294967295}, id)
            return
        end

        local veh = get.PlayerVehicle(id)
        if veh == 0 then
            Notify('No vehicle found.', "Error", '')
            return
        end
    
        if veh ==  scriptevent.GetPersonalVehicle(id) then
            Notify('This does not work on personal vehicles.', "Error", '')
            return
        end

        if not utility.request_ctrl(veh, 5000) then
            Notify('Failed to gain control over the Players vehicle.\nThe feature might not have worked.', "Error", '')
        end
            
        decorator.decor_register('Player_Vehicle', 3)
        decorator.decor_set_int(veh, 'Player_Vehicle', 0)
    end)
    Script.PlayerFeature['Vehicle Kick']:set_str_data({'v1', 'v2'})


    Script.PlayerFeature['Disable Ability to Drive'] = menu.add_player_feature('Disable Ability to Drive', 'action', Script.Parent['Player Vehicle'].id, function(f, id)
        for i = 0, 31 do
            if not player.is_player_valid(i) then
                scriptevent.Send('Apartment Invite', {Self(), i, 4294967295, 1, 115, 0, 0, 0}, id)
                return
            end
        end
    end)

    
    Script.PlayerFeature['Vehicle EMP'] = menu.add_player_feature('Vehicle Emp', 'action_value_str', Script.Parent['Player Vehicle'].id, function(f, id)
        local pos = get.PlayerCoords(id)
        if f.value == 0 then
            scriptevent.Send('Vehicle EMP', {Self(), math.floor(pos.x), math.floor(pos.y), math.floor(pos.z), 0}, id)
            
        elseif f.value == 1 then
            fire.add_explosion(utility.OffsetCoords(pos, player.get_player_heading(id), 2), 83, true, false, 0, get.PlayerPed(id))
            
        elseif f.value == 2 then
            fire.add_explosion(utility.OffsetCoords(pos, player.get_player_heading(id), 2), 83, false, true, 0, get.PlayerPed(id))
        end
    end)
    Script.PlayerFeature['Vehicle EMP']:set_str_data({'Script Event', 'Explosion', 'Silent Explosion'})


    Script.PlayerFeature['Vehicle Mine Impacts'] = menu.add_player_feature('Mine Impacts', 'action_value_str', Script.Parent['Player Vehicle'].id, function(f, id)
        local types = {64, 66, 67, 68}
        local pos = get.PlayerCoords(id)

        fire.add_explosion(utility.OffsetCoords(pos, player.get_player_heading(id), 5), types[f.value + 1], true, false, 0, get.PlayerPed(id))
    end)
    Script.PlayerFeature['Vehicle Mine Impacts']:set_str_data({'Kinetic', 'Spike', 'Slick', 'Tar'})

    
    Script.PlayerFeature['Trap In Vehicle'] = menu.add_player_feature('Trap And Drown', 'action', Script.Parent['Player Vehicle'].id, function(f, id)
        local veh = get.PlayerVehicle(id)
        if veh == 0 then
            Notify('No vehicle found.', "Error", '')
            return
        end

        if not utility.request_ctrl(veh, 5000) then
            Notify('Failed to gain control over the Players vehicle.\nThe feature might not have worked.', "Error", '')
        end
        
        vehicle.set_vehicle_doors_locked(veh, 4)

        utility.set_coords(veh, v3(10, 685, 190))
    end)

    
    Script.PlayerFeature['Tire Burst'] = menu.add_player_feature('Tire Burst Spam', 'slider', Script.Parent['Player Vehicle'].id, function(f, id)
        while f.on do
            local veh = get.PlayerVehicle(id)

            if veh == 0 then
                goto continue
            end

            utility.request_ctrl(veh)
            vehicle.set_vehicle_mod_kit_type(veh, 0)
            vehicle.set_vehicle_bulletproof_tires(veh, false)
            vehicle.set_vehicle_tires_can_burst(veh, true)

            for i = 0, 6 do
                vehicle.set_vehicle_tire_burst(veh, i, true, 1000.0)
            end
            
            ::continue::
            coroutine.yield(500 - math.floor(f.value))
        end
    end)
    Script.PlayerFeature['Tire Burst'].min = 0
	Script.PlayerFeature['Tire Burst'].max = 500
	Script.PlayerFeature['Tire Burst'].mod = 50
    Script.PlayerFeature['Tire Burst'].value = 50

    
    Script.PlayerFeature['Destroy Personal Vehicle'] = menu.add_player_feature('Destroy Personal Vehicle', 'action', Script.Parent['Player Vehicle'].id, function(f, id)
        if scriptevent.GetPersonalVehicle(id) == 0 then
            Notify('Player has no personal vehicle', "Error", '')
            return
        end
        
        scriptevent.Send('Destroy Personal Vehicle', {Self(), id}, id)
        scriptevent.Send('Vehicle Kick', {Self(), 4294967295, 4294967295, 4294967295}, id)
    end)

    
    Script.PlayerFeature['Modify Speed'] = menu.add_player_feature('Modify Speed', 'action_value_str', Script.Parent['Player Vehicle'].id, function(f, id)
        local veh = get.PlayerVehicle(id)
        if veh == 0 then
            Notify('No vehicle found.', "Error", '')
            return
        end

        if f.value == 0 then
            local speed = tonumber(get.Input('Enter modified Speed (1-1000)', 4, 3))
            if not speed then
                Notify('Input canceled.', "Error", '')
                return
            end

            if speed < 1 or speed > 1000 then
                Notify('Input must be between 1 and 1000.', "Error", '')
                return
            end

            if not utility.request_ctrl(veh, 5000) then
                Notify('Failed to gain control over the Players vehicle.\nThe feature might not have worked.', "Error", '')
            end

            vehicle.modify_vehicle_top_speed(veh, speed)
            entity.set_entity_max_speed(veh, speed)
        else
            if not utility.request_ctrl(veh, 5000) then
                Notify('Failed to gain control over the Players vehicle.\nThe feature might not have worked.', "Error", '')
            end

            vehicle.modify_vehicle_top_speed(veh, 1)
            utility.RepairVehicle(veh)
        end
    end)
    Script.PlayerFeature['Modify Speed']:set_str_data({'Modify', 'Reset'})

    
    Script.PlayerFeature['Random Force'] = menu.add_player_feature('Apply random Force', 'action', Script.Parent['Player Vehicle'].id, function(f, id)
        local veh = get.PlayerVehicle(id)
        if veh == 0 then
            Notify('No vehicle found.', "Error", '')
            return
        end

        if not utility.request_ctrl(veh, 5000) then
            Notify('Failed to gain control over the Players vehicle.\nThe feature might not have worked.', "Error", '')
        end

        local velocity = entity.get_entity_velocity(veh)
        for i = 1, 5 do
            velocity.x = math.random(math.floor(velocity.x - 50), math.floor(velocity.x + 50))
            velocity.y = math.random(math.floor(velocity.y - 50), math.floor(velocity.y + 50))
            velocity.z = math.random(math.floor(velocity.z - 50), math.floor(velocity.z + 50))
            entity.set_entity_velocity(veh, velocity)
            coroutine.yield(10)
        end
    end)


    Script.Parent['Player Trolling'] = menu.add_player_feature('Trolling', 'parent', Script.Parent['Player Parent'].id, nil)
    

    Script.Parent['Player Notifications'] = menu.add_player_feature('Notifications', 'parent', Script.Parent['Player Trolling'].id, nil)


    Script.PlayerFeature['Player Job Notification'] = menu.add_player_feature('Job Notification: Input', 'action', Script.Parent['Player Notifications'].id, function(f, id)
        local jobname = tostring(get.Input('Enter Job Name', 100))

        if not jobname then
            Notify('Input canceled.', "Error", '')
            return
        end

        local Table = utils.str_to_vecu64(jobname)
        local newTable = {Self()}

        for i = 1, #Table do
            newTable[i + 1] = Table[i]
        end

        scriptevent.Send('Job Join Notification', newTable, id)
    end)
    
    
    Script.PlayerFeature['Player Cash Removed'] = menu.add_player_feature('Cash Removed', 'action_value_str', Script.Parent['Player Notifications'].id, function(f, id)
        if f.value == 0 then
            scriptevent._notification(id, 1, math.random(1, 100000))
            return
        end

        local amount = get.Input('Enter The Amount Of Money (0 - 2147483647)', 10, 3)
            
        if not amount then
            Notify('Input canceled.', "Error", '')
            return
        end
            
        scriptevent._notification(id, 1, amount)
    end)
    Script.PlayerFeature['Player Cash Removed']:set_str_data({'Random Amount', 'Input'})

    
    Script.PlayerFeature['Player Cash Stolen'] = menu.add_player_feature('Cash Stolen', 'action_value_str', Script.Parent['Player Notifications'].id, function(f, id)
        if f.value == 0 then
            scriptevent._notification(id, 2, math.random(1, 100000))
            return
        end

        local amount = get.Input('Enter The Amount Of Money (0 - 2147483647)', 10, 3)
            
        if not amount then
            Notify('Input canceled.', "Error", '')
            return
        end
        
        scriptevent._notification(id, 2, amount)
    end)
    Script.PlayerFeature['Player Cash Stolen']:set_str_data({'Random Amount', 'Input'})

    
    Script.PlayerFeature['Player Cash Banked'] = menu.add_player_feature('Cash Banked', 'action_value_str', Script.Parent['Player Notifications'].id, function(f, id)
        if f.value == 0 then
            scriptevent._notification(id, 3, math.random(1, 100000))
            return
        end

        local amount = get.Input('Enter The Amount Of Money (0 - 2147483647)', 10, 3)
            
        if not amount then
            Notify('Input canceled.', "Error", '')
            return
        end

        scriptevent._notification(id, 3, amount)
    end)
    Script.PlayerFeature['Player Cash Banked']:set_str_data({'Random Amount', 'Input'})

    
    Script.PlayerFeature['Player Insurance Notification'] = menu.add_player_feature('Insurance Notification', 'action_value_str', Script.Parent['Player Notifications'].id, function(f, id)
        if f.value == 0 then
            scriptevent.Send('Insurance Notification', {Self(), math.random(1, 20000)}, id)
            return
        end

        local amount = get.Input('Enter The Amount Of Money (0 - 2147483647)', 10, 3)
            
        if not amount then
            Notify('Input canceled.', "Error", '')
            return
        end

        scriptevent.Send('Insurance Notification', {Self(), amount}, id)
    end)
    Script.PlayerFeature['Player Insurance Notification']:set_str_data({'Random Amount', 'Input'})

    
    Script.PlayerFeature['Player Notification Spam'] = menu.add_player_feature('Notification Spam', 'toggle', Script.Parent['Player Notifications'].id, function(f, id)
        while f.on do
            scriptevent._notification(id, 1, math.random(1, 100000))
            scriptevent._notification(id, 2, math.random(1, 100000))
            scriptevent._notification(id, 3, math.random(1, 100000))

            coroutine.yield(200)
        end
    end)


    Script.Parent['Player Teleports'] = menu.add_player_feature('Teleports', 'parent', Script.Parent['Player Trolling'].id, nil)
    

    Script.PlayerFeature['Player Random Apartment Invite'] = menu.add_player_feature('Random Apartment Invite', 'action', Script.Parent['Player Teleports'].id, function(f, id)
        scriptevent.Send('Apartment Invite', {Self(), id, 4294967295, 1, math.random(1, 114), 0, 0, 0}, id)
    end)

    
    Script.PlayerFeature['Player Apartment Invite Loop'] = menu.add_player_feature('Apartment Invite Loop', 'toggle', Script.Parent['Player Teleports'].id, function(f, id)
        while f.on do
            scriptevent.Send('Apartment Invite', {Self(), id, 4294967295, 1, math.random(1, 114), 0, 0, 0}, id)
            coroutine.yield(500)
        end
    end)

    
    Script.PlayerFeature['Player Warehouse Invite'] = menu.add_player_feature('Warehouse Invite', 'action_value_str', Script.Parent['Player Teleports'].id, function(f, id)
        if f.value == 22 then
            scriptevent.Send('Warehouse Invite', {Self(), 0, 1, math.random(1, 22)}, id)
            return
        end

        scriptevent.Send('Warehouse Invite', {Self(), 0, 1, f.value + 1}, id)
    end)
	Script.PlayerFeature['Player Warehouse Invite']:set_str_data({
    'Elysian Island North',
    'La Puerta North',
    'La Mesa Mid',
    'Rancho West',
    'West Vinewood',
    'LSIA North',
    'Del Perro',
    'LSIA South',
    'Elysian Island South',
    'El Burro Heights',
    'Elysian Island West',
    'Textile City',
    'La Puerta South',
    'Strawberry',
    'Downtown Vinewood North',
    'La Mesa South',
    'La Mesa North',
    'Cypress Flats North',
    'Cypress Flats South',
    'West Vinewood West',
    'Rancho East',
    'Banning',
    'Random'
    })

    
    Script.PlayerFeature['Player Warehouse Invite Loop'] = menu.add_player_feature('Warehouse Invite Loop', 'toggle', Script.Parent['Player Teleports'].id, function(f, id)
        while f.on do
            scriptevent.Send('Warehouse Invite', {Self(), 0, 1, math.random(1, 22)}, id)
            coroutine.yield(500)
        end
    end)


    --[[
    Script.PlayerFeature['Player Force Island'] = menu.add_player_feature('Send to Cayo Perico', 'action', Script.Parent['Player Teleports'].id, function(f, id)
        scriptevent.Send('Force To Island', {Self(), 1}, id)
    end)


    Script.PlayerFeature['Player Force Island 2'] = menu.add_player_feature('Send to Cayo Perico v2', 'action_value_str', Script.Parent['Player Teleports'].id, function(f, id)
        if f.value == 0 then
            scriptevent.Send('Force To Island 2', {Self(), 0, 0, 3, 1}, id)

        elseif f.value == 1 then
            scriptevent.Send('Force To Island 2', {Self(), 0, 0, 4, 1}, id)

        elseif f.value == 2 then
            scriptevent.Send('Force To Island 2', {Self(), 0, 0, 3, 0}, id)

        elseif f.value == 3 then
            scriptevent.Send('Force To Island 2', {Self(), 0, 0, 4, 0}, id)
        end
    end)
    Script.PlayerFeature['Player Force Island 2']:set_str_data({'Via Plane', 'Instant', 'Back Home', 'Kicked Out'})
    ]]

    
    Script.PlayerFeature['Player Force Mission'] = menu.add_player_feature("Force to Mission", "action_value_str", Script.Parent['Player Teleports'].id, function(f, id)
        if f.value == 0 then
            scriptevent.Send('Force To Mission', {Self()}, id)
            return
        end
        
        scriptevent.Send('Force To Mission', {Self(), f.value}, id)
    end)
	Script.PlayerFeature['Player Force Mission']:set_str_data({'Severe Weather Patterns', 'Half-track Bully', 'Exit Strategy', 'Offshore Assets', 'Cover Blown', 'Mole Hunt', 'Data Breach', 'Work Dispute'})


    Script.Parent['Player Cages'] = menu.add_player_feature('Cages', 'parent', Script.Parent['Player Trolling'].id, nil)


    Script.PlayerFeature['Player Stunt Tube'] = menu.add_player_feature("Stunt Tube", "action", Script.Parent['Player Cages'].id, function(f, id)
        local pos = get.PlayerCoords(id)
        pos.z = pos.z - 5

        local tube = Spawn.Object(1125864094, pos)
        entity.set_entity_rotation(tube, v3(0, 90, 0))

        if Script.Feature['Player Cages Invisible'].on then
            entity.set_entity_visible(tube, false)
        end
    end)


    Script.PlayerFeature['Player Paragon Cage'] = menu.add_player_feature('Paragon Cage', 'action_value_str', Script.Parent['Player Cages'].id, function(f, id)
        local pos = get.PlayerCoords(id)
        local cage1
        local cage2

        if f.value == 0 then
            cage1 = Spawn.Object(2718056036, v3(pos.x, pos.y, pos.z + 0.5))
            cage2 = Spawn.Object(2718056036, v3(pos.x, pos.y, pos.z - 0.5))
        else
            cage1 = Spawn.Worldobject(1563219665, v3(pos.x, pos.y, pos.z + 0.5))
            cage2 = Spawn.Worldobject(1563219665, v3(pos.x, pos.y, pos.z - 0.5))
        end

        if Script.Feature['Player Cages Invisible'].on then
            entity.set_entity_visible(cage1, false)
            entity.set_entity_visible(cage2, false)
        end
    end)
    Script.PlayerFeature['Player Paragon Cage']:set_str_data({'v1', 'v2'})


    Script.PlayerFeature['Player Airport Trailer Cage'] = menu.add_player_feature('Airport Trailer', 'action', Script.Parent['Player Cages'].id, function(f, id)
        local pos = get.PlayerCoords(id) + v3(1.24, 0.24, 0)

        local cage1 = Spawn.Object(401136338, pos)
        entity.set_entity_rotation(cage1, v3(0, -90, 0))
        entity.freeze_entity(cage1, true)

        pos = pos + v3(-1.22, 0.58, 0)

        local cage2 = Spawn.Object(401136338, pos)
        entity.set_entity_rotation(cage2, v3(90, -90, 0))
        entity.freeze_entity(cage2, true)

        if Script.Feature['Player Cages Invisible'].on then
            entity.set_entity_visible(cage1, false)
            entity.set_entity_visible(cage2, false)
        end
    end)

    
    Script.PlayerFeature['Player Food Van Cage'] = menu.add_player_feature('Food Van', 'action_value_str', Script.Parent['Player Cages'].id, function(f, id)
        local hashes = {4022605402, 1257426102}
        local hash = hashes[f.value + 1]

        local pos = get.PlayerCoords(id)

        if f.value == 0 then
            pos = pos + v3(0, 0, -1)
        end

        local cage = Spawn.Object(hash, pos)
        entity.freeze_entity(cage, true)

        if Script.Feature['Player Cages Invisible'].on then
            entity.set_entity_visible(cage, false)
        end
    end)
    Script.PlayerFeature['Player Food Van Cage']:set_str_data({'v1', 'v2'})


    Script.PlayerFeature['Player Coffee Vend Cage'] = menu.add_player_feature('Coffee Vend', 'action', Script.Parent['Player Cages'].id, function(f, id)
        local pos = get.PlayerCoords(id)

        local cage = Spawn.Object(2976931766, pos)
        entity.freeze_entity(cage, true)
        entity.set_entity_rotation(cage, v3(0, -90, 180))

        if Script.Feature['Player Cages Invisible'].on then
            entity.set_entity_visible(cage, false)
        end
    end)


    Script.PlayerFeature['Player Wooden Crate Cage'] = menu.add_player_feature('Wooden Crate', 'action', Script.Parent['Player Cages'].id, function(f, id)
        local pos = get.PlayerCoords(id)

        local cage = Spawn.Object(1262767548, pos)
        entity.freeze_entity(cage, true)

        if Script.Feature['Player Cages Invisible'].on then
            entity.set_entity_visible(cage, false)
        end
    end)


    Script.PlayerFeature['Player Box Cage'] = menu.add_player_feature('Box Cage', 'action', Script.Parent['Player Cages'].id, function(f, id)
        local pos = get.PlayerCoords(id)

        local cage = Spawn.Object(1502702711, pos)
        entity.freeze_entity(cage, true)

        if Script.Feature['Player Cages Invisible'].on then
            entity.set_entity_visible(cage, false)
        end
    end)


    Script.PlayerFeature['Player Test Elevator Cage'] = menu.add_player_feature('Test Elevator', 'action', Script.Parent['Player Cages'].id, function(f, id)
        local pos = get.PlayerCoords(id)

        local cage = Spawn.Object(251770068, pos)
        entity.set_entity_rotation(cage, v3(90, 0, 0))
        entity.freeze_entity(cage, true)

        if Script.Feature['Player Cages Invisible'].on then
            entity.set_entity_visible(cage, false)
        end
    end)


    Script.PlayerFeature['Player Mesh Fence Cage'] = menu.add_player_feature('Mesh Fence', 'action', Script.Parent['Player Cages'].id, function(f, id)
        local pos = get.PlayerCoords(id) + v3(-1, 1, -1)

        local cage = Spawn.Object(206865238, pos)
        entity.set_entity_heading(cage, 180)
        entity.freeze_entity(cage, true)

        pos = pos + v3(3.4, -3.4, 0)
        local cage2 = Spawn.Object(206865238, pos)
        entity.freeze_entity(cage2, true)

        if Script.Feature['Player Cages Invisible'].on then
            entity.set_entity_visible(cage, false)
            entity.set_entity_visible(cage2, false)
        end
    end)


    Script.PlayerFeature['Player Fake Invite 3'] = menu.add_player_feature('Fake Invite', 'action_value_str', Script.Parent['Player Trolling'].id, function(f, id)
        scriptevent.Send('Fake Invite', {Self(), math.random(0, 190), miscdata.smslocations[f.value + 1]}, id)
    end)
    Script.PlayerFeature['Player Fake Invite 3']:set_str_data({
        'Business',
        'Vehicle Warehouse',
        'Bunker',
        'Mobile Operations Center',
        'Hangar',
        'Avenger',
        'Facility',
        'Nightclub',
        'Terrorbyte',
        'Arena Workshop',
        'Penthouse',
        'Arcade',
        'Kosatka',
        'Record A Studios',
        'Auto Shop',
        'LS Car Meet',
        'Agency',
        'Acid Lab',
        'The Freakshop',
        'Eclipse Blvd Garage',
        'ERROR'
    })
    

    
    Script.PlayerFeature['Player Fake Invite Spam'] = menu.add_player_feature('Fake Invite Spam', 'toggle', Script.Parent['Player Trolling'].id, function(f, id)
        while f.on do
            scriptevent.Send('Fake Invite', {Self(), math.random(0, 190), miscdata.smslocations[math.random(#miscdata.smslocations)]}, id)
            coroutine.yield(100)
        end
    end)

    
    Script.PlayerFeature['Player Script Freeze'] = menu.add_player_feature('Script Freeze', 'toggle', Script.Parent['Player Trolling'].id, function(f, id)
        while f.on do
            scriptevent.Send('Warehouse Invite', {Self(), 0, 1, 0}, id)

            coroutine.yield(500)
        end
    end)


    Script.PlayerFeature['Player Taze'] = menu.add_player_feature('Tazer', 'action', Script.Parent['Player Trolling'].id, function(f, id)
        if get.PlayerVehicle(id) ~= 0 then
            Notify('This does not work while the Target is in a vehicle.', 'Error', '')
            return
        end

        local pos = get.PlayerCoords(id)
        gameplay.shoot_single_bullet_between_coords(pos + v3(0, 0, 2), pos, 0, 0x3656C8C1, get.OwnPed(), true, false, 10000)
    end)


    Script.PlayerFeature['Player Tazer Loop'] = menu.add_player_feature('Tazer Loop', 'toggle', Script.Parent['Player Trolling'].id, function(f, id)
        if get.PlayerVehicle(id) ~= 0 then
            Notify('This does not work while the Target is in a vehicle.', 'Error', '')
            f.on = false
            return
        end

        while f.on do
            local pos = get.PlayerCoords(id)
            gameplay.shoot_single_bullet_between_coords(pos + v3(0, 0, 2), pos, 0, 0x3656C8C1, get.OwnPed(), true, false, 10000)
            coroutine.yield(2500)
        end
    end)

    
    Script.PlayerFeature['Player Ragdoll'] = menu.add_player_feature('Ragdoll Player', 'action_value_str', Script.Parent['Player Trolling'].id, function(f, id)
        local pos = get.PlayerCoords(id)

        if f.value == 0 then
            fire.add_explosion(pos, 70, false, true, 0, get.PlayerPed(id))
            return
        end

        fire.add_explosion(pos, 13, false, true, 0, get.PlayerPed(id))
    end)
    Script.PlayerFeature['Player Ragdoll']:set_str_data({'v1', 'v2'})

    --[[
    Script.PlayerFeature['Player Start Cutscene'] = menu.add_player_feature('Start Casino Cutscene', 'action', Script.Parent['Player Trolling'].id, function(f, id)
        scriptevent.Send('Casino Cutscene', {Self()}, id)
    end)
    ]]


    Script.PlayerFeature['Player Force Camera Forward'] = menu.add_player_feature('Force Camera Forward', 'toggle', Script.Parent['Player Trolling'].id, function(f, id)
        local done = 0
        while f.on do
            scriptevent.Send('Camera Manipulation', {Self(), -970603040, 0}, id)
            done = done + 1

            if done == 25 then
                done = 0
                coroutine.yield(50)
            end

            coroutine.yield(0)
        end
    end)

    --[[
    Script.PlayerFeature['Player Transaction Error'] = menu.add_player_feature('Transaction Error', 'toggle', Script.Parent['Player Trolling'].id, function(f, id)
        while f.on do
            scriptevent.Send('Transaction Error', {Self(), 50000, 0, 1, scriptevent.MainGlobal(id), scriptevent.GlobalPair(), 1}, id)
            coroutine.yield(1000)
        end
    end)
    ]]


    Script.Parent['Player Griefing'] = menu.add_player_feature('Griefing', 'parent', Script.Parent['Player Parent'].id, nil)


    Script.PlayerFeature['Player Radiation Lags'] = menu.add_player_feature('Radiation Lags', 'slider', Script.Parent['Player Griefing'].id, function(f, id)
        while f.on do
            graphics.set_next_ptfx_asset('scr_agencyheistb')
            while not graphics.has_named_ptfx_asset_loaded('scr_agencyheistb') do
                graphics.request_named_ptfx_asset('scr_agencyheistb')

                coroutine.yield(0)
            end

            graphics.start_networked_ptfx_non_looped_on_entity('scr_agency3b_elec_box', get.PlayerPed(id), v3(), v3(), f.value)

            coroutine.yield(0)
        end
        graphics.remove_named_ptfx_asset('scr_agencyheistb')
    end)
	Script.PlayerFeature['Player Radiation Lags'].min = 10
	Script.PlayerFeature['Player Radiation Lags'].max = 100
	Script.PlayerFeature['Player Radiation Lags'].mod = 10


    Script.Parent['Player Blame Kill'] = menu.add_player_feature('Blame Kill', 'parent', Script.Parent['Player Griefing'].id)

    for i = 0, 31 do
        if player.is_player_valid(i) and not playerblamekill[i] and get.Name then
            playerblamekill[i] = menu.add_player_feature(get.Name(i), 'action', Script.Parent['Player Blame Kill'].id, function(f, id)
                ped.clear_ped_tasks_immediately(get.PlayerPed(i))
                fire.add_explosion(get.PlayerCoords(i), 5, true, false, 1, get.PlayerPed(id))
            end)
        end
    end


    Script.PlayerFeature['Player Ram with Vehicle'] = menu.add_player_feature('Ram with Vehicle', 'action', Script.Parent['Player Griefing'].id, function(f, id)
        local speed = 200
        local direction = -10

        local choice = math.random(1, 2)
        if choice == 2 then
            speed = -200
            direction = 10
        end

        local veh = Spawn.Vehicle(3078201489, utility.OffsetCoords(get.PlayerCoords(id), get.PlayerHeading(id), direction))
        entity.set_entity_rotation(veh, v3(0, 0, get.PlayerHeading(id)))
        vehicle.set_vehicle_forward_speed(veh, speed)

        coroutine.yield(2000)

        utility.clear(veh)
    end)


    Script.PlayerFeature['Player Set on Fire'] = menu.add_player_feature('Set on Fire' ,'action', Script.Parent['Player Griefing'].id, function(f, id)
        local ptfx

        graphics.set_next_ptfx_asset('scr_recrash_rescue')
        while not graphics.has_named_ptfx_asset_loaded('scr_recrash_rescue') do
            graphics.request_named_ptfx_asset('scr_recrash_rescue')
            coroutine.yield(0)
        end

        while not ptfx do
            ptfx = graphics.start_networked_ptfx_looped_on_entity('scr_recrash_rescue_fire', get.PlayerPed(id), v3(), v3(), 1)
            coroutine.yield(0)
        end
    end)

    
    Script.PlayerFeature['Player Perma Burn'] = menu.add_player_feature('Perma Burn', 'toggle', Script.Parent['Player Griefing'].id, function(f, id)
        local permaburn = 0

        while f.on do
            if not graphics.does_looped_ptfx_exist(permaburn) then
                graphics.set_next_ptfx_asset('scr_recrash_rescue')
                while not graphics.has_named_ptfx_asset_loaded('scr_recrash_rescue') do
                    graphics.request_named_ptfx_asset('scr_recrash_rescue')
                    coroutine.yield(0)
                end

                permaburn = graphics.start_networked_ptfx_looped_on_entity('scr_recrash_rescue_fire', get.PlayerPed(id), v3(), v3(), 1)
            end
            
            coroutine.yield(1000)
        end
        graphics.remove_particle_fx(permaburn)
    end)


    Script.PlayerFeature['Player Shockwave Spam'] = menu.add_player_feature('Shockwave Spam', 'toggle', Script.Parent['Player Griefing'].id, function(f, id)
        while f.on do
            local pos = get.PlayerCoords(id)
            pos.x = pos.x + math.random(-3, 3)
            pos.y = pos.y + math.random(-3, 3)
            pos.z = pos.z + math.random(-2, 2)

            fire.add_explosion(pos, 70, true, false, 0, 0)

            coroutine.yield(100)
        end
    end)


    Script.PlayerFeature['Player Cluster Bomb'] = menu.add_player_feature('Cluster Bomb', 'action', Script.Parent['Player Griefing'].id, function(f, id)
        menu.create_thread(function(Player)
            local pos = get.PlayerCoords(Player)

            fire.add_explosion(pos, 47, true, false, 5, 0)
            
            coroutine.yield(500)
    
            for i = 1, 15 do
                pos = get.PlayerCoords(Player)
                pos.x = pos.x + math.random(-6, 6)
                pos.y = pos.y + math.random(-6, 6)
                pos.z = Math.GetGroundZ(pos.x, pos.y)
    
                fire.add_explosion(pos, 54, true, false, 2, 0)
    
                coroutine.yield(50)
            end
        end, id)
    end)


    Script.PlayerFeature['Player Airstrike'] = menu.add_player_feature('Airstrike (Named)', 'action', Script.Parent['Player Griefing'].id, function(f, id)
        if not weapon.has_ped_got_weapon(get.OwnPed(), 0xB1CA77B1) then
            weapon.give_delayed_weapon_to_ped(get.OwnPed(), 0xB1CA77B1, 0, 0)
            coroutine.yield(200)
        end
        
        local whash = gameplay.get_hash_key('weapon_airstrike_rocket')
        local pos = get.PlayerCoords(id)
        gameplay.shoot_single_bullet_between_coords(pos + v3(0, 0, 50), pos, 1000, whash, get.OwnPed(), true, false, 5000)
    end)


    Script.PlayerFeature['Player Airstrike Rain'] = menu.add_player_feature('Airstrike Rain (Named)', 'slider', Script.Parent['Player Griefing'].id, function(f, id)
        if not weapon.has_ped_got_weapon(get.OwnPed(), 0xB1CA77B1) then
            weapon.give_delayed_weapon_to_ped(get.OwnPed(), 0xB1CA77B1, 0, 0)
            coroutine.yield(200)
        end

        local whash = gameplay.get_hash_key('weapon_airstrike_rocket')
        while f.on do
            local pos = get.PlayerCoords(id)
            pos.x = pos.x + math.random(-15, 15)
            pos.y = pos.y + math.random(-15, 15)
            gameplay.shoot_single_bullet_between_coords(pos + v3(0, 0, 50), pos, 1000, whash, get.OwnPed(), true, false, 5000)

            coroutine.yield(1000 - math.floor(f.value))
        end
    end)
    Script.PlayerFeature['Player Airstrike Rain'].min = 100
	Script.PlayerFeature['Player Airstrike Rain'].max = 1000
	Script.PlayerFeature['Player Airstrike Rain'].mod = 100
    Script.PlayerFeature['Player Airstrike Rain'].value = 500


    Script.PlayerFeature['CEO Kick'] = menu.add_player_feature("CEO Kick", "action", Script.Parent['Player Griefing'].id, function(f, id)
        if not scriptevent.IsPlayerAssociate(id) then
            Notify('Player is not an associate.', "Error", '')
            return
        end

        scriptevent.Send('CEO Kick', {Self(), 1, 5}, id)
    end)


    Script.PlayerFeature['Player Set Bounty'] = menu.add_player_feature('Set Bounty: Input', 'action_value_str', Script.Parent['Player Griefing'].id, function(f, id)
        local amount = get.Input('Enter Bounty Value (0 - 10000)', 5, 3, "10000")
        if not amount then
            Notify('Input canceled.', "Error", '')
            return
        end

        if tonumber(amount) > 10000 then
            Notify('Value cannot be more than 10000.', nil, '')
            return
        end

        scriptevent.Send('Bounty', {Self(), id, 1, amount, 0, f.value,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, scriptevent.GlobalPair()}, script.get_host_of_this_script())
    end)
	Script.PlayerFeature['Player Set Bounty']:set_str_data({'Named', 'Anonymous'})


    Script.PlayerFeature['Player Bounty After Death'] = menu.add_player_feature('Reapply Bounty after Death', 'value_str', Script.Parent['Player Griefing'].id, function(f, id)
        local bounty_value = get.Input('Enter Bounty Value (0 - 10000)', 5, 3, "10000")

        if not bounty_value then
            Notify('Input canceled.', "Error", '')
            f.on = false
            return
        end

        if tonumber(bounty_value) > 10000 then
            Notify('Value cannot be more than 10000.', "Error", '')
            f.on = false
            return
        end

        while f.on do
            if entity.is_entity_dead(get.PlayerPed(id)) then
                Notify(get.Name(id) .. ' is dead.\nReapplying bounty...', "Neutral")
                Log(get.Name(id) .. ' is dead.\nReapplying bounty...')

                scriptevent.Send('Bounty', {Self(), id, 1, bounty_value, 0, f.value,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, scriptevent.GlobalPair()}, script.get_host_of_this_script())
                while player.get_player_health(id) == 0 do
                    coroutine.yield(0)
                end
            end

            coroutine.yield(0)
        end
    end)
	Script.PlayerFeature['Player Bounty After Death']:set_str_data({'Named', 'Anonymous'})


    Script.PlayerFeature['Player Asteroid'] = menu.add_player_feature('Falling Asteroids', 'action_value_str', Script.Parent['Player Griefing'].id, function(f, id)
        if f.value == 0 then
            for i = 1, 25 do
                local pos = get.PlayerCoords(id)
                pos.x = math.random(math.floor(pos.x - 80), math.floor(pos.x + 80))
                pos.y = math.random(math.floor(pos.y - 80), math.floor(pos.y + 80))
                pos.z = pos.z + math.random(45, 90)

                entitys['asteroids'][#entitys['asteroids'] + 1] = Spawn.Object(3751297495, pos, true, true)

                local force = math.random(-125, 25)
                entity.apply_force_to_entity(entitys['asteroids'][#entitys['asteroids']], 3, 0, 0, force, 0, 0, 0, true, true)
            end
            for j = 1, 25 do
                local pos = entity.get_entity_coords(entitys['asteroids'][(#entitys['asteroids'] - 25 + j)])
                fire.add_explosion(pos, 8, true, false, 0, 0)

                coroutine.yield(100)
            end

        elseif f.value == 1 then
            Log('Clearing Asteroids...')
            for i = 1, #entitys['asteroids'] do
                for j = 1, 50 do
                    if entity.is_an_entity(entitys['asteroids'][i]) then
                        utility.request_ctrl(entitys['asteroids'][i])
                        entity.set_entity_velocity(entitys['asteroids'][i], v3())
                        entity.set_entity_coords_no_offset(entitys['asteroids'][i], v3(8000, 8000, -1000))
                        entity.set_entity_as_mission_entity(entitys['asteroids'][i], true, true)
                        entity.set_entity_as_no_longer_needed(entitys['asteroids'][i])
                        entity.delete_entity(entitys['asteroids'][i])
                    end
                end
            end
            entitys['asteroids'] = {}
            Log('Asteroids Successfully Cleared.')
            Notify('Asteroids Cleared.', "Success")
        end
    end)
    Script.PlayerFeature['Player Asteroid']:set_str_data({'Start', 'Delete'})


    Script.PlayerFeature['Player Infinite Apartment Invite'] = menu.add_player_feature('Infinite Loading Screen', 'action_value_str', Script.Parent['Player Griefing'].id, function(f, id)
        if f.value == 0 then
            scriptevent.Send('Apartment Invite', {Self(), id, 4294967295, 1, 115, 0, 0, 0}, id)
        else
            scriptevent.Send('Force on Death Bike', {Self(), 0, 32, network.network_hash_from_player(id), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1}, id)
        end
    end)
    Script.PlayerFeature['Player Infinite Apartment Invite']:set_str_data{'v1', 'v2'}


    Script.PlayerFeature['Player Passive Mode'] = menu.add_player_feature("Block Passive Mode", "toggle", Script.Parent['Player Griefing'].id, function(f, id)
        while f.on do
            scriptevent.Send('Passive Mode', {Self(), 1}, id)
            coroutine.yield(100)
        end

        scriptevent.Send('Passive Mode', {Self(), 0}, id)
    end)


    Script.PlayerFeature['Player Spam Script Events'] = menu.add_player_feature('Spam Script Events', 'value_str', Script.Parent['Player Griefing'].id, function(f, id)
        if id == Self() then
            Notify('No point in doing this on yourself', "Error", '')
            f.on = false
            return
        end

        for i = 0, 31 do
            if i ~= id and player.is_player_valid(i) and Script.PlayerFeature['Player Spam Script Events'].on[i] then
                Notify('Feature is already on for another Player.', "Error", '')
                f.on = false
                return
            end
        end

        while f.on do
            scriptevent.Send('Warehouse Invite', {Self(), 0, 1, math.random(1, 22)}, id)
            scriptevent.Send('Apartment Invite', {Self(), id, 4294967295, 1, math.random(1, 114), 0, 0, 0}, id)
            scriptevent.Send('Force To Mission', {Self(), math.random(0, 7)}, id)
            --scriptevent.Send('Force To Island', {Self(), 1}, id)
            --scriptevent.Send('Casino Cutscene', {Self()}, id)
            coroutine.yield(0)
            scriptevent.Send('Vehicle Kick', {Self(), 4294967295, 4294967295, 4294967295}, id)
            --scriptevent.Send('Transaction Error', {Self(), 50000, 0, 1, scriptevent.MainGlobal(id), scriptevent.GlobalPair(), 1}, id)
            scriptevent.Send('Passive Mode', {Self(), 1}, id)
            coroutine.yield(0)
            scriptevent._notification(id, 1, math.random(1, 100000))
            scriptevent._notification(id, 2, math.random(1, 100000))
            scriptevent._notification(id, 3, math.random(1, 100000))
            scriptevent.Send('Fake Invite', {Self(), math.random(0, 190), miscdata.smslocations[math.random(#miscdata.smslocations)]}, id)
            if f.value == 1 then
                coroutine.yield(0)
                scriptevent.Send('Warehouse Invite', {Self(), 0, 1, 0}, id)
                scriptevent.Send('Apartment Invite', {Self(), id, 4294967295, 1, 115, 0, 0, 0}, id)
                coroutine.yield(0)
                scriptevent.kick(id)
                coroutine.yield(0)
                scriptevent.crash(id)
            end
            coroutine.yield(100)
        end
    end)
    Script.PlayerFeature['Player Spam Script Events']:set_str_data({'Trolling', 'Malicious'})


    Script.Parent['Player Friendly'] = menu.add_player_feature('Friendly', 'parent', Script.Parent['Player Parent'].id, nil)


    if settings['Enable Vehicle Spawner'].Enabled then
        Script.Parent['Player Spawn Vehicle'] = menu.add_player_feature('Spawn Vehicle', 'parent', Script.Parent['Player Friendly'].id, nil)


        Script.Parent['Player Spawn Vehicle Settings'] = menu.add_player_feature('Spawn Settings', 'parent', Script.Parent['Player Spawn Vehicle'].id, nil)


        Script.PlayerFeature['Player Spawn Vehicle Upgraded'] = menu.add_player_feature('Upgraded', 'value_str', Script.Parent['Player Spawn Vehicle Settings'].id)
        Script.PlayerFeature['Player Spawn Vehicle Upgraded']:set_str_data({'Max', 'Performance'})


        Script.PlayerFeature['Player Spawn Vehicle Godmode'] = menu.add_player_feature('Godmode', 'toggle', Script.Parent['Player Spawn Vehicle Settings'].id)


        Script.PlayerFeature['Player Spawn Vehicle Lockon'] = menu.add_player_feature('Lock-on Disabled', 'toggle', Script.Parent['Player Spawn Vehicle Settings'].id)


        Script.PlayerFeature['Player Spawn Vehicle Input'] = menu.add_player_feature('Model/Hash Input', 'action', Script.Parent['Player Spawn Vehicle'].id, function(f, id)
            local _input = get.Input("Enter Vehicle Model Name or Hash")
            if not _input then
                Notify('Input canceled.', "Error", '')
                return
            end

            local hash = _input
            if not tonumber(_input) then
                if mapper.veh.GetHashFromName(_input) ~= nil then
                    hash = mapper.veh.GetHashFromName(_input)
                else
                    hash = gameplay.get_hash_key(_input)
                end
            end

            if not streaming.is_model_a_vehicle(hash) then
                Notify('Input is not a valid vehicle.', "Error", '')
                return
            end

            local pos = get.PlayerCoords(id)
            pos.z = Math.GetGroundZ(pos.x, pos.y)
            local veh = Spawn.Vehicle(hash, utility.OffsetCoords(pos, get.PlayerHeading(id), 10))

            if not veh then
                Notify('Failed to spawn vehicle', 'Error', 'Vehicle Spawner')
                return
            end

            if not utility.request_ctrl(veh, 5000) then
                Notify('Failed to gain control over spawned Vehicle.', "Error", '')
            end

            decorator.decor_set_int(veh, 'MPBitset', 1 << 10)
            if Script.PlayerFeature['Player Spawn Vehicle Upgraded'].on[id] then
                utility.MaxVehicle(veh, Script.PlayerFeature['Player Spawn Vehicle Upgraded'].value[id] + 1)
            end

            if Script.PlayerFeature['Player Spawn Vehicle Godmode'].on[id] then
                entity.set_entity_god_mode(veh, true)
            end

            if Script.PlayerFeature['Player Spawn Vehicle Lockon'].on[id] then
                vehicle.set_vehicle_can_be_locked_on(veh, false, false)
            end
        end)


        for i = 1, #miscdata.VehicleCategories do
            local Name = miscdata.VehicleCategories[i]

            Script.Parent['Player Spawn ' .. Name] = menu.add_player_feature(Name, 'parent', Script.Parent['Player Spawn Vehicle'].id, nil)
            Script.Parent['Lobby Spawn ' .. Name] = menu.add_feature(Name, 'parent', Script.Parent['Lobby Spawn Vehicles'].id, nil)
        end


        menu.create_thread(function(Vehicles)
            local done = 0
            for i = 1, #Vehicles do
                if done == 50 then
                    coroutine.yield(0)
                end

                local Hash = Vehicles[i].Hash
                local Name = Vehicles[i].Name
                local Model = Vehicles[i].Model
                local Category = Vehicles[i].Category

                if (Category == "Trains") or (Category == "Invalid") or Category == "Utility" or not streaming.is_model_a_vehicle(Hash) then
                    goto continue
                end

                Script.PlayerFeature['Player Spawn ' .. Model] = menu.add_player_feature(Name, 'action', Script.Parent['Player Spawn ' .. Category].id, function(f, id)
                    local pos = get.PlayerCoords(id)
                    pos.z = Math.GetGroundZ(pos.x, pos.y)
                    local veh = Spawn.Vehicle(Hash, utility.OffsetCoords(pos, get.PlayerHeading(id), 10))

                    if not veh then
                        Notify('Failed to spawn vehicle', 'Error', 'Vehicle Spawner')
                        return
                    end
        
                    if not utility.request_ctrl(veh, 5000) then
                        Notify('Failed to gain control over spawned Vehicle.', "Error", '')
                    end
        
                    decorator.decor_set_int(veh, 'MPBitset', 1 << 10)
                    if Script.PlayerFeature['Player Spawn Vehicle Upgraded'].on[id] then
                        utility.MaxVehicle(veh, Script.PlayerFeature['Player Spawn Vehicle Upgraded'].value[id] + 1)
                    end
        
                    if Script.PlayerFeature['Player Spawn Vehicle Godmode'].on[id] then
                        entity.set_entity_god_mode(veh, true)
                    end
        
                    if Script.PlayerFeature['Player Spawn Vehicle Lockon'].on[id] then
                        vehicle.set_vehicle_can_be_locked_on(veh, false, false)
                    end
                end)

                Script.Feature['Lobby Spawn ' .. Model] = menu.add_feature(Name, 'action', Script.Parent['Lobby Spawn ' .. Category].id, function(f)
                    for id = 0, 31 do
                        if player.is_player_valid(id) and id ~= Self() and not player.is_player_god(id) and interior.get_interior_from_entity(get.PlayerPed(id)) == 0 then
                            local pos = get.PlayerCoords(id)
                            pos.z = Math.GetGroundZ(pos.x, pos.y)
        
                            local veh = Spawn.Vehicle(Hash, utility.OffsetCoords(pos, get.PlayerHeading(id), 10))

                            if not veh then
                                Notify('Failed to spawn vehicle for player ' .. get.Name(id), 'Error', 'Vehicle Spawner')
                                
                            else
                                utility.request_ctrl(veh)
                                decorator.decor_set_int(veh, 'MPBitset', 1 << 10)
            
                                if Script.Feature['Lobby Spawn Vehicle Upgraded'].on then
                                    utility.MaxVehicle(veh, Script.Feature['Lobby Spawn Vehicle Upgraded'].value + 1)
                                end
            
                                if Script.Feature['Lobby Spawn Vehicle Godmode'].on then
                                    entity.set_entity_god_mode(veh, true)
                                end
            
                                if Script.Feature['Lobby Spawn Vehicle Lockon'].on then
                                    vehicle.set_vehicle_can_be_locked_on(veh, false, false)
                                end
                            end
                        end
                    end
                end)

                ::continue::
                done = done + 1
            end
        end, mapper.veh.GetAllVehicles())
    end


    Script.Parent['Player CEO Money'] = menu.add_player_feature('CEO Money', 'parent', Script.Parent['Player Friendly'].id, function()
        if not Script.Feature['Disable Warning Messages'].on then
            Notify('The Target must be an associate in any Organisation to receive the Money.\nEnabling multiple Loops at once can cause Transaction Errors.', "Neutral")
            coroutine.yield(5000)
        end
    end)


    Script.PlayerFeature['Player CEO Loop Preset'] = menu.add_player_feature('Preset', 'value_str', Script.Parent['Player CEO Money'].id, function(f, id)
        if id == Self() then
            Notify('This doesnt work on yourself.', "Error", '')
            f.on = false
            return
        end

        if not scriptevent.IsPlayerAssociate(id) then
            Notify('Player is not an associate.', "Error", '')
            f.on = false
            return
        end

        if f.value == 0 then
            menu.create_thread(function()
                while f.on do
                    if scriptevent.IsPlayerAssociate(id) then
                        scriptevent.Send('CEO Money', {Self(), 10000, -1292453789, 1, scriptevent.MainGlobal(id), scriptevent.GlobalPair()}, id)
                    end
    
                    coroutine.yield(40000)
                end
            end, nil)
    
            coroutine.yield(5000)
            while f.on do
                if scriptevent.IsPlayerAssociate(id) then
                    scriptevent.Send('CEO Money', {Self(), 30000, 198210293, 1, scriptevent.MainGlobal(id), scriptevent.GlobalPair()}, id)
                end
    
                coroutine.yield(150000)
            end

            return
        end

        local resumenormal  
        while f.on do
            if not resumenormal then
                for i = 1, 5 do
                    for j = 1, 5 do
                        if not f.on then
                            return
                        end

                        if scriptevent.IsPlayerAssociate(id) then
                            scriptevent.Send('CEO Money', {Self(), 10000, -1292453789, 1, scriptevent.MainGlobal(id), scriptevent.GlobalPair()}, id)
                        end
                        
                        coroutine.yield(30000)
                    end
                        
                    if not f.on then
                        return
                    end

                    coroutine.yield(40000)

                    if scriptevent.IsPlayerAssociate(id) then
                        scriptevent.Send('CEO Money', {Self(), 30000, 198210293, 1, scriptevent.MainGlobal(id), scriptevent.GlobalPair()}, id)
                    end

                    coroutine.yield(40000)
                end

                resumenormal = true
            end

            for i = 1, 10 do
                if not f.on then
                    return
                end
                 
                if scriptevent.IsPlayerAssociate(id) then
                    scriptevent.Send('CEO Money', {Self(), 10000, -1292453789, 1, scriptevent.MainGlobal(id), scriptevent.GlobalPair()}, id)
                end

                coroutine.yield(30000)
            end

            resumenormal = false
        end
    end)
    Script.PlayerFeature['Player CEO Loop Preset']:set_str_data({'Fast', 'Stable'})


    for i = 1, #miscdata.ceomoney do
        Script.PlayerFeature['Player CEO Loop ' .. i] = menu.add_player_feature(miscdata.ceomoney[i][1] .. ' (ms)', 'value_i', Script.Parent['Player CEO Money'].id, function(f, id)
            if id == Self() then
                Notify('This doesnt work on yourself.', "Error", '')
                f.on = false
                return
            end

            if not scriptevent.IsPlayerAssociate(id) then
                Notify('Player is not an associate.', "Error", '')
                f.on = false
                return
            end

            while f.on do
                if scriptevent.IsPlayerAssociate(id) then
                    scriptevent.Send('CEO Money', {Self(), miscdata.ceomoney[i][2], miscdata.ceomoney[i][3], miscdata.ceomoney[i][4], scriptevent.MainGlobal(id), scriptevent.GlobalPair()}, id)
                end

                coroutine.yield(f.value)
            end
            
        end)
        Script.PlayerFeature['Player CEO Loop ' .. i].min = 10000
        Script.PlayerFeature['Player CEO Loop ' .. i].max = 300000
        Script.PlayerFeature['Player CEO Loop ' .. i].mod = 10000
        Script.PlayerFeature['Player CEO Loop ' .. i].value = miscdata.ceomoney[i][5]
    end


    Script.PlayerFeature['Give Collectibles'] = menu.add_player_feature('Give Collectibles', 'action_value_str', Script.Parent['Player Friendly'].id, function(f, id)
        local data = {
            ["Movie Props"] = {ID = 0, Times = 9},
            ["Hidden Caches"] = {ID = 1, Times = 9},
            ["Treasure Chests"] = {ID = 2, Times = 1},
            ["Radio Antennas"] = {ID = 3, Times = 9},
            ["Media USBs"] = {ID = 4, Times = 19},
            ["Shipwreck"] = {ID = 5, Times = 0},
            ["Burried Stashes"] = {ID = 6, Times = 9},
            ["Halloween T-Shirt"] = {ID = 7, Times = 0},
            ["Jack O' Lanterns"] = {ID = 8, Times = 9},
            ["LD Organics Product"] = {ID = 9, Times = 99},
            ["Junk Energy Skydives"] = {ID = 10, Times = 9},
        }

        local selection =  data[f:get_str_data()[f.value + 1]]
        if selection.Times == 0 then
            scriptevent.Send('Collectibles', {Self(), selection.ID, 0, 1, 1, 1}, id)

        else
            for i = 0, selection.Times do
                scriptevent.Send('Collectibles', {Self(), selection.ID, i, 1, 1, 1}, id)

                if i == 25 or i == 50 or i == 75 then
                    coroutine.yield(50)
                end
            end
        end

        Notify('Gave collectibles to player.', 'Success', 'Give Collectibles')
    end)
    Script.PlayerFeature['Give Collectibles']:set_str_data({'Movie Props', 'Hidden Caches', 'Treasure Chests', 'Radio Antennas', 'Media USBs', 'Shipwreck', 'Burried Stashes', 'Halloween T-Shirt', "Jack O' Lanterns", 'LD Organics Product', 'Junk Energy Skydives'})


    Script.PlayerFeature['RP Drop'] = menu.add_player_feature("RP Drop", "slider", Script.Parent['Player Friendly'].id, function(f, id)
        if not menu.is_trusted_mode_enabled(1 << 2) then
            Notify('Not available while trusted mode for natives is turned off', 'Error', 'RP Drop')
            f.on = false
            return
        end

        local hashes = {1298470051, 446117594, 1025210927, 437412629}

        while f.on do
            if not menu.is_trusted_mode_enabled(1 << 2) then
                f.on = false
            end

            local Hash = hashes[math.random(#hashes)]
            utility.request_model(Hash)

            local random = (math.random() + math.random(-80, 80)) / 100
            local pos = player.get_player_coords(id) + v3(random, random, 1)
    
            N.OBJECT.CREATE_AMBIENT_PICKUP(0x2C014CA6, pos, 0, 1, Hash, 0, 1)
    
            coroutine.yield(1000 - math.floor(f.value))
        end

        for i = 1, #hashes do
            streaming.set_model_as_no_longer_needed(hashes[i])
        end
    end)
    Script.PlayerFeature['RP Drop'].min = 0
    Script.PlayerFeature['RP Drop'].max = 1000
    Script.PlayerFeature['RP Drop'].mod = 100


    Script.PlayerFeature['Give Parachute'] = menu.add_player_feature('Give Parachute', 'action', Script.Parent['Player Friendly'].id, function(f, id)
        weapon.give_delayed_weapon_to_ped(get.PlayerPed(id), 0xFBAB5776, 1, 1)
        Notify('Gave parachute to player.', 'Success', 'Give Parachute')
    end)


    Script.PlayerFeature['Off The Radar'] = menu.add_player_feature('Off The Radar', 'value_str', Script.Parent['Player Friendly'].id, function(f, id)
        if f.value == 0 then
            if not scriptevent.IsPlayerOTR(id) then
                scriptevent.Send('Off The Radar', {Self(), utils.time() - 60, utils.time(), 1, 1, scriptevent.MainGlobal(id)}, id)
            end
            f.on = false
        end

        while f.on do
            if f.value == 0 then
                f.on = false
            end

            if not scriptevent.IsPlayerOTR(id) then
                scriptevent.Send('Off The Radar', {Self(), utils.time() - 60, utils.time(), 1, 1, scriptevent.MainGlobal(id)}, id)
            end

            coroutine.yield(500)
        end
    end)
    Script.PlayerFeature['Off The Radar']:set_str_data({'Once', 'Loop'})


    Script.PlayerFeature['Bribe Authorities'] = menu.add_player_feature('Bribe Authorities', 'toggle', Script.Parent['Player Friendly'].id, function(f, id)
        while f.on do
            scriptevent.Send('Bribe Authorities', {Self(), 0, 0, utils.time_ms(), 0, scriptevent.MainGlobal(id)}, id)
            coroutine.yield(500)
        end
    end)


    Script.PlayerFeature['Explosive Ammo'] = menu.add_player_feature('Explosive Ammo', 'toggle', Script.Parent['Player Friendly'].id, function(f, id)
        while f.on do
            local Ped = get.PlayerPed(id)
            if ped.is_ped_shooting(Ped) then
                local shot, pos = ped.get_ped_last_weapon_impact(Ped)
                if shot then
                    fire.add_explosion(pos, 1, true, false, 0.5, 0)
                end
            end

            coroutine.yield(0)
        end
    end)


    Script.Parent['Ped Assassins'] = menu.add_player_feature('Ped Assassins', 'parent', Script.Parent['Player Parent'].id, nil)


    Script.PlayerFeature['Clear Assassins'] = menu.add_player_feature('Clear Peds', 'action', Script.Parent['Ped Assassins'].id, function()
        Log('Clearing Ped Assassins...')
        utility.clear(entitys['peds'])
        entitys['peds'] = {}
        Log('Ped Assassins Successfully Cleared.')
        Notify('Ped Assassins Cleared.', "Success")
    end)


    Script.PlayerFeature['Ped Assassins Input'] = menu.add_player_feature('Send Assassins: Input', 'action', Script.Parent['Ped Assassins'].id, function(f, id)

        local _input = get.Input("Enter ped model name")
        if not _input then
            Notify('Input canceled.', "Error", '')
            return
        end

        local hash = gameplay.get_hash_key(_input)
        local pos
        
        for i = 1, Script.Feature['Amount of Assassins'].value do
            local assassin = entitys['peds'][#entitys['peds'] + 1]

            pos = get.PlayerCoords(id) + v3(math.random(-50, 50), math.random(-50, 50), 0)
            pos.z = Math.GetGroundZ(pos.x, pos.y)

            assassin = Spawn.Ped(hash, pos, 26)
            if ped_type ~= 28 then
                weapon.give_delayed_weapon_to_ped(assassin, 0xDBBD7280, 1, 1)
            end

            if Script.Feature['Godmode Assassins'].on then
                entity.set_entity_god_mode(assassin, true)
            else
                ped.set_ped_max_health(assassin, 328)
                ped.set_ped_health(assassin, 328)
            end

            ped.set_ped_combat_attributes(assassin, 46, true)
            ped.set_ped_combat_ability(assassin, 2)
            ped.set_ped_config_flag(assassin, 187, 0)
            ped.set_ped_can_ragdoll(assassin, false)

            menu.create_thread(Threads.Assassins, {assassin, id})
        end
    end)


    Script.PlayerFeature['Ped Assassins Clones'] = menu.add_player_feature('Send Clones', 'action', Script.Parent['Ped Assassins'].id, function(f, id)
        local pos
        local playerped = get.PlayerPed(id)
        local Weapon = ped.get_current_ped_weapon(playerped)
        if Weapon == 0xA2719263 or Weapon == 0xBA45E8B8 or Weapon == 0xAB564B93 or Weapon == 0x2C3731D9 or Weapon == 0x24B17070 or Weapon == 0x497FACC3 or Weapon == 0x93E220BD then
            Weapon = 0xC0A3098D
        end

        for i = 1, Script.Feature['Amount of Assassins'].value do
            pos = get.PlayerCoords(id) + v3(math.random(-50, 50), math.random(-50, 50), 0)
            pos.z = Math.GetGroundZ(pos.x, pos.y)

            entitys['peds'][#entitys['peds'] + 1] = ped.clone_ped(playerped)
            
            local assassin = entitys['peds'][#entitys['peds']]

            entity.set_entity_coords_no_offset(assassin, pos)
            weapon.give_delayed_weapon_to_ped(assassin, Weapon, 1, 1)

            if Script.Feature['Godmode Assassins'].on then
                entity.set_entity_god_mode(assassin, true)
            else
                ped.set_ped_max_health(assassin, 328)
                ped.set_ped_health(assassin, 328)
            end

            ped.set_ped_combat_attributes(assassin, 46, true)
            ped.set_ped_combat_ability(assassin, 2)
            ped.set_ped_config_flag(assassin, 187, 0)
            ped.set_ped_can_ragdoll(assassin, false)

            menu.create_thread(Threads.Assassins, {assassin, id})
        end
    end)


    for i = 1, #customData.ped_assassins do
        Script.PlayerFeature['Send ' .. customData.ped_assassins[i].Name] = menu.add_player_feature('Send ' .. customData.ped_assassins[i].Name, 'action', Script.Parent['Ped Assassins'].id, function(f, id)
            local pos
            local hash = customData.ped_assassins[i].Hash
            local ped_type = customData.ped_assassins[i].PedType
            local ped_weapon = customData.ped_assassins[i].Weapon

            if not ped_weapon then 
                ped_weapon = 0xDBBD7280 
            end

            for i = 1, Script.Feature['Amount of Assassins'].value do
                pos = get.PlayerCoords(id) + v3(math.random(-50, 50), math.random(-50, 50), 0)
                pos.z = Math.GetGroundZ(pos.x, pos.y)

                entitys['peds'][#entitys['peds'] + 1] = Spawn.Ped(hash, pos, ped_type)

                local assassin = entitys['peds'][#entitys['peds']]

                if ped_type ~= 28 then
                    weapon.give_delayed_weapon_to_ped(assassin, ped_weapon, 1, 1)
                end

                if Script.Feature['Godmode Assassins'].on then
                    entity.set_entity_god_mode(assassin, true)
                else
                    ped.set_ped_max_health(assassin, 328)
                    ped.set_ped_health(assassin, 328)
                end

                ped.set_ped_combat_attributes(assassin, 46, true)
                ped.set_ped_combat_ability(assassin, 2)
                ped.set_ped_config_flag(assassin, 187, 0)
                ped.set_ped_can_ragdoll(assassin, false)
                ped.set_can_attack_friendly(assassin, false, false)

                menu.create_thread(Threads.Assassins, {assassin, id})
            end
        end)
    end


    Script.Parent['Player SMS Sender'] = menu.add_player_feature('SMS Sender', 'parent', Script.Parent['Player Parent'].id)


    Script.PlayerFeature['Player Send Custom SMS'] = menu.add_player_feature('Send SMS: Input', 'action', Script.Parent['Player SMS Sender'].id, function(f, id)
        local msg = get.Input('Enter message to send')
        if not msg then
            Notify('Input canceled.', "Error", '')
            return
        end

        player.send_player_sms(id, msg)
    end)


    Script.PlayerFeature['Player Send SCID And IP'] = menu.add_player_feature('Send their SCID & IP', 'action', Script.Parent['Player SMS Sender'].id, function(f, id)
        local name = get.Name(id)
        local scid = tostring(get.SCID(id))
        local ip = get.IP(id)

        player.send_player_sms(id, 'Name: ' .. name ..  '\nR*SCID: ' .. scid .. '\nIP: ' .. ip)
    end)


    Script.PlayerFeature['Player SMS Delay'] = menu.add_player_feature('Spam Speed', 'autoaction_slider', Script.Parent['Player SMS Sender'].id)
    Script.PlayerFeature['Player SMS Delay'].min = 250
    Script.PlayerFeature['Player SMS Delay'].max = 10000
    Script.PlayerFeature['Player SMS Delay'].mod = 250


    Script.PlayerFeature['Player Spam Custom SMS'] = menu.add_player_feature('Spam SMS: Input', 'toggle', Script.Parent['Player SMS Sender'].id, function(f, id)
        local msg = get.Input('Enter message to spam')

        if not msg then
            Notify('Input canceled.', "Error", '')
            f.on = false
            return
        end

        while f.on do
            player.send_player_sms(id, msg)

            coroutine.yield(10000 - math.floor(Script.PlayerFeature['Player SMS Delay'].value[id]))
        end
    end)


    Script.PlayerFeature['Player SMS SCID IP'] = menu.add_player_feature('Spam their SCID & IP', 'toggle', Script.Parent['Player SMS Sender'].id, function(f, id)
        local name = get.Name(id)
        local scid = tostring(get.SCID(id))
        local ip = get.IP(id)

        while f.on do
            player.send_player_sms(id, 'Name: ' .. name ..  '\nR*SCID: ' .. scid .. '\nIP: ' .. ip)

            coroutine.yield(10000 - math.floor(Script.PlayerFeature['Player SMS Delay'].value[id]))
        end
    end)
    

    Script.Parent['Player Miscellaneous'] = menu.add_player_feature('Miscellaneous', 'parent', Script.Parent['Player Parent'].id, nil)


    Script.PlayerFeature['Player Log Script Events'] = menu.add_player_feature('Log Script Events', 'toggle', Script.Parent['Player Miscellaneous'].id, function(f, id)
            if hooks.script[id] == nil then
                local initname
                hooks.script[id] = hook.register_script_event_hook(function(source, target, params, count)
                    if not initname then
                        initname = get.Name(id)
                    end

                    for i = 1, #params do
                        params[i] = params[i] & 0xFFFFFFFF
                    end

                    if source == id then
                        local prefix = Math.TimePrefix()
                        local scid = get.SCID(id)
                        local name = get.Name(id)

                        if initname ~= name then
                            Notify("Removed script event hook as player " .. initname .. " is no longer valid", "Neutral", 'Script Event Logger')
                            hook.remove_script_event_hook(hooks.script[id])
                            return
                        end

                        local uuid = tostring(scid) .. '-' .. name
                        local file = paths['Event-Logger'] .. '\\' .. uuid .. '\\' .. 'Script-Events.log'
                        local prefix = prefix .. ' [Script-Event-Logger]'
                        local text = prefix
                        if not utils.dir_exists(paths['Event-Logger']) then
                            utils.make_dir(paths['Event-Logger'])
                        end
                        if not utils.dir_exists(paths['Event-Logger'] .. '\\' .. uuid) then
                            utils.make_dir(paths['Event-Logger'] .. '\\' .. uuid)
                        end
                        if not utils.file_exists(file) then
                            Notify("Logging to folder '2Take1Script/Event-Logger/" .. uuid, "Success", 'Script Event Logger')
                            text =
                                'Starting to log Script-Events from Player: ' ..
                                name .. ':' .. scid .. '\n' .. prefix
                        end
                        text = text .. '\n' .. params[1] .. ', {'
                        for i = 2, #params do
                            text = text .. params[i]
                            if i ~= #params then
                                text = text .. ', '
                            end
                        end
                        text = text .. '}\n'
                        text = text .. 'Parameter count: ' .. count - 1 .. '\n'
                        utility.write(io.open(file, 'a'), text)
                        print(text)
                    end
                end)
            else
                if hooks.script[id] then
                    hook.remove_script_event_hook(hooks.script[id])
                    hooks.script[id] = nil
                end
            end
    end)


    Script.PlayerFeature['Player Reset SE Log'] = menu.add_player_feature('Reset Script Event Log', 'action', Script.Parent['Player Miscellaneous'].id, function(f, id)
        local scid = get.SCID(id)
        local name = get.Name(id)
        local uuid = tostring(scid) .. '-' .. name
        local file = paths['Event-Logger'] .. '\\' .. uuid .. '\\' .. 'Script-Events.log'
        if utils.file_exists(file) then
            io.remove(file)
        else
            Notify('There was no log to reset.', "Error", 'Event Logger')
        end
    end)


    Script.PlayerFeature['Player Log Net Events'] = menu.add_player_feature('Log net_events', 'toggle', Script.Parent['Player Miscellaneous'].id, function(f, id)
            if hooks.net[id] == nil then
                local initname
                hooks.net[id] = hook.register_net_event_hook(function(source, target, eventId)
                    if not initname then
                        initname = get.Name(id)
                    end

                    if source == id then
                        local prefix = Math.TimePrefix()
                        local scid = get.SCID(id)
                        local name = get.Name(id)

                        if initname ~= name then
                            Notify("Removed net event hook as player " .. initname .. " is no longer valid", "Neutral", 'Net Event Logger')

                            hook.remove_net_event_hook(hooks.net[id])
                            return
                        end

                        local uuid = tostring(scid) .. '-' .. name
                        local file = paths['Event-Logger'] .. '\\' .. uuid .. '\\' .. 'Net-Events.log'
                        local prefix = prefix .. ' [Net-Event-Logger]'
                        local text = prefix
                        if not utils.dir_exists(paths['Event-Logger']) then
                            utils.make_dir(paths['Event-Logger'])
                        end
                        if not utils.dir_exists(paths['Event-Logger'] .. '\\' .. uuid) then
                            utils.make_dir(paths['Event-Logger'] .. '\\' .. uuid)
                        end
                        if not utils.file_exists(file) then
                            Notify("Logging to folder 2Take1Script/Event-Logger/" .. uuid, "Success", 'Net Event Logger')
                            text =
                                'Starting to log Net-Events from Player: ' ..
                                name .. ':' .. scid .. '\n' .. text
                        end
                        local event_name = mapper.net.GetEventName(eventId)
                        text = text .. '\nEvent: ' .. event_name .. '\nEvent ID: ' .. eventId .. '\n'
                        utility.write(io.open(file, 'a'), text)
                    end
                end)
            else
                if hooks.net[id] then
                    hook.remove_net_event_hook(hooks.net[id])
                    hooks.net[id] = nil
                end
            end
    end)


    Script.PlayerFeature['Player Reset Net Log'] = menu.add_player_feature('Reset net_event Log', 'action', Script.Parent['Player Miscellaneous'].id, function(f, id)
        local scid = get.SCID(id)
        local name = get.Name(id)
        local uuid = tostring(scid) .. '-' .. name
        local file = paths['Event-Logger'] .. '\\' .. uuid .. '\\' .. 'Net-Events.log'
        if utils.file_exists(file) then
            io.remove(file)
        else
            Notify('There was no log to reset.', "Error", 'Event Logger')
        end
    end)


    Script.Parent['Entity Spam'] = menu.add_player_feature('Entity Spam', 'parent', Script.Parent['Player Parent'].id, function()
        if not Script.Feature['Disable Warning Messages'].on then
            Notify('Its recommended to keep distance from the Target while using this.', "Neutral", 'Entity Spam')
            coroutine.yield(5000)
        end
    end)


    Script.PlayerFeature['Entity Spam Clear'] = menu.add_player_feature('Delete Spam Entities', 'action', Script.Parent['Entity Spam'].id, function()
        Log('Clearing Spam Entities...')
        utility.clear(entitys['entity_spam'])
        entitys['entity_spam'] = {}
        Log('Spam Entities Successfully Cleared.')
        Notify('Spam Entities Cleared.', "Success", 'Entity Spam')
    end)


    Script.Parent['Entity Spam Presets'] = menu.add_player_feature('Spam Presets', 'parent', Script.Parent['Entity Spam'].id, nil)


    for i = 1, #customData.entity_spam do
        Script.PlayerFeature['Spam Entity ' .. customData.entity_spam[i].Name] = menu.add_player_feature(customData.entity_spam[i].Name, 'action', Script.Parent['Entity Spam Presets'].id, function(f, id)
            local hash = customData.entity_spam[i].Hash
            local pos

            if streaming.is_model_a_ped(hash) then
                for i = 1, Script.Feature['Entity Spam Amount'].value do
                    if Script.Feature['Entity Spam Location'].value == 0 then
                        pos = get.PlayerCoords(id) + v3(math.random(-10, 10), math.random(-10, 10), 0)
                        pos.z = Math.GetGroundZ(pos.x, pos.y)
                    elseif Script.Feature['Entity Spam Location'].value == 1 then
                        pos = get.PlayerCoords(id) + v3(0, 0, 75)
                    else
                        pos = get.PlayerCoords(id) + v3(0, 0, 1)
                    end

                    entitys['entity_spam'][#entitys['entity_spam'] + 1] = Spawn.Ped(hash, pos)
                    coroutine.yield(0)
                end

            elseif streaming.is_model_a_vehicle(hash) then
                for i = 1, Script.Feature['Entity Spam Amount'].value do
                    if Script.Feature['Entity Spam Location'].value == 0 then
                        pos = get.PlayerCoords(id) + v3(math.random(-10, 10), math.random(-10, 10), 0)
                        pos.z = Math.GetGroundZ(pos.x, pos.y)
                    elseif Script.Feature['Entity Spam Location'].value == 1 then
                        pos = get.PlayerCoords(id) + v3(0, 0, 75)
                    else
                        pos = get.PlayerCoords(id) + v3(0, 0, 1)
                    end

                    entitys['entity_spam'][#entitys['entity_spam'] + 1] = Spawn.Vehicle(hash, pos)
                    coroutine.yield(0)
                end

            elseif streaming.is_model_an_object(hash) then
                for i = 1, Script.Feature['Entity Spam Amount'].value do
                    if Script.Feature['Entity Spam Location'].value == 0 then
                        pos = get.PlayerCoords(id) + v3(math.random(-10, 10), math.random(-10, 10), 0)
                        pos.z = Math.GetGroundZ(pos.x, pos.y)
                    elseif Script.Feature['Entity Spam Location'].value == 1 then
                        pos = get.PlayerCoords(id) + v3(0, 0, 75)
                    else
                        pos = get.PlayerCoords(id) + v3(0, 0, 1)
                    end

                    entitys['entity_spam'][#entitys['entity_spam'] + 1] = Spawn.Object(hash, pos)
                    coroutine.yield(0)
                end

            else
                Notify('Invalid Preset.\nHash is not a valid entity', "Error", '')
                return
            end

            if not Script.Feature['Entity Spam Cleanup'].on then
                Notify("Entities sent", "Success", 'Entity Spam')
                return
            end

            Notify("Entities sent, starting cleanup in 10 seconds...", "Success", 'Entity Spam')
            coroutine.yield(10000)
            
            utility.clear(entitys['entity_spam'])
            entitys['entity_spam'] = {}
            Notify('Cleanup complete.', "Success", 'Entity Spam')
        end)
    end


    Script.PlayerFeature['Ped Spam Input'] = menu.add_player_feature('Ped: Input', 'action', Script.Parent['Entity Spam'].id, function(f, id)
        local _input = get.Input("Enter Ped Model Name or Hash")
        if not _input then
            Notify('Input canceled.', "Error", 'Entity Spam')
            return
        end

        local hash = _input
        if not tonumber(_input) then
            hash = gameplay.get_hash_key(_input)
        end

        if not streaming.is_model_a_ped(hash) then
            Notify('Input is not a valid ped.', "Error", 'Entity Spam')
            return
        end

        for i = 1, Script.Feature['Entity Spam Amount'].value do
            local pos
            if Script.Feature['Entity Spam Location'].value == 0 then
                pos = get.PlayerCoords(id) + v3(math.random(-10, 10), math.random(-10, 10), 0)
                pos.z = Math.GetGroundZ(pos.x, pos.y)
            elseif Script.Feature['Entity Spam Location'].value == 1 then
                pos = get.PlayerCoords(id) + v3(0, 0, 10)
            else
                pos = get.PlayerCoords(id) + v3(0, 0, 1)
            end
            entitys['entity_spam'][#entitys['entity_spam'] + 1] = Spawn.Ped(hash, pos)
            coroutine.yield(0)
        end

        if not Script.Feature['Entity Spam Cleanup'].on then
            Notify("Peds sent", "Success", 'Entity Spam')
            return
        end

        Notify("Peds sent, starting cleanup in 10 seconds...", "Success", 'Entity Spam')
        coroutine.yield(10000)

        utility.clear(entitys['entity_spam'])
        entitys['entity_spam'] = {}
        Notify('Cleanup complete.', "Success", 'Entity Spam')
    end)


    Script.PlayerFeature['Vehicle Spam Input'] = menu.add_player_feature('Vehicle: Input', 'action', Script.Parent['Entity Spam'].id, function(f, id)
        local _input = get.Input("Enter Vehicle Model Name or Hash")
        if not _input then
            Notify('Input canceled.', "Error", 'Entity Spam')
            return
        end

        local hash = _input
        if not tonumber(_input) then
            hash = gameplay.get_hash_key(_input)
        end

        if not streaming.is_model_a_vehicle(hash) then
            Notify('Input is not a valid vehicle.', "Error", 'Entity Spam')
            return
        end

        for i = 1, Script.Feature['Entity Spam Amount'].value do
            local pos
            if Script.Feature['Entity Spam Location'].value == 0 then
                pos = get.PlayerCoords(id) + v3(math.random(-10, 10), math.random(-10, 10), 0)
                pos.z = Math.GetGroundZ(pos.x, pos.y)
            elseif Script.Feature['Entity Spam Location'].value == 1 then
                pos = get.PlayerCoords(id) + v3(0, 0, 10)
            else
                pos = get.PlayerCoords(id) + v3(0, 0, 1)
            end
            entitys['entity_spam'][#entitys['entity_spam'] + 1] = Spawn.Vehicle(hash, pos)
        end

        if not Script.Feature['Entity Spam Cleanup'].on then
            Notify("Vehicles sent", "Success", 'Entity Spam')
            return
        end

        Notify('Vehicles sent, starting cleanup in 10 seconds...', "Success", 'Entity Spam')
        coroutine.yield(10000)

        utility.clear(entitys['entity_spam'])
        entitys['entity_spam'] = {}
        Notify('Cleanup complete.', "Success", 'Entity Spam') 
    end)


    Script.PlayerFeature['Object Spam Input'] = menu.add_player_feature('Object: Input', 'action', Script.Parent['Entity Spam'].id, function(f, id)
        local _input = get.Input("Enter Object Model Name or Hash")
        if not _input then
            Notify('Input canceled.', "Error", 'Entity Spam')
            return
        end

        local hash = _input
        if not tonumber(_input) then
            hash = gameplay.get_hash_key(_input)
        end

        if not streaming.is_model_an_object(hash) then
            Notify('Input is not a valid object.', "Error", 'Entity Spam')
            return
        end

        for i = 1, Script.Feature['Entity Spam Amount'].value do
            local pos
            if Script.Feature['Entity Spam Location'].value == 0 then
                pos = get.PlayerCoords(id) + v3(math.random(-10, 10), math.random(-10, 10), 0)
                pos.z = Math.GetGroundZ(pos.x, pos.y)
            elseif Script.Feature['Entity Spam Location'].value == 1 then
                pos = get.PlayerCoords(id) + v3(0, 0, 10)
            else
                pos = get.PlayerCoords(id) + v3(0, 0, 1)
            end
            entitys['entity_spam'][#entitys['entity_spam'] + 1] = Spawn.Object(hash, pos)
            coroutine.yield(0)
        end

        if not Script.Feature['Entity Spam Cleanup'].on then
            Notify("Objects sent", "Success", 'Entity Spam')
            return
        end

        Notify("Objects sent, starting cleanup in 10 seconds...", "Success", 'Entity Spam')
        coroutine.yield(10000)
        
        utility.clear(entitys['entity_spam'])
        entitys['entity_spam'] = {}
        Notify('Cleanup complete.', "Success", 'Entity Spam') 
    end)


    Script.PlayerFeature['Dump All Entites onto Player'] = menu.add_player_feature('Dump All Entites onto Player', 'action', Script.Parent['Entity Spam'].id, function(f, id)
        if id == Self() then
            Notify('Doing this on yourself would result in a crash.', "Error", 'Dump Entites onto Player')
            return
        end
        
        local pos = get.PlayerCoords(id)
        local allpeds = ped.get_all_peds()
        local allvehicles = vehicle.get_all_vehicles()
        local allobjects = object.get_all_objects()
        local ownped = get.OwnPed()
        local ownvehicle = get.OwnVehicle()

        for i = 1, #allpeds do
            if allpeds[i] ~= ownped then
                entity.set_entity_coords_no_offset(allpeds[i], pos)
            end
        end
        for i = 1, #allvehicles do
            if allvehicles[i] ~= ownvehicle then
                entity.set_entity_coords_no_offset(allvehicles[i], pos)
            end
        end
        for i = 1, #allobjects do
            entity.set_entity_coords_no_offset(allobjects[i], pos)
        end
    end)


    Script.Parent['Player Removal'] = menu.add_player_feature('Player Removal', 'parent', Script.Parent['Player Parent'].id, nil)


    Script.PlayerFeature['Kick Player'] = menu.add_player_feature('Kick Player', 'action_value_str', Script.Parent['Player Removal'].id, function(f, id)
        if id == Self() then
            Notify('No point in kicking yourself.', "Error", 'Kick Player')
            return
        end

        if f.value == 0 then
            scriptevent.kick(id)

        elseif f.value == 1 then
            local pos = get.PlayerCoords(id)
            local target = get.PlayerPed(id)
            utility.request_model(1025210927)

            ped.clear_ped_tasks_immediately(target)
            N.OBJECT.CREATE_AMBIENT_PICKUP(0x2C014CA6, pos, 1, math.random(8989, 9090), 1025210927, 1, 1)

        elseif f.value == 2 then
            if not network.network_is_host() then
                Notify('You are not Session Host.', "Error", 'Kick Player')
                return
            end

            network.network_session_kick_player(id)

        end

        Notify('Kick sent.', "Success", 'Kick Player')
    end)
    Script.PlayerFeature['Kick Player']:set_str_data({'Script Event', 'PU Kick', 'Host Kick'})


    Script.PlayerFeature['Script Event Crash'] = menu.add_player_feature('Script Event Crash', 'action', Script.Parent['Player Removal'].id, function(f, id)
        if id == Self() then
            Notify('No point in crashing yourself.', "Error", 'Crash Player')
            return
        end

        scriptevent.crash(id)
        Notify("Crash sent.", "Success", 'Crash Player')
    end)


    Script.PlayerFeature['Sound Spam Crash'] = menu.add_player_feature('Sound Spam Crash', 'action', Script.Parent['Player Removal'].id, function(f, id)
        if id == Self() then
            Notify('No point in crashing yourself.', "Error", 'Crash Player')
            return
        end

        local sounds = {
            {Name = 'ROUND_ENDING_STINGER_CUSTOM', Ref = 'CELEBRATION_SOUNDSET'},
            {Name = 'Object_Dropped_Remote', Ref = 'GTAO_FM_Events_Soundset'},
            {Name = 'Oneshot_Final', Ref = 'MP_MISSION_COUNTDOWN_SOUNDSET'},
            {Name = '5s', Ref = 'MP_MISSION_COUNTDOWN_SOUNDSET'}
        }

        local sound = sounds[math.random(#sounds)]
        local time = utils.time_ms() + 2500

        while time > utils.time_ms() do
            local pos = get.PlayerCoords(id)

            for i = 1, 10 do
                audio.play_sound_from_coord(-1, sound.Name, pos, sound.Ref, true, 10, false)
            end

            coroutine.yield(0)
        end
        Notify("Crash sent.", "Success", 'Crash Player')
    end)

    
    Script.PlayerFeature['Tow Truck Crash'] = menu.add_player_feature('Tow Truck Crash', 'action', Script.Parent['Player Removal'].id, function(f, id)
        if id == Self() then
            Notify('No point in crashing yourself.', "Error", 'Crash Player')
            return
        end

        local pos = get.PlayerCoords(id)

        local truck = Spawn.Vehicle(0xE5A2D6C6, utility.OffsetCoords(v3(pos.x, pos.y, pos.z + 5), get.PlayerHeading(id), 10))
        local boat = Spawn.Vehicle(0x82CAC433, pos)

        entity.set_entity_visible(truck, false)
        entity.set_entity_visible(boat, false)

        entity.attach_entity_to_entity(boat, truck, 0, v3(), v3(), true, true, false, 0, true)

        Notify("Crash sent, starting cleanup in 5 seconds.", "Neutral", 'Crash Player')
        coroutine.yield(5000)

        utility.clear({boat, truck})
        coroutine.yield(500)

        if not entity.is_an_entity(truck) then
            Notify('Cleanup successful.', "Success", 'Crash Player')
        else
            Notify('Cleanup failed.', "Error", 'Crash Player')
        end
    end)


    Script.PlayerFeature['World Object Crash'] = menu.add_player_feature('Invalid World Object', 'action', Script.Parent['Player Removal'].id, function(f, id)
        if id == Self() then
            Notify('No point in crashing yourself.', "Error", 'Crash Player')
            return
        end

        local worldhashes = {
            386259036, 450174759, 1567950121, 1734157390, 1759812941, 2040219850,
            1727217687,-993438434, -990984874, -818431457, -681705050, -568850501, 
            3301528862, 3303982422, 3476535839, 3726116795, -1231365640, 4227322399,
            1830533141, 3613262246, 452618762, -930879665
        }

        local fulltable = Randomize(worldhashes)
        local objects = {}
        
        for i = 1, #fulltable do
            local Hash = worldhashes[fulltable[i]]
            objects[#objects + 1] = Spawn.Worldobject(Hash, get.PlayerCoords(id), true, false)
        end
            
        Notify('Crash sent, attemping cleanup in 5 seconds.', "Neutral", 'Crash Player')
        coroutine.yield(5000)

        utility.clear(objects)
        Notify('Cleanup done.', "Success", 'Crash Player')
    end)


    Script.PlayerFeature['Invalid Tasks Crash'] = menu.add_player_feature('Invalid Tasks', 'action', Script.Parent['Player Removal'].id, function(f, id)
        if id == Self() then
            Notify('No point in crashing yourself.', "Error", 'Crash Player')
            return
        end

        if not menu.is_trusted_mode_enabled(1 << 2) then
            Notify('Not available while trusted mode for natives is turned off', 'Error', 'Crash Player')
            return
        end

        local Ped = get.PlayerPed(id)
        local TargetCoords = get.PlayerCoords(id)
        local success
        local AllVehicles = vehicle.get_all_vehicles()

        local rounds = {33, 15, 16, 18}

        for i = 1 , 3 do
            for j = 1, #AllVehicles do
                local coords = entity.get_entity_coords(AllVehicles[j])

                if coords:magnitude(TargetCoords) < 50 then
                    N.TASK.TASK_VEHICLE_TEMP_ACTION(Ped, AllVehicles[j], rounds[i], 999)
                    success = true
                end
            end

            coroutine.yield(1000)
        end

        if not success then
            Notify('Crash failed. Make sure the target is near vehicles.', 'Error', 'Crash Player')
        else
            Notify('Crash done.', 'Success', 'Crash Player')
        end
    end)


    Script.PlayerFeature['Invalid Ped Crash'] = menu.add_player_feature('Invalid Ped', 'action', Script.Parent['Player Removal'].id, function(f, id)
        if id == Self() then
            Notify('No point in crashing yourself.', "Error", 'Crash Player')
            return
        end

        local Coords = get.PlayerCoords(id)
        local Position = get.OwnCoords()

        if f.value ~= 2 and Position:magnitude(Coords) < 1000 then
            Notify('You are too close to the Target.', "Error", 'Crash Player')
            return
        end

        local pos = utility.OffsetCoords(Coords, get.PlayerHeading(id), 10)
        local hashes = {0x3F039CBA, 0x856CFB02, 0x2D7030F3}
        local crashent = Spawn.Ped(hashes[math.random(#hashes)], pos)

        Notify('Crash sent, attemping cleanup in 5 seconds.\nDont go near the Target.', "Neutral", 'Crash Player')
        coroutine.yield(5000)

        utility.clear(crashent)
        coroutine.yield(500)

        if not entity.is_an_entity(crashent) then
            Notify('Cleanup Successful.', "Success", 'Crash Player')
        else
            Notify('Cleanup failed.', "Error", 'Crash Player')
        end
    end)


    Script.PlayerFeature['Invalid Vehicle Crash'] = menu.add_player_feature('Invalid Vehicle', 'action', Script.Parent['Player Removal'].id, function(f, id)
        if id == Self() then
            Notify('No point in crashing yourself.', "Error", 'Crash Player')
            return
        end

        local Coords = get.PlayerCoords(id)
        local Position = get.OwnCoords()

        if f.value ~= 2 and Position:magnitude(Coords) < 1000 then
            Notify('You are too close to the Target.', "Error", 'Crash Player')
            return
        end

        local pos = utility.OffsetCoords(Coords, get.PlayerHeading(id), 10)
        local hashes = {956849991, 1133471123, 2803699023, 386089410, 1549009676}
        local crashent = Spawn.Vehicle(hashes[math.random(#hashes)], pos)

        Notify('Crash sent, attemping cleanup in 5 seconds.\nDont go near the Target.', "Neutral", 'Crash Player')
        coroutine.yield(5000)

        utility.clear(crashent)
        coroutine.yield(500)

        if not entity.is_an_entity(crashent) then
            Notify('Cleanup Successful.', "Success", 'Crash Player')
        else
            Notify('Cleanup failed.', "Error", 'Crash Player')
        end
    end)


    Script.PlayerFeature['Invalid Vehicle Data Crash'] = menu.add_player_feature('Invalid Vehicle Data', 'action', Script.Parent['Player Removal'].id, function(f, id)
        if id == Self() then
            Notify('No point in crashing yourself.', "Error", 'Crash Player')
            return
        end

        local hashes = {1349725314, 3253274834, 1591739866}
        local Position = utility.OffsetCoords(get.PlayerCoords(id), get.PlayerHeading(id), 10)

        local CrashVeh = Spawn.Vehicle(hashes[math.random(#hashes)], Position)
    
        utility.MaxVehicle(CrashVeh, nil, true)
    
        Notify('Crash sent, attemping cleanup in 5 seconds.', "Neutral", 'Crash Player')
        coroutine.yield(5000)

        utility.clear(CrashVeh)
        coroutine.yield(500)

        if not entity.is_an_entity(CrashVeh) then
            Notify('Cleanup Successful.', "Success", 'Crash Player')
        else
            Notify('Cleanup failed.', "Error", 'Crash Player')
        end
    end)


    Script.PlayerFeature['Explosive Ped Crash'] = menu.add_player_feature('Explosive Ped', 'action_value_str', Script.Parent['Player Removal'].id, function(f, id)
        if id == Self() then
            Notify('No point in crashing yourself.', "Error", 'Crash Player')
            return
        end
        
        if not menu.is_trusted_mode_enabled(1 << 2) then
            Notify('Not available while trusted mode for natives is turned off', 'Error', 'Crash Player')
            return
        end

        if f.value == 0 then
            local Ped = get.PlayerPed(id)
            local crashent = Spawn.Ped(0x431D501C, get.PlayerCoords(id) + v3(0, 0, 1))
            entity.set_entity_visible(crashent, false)

            N.WEAPON.GIVE_WEAPON_TO_PED(crashent, -853065399, 10, false, true)
            N.WEAPON.SET_CURRENT_PED_WEAPON(crashent, -853065399, true)
            ai.task_shoot_at_entity(crashent, Ped, 10000, 0x5D60E4E0)
            system.wait(1000)

            fire.add_explosion(entity.get_entity_coords(crashent), 4, false, true, 0, Ped)
            system.wait(1000)

        elseif f.value == 1 then
            local Ped = get.PlayerPed(id)
            local crashent = Spawn.Ped(0x431D501C, get.PlayerCoords(id) + v3(0, 0, 1))
            entity.set_entity_visible(crashent, false)

            N.WEAPON.GIVE_WEAPON_TO_PED(crashent, -853065399, 10, false, true)
            N.WEAPON.SET_CURRENT_PED_WEAPON(crashent, -853065399, true)
            ai.task_shoot_at_entity(crashent, Ped, 10000, 0x5D60E4E0)
            system.wait(1000)

            fire.add_explosion(entity.get_entity_coords(crashent), 4, false, true, 0, Ped)
            system.wait(1000)

        end
        Notify('Crash Complete.', "Success", 'Crash Player')
    end)
    Script.PlayerFeature['Explosive Ped Crash']:set_str_data({'v1', 'v2'})


    Script.PlayerFeature['Physics Crap'] = menu.add_player_feature('Physics Crap', 'action', Script.Parent['Player Removal'].id, function(f, id)
        if id == Self() then
            Notify('No point in crashing yourself.', "Error", 'Crash Player')
            return
        end

        local Pos = get.PlayerCoords(id)
        local OwnPos = get.OwnCoords()

        if f.value ~= 2 and OwnPos:magnitude(Pos) < 1000 then
            Notify('You are too close to the Target.', "Error", 'Crash Player')
            return
        end

        if script.get_host_of_this_script() ~= Self() then
            menu.get_feature_by_hierarchy_key('online.lobby.force_script_host'):toggle()
        end
        
        local objecthash = gameplay.get_hash_key("prop_fragtest_cnst_04") 
        local crashent = Spawn.Object(objecthash, Pos)
        entity.set_entity_visible(crashent, false)

        local veh = Spawn.Vehicle(2038858402, Pos)
        system.yield(9000)
        utility.clear{crashent}
    
        Notify('Crash Complete.', "Success", 'Crash Player')
    end)
    

    Script.PlayerFeature['Duplicate Entity Crash'] = menu.add_player_feature('Duplicate Entity', 'action', Script.Parent['Player Removal'].id, function(f, id)
        if id == Self() then
            Notify('No point in crashing yourself.', "Error", 'Crash Player')
            return
        end

        local CrashObjects = {}
        
        for i = 1, 5 do
            local Position = utility.OffsetCoords(get.PlayerCoords(id), get.PlayerHeading(id), 15)
            for j = 1, 10 do
                CrashObjects[j] = Spawn.Object(1421582485, Position)
            end
    
            fire.add_explosion(v3(Position.x - 1, Position.y - 1, Position.z), 8, true, false, 0.5, 0)
            coroutine.yield(500)
    
            utility.clear(CrashObjects)
            CrashObjects = {}

            coroutine.yield(0)
        end
    
        Notify('Crash Complete.', "Success", 'Crash Player')
    end)


    Script.PlayerFeature['Bad Attach Crash'] = menu.add_player_feature('Bad Attach', 'action', Script.Parent['Player Removal'].id, function(f, id)
        if id == Self() then
            Notify('No point in crashing yourself.', "Error", 'Crash Player')
            return
        end

        local OwnPed = get.OwnPed()
        local OwnPosition = get.OwnCoords()
    
        local Trailer = Spawn.Vehicle(390902130, OwnPosition)
        entity.attach_entity_to_entity(Trailer, OwnPed, 0, v3(0, 0, -10), v3(0,0,0), false, true, false, 0, true)
        coroutine.yield(500)
    
        for i = 1, 50 do
            local Position = get.PlayerCoords(id)
    
            entity.set_entity_coords_no_offset(OwnPed, Position)
            coroutine.yield(20)
        end
    
        coroutine.yield(20)
    
        local dummy = ped.clone_ped(OwnPed)
        entity.attach_entity_to_entity(Trailer, dummy, 0, v3(), v3(), false, true, false, 0, true)
        entity.set_entity_coords_no_offset(dummy, v3(8000, 8000, -8000))
    
        entity.set_entity_coords_no_offset(OwnPed, OwnPosition)
    
        Notify('Crash Complete.', "Success", 'Crash Player')
    end)
    Script.PlayerFeature['Bad Attach Crash'].hint = "High chance to crash yourself after execution or on lobby change."

    
    Script.PlayerFeature['AIO Crash'] = menu.add_player_feature('AIO Crash', 'action', Script.Parent['Player Removal'].id, function(f, id)
        if id == Self() then
            Notify('No point in doing this on yourself', "Error", 'AIO Crash')
            return
        end

        local Coords = get.PlayerCoords(id)
        local Position = get.OwnCoords()
        if Position:magnitude(Coords) < 1000 then
            Notify('You are too close to the Target.', "Error", 'AIO Crash')
            return
        end

        local SpawnCoords = v3(-5000, -5000, 1000)
        local Entities = {}
        local boat

        Notify('AIO Crash started.\nDont go near the Target.', "Neutral", 'AIO Crash')

        local Dummy = Spawn.Ped(mapper.ped.GetRandomPed(), SpawnCoords)
        entity.freeze_entity(Dummy)

        local hashes = {
            1349725314, 3253274834, 956849991, 1133471123, 2803699023, 386089410, 1549009676, 1031068452,0x3F039CBA, 0x856CFB02, 0x2D7030F3,
            386259036, 450174759, 1567950121, 1734157390, 1759812941, 2040219850, -1231365640, 1727217687, 3613262246, 0xE5A2D6C6, -930879665
            -993438434, -990984874, -818431457, -681705050, -568850501, 3301528862, 3303982422, 3476535839, 3726116795, 1591739866, 452618762
        }
        local fulltable = Randomize(hashes)

        for i = 1, #fulltable do
            local hash = fulltable[i]
            if streaming.is_model_a_world_object(hash) then
                Entities[#Entities + 1] = Spawn.Worldobject(hash, SpawnCoords, true, false)

            elseif streaming.is_model_an_object(hash) then
                Entities[#Entities + 1] = Spawn.Object(hash, SpawnCoords)

            elseif streaming.is_model_a_vehicle(hash) then
                Entities[#Entities + 1] = Spawn.Vehicle(hash, SpawnCoords)
                utility.MaxVehicle(Entities[#Entities])

                if hash == 0xE5A2D6C6 then
                    boat = Spawn.Vehicle(0x82CAC433, SpawnCoords)
                    entity.attach_entity_to_entity(boat, Entities[#Entities], 0, v3(), v3(), true, true, false, 0, true)
                end

            elseif streaming.is_model_a_ped(hash) then
                Spawn.Ped(hash, SpawnCoords)

            end
        end

        for i = 1, #Entities do
            entity.attach_entity_to_entity(Entities[i], Dummy, 0, v3(), v3(), true, true, false, 0, true)
        end

        Coords = get.PlayerCoords(id)
        utility.request_ctrl(Dummy)
        entity.set_entity_coords_no_offset(Dummy, Coords)

        if menu.is_trusted_mode_enabled(1 << 2) then
            menu.create_thread(function()
                local Ped = get.PlayerPed(id)
                local AllVehicles = vehicle.get_all_vehicles()
        
                local rounds = {15, 16, 18}
        
                for i = 1 ,#rounds do
                    for j = 1, #AllVehicles do
                        N.TASK.TASK_VEHICLE_TEMP_ACTION(Ped, AllVehicles[j], rounds[i], 999)
                    end
        
                    coroutine.yield(1000)
                end
            end, nil)
        end

        menu.create_thread(function()
            local CrashObjects = {}
        
            for i = 1, 5 do
                local Position = utility.OffsetCoords(get.PlayerCoords(id), get.PlayerHeading(id), 15)
                for j = 1, 10 do
                    CrashObjects[j] = Spawn.Object(1421582485, Position)
                end
        
                fire.add_explosion(v3(Position.x - 1, Position.y - 1, Position.z), 8, true, false, 0.5, 0)
                coroutine.yield(500)
        
                utility.clear(CrashObjects)
                CrashObjects = {}
    
                coroutine.yield(0)
            end
        end, nil)

        menu.create_thread(function()
            local Ped = get.PlayerPed(id)
            local crashent = Spawn.Ped(0x431D501C, get.PlayerCoords(id) + v3(0, 0, 1))
            entity.set_entity_visible(crashent, false)

            N.WEAPON.GIVE_WEAPON_TO_PED(crashent, -853065399, 10, false, true)
            N.WEAPON.SET_CURRENT_PED_WEAPON(crashent, -853065399, true)
            ai.task_shoot_at_entity(crashent, Ped, 10000, 0x5D60E4E0)
            system.wait(1000)

            fire.add_explosion(entity.get_entity_coords(crashent), 4, false, true, 0, Ped)
        end, nil)

        menu.create_thread(function()
            local time = utils.time_ms() + 2500

            while time > utils.time_ms() do
                local pos = player.get_player_coords(id)
    
                for i = 1, 10 do
                    audio.play_sound_from_coord(-1, "ROUND_ENDING_STINGER_CUSTOM", pos, "CELEBRATION_SOUNDSET", true, 1, false)
                end
    
                coroutine.yield(0)
            end
        end, nil)

        menu.create_thread(function()
            scriptevent.crash(id)
        end, nil)

        coroutine.yield(3000)
        Notify('Crash sent, attempting cleanup in 5 seconds', 'Neutral', 'AIO Crash')

        coroutine.yield(5000)
        utility.clear(Entities)
        utility.clear({Dummy, boat})

        coroutine.yield(2000)
        Notify('Cleanup done.', 'Success', 'AIO Crash')
    end)

end, nil)
-- End of Player Features

menu.create_thread(function()
    while not menu.has_thread_finished(MainThread1) and menu.has_thread_finished(MainThread2) do
        coroutine.yield(0)
    end

    if not menu.is_trusted_mode_enabled(1 << 0) or not menu.is_trusted_mode_enabled(1 << 2) or not menu.is_trusted_mode_enabled(1 << 3) then
        Notify('Required Trusted Mode flags:\n- Stats\n- Natives\n- Http\n\nFeatures requiring these flags are disabled while their respective flag is turned off.', 'Neutral', '2Take1Script')
    end

    if utils.file_exists(files['DefaultConfig']) then
        setup.LoadSettings()
    else
        setup.SaveSettings()
    end

    if Script.Feature['Enable Weapon Loadout'].on and Script.Feature['Weapon Loadout Remove'].on then
        weapon.remove_all_ped_weapons(get.OwnPed())
    end

    local quicksave = {
        'Kill Aura Range',
        'Kill Aura Option',
        'Force Field Range',
        'Force Field Strength',
        'Bodyguard Combat Behavior',
        'Bodyguard Max Distance',
        'Bodyguard Formation',
        'Amount of Bodyguards',
        'Vehicle Colors Speed',
        'AI Driving Style',
        'Sound Spam Speed',
        'Explosion Delay',
        'Explosion Camshake',
        'Chat Spam Delay',
        'SMS Delay',
        'Vehicle Blacklist Reaction',
        'Weapon Blacklist Reaction'
    }

    for i = 1, #quicksave do
        local feature = quicksave[i]
        settings[feature] = {Value = Script.Feature[feature].value}
    end
    settings['Change Force Plate Text'] = {Value = Script.Feature['Change Force Plate Text']:get_str_data()[1]}

    for i = 0, 31 do
        if player.is_player_valid(i) and get.Name then
            playerlogging[i] = {ID = i, Name = get.Name(i)}
        end
    end

    menu.create_thread(function()
        while true do
            if menu.is_trusted_mode_enabled(1 << 0) and network.is_session_started() then
                Script.Parent['local_stats'].hidden = false
                Script.Parent['Casino Heist Stats'].hidden = false
                Script.Parent['Cayo Perico Stats'].hidden = false
            else
                Script.Parent['local_stats'].hidden = true
                Script.Parent['Casino Heist Stats'].hidden = true
                Script.Parent['Cayo Perico Stats'].hidden = true
            end

            coroutine.yield(1000)
        end
    end, nil)


    -- console commands
    if not console.register_command('anticrashcam', '[2Take1Script Command] Teleports you to the Anti-Crash Cam. Useful against entity spam', function(mode)
        if Script.Feature['Anti-Crash Cam'].on then
            Script.Feature['Anti-Crash Cam'].on = false
        else
            Script.Feature['Anti-Crash Cam'].on = true
        end
    
    end) and Script.Feature['Override Commands'].on then
        console.remove_command('anticrashcam')

        console.register_command('anticrashcam', '[2Take1Script Command] Teleports you to the Anti-Crash Cam. Useful against entity spam', function(mode)
            if Script.Feature['Anti-Crash Cam'].on then
                Script.Feature['Anti-Crash Cam'].on = false
            else
                Script.Feature['Anti-Crash Cam'].on = true
            end
        
        end)
    end


    if not console.register_command('modelchange', '[2Take1Script Command] Changes you ped to the specified model', function(model)
        if not ArgVerify(model) then
            return
        end

        model = model:sub(13)
        local hash = mapper.ped.GetHashFromModel(model) or 0

        menu.create_thread(function()
            if streaming.is_model_a_ped(hash) then
                change_model(hash, nil, true, nil, true)
            else
                print('Invalid model.')
                return
            end

            print('Model change successful.')
        end, nil)
        
    end, function(s)
        return AutoResult(s, modelList)
    end) and Script.Feature['Override Commands'].on then
        console.remove_command('modelchange')

        console.register_command('modelchange', '[2Take1Script Command] Changes you ped to the specified model', function(model)
            if not ArgVerify(model) then
                return
            end
    
            model = model:sub(13)
            local hash = mapper.ped.GetHashFromModel(model) or 0

            menu.create_thread(function()
                if streaming.is_model_a_ped(hash) then
                    change_model(hash, nil, true, nil, true)
                else
                    print('Invalid model.')
                    return
                end

                print('Model change successful.')
            end, nil)
        
        end, function(s)
            return AutoResult(s, modelList)
        end)
    end


    if not console.register_command('copy', '[2Take1Script Command] Copies the chosen info of a player to your clipboard', function(data)
        local args = {}
        for arg in data:gmatch("[^ ]+") do
            args[#args + 1] = arg
        end

        if #args < 3 then
            print('Invalid args.')
            return
        end

        local method = args[2]
        local name = args[3]
        local id = get.IDFromName(name)
    
        if not player.is_player_valid(id) then
            print('Invalid player.')
            return
        end

        if method == 'name' then
            utils.to_clipboard(tostring(get.Name(id)))
        elseif method == 'scid' then
            utils.to_clipboard(get.SCID(id))
        elseif method == 'ip' then
            utils.to_clipboard(tostring(get.IP(id)))
        elseif method == 'hosttoken' then
            utils.to_clipboard(Math.DecToHex2(get.HostToken(id)))
        else
            print('Invalid method.')
            return
        end

        print('Info successfully copied.')
    
    end, function(s)
        return TripleArgResult(s, {'name', 'scid', 'ip', 'hosttoken'})
    end) and Script.Feature['Override Commands'].on then
        console.remove_command('copy')
    
        local args = {}
        for arg in data:gmatch("[^ ]+") do
            args[#args + 1] = arg
        end

        if #args < 3 then
            print('Invalid args.')
            return
        end

        local method = args[2]
        local name = args[3]
        local id = get.IDFromName(name)
    
        if not player.is_player_valid(id) then
            print('Invalid player.')
            return
        end

        if method == 'name' then
            utils.to_clipboard(tostring(get.Name(id)))
        elseif method == 'scid' then
            utils.to_clipboard(get.SCID(id))
        elseif method == 'ip' then
            utils.to_clipboard(tostring(get.IP(id)))
        elseif method == 'hosttoken' then
            utils.to_clipboard(Math.DecToHex2(get.HostToken(id)))
        else
            print('Invalid method.')
            return
        end

        print('Info successfully copied.')
    end


    if not console.register_command('tp', '[2Take1Script Command] Teleport to a player', function(name)
        name = name:sub(4)
        local id = get.IDFromName(name)
    
        if not player.is_player_valid(id) then
            return
        end
    
        local coords = utility.OffsetCoords(get.PlayerCoords(id), get.PlayerHeading(id), -2)
        utility.set_coords(get.OwnPed(), coords)
    
    end, function(s)
        return PlayerAutocomplete(s, true)
    end) and Script.Feature['Override Commands'].on then
        console.remove_command('tp')
    
        console.register_command('tp', '[2Take1Script Command] Teleport to a player', function(name)
            name = name:sub(4)
            local id = get.IDFromName(name)
        
            if not player.is_player_valid(id) then
                return false
            end
        
            local coords = utility.OffsetCoords(get.PlayerCoords(id), get.PlayerHeading(id), -2)
            utility.set_coords(get.OwnPed(), coords)
        
        end, function(s)
            return PlayerAutocomplete(s, true)
        end)
    end


    if not console.register_command('iplookup', '[2Take1Script Command] Look up a players IP', function(name)
        name = name:sub(10)
        local id = get.IDFromName(name)
    
        if not player.is_player_valid(id) then
            return false
        end
    
        if not menu.is_trusted_mode_enabled(1 << 3) then
            print('Not available while trusted mode for http is turned off')
            return
        end
        
        menu.create_thread(function()
            local IP = get.IP(id)
            local State, Result = web.get("http://ip-api.com/csv/" .. IP)
    
            if State ~= 200 then
                Notify('IP lookup failed. Error code: ' .. State, 'Error', 'IP Lookup')
                return
            end
    
            local parts = {}
            for part in Result:gmatch("[^,]+") do
                parts[#parts + 1] = part
            end
    
            local Success = parts[1]
            if Success == 'fail' then
                Notify('IP lookup failed', 'Error', '')
                return
            end
    
            local Data = 'Country : ' .. parts[2] .. ' [' .. parts[3] .. ']\n' ..
            'Region: ' .. parts[5] .. ' [' .. parts[4] .. ']\n' ..
            'City: ' .. parts[6] .. '\n' ..
            'Zip Code: ' .. parts[7] .. '\n' ..
            'Coords: ' .. parts[8] .. '/' .. parts[9] .. '\n' ..
            'Continent: ' .. parts[10] .. '\n' ..
            'ISP: ' .. parts[11]
            
            print('IP Address : ' .. IP .. '\n' .. Data)
        end, nil)
    
    end, function(s)
        return PlayerAutocomplete(s)
    end) and Script.Feature['Override Commands'].on then
        console.remove_command('iplookup')
    
        console.register_command('iplookup', '[2Take1Script Command] Look up a players IP', function(name)
            name = name:sub(10)
            local id = get.IDFromName(name)
        
            if not player.is_player_valid(id) then
                return
            end
        
            if not menu.is_trusted_mode_enabled(1 << 3) then
                print('Not available while trusted mode for http is turned off')
                return
            end
            
            menu.create_thread(function()
                local IP = get.IP(id)
                local State, Result = web.get("http://ip-api.com/csv/" .. IP)
        
                if State ~= 200 then
                    Notify('IP lookup failed. Error code: ' .. State, 'Error', 'IP Lookup')
                    return
                end
        
                local parts = {}
                for part in Result:gmatch("[^,]+") do
                    parts[#parts + 1] = part
                end
        
                local Success = parts[1]
                if Success == 'fail' then
                    Notify('IP lookup failed', 'Error', '')
                    return
                end
        
                local Data = 'Country : ' .. parts[2] .. ' [' .. parts[3] .. ']\n' ..
                'Region: ' .. parts[5] .. ' [' .. parts[4] .. ']\n' ..
                'City: ' .. parts[6] .. '\n' ..
                'Zip Code: ' .. parts[7] .. '\n' ..
                'Coords: ' .. parts[8] .. '/' .. parts[9] .. '\n' ..
                'Continent: ' .. parts[10] .. '\n' ..
                'ISP: ' .. parts[11]
                
                print('IP Address : ' .. IP .. '\n' .. Data)
            end, nil)
        
        end, function(s)
            return PlayerAutocomplete(s)
        end)
    end


    print('2Take1Script version '.. Version .. ' successfully executed!')
    Notify('2Take1Script version '.. Version .. ' successfully executed!', "Success")
end, nil)