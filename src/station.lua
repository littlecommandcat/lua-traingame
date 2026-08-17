local Station = {}

function Station.new(x, y, city)
    return {
        x = x,
        y = y,
        city = city,
        connected = false,
        level = 1,
        trains = {}
    }
end

return Station