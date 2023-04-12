local Cjson = require('cjson')
local Base = require('mysql.base')
local Conf = require('utils.config')
local Constants = require('utils.constants')

local channelSize = ngx.shared.channel_size

local config = {
  host = Conf.MYSQL.HOST,
  port = Conf.MYSQL.PORT,
  database = Conf.MYSQL.DATABASE,
  user = Conf.MYSQL.USER,
  password = Conf.MYSQL.PASSWORD,
  max_package_size = 1024
}

local _M = {}

-- 初始化建立连接
function _M:new()
  local db = Base:new(config)
  if not db then
    ngx.log(ngx.ERR, "failed to instanticate mysql pomelo, config", Cjson.encode(config))
    return nil 
  end
  self.db = db
  return self
end

-- 拉取数据
function _M:pullChannel()
  if not self.db then
    self:new()
  end

  local id = channelSize:get('id')
  if id == nil then
    id = self:getOldestIdInThePastHour()
    channelSize:set('id', id)
  end
  
  local sqlStr = "sql example > " .. id .. " limit " .. Constants.COUNT.PULL_NUM
  local res = self.db:queryBySql(sqlStr)
  
  if #res ~= 0 then
    channelSize:set('id', res[#res].id)
  end

  self:close()
  return res
end

-- 获取过去1小时最近的id
function _M:getOldestIdInThePastHour()
  local currTime = ( ngx.time() - 3600 ) * 1000
  local sqlStr = "sql example" .. currTime .. " order by id desc limit 1"
  local res = self.db:queryBySql(sqlStr)
  if #res == 0 then
    return 0
  end
  return res[1].id
end

-- 通过channelId查找
function _M:findByChannelId(channelId)
  ngx.log(ngx.ERR, 'query start:', ngx.now())
  if channelId == nil then
    return {}
  end

  if not self.db then
    self:new()
  end

  local sqlStr = "sql example " .. "'" .. channelId .. "'"
  local res = self.db:queryBySql(sqlStr)

  self:close()
  ngx.log(ngx.ERR, 'query end:', ngx.now())
  return res
end


-- 关闭连接
function _M:close()
  self.db:close()
  self.db = nil
end

return _M