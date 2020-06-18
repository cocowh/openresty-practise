-- 根据环境解析配置

local env = os.getenv('NGINX_ENV')
local configFile = "config.config_"
if env == 'LOCAL' then
  configFile = configFile..'local' 
elseif env == "DEV" then
  configFile = configFile..'dev'
else
  configFile =configFile..'prod'
end

return require(configFile)
