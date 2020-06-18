-- local Cjson = require('cjson')
-- local Conf = require('utils.config')
-- local Shared = require('shared.manager')
-- local Constants = require('utils.constants')

-- -- 初始化反代上游信息
-- local host = Conf.HTTP_SEED.HOST
-- local port = Conf.HTTP_SEED.PORT
-- local path = Conf.POMELO_REQ_PATH.GET_UPSTREAM

-- local cmd = "curl " .. host .. ":" .. port .. path
-- local f = io.popen(cmd)

-- if f == nil then
--   ngx.log(ngx.ERR, 'init_shared fail')
-- else
--   local content = f:read("*a");
--   f:close()
--   content = Cjson.decode(content)
--   ngx.log(ngx.ERR, 'init_shared, curl ret :', Cjson.encode(content))  -- 先解再序列化仅仅因为格式，可提前
--   Shared:updateAll(content)
-- end