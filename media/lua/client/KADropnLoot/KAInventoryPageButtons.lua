require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISInventoryTransferAction"
require "ISUI/ISButton"
require "KACommon"

local string_UI_transfer_compulsively = getText("UI_transfer_compulsively")
local string_UI_transfer_compulsively_tooltip = getText("UI_transfer_compulsively_tooltip")
local string_UI_loot_compulsively = getText("UI_loot_compulsively")
local string_UI_loot_compulsively_tooltip = getText("UI_loot_compulsively_tooltip")
local ISInventoryPagecreateChildren = ISInventoryPage.createChildren
local ISInventoryPageprerender = ISInventoryPage.prerender

local function transfer(self, source, destination)
    local player = getSpecificPlayer(self.player)
    local items = destination:getItems() -- items in destination inventory
    local categories = KAgetCategories(items) -- categories of items in destination inventory
    for _, category in pairs(categories) do
        local targetItems = KAgetItemsByCategory(source, category) -- get same category items from player's inventory
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

function ISInventoryPage:KATransferCompulsively()
    local playerData = getPlayerData(self.player)
    local playerInventory = playerData.playerInventory.inventory -- currently selected player container (e.g., player's duffel bag, plastic bag, key ring, own inventory etc.)
    local lootInventory = playerData.lootInventory.inventory -- currently selected loot container (e.g., shelf, fridge, crate, floor etc.)
    transfer(self, playerInventory, lootInventory)
end

function ISInventoryPage:KALootCompulsively()
    local playerData = getPlayerData(self.player)
    local playerInventory = playerData.playerInventory.inventory -- currently selected player container (e.g., player's duffel bag, plastic bag, key ring, own inventory etc.)
    local lootInventory = playerData.lootInventory.inventory -- currently selected loot container (e.g., shelf, fridge, crate, floor etc.)
    transfer(self, lootInventory, playerInventory)
end

local function createTransferAllCompulsivelyButton(self)
    if (self.KAtransferAllCompulsively == nil and self.onCharacter) then
        local titleBarHeight = self:titleBarHeight()
        local lootButtonHeight = titleBarHeight
        local textWid = getTextManager():MeasureStringX(UIFont.Small, string_UI_transfer_compulsively)
        self.KAtransferAllCompulsively = ISButton:new(0, 0, textWid, lootButtonHeight,
            string_UI_transfer_compulsively, self, ISInventoryPage.KATransferCompulsively);
        self.KAtransferAllCompulsively:initialise();
        self.KAtransferAllCompulsively.tooltip = string_UI_transfer_compulsively_tooltip
        self.KAtransferAllCompulsively.borderColor.a = 0.0;
        self.KAtransferAllCompulsively.backgroundColor.a = 0.0;
        self.KAtransferAllCompulsively.backgroundColorMouseOver.a = 0.7;
        self:addChild(self.KAtransferAllCompulsively);
        self.KAtransferAllCompulsively:setVisible(true);
    end
end

local function createLootAllCompulsivelyButton(self)
    if (self.KAlootAllCompulsively == nil and not self.onCharacter) then
        local titleBarHeight = self:titleBarHeight()
        local lootButtonHeight = titleBarHeight
        local textWid = getTextManager():MeasureStringX(UIFont.Small, string_UI_loot_compulsively)
        self.KAlootAllCompulsively = ISButton:new(0, 0, textWid, lootButtonHeight,
            string_UI_loot_compulsively, self, ISInventoryPage.KALootCompulsively);
        self.KAlootAllCompulsively:initialise();
        self.KAlootAllCompulsively.tooltip = string_UI_loot_compulsively_tooltip
        self.KAlootAllCompulsively.borderColor.a = 0.0;
        self.KAlootAllCompulsively.backgroundColor.a = 0.0;
        self.KAlootAllCompulsively.backgroundColorMouseOver.a = 0.7;
        self:addChild(self.KAlootAllCompulsively);
        self.KAlootAllCompulsively:setVisible(true);
    end
end

local function getTransferCompusivelyButtonOffset(self)
    local result = 0
    if (self.transferAll:getIsVisible()) then -- transfer all button
        result = self.transferAll:getX() - 3 - self.KAtransferAllCompulsively.width
    end
    if (self.swapAutoLoot ~= nil and self.swapAutoLoot:getIsVisible()) then -- AutoLoot button
        result = self.swapAutoLoot:getX() - 3 - self.KAtransferAllCompulsively.width
    end
    return result
end

local function updateTransferCompulsivelyButton(self)
    if (self.onCharacter) then
        if (self.width >= 370) then
            self.transferAll:setVisible(true)
            self.KAtransferAllCompulsively:setVisible(true)
            --local offset = self.transferAll.x - 3 - self.KAtransferAllCompulsively.width
            local offset = getTransferCompusivelyButtonOffset(self)
            self.KAtransferAllCompulsively:setX(offset)
        else
            -- hide when Transfer All button hides
            self.KAtransferAllCompulsively:setVisible(false)
        end
    end
end

local function findSmartStackToAllButton(self)
    if (self.children) then
        for _, selectedItem in pairs(self.children) do
            if (selectedItem.title == getText("UI_StackToAll")) then
                return selectedItem
            end
        end
    end
    return nil
end

local function getLootCompusivelyButtonOffset(self)
    local result = 0
    -- Loot All button
    if (self.lootAll:getIsVisible()) then
        result = self.lootAll:getRight() + 3
    end
    -- AutoLoot button
    if (self.stackItemsButtonIcon ~= nil and self.stackItemsButtonIcon:getIsVisible()) then
        result = self.stackItemsButtonIcon:getRight() + 3
    end
    -- Smart Stack button
    local smartStackButton = findSmartStackToAllButton(self)
    if (smartStackButton ~= nil) then
        result = smartStackButton:getRight() + 3
    end
    return result
end

local function updateLootCompulsivelyButton(self)
    if (not self.onCharacter) then
        local offset = getLootCompusivelyButtonOffset(self)
        self.KAlootAllCompulsively:setX(offset)
    end
end

local function updateOvenAndRemoveAllButton(self)
    if (not self.onCharacter) then
        local offset = self.KAlootAllCompulsively:getRight() + 3
        if (self.toggleStove:getIsVisible()) then
            self.toggleStove:setX(offset)
        end
        if (self.removeAll:getIsVisible()) then
            self.removeAll:setX(offset)
        end
    end
end

function ISInventoryPage:createChildren()
    ISInventoryPagecreateChildren(self)
    pcall(createTransferAllCompulsivelyButton, self)
    pcall(createLootAllCompulsivelyButton, self)
end

function ISInventoryPage:prerender()
    ISInventoryPageprerender(self)
    pcall(updateTransferCompulsivelyButton, self)
    pcall(updateLootCompulsivelyButton, self)
    pcall(updateOvenAndRemoveAllButton, self)
end
