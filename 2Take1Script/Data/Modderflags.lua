local customflags = {}

local names = {
    'Remembered',
    --'Profanity Filter Bypass',
    'Modded Health/Armor',
    'Vehicle Godmode',
    'Modded Off The Radar',
    'Modded Script Event',
    'Max Speed Bypass',
    'Player Godmode',
    'Bad Net Event'
}

for i = 1, #names do
    local flag = 1

    while #player.get_modder_flag_text(flag) > 0 do
        if player.get_modder_flag_text(flag) == names[i] then
            goto skip
        end
        flag = flag * 2
    end

    player.add_modder_flag(names[i])
    
    ::skip::
    customflags[names[i]] = flag
end

return customflags