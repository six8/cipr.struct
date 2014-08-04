--[[
An efficient 2D grid structure
]]--
local math = math

local Grid = {}

Grid.UP = { 0, -1 }
Grid.LEFT = { -1, 0 }
Grid.DOWN = { 0, 1 }
Grid.RIGHT = { 1, 0 }

Grid.DIRECTIONS = {}
Grid.DIRECTIONS[-1] = {}
Grid.DIRECTIONS[-1][-1] = 'SE'
Grid.DIRECTIONS[-1][0] = 'E'
Grid.DIRECTIONS[-1][1] = 'NE'
Grid.DIRECTIONS[0] = {}
Grid.DIRECTIONS[0][-1] = 'S'
Grid.DIRECTIONS[0][0] = nil
Grid.DIRECTIONS[0][1] = 'N'
Grid.DIRECTIONS[1] = {}
Grid.DIRECTIONS[1][-1] = 'SW'
Grid.DIRECTIONS[1][0] = 'W'
Grid.DIRECTIONS[1][1] = 'NW'

function Grid:new(cols, rows)  
    local instance = {}
    setmetatable(instance, { __index = Grid })  
    instance:initialize(cols, rows)
    return instance
end

function Grid:initialize(cols, rows)
    self:resize(cols, rows)
end

--[[
Re-size grid, will clear contents
]]--
function Grid:resize(cols, rows)
    self._rows = rows
    self._cols = cols

    self._cells = {}
    self._valueToCellMap = {}

    -- Pre-populate all cells with nil
    for col=1, self._cols do
        self._cells[col] = {}
    end


    self._stream = {}
    local i = 1
    for col = 1, self._cols do
        for row = 1, self._rows do
            self._stream[i] = {col, row}
            i = i + 1
        end
    end    
end    

function Grid:getSize()
    return self._cols, self._rows
end

function Grid:find(obj)
    if self._valueToCellMap[obj] then
        return self._valueToCellMap[obj][1], self._valueToCellMap[obj][2]
    else
        return nil, nil
    end
end

function Grid:findCell(obj)
    if self._valueToCellMap[obj] then
        return { col = self._valueToCellMap[obj][1], row = self._valueToCellMap[obj][2], obj = obj }
    else
        return nil
    end
end

function Grid:remove(obj)
    local col, row = self:find(obj)
    if col ~= nil and row ~= nil then
        self:setCell(col, row, nil)
    end
end

-- Add item to the nearest empty cell
function Grid:add(item)
    local stream = self._stream
    for i=1,#stream do
        local col, row = stream[i][1], stream[i][2]
        if self:isEmpty(col, row) then
            self:setCell(col, row, item)
            return col, row
        end
    end
end

--[[
This checks to see if a given x,y pair are within
the boundaries of the grid.
--]]
function Grid:isValid(col, row)
    if col == nil or row == nil then
        return false
    elseif (col > 0 and col <= self._cols) and (row > 0 and row <= self._rows) then
        return true
    else
        return false
    end
end

--[[ Gets the data in a given x,y cell. ]]
function Grid:getCell(col, row)
    if self:isValid(col, row) then
        return self._cells[col][row]
    end
end

function Grid:isEmpty(col, row)
    if self:isValid(col, row) and self._cells[col][row] ~= nil then
        return false
    end

    return true
end

--[[
This method will return a set of cell data in a table.
]]--
function Grid:getCells()
    local data = {}
    local col, row, obj

    local i = 1
    for col = 1, self._cols do
        for row = 1, self._rows do
            local obj = self._cells[col][row]
            data[i] = { obj = obj, col = col, row = row }
            i = i + 1
        end
    end

    return data
end

--[[
Call func for each cell in the grid
]]--
function Grid:eachCell(func)
    local col, row, obj

    local i = 1
    for row = 1, self._rows do
        for col = 1, self._cols do        
            local obj = self._cells[col][row]
            func(col, row, obj)
            i = i + 1
        end
    end

    return data
