local scriptevents = {
    ['Netbail Kick'] = 915462795, --requires script global 1
    ['Passive Mode'] = 949664396,
    ['CEO Kick'] = 1421455565,
    ['CEO Money'] = -337848027, --requires script global 1, pair
    ['Force To Mission'] = 259469385,
    ['Job Join Notification'] = 1186559054,
    ['Start CEO Mission'] = 1450115979,
    --['Force To Island'] = -369672308,
    --['Force To Island 2'] = 330622597,
    --['Casino Cutscene'] = 2139870214,
    --['Transaction Error'] = 54323524, --requires script global 1, pair
    ['Camera Manipulation'] = 800157557,
    ['Off The Radar'] = 57493695, --requires script global 1
    ['Bribe Authorities'] = -305178342, --requires script global 1
    ['Notification'] = -642704387,
    ['Typing Begin'] = -1760661233,
    ['Typing Stop'] = 476054205,
    ['Fake Invite'] = 288412940,
    ['Insurance Notification'] = 1655503526,
    ['Apartment Invite'] = -1321657966,
    ['Warehouse Invite'] = -1253241415,
    ['Vehicle Kick'] = -503325966,
    ['Vehicle EMP'] = 1872545935,
    ['Destroy Personal Vehicle'] = 109434679,
    ['Collectibles'] = 968269233,
    ['Force on Death Bike'] = 1103127469,
    ['SMS'] = -1773335296,
    ['Bounty'] = 1517551547, --requires script global pair
    ['Remove Wanted'] = -1704545346, --requires script global 1
}

function scriptevents.MainGlobal(Target)
    return script.get_global_i(1894573 + (1 + (Target * 608) + 510))
end

function scriptevents.CEOID(Target)
    return script.get_global_i(1894573 + (1 + (Target * 608)) + 10)
end

function scriptevents.IsPlayerAssociate(Target)
    local ceoid = script.get_global_i(1894573 + (1 + (Target * 608)) + 10)
    return (ceoid ~= -1 and ceoid ~= Target)
end

function scriptevents.IsPlayerOTR(Target)
    return script.get_global_i(2657589 + (1 + (Target * 366)) + 210) == 1
end

function scriptevents.isPlayerInInterior(Target)
    return script.get_global_i(2657589 + (1 + (Target * 466)) + 245) ~= 0
end

function scriptevents.GetPersonalVehicle(Target)
    return script.get_global_i(2672505 + (187 + Target + 1))
end

function scriptevents.GlobalPair()
    return script.get_global_i(1923597 + 9), script.get_global_i(1923597 + 10)
end


function scriptevents.Send(Event, Params, Target)
    if not Target or not player.is_player_valid(Target) then
        return
    end

    if not tonumber(Event) then
        if scriptevents[Event] then
            Event = scriptevents[Event]
        else
            return
        end
    end

    script.trigger_script_event(Event, Target, Params)
end

local function random_args(Amount, Min, Max)
    local args = {player.player_id()}
    if not Amount or Amount == 0 then
        return args
    end

    if not Min then
        Min = -2147483647
    end

    if not Max then
        Max = 2147483647
    end

    for i = 1, Amount do
        args[#args + 1] = math.random(Min, Max)
    end

    return args
end

function scriptevents.kick(Target)
    if not Target or not player.is_player_valid(Target) then
        return
    end

    if script.get_host_of_this_script() == Target then
        script.trigger_script_event(scriptevents['Start CEO Mission'], Target, {player.player_id(), 0, 4294967295})
    end

    script.trigger_script_event(scriptevents['Netbail Kick'], Target, {player.player_id(), scriptevents.MainGlobal(Target)})
    script.trigger_script_event(scriptevents['Collectibles'], Target, {player.player_id(), 4, -1, 1, 1, 1})

    local args = random_args(25)
    args[5] = 115

    script.trigger_script_event(scriptevents['Apartment Invite'], Target, args)
end

function scriptevents._notification(Target, Type, Amount)
    if Type == 1  then
        script.trigger_script_event(scriptevents['Notification'], Target, {player.player_id(), 853249803, Amount}) -- cash removed
    elseif Type == 2 then
        script.trigger_script_event(scriptevents['Notification'], Target, {player.player_id(), 82080686, Amount}) -- cash stolen
    else
        script.trigger_script_event(scriptevents['Notification'], Target, {player.player_id(), 276906331, Amount}) -- cash banked
    end
end

function scriptevents.crash(Target)
    if not Target or not player.is_player_valid(Target) then
        return
    end

    script.trigger_script_event(1775863255, Target, random_args(25))
end

return scriptevents