local Natives = {
    PLAYER = {},
    PED = {},
    VEHICLE = {},
    OBJECT = {},
    ENTITY = {},
    NETWORK = {},
    GRAPHICS = {},
    WEAPON = {},
    MISC = {},
    HUD = {},
    RECORDING = {},
    STREAMING = {},
    MOBILE = {},
    NETSHOPPING = {},
    MONEY = {},
    TASK = {},
    CAM = {}
}

function Natives.PLAYER.GIVE_ACHIEVEMENT_TO_PLAYER(achievement)
    return native.call(0xBEC7076D64130195, achievement)
end


function Natives.PED.GET_PED_MONEY(Ped)
    return native.call(0x3F69145BBA87BAE7, Ped):__tointeger()
end

function Natives.PED.SET_PED_MONEY(Ped, amount)
    native.call(0xA9C8960E8684C1B5, Ped, amount)
end

function Natives.PED.GET_VEHICLE_PED_IS_ENTERING(Ped)
    return native.call(0xF92691AED837A5FC, Ped):__tointeger()
end


function Natives.VEHICLE.SET_VEHICLE_ENGINE_HEALTH(Vehicle, health)
    native.call(0x45F6D8EEF34ABEF1, Vehicle, health)
end

function Natives.VEHICLE.SET_VEHICLE_ENGINE_ON(Vehicle, toggle, instantly, disableAutoStart)
    native.call(0x2497C4717C8B881E, Vehicle, toggle, instantly, disableAutoStart)
end

function Natives.VEHICLE._IS_VEHICLE_PARACHUTE_ACTIVE(Vehicle)
    native.call(0x3DE51E9C80B116CF, Vehicle)
end

function Natives.VEHICLE._SET_VEHICLE_PARACHUTE_TEXTURE_VARIATION(Vehicle, textureVariation)
    native.call(0xA74AD2439468C883, Vehicle, textureVariation)
end


function Natives.OBJECT.CREATE_AMBIENT_PICKUP(pickupHash, pos, flags, value, modelHash, returnHandle, p8)
    return native.call(0x673966A0C0FD7171, pickupHash, pos, flags, value, modelHash, returnHandle, p8)
end


function Natives.ENTITY.SET_ENTITY_PROOFS(Entity, bulletProof, fireProof, explosionProof, collisionProof, meleeProof, steamProof, p7, drownProof)
    native.call(0xFAEE099C6F890BB8, Entity, bulletProof, fireProof, explosionProof, collisionProof, meleeProof, steamProof, p7, drownProof)
end


function Natives.NETWORK.SET_STORE_ENABLED(toggle)
    native.call(0x9641A9FF718E9C5E, toggle)
end

function Natives.NETWORK.NETWORK_CAN_BAIL()
    return native.call(0x580CE4438479CC61):__tointeger() ~= 0
end

function Natives.NETWORK.NETWORK_BAIL()
    native.call(0x95914459A87EBA28)
end

function Natives.NETWORK._SET_RELATIONSHIP_TO_PLAYER(Player, toggle)
    native.call(0xA7C511FA1C5BDA38, Player, toggle)
end

function Natives.NETWORK.NETWORK_SEND_TEXT_MESSAGE(message, networkHandle)
    native.call(0x3A214F2EC889B100, message, networkHandle)
end


function Natives.GRAPHICS.SET_NIGHTVISION(toggle)
    native.call(0x18F621F7A5B1F85D, toggle)
end

function Natives.GRAPHICS.SET_SEETHROUGH(toggle)
    native.call(0x7E08924259E08CE0, toggle)
end

function Natives.WEAPON.GIVE_WEAPON_TO_PED(Ped, weaponHash, ammoCount, isHidden, bForceInHand)
    native.call(0xBF0FD6E56C964FCB, Ped, weaponHash, ammoCount, isHidden, bForceInHand)
end

function Natives.WEAPON.SET_CURRENT_PED_WEAPON(Ped, weaponHash, bForceInHand)
    native.call(0xADF692B254977C0C, Ped, weaponHash, bForceInHand)
end


function Natives.MISC.SET_FAKE_WANTED_LEVEL(fakeWantedLevel)
    native.call(0x1454F2448DE30163, fakeWantedLevel)
end

function Natives.MISC.SET_RIOT_MODE_ENABLED(toggle)
    native.call(0x2587A48BC88DFADF, toggle)
end

function Natives.MISC.SET_STUNT_JUMPS_CAN_TRIGGER(toggle)
    native.call(0xD79185689F8FD5DF, toggle)
end


function Natives.HUD.CREATE_FAKE_MP_GAMER_TAG(Ped, username, crewIsPrivate, crewIsRockstar, crewName, crewRank)
    return native.call(0xBFEFE3321A3F5015, Ped, username, crewIsPrivate, crewIsRockstar, crewName, crewRank):__tointeger()
end

function Natives.HUD._DISABLE_MULTIPLAYER_CHAT(disable)
    native.call(0x1DB21A44B09E8BA3, disable)
end


function Natives.RECORDING._STOP_RECORDING_AND_DISCARD_CLIP()
    native.call(0x88BB3507ED41A240)
end

function Natives.RECORDING._STOP_RECORDING_THIS_FRAME()
    native.call(0xEB2D525B57F42B40)
end


function Natives.STREAMING.REQUEST_ADDITIONAL_COLLISION_AT_COORD(x, y, z)
    native.call(0xC9156DC11411A9EA, x, y, z)
end


function Natives.MOBILE.DESTROY_MOBILE_PHONE()
    native.call(0x3BC861DF703E5097)
end

function Natives.MOBILE.CREATE_MOBILE_PHONE(type)
    native.call(0xA4E8E696C532FBC7, type)    
end


function Natives.NETSHOPPING._NET_GAMESERVER_IS_SESSION_VALID(charSlot)
    return native.call(0xB24F0944DA203D9E, charSlot):__tointeger() ~= 0
end

function Natives.NETSHOPPING._NET_GAMESERVER_TRANSFER_WALLET_TO_BANK(charSlot, amount)
    return native.call(0xC2F7FE5309181C7D, charSlot, amount):__tointeger() ~= 0
end

function Natives.NETSHOPPING._NET_GAMESERVER_TRANSFER_BANK_TO_WALLET(charSlot, amount)
    return native.call(0xD47A2C1BA117471D, charSlot, amount):__tointeger() ~= 0
end


function Natives.MONEY.NETWORK_GET_STRING_WALLET_BALANCE(characterSlot)
    return native.call(0xF9B10B529DCFB33B, characterSlot):__tostring(true)
end

function Natives.MONEY.NETWORK_GET_STRING_BANK_BALANCE()
    return native.call(0xA6FA3979BED01B81):__tostring(true)
end


function Natives.TASK.TASK_VEHICLE_TEMP_ACTION(driver, Vehicle, action, time)
    native.call(0xC429DCEEB339E129, driver, Vehicle, action, time)
end


function Natives.CAM.INVALIDATE_IDLE_CAM()
    native.call(0xF4F2C0D4EE209E20)
end

function Natives.CAM._INVALIDATE_VEHICLE_IDLE_CAM()
    native.call(0x9E4CFFF989258472)
end

function Natives.CAM._DISABLE_FIRST_PERSON_CAM_THIS_FRAME()
    native.call(0xDE2EF5DA284CC8DF)
end

function Natives.CAM._DISABLE_VEHICLE_FIRST_PERSON_CAM_THIS_FRAME()
    native.call(0xADFF1B2A555F5FBA)
end


return Natives