--[[
Common set operations for lua.

local set = Set:new({'foo'})
set:add('bar')
]]--

local pairs = pairs

local Set = {}

function Set:new(tbl)  
    local instance = {}
    setmetatable(instance, { __index = Set })  
    instance:initialize(tbl)
    return instance
end

function Set:initialize(tbl)
    self._index = {}
    self._size = 0

    for i=1,#tbl do
        self:add(tbl[i])
    end
end

function Set:contains(val)
    return self._index[val] ~= nil
end

function Set:add(val)
    if self._index[val] ~= true then
        self._size = self._size + 1
        self._index[val] = true
    end
end

function Set:values()
    local x = {}
    local i = 1
    for v, _ in pairs(self._index) do
        x[i] = v
        i = i + 1
    end
    return x
end

function Set:clone()
    local c = Set:new({})
    for v, _ in pairs(self._index) do
        c:add(v)
    end
    return c
end

function Set:__add(b)
    return self:union(b)
end

function Set:union(b)
    local x = self:clone()
    local values = b:values()

    for i=1,#values do
        x:add(values[i])
    end
    return x
end

function Set:intersection(b)
    local x = Set:new({})
    local values = b:values()

    for i=1,#values do
        local v = values[i]
        if self:contains(v) then
            x:add(v)
        end
    end
    
    return x
end

function Set:__sub(b)
    return self:difference(b)
end

function Set:difference(b)
    local x = Set:new({})
    local values = b:values()

    for i=1,#values do
        local v = values[i]
        if not self:contains(v) then
            x:add(v)
        end
    end

    return x
end

function Set:size()
    return self._size
end


return Set