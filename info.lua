_addon.name = 'info'
_addon.author = 'Lorand'
_addon.command = 'info'
_addon.version = '1.5.0'
_addon.lastUpdate = '2016.06.25'

--[[
    Info is a Windower addon for FFXI that is designed to allow users to view
    data that is available to Windower from within the game.
--]]

require('luau')
require('lor/lor_utils')
_libs.lor.req('functional', 'tables', 'strings', 'chat', 'exec')

local res = require('resources')
local packets = require('packets')
local slips = require('slips')
local extdata = require('extdata')
local config = require('config')

local showKB = false
local showAnActionPacket = false
local exec_funcs = nil

windower.register_event('addon command', function (command,...)
    local cmd = command:lower() or 'help'
    
    if exec_funcs[cmd] ~= nil then
        exec_funcs[cmd]()
    elseif cmd == 'reload' then
        windower.send_command('lua reload '.._addon.name)
    elseif cmd == 'unload' then
        windower.send_command('lua unload '.._addon.name)
    elseif cmd == 'showkb' then
        showKB = not showKB
    elseif cmd == 'actionpacket' then
        showAnActionPacket = true
    else
        _libs.lor.exec.process_input(command, {...})
    end
end)


windower.register_event('incoming chunk', function(id,data)
    if showAnActionPacket then
        if id == 0x28 then
            local parsed = packets.parse('incoming', data)
            print_table(parsed, 'Action Packet (0x028)')
            if parsed['Target 1 Action 1 Message'] == 230 then
                showAnActionPacket = false
            end
        end
    end
end)


windower.register_event('keyboard', function (dik, flags, blocked)
    if showKB then
        atc('[Keyboard] dik: '..tostring(dik)..', flags: '..tostring(flags)..', blocked: '..tostring(blocked))
    end
end)


function ws_properties()
    atc(166,'Weaponskill properties')
    local wses = res.weapon_skills
    local skills = res.skills
    for _,ws in pairs(res.weapon_skills) do
        local name = ws.en
        local skill = (ws.skill ~= nil) and skills[ws.skill].en or ''
        local a,b,c = tostring(ws.skillchain_a),tostring(ws.skillchain_b),tostring(ws.skillchain_c)
        atc(name..','..skill..','..a..','..b..','..c)
    end
end


function orTest()
    local a = 'original'
    local b = b or 'replacement'
    local c = false
    local d = c or b
    atc('OR Test result: '..b)
end


function item_info()
    local inv = windower.ffxi.get_items().inventory
    for slot,itbl in pairs(inv) do
        if type(slot) == 'number' then
            local irt, iid = nil, nil
            if not any_eq(type(itbl), 'number', 'boolean') then
                iid = itbl.id
                irt = res.items[iid]
            end
            
            if (irt == nil) then
                atc('[%2s] %s | NO INFO':format(slot, tostring(iid)))
            else
                local augs = get_augment_string(itbl)
                atc('[%2d] %s | %s | %s':format(slot, iid, irt.enl:capitalize(), tostring(augs)))
            end
        end
    end
end


function get_augment_string(item)
    local augments
    if item.extdata then
        augments = extdata.decode(item).augments or {}
    else
        augments = item.augment or item.augments
    end

    local started = false
    if augments and #augments > 0 then
        local aug_str = ''
        for aug_ind,augment in pairs(augments) do
            if augment ~= 'none' then
                if started then
                    aug_str = aug_str .. ','
                end
                
                aug_str = aug_str.."'"..augment.."'"
                started = true
            end
        end
        
        return aug_str
    end
end


function geardump()
    local items = windower.ffxi.get_items()
    local bags = {items.wardrobe,items.wardrobe2,items.locker,items.storage,items.sack,items.satchel,items.inventory,items.safe,items.case}
    
    local gear = {}
    for _,tbl in pairs(bags) do
        for i = 1, 80 do
            local itbl = tbl[i]
            local irt = res.items[itbl.id]
            if (irt ~= nil) then
                local augstr = get_augment_string(itbl)
                local iname = irt.enl:capitalize()
                gear['id'..itbl.id] = {id=itbl.id,name=iname,augs=augstr}
            end
        end
    end
    for slipid,sitems in pairs(slips.get_player_items()) do
        for idx,iid in pairs(sitems) do
            if (idx ~= 'n') then
                local irt = res.items[iid]
                if (irt ~= nil) then
                    local iname = irt.enl:capitalize()
                    gear['id'..iid] = {id=iid,name=iname}
                else
                    atc(123,'Error: Unknown item with id '..tostring(iid))
                end
            end 
        end
    end
    config.load(gear)
    atc('Dumped gear.')
end


exec_funcs = {
    ['geardump'] = geardump,
    ['item_info'] = item_info,
    ['ws_properties'] = ws_properties,
    ['ortest'] = orTest
}

-----------------------------------------------------------------------------------------------------------
--[[
Copyright © 2014-2015, Lorand
All rights reserved.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of info nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Lorand BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]
-----------------------------------------------------------------------------------------------------------