local City = {}

local DIRECTIONS = {
    {x = 1, y = 0},
    {x = -1, y = 0},
    {x = 0, y = 1},
    {x = 0, y = -1}
}

function City.new(x, y)
    return {
        x = x,
        y = y,
        level = 1,
        population = 100,
        station = nil
    }
end

function City.canBuildStation(city, x, y)
    for _, direction in ipairs(DIRECTIONS) do
        if city.x + direction.x == x and city.y + direction.y == y then
            return true
        end
    end

    return false
end

function City.distance(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y

    return math.sqrt(dx * dx + dy * dy)
end

return City