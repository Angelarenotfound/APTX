local Server = {}
Server.__index = Server

local http = game:GetService("HttpService")
local ls = game:GetService("LocalizationService")
local tp = game:GetService("TeleportService")

local MAP = {
    ["en-us"]="us-east",["es-mx"]="us-east",["es-es"]="eu-west",
    ["pt-br"]="sa-east",["en-gb"]="eu-west",["de-de"]="eu-central",
    ["fr-fr"]="eu-west",["it-it"]="eu-central",["ru-ru"]="eu-central",
    ["ja-jp"]="ap-northeast",["ko-kr"]="ap-northeast",["zh-cn"]="ap-northeast",
    ["zh-tw"]="ap-northeast",["id-id"]="ap-southeast",["th-th"]="ap-southeast",
    ["vi-vn"]="ap-southeast",["hi-in"]="ap-south",["ms-my"]="ap-southeast",
}

local function getRegion()
    local ok, v = pcall(function() return ls:GetColocatedRegion() end)
    if not ok or not v then return "us-east" end
    return MAP[string.lower(v)] or "us-east"
end

local function getRequest()
    if syn and syn.request then return syn.request end
    if request then return request end
    error("[Server] El executor no soporta HTTP requests")
end

function Server:Init(cfg)
    assert(cfg, "[Server] Init requiere una tabla de configuración")
    assert(cfg.url, "[Server] cfg.url es requerido")
    assert(cfg.player, "[Server] cfg.player es requerido")

    self._url = cfg.url
    self._player = cfg.player
    self._place = cfg.place_id or game.PlaceId
    self._region = cfg.region or getRegion()
    self._ping = cfg.ping or 200
    self._score = cfg.score or 0.1
    self._limit = cfg.limit or 10
    self._fn = getRequest()
    self._ready = true

    print(string.format("[Server] Iniciado | jugador: %s | región: %s | url: %s",
        self._player.Name, self._region, self._url))

    return self
end

function Server:_req(endpoint, method, body)
    assert(self._ready, "[Server] Llama Init() primero")

    local opts = {
        Url = self._url .. endpoint,
        Method = method or "GET",
        Headers = { ["Content-Type"] = "application/json" },
    }
    if body then opts.Body = http:JSONEncode(body) end

    local ok, res = pcall(self._fn, opts)
    if not ok then error("[Server] Request falló: " .. tostring(res)) end

    local msg = {
        [429] = "Rate limit alcanzado, espera un momento",
        [502] = "Backend no pudo contactar la API de Roblox",
        [404] = "Endpoint no encontrado",
        [405] = "Método no permitido",
        [415] = "Content-Type inválido",
        [500] = "Error interno del servidor",
    }
    if msg[res.StatusCode] then error("[Server] " .. msg[res.StatusCode]) end
    if res.StatusCode ~= 200 then
        error("[Server] HTTP " .. res.StatusCode .. ": " .. tostring(res.Body))
    end

    local dok, data = pcall(function() return http:JSONDecode(res.Body) end)
    if not dok then error("[Server] JSON inválido en respuesta") end
    return data
end

function Server:Find(ping, score, limit)
    assert(self._ready, "[Server] Llama Init() primero")

    local body = {
        place_id = self._place,
        user_region = self._region,
        max_ping = ping or self._ping,
        min_availability_score = score or self._score,
        limit = limit or self._limit,
    }

    print(string.format("[Server:Find] región: %s | ping máx: %d | score mín: %.2f | límite: %d",
        body.user_region, body.max_ping, body.min_availability_score, body.limit))

    local ok, data = pcall(function() return self:_req("/servers/find", "POST", body) end)
    if not ok then
        warn("[Server:Find] " .. tostring(data))
        return nil
    end

    if not data.servers or #data.servers == 0 then
        warn("[Server:Find] No se encontraron servidores con esos filtros")
        return nil
    end

    print(string.format("[Server:Find] %d servidor(es) | %.2fms | cache: %s",
        data.total_found, data.elapsed_ms, tostring(data._cache_hit)))

    for i, srv in ipairs(data.servers) do
        print(string.format("  [%d] %s | %d/%d jugadores | %dms | %.1f fps | score: %.4f | %s",
            i, srv.server_id, srv.player_count, srv.max_players,
            srv.ping, srv.fps, srv.availability_score, srv.estimated_region))
    end

    self._last = data
    return data
end

function Server:Join(index)
    assert(self._ready, "[Server] Llama Init() primero")

    local data = self._last
    if not data then
        warn("[Server:Join] No hay resultados, llama Find() primero")
        return false
    end

    index = index or 1
    local srv = data.servers[index]
    if not srv then
        warn("[Server:Join] Índice " .. index .. " no existe en los resultados")
        return false
    end

    print(string.format("[Server:Join] Uniéndose a [%d] %s (ping: %dms, score: %.4f)",
        index, srv.server_id, srv.ping, srv.availability_score))

    local ok, err = pcall(function()
        tp:TeleportToPlaceInstance(srv.place_id, srv.server_id, self._player)
    end)

    if not ok then
        warn("[Server:Join] Teleport falló: " .. tostring(err))
        return false
    end

    return true
end

function Server:Best(ping, score)
    local data = self:Find(ping, score, 1)
    if not data then return false end
    return self:Join(1)
end

function Server:Regions()
    assert(self._ready, "[Server] Llama Init() primero")

    local ok, data = pcall(function() return self:_req("/servers/regions", "GET") end)
    if not ok then
        warn("[Server:Regions] " .. tostring(data))
        return nil
    end

    print("[Server:Regions] Regiones disponibles:")
    for _, r in ipairs(data.regions) do
        local active = r.region == self._region and " <- tuya" or ""
        print(string.format("  %s | %dms%s", r.region, r.self_latency_ms, active))
    end

    return data
end

function Server:Health()
    assert(self._ready, "[Server] Llama Init() primero")

    local ok, data = pcall(function() return self:_req("/servers/health", "GET") end)
    if not ok then
        warn("[Server:Health] " .. tostring(data))
        return nil
    end

    print(string.format("[Server:Health] status: %s | cache: %d/%d | ttl: %ds",
        data.status, data.cache_size, data.cache_maxsize, data.cache_ttl_seconds))

    return data
end

function Server:SetRegion(r)
    assert(self._ready, "[Server] Llama Init() primero")
    self._region = r
    print("[Server:SetRegion] Región cambiada a: " .. r)
    return self
end

function Server:Last()
    return self._last
end

return Server