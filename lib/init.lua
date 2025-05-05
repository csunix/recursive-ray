--[[
    Smart recursive ray for interacting with the physical worldspace.
]]

local RAYCAST_PARAMS = {
    'BruteForceAllSlow',
    'CollisionGroup',
    'FilterDescendantsInstances',
    'FilterType',
    'IgnoreWater',
    'RespectCanCollide'
}

-- Filter function similar to the inplementation of JavaScript's array.filter(...)
local function filter(array, filterFn)
    local nArray = {}
    for index, value in pairs(array) do
        if filterFn(index, value) then
            nArray[index] = value
        end
    end

    return nArray
end

-- Calculates amount of entities based off a filter function.
-- Purely for debugging this serves no other purpose.
local function entities(filterFn, ...)
    local total = 0
    for _, tab in table.pack(...) do
        for _, entity in tab do
            if filterFn(entity) then
                total += 1
            end
        end
    end

    return total
end

-- Check if the indices exists based on a query.
local function indices(indices, checkFn)
    for index, _ in pairs(indices) do
        if not checkFn(index) then
            return false, index
        end
    end

    return true
end

-- Enables a super configuration for a child class.
local function super(child, parent)
    child.__call = function()
        return parent
    end
end

-- Configuration variables
local SPACE_DEBUG = 'Spaces(%d)'
local INVALID_SPACE_NAME = 'The space %s does not exist / has not been created!'
local INVALID_CONFIGURATION_ITEM = 'Could not apply the configuration for %s.'
local EXPECT_ERROR = 'Expected %s got %s.'

-- Class
local RecursiveRay = {}
RecursiveRay.Spaces = {}
RecursiveRay.Settings = {
    Lifetime = nil,
}

RecursiveRay.__entryIsntDemand = function(index, _)
    return typeof(index) ~= 'string'
end

function RecursiveRay:__tostring(spaceName)
    local data = {}
    if spaceName then
        if not self.Spaces[spaceName] then
            warn(string.format(INVALID_SPACE_NAME, spaceName))
        end

        table.insert(data, self.Spaces[spaceName])
    else
        data = self.Spaces
    end

    return string.format(SPACE_DEBUG, entities(self.__entryIsntDemand, table.unpack(data)))
end

-- Create a new space for Rays.
function RecursiveRay.newSpace(filterList: {any})
    local self = {}

    self.Util = {}
    self.Config = {}
    self.Ray = {}

    self.FilterList = filter(filterList, RecursiveRay.__entryIsntDemand)
    self.RaycastParams = RaycastParams.new()
    self.Settings = RecursiveRay.Settings

    do
        self:ForceRayParams({
            FilterType = filterList['FilterType'] or Enum.RaycastFilterType.Exclude,
            FilterDescendantsInstances = filter(filterList, function(_, value)
                return typeof(value) == 'Instance'
            end)
        })

        self.Util.__index = RecursiveRay.Util
        super(self.Util, self)
    end
    setmetatable(self, RecursiveRay)
    setmetatable(self.Util, RecursiveRay.Util)

    return self
end

-- Utility
RecursiveRay.Util = {}

function RecursiveRay.Util.GetSpace(spaceName: string)
    assert(typeof(spaceName) == 'string', string.format(INVALID_SPACE_NAME, tostring(spaceName)))
    return RecursiveRay.Spaces[spaceName] or warn(string.format(INVALID_SPACE_NAME, spaceName))
end

function RecursiveRay.Util:SetLifetime(n: number)
    assert(typeof(n) == 'number', string.format(EXPECT_ERROR, 'number', typeof(n)))
    
    self().Settings.Lifetime = n
    return self
end

-- Configuration
function RecursiveRay:ApplyRayParams(params: {[string]: any})
    local indexCanApply, response = indices(params, RAYCAST_PARAMS)

    if not indexCanApply then
        error(string.format(INVALID_CONFIGURATION_ITEM, response))
    end

    self:ForceRayParams(params)
end

function RecursiveRay:ForceRayParams(params: {[string]: any})
    local raycastParams = self.RaycastParams

    for param, value in pairs(params) do
        raycastParams[param] = value
    end

    self.RaycastParams = raycastParams
end

-- Raycast

-- Create the OOP construction for instantiation.
RecursiveRay.__index = RecursiveRay
return RecursiveRay