local Railway = {}
Railway.__index = Railway

local DIRECTIONS = {
    {x = 1, y = 0},
    {x = -1, y = 0},
    {x = 0, y = 1},
    {x = 0, y = -1}
}

local function key(x, y)
    return x .. "," .. y
end

function Railway.new()
    return setmetatable({
        tiles = {}
    }, Railway)
end

function Railway:add(x, y)
    self.tiles[key(x, y)] = {
        x = x,
        y = y
    }
end

function Railway:has(x, y)
    return self.tiles[key(x, y)] ~= nil
end

function Railway:get(x, y)
    return self.tiles[key(x, y)]
end

function Railway:getNeighbors(x, y)
    local neighbors = {}

    for _, direction in ipairs(DIRECTIONS) do
        local nx = x + direction.x
        local ny = y + direction.y

        if self:has(nx, ny) then
            table.insert(neighbors, self:get(nx, ny))
        end
    end

    return neighbors
end

function Railway:findPath(startX, startY, endX, endY)
    local startKey = key(startX, startY)
    local targetKey = key(endX, endY)

    if not self.tiles[startKey] then
        return nil
    end

    if not self.tiles[targetKey] then
        return nil
    end

    local queue = {
        {
            x = startX,
            y = startY
        }
    }

    local visited = {
        [startKey] = true
    }

    local previous = {}

    local index = 1

    while index <= #queue do
        local current = queue[index]
        index = index + 1

        if current.x == endX and current.y == endY then
            break
        end

        for _, direction in ipairs(DIRECTIONS) do
            local nx = current.x + direction.x
            local ny = current.y + direction.y
            local nextKey = key(nx, ny)

            if self:has(nx, ny) and not visited[nextKey] then
                visited[nextKey] = true

                previous[nextKey] = current

                table.insert(queue, {
                    x = nx,
                    y = ny
                })
            end
        end
    end

    if not visited[targetKey] then
        return nil
    end

    local path = {}

    local current = {
        x = endX,
        y = endY
    }

    while current do
        table.insert(path, 1, {
            x = current.x,
            y = current.y
        })

        if current.x == startX and current.y == startY then
            break
        end

        current = previous[key(current.x, current.y)]
    end

    return path
end

return Railway