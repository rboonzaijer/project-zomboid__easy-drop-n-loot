--- Easy Drop'n'Loot Main ---

require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISInventoryTransferAction"

-- Trim whitespaces from the beginning + end of a string
local function trim(s)
  return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

-- Split a string by delimiter
local function split(str, delimiter)
    local table = {}
    for k, v in string.gmatch(str, "([^" .. delimiter .. "]+)")
    do
        table[#table+1] = k
    end
    return table
end

--- Get Category or Subcategory name for comparison (depending on onlySubCategory)
local function getCategoryComparisonName(category, onlySubCategory)
    if onlySubCategory == false then
        return trim(split(category, "-")[1])
    end
    return category
end

-- Convert array into table
local function arrayToTable(array)
    if (type(array) == "table") then
        return array
    end
    local result = {}
    for i = 1, array:size() do
        result[i] = array:get(i - 1)
    end
    return result
end

--- Extract InventoryItem from Lua table containers
local function getSingleItem(item)
    if (item["items"] ~= nil) then
        return getSingleItem(item["items"])
    elseif (type(item) == "table") then
        return getSingleItem(item[1])
    else
        return item
    end
end

--- Get InventoryItem category
local function getItemCategory(item)
    local category = item:getDisplayCategory() -- e.g., Literature, SkillBook, Food
    if (category == nil) then
        category = item:getCategory() -- fallback
    end
    return category
end

--- Get InventoryItem display category
local function getItemDisplayCategory(item)
    local category = item:getDisplayCategory() -- e.g., Literature, SkillBook, Food
    if (category == nil or category == "") then
        return item:getCategory() -- fallback
    end
    local result = getText("IGUI_ItemCat_" .. category) -- get item category translation
    if (result == nil or result == "") then
        return item:getCategory() -- fallback
    end
    return result    
end

--- Get categories list of selected items
local function EDNL_getItemsCategories(items)
    local result = {}
    local categories = {}
    local list = arrayToTable(items)
    for _, selectedItem in ipairs(list) do
        local item = getSingleItem(selectedItem)
        -- local category = getItemCategory(item)
        local category = getItemDisplayCategory(item)
        if (category ~= nil and categories[category] == nil) then
            categories[category] = true
            table.insert(result, category)
        end
    end
    return result
end

-- Get items of specific category
local function getItemsByCategory(inventory, category, onlySubCategory)
    local result = {}
    local items = inventory:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        -- if (getItemCategory(item) == category) then
        if (getCategoryComparisonName(getItemDisplayCategory(item), onlySubCategory) == getCategoryComparisonName(category, onlySubCategory)) then
            table.insert(result, item)
        end
    end
    return result
end

-- Drop items of selected categories form selected player inventory
function EDNL_moveItemsByCategories(items, playerIndex, source, destination, onlySubCategory)
    local player = getSpecificPlayer(playerIndex)
    local categories = EDNL_getItemsCategories(items) -- get same category items from player's inventory
    for _, category in ipairs(categories) do
        local targetItems = getItemsByCategory(source, category, onlySubCategory) -- get same category items from player's inventory
        for _, inventoryItem in pairs(targetItems) do
            local item = getSingleItem(inventoryItem)
            -- ignore favorite and equipped items
            if (not item:isFavorite() and not player:isEquipped(item)) then
                -- create "timed action" to transfer items (game api)
                ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, item:getContainer(), destination))
            end
        end
    end
end

-- Transfer items from source container to destination container
local function transfer(playerIndex, source, destination, onlySubCategory)
    local items = destination:getItems() -- items in destination inventory

    EDNL_moveItemsByCategories(items, playerIndex, source, destination, onlySubCategory)
end

--- Get categories display names list of selected items
function EDNL_getItemsDisplayCategories(items, onlySubCategory)
    local result = {}
    local categories = {}
    local list = arrayToTable(items)
    for _, selectedItem in ipairs(list) do
        local item = getSingleItem(selectedItem)
        local category = getCategoryComparisonName(getItemDisplayCategory(item), onlySubCategory)
        if (category ~= nil and categories[category] == nil) then
            categories[category] = true
            table.insert(result, category)
            result[category] = category
        end
    end
    return result
end

-- Check if item is equipped
function EDNL_isEquipped(playerIndex, items)
    local player = getSpecificPlayer(playerIndex)
    return player:isEquipped(getSingleItem(items))
end

-- Get source and destination inventories depending on current context
function EDNL_getSourceAndDestinationInventories(selectedItems, playerIndex)
    local playerData = getPlayerData(playerIndex)
    local playerInventory = playerData.playerInventory.inventory -- currently selected player container (e.g., player's duffel bag, plastic bag, key ring, own inventory etc.)
    local lootInventory = playerData.lootInventory.inventory -- currently selected loot container (e.g., shelf, fridge, crate, floor etc.)
    local firstItem = getSingleItem(selectedItems) -- first selected item    
    local source -- source container
    local grabbing = false -- grabbing items from loot inventory
    local destination -- destination container
    -- if source is player inventory then destination is loot inventory and vise-versa
    if (firstItem:getContainer():getCharacter()) then
        source = playerInventory
        destination = lootInventory
    else
        grabbing = true
        source = lootInventory
        destination = playerInventory
    end
    return source, destination, grabbing
end

-- Drop items form selected player inventory
function EDNL_dropItems(playerIndex, onlySubCategory)
    local playerData = getPlayerData(playerIndex)
    local playerInventory = playerData.playerInventory.inventory -- currently selected player container (e.g., player's duffel bag, plastic bag, key ring, own inventory etc.)
    local lootInventory = playerData.lootInventory.inventory -- currently selected loot container (e.g., shelf, fridge, crate, floor etc.)
    transfer(playerIndex, playerInventory, lootInventory, onlySubCategory)
end

-- Loot items from selected loot container
function EDNL_lootItems(playerIndex, onlySubCategory)
    local playerData = getPlayerData(playerIndex)
    local playerInventory = playerData.playerInventory.inventory -- currently selected player container (e.g., player's duffel bag, plastic bag, key ring, own inventory etc.)
    local lootInventory = playerData.lootInventory.inventory -- currently selected loot container (e.g., shelf, fridge, crate, floor etc.)
    transfer(playerIndex, lootInventory, playerInventory, onlySubCategory)
end