end

--[[
Swap the contents for from cell with to cell
]]--
function Grid:swapCells(fromCol, fromRow, toCol, toRow) 
    local fromObj = self:getCell(fromCol, fromRow)
    local toObj = self:getCell(toCol, toRow)

    self:setCell(toCol, toRow, fromObj)
    self:setCell(fromCol, fromRow, toObj)
end

--[[ Sets a given x,y cell to the data object. ]]--
function Grid:setCell(col, row, obj)
    if self:isValid(col, row) then
        self:clearCell(col, row)

        if obj ~= nil then
            if self._valueToCellMap[obj] then
                -- Remove from old cell
                local ocol, orow = unpack(self._valueToCellMap[obj])
                self:clearCell(ocol, orow)
            end

            self._cells[col][row] = obj
            self._valueToCellMap[obj] = {col, row}
        end
    end
end

--[[ Resets a given x,y cell to the grid default value. ]]
function Grid:clearCell(col, row)
    if self:isValid(col, row) then
        local obj = self._cells[col][row]
        if obj then
            -- Remove existing object from map
            self._valueToCellMap[obj] = nil
            self._cells[col][row] = nil
        end
    end
end

--[[ Resets the entire grid to the default value. ]]
function Grid:clearAll()
    for col=1, self._cols do
        for row=1, self._rows do
            self:clearCell(col, row)
        end
    end
end

--[[
This method is used to populate multiple cells at once. Input is a list of items.

Example:

    - Input

        {1,2,3,4}

    - 2x2 Grid:

        1, 2
        3, 4

If the object to be populated is nil, it is replaced with
the default value.
--]]
function Grid:fill(data)
    for i=1,#data do
        local col, row = self:getColRowByIndex(i)
        self:setCell(col, row, data[i])
    end
end

function Grid:getColRowByIndex(index)    
    local col = ((index - 1) % self._cols) + 1
    local row = math.ceil(index / self._rows)

    return col, row
end

