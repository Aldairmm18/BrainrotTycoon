const fs = require('fs');
const text = fs.readFileSync('BrainrotTycoon.rbxlx', 'utf-8');

// match all scripts
const scripts = text.split('<Item class="Script"');
scripts.forEach((str, i) => {
    if(i === 0) return;
    const nameMatch = str.match(/<string name="Name">([^<]+)<\/string>/);
    const sourceMatch = str.match(/<string name="Source"><!\[CDATA\[([\s\S]*?)\]\]><\/string>/);
    
    if (nameMatch && sourceMatch) {
        const name = nameMatch[1];
        const sys = sourceMatch[1];
        if (sys.includes("WalkSpeed") || sys.includes("JumpPower") || sys.toLowerCase().includes("speed") || sys.includes('SAB')) {
            console.log("Found in script (Server):", name);
            console.log(sys.substring(0, 200).split('\n').map(l => '  ' + l).join('\n'));
        }
    }
});

const localScripts = text.split('<Item class="LocalScript"');
localScripts.forEach((str, i) => {
    if(i === 0) return;
    const nameMatch = str.match(/<string name="Name">([^<]+)<\/string>/);
    const sourceMatch = str.match(/<string name="Source"><!\[CDATA\[([\s\S]*?)\]\]><\/string>/);
    
    if (nameMatch && sourceMatch) {
        const name = nameMatch[1];
        const sys = sourceMatch[1];
        if (sys.includes("WalkSpeed") || sys.includes("JumpPower") || sys.toLowerCase().includes("speed") || sys.includes('SAB')) {
            console.log("Found in script (Client):", name);
            console.log(sys.substring(0, 200).split('\n').map(l => '  ' + l).join('\n'));
        }
    }
});
