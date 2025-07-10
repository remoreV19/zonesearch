addon.name      = 'zonesearch';
addon.author    = 'Viy';
addon.version   = '0.2.0';
addon.desc      = 'Search shorthand';

require('common');
require('lib.levenshtein_algorithm');

local chat  = require('chat');
local zones = require('lib.zones');

local config = {
    tolerance = 5
}

local search = function(query)
    local results = {}
    local sort = function(a, b)
        return a.distance < b.distance
    end

    for short, real in pairs(zones) do
        query = string.lower(query)
        full  = string.lower(real)

        local distance = 0
    
        for queryToken in string.gmatch(query, "[^%s]+") do

            local tokenDistance = string.len(queryToken)
            for zoneToken in string.gmatch(full, "[^%s]+") do
                if string.len(queryToken) < string.len(zoneToken) then
                    zoneToken = string.sub(zoneToken, 0, string.len(queryToken))
                end
                tokenDistance = math.min(tokenDistance, string.levenshtein(queryToken, zoneToken))

            end

            distance = distance + tokenDistance
        end

        table.insert(results, {
            distance = distance,
            short    = short,
            full     = real
        });
    end

    table.sort(results, sort)

    local shortlist = {}
    for i, result in ipairs(results) do
        if result.distance <= config.tolerance then
            print(chat.header(addon.name):append(chat.message('Searching ' .. result.full)));
            AshitaCore:GetChatManager():QueueCommand(1, '/sea ' .. result.short)
            return
        end

        if (i <= 5) then
            table.insert(shortlist, result)
        else
            break;
        end
    end

    print(chat.header(addon.name):append(chat.message('Did you mean:')))

    for i, result in ipairs(shortlist) do
        print(chat.header(addon.name):append(chat.message(i .. ') ' .. result.short .. '(' .. result.distance .. ')')));
    end
end;

--[[
* event: command
* desc : Event called when the addon is processing a command.
--]]
ashita.events.register('command', 'command_cb', function (e)
    -- Parse the command arguments..
    local args = e.command:args();
    if (#args == 0 or not args[1]:any('/zs')) then
        return;
    end

    if (#args >= 2) then
        search(table.concat(args, " ", 2))

        return;
    end
end);
    
