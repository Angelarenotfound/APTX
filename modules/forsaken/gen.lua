local GenModule = {}

local genConfig = {
    enabled = false,
    speed = 0.03
}

if not table.clone then
    function table.clone(t)
        local result = {}
        for k, v in pairs(t) do
            result[k] = v
        end
        return result
    end
end

local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("Error en función: " .. tostring(result))
        return nil, result
    end
    return result
end

local function safeWait(delay)
    if type(delay) ~= "number" or delay < 0 then
        delay = 0.03
    end
    task.wait(delay)
end

local function getDirection(currentRow, currentCol, otherRow, otherCol)
    if not currentRow or not currentCol or not otherRow or not otherCol then
        return nil
    end

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
    return nil
end

local function getConnections(prev, curr, nextnode)
    local connections = {}

    if prev and curr then
        local dir = getDirection(curr.row, curr.col, prev.row, prev.col)
        if dir then
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
    end

    if nextnode and curr then
        local dir = getDirection(curr.row, curr.col, nextnode.row, nextnode.col)
        if dir and dir ~= "" then
            connections[dir] = true
        end
    end

    return connections
end

local function isNeighbourLocal(r1, c1, r2, c2)
    if not r1 or not c1 or not r2 or not c2 then
        return false
    end

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
    if not node or not node.row or not node.col then
        return nil
    end
    return string.format("%d-%d", node.row, node.col)
end

local function orderPathFromEndpoints(path, endpoints)
    if not path or #path == 0 then
        return path or {}
    end

    local startEndpoint = nil

    if endpoints and type(endpoints) == "table" then
        for _, ep in endpoints do
            if ep and ep.row and ep.col then
                for _, n in path do
                    if n.row == ep.row and n.col == ep.col then
                        startEndpoint = { row = ep.row, col = ep.col }
                        break
                    end
                end
            end
            if startEndpoint then
                break
            end
        end
    end

    if not startEndpoint then
        local inPath = {}
        for _, n in path do
            local key = coordKey(n)
            if key then
                inPath[key] = n
            end
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
                local key = string.format("%d-%d", r, c)
                if inPath[key] ~= nil then
                    neighbours = neighbours + 1
                end
            end
            if neighbours == 1 then
                startEndpoint = { row = n.row, col = n.col }
                break
            end
        end
    end

    if not startEndpoint and path[1] then
        startEndpoint = { row = path[1].row, col = path[1].col }
    end

    if not startEndpoint then
        return path
    end

    local remaining = {}
    for _, n in path do
        local key = coordKey(n)
        if key then
            remaining[key] = { row = n.row, col = n.col }
        end
    end

    local ordered = {}
    local current = { row = startEndpoint.row, col = startEndpoint.col }
    table.insert(ordered, table.clone(current))

    local key = coordKey(current)
    if key then
        remaining[key] = nil
    end

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
            local neighbour = isNeighbourLocal(current.row, current.col, node.row, node.col)
            if neighbour then
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
    if not genConfig.enabled then
        return nil
    end

    if not puzzle or not puzzle.Solution then
        warn("Puzzle no válido o sin solución")
        return nil
    end

    if delayTime == nil then
        delayTime = genConfig.speed
    end

    if type(delayTime) ~= "number" or delayTime < 0 then
        delayTime = 0.03
    end

    local totalPaths = #puzzle.Solution
    if totalPaths == 0 then
        warn("No hay caminos para dibujar")
        return nil
    end

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
        if puzzle.Solution[colorIndex] then
            local path = puzzle.Solution[colorIndex]
            local endpoints = puzzle.targetPairs and puzzle.targetPairs[colorIndex]
            local orderedPath = orderPathFromEndpoints(path, endpoints)

            if orderedPath and #orderedPath > 0 then
                if not puzzle.paths then
                    puzzle.paths = {}
                end
                puzzle.paths[colorIndex] = {}

                for i = 0, #orderedPath - 1 do
                    local node = orderedPath[i + 1]
                    if node and node.row and node.col then
                        table.insert(puzzle.paths[colorIndex], { row = node.row, col = node.col })

                        local prev = orderedPath[i]
                        local nextNode = orderedPath[i + 2]
                        local conn = getConnections(prev, node, nextNode)

                        if not puzzle.gridConnections then
                            puzzle.gridConnections = {}
                        end
                        local key = string.format("%d-%d", node.row, node.col)
                        puzzle.gridConnections[key] = conn

                        local success = safeCall(function()
                            if puzzle.updateGui then
                                puzzle:updateGui()
                            end
                        end)

                        if not success then
                            warn("Error al actualizar GUI")
                        end

                        safeWait(delayTime)
                    end
                end

                local success = safeCall(function()
                    if puzzle.checkForWin then
                        puzzle:checkForWin()
                    end
                end)

                if not success then
                    warn("Error al verificar victoria")
                end
            else
                warn("Camino ordenado vacío para color " .. tostring(colorIndex))
            end
        else
            warn("Índice de color " .. tostring(colorIndex) .. " no existe en la solución")
        end
    end

    local success = safeCall(function()
        if puzzle.checkForWin then
            puzzle:checkForWin()
        end
    end)

    if not success then
        warn("Error en verificación final")
    end
