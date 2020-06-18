local Math = require('math')
local Constants = require('utils.constants')
local Cjson = require('cjson')
local PomeloMysql = require('mysql.pomelo')

Cjson.encode_sparse_array(true) --稀疏数组encode报错问题


-- 共享内存块
local upstream_gate = ngx.shared.upstream_gate
local upstream_http = ngx.shared.upstream_http
local upstream_ch1  = ngx.shared.upstream_ch1
local upstream_ch2  = ngx.shared.upstream_ch2
local upstream_ch3  = ngx.shared.upstream_ch3
local channel_size  = ngx.shared.channel_size
local ch_map        = ngx.shared.ch_map

local _M = {}

-- 更新http或者gate
function _M:setHttpOrGate(shared, serverArr)
    for k, v in pairs(serverArr) do
        shared:set(v.server, 1)
    end
end

-- 随机选取一个空闲id
function _M:getFreeId(freeIds)
    local tmpKeyA, n = {}, 1
    for k, v in pairs(freeIds) do
        tmpKeyA[n] = k
        n = n + 1
    end
    if n <= 1 then
        return nil
    end
    Math.randomseed(ngx.time())
    local key = Math.random(1, n - 1);
    local value = freeIds[tmpKeyA[key]]
    freeIds[value] = nil
    -- ngx.log(ngx.ERR, 'getFreeId, key: ',key, ' value: ', value,' tk: ', Cjson.encode(tmpKeyA))
    return value
end

-- 更新connector
function _M:setChMulti(shared, serverArr)
    local len = #serverArr
    local freeIds = shared:get(Constants.KEY_WORDS.FREEIDS);

    if freeIds == nil then -- 首次做节点映射
        freeIds = {}
        for i = len, 1, -1 do
            freeIds[i] = i
        end
        shared:set(i, '') -- 占位
    else
        freeIds = Cjson.decode(freeIds)
    end
    
    local memLen = #shared:get_keys()
    for k, v in pairs(serverArr) do
        local isAssign = ch_map:get(v.server)
        if isAssign == nil then --检查是否已经被分配过
            isAssign = self:getFreeId(freeIds)
            -- ngx.log(ngx.ERR, 'assign: ', isAssign, ' server:', v.server, 'freeIds', Cjson.encode(freeIds))
            if isAssign == nil then -- 扩容节点增多，不够分配
                isAssign = memLen  --以已存储长度进行节点累加
                memLen = memLen + 1
            end
            ch_map:set(v.server, isAssign)
        end
        shared:set(isAssign, v.server)
    end
    -- 更新空闲节点
    shared:set(Constants.KEY_WORDS.FREEIDS, Cjson.encode(freeIds))
end

-- 删除服务
function _M:delCh(shared, server)
    local freeId = ch_map:get(server)
    if freeId ~= nil then
        local freeIds = shared:get(Constants.KEY_WORDS.FREEIDS);
        freeIds = Cjson.decode(freeIds)
        freeIds[freeId] = freeId
        shared:set(Constants.KEY_WORDS.FREEIDS, Cjson.encode(freeIds))
        shared:set(freeId, '')
    end
    ch_map:delete(server)
end

-- 更新反代共享内存
function _M:updateAll(searchData)
    for serverType, serverArr in pairs(searchData) do
        if serverType == Constants.SERVER_TYPE.GATE then
            self:setHttpOrGate(upstream_gate, serverArr)
        elseif serverType == Constants.SERVER_TYPE.CONNECTOR_TUTOR then 
            self:setChMulti(upstream_ch1, serverArr)
        elseif serverType == Constants.SERVER_TYPE.CONNECTOR_LEC then
            self:setChMulti(upstream_ch2, serverArr)
        elseif serverType == Constants.SERVER_TYPE.CONNECTOR_TEACHER then
            self:setChMulti(upstream_ch3, serverArr)
        elseif serverType == Constants.SERVER_TYPE.HTTP_CHAT then
            self:setHttpOrGate(upstream_http, serverArr)
        end
    end
end

-- 更新频道
function _M:updateChannel(pullChannel)
    for k,v in pairs(pullChannel) do
        channel_size:set(v.channel_id, v.mode, Constants.TIME.CH_SIZE_EXPIRE)
    end
end

-- 根据频道查找size
function _M:getChannelSizeByRid(rid)
    local search = channel_size:get(rid)
    if not search then
        local res = PomeloMysql:findByChannelId(rid)
        if #res == 0 then
            return nil
        end
        -- search = res[1].mode
        -- channel_size:set(rid, search, Constants.TIME.CH_SIZE_EXPIRE)
    end
    return search
end

return _M