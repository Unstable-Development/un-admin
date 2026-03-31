fx_version 'cerulean'
game 'gta5'

author 'un-admin'
description 'un-admin - Universal Admin Menu'
version '2.0.0'

ui_page 'html/index.html'

shared_scripts {
    'config.lua',
    'config/vehicles.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/images/*.png'
}

lua54 'yes'
