require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISInventoryTransferAction"
require "KACommon"

local string_UI_grab_category = getText('UI_grab_category')
local string_UI_drop_category = getText('UI_drop_category')

-- Get source inventory, destination inventory and type of item transfer (grab or drop)
local function getSourceAndDestinationInventories(selectedItems, playerIndex)
    local playerData = getPlayerData(playerIndex)
    local playerInventory = playerData.playerInventory.inventory -- currently selected player container (e.g., player's duffel bag, plastic bag, key ring, own inventory etc.)
    local lootInventory = playerData.lootInventory.inventory -- currently selected loot container (e.g., shelf, fridge, crate, floor etc.)
    local firstItem = KAgetItem(selectedItems) -- first selected item
    local source = firstItem:getContainer() -- source container
    local grabbing = false -- grabbing items from loot inventory
    local destination -- destination container
    -- if source is player then destination is loot and vise-versa
    if (source == lootInventory) then
        grabbing = true
        destination = playerInventory
    else
        destination = lootInventory
    end
    return source, destination, grabbing
end

local function transferByCategory(categories, player, source, destination)
    for _, category in pairs(categories) do
        local targetItems = KAgetItemsByCategory(source, category)
        for _, inventoryItem in pairs(targetItems) do
            local item = KAgetItem(inventoryItem)
            -- ignore favorite and equipped items
            if (not item:isFavorite() and not player:isEquipped(item)) then
                -- create "timed action" to transfer items (game api)
                ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, source, destination))
            end
        end
    end
end

local function createInventoryItemMenu(playerIndex, context, items)
    if (#items < 1) then
        return -- no items selected
    end    
    local player = getSpecificPlayer(playerIndex)
    if (#items == 1 and player:isEquipped(KAgetItem(items))) then
        return -- equipped container selected
    end
    local source, destination, grabbing = getSourceAndDestinationInventories(items, playerIndex)
    local string = string_UI_drop_category
    if (grabbing) then
        string = string_UI_grab_category
    end
    local categories = KAgetCategories(items)
    -- create right click menu item
    context:addOption(string, categories, transferByCategory, player, source, destination)
end

Events.OnPreFillInventoryObjectContextMenu.Add(createInventoryItemMenu)