-- --- Easy Drop'n'Loot Options ---

require "EDNLMain"

local config = {
    lootKey = nil,
    dropKey = nil
}

local function createEDNLConfigOptions()
    -- create mod menu options
    local options = PZAPI.ModOptions:create("EDNLOptions", "Easy Drop'n'Loot")
    config.dropKey = options:addKeyBind("EDNLOptionsDropKey", getText("UI_drop_items_button"), nil, getText("UI_drop_items_button_tooltip"))
    config.lootKey = options:addKeyBind("EDNLOptionsLootKey", getText("UI_loot_items_button"), nil, getText("UI_loot_items_button_tooltip"))
end

createEDNLConfigOptions()

local function onEDNLKeyPressed(key)    
    -- loot key
    if config.lootKey and key == config.lootKey:getValue() then     
        local player = getPlayer()
        if (player) then
            local playerIndex = player:getPlayerNum()            
            EDNL_lootItems(playerIndex)
        end
    end
    -- drop key
    if config.dropKey and key == config.dropKey:getValue() then        
        local player = getPlayer()
        if (player) then
            local playerIndex = player:getPlayerNum()            
            EDNL_dropItems(playerIndex)
        end
    end
end

Events.OnKeyPressed.Add(onEDNLKeyPressed)
