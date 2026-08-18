local Map = require("logic.map")
local City = require("logic.city")
local Station = require("logic.station")
local Railway = require("logic.railway")
local Train = require("logic.train")

local mainCity
local railway

local cities = {}
local stations = {}
local trains = {}
local money = 1000
local trainPrice = 200

local mainCityIncomeTimer = 0

local stationPanel = {
    width = 320,
    height = 300
}

local camera = {
    x = 0,
    y = 0,
    zoom = 1
}

local INCOME_PER_TILE = 0.05
local selectedStation = nil
local dragging = false
local lastMouseX
local lastMouseY

function getStationAtScreen(x, y)
    local tileSize = Map.TILE_SIZE * camera.zoom

    for _, station in ipairs(stations) do
        local sx, sy = worldToScreen(station.x, station.y)

        local centerX = sx + tileSize / 2
        local centerY = sy + tileSize / 2

        local radius = tileSize * 0.35

        local dx = x - centerX
        local dy = y - centerY

        if dx * dx + dy * dy <= radius * radius then
            return station
        end
    end

    return nil
end

function worldToScreen(x, y)
    local size = Map.TILE_SIZE * camera.zoom

    return
        love.graphics.getWidth() / 2 + x * size + camera.x,
        love.graphics.getHeight() / 2 + y * size + camera.y
end

local function screenToWorld(x, y)
    local size = Map.TILE_SIZE * camera.zoom

    local worldX =
        (x - camera.x - love.graphics.getWidth() / 2) / size

    local worldY =
        (y - camera.y - love.graphics.getHeight() / 2) / size

    return math.floor(worldX), math.floor(worldY)
end

local function distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1

    return math.sqrt(dx * dx + dy * dy)
end

local function generateCities()
    local attempts = 0

    while #cities < 12 and attempts < 10000 do
        attempts = attempts + 1

        local x = math.random(-45, 45)
        local y = math.random(-45, 45)

        if distance(x, y, 0, 0) >= 10 then
            local valid = true

            for _, city in ipairs(cities) do
                if distance(x, y, city.x, city.y) < 10 then
                    valid = false
                    break
                end
            end

            if valid then
                table.insert(cities, City.new(x, y))
            end
        end
    end
end

local function createCentralStation()
    local station = Station.new(0, 0, nil)

    station.id = #stations + 1
    station.name = "中央車站"
    station.isMain = true

    table.insert(stations, station)

    railway:add(0, 0)

    mainCity = City.new(2, 0)
    mainCity.isMain = true
end

local function findStationAt(x, y)
    for _, station in ipairs(stations) do
        if station.x == x and station.y == y then
            return station
        end
    end

    return nil
end

local function createStation(x, y)
    if mainCity and mainCity.x == x and mainCity.y == y then
        return
    end
    
    if findStationAt(x, y) then
        return
    end

    for _, city in ipairs(cities) do
        if City.canBuildStation(city, x, y) then
            local station = Station.new(x, y, city)

            station.id = #stations + 1
            station.name = "車站 #" .. station.id

            city.station = station

            table.insert(stations, station)

            updateConnections()

            return station
        end
    end
end

local function findCityAt(x, y)
    if mainCity and mainCity.x == x and mainCity.y == y then
        return mainCity
    end

    for _, city in ipairs(cities) do
        if city.x == x and city.y == y then
            return city
        end
    end

    return nil
end

local function canBuildRailway(x, y)
    if railway:has(x, y) then
        return false
    end

    if findCityAt(x, y) then
        return false
    end

    if findStationAt(x, y) then
        return false
    end

    for _, city in ipairs(cities) do
        local dx = math.abs(x - city.x)
        local dy = math.abs(y - city.y)

        if dx + dy == 1 then
            return false
        end
    end

    return
        railway:has(x + 1, y) or
        railway:has(x - 1, y) or
        railway:has(x, y + 1) or
        railway:has(x, y - 1)
end
-- local function buildTrainForStation(station)
--     if not station.city then
--         return
--     end

--     local route = railway:findPath(
--         0,
--         0,
--         station.x,
--         station.y
--     )

--     if not route or #route < 2 then
--         return
--     end

--     local train = Train.new(route)

--     table.insert(trains, train)
-- end