--[[ Gets a cell's neighbor in a given vector. ]]
function Grid:getNeighbor(col, row, vector)
    local vx, vy = unpack(vector)
    col, row = col + vx, row + vy

    local obj = self:getCell(col, row)
    return { col = col, row = row, obj = obj }
end

--[[
Will return a table of 8 elements, with each element
representing one of the 8 neighbors for the given
x,y cell.
--]]
function Grid:getNeighbors(col, row)
    local data = {}
    local gx, gy, vx, vy
    if not self:isValid(col, row) then
        return data
    end

    --[[
    -- The vectors used are x,y pairs between -1 and +1
    -- for the given x,y cell.
    -- IE:
    --     (-1, -1) (0, -1) (1, -1)
    --     (-1,  0) (0,  0) (1,  0)
    --     (-1,  1) (0,  1) (1,  1)
    -- Value of 0,0 is ignored, since that is the cell
    -- we are working with! :D
    --]]

    local i = 1
    for gx = -1, 1 do
        for gy = -1, 1 do
            vx = col + gx
            vy = row + gy
            if (gx == 0 and gy == 0) then
                -- Center, it's our cell
            elseif self:isValid(vx, vy) then
                local dir = Grid.DIRECTIONS[gx][gy]
                data[i] = {col = vx, row = vy, obj = self._cells[vx][vy], vcol = gx, vrow = gy, dir = dir}
                i = i + 1
            end
        end
    end

    return data
end


--[[
Will return a table of 4 elements, with each element
representing one of the 4 direct (perpendicular) neighbors 
for the given x,y cell.
--]]
function Grid:getDirectNeighbors(col, row)
    local data = {}
    if not self:isValid(col, row) then
        return data
    end

    local gx, gy, vx, vy

    --[[
    -- The vectors used are x,y pairs between -1 and +1
    -- for the given x,y cell.
    -- IE:
    --              (0, -1)
    --     (-1,  0) (0,  0) (1,  0)
    --              (0,  1)
    -- Value of 0,0 is ignored, since that is the cell
    -- we are working with! :D
    --]]

    local direct = {
        { 0, -1},
        {-1,  0},
        { 1,  0},
        { 0,  1},
    }

    for i=1,#direct do
        local gx, gy = direct[i][1], direct[i][2]
        vx = col + gx
        vy = row + gy        
        if self:isValid(vx, vy) then
            local dir = Grid.DIRECTIONS[gx][gy]
            data[i] = {col = vx, row = vy, obj = self._cells[vx][vy], vcol = gx, vrow = gy, dir = dir}
            i = i + 1
        end
    end

    return data
end

--[[
This method returns a table of all values in a given column
--]]
function Grid:getColumn(col)
    local cells = {}
    if self:isValid(col, 1) then
        for row=1, self._rows do
            cells[row] = {
                col = col,
                row = row,
                obj = self._cells[col][row]
            }
        end
    end
    return cells
end

--[[
This method returns a table of all objs in a given column
--]]
function Grid:getColumnObjs(col)
    local cells = {}
    if self:isValid(col, 1) then
        for row=1, self._rows do
            cells[row] = self._cells[col][row]
        end
    end
    return cells
end

--[[
This method returns a table of all values in a given row
--]]
function Grid:getRow(row)
    local cells = {}
    if self:isValid(1, row) then
        for col=1, self._cols do
            cells[col] = {
                col = col,
                row = row,
                obj = self._cells[col][row]
            }
        end
    end
    return cells
end

--[[
This method returns a table of all objs in a given row
--]]
function Grid:getRowObjs(row)
    local cells = {}
    if self:isValid(1, row) then
        for col=1, self._cols do
            cells[col] = self._cells[col][row]
        end
    end
    return cells
end

--[[
This method traverses a line of cells, from a given x,y
going in 'vector' direction.This will return a table of
data of the cells along the traversal path or nil if
the original x,y is not valid or if the vector is not one
of the constant values.
In the returned table, each element will be in the format
of {x, y, obj}
--]]
function Grid:traverse(col, row, vector, filterFunc)
    local data = {}

    if self:isValid(col, row) then
        if filterFunc == nil then
            filterFunc = function(obj, col, row)
                -- Include all items
                return true
            end
        end

        local gx, gy, vx, vy
        vx, vy = unpack(vector)

        if vx == nil then
            -- table is still empty.
            return data
        end

        gx = x + vx
        gy = y + vy

        while self:isValid(gx, gy) do
            local obj = self:getCell(gx, gy)
            
            if filterFunc(obj, gx, gy) then
                table.insert(data, {gx, gy, obj})
            end

            gx = gx + vx
            gy = gy + vy
        end
    end

    return data
end

local isNotEmpty = function(obj, col, row)
    -- Include all non empty items
    return obj ~= nil
end

function Grid:getCellsByFilter(filterFunc)
    local data = {}

    if filterFunc == nil then
        filterFunc = isNotEmpty
    end

    local i = 1
    for col = 1, self._cols do
        for row = 1, self._rows do
            local obj = self:getCell(col, row)
            if filterFunc(obj, col, row) then
                data[i] = { obj = obj, col = col, row = row }
                i = i + 1
            end
        end
    end

    return data
end

function Grid:getAllObjs()
    local objs = {}
    local i = 1
    for obj, _ in pairs(self._valueToCellMap) do
        objs[i] = obj
        i = i + 1
    end
    return objs
end


--[[
Get all objects for each row starting at the top.
Does not return empty cells.
]]--
function Grid:getAllObjsByRows()
    local rows = {}
    for row = 1, self._rows do
        local r = {}
        for col = 1, self._cols do   
            local obj = self:getCell(col, row)
            if obj then
                r[#r+1] = obj
            end
        end
        if #r > 0 then
            rows[#rows+1] = r
        end
    end
    return rows
end

return Grid
