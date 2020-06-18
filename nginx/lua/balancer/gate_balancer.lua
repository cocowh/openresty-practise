local Base = require('balancer.base')

local upstream_gate = ngx.shared.upstream_gate

Base:upstreamSimple(upstream_gate)