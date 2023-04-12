local Constants = require('utils.constants')
local PomeloApi = require('http.pomelo')
local Shared = require('shared.manager')
local PomeloMysql = require('mysql.pomelo')
 
local delay = Constants.TIME.TIMER_DELAY

local function update() 
  -- 更新代理上游信息
  local pullUpstream = PomeloApi:getUpstream()
  Shared:updateAll(pullUpstream)
  -- 拉取频道大小
  local pullChannel = PomeloMysql:pullChannel()
  Shared:updateChannel(pullChannel)
end


if 0 == ngx.worker.id() then
    local ok,err = ngx.timer.every(delay, update)
    if not ok then
        ngx.log(ngx.ERR, "failed to create timer: ", err)
        return
    end
end