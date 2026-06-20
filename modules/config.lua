local HttpService = game:GetService("HttpService")

local M = {}
local _data = {}
local _path = ""
local _autoSave = true
local _dirty = false

local function p(key)
    return type(key) == "table" and key or { key }
end

local function deepGet(tbl, keys)
    for _, k in ipairs(keys) do
        if type(tbl) ~= "table" or tbl[k] == nil then return nil end
        tbl = tbl[k]
    end
    return tbl
end

local function deepSet(tbl, keys, value)
    for i = 1, #keys - 1 do
        local k = keys[i]
        if type(tbl[k]) ~= "table" then tbl[k] = {} end
        tbl = tbl[k]
    end
    tbl[keys[#keys]] = value
end

local function deepRemove(tbl, keys)
    for i = 1, #keys - 1 do
        local k = keys[i]
        if type(tbl[k]) ~= "table" then return end
        tbl = tbl[k]
    end
    tbl[keys[#keys]] = nil
end

local function write()
    local ok, err = pcall(writefile, _path, HttpService:JSONEncode(_data))
    if ok then _dirty = false
    else warn("[Config] write failed:", err) end
end

local function mark()
    _dirty = true
    if _autoSave then write() end
end

function M.Init(opts)
    opts = opts or {}
    local folder = opts.folder or "AE-Library"
    _path     = folder .. "/" .. (opts.file or "config.json")
    _autoSave = opts.autoSave ~= false

    if not isfolder(folder) then
        local ok, err = pcall(makefolder, folder)
        if not ok then error("[Config] makefolder: " .. tostring(err)) end
    end

    if not isfile(_path) then
        local ok, err = pcall(writefile, _path, "{}")
        if not ok then error("[Config] writefile: " .. tostring(err)) end
    end

    local raw = readfile(_path)
    local ok, result = pcall(HttpService.JSONDecode, HttpService, raw)

    if ok and type(result) == "table" then
        _data = result
    else
        warn("[Config] corrupt JSON, backing up")
        pcall(writefile, _path .. ".bak", raw)
        _data = {}
        pcall(writefile, _path, "{}")
    end
end

function M.get(key)                    return deepGet(_data, p(key)) end
function M.has(key)                    return M.get(key) ~= nil end
function M.getOrDefault(key, default)  local v = M.get(key); return v ~= nil and v or default end
function M.set(key, value)             deepSet(_data, p(key), value); mark() end
function M.remove(key)                 deepRemove(_data, p(key)); mark() end
function M.reset()                     _data = {}; mark() end
function M.flush()                     _dirty = true; write() end

function M.toggle(key)
    local v = M.get(key)
    M.set(key, not (type(v) == "boolean" and v or false))
end

function M.add(key, n)
    local v = M.get(key)
    M.set(key, (type(v) == "number" and v or 0) + n)
end

function M.append(key, value)
    local list = M.get(key)
    if type(list) ~= "table" then list = {} end
    table.insert(list, value)
    M.set(key, list)
end

function M.pop(key)
    local list = M.get(key)
    if type(list) ~= "table" or #list == 0 then return end
    table.remove(list, #list)
    M.set(key, list)
end

function M.keys(key)
    local val = M.get(key)
    if type(val) ~= "table" then return {} end
    local out = {}
    for k in pairs(val) do table.insert(out, k) end
    return out
end

function M.strKeys(key)
    local val = M.get(key)
    if type(val) ~= "table" then return {} end
    local out = {}
    for k in pairs(val) do
        if type(k) == "string" then table.insert(out, k) end
    end
    return out
end

function M.batch(fn)
    local prev = _autoSave
    _autoSave = false
    local ok, err = pcall(fn)
    _autoSave = prev
    if not ok then warn("[Config] batch error:", err) end
    if _dirty then write() end
end

return M