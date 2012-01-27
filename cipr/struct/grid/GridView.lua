local cipr = require 'cipr'
local Grid = cipr.import 'cipr.struct.grid.Grid'
local GridView = {}

function GridView:new(grid, cellSize, x, y)  
    local instance = {}
    setmetatable(instance, { __index = GridView })  
    instance:initialize(grid, cellSize, x, y)
    return instance
end

--[[
:param grid: cipr.struct.grid.Grid - Grid of objects to represent in a view
:param cellSize: int/table - Size of each grid cell (use an int for both x/y or use a table with x, y keys)
:param x: int - Coordinate offset (default 0)
:param y: int - Coordinate offset (default 0)
]]--
function GridView:initialize(grid, cellSize, x, y)
    self._grid = grid
    self._x = x or 0
    self._y = y or 0

    self._cellSize = {}
    if type(cellSize) == 'table' then
        self._xCellSize = cellSize.x
        self._yCellSize = cellSize.y
    else
        self._xCellSize = cellSize
        self._yCellSize = cellSize
    end

    self._xHalfSize = self._xCellSize / 2
    self._yHalfSize = self._yCellSize / 2
    self._cols, self._rows = self._grid:getSize()
    self.width = self._cols * self._cellSize
    self.height = self._rows * self._cellSize

    -- Cache x,y to col,row translation
    self._xyCache = {}

    -- Cache col,row to x,y translation
    self._colRowToXyMap = {}
    
    self:_buildCache()
end

--[[
Pre-generate the coordinates for each cell
]]--
function GridView:_buildCache()
    local x, y

    local xCellSize = self._xCellSize
    local yCellSize = self._yCellSize
    for col = 1, self._cols do
        self._colRowToXyMap[col] = {}

        for row = 1, self._rows do
            x, y = self:getXYAlignedToGrid((col - 1) * xCellSize, (row - 1) * yCellSize)

--            x = x - (x % cellSize)
--            y = y - (y % cellSize)

            self._colRowToXyMap[col][row] = { x = x, y = y }

            if not self._xyCache[x] then
                self._xyCache[x] = {}
            end
            
            self._xyCache[x][y] = { col = col, row = row }
        end
    end
end


function GridView:getGrid()
    return self._grid
end

function GridView:getXYAlignedToGrid(x, y)
    local newX = self._x + x - (x % self._xCellSize) + self._xHalfSize
    local newY = self._y + y - (y % self._yCellSize) + self._yHalfSize
    return newX, newY
end

function GridView:add(obj)
    local col, row = self._grid:add(obj)
    self:_alignCell({col = col, row = row, obj = obj})

    return col, row
end

function GridView:setCell(col, row, obj)
    self._grid:setCell(col, row, obj)
    self:_alignCell({col = col, row = row, obj = obj})
end

-- TODO Make use of xy cache
function GridView:getColRowByXY(x, y)
    x, y = self:getXYAlignedToGrid(x, y)

    local col, row = (x - self._xHalfSize) / self._xCellSize + 1,
                     (y - self._yHalfSize) / self._yCellSize + 1

    return col, row
end

--[[
Get the X, Y coords of a col, row pair.

For performance reasons it's assumed you're always using valid col, rows.
]]--
function GridView:getXYByColRow(col, row)
    local cell = self._colRowToXyMap[col][row]
    return cell.x, cell.y
end

function GridView:getCellAtXy(x, y)
    local col, row = self:getColRowByXY(x, y)

    local obj = self._grid:getCell(col, row)
    if obj then
        return { obj = obj, col = col, row = row }
    else
        return nil
    end
end

--[[
Move the object of a cell to the cell's x,y coords
]]--
function GridView:_alignCell(cell)
    if cell.obj then
        local x, y = self:getXYByColRow(cell.col, cell.row)
        cell.obj.x = x
        cell.obj.y = y
    end
end

--[[
If your grid changes outside the GridView, use updateView to re-sync it
]]--
function GridView:updateView()
    local cells = self._grid:getCells()
    for i=1,#cells do
        self:_alignCell(cells[i])
    end
end

return GridView