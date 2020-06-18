local Base = require('balancer.base')

local upstream_http = ngx.shared.upstream_http

Base:upstreamSimple(upstream_http)