end

local function patchFlowGame()
    local success, ReplicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)

    if not success or not ReplicatedStorage then
        warn("No se pudo obtener ReplicatedStorage")
        return nil
    end

    local Modules = nil
    local attempts = 0
    while not Modules and attempts < 10 do
        local success, result = pcall(function()
            return ReplicatedStorage:FindFirstChild("Modules")
        end)
        if success and result then
            Modules = result
            break
        end
        attempts = attempts + 1
        task.wait(0.1)
    end

    if not Modules then
        warn("No se encontró el módulo Modules después de varios intentos")
        return nil
    end

    local Misc = nil
    attempts = 0
    while not Misc and attempts < 10 do
        local success, result = pcall(function()
            return Modules:FindFirstChild("Minigames")
        end)
        if success and result then
            Misc = result
            break
        end
        attempts = attempts + 1
        task.wait(0.1)
    end

    if not Misc then
        warn("No se encontró el módulo Misc")
        return nil
    end

    local FlowGameManager = nil
    attempts = 0
    while not FlowGameManager and attempts < 10 do
        local success, result = pcall(function()
            return Misc:FindFirstChild("FlowGameManager")
        end)
        if success and result then
            FlowGameManager = result
            break
        end
        attempts = attempts + 1
        task.wait(0.1)
    end

    if not FlowGameManager then
        warn("No se encontró FlowGameManager")
        return nil
    end

    local FlowGameModule = nil
    attempts = 0
    while not FlowGameModule and attempts < 10 do
        local success, result = pcall(function()
            return FlowGameManager:FindFirstChild("FlowGame")
        end)
        if success and result then
            FlowGameModule = result
            break
        end
        attempts = attempts + 1
        task.wait(0.1)
    end

    if not FlowGameModule then
        warn("No se encontró el módulo FlowGame")
        return nil
    end

    local gameModule = nil
    local success, result = pcall(function()
        return require(FlowGameModule)
    end)

    if not success or not result then
        warn("No se pudo cargar el módulo FlowGame: " .. tostring(result))
        return nil
    end

    gameModule = result

    if gameModule.new then
        local oldNew = gameModule.new
        gameModule.new = function(...)
            local success, result = pcall(oldNew, ...)

            if not success or not result then
                warn("Error al crear nuevo FlowGame: " .. tostring(result))
                return result
            end

            local puzzle = result

            if GenModule._solverThread and coroutine.status(GenModule._solverThread) ~= "dead" then
                task.cancel(GenModule._solverThread)
            end
            GenModule._solverThread = task.spawn(function()
                local success = safeCall(function()
                    HintSystem:DrawSolutionOneByOne(puzzle)
                end)
                if not success then
                    warn("Error al ejecutar HintSystem")
                end
            end)

            return puzzle
        end
    else
        warn("El módulo FlowGame no tiene función 'new'")
        return nil
    end
end

function GenModule.State(enabled)
    if enabled ~= nil then
        genConfig.enabled = enabled
    end
    return genConfig.enabled
end

function GenModule.Speed(speed)
    if speed ~= nil and type(speed) == "number" and speed >= 0 then
        genConfig.speed = speed
    end
    return genConfig.speed
end

task.spawn(function()
    local success = safeCall(patchFlowGame)
    if not success then
        warn("Error al parchear FlowGame")
    end
end)

return GenModule