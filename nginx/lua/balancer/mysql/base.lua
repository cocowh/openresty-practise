local Mysql = require('resty.mysql')
local Cjson = require('cjson')
local Constants = require('utils.constants')

local _M = {}

function _M:new(config)
  local db, err = Mysql:new()
  if not db then
    ngx.log(ngx.ERR, "failed to instanticate mysql: ", err)
    return nil
  end
  
  db:set_timeout(Constants.TIME.MYSQL_TIMEOUT)
  
  local ok, err, errno, sqlstate = db:connect(config)
  if not ok then
    ngx.log(ngx.ERR, "failed to connect, err: ", err, " errno: ", errno, " sqlstate: ", sqlstate, " config: ", Cjson.encode(config))
    return nil
  end
  self.db = db
  return self
end

function _M:close()
  self.db:close()
end

function _M:queryBySql(sql)
  local res, err, errno, sqlstate = self.db:query(sql)
  if not res then
    ngx.log(ngx.ERR, "query bad result, err: ", err, " errno: ", errno, " sqlstate: ", sqlstate, " sql: ",sql)
    return {}
  end
  ngx.log(ngx.ERR, "query success, sqlstate: ", sqlstate, " sql: ", sql)
  return res
end

return _M