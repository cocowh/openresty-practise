local Base = require('balancer.base')


local upstream_ch2 = ngx.shared.upstream_ch2
local size = ngx.ctx.size
local rid = ngx.ctx.rid

Base:upstreamCh(upstream_ch2, size, rid)