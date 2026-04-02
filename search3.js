const fs = require('fs');
const text = fs.readFileSync('BrainrotTycoon.rbxlx', 'utf-8');

const regex = /<Item class="LocalScript"[\s\S]*?<string name="Name">([^<]+)<\/string>/g;
let match;
while((match = regex.exec(text)) !== null) {
  console.log(match[1]);
}
