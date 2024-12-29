const fs = require('fs');

// path to save/vscripts folder in your asrd server
const logFilePath = 'D:/RDServer/asrdserver/reactivedrop/save/vscripts/chat_messages';

const tmi = require("tmi.js"); // dependencies...
const ChildProcess = require("child_process");

const { spawn } = require('child_process');

// dont mind this being called xonotic im lazy to rename variables
// path to srcds.exe and server launch options
// doesnt check for game updates so launch your server the normal way to update it
let xonotic = spawn("D:/RDServer/asrdserver/srcds", [
  '-console',
  '-nomessagebox',
  '-nocrashdialog',
  '-num_edicts', '8192',
  '-game', 'reactivedrop',
  '-heapsize', '512000',
  '-tickrate', '60',
  '-port', '27069',
  '-maxplayers', '32',
  '+map', 'lobby',
  '+exec', 'server.cfg'
], {
  cwd: "D:/RDServer/asrdserver/",
  stdio: 'inherit'
});

xonotic.on('error', (err) => {
  console.error(`Failed to start process: ${err.message}`);
});

const client = new tmi.Client({
channels: ['jhheight'] // replace with your Twatch name to link to your strims' chat
});
client.connect();
client.on("message", (channel, tags, message, self) => {
  if (self) return;

  const logMessage = `${tags['display-name']}\x1F${message}\n`;

fs.appendFile(logFilePath, logMessage, (err) => {
    if (err) {
      console.error("Error appending to file:", err);
    } else {
      console.log("Message appended to file.");
    }
  });
});

client.on("error", (err) => {
  console.error(`Twitch client error: ${err.message}`);
});

xonotic.on("close", () => {
process.exit();
});