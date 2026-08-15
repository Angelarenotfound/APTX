local GenModule = {}

local genConfig = {
    enabled = false,
    speed = 0.03
}

if not table.clear then
    function table.clear(t)
        for k in pairs(t) do
            t[k] = nil
        end
    end
end

local dirs = {
    { -1, 0 },
    { 1, 0 },
    { 0, -1 },
    { 0, 1 }
}

local function logErr(err)
    warn("GenModule: " .. tostring(err))
end

local function coordKey(row, col)
    return row .. "-" .. col
end

local function validNode(node)
    return node ~= nil and node.row ~= nil and node.col ~= nil
end

local function getConnections(prev, curr, next)
    local conn = {}

    if prev and prev.row ~= nil and prev.col ~= nil and curr and curr.row ~= nil and curr.col ~= nil then
        if prev.row < curr.row then
            conn.down = true
        elseif prev.row > curr.row then
            conn.up = true
        elseif prev.col < curr.col then
            conn.right = true
        elseif prev.col > curr.col then
            conn.left = true
        end
    end

    if next and next.row ~= nil and next.col ~= nil and curr and curr.row ~= nil and curr.col ~= nil then
        if next.row < curr.row then
            conn.up = true
        elseif next.row > curr.row then
            conn.down = true
        elseif next.col < curr.col then
            conn.left = true
        elseif next.col > curr.col then
            conn.right = true
        end
    end

    return conn
end

local function countNeighbors(byKey, row, col)
    local count = 0

    for _, d in dirs do
        if byKey[coordKey(row + d[1], col + d[2])] then
            count += 1
        end
    end

    return count
end

