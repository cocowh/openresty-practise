local _M = {
  SERVER_TYPE = {  -- 服务类型
    HTTP_CHAT = 'http',
    GATE  = 'gate',
    CONNECTOR_TUTOR = 'ch1',
    CONNECTOR_LEC = 'ch2',
    CONNECTOR_TEACHER = 'ch3',
  },
  RETRY_TIMES = { 
    SET_BALANCER = 2, -- 同一host:port反代重试次数
    SELECT_BALANCER = 2, -- 同一请求反代重试次数
    POMELO_REQ = 2, -- pomelo请求重试次数
  },
  TIME = {
    POMELO_REQ_TIMEOUT = 5000, -- pomelo请求超时时间 second
    TIMER_DELAY = 10, -- 定时器周期 second
    MYSQL_TIMEOUT = 2000, -- mysql连接超时时间
    CH_SIZE_EXPIRE = 86400, -- 频道类型的过期时间，day
  },
  COUNT = {
    PULL_NUM = 50, -- 每一次mysql拉取的条数
    SERVER_GROUP = 5, -- 每一组connector的数目
  },
  CHANNEL_SIZE = { -- 频道大小
    SMALL = 1,
    MIDDLE = 2,
    BIG = 3,
  },
  KEY_WORDS = {
    FREEIDS = 'freeIds',
  },
}

return _M