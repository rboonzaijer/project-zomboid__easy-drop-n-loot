-- update 25.11.2022

local arrayToTable = function(array)
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
function KAgetItem(item)
    if (item["items"] ~= nil) then
        return KAgetItem(item["items"])
    elseif (type(item) == "table") then
        return KAgetItem(item[1])
    else
        return item
    end
end

--- Get InventoryItem display category
function KAgetItemCategory(item)
    local category = item:getDisplayCategory() -- e.g., Literature, Skill Book, Food
    if (category == nil) then
        category = item:getCategory() -- fallback
    end
    return category
end

--- Get categories list of selected items
function KAgetCategories(items)
    local result = {}
    local categories = {}
    local list = arrayToTable(items)
    for _, selectedItem in ipairs(list) do
        local item = KAgetItem(selectedItem)
        local category = KAgetItemCategory(item)
        if (category ~= nil and categories[category] == nil) then
            categories[category] = true
            table.insert(result, category)
        end
    end
    return result
end

-- Get items of specific category
function KAgetItemsByCategory(inventory, category)
    local result = {}
    local items = inventory:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if (KAgetItemCategory(item) == category) then
            table.insert(result, item)
        end
    end
    return result
end