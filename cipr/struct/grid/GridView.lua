--[[
Translates a Grid into display coordinates
]]--
local cipr = require 'cipr'
local Grid = cipr.import 'cipr.struct.grid.Grid'
local GridView = {}
local floor = math.floor
local ceil = math.ceil
local abs = math.abs
local round = math.round

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

    if type(cellSize) == 'table' then
        self.xCellSize = cellSize.x
        self.yCellSize = cellSize.y
    else
        self.xCellSize = cellSize
        self.yCellSize = cellSize
    end

    self._xHalfSize = self.xCellSize / 2
    self._yHalfSize = self.yCellSize / 2
    self._cols, self._rows = self._grid:getSize()
    self.width = self._cols * self.xCellSize
    self.height = self._rows * self.yCellSize

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

    local xCellSize = self.xCellSize
    local yCellSize = self.yCellSize
    for col = 0.5, self._cols, 0.5 do
        self._colRowToXyMap[col] = {}

        for row = 0.5, self._rows, 0.5 do
            -- x, y = self:getXYAlignedToGrid((col - 1) * xCellSize, (row - 1) * yCellSize)

            x = self._x + (col - 1) * xCellSize + self._xHalfSize
            y = self._y + (row - 1) * yCellSize + self._yHalfSize

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

function GridView:getSize()
    return self._cols, self._rows
end

function GridView:getGrid()
    return self._grid
end

--[[
Returns x,y aligned to closest grid coordinates centered on the col/row
]]--
function GridView:getXYAlignedToGrid(x, y)
    local newX = self._x + x - (x % self.xCellSize) + self._xHalfSize
    local newY = self._y + y - (y % self.yCellSize) + self._yHalfSize
    return newX, newY
end

--[[
Add an object that will have it's position managed by
GridView. Object must implement `move(x, y)`
]]--
function GridView:add(obj)
    local col, row = self._grid:add(obj)
    self:_alignCell({col = col, row = row, obj = obj})

    return col, row
end

function GridView:setCell(col, row, obj)
    self._grid:setCell(col, row, obj)
    self:_alignCell({col = col, row = row, obj = obj})
end

--[[
Get col, row that contains x, y.
]]--
-- TODO Make use of xy cache
function GridView:getColRowByXY(x, y)
    x, y = self:getXYAlignedToGrid(x, y)

    local col, row = x  / self.xCellSize,
                     y / self.yCellSize
    return round(col), round(row)
end

--[[
Get col, row closest to x, y. Gets it by closest distance
to the center of the cell.
]]--
function GridView:getClosestColRowByXY(x, y)
    -- x, y = self:getXYAlignedToGrid(x, y)

    -- x = self._x + x - (x % self.xCellSize) + self._xHalfSize
    -- y = self._y + y - (y % self.yCellSize) + self._yHalfSize

    -- local col, row = (x - self._xHalfSize) / self.xCellSize + 1,
    --                  (y - self._yHalfSize) / self.yCellSize + 1
    local col, row = (self._x + x) / self.xCellSize,
                     (self._y + y) / self.yCellSize
    return col + 1, row + 1
end

--[[
Get the X, Y coords of a col, row pair.

For performance reasons it's assumed you're always using valid col, rows.
]]--
function GridView:getXYByColRow(col, row)
    if self._colRowToXyMap[col] then
        local cell = self._colRowToXyMap[col][row]
        if cell then
            return cell.x, cell.y
        end
    end

    return nil, nil
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
        cell.obj:move(x, y)
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