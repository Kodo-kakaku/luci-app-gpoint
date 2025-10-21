#!/usr/bin/env lua
-- Test for startGNSS function with array commands support
-- Copyright 2024

common_path = '/usr/share/gpoint/tests/luaunitlib/?.lua;'
package.path = common_path .. package.path

lu = require('luaunit')

-- Mock modules for testing
local original_require = require
require = function(module)
    if module == "serial" then
        return {
            write = function(port, command)
                print("MOCK: serial.write called with port=" .. tostring(port) .. ", command=" .. tostring(command))
                return {false, "OK"} -- Successful execution
            end
        }
    elseif module == "nixio" then
        return {
            fs = {
                glob = function(pattern)
                    -- Mock glob to return test port
                    return function()
                        return "/dev/ttyUSB0"
                    end
                end
            }
        }
    else
        return original_require(module)
    end
end

-- Load nmea module
local nmea = require("nmea")

-- Test data
local test_port = "/dev/ttyUSB1"

-- Test 1: Single command (string) - backward compatibility
function testSingleCommand()
    print("\n=== Test 1: Single command (string) ===")
    local commands = "AT+GPS=1"
    local error, resp = nmea.startGNSS(test_port, commands)
    
    lu.assertEquals(error, false)
    lu.assertEquals(resp.warning.app[1], false)
    lu.assertEquals(resp.warning.app[2], "GOOD!")
    print("✓ Single command works correctly")
end

-- Test 2: Array with single command
function testSingleCommandArray()
    print("\n=== Test 2: Array with single command ===")
    local commands = {"AT+GPS=1"}
    local error, resp = nmea.startGNSS(test_port, commands)
    
    lu.assertEquals(error, false)
    lu.assertEquals(resp.warning.app[1], false)
    lu.assertEquals(resp.warning.app[2], "GOOD!")
    print("✓ Array with single command works correctly")
end

-- Test 3: Array with multiple commands
function testMultipleCommands()
    print("\n=== Test 3: Array with multiple commands ===")
    local commands = {"AT+GPS=1", "AT+QGPSXTRA=1", "AT+QGPSCFG=\"nmeasrc\",1"}
    local error, resp = nmea.startGNSS(test_port, commands)
    
    lu.assertEquals(error, false)
    lu.assertEquals(resp.warning.app[1], false)
    lu.assertEquals(resp.warning.app[2], "GOOD!")
    print("✓ Multiple commands execute sequentially")
end

-- Test 4: Disabled command "-"
function testDisabledCommand()
    print("\n=== Test 4: Disabled command ===")
    local commands = "-"
    local error, resp = nmea.startGNSS(test_port, commands)
    
    lu.assertEquals(error, false)
    lu.assertEquals(resp.warning.app[1], false)
    lu.assertEquals(resp.warning.app[2], "GOOD!")
    print("✓ Disabled command works correctly")
end

-- Test 5: Array with disabled command
function testDisabledCommandArray()
    print("\n=== Test 5: Array with disabled command ===")
    local commands = {"-"}
    local error, resp = nmea.startGNSS(test_port, commands)
    
    lu.assertEquals(error, false)
    lu.assertEquals(resp.warning.app[1], false)
    lu.assertEquals(resp.warning.app[2], "GOOD!")
    print("✓ Array with disabled command works correctly")
end

-- Test 6: Mixed array with commands and disabled
function testMixedCommands()
    print("\n=== Test 6: Mixed array ===")
    local commands = {"AT+GPS=1", "-", "AT+QGPSXTRA=1"}
    local error, resp = nmea.startGNSS(test_port, commands)
    
    lu.assertEquals(error, false)
    lu.assertEquals(resp.warning.app[1], false)
    lu.assertEquals(resp.warning.app[2], "GOOD!")
    print("✓ Mixed array processed correctly")
end

-- Test 7: Empty array
function testEmptyArray()
    print("\n=== Test 7: Empty array ===")
    local commands = {}
    local error, resp = nmea.startGNSS(test_port, commands)
    
    lu.assertEquals(error, false)
    lu.assertEquals(resp.warning.app[1], false)
    lu.assertEquals(resp.warning.app[2], "GOOD!")
    print("✓ Empty array processed correctly")
end

-- Test 8: Test with gpsd module
function testGpsdModule()
    print("\n=== Test 8: GPSD module ===")
    local gpsd = require("gpsd")
    local commands = {"AT+GPS=1", "AT+QGPSXTRA=1"}
    local error, resp = gpsd.startGNSS(test_port, commands)
    
    lu.assertEquals(error, false)
    lu.assertEquals(resp.warning.app[1], false)
    lu.assertEquals(resp.warning.app[2], "GOOD!")
    print("✓ GPSD module works with command arrays")
end

-- Run tests
print("Running tests for startGNSS function with array commands support...")
print("=" * 60)

os.exit(lu.LuaUnit.run())