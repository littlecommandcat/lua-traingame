local Map = {}

Map.TILE_SIZE = 32
Map.WIDTH = 100
Map.HEIGHT = 100

function Map.new()
    local map = {
        tiles = {}
    }

    for y = 1, Map.HEIGHT do
        map.tiles[y] = {}

        for x = 1, Map.WIDTH do
            map.tiles[y][x] = {
                railway = false
            }
        end
    end

    return map
end

function Map:get(x, y)
    if x < 1 or x > Map.WIDTH or y < 1 or y > Map.HEIGHT then
        return nil
    end

    return self.tiles[y][x]
end

function Map:setRailway(x, y)
    local tile = self:get(x, y)

    if tile then
        tile.railway = true
    end
end

return Map