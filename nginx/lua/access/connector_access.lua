local Base = require('balancer.base')

local Shared = require('shared.manager')
local PomeloMysql = require('mysql.pomelo')
local Util = require('utils.util')
local Cjson = require('cjson')

local size,rid = Base:getChannelSizeByRid()

ngx.ctx.size = size
ngx.ctx.rid = rid