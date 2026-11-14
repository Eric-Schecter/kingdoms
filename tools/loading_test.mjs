import {readFileSync} from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
const html=readFileSync('tools/web_shell.html','utf8');
const code=html.match(/<script>\s*([\s\S]*?)<\/script>/)[1].replace('$GODOT_CONFIG',JSON.stringify({executable:'index',args:[]}));
const elements=Object.fromEntries(['canvas','play','progress','status','error','launch'].map(id=>[id,{hidden:id==='play',disabled:true,style:{},textContent:'',addEventListener(e,f){this[e]=f},removeAttribute(k){delete this[k]},remove(){this.removed=true},focus(){}}]));
let config,finish,starts=0;
class Engine {constructor(c){config=c} init(){return Promise.resolve()} preloadFile(){return new Promise(r=>finish=r)} async start(){starts++}}
vm.runInNewContext(code,{document:{getElementById:id=>elements[id]},Engine});
config.onProgress(25,100);assert.equal(elements.progress.value,25);assert.match(elements.status.textContent,/25%/);assert.equal(starts,0);
finish();await new Promise(r=>setImmediate(r));assert.equal(elements.play.disabled,false);
await elements.play.click();assert.equal(starts,1);assert.equal(elements.launch.removed,true);
console.log('LOADING PASS: actual byte progress, preloading gate, click-to-start');
