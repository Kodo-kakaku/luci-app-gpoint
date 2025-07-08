-------------------------------------------------------------------
-- Module is designed to work with the Yandex Locator API
-- (WiFi is required!)
-------------------------------------------------------------------
-- Copyright 2021-2025 Vladislav Kadulin <spanky@yandex.ru>
-- Licensed to the GNU General Public License v3.0

local json    = require("luci.jsonc")
local sys     = require("luci.sys")
local iwinfo  = require("iwinfo")

locator = {}

local function configJSON(jsonData, iface)
	local inter = iwinfo.type(iface)
	local scanlist = iwinfo[inter].scanlist(iface)
	for _, v in pairs(scanlist) do
		v.bssid = string.gsub(v.bssid, ':', '')
		table.insert(jsonData.wifi, {
			["bssid"] = v.bssid,
			["signal_strength"] = v.signal
		})
	end
end

local function request(curl, jsonData)
	local cmd = string.format(
			'curl -H "Content-Type: application/json" -X POST "%s" -d \'%s\'',
			curl,
			json.stringify(jsonData)
	)
	local res = sys.exec(cmd)
	if res == "" then
		res = "{\"error\": {\"message\":\"No internet connection\"}}"
	end
	return json.parse(res)
end

function locator.degreesToNmea(coord)
	local degrees = math.floor(coord)
	coord = math.abs(coord) - degrees
	local sign = coord < 0 and "-" or ""
	return sign .. string.format("%02i%02.5f", degrees, coord * 60.00)
end

function locator.getLocation(iface_name, api_key)
	local endpoint = string.format("https://locator.api.maps.yandex.ru/v1/locate?apikey=%s", api_key)

	local jsonData = {
		wifi = {}
	}

	configJSON(jsonData, iface_name)
	local response = request(endpoint, jsonData)
	local err = {false, "OK"}
	local latitude  = ""
	local longitude = ""

	if not response or next(response) == nil then
		return {true, "Yandex locator empty request"}, latitude, longitude
	end

	if response.error then
		err = {true, response.error.message}
		return err, latitude, longitude
	end

	if response.location and response.location.point then
		if response.location.accuracy and tonumber(response.location.accuracy) >= 100000 then
			err = {true, "Bad precision"}
		else
			local lat = tonumber(response.location.point.lat)
			local lon = tonumber(response.location.point.lon)

			if lat and lon then
				latitude  = string.format("%0.8f", lat)
				longitude = string.format("%0.8f", lon)
			else
				err = {true, "Bad coordinates"}
			end
		end
	else
		err = {true, "Bad data"}
	end

	return err, latitude, longitude
end

return locator
