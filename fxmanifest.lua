fx_version 'cerulean'
game 'gta5'
version '0.0.1'

lua54 'yes'

client_scripts {
	'client/*.lua'
}

server_scripts {
	'server/*.lua',
}

files {
	'locales/*.json'
}

shared_script {
	'@ox_lib/init.lua',
}

ox_libs {
    'locale',
    'print',
    'table',
}