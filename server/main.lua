lib.locale()

local clientLoopInterval = 15000
local freezeWeather = false
local weatherForecast = {}
local mainWeatherSets = {'clear', 'clear_cloudy', 'clouds', 'clouds_rain', 'rain'}
local moonPhases = {
    [1] = {
        name = "New Moon",
        value = "0.0"
    },
    [2] = {
        name = "Waxing Crescent",
        value = "0.1"
    },
    [3] = {
        name = "First Quarter",
        value = "0.2"
    },
    [4] = {
        name = "Waxing Gibbous",
        value = "0.3"
    },
    [5] = {
        name = "Full Moon",
        value = "0.5"
    },
    [6] = {
        name = "Waning Gibbous",
        value = "0.7"
    },
    [7] = {
        name = "Last Quarter",
        value = "0.8"
    },
    [8] = {
        name = "Waning Crescent",
        value = "0.9"
    }
}
local lastMoonPhaseIdx = math.random(1, #moonPhases)
local weatherSets = {

    clear = {
        primary = {"CLEAR", "EXTRASUNNY"},
        modifiers = {"CLEAR", "EXTRASUNNY"}
    },

    clear_cloudy = {
        primary = {"CLEAR", "EXTRASUNNY", "CLOUDS"},
        modifiers = {"SMOG", "FOGGY", "OVERCAST"}
    },

    clouds = {
        primary = {"CLOUDS", "OVERCAST", "THUNDER"},
        modifiers = {"SMOG", "FOGGY", "CLEARING"}
    },

    clouds_rain = {
        primary = {"CLOUDS", "OVERCAST", "RAIN", "THUNDER"},
        modifiers = {"SMOG", "FOGGY", "CLEARING"}
    },

    rain = {
        primary = {"RAIN", "CLEARING", "THUNDER"},
        modifiers = {"SMOG", "FOGGY", "CLOUDS"}
    }
}

RegisterServerEvent("tofu-weather:server:requestCurrentWeather")
AddEventHandler("tofu-weather:server:requestCurrentWeather", function()
	TriggerClientEvent("tofu-weather:client:syncWeather", source, clientLoopInterval, weatherForecast, freezeWeather, false)
end)

local function generateWeatherForecastForHour(forcedWeatherSet)
    local randomWeatherSet = mainWeatherSets[math.random(1, #mainWeatherSets)]
    local randomWeatherSetPrimary = weatherSets[randomWeatherSet]['primary'][math.random(1, #weatherSets[randomWeatherSet]['primary'])]
    local randomWeatherSetModifier = weatherSets[randomWeatherSet]['modifiers'][math.random(1, #weatherSets[randomWeatherSet]['modifiers'])]
    local modifierRatio = RandomDecimal(0.3, 0.7, 1)
    local rainRatio = 0
    local randomWindSpeed = math.random(0,100)
    local randomWindDirection = math.rad(RandomDecimal(0, 360, 1))

    if forcedWeatherSet ~= nil then
        randomWeatherSet = forcedWeatherSet
        randomWeatherSetPrimary = weatherSets[forcedWeatherSet]['primary'][math.random(1, #weatherSets[forcedWeatherSet]['primary'])]
        randomWeatherSetModifier = weatherSets[forcedWeatherSet]['modifiers'][math.random(1, #weatherSets[forcedWeatherSet]['modifiers'])]
    end

    if randomWeatherSetPrimary == "RAIN" then
        rainRatio = RandomDecimal(0.5, 1, 1)
    elseif randomWeatherSetPrimary == "THUNDER" then
        rainRatio = RandomDecimal(0.7, 1, 1)
        randomWeatherSetModifier = "RAIN"
    end

    if lastMoonPhaseIdx > #moonPhases then
        lastMoonPhaseIdx = 1
    end

    local moonPhase = moonPhases[lastMoonPhaseIdx]['value']
    local moonPhaseString = moonPhases[lastMoonPhaseIdx]['name']
    lastMoonPhaseIdx = lastMoonPhaseIdx + 1

    return {
        primary = randomWeatherSetPrimary,
        modifier = randomWeatherSetModifier,
        ratio = modifierRatio,
        rain = rainRatio,
        wind = randomWindSpeed,
        windDirection = randomWindDirection,
        moonPhase = moonPhase,
        moonPhaseString = moonPhaseString
    }
end

local function generateWeatherForecast(forcedWeatherSet)
    -- TODO: get time multiplier from game time so we can generate and map in-game hours to
    --       realtime hours. Implemented with the assumption that the server will be restarted
    --       at a frequent interval. eg: 12hrs (realtime)
    weatherForecast = {}
    for i = 0,23,1 do -- 0,23 here indicates 24 hours of in-game time (1 whole day)
        table.insert(weatherForecast, generateWeatherForecastForHour(forcedWeatherSet))
    end
    lib.print.debug(locale("weather_forecast_generated"))
end

 -- generate random decimal
 function RandomDecimal(min, max, precision)
	local precision = precision or 0
	local num = math.random()
	local range = math.abs(max - min)
	local offset = range * num
	local randomnum = min + offset
	return math.floor(randomnum * math.pow(10, precision) + 0.5) / math.pow(10, precision)
end

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    generateWeatherForecast()

    lib.addCommand('freezeweather', {
        help = 'Freeze weather',
        params = {},
        restricted = 'group.admin'
    }, function(source, args, raw)
        freezeWeather = not freezeWeather
        lib.print.debug(locale('weather_frozen', tostring(freezeWeather)))
        TriggerClientEvent("tofu-weather:client:syncWeather", -1, clientLoopInterval, weatherForecast, freezeWeather, false)
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Weather',
            description = locale('weather_frozen', tostring(freezeWeather)),
            type = 'success'
        })
    end)
    
    lib.addCommand('generateweather', {
        help = 'Gnerate weather & forecast',
        params = {},
        restricted = 'group.admin'
    }, function (source, args, raw)
        generateWeatherForecast()
        TriggerClientEvent("tofu-weather:client:syncWeather", -1, clientLoopInterval, weatherForecast, freezeWeather, true)
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Weather',
            description = locale("weather_forecast_generated"),
            type = 'success'
        })
    end)

    lib.addCommand('weatherset', {
        help = 'Force to a specific weather set',
        params = {
            {
                name = 'weatherset',
                help = 'Weather set to use',
                type = 'string'
            }
        },
        restricted = 'group.admin'
    }, function (source, args, raw)
        if not lib.table.contains(mainWeatherSets, args.weatherset) then
            lib.print.error(locale('weather_set_invalid', args.weatherset))
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Weather',
                description = locale('weather_set_invalid', args.weatherset),
                type = 'error'
            })
            return
        end
        lib.print.debug(locale('weather_set_forced', args.weatherset))
        generateWeatherForecast(args.weatherset)
        TriggerClientEvent("tofu-weather:client:syncWeather", -1, clientLoopInterval, weatherForecast, freezeWeather, true)
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Weather',
            description = locale('weather_set_forced', args.weatherset),
            type = 'success'
        })
    end)
end)
