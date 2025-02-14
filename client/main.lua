lib.locale()

local synced, weatherFreeze = false, false
local weatherHour, lastWeatherHour = 0, 1
local loopInterval = 1000

local weatherForecast = {}
local weatherHash = {
    clear      = 0x36A83D84,
    EXTRASUNNY = 0x97AA0A79,
    CLOUDY     = 0x30FDAF5C,
    OVERCAST   = 0xBB898D2D,
    RAIN       = 0x54A69840,
    CLEARING   = 0x6DB1A50D,
    THUNDER    = 0xB677829F,
    SMOG       = 0x10DCF4B5,
    FOGGY      = 0xAE737644,
    XMAS       = 0xAAC9C895,
    SNOWLIGHT  = 0x23FB812B,
    BLIZZARD   = 0x27EA2814,
}

local function doWeather()
    -- print(locale('weather_forecast', 
    --    string.lower(weatherForecast[weatherHour]['primary']),
    --    string.lower(weatherForecast[weatherHour]['modifier']),
    --    string.lower(weatherForecast[weatherHour]['moonPhaseString']),
    --    weatherForecast[weatherHour]['rain'],
    --    weatherForecast[weatherHour]['wind'],
    --    math.deg(weatherForecast[weatherHour]['windDirection'])
    --))

    if weatherForecast[lastWeatherHour]['primary'] ~= weatherForecast[weatherHour]['primary'] then
        SetWeatherTypeOvertimePersist(weatherForecast[weatherHour]['primary'], 15.0)
        Citizen.Wait(15000)
    end

    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypePersist(weatherForecast[weatherHour]['primary'])
    SetWeatherTypeNow(weatherForecast[weatherHour]['primary'])
    SetWeatherTypeNowPersist(weatherForecast[weatherHour]['primary'])

    SetWeatherTypeTransition(
        weatherHash[weatherForecast[weatherHour]['primary']],
        weatherHash[weatherForecast[weatherHour]['modifier']],
        weatherForecast[weatherHour]['ratio']
    )

    SetRainLevel(weatherForecast[weatherHour]['rain'])
    SetWind(weatherForecast[weatherHour]['wind'])
    SetWindDirection(weatherForecast[weatherHour]['windDirection'])
    EnableMoonCycleOverride(weatherForecast[weatherHour]['moonPhase'])
end

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    while not NetworkIsPlayerActive(PlayerId()) do
        Citizen.Wait(100)
    end
    TriggerServerEvent("tofu-weather:server:requestCurrentWeather")
    while not synced do
        Citizen.Wait(0)
    end
end)

RegisterNetEvent("tofu-weather:client:syncWeather")
AddEventHandler("tofu-weather:client:syncWeather", function(interval, weather, freeze, forceUpdate)
    loopInterval = interval
    weatherForecast = weather
    weatherFreeze = freeze
    synced = true

    -- local function PrintObject(o, indent)
    --     indent = indent or 0
    --     local indentStr = string.rep("  ", indent)
    --     if type(o) == 'table' then
    --         local s = '{\n'
    --         for k, v in pairs(o) do
    --             if type(k) ~= 'number' then k = '"' .. k .. '"' end
    --             s = s .. indentStr .. '  [' .. k .. '] = ' .. PrintObject(v, indent + 1) .. ',\n'
    --         end
    --         return s .. indentStr .. '}'
    --     else
    --         return tostring(o)
    --     end
    -- end

    -- lib.print.debug(weather)
    -- print(PrintObject(weather))

    if forceUpdate then
        doWeather()
    end
end)

Citizen.CreateThread(function()
    while true do
        if #weatherForecast > 0 then
            weatherHour = GetClockHours() + 1

            if weatherHour ~= lastWeatherHour and weatherForecast[weatherHour] ~= nil and not weatherFreeze then
                doWeather()
                lastWeatherHour = weatherHour
            end
        end

        Citizen.Wait(loopInterval)
    end
end)
