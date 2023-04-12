local Base = require('balancer.base')


local upstream_ch1 = ngx.shared.upstream_ch1
local size = ngx.ctx.size
local rid = ngx.ctx.rid

Base:upstreamCh(upstream_ch1, size, rid)

