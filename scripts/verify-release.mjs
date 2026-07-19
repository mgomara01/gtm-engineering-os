import {execSync} from 'node:child_process';
const commands=['npm run typecheck','npm test','npm run build'];
for(const command of commands){console.log(`\n> ${command}`);execSync(command,{stdio:'inherit'});}console.log('\nRelease verification passed.');
