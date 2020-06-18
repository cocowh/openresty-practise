local Base = require('balancer.base')


local upstream_ch3 = ngx.shared.upstream_ch3
local size = ngx.ctx.size
local rid = ngx.ctx.rid

Base:upstreamCh(upstream_ch3, size, rid)