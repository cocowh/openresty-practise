local Math = require('math')
local Balancer = require('ngx.balancer')
local Shared = require('shared.manager')
local Constants = require('utils.constants')
local Util = require('utils.util')

local _M = {}

-- 随机选取服务
function _M:getRandomServer(ch, len, seed)
  local server, start = nil, nil

  if not seed then
    Math.randomseed(ngx.time())
    seed = Math.random(len)
    start = seed
  else
    start = seed % len + 1
  end

  repeat
    server = ch:get(start)
    if server then
      return server, start
    end
    start = start % len + 1
  until(start == seed)
  return nil, start
end

-- 随机获取数组值
function _M:getRandomSeed(arr)
  if #arr == 0 then
    return nil
  end

  local tmpKeyA, n = {}, 1
  for k, v in pairs(arr) do
    tmpKeyA[n] = k
    n = n + 1
  end
  Math.randomseed(ngx.time())
  local key = Math.random(1, n - 1);
  local value = arr[tmpKeyA[key]]
  return value
end

-- 先hash再rr
function _M:getServerByHashAndRr(ch, rid, len, seed)
  if len == 0 then
    return nil,nil
  end
  local groupNum = Math.ceil(len / Constants.COUNT.SERVER_GROUP)
  local start, stop, hashCode = nil, nil, nil

  if not seed then
    hashCode = ngx.crc32_long(rid) % groupNum
  else
    hashCode = Math.floor(seed / Constants.COUNT.SERVER_GROUP)
  end
  start = hashCode * Constants.COUNT.SERVER_GROUP + 1
  stop = start + Constants.COUNT.SERVER_GROUP

  if stop > len then
    stop = len
  end

  local arr = Util:getArrBetween(start, stop)
  
  if seed then
    arr[seed] = nil
  end

  local flag, rs = false, nil
  repeat
    local rs = self:getRandomSeed(arr)
    if not rs then
      flag = true
    end
    local server = ch:get(start)
    if server then
      return server, start
    else
      arr[rs] = nil
    end
  until(flag)
  return nil, rs
end

-- hash获取server
function _M:getServerByHash(ch, rid, len, seed)
  if len == 0 then
    return nil, nil
  end
  if len == 1 and seed ~= nil then
    return nil, seed
  end

  local start = nil
  if not seed then
    local hash = ngx.crc32_long(rid)
    seed = hash % len + 1
    start = seed
  else
    start = seed % len + 1
  end

  repeat
    local server = ch:get(start)
    if server then
      return server, start
    end
    start = start % len + 1
  until(start == seed)

  return nil, seed
end

-- 通过rid判断频道大小
function _M:getChannelSizeByRid()
  local rid = ngx.var.arg_rid
  if rid == nil then
    return Constants.CHANNEL_SIZE.BIG, nil
  end
  rid = Util.parseServer(rid)
  local size = Shared:getChannelSizeByRid(rid)
  if size == nil or size == Constants.CHANNEL_SIZE.MIDDLE then
    return Constants.CHANNEL_SIZE.MIDDLE, rid
  elseif size == Constants.CHANNEL_SIZE.SMALL then
    return Constants.CHANNEL_SIZE.SMALL, rid
  else
    return Constants.CHANNEL_SIZE.BIG, rid
  end
end


-- 设置连接
function _M:setPeer(server)
  local host, port = Util.parseServer(server)
    
  Balancer.set_more_tries(Constants.RETRY_TIMES.SET_BALANCER)
  local ok, err = Balancer.set_current_peer(host, port)

  if not ok then
      ngx.log(ngx.ERR, "failed to set the current peer: ", err, " server: ", server)
      return false
  end
  return true
end

-- connector动态反代
function _M:upstreamCh(ch, size, rid)
  local retryTimes, ok, server, seed = Constants.RETRY_TIMES.SELECT_BALANCER, false, nil, nil
  local serverKeys = ch:get_keys()
  local len = #serverKeys - 1
  
  if len <= 0 then
    ngx.log(ngx.ERR, 'no enough server to get, rid:', rid, ' size:', size)
    return ngx.exit(500)
  end
  
  repeat
    if size == Constants.CHANNEL_SIZE.SMALL then -- 小班
      if not seed then
        server, seed = self:getServerByHash(ch, rid, len)
      else
        server, seed = self:getServerByHash(ch, rid, len, seed)
      end
      if not server then
        ngx.log(ngx.ERR, 'get small channel server fail, server: ', server, ' seed:', seed)
      else
        ok = self:setPeer(server)
        if not ok then
          Shared:delCh(server)
        end
      end
    elseif size == Constants.CHANNEL_SIZE.BIG then -- 大班
      if not seed then
        server, seed = self:getRandomServer(ch, len)
      else
        server, seed = self:getRandomServer(ch, len, seed)
      end
        if not server then
          ngx.log(ngx.ERR, 'get middle channel server fail, server: ', server, ' seed:', seed)
        else
          ok = self:setPeer(server)
          if not ok then
            Shared:delCh(ch, server)
          end
        end
    else                                        --中班
      if not seed then
        server, seed = self:getServerByHashAndRr(ch, rid, len)
      else
        server, seed = self:getServerByHashAndRr(ch, rid, len, seed)
      end
      if not server then
        ngx.log(ngx.ERR, 'get big channel server fail, server: ', server, ' seed:', seed)
      else
        ok = self:setPeer(server)
        if not ok then
          Shared:delCh(ch, server)
        end
      end
    end
    retryTimes = retryTimes - 1
  until(retryTimes <= 0 or ok)
  
  if retryTimes <= 0 and ok == false then
      return ngx.exit(500)
  else
      ngx.log(ngx.ERR, 'success set peer, server: ', server, ' rid:', rid, ' size:', size)
  end
end

-- httpchat、gate一般动态反代
function _M:upstreamSimple(shareDict)
  local retryTimes, ok, server, seed = Constants.RETRY_TIMES.SELECT_BALANCER, false, nil, nil
  local servers = shareDict:get_keys()
  local len = #servers
 
  if len == 0 then 
    ngx.log(ngx.ERR, 'no server in shared')
    return ngx.exit(500)
  end

  repeat
    if not seed then
      math.randomseed(ngx.time())
      seed = math.random(len)
      -- seed = ngx.crc32_long(ngx.var.remote_addr) % len + 1
      server = servers[seed]
    else
      seed = seed % len + 1
      server = servers[seed]
    end
    if not server then
      ngx.log(ngx.ERR, 'get random server failed, server: ', server, ' seed:', seed)
    else
      ok = self:setPeer(server)
      if not ok then
        shareDict:delete(server)
      end
    end
    retryTimes = retryTimes - 1
  until(retryTimes <= 0 or ok)

  if retryTimes <= 0 and ok == false then
    return ngx.exit(500)
  else
      ngx.log(ngx.ERR, 'success set peer, server: ', server)
  end
end

return _M