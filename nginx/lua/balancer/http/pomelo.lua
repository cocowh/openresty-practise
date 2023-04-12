local Conf = require("utils.config")
local Constants = require("utils.constants");
local Math = require('math')
local Util = require("utils.util")
local Request = require('http.request')

local upstream_http = ngx.shared.upstream_http

local _M = {}

-- 选择请求的ip+port
function _M.selectServer()
  local all = upstream_http:get_keys()
  local len = #all
  if len == 0 then -- 共享内存无则返回种子
    return Conf.HTTP_SEED.HOST, Conf.HTTP_SEED.PORT
  end
  Math.randomseed(ngx.time())
  local select = all[math.random(len)]
  local server = upstream_http:get(select)
  return Util.parseServer(server)
end

-- 请求上游服务信息
function _M:getUpstream()
  local retryTimes = Constants.RETRY_TIMES.POMELO_REQ;
  local host = Conf.HTTP_SEED.HOST
  local port = Conf.HTTP_SEED.PORT
  local path = Conf.POMELO_REQ_PATH.GET_UPSTREAM

  repeat
    local body, err = Request.get(host, port, path);
    if err == nil then
      return body
    end

    upstream_http:delete(host .. ":" .. port)
    host, port = self.selectServer()
    retryTimes = retryTimes - 1
  until(retryTimes <= 0)

  ngx.log(ngx.ERR, 'request getUpstream failed more than ', retryTimes)
  return {}
end

return _M