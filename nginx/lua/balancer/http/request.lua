local Zhttp = require('resty.http') 
local Constants = require('utils.constants')
local Cjson = require('cjson')

local _M = {}

-- get request
function _M.get(host, port, path)
  local respBody = {}

  local httpc = Zhttp.new()
  httpc:set_timeout(Constants.TIME.POMELO_REQ_TIMEOUT)
  httpc:connect(host, port)

  local resp, err = httpc:request{
    path = path,
    headers = {
      ["Expect"] = "100-continue",
      ["Content-Type"] = "application/x-www-form-urlencoded",
    }
  }

  if not resp then
    ngx.log(ngx.ERR,'request ', path, ' err: ', err, ' host: ', host, ' port:', port)
  else
    respBody = Cjson.decode(resp:read_body())
    ngx.log(ngx.ERR,'request: ', path, ' status: ', resp.status)
  end

  httpc:close()
  return respBody, err
end

return _M