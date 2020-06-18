local _M = {}

-- 获取两数之间的数组
function _M:getArrBetween(start, stop)
    local t = {}
    for i = start, stop, -1 do
        t[i] = i
    end
    return t
end

-- 解析出host和port
function _M.parseServer(server)
    if server == nil then
        return nil,nil
    end

    local position = string.find(server, ":")
    if position == nil then
        return server, nil
    end

    local host = string.sub(server, 1, position - 1)
    local port = string.sub(server, position + 1)
    
    return host, port
end

-- 序列化table，方便打印日志
function _M:serialize(obj)
    local str = ""
    local t = type(obj)
    if t == "number" then  
        str = str .. obj  
    elseif t == "boolean" then  
        str = str .. tostring(obj)  
    elseif t == "string" then  
        str = str .. string.format("%q", obj)  
    elseif t == "table" then  
        str = str .. "{"  
        for k, v in pairs(obj) do  
            str = str .. "[" .. self:serialize(k) .. "]=" .. self:serialize(v) .. ","  
        end  
        local metatable = getmetatable(obj)  
        if metatable ~= nil and type(metatable.__index) == "table" then  
            for k, v in pairs(metatable.__index) do  
                str = str .. "[" .. self:serialize(k) .. "]=" .. self:serialize(v) .. ","  
            end  
        end  
        str = str .. "}"  
    elseif t == "nil" then  
        return nil
    else  
        error("can not serialize a " .. t .. " type.")  
    end  
    return str  
end

return _M