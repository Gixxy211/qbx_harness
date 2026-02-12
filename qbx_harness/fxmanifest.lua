fx_version 'cerulean'
game 'gta5'

name "np Harness"
author "np Development"
version "1.1"

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'locales/*.lua',
    'shared/*.lua',
}

client_scripts {
    'client/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua',
}