function getStationRoute(station)
    local railwayX, railwayY = getStationRailwayTile(station)

    if not railwayX then
        return nil
    end

    local route = railway:findPath(
        0,
        0,
        railwayX,
        railwayY
    )

    if not route then
        return nil
    end

    table.insert(route, {
        x = station.x,
        y = station.y
    })

    return route
end

local function getRouteLength(route)
    if not route then
        return 0
    end

    return math.max(0, #route - 1)
end

-- local function updateConnections()
--     for _, station in ipairs(stations) do
--         if station.city and not station.connected then
--             local path = railway:findPath(
--                 0,
--                 0,
--                 station.x,
--                 station.y
--             )

--             if path then
--                 station.connected = true

--                 buildTrainForStation(station)
--             end
--         end
--     end
-- end

function updateConnections()
    for _, station in ipairs(stations) do
        if not station.connected then
            local connected =
                railway:has(station.x + 1, station.y) or
                railway:has(station.x - 1, station.y) or
                railway:has(station.x, station.y + 1) or
                railway:has(station.x, station.y - 1)

            if connected then
                station.connected = true
            end
        end
    end
end

function love.load()
    math.randomseed(os.time())

    love.window.setTitle("Railway City")
    love.window.setMode(1280, 720)

    map = Map.new()
    railway = Railway.new()

    createCentralStation()
    generateCities()
end

function love.update(dt)
    mainCityIncomeTimer = mainCityIncomeTimer + dt

    while mainCityIncomeTimer >= 1 do
        mainCityIncomeTimer = mainCityIncomeTimer - 1
        money = money + 0.1
    end

    for _, train in ipairs(trains) do
        if train:update(dt) then
            if train.station and train.income then
                money = money + train.income
            end
        end
    end
end

function love.draw()
    local tileSize = Map.TILE_SIZE * camera.zoom

    local startX = math.floor(
        (-camera.x - love.graphics.getWidth() / 2) / tileSize
    ) - 2

    local startY = math.floor(
        (-camera.y - love.graphics.getHeight() / 2) / tileSize
    ) - 2

    local endX = startX + math.ceil(
        love.graphics.getWidth() / tileSize
    ) + 4

    local endY = startY + math.ceil(
        love.graphics.getHeight() / tileSize
    ) + 4
    love.graphics.setColor(0.35, 0.35, 0.35, 1)
    for y = startY, endY do
        for x = startX, endX do
            local screenX, screenY = worldToScreen(x, y)

            love.graphics.rectangle(
                "line",
                screenX,
                screenY,
                tileSize,
                tileSize
            )
        end
    end

    love.graphics.setLineWidth(
        math.max(2, 5 * camera.zoom)
    )

    love.graphics.setColor(0.15, 0.15, 0.15, 1)

    love.graphics.setLineWidth(
        math.max(2, 5 * camera.zoom)
    )

    love.graphics.setColor(255, 255, 255, 1)

    for _, tile in pairs(railway.tiles) do
        local x, y = worldToScreen(tile.x, tile.y)

        local centerX = x + tileSize / 2
        local centerY = y + tileSize / 2

        local left = railway:has(tile.x - 1, tile.y)
        local right = railway:has(tile.x + 1, tile.y)
        local up = railway:has(tile.x, tile.y - 1)
        local down = railway:has(tile.x, tile.y + 1)

        local leftStation = findStationAt(tile.x - 1, tile.y)
        local rightStation = findStationAt(tile.x + 1, tile.y)
        local upStation = findStationAt(tile.x, tile.y - 1)
        local downStation = findStationAt(tile.x, tile.y + 1)

        if left then
            love.graphics.line(
                centerX,
                centerY,
                x,
                centerY
            )
        elseif leftStation then
            love.graphics.line(
                centerX,
                centerY,
                x - tileSize / 2,
                centerY
            )
        end

        if right then
            love.graphics.line(
                centerX,
                centerY,
                x + tileSize,
                centerY
            )
        elseif rightStation then
            love.graphics.line(
                centerX,
                centerY,
                x + tileSize + tileSize / 2,
                centerY
            )
        end

        if up then
            love.graphics.line(
                centerX,
                centerY,
                centerX,
                y
            )
        elseif upStation then
            love.graphics.line(
                centerX,
                centerY,
                centerX,
                y - tileSize / 2
            )
        end

        if down then
            love.graphics.line(
                centerX,
                centerY,
                centerX,
                y + tileSize
            )
        elseif downStation then
            love.graphics.line(
                centerX,
                centerY,
                centerX,
                y + tileSize + tileSize / 2
            )
        end

        if not left
            and not right
            and not up
            and not down
            and not leftStation
            and not rightStation
            and not upStation
            and not downStation then

            love.graphics.circle(
                "fill",
                centerX,
                centerY,
                math.max(2, tileSize * 0.1)
            )
        end
    end

    for _, city in ipairs(cities) do
        local x, y = worldToScreen(city.x, city.y)

        love.graphics.rectangle(
            "fill",
            x + tileSize * 0.2,
            y + tileSize * 0.2,
            tileSize * 0.6,
            tileSize * 0.6
        )

        love.graphics.print(
            "City Lv." .. city.level,
            x,
            y - 20
        )
    end
    if mainCity then
        local x, y = worldToScreen(mainCity.x, mainCity.y)

        love.graphics.setColor(0.2, 0.8, 0.3, 1)

        love.graphics.rectangle(
            "fill",
            x + tileSize * 0.15,
            y + tileSize * 0.15,
            tileSize * 0.7,
            tileSize * 0.7
        )

        love.graphics.setColor(1, 1, 1, 1)

        love.graphics.print(
            "Main City",
            x,
            y - 20
        )
    end
    for _, station in ipairs(stations) do
        local x, y = worldToScreen(station.x, station.y)

        love.graphics.circle(
            "fill",
            x + tileSize / 2,
            y + tileSize / 2,
            tileSize * 0.3
        )
    end

    for _, train in ipairs(trains) do
        local x, y = train:getPosition()

        if x and y then
            local screenX, screenY = worldToScreen(x, y)

            love.graphics.circle(
                "fill",
                screenX + tileSize / 2,
                screenY + tileSize / 2,
                tileSize * 0.2
            )
        end
    end

    local infoX = 10
    local infoY = 10
    local infoWidth = 500
    local infoHeight = 60

    love.graphics.setColor(0, 0, 0, 0.7)

    love.graphics.rectangle(
    "fill",
    infoX,
    infoY,
    infoWidth,
    infoHeight,
    6,
    6
)

    love.graphics.setColor(1, 1, 1)

    love.graphics.rectangle(
        "line",
        infoX,
        infoY,
        infoWidth,
        infoHeight,
        6,
        6
    )

    love.graphics.print(
        "Money: $" .. money ..
        "  Cities: " .. #cities ..
        "  Stations: " .. #stations ..
        "  Trains: " .. #trains,
        infoX + 10,
        infoY + 8
    )

    love.graphics.print(
        "Left: Railway / Buy Train",
        infoX + 10,
        infoY + 32
    )

    love.graphics.print(
        "Right: Station  Middle: Move  Wheel: Zoom",
        infoX + 205,
        infoY + 32
)
    if selectedStation then
        local w = stationPanel.width
        local h = stationPanel.height

        local x = love.graphics.getWidth() / 2 - w / 2
        local y = love.graphics.getHeight() / 2 - h / 2

        love.graphics.setColor(0.08, 0.08, 0.08, 0.95)

        love.graphics.rectangle(
            "fill",
            x,
            y,
            w,
            h
        )

        love.graphics.setColor(1, 1, 1)

        love.graphics.rectangle(
            "line",
            x,
            y,
            w,
            h
        )

        local route = getStationRoute(selectedStation)
        local length = getRouteLength(route)
        local income = getStationIncome(selectedStation)

        love.graphics.print(
            selectedStation.name,
            x + 20,
            y + 20
        )

        love.graphics.print(
            "Station #" .. selectedStation.id,
            x + 20,
            y + 50
        )

        love.graphics.print(
            "Level: " .. (selectedStation.level or 1),
            x + 20,
            y + 75
        )

        love.graphics.print(
            "Connected: " ..
            (selectedStation.connected and "Yes" or "No"),
            x + 20,
            y + 100
        )

        love.graphics.print(
            "Route: " .. length .. " tiles",
            x + 20,
            y + 125
        )

        love.graphics.print(
            "Income: $" .. income .. " / trip",
            x + 20,
            y + 150
        )

        love.graphics.rectangle(
            "fill",
            x + 20,
            y + 190,
            w - 40,
            40
        )

        love.graphics.setColor(0, 0, 0)

        love.graphics.printf(
            "Buy Train  $" .. trainPrice,
            x + 20,
            y + 202,
            w - 40,
            "center"
        )

        love.graphics.setColor(1, 1, 1)

        love.graphics.rectangle(
            "line",
            x + 20,
            y + 245,
            w - 40,
            35
        )

        love.graphics.printf(
            "Close",
            x + 20,
            y + 255,
            w - 40,
            "center"
        )
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        if selectedStation then
            return
        end

        local station = getStationAtScreen(x, y)

        if station then
            if station.isMain then
                return
            end

            selectedStation = station
            return
        end

        local gridX, gridY = screenToWorld(x, y)

        if canBuildRailway(gridX, gridY) then
            railway:add(gridX, gridY)
            updateConnections()
        end

    elseif button == 2 then
        dragging = true

        lastMouseX = x
        lastMouseY = y

    elseif button == 3 then
        if not selectedStation then
            local gridX, gridY = screenToWorld(x, y)

            createStation(gridX, gridY)
        end
    end
end

function love.mousereleased(x, y, button)
    if button == 2 then
        dragging = false
        return
    end

    if button ~= 1 then
        return
    end

    if not selectedStation then
        return
    end

    local w = stationPanel.width
    local h = stationPanel.height

    local panelX = love.graphics.getWidth() / 2 - w / 2
    local panelY = love.graphics.getHeight() / 2 - h / 2

    local buyX = panelX + 20
    local buyY = panelY + 190

    local closeX = panelX + 20
    local closeY = panelY + 245

    if x >= buyX and
       x <= buyX + w - 40 and
       y >= buyY and
       y <= buyY + 40 then

        buyTrain(selectedStation)

    elseif x >= closeX and
           x <= closeX + w - 40 and
           y >= closeY and
           y <= closeY + 35 then

        selectedStation = nil
    end
end

function love.mousemoved(x, y)
    if not dragging then
        return
    end

    camera.x = camera.x + x - lastMouseX
    camera.y = camera.y + y - lastMouseY

    lastMouseX = x
    lastMouseY = y
end

function love.wheelmoved(x, y)
    if y == 0 then
        return
    end

    local mouseX, mouseY = love.mouse.getPosition()

    local oldZoom = camera.zoom

    if y > 0 then
        camera.zoom = math.min(camera.zoom * 1.1, 4)
    else
        camera.zoom = math.max(camera.zoom / 1.1, 0.25)
    end

    if oldZoom == camera.zoom then
        return
    end

    local worldX = (
        mouseX -
        camera.x -
        love.graphics.getWidth() / 2
    ) / (Map.TILE_SIZE * oldZoom)

    local worldY = (
        mouseY -
        camera.y -
        love.graphics.getHeight() / 2
    ) / (Map.TILE_SIZE * oldZoom)

    camera.x = mouseX -
        love.graphics.getWidth() / 2 -
        worldX * Map.TILE_SIZE * camera.zoom

    camera.y = mouseY -
        love.graphics.getHeight() / 2 -
        worldY * Map.TILE_SIZE * camera.zoom
end

function getStationRailwayTile(station)
    local directions = {
        {1, 0},
        {-1, 0},
        {0, 1},
        {0, -1}
    }

    for _, direction in ipairs(directions) do
        local x = station.x + direction[1]
        local y = station.y + direction[2]

        if railway:has(x, y) then
            return x, y
        end
    end

    return nil
end

function getStationIncome(station)
    local route = getStationRoute(station)

    if not route then
        return 0
    end

    local length = getRouteLength(route)

    return length * INCOME_PER_TILE
end

function buyTrain(station)
    if station.isMain then
        return false
    end

    if not station.connected then
        return false
    end

    if not station.connected then
        return false
    end

    if money < trainPrice then
        return false
    end

    local railwayX, railwayY = getStationRailwayTile(station)

    if not railwayX then
        return false
    end

    local route = railway:findPath(
        0,
        0,
        railwayX,
        railwayY
    )

    if not route or #route < 1 then
        return false
    end

    table.insert(route, {
        x = station.x,
        y = station.y
    })

    money = money - trainPrice

    local train = Train.new(route)

    train.station = station
    train.income = getStationIncome(station)
    train.paid = false

    table.insert(trains, train)

    return true
end