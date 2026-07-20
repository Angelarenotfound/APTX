local Gen = {}

local config = {
    enabled = false,
    speed = 0.03
}

local function getDirection(currentRow, currentCol, otherRow, otherCol)
    if otherRow < currentRow then
        return "up"
    end
    if otherRow > currentRow then
        return "down"
    end
    if otherCol < currentCol then
        return "left"
    end
    if otherCol > currentCol then
        return "right"
    end
end

local function getConnections(prev, curr, nextnode)
    local connections = {}
    if prev and curr then
        local dir = getDirection(curr.row, curr.col, prev.row, prev.col)
        if dir == "up" then
            dir = "down"
        elseif dir == "down" then
            dir = "up"
        elseif dir == "left" then
            dir = "right"
        elseif dir == "right" then
            dir = "left"
        end
        if dir ~= "" and dir then
            connections[dir] = true
        end
    end
    if nextnode and curr then
        local dir = getDirection(curr.row, curr.col, nextnode.row, nextnode.col)
        if dir ~= "" and dir then
            connections[dir] = true
        end
    end
    return connections
end

local function isNeighbourLocal(r1, c1, r2, c2)
    if r2 == r1 - 1 and c2 == c1 then
        return "up"
    end
    if r2 == r1 + 1 and c2 == c1 then
        return "down"
    end
    if r2 == r1 and c2 == c1 - 1 then
        return "left"
    end
    if r2 == r1 and c2 == c1 + 1 then
        return "right"
    end
    return false
end

local function coordKey(node)
    return string.format("%d-%d", node.row, node.col)
end

local function orderPathFromEndpoints(path, endpoints)
    if not path or #path == 0 then
        return path
    end
    
    local startEndpoint
    for _, ep in endpoints or {} do
        for _, n in path do
            if n.row == ep.row and n.col == ep.col then
                startEndpoint = { row = ep.row, col = ep.col }
                break
            end
        end
        if startEndpoint then
            break
        end
    end
    
    if not startEndpoint then
        local inPath = {}
        for _, n in path do
            inPath[coordKey(n)] = n
        end
        for _, n in path do
            local neighbours = 0
            local dirs = {
                { n.row - 1, n.col },
                { n.row + 1, n.col },
                { n.row, n.col - 1 },
                { n.row, n.col + 1 }
            }
            for _, dir in dirs do
                local r, c = dir[1], dir[2]
                if inPath[string.format("%d-%d", r, c)] ~= nil then
                    neighbours = neighbours + 1
                end
            end
            if neighbours == 1 then
                startEndpoint = { row = n.row, col = n.col }
                break
            end
        end
    end
    
    if not startEndpoint then
        startEndpoint = { row = path[1].row, col = path[1].col }
    end
    
    local remaining = {}
    for _, n in path do
        remaining[coordKey(n)] = { row = n.row, col = n.col }
    end
    
    local ordered = {}
    local current = { row = startEndpoint.row, col = startEndpoint.col }
    table.insert(ordered, table.clone(current))
    remaining[coordKey(current)] = nil
    
    while true do
        local size = 0
        for _ in remaining do
            size = size + 1
        end
        if not (size > 0) then
            break
        end
        
        local foundNext = false
        for key, node in remaining do
            if isNeighbourLocal(current.row, current.col, node.row, node.col) then
                table.insert(ordered, table.clone(node))
                remaining[key] = nil
                current = node
                foundNext = true
                break
            end
        end
        if not foundNext then
            return path
        end
    end
    
    return ordered
end

local HintSystem = {}

function HintSystem:DrawSolutionOneByOne(puzzle, delayTime)
    if delayTime == nil then
        delayTime = config.speed
    end
    if not config.enabled or not puzzle or not puzzle.Solution then
        return nil
    end
    
    local totalPaths = #puzzle.Solution
    local indices = {}
    for i = 1, totalPaths do
        table.insert(indices, i)
    end
    
    for i = #indices - 1, 2, -1 do
        local j = math.random(1, i)
        local temp = indices[i + 1]
        indices[i + 1] = indices[j + 1]
        indices[j + 1] = temp
    end
    
    for _, colorIndex in indices do
        local path = puzzle.Solution[colorIndex]
        local endpoints = puzzle.targetPairs[colorIndex]
        local orderedPath = orderPathFromEndpoints(path, endpoints)
        
        puzzle.paths[colorIndex] = {}
        for i = 0, #orderedPath - 1 do
            local node = orderedPath[i + 1]
            table.insert(puzzle.paths[colorIndex], { row = node.row, col = node.col })
            
            local prev = orderedPath[i]
            local nextNode = orderedPath[i + 2]
            local conn = getConnections(prev, node, nextNode)
            puzzle.gridConnections = puzzle.gridConnections or {}
            puzzle.gridConnections[string.format("%d-%d", node.row, node.col)] = conn
            
            puzzle:updateGui()
            task.wait(delayTime)
        end
        puzzle:checkForWin()
    end
    puzzle:checkForWin()
end

local function patchFlowGame()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local FlowGameModule = require(ReplicatedStorage:WaitForChild("Modules"):FindFirstChild("Misc"):FindFirstChild("FlowGameManager"):FindFirstChild("FlowGame"))
    
    local oldNew = FlowGameModule.new
    FlowGameModule.new = function(...)
        local args = { ... }
        local output = { oldNew(unpack(args)) }
        local puzzle = output[1]
        
        task.spawn(function()
            HintSystem:DrawSolutionOneByOne(puzzle)
        end)
        
        return puzzle
    end
end

function Gen.State(enabled)
    if enabled ~= nil then
        config.enabled = enabled
    end
    return config.enabled
end

function Gen.Speed(speed)
    if speed ~= nil and type(speed) == "number" and speed >= 0 then
        config.speed = speed
    end
    return config.speed
end

task.spawn(function()
    patchFlowGame()
end)

return Gen