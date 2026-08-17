local Train = {}
Train.__index = Train

function Train.new(route)
    return setmetatable({
        route = route,
        index = 1,
        progress = 0,
        speed = 3,
        waitTime = 0,
        waiting = false,
        returning = false,
        station = nil,
        income = 0
    }, Train)
end

function Train:update(dt)
    if self.waiting then
        self.waitTime = self.waitTime - dt

        if self.waitTime <= 0 then
            self.waiting = false
            self.progress = 0

            self:returnToStart()
        end

        return false
    end

    if self.index >= #self.route then
        return self:arrive()
    end

    self.progress = self.progress + self.speed * dt

    while self.progress >= 1 do
        self.progress = self.progress - 1
        self.index = self.index + 1

        if self.index >= #self.route then
            return self:arrive()
        end
    end

    return false
end

function Train:arrive()
    self.index = #self.route
    self.progress = 0
    self.waiting = true
    self.waitTime = 3

    return true
end

function Train:returnToStart()
    local reversed = {}

    for i = #self.route, 1, -1 do
        table.insert(reversed, self.route[i])
    end

    self.route = reversed
    self.index = 1
    self.progress = 0
    self.waiting = false
    self.returning = not self.returning

    if self.returning then
        self.paid = false
    else
        self.paid = false
    end
end

function Train:getPosition()
    local current = self.route[self.index]

    if not current then
        return nil, nil
    end

    local next = self.route[self.index + 1]

    if not next then
        return current.x, current.y
    end

    local x = current.x + (next.x - current.x) * self.progress
    local y = current.y + (next.y - current.y) * self.progress

    return x, y
end

return Train