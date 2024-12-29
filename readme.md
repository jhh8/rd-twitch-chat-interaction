a script to convert twitch chat messages into various interactions with gameplay in real-time

this script prints chat messages from twitch into the in-game chat
also includes various commands like spawnhorde, spawnrandomalien, dropnuke, screenfreeze etc. which affect gameplay (twitch viewer spawns)
for full list of commands see ChatCommands_t in mapspawn.nut, to remove unwanted commands just comment one line out which initializes that command

configure the javascript to launch your dedicated server (srcds.exe) with needed launch options
tmi.js dependency is required https://tmijs.com/
mapspawn.nut goes into scripts/vscripts folder in your server, make sure you have sv_mapspawn_nut_exec 1 set or it wont run

the javascript appends twitch messages into a file called chat_messages located in save/vscripts folder on your server, which then gets parsed by mapspawn.nut to produce certain actions

big thanks to vq and banano for help with javascript

some footage https://www.twitch.tv/videos/2339131868
