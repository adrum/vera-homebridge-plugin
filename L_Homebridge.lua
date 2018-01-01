local http = require 'socket.http'
local ltn12 = require 'ltn12'
--
-- Table entries { "ServiceID", "VariableName", DeviceNo, SceneNo }
-- http://wiki.mios.com/index.php/Luup_UPnP_Variables_and_Actions
--

watchTable = {
    -- category_num: {device_type, variable, key}
    -- House Modes: http://wiki.micasaverde.com/index.php/House_Modes
    ["0"]={
        {"urn:micasaverde-com:serviceId:HouseModes1","ModeSetting",'mode'},
        {"urn:micasaverde-com:serviceId:HouseModes1","HMode",'mode'},
        -- {"urn:micasaverde-com:serviceId:HaDevice1 ","ModeSetting",'mode'},
    },
    -- Dimmer/Fan
    ["2"]={
        {"urn:upnp-org:serviceId:SwitchPower1","Status",'status'},
        {"urn:upnp-org:serviceId:Dimming1","LoadLevelStatus",'level'},
    },
    -- Lock
    ["7"]={
        {"urn:micasaverde-com:serviceId:DoorLock1","Locked",'locked'},
        -- {"urn:micasaverde-com:serviceId:HaDevice1","BatteryLevel",'batterylevel'},
    },
    -- Light/Switch(4)
    ["3"]={
        {"urn:upnp-org:serviceId:SwitchPower1","Status",'status'},
    },
    -- Motion
    ["4>3"]={
        {"urn:micasaverde-com:serviceId:SecuritySensor1","Tripped",'tripped'},
        {"urn:micasaverde-com:serviceId:SecuritySensor1","Armed",'armed'},
        {"urn:micasaverde-com:serviceId:SecuritySensor1","CommFailure",'commFailure'},
        {"urn:micasaverde-com:serviceId:HaDevice1","BatteryLevel",'batterylevel'},
    },
    -- Contact
    ["4>1"]={
        {"urn:micasaverde-com:serviceId:SecuritySensor1","Tripped",'tripped'},
        {"urn:micasaverde-com:serviceId:SecuritySensor1","CommFailure",'commFailure'},
        {"urn:micasaverde-com:serviceId:HaDevice1","BatteryLevel",'batterylevel'},
    },
    -- Humidity
    ["16"]={
        {"urn:micasaverde-com:serviceId:HumiditySensor1","CurrentLevel",'humidity'},
        {"urn:micasaverde-com:serviceId:HaDevice1","BatteryLevel",'batterylevel'},
    },
    -- Temperature
    ["17"]={
        -- urn:schemas-micasaverde-com:device:TemperatureSensor:1
        {"urn:micasaverde-com:serviceId:TemperatureSensor1","CurrentTemperature",'temperature'},
        {"urn:micasaverde-com:serviceId:HaDevice1","BatteryLevel",'batterylevel'},
    },
    -- Light Sensor
    ["18"]={
        {"urn:micasaverde-com:serviceId:LightSensor1","CurrentLevel",'light'},
        {"urn:micasaverde-com:serviceId:HaDevice1","BatteryLevel",'batterylevel'},
    },
    -- Smoke
    ["4>4"]={
        {"urn:schemas-micasaverde-com:device:SmokeSensor:1","ArmedTripped",'armedtripped'},
        {"urn:schemas-urn:micasaverde-com:serviceId:HaDevice1","BatteryLevel",'batterylevel'},
    },
    -- CO
    ["4>5"]={
        {"urn:schemas-micasaverde-com:device:SmokeSensor:1","ArmedTripped",'armedtripped'},
        {"urn:schemas-urn:micasaverde-com:serviceId:HaDevice1","BatteryLevel",'batterylevel'},
    },
    -- Contact
    ["4>6"]={
        {"urn:micasaverde-com:serviceId:SecuritySensor1","Armed",'armed'},
        {"urn:micasaverde-com:serviceId:SecuritySensor1","ArmedTripped",'armedtripped'},
        {"urn:micasaverde-com:serviceId:SecuritySensor1","CommFailure",'commFailure'},
        {"urn:micasaverde-com:serviceId:HaDevice1","BatteryLevel",'batterylevel'},
    },
    -- Window Cover
    ["8"]={
        {"urn:upnp-org:serviceId:Dimming1","LoadLevelStatus",'level'},
    },
    -- Thermostat
    ["5"]={
        {"urn:micasaverde-com:serviceId:TemperatureSensor1","CurrentTemperature",'temperature'},
        {"urn:upnp-org:serviceId:HVAC_UserOperatingMode1", "ModeStatus",'mode'},
        {"urn:upnp-org:serviceId:TemperatureSetpoint1_Cool", "CurrentSetpoint",'heat'},
        {"urn:upnp-org:serviceId:TemperatureSetpoint1_Heat", "CurrentSetpoint",'cool'},
        {"urn:upnp-org:serviceId:TemperatureSetpoint1_Heat", "CurrentSetpoint",'setpoint'}, -- todo: conditaionl send setpoint along if in mode
        {"urn:upnp-org:serviceId:TemperatureSetpoint1_Cool", "CurrentSetpoint",'setpoint'}, -- todo: conditaionl send setpoint along if in mode
    }
}
function SendUpdate(lul_device, id, key, value)

    -- Fetch Configs
    local HomebridgeIp = readConfig(lul_device,deviceSID,"HomebridgeIp","192.168.1.0")
    local HomebridgePort = readConfig(lul_device,deviceSID,"HomebridgePort","8000")
    local Username = readConfig(lul_device,deviceSID,"Username","user")
    local Password = readConfig(lul_device,deviceSID,"Password","secret")

    -- Prep JSON
    local postdata = '{"id": "'..id..'", "property": "'..key..'", "value": "'..value..'"}'
    local len = string.len(postdata)

    -- Prepare Request
    local url = "http://"..HomebridgeIp..":"..HomebridgePort.."/update"
    local authorization = "Basic "..Username..":"..Password
    header = { }
    local res, status, headers = socket.http.request
    {
      url = url;
      method = "POST";
      source = ltn12.source.string(postdata),
      sink = ltn12.sink.table(bodyparts),
      headers =
      {
        ["Content-Type"] = "application/json";
        ["content-length"] = len;
        ["authorization"] = authorization;
      };
    }
end
function findKeyForServiceAndProperty (service, property)
    for cat, properties in pairs(watchTable) do
        for i, table in ipairs(properties) do
            local device_type = table[1]
            local prop = table[2]

            if ((service == device_type) and (prop == property) ) then
                local key = table[3]
                return key
            end
        end
    end
    return false
end

--
-- When a watched variable changes, send the update
--
function catchWatch(lul_device, lul_service, lul_variable, lul_value_old, lul_value_new)
    local key = findKeyForServiceAndProperty(lul_service, lul_variable)
    SendUpdate(MainDevice, lul_device, key, lul_value_new)
end
