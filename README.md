# openresty-balancer

proxy for upstream server

## lua scripts

path: `./nginx/lua`

tree:

```
.
├── access                       // access 阶段
│   └── connector_access.lua
├── balancer                     // 反代&负载均衡策略
│   ├── base.lua
│   ├── ch1_balancer.lua
│   ├── ch2_balancer.lua
│   ├── ch3_balancer.lua
│   ├── gate_balancer.lua
│   └── http_balancer.lua
├── config                       // 配置文件
│   ├── config_dev.lua
│   ├── config_local.lua
│   └── config_prod.lua
├── http                         // http请求
│   ├── pomelo.lua
│   └── request.lua
├── init                         // 初始化阶段
│   ├── init_shared.lua
│   ├── init_worker.lua
│   └── shared.lua
├── mysql                        // mysql
│   ├── base.lua
│   └── pomelo.lua
├── shared                       // 操作共享内存
│   └── manager.lua
└── utils                        // 工具
    ├── config.lua
    ├── constants.lua
    └── util.lua
```

## how to run

* install the project under the  `/home/work/local` path  
* use root user under the install path to run  `./bin/openresty`

if you are a MacOS user, you shoud to install openresty in your mac, then use `ln -s` command to link `./nginx` as your install openrety nginx. 

you can compile and install the openresty in your local env as well, then copy `./nginx/lua/*` to your same path.