local function orderPath(path, endpoints)
    if not path or #path == 0 then
        return {}
    end

    local byKey = {}

    for _, node in path do
        if validNode(node) then
            byKey[coordKey(node.row, node.col)] = node
        end
    end

    local start

    if endpoints and type(endpoints) == "table" then
        for _, ep in endpoints do
            if validNode(ep) then
                local node = byKey[coordKey(ep.row, ep.col)]

                if node then
                    start = node
                    break
                end
            end
        end
    end

    if not start then
        for _, node in path do
            if validNode(node) and countNeighbors(byKey, node.row, node.col) == 1 then
                start = node
                break
            end
        end
    end

    if not validNode(start) then
        start = path[1]
    end

    if not validNode(start) then
        return path
    end

    local remaining = byKey
    remaining[coordKey(start.row, start.col)] = nil

    local remainingCount = 0

    for _ in remaining do
        remainingCount += 1
    end

    local ordered = { start }
    local current = start

    while remainingCount > 0 do
        local nextNode
        local nextKey

        for _, d in dirs do
            local key = coordKey(current.row + d[1], current.col + d[2])
            local node = remaining[key]

            if node then
                nextNode = node
                nextKey = key
                break
            end
        end

        if not nextNode then
            break
        end

        ordered[#ordered + 1] = nextNode
        remaining[nextKey] = nil
        remainingCount -= 1
        current = nextNode
    end

    return ordered
end

local function resetSolverState(puzzle)
    if type(puzzle.paths) == "table" then
        if type(puzzle._genColors) == "table" then
            for _, colorIndex in puzzle._genColors do
                puzzle.paths[colorIndex] = nil
            end
        else
            table.clear(puzzle.paths)
        end
    else
        puzzle.paths = {}
    end

    if type(puzzle.gridConnections) == "table" then
        if type(puzzle._genKeys) == "table" then
            for _, key in puzzle._genKeys do
                puzzle.gridConnections[key] = nil
            end
        else
            table.clear(puzzle.gridConnections)
        end
    else
        puzzle.gridConnections = {}
    end

    puzzle._genColors = {}
    puzzle._genKeys = {}
    puzzle._genKeySet = {}
end

local HintSystem = {}

function HintSystem.solve(puzzle, delayTime)
    if not genConfig.enabled then
        return
    end

    if type(puzzle) ~= "table" or type(puzzle.Solution) ~= "table" or #puzzle.Solution == 0 then
        return
    end

    if type(delayTime) ~= "number" or delayTime < 0 then
        delayTime = genConfig.speed
    end

    if type(delayTime) ~= "number" or delayTime < 0 then
        delayTime = 0
    end

    resetSolverState(puzzle)

    local indices = {}

    for i = 1, #puzzle.Solution do
        indices[i] = i
    end

    for i = #indices, 2, -1 do
        local j = math.random(i)
        indices[i], indices[j] = indices[j], indices[i]
    end

    local updateThread

    local function updateNow()
        if type(puzzle.updateGui) == "function" then
            local ok, err = pcall(puzzle.updateGui, puzzle)

            if not ok then
                logErr(err)
            end
        end
    end

    local function requestUpdate()
        if updateThread then
            return
        end

        updateThread = task.defer(function()
            updateThread = nil
            updateNow()
        end)
    end

    local function flushUpdate()
        if not updateThread then
            return
        end

        task.cancel(updateThread)
        updateThread = nil
        updateNow()
    end

    for _, colorIndex in indices do
        local path = puzzle.Solution[colorIndex]

        if type(path) == "table" then
            local endpoints = puzzle.targetPairs and puzzle.targetPairs[colorIndex]
            local ordered = orderPath(path, endpoints)

            if #ordered > 0 then
                puzzle._genColors[#puzzle._genColors + 1] = colorIndex

                local line = {}
                puzzle.paths[colorIndex] = line

                for i = 1, #ordered do
                    local node = ordered[i]

                    if validNode(node) then
                        line[#line + 1] = { row = node.row, col = node.col }

                        local key = coordKey(node.row, node.col)
                        puzzle.gridConnections[key] = getConnections(ordered[i - 1], node, ordered[i + 1])

                        if not puzzle._genKeySet[key] then
                            puzzle._genKeySet[key] = true
                            puzzle._genKeys[#puzzle._genKeys + 1] = key
                        end

                        requestUpdate()

                        if delayTime > 0 then
                            task.wait(delayTime)
                        elseif i % 250 == 0 then
                            task.wait()
                        end
                    end
                end
            end
        end
    end

    flushUpdate()

    if type(puzzle.checkForWin) == "function" then
        task.defer(function()
            local ok, err = pcall(puzzle.checkForWin, puzzle)

            if not ok then
                logErr(err)
            end
        end)
    end
end

local activeThread

local function cancelThread(thread)
    if thread and thread ~= coroutine.running() and coroutine.status(thread) ~= "dead" then
        pcall(task.cancel, thread)
    end
end

local function startSolver(puzzle)
    if type(puzzle) == "table" then
        cancelThread(puzzle._genSolver)

        puzzle._genSolver = task.defer(function()
            local current = coroutine.running()

            HintSystem.solve(puzzle)

            if puzzle._genSolver == current then
                puzzle._genSolver = nil
            end
        end)

        return
    end

    cancelThread(activeThread)

    activeThread = task.defer(function()
        local current = coroutine.running()

        HintSystem.solve(puzzle)

        if activeThread == current then
            activeThread = nil
        end
    end)
end

local function unwrapNew(wrapper)
    if type(wrapper) ~= "function" then
        return nil
    end

    if type(debug) ~= "table" or type(debug.getupvalue) ~= "function" then
        return nil
    end

    local current = wrapper

    for _ = 1, 5 do
        local ok, nextFn = pcall(function()
            local i = 1

            while true do
                local name, value = debug.getupvalue(current, i)

                if not name then
                    return nil
                end

                if type(value) == "function" and value ~= current then
                    if name == "oldNew" or name == "original" or name == "_originalNew" or name == "old" then
                        return value
                    end
                end

                i += 1
            end
        end)

        if not ok or type(nextFn) ~= "function" or nextFn == current then
            break
        end

        current = nextFn
    end

    if current ~= wrapper then
        return current
    end

    return nil
end

local function attemptPatch()
    local ok, ReplicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)

    if not ok or not ReplicatedStorage then
        return false
    end

    local Modules = ReplicatedStorage:FindFirstChild("Modules")

    if not Modules then
        return false
    end

    local Minigames = Modules:FindFirstChild("Minigames")

    if not Minigames then
        return false
    end

    local FlowGameManager = Minigames:FindFirstChild("FlowGameManager")

    if not FlowGameManager then
        return false
    end

    local FlowGameModule = FlowGameManager:FindFirstChild("FlowGame")

    if not FlowGameModule then
        return false
    end

    local requireOk, gameModule = pcall(require, FlowGameModule)

    if not requireOk or type(gameModule) ~= "table" then
        return false
    end

    if gameModule._genPatched then
        return true
    end

    local oldNew = gameModule._genOriginal

    if not oldNew and gameModule._patched then
        oldNew = unwrapNew(gameModule.new)

        if not oldNew then
            return true
        end
    end

    if not oldNew then
        oldNew = gameModule.new
    end

    if type(oldNew) ~= "function" then
        return false
    end

    if oldNew == gameModule.new and gameModule._patched then
        return true
    end

    gameModule._genOriginal = oldNew

    gameModule.new = function(...)
        local results = table.pack(pcall(oldNew, ...))

        if not results[1] then
            logErr(results[2])
            return nil
        end

        local puzzle = results[2]

        if puzzle then
            startSolver(puzzle)
        end

        return table.unpack(results, 2, results.n)
    end

    gameModule._genPatched = true
    gameModule._patched = true

    return true
end

local function patchFlowGame()
    task.wait(3)

    for _ = 1, 20 do
        if attemptPatch() then
            return true
        end

        task.wait(2)
    end

    return false
end

function GenModule.State(enabled)
    if enabled ~= nil then
        genConfig.enabled = not not enabled
    end

    return genConfig.enabled
end

function GenModule.Speed(speed)
    if type(speed) == "number" and speed >= 0 then
        genConfig.speed = speed
    end

    return genConfig.speed
end

task.spawn(function()
    local ok, result = pcall(patchFlowGame)

    if not ok then
        logErr(result)
    elseif result == false then
        logErr("patch failed")
    end
end)

return GenModule