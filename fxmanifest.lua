fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Ferp'
description 'Group Management App for FD Laptop'
version '1.0.0'

ui_page 'web/dist/index.html'

clidependencies {
    'fd_laptop',
    'ox_lib',
    'qbx_core',
    -- 'qb-core' -- Uncomment if using QBCore
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

files {
    'web/dist/index.html',
    'web/dist/**/*',
}
