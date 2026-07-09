const cv=document.getElementById('cv');
const ctx=cv.getContext('2d');
ctx.imageSmoothingEnabled=false;

const CW=660,CH=500,S=3;
cv.width=CW;cv.height=CH;

const NS_BASE=['Lily C.','Pearl J.','Mia K.','Kai R.','Zoe T.','Maria L.','Boba B.','Taro S.','Max M.','Anna P.','Frank D.','Rosa N.','Eddie W.','Matcha O.'];

/* ===== REGULARS SYSTEM =====
   A regular is a named customer who has visited 3+ times. They have a
   favourite drink, a consistent look, and give bonus tips. Each regular
   is stored in G.regulars keyed by name. Fields:
     visits      – lifetime visit count
     favId       – item id of their favourite drink (most ordered)
     orders      – map of {itemId: count} to track favourite
     skinCol, shirtCol, hairCol – consistent appearance
     tipBonus    – extra tip multiplier (starts at 1.1, grows with visits)
   A regular spawning gets a greeting log line and a small tip bonus.
   After 10 visits they become a VIP (★) with bigger bonuses.
   Regulars only form from the current world's menu so their fav always
   exists; when the world changes their visit count is kept but favId is
   cleared so a new favourite forms naturally. */
const REGULAR_THRESHOLD = 3;   // visits before someone is a "regular"
const REGULAR_SPAWN_CHANCE = 0.35; // 35 % chance a seat is filled by a regular (if any exist)

/* Greetings shown in the log when a known regular walks in */
const REGULAR_GREETINGS = [
  n=>`${n} is back! They're basically family. 🧋`,
  n=>`${n} slides into their usual spot. ✨`,
  n=>`Look who it is — ${n}! ☀`,
  n=>`${n} walks in without even checking the menu. 👀`,
  n=>`${n} again! They never miss a day. 🌟`,
];
const VIP_GREETINGS = [
  n=>`★ VIP alert — ${n} is here! ★`,
  n=>`${n} the legend has arrived. 👑`,
  n=>`Everyone looks up as ${n} walks in. ✨`,
];

/* Level 1 – Classic Boba Stand */
const BISTRO_MENU_DAY=[
  {id:'classicpearl', nm:'Classic Pearl Tea',  em:'🧋',price:5, time:3000,rep:2},
  {id:'brownsugarlatte',nm:'Brown Sugar Latte', em:'🍵',price:7, time:3500,rep:2},
  {id:'taromilk',    nm:'Taro Milk Tea',        em:'🫧',price:8, time:4000,rep:3},
  {id:'matchalatte', nm:'Matcha Latte',          em:'🍵',price:6, time:3000,rep:2},
  {id:'strawberry',  nm:'Strawberry Milk',       em:'🍓',price:6, time:2500,rep:1},
  {id:'tigermilk',   nm:'Tiger Milk Tea',        em:'🧋',price:9, time:4500,rep:4},
];

/* Level 2 – Pixel Tea Shop */
const WOK_MENU_DAY=[
  {id:'passionfruit', nm:'Passion Fruit Tea', em:'🍹',price:8, time:3500,rep:2},
  {id:'honeydew',     nm:'Honeydew Slush',    em:'🍈',price:7, time:3000,rep:2},
  {id:'lychee',       nm:'Lychee Sparkle',    em:'🫧',price:9, time:4000,rep:2},
  {id:'thaitea',      nm:'Thai Milk Tea',     em:'🍵',price:10,time:4500,rep:3},
  {id:'coconut',      nm:'Coconut Panda',     em:'🥥',price:9, time:4000,rep:3},
  {id:'mango',        nm:'Mango Smoothie',    em:'🥭',price:8, time:3500,rep:3},
];

/* Level 3 – Pixel Bubble Bar */
const TAQ_MENU_DAY=[
  {id:'cheesetea',    nm:'Cheese Tea',         em:'🍵',price:10,time:4000,rep:2},
  {id:'yakult',       nm:'Yakult Fruit Tea',   em:'🍶',price:8, time:3500,rep:2},
  {id:'saltedmatcha', nm:'Salted Cream Matcha',em:'🍵',price:12,time:5000,rep:3},
  {id:'oolong',       nm:'Oolong Pearl Tea',   em:'🧋',price:10,time:4000,rep:2},
  {id:'roselychee',   nm:'Rose Lychee Tea',    em:'🌸',price:11,time:4500,rep:3},
  {id:'peachoolong',  nm:'Peach Oolong',       em:'🍑',price:9, time:3500,rep:3},
];

/* Level 4 – Pixel Matcha Lounge */
const SUSHI_MENU_DAY=[
  {id:'ceremonial',   nm:'Ceremonial Matcha',  em:'🍵',price:12,time:5000,rep:3},
  {id:'hojicha',      nm:'Hojicha Latte',      em:'🍵',price:11,time:4500,rep:3},
  {id:'kuromitsu',    nm:'Kuromitsu Boba',     em:'🧋',price:13,time:5500,rep:3},
  {id:'jasminepearl', nm:'Jasmine Pearl Tea',  em:'🌸',price:10,time:4000,rep:2},
  {id:'lavender',     nm:'Lavender Milk Tea',  em:'💜',price:12,time:5000,rep:3},
  {id:'pandan',       nm:'Pandan Layer Boba',  em:'🫧',price:8, time:3000,rep:2},
];

/* Level 5 – Pixel Boba Café */
const PIZZA_MENU_DAY=[
  {id:'affogato',     nm:'Affogato Boba',      em:'☕',price:13,time:5500,rep:3},
  {id:'tiramisu',     nm:'Tiramisu Milk Tea',  em:'🍮',price:14,time:5000,rep:3},
  {id:'pistachio',    nm:'Pistachio Latte',    em:'🌿',price:12,time:4500,rep:3},
  {id:'rosepetal',    nm:'Rose Petal Milk Tea',em:'🌹',price:11,time:4000,rep:2},
  {id:'espresso',     nm:'Espresso Boba',      em:'☕',price:10,time:3500,rep:2},
  {id:'vanillacream', nm:'Vanilla Cream Boba', em:'🧋',price:12,time:4500,rep:4},
];

/* Level 6 – Pixel Pearl Palace */
const CURRY_MENU_DAY=[
  {id:'saffron',      nm:'Saffron Milk Tea',   em:'🍵',price:16,time:5500,rep:3},
  {id:'masalachai',   nm:'Masala Chai Boba',   em:'🧋',price:14,time:6000,rep:3},
  {id:'cardamom',     nm:'Cardamom Latte',     em:'☕',price:11,time:4000,rep:2},
  {id:'turmericgold', nm:'Turmeric Gold Latte',em:'🌟',price:12,time:4500,rep:3},
  {id:'roselassi',    nm:'Rose Lassi Boba',    em:'🌸',price:13,time:5000,rep:3},
  {id:'paanpearl',    nm:'Paan Pearl Tea',     em:'🫧',price:15,time:5500,rep:4},
];

/* Level 7 – Pixel Boba Cart */
const TRUCK_MENU_DAY=[
  {id:'streetpearl',  nm:'Street Pearl Tea',   em:'🧋',price:6, time:3000,rep:2},
  {id:'brownsugar2',  nm:'Brown Sugar Fresh',  em:'🍵',price:8, time:3500,rep:2},
  {id:'fruitslush',   nm:'Fruit Slush',        em:'🍹',price:7, time:2500,rep:2},
  {id:'taroslush',    nm:'Taro Slush',         em:'🫧',price:9, time:4000,rep:3},
  {id:'mangoblast',   nm:'Mango Blast',        em:'🥭',price:8, time:3000,rep:2},
  {id:'grassjelly',   nm:'Grass Jelly Boba',   em:'🧋',price:7, time:3000,rep:3},
];



/* ===== WORLDS =====
   Each entry is a full boba shop "level". When the player's money hits
   `threshold`, they're offered the next world — money, upgrades and staff
   all carry over, only the menu, customers and decor change. */
const WORLDS=[
  {
    id:'bobastand',name:'Pixel Boba Stand',icon:'🧋',threshold:Infinity,
    menuDay:BISTRO_MENU_DAY,
    customers:NS_BASE,
    colors:{
      wall:'#2a1a28',wallAlt:'#241620',trim:'#f7a8d0',accent:'#8b3a6b',
      window:'#180e18',windowGl:'#f2c4e8',
      table:'#3a2038',tableTop:'#4a2c48',chair:'#241828',cloth:'#f7a8d0',
      floor1:'#221628',floor2:'#2c1e34',
      stove:'#2e1a2c',dark:'#160e18',dot:'#0e0810'
    }
  },
];

let MENU_ALL,NS,MENU_IDX,PAL=WORLDS[0].colors;
function applyWorld(idx){
  const w=WORLDS[idx];
  MENU_ALL=w.menuDay;
  NS=w.customers;
  MENU_IDX={};
  MENU_ALL.forEach(m=>MENU_IDX[m.id]=m);
  PAL=w.colors;
  const titleEl=document.getElementById('worldTitle');
  if(titleEl)titleEl.textContent=`${w.icon} ${w.name.toUpperCase()} ${w.icon}`;
  const kL=document.getElementById('kitchenLabel'),dL=document.getElementById('diningLabel'),rL=document.getElementById('readyLabel');
  if(kL)kL.textContent=w.truckScroll?'CART STATION':'BREW STATION';
  if(dL)dL.textContent=w.truckScroll?'QUEUE':'SEATING AREA';
  if(rL)rL.textContent='READY TO SERVE';
}

/* Each upgrade has an unlockWorld tier — 0 means available from the start,
   1 means it only becomes purchasable once the player reaches the second
   world (Pixel Wok), etc. This is how "the better the world, the more
   upgrades you get" works: every new world appends a fresh, stronger tier
   on top of the previous ones (which stay bought/active forever). Each
   tier has 5 categories: cook speed (cookMult), customer arrival speed
   (spawnSecs), day tips, night tips, and table turnover speed (eatMult).
   To add upgrades for a future world, add entries with a new unlockWorld
   and reference them in the matching function below. */
const UPGRADES={
  sign:{nm:'Chalkboard Menu Sign',  cost:40, ds:'Customers arrive faster',                                         done:false,unlockWorld:0},
  seat:{nm:'Extra Seating',         cost:60, ds:'2 more seats for guests',                                         done:false,unlockWorld:0},
  seat2:{nm:'Outdoor Patio',        cost:550,ds:'2 more seats — now you\'re using that pavement',                  done:false,unlockWorld:1},
  oven:{nm:'Faster Pearl Cooker',   cost:80, ds:'Brew drinks 50% faster',                                          done:false,unlockWorld:0},
  tipjar:{nm:'Tip Jar',             cost:70, ds:'+15% more day session tips',                                      done:false,unlockWorld:0},
  quickbite:{nm:'Wide Straw Upgrade',cost:90,ds:'Customers sip 20% faster, freeing seats sooner',                 done:false,unlockWorld:0},
  menu:{nm:'Extended Menu',         cost:100,ds:'Unlock the last 3 drinks',                                        done:false,unlockWorld:0},
  wokburner:{nm:'Pro Tea Brewer',   cost:300,ds:'Brew another 25% faster (stacks with Pearl Cooker)',              done:false,unlockWorld:1},
  scooter:{nm:'Delivery Scooter',   cost:280,ds:'Customers arrive even faster (stacks with Chalkboard Sign)',      done:false,unlockWorld:1},
  dailyspecial:{nm:'Daily Specials Board',cost:320,ds:'+15% more day tips (stacks with Tip Jar)',                  done:false,unlockWorld:1},
  bamboobaskets:{nm:'Eco Cup Sleeves',cost:330,ds:'Customers sip 15% faster (stacks with previous)',               done:false,unlockWorld:1},
  molcajete:{nm:'Ultrasonic Frother',cost:450,ds:'Brew another 20% faster (stacks with previous)',                 done:false,unlockWorld:2},
  foodtruck:{nm:'TikTok Promo',     cost:420,ds:'Customers arrive even faster (stacks with previous)',             done:false,unlockWorld:2},
  comboplate:{nm:'Combo Deal Board',cost:470,ds:'+12% more day tips (stacks with previous)',                       done:false,unlockWorld:2},
  salsabar:{nm:'Self-Serve Topping Bar',cost:460,ds:'Customers sip 15% faster (stacks with previous)',            done:false,unlockWorld:2},
  robatagrill:{nm:'Nitrogen Infuser',cost:650,ds:'Brew another 15% faster (stacks with previous)',                 done:false,unlockWorld:3},
  bikecourier:{nm:'Bike Courier Network',cost:600,ds:'Customers arrive at max speed (stacks with previous)',       done:false,unlockWorld:3},
  omakase:{nm:'Seasonal Tasting Menu',cost:680,ds:'+15% more day tips (stacks with previous)',                     done:false,unlockWorld:3},
  conveyorbelt:{nm:'Conveyor Cup Pickup',cost:670,ds:'Customers sip 15% faster (stacks with previous)',            done:false,unlockWorld:3},
  woodfiredoven:{nm:'Cold Brew System',cost:900,ds:'Brew another 20% faster (stacks with previous)',               done:false,unlockWorld:4},
  vespascooter:{nm:'Vespa Delivery Fleet',cost:850,ds:'Customers arrive even faster (stacks with previous)',       done:false,unlockWorld:4},
  garlicknot:{nm:'Loyalty Points App',cost:950,ds:'+12% more day tips (stacks with previous)',                     done:false,unlockWorld:4},
  quickslice:{nm:'Express Counter',  cost:930,ds:'Customers sip 15% faster (stacks with previous)',                done:false,unlockWorld:4},
  tandoor:{nm:'Smart Brewer 3000',  cost:1200,ds:'Brew another 25% faster (stacks with previous)',                 done:false,unlockWorld:5},
  rickshaw:{nm:'Rickshaw Delivery', cost:1100,ds:'Customers swarm at record pace (stacks with previous)',           done:false,unlockWorld:5},
  thali:{nm:'Premium Bundle Pack',  cost:1250,ds:'+15% more day tips (stacks with previous)',                      done:false,unlockWorld:5},
  tiffinservice:{nm:'Drive-Thru Window',cost:1230,ds:'Customers sip 15% faster (stacks with previous)',            done:false,unlockWorld:5},
  generator:{nm:'Turbo Brew Station',cost:1500,ds:'Brew another 30% faster (stacks with previous)',                done:false,unlockWorld:6},
  megaphone:{nm:'Viral Social Media',cost:1400,ds:'Customers come at record pace (stacks with previous)',           done:false,unlockWorld:6},
  punchcard:{nm:'Stamp Card Rewards',cost:1550,ds:'+15% more day tips (stacks with previous)',                     done:false,unlockWorld:6},
  grabandgo:{nm:'Grab-and-Go Handles',cost:1520,ds:'Customers sip 15% faster (stacks with previous)',              done:false,unlockWorld:6},
};

const STAFF={
  cook:{nm:'Hire Barista',        cost:150,ds:'Auto-brews drinks as customers arrive',                            done:false,unlockWorld:0},
  cook2:{nm:'Promote to Head Barista',cost:500,ds:'Brewing staff works 20% faster (stacks with brew upgrades)',   done:false,unlockWorld:1,requires:'cook'},
  cook3:{nm:'Hire Boba Master',   cost:1400,ds:'Brewing staff works another 25% faster (stacks with previous)',   done:false,unlockWorld:3,requires:'cook2'},
  waiter:{nm:'Hire Server',       cost:150,ds:'Auto-delivers ready drinks to customers',                          done:false,unlockWorld:0},
  waiter2:{nm:'Promote to Lead Server',cost:500,ds:'Seats turn over 15% faster (stacks with sip upgrades)',      done:false,unlockWorld:1,requires:'waiter'},
  waiter3:{nm:'Hire Floor Manager',cost:1400,ds:'Seats turn over another 15% faster (stacks with previous)',     done:false,unlockWorld:3,requires:'waiter2'},
};

const SKIN_COLS=['#f5c5a3','#e8a87c','#c68642','#8d5524','#f8d5b0','#d4956a'];
const SHIRT_COLS=['#c0392b','#2980b9','#27ae60','#8e44ad','#e67e22','#16a085'];
const HAIR_COLS=['#2c1a0e','#5c3d1e','#f0c040','#c0392b','#1a1a1a','#7d5a3c'];

function tableCount(){
  const base=UPGRADES.seat2.done?9:UPGRADES.seat.done?7:5;
  if(WORLDS[G.worldIdx]&&WORLDS[G.worldIdx].truckScroll)return base+4;
  return base;
}
function activeMenu(){
  return UPGRADES.menu.done?MENU_ALL:MENU_ALL.slice(0,3);
}
function cookMult(){
  let m=1;
  if(UPGRADES.oven.done)m*=1.5;
  if(UPGRADES.wokburner.done)m*=1.25;
  if(UPGRADES.molcajete.done)m*=1.2;
  if(UPGRADES.robatagrill.done)m*=1.15;
  if(UPGRADES.woodfiredoven.done)m*=1.2;
  if(UPGRADES.tandoor.done)m*=1.25;
  if(UPGRADES.generator.done)m*=1.3;
  if(STAFF.cook2.done)m*=1.2;
  if(STAFF.cook3.done)m*=1.25;
  return m;
}
function spawnSecs(){
  let secs=UPGRADES.sign.done?5:9;
  if(UPGRADES.scooter.done)secs=Math.max(2,secs-2);
  if(UPGRADES.foodtruck.done)secs=Math.max(2,secs-1);
  if(UPGRADES.bikecourier.done)secs=Math.max(1.2,secs-1);
  if(UPGRADES.vespascooter.done)secs=Math.max(0.9,secs-0.5);
  if(UPGRADES.rickshaw.done)secs=Math.max(0.6,secs-0.4);
  if(UPGRADES.megaphone.done)secs=Math.max(0.4,secs-0.3);
  if(Math.round(G.rep)>=5)secs=Math.max(0.3,secs-0.5);
  return secs;
}
/* Lowers how long a served customer lingers at the table before leaving,
   so the spot frees up for the next person sooner. */
function eatMult(){
  let m=1;
  if(UPGRADES.quickbite.done)m*=0.8;
  if(UPGRADES.bamboobaskets.done)m*=0.85;
  if(UPGRADES.salsabar.done)m*=0.85;
  if(UPGRADES.conveyorbelt.done)m*=0.85;
  if(UPGRADES.quickslice.done)m*=0.85;
  if(UPGRADES.tiffinservice.done)m*=0.85;
  if(UPGRADES.grabandgo.done)m*=0.85;
  if(STAFF.waiter2.done)m*=0.85;
  if(STAFF.waiter3.done)m*=0.85;
  return Math.max(0.25,m);
}
/* Reputation now has real teeth: the star rating shown in the REPUTATION
   tile scales a global earnings multiplier (matches the stars exactly,
   so it's easy to read at a glance), and a full 5-star rating also
   brings in customers a little faster — word of mouth. */
function repMult(){
  const r=Math.round(G.rep);
  if(r<=1)return 0.85;
  if(r===2)return 0.95;
  if(r===3)return 1.0;
  if(r===4)return 1.1;
  return 1.25; // 5 stars
}

const G={
  money:50,day:1,tm:8*60,open:true,rep:3,served:0,ds:0,spd:1,
  totalEarned:0,prestige:0,
  regulars:{}, // keyed by customer name → {visits,favId,orders:{},skinCol,shirtCol,hairCol,tipBonus}
  hotelMode:false,puddles:[],cleanAnim:0,closingWarnShown:false,closingFade:0,
  cookSlots:[],ready:[],held:null,
  tables:[],sprites:[],assistants:[],
  worldIdx:0,worldTransitionPending:false,
  truckWaveServed:0,
  earnRateEWMA:0,lastEarnTs:null,
  lT:Date.now(),cT:0,spawnCooldown:false,
  cat:{x:20,y:45,tx:20,ty:45,dir:1,idleMs:0,walkMs:0,state:'idle'} // wandering shop cat
};

function initTables(){
  const n=tableCount();
  const positions=tablePositions(n);
  while(G.tables.length<n){
    const i=G.tables.length;
    G.tables.push({idx:i,state:'empty',custNm:'',order:null,eatMs:0,maxEatMs:0,autoCooking:false,
      px:positions[i].x,py:positions[i].y,skinCol:'#f5c5a3',shirtCol:'#c0392b',hairCol:'#2c1a0e'});
  }
  if(G.tables.length>n)G.tables.length=n;
  G.tables.forEach((t,i)=>{t.px=positions[i].x;t.py=positions[i].y;});
}

function tablePositions(n){
  // The original pixel art (kitchen wall, truck, queue) was hand-tuned for a
  // 220x60 grid (roadY=33). Since the canvas can now be taller, everything
  // below gets shifted down by the same amount the grid grew, so the scene
  // stays anchored to the floor/road instead of floating near the old size.
  const gh=Math.ceil(CH/S);
  const extra=gh-60;
  if(WORLDS[G.worldIdx]&&WORLDS[G.worldIdx].truckScroll){
    // single-file line of customers in front of the truck's service window
    const roadY=Math.floor(gh*0.55);
    const shift=roadY-33;
    const positions=[];
    const startX=84,gap=16;
    for(let i=0;i<n;i++){
      positions.push({x:startX+i*gap,y:18+shift+(i%2)*5});
    }
    return positions;
  }
  const positions=[];
  const cols=Math.min(n,5);
  const gw=Math.ceil(CW/S);
  const diningTopY=34,diningBotY=Math.round(gh*0.75);
  const diningZoneH=diningBotY-diningTopY;
  const colW=Math.floor(gw/cols);
  for(let i=0;i<n;i++){
    const col=i%cols,row=Math.floor(i/cols);
    positions.push({
      x:Math.round(colW*col+colW/2)-8,
      y:diningTopY+Math.round(row*(diningZoneH*0.55))+4
    });
  }
  return positions;
}

function px(x,y,w,h,col){
  ctx.fillStyle=col;
  ctx.fillRect(x*S,y*S,w*S,h*S);
}

let truckScrollX=0;

function drawFloor(){
  const gw=Math.ceil(CW/S),gh=Math.ceil(CH/S);
  if(WORLDS[G.worldIdx]&&WORLDS[G.worldIdx].truckScroll){
    // Draw scrolling road
    const roadY=Math.floor(gh*0.55);
    const roadH=gh-roadY;
    // Asphalt base
    for(let y=roadY;y<gh;y++)for(let x=0;x<gw;x++)px(x,y,1,1,'#2a2a2a');
    // Road markings — dashed center line scrolling
    const dashW=6,gapW=4,totalW=dashW+gapW;
    const offset=Math.floor(truckScrollX/S)%totalW;
    const lineY=roadY+Math.floor(roadH/2);
    for(let x=-totalW;x<gw+totalW;x++){
      const xOff=(x+offset+totalW*10)%totalW;
      if(xOff<dashW)px(x,lineY,1,1,'#ffe135');
    }
    // Kerb lines
    for(let x=0;x<gw;x++){px(x,roadY,1,1,'#ffffff');px(x,gh-1,1,1,'#ffffff');}
    // Sidewalk above road
    const c1=PAL.floor1;
    const c2=PAL.floor2;
    for(let y=0;y<roadY;y++)for(let x=0;x<gw;x++)
      px(x,y,1,1,(x+y)%2===0?c1:c2);
  } else {
    const c1=PAL.floor1;
    const c2=PAL.floor2;
    // Modern large-format floor tiles (8x8 grid cells) with grout lines
    const tileW=8, tileH=6;
    const grout=PAL.dark;
    for(let y=0;y<gh;y++){
      for(let x=0;x<gw;x++){
        const onGroutX=(x%tileW===0);
        const onGroutY=(y%tileH===0);
        if(onGroutX||onGroutY){
          px(x,y,1,1,grout);
        } else {
          // Subtle two-tone tile variation
          const tileCol=Math.floor(x/tileW)+Math.floor(y/tileH);
          px(x,y,1,1,tileCol%2===0?c1:c2);
        }
      }
    }
  }
}

// Lerp between two hex colours — returns a hex string
function lerpCol(a,b,t){
  const ah=parseInt(a.slice(1),16),bh=parseInt(b.slice(1),16);
  const ar=(ah>>16)&0xff,ag=(ah>>8)&0xff,ab2=ah&0xff;
  const br=(bh>>16)&0xff,bg=(bh>>8)&0xff,bb2=bh&0xff;
  const r=Math.round(ar+(br-ar)*t),g=Math.round(ag+(bg-ag)*t),b2=Math.round(ab2+(bb2-ab2)*t);
  return'#'+((1<<24)|(r<<16)|(g<<8)|b2).toString(16).slice(1);
}

// Sky colours keyed to hour of day (8 AM → 21 PM maps to 0→1)
function skyColour(t){
  // stops: dawn(0) → morning(.15) → midday(.4) → afternoon(.65) → dusk(.85) → night(1)
  const stops=[
    [0,    '#1a0e28','#3a1a40'], // 8 AM – dawn purple
    [0.15, '#e8803a','#f0b060'], // 9:30 AM – warm orange sunrise
    [0.35, '#5090d8','#80b8f0'], // noon-ish – bright blue
    [0.60, '#3a70c0','#70a0e8'], // 3 PM – slightly deeper blue
    [0.80, '#e06030','#f09050'], // 6 PM – golden dusk
    [0.90, '#301840','#4a2060'], // 7:30 PM – twilight purple
    [1.00, '#0a0816','#1a1030'], // 9 PM – deep night
  ];
  for(let i=1;i<stops.length;i++){
    if(t<=stops[i][0]){
      const seg=(t-stops[i-1][0])/(stops[i][0]-stops[i-1][0]);
      return{top:lerpCol(stops[i-1][1],stops[i][1],seg),bot:lerpCol(stops[i-1][2],stops[i][2],seg)};
    }
  }
  return{top:stops[stops.length-1][1],bot:stops[stops.length-1][2]};
}

function drawWall(frame){
  const gw=Math.ceil(CW/S);
  const wallH=7;

  // Time of day: G.tm in minutes, open 8*60→21*60
  const dayT=G&&G.tm!=null?Math.max(0,Math.min(1,(G.tm-8*60)/(21*60-8*60))):0.3;
  const sky=skyColour(dayT);
  const isNight=dayT>0.85;
  const isDusk=(dayT>0.72&&dayT<=0.92);
  const isDawn=(dayT<0.18);

  // Base wall fill
  for(let x=0;x<gw;x++)px(x,0,1,wallH,PAL.wall);

  // Wainscoting panel
  const panelTop=4, panelH=2;
  for(let x=0;x<gw;x++)px(x,panelTop,1,panelH,PAL.dark);
  for(let x=0;x<gw;x++)px(x,panelTop,1,1,PAL.trim);
  for(let p=8;p<gw;p+=18) px(p,panelTop+1,1,panelH-1,PAL.wallAlt);

  // (windows drawn after kitchen/chillroom — see drawWindows)
  // ── NEON SIGN ─────────────────────────────────────────────────────────
  // Mounted BELOW the wall strip, visible in the dining room.
  // Position: hanging at y=8..17 (10 grid rows = 30px), centred x=55..90
  // Big enough to read clearly, always on, glows brighter at night.

  const flickerCycle=Math.floor(frame)%97;
  const isFlicker=(flickerCycle===0||flickerCycle===1||flickerCycle===44);
  const signAlpha=isFlicker?0.12:Math.max(0.7,1-dayT*0.2);

  const neonCols=['#ff2299','#ff5533','#ffaa00','#00ccff','#ff3311','#ff8800','#00ff88','#ffdd00'];
  const neonCol=neonCols[G&&G.worldIdx!=null?G.worldIdx%neonCols.length:0];
  const dimCol=lerpCol('#111111',neonCol,signAlpha);
  const hotCol=lerpCol(neonCol,'#ffffff',isFlicker?0:0.55);

  // Sign frame: 36 wide x 10 tall, hanging at (54, 8)
  const sx=54,sy=8,sw=36,sh=10;

  // Mounting brackets (2 thin vertical lines above sign)
  px(sx+8, sy-2, 1, 2, PAL.wallAlt);
  px(sx+sw-9, sy-2, 1, 2, PAL.wallAlt);

  // Glow cloud behind sign
  const haloCol=lerpCol(PAL.floor1,neonCol,isFlicker?0.03:signAlpha*0.22);
  px(sx-2,sy-1,sw+4,sh+3,haloCol);

  // Dark sign backing
  px(sx,sy,sw,sh,lerpCol('#0a0a0a',PAL.dark,0.7));

  // Neon border tube
  for(let x=sx;x<sx+sw;x++){
    px(x,sy,1,1,dimCol); px(x,sy+sh-1,1,1,dimCol);
  }
  for(let y=sy;y<sy+sh;y++){
    px(sx,y,1,1,dimCol); px(sx+sw-1,y,1,1,dimCol);
  }
  // Corner brights
  for(const [cx2,cy2] of[[sx,sy],[sx+sw-1,sy],[sx,sy+sh-1],[sx+sw-1,sy+sh-1]])
    px(cx2,cy2,1,1,hotCol);

  // Pixel-art "OPEN" in a 5-tall font inside the sign
  // Each letter is 4px wide + 1px gap = 5px. 4 letters = 20px. Centre in sw-2=34.
  // Start at sx+7 so letters sit centred.
  const font5={
    O:[[0,1,1,0],[1,0,0,1],[1,0,0,1],[1,0,0,1],[0,1,1,0]],
    P:[[1,1,1,0],[1,0,0,1],[1,1,1,0],[1,0,0,0],[1,0,0,0]],
    E:[[1,1,1,1],[1,0,0,0],[1,1,1,0],[1,0,0,0],[1,1,1,1]],
    N:[[1,0,0,1],[1,1,0,1],[1,0,1,1],[1,0,0,1],[1,0,0,1]],
  };
  const ltBright=lerpCol('#000000',neonCol,signAlpha);
  const ltHot=lerpCol(neonCol,'#ffffff',isFlicker?0:0.45);
  let lx=sx+7;
  const ly=sy+2;
  for(const ch of['O','P','E','N']){
    const bm=font5[ch];
    for(let row=0;row<5;row++){
      for(let col=0;col<4;col++){
        if(bm[row][col]){
          px(lx+col, ly+row, 1, 1, (row===2&&col===1)?ltHot:ltBright);
        }
      }
    }
    lx+=5;
  }

  // Neon glow wash on floor below sign
  if(!isFlicker){
    const fw=lerpCol(PAL.floor1,neonCol,0.15*signAlpha);
    for(let fx=sx-3;fx<sx+sw+3;fx++) px(fx,sy+sh,1,2,fw);
  }

  // ── PLANTS & GREENERY ──────────────────────────────────────────────────
  // Drawn last so they sit on top of wall, windows, sign.
  // All Y coords are in grid pixels. wallH=7 = top of dining area.
  // Plants live in the dining room (y >= wallH) and along the wall face.

  const leafD2=lerpCol('#1a5c38',PAL.accent,0.12);
  const leafM2=lerpCol('#2a8050',PAL.accent,0.10);
  const leafH2=lerpCol('#44bb70',PAL.accent,0.08);
  const stemC2=lerpCol('#1a3a22',PAL.accent,0.15);
  const potC2='#8a5a30';
  const potDk2='#5a3010';
  const soil2='#3a2010';
  const cactusC2='#3a7a40';
  const cactusH2='#5aaa58';

  // 1. Big monstera floor plants — base at y=wallH+12, leaves reach up into dining area
  function drawMonstra2(ox,baseY){
    // pot sits at baseY+6..baseY+12
    px(ox+1,baseY+6,8,6,potC2);
    px(ox+1,baseY+6,8,1,lerpCol(potC2,'#fff',0.2));
    px(ox+2,baseY+8,6,4,soil2);
    px(ox+1,baseY+11,1,1,potDk2); px(ox+8,baseY+11,1,1,potDk2);
    // stem
    px(ox+4,baseY+1,2,6,stemC2);
    // centre leaf (tall, goes up from baseY-8 to baseY+1)
    px(ox+2,baseY-7,6,9,leafM2); px(ox+3,baseY-9,4,3,leafM2);
    px(ox+4,baseY-9,1,11,leafD2);
    px(ox+3,baseY-5,1,3,leafH2); px(ox+5,baseY-5,1,3,leafH2);
    // monstera splits
    px(ox+2,baseY-3,1,4,PAL.wall); px(ox+7,baseY-3,1,4,PAL.wall);
    // left leaf
    px(ox-4,baseY-3,7,6,leafM2); px(ox-5,baseY-2,3,4,leafM2);
    px(ox-3,baseY-3,1,5,leafD2); px(ox-2,baseY-2,1,2,leafH2);
    px(ox-4,baseY-1,1,3,PAL.wall);
    // right leaf
    px(ox+7,baseY-3,7,6,leafM2); px(ox+12,baseY-2,3,4,leafM2);
    px(ox+10,baseY-3,1,5,leafD2); px(ox+9,baseY-2,1,2,leafH2);
    px(ox+13,baseY-1,1,3,PAL.wall);
    // small lower leaf
    px(ox+2,baseY+2,5,4,leafD2); px(ox+3,baseY+3,2,2,leafH2);
  }
  // place at left and right of dining room, clear of tables
  drawMonstra2(1, wallH+14);
  drawMonstra2(gw-12, wallH+14);

  // 2. Hanging vines from wall face, between/beside windows — drawn on wall (y 0-wallH)
  function drawVine2(topX){
    for(let i=0;i<wallH+4;i++){
      if(i<wallH) px(topX,i,1,1,stemC2);
      // leaves alternate sides, skip inside window zones
      if(i%2===0&&i>=1){ px(topX-2,i,3,2,leafM2); px(topX-3,i+1,1,1,leafH2); }
      else if(i%2===1&&i>=2){ px(topX+1,i,3,2,leafD2); px(topX+3,i,1,1,leafM2); }
    }
  }
  // hang vines in gaps between windows (at x=20, 58, 95, 132)
  for(const vx of [20,58,95,132]){ if(vx<gw-4) drawVine2(vx); }

  // 3. Small ceramic pots with succulents on the sill of each window (y=wallH = sill)
  function drawSucculent2(sx2){
    const sy2=wallH; // sits right on the wainscot/sill line
    px(sx2,sy2,5,2,potC2); px(sx2,sy2,5,1,lerpCol(potC2,'#fff',0.18));
    // rosette
    px(sx2+1,sy2-2,3,1,leafH2);
    px(sx2,sy2-1,5,2,leafM2);
    px(sx2+1,sy2+1,3,1,leafD2);
    px(sx2+2,sy2-1,1,1,lerpCol(leafH2,'#fff',0.3));
  }
  for(const wx of [5,40,75,110,150]){ if(wx+14<=gw) drawSucculent2(wx+4); }

  // 4. Small cactus pots in the dining room, flanking the monstera area
  function drawCactus2(cx2,cy2){
    px(cx2,cy2+8,6,4,potC2); px(cx2,cy2+8,6,1,lerpCol(potC2,'#fff',0.18));
    px(cx2+1,cy2+10,4,2,soil2);
    // trunk
    px(cx2+2,cy2,3,9,cactusC2); px(cx2+3,cy2+1,1,7,cactusH2);
    // arms
    px(cx2-2,cy2+2,4,2,cactusC2); px(cx2-2,cy2,1,3,cactusC2); px(cx2-1,cy2+1,1,1,cactusH2);
    px(cx2+4,cy2+4,4,2,cactusC2); px(cx2+6,cy2+3,1,3,cactusC2); px(cx2+5,cy2+4,1,1,cactusH2);
    // spines
    px(cx2+1,cy2,1,1,'#c8d0a8'); px(cx2+4,cy2+2,1,1,'#c8d0a8');
  }
  drawCactus2(18, wallH+6);
  drawCactus2(gw-22, wallH+6);

  // 5. Trailing pothos shelf-plant flanking the neon sign (right wall, y=18-30)
  function drawPothos2(ox2,oy2){
    // shelf bracket
    px(ox2,oy2,10,1,PAL.trim); px(ox2,oy2,1,3,PAL.trim);
    // pot
    px(ox2+2,oy2+1,7,4,potC2); px(ox2+2,oy2+1,7,1,lerpCol(potC2,'#fff',0.18));
    px(ox2+3,oy2+3,5,2,soil2);
    // right-draping vines
    for(let v=0;v<8;v++){
      const vx=ox2+5+v; const vy=oy2+3+v;
      if(vx<gw){ px(vx,vy,1,1,stemC2); }
      if(v%2===0&&vx+2<gw){ px(vx+1,vy,3,2,leafM2); px(vx+1,vy,1,1,leafH2); }
    }
    // left-draping vines
    for(let v=0;v<7;v++){
      const vx=ox2+3-v; const vy=oy2+3+v;
      if(vx>=0){ px(vx,vy,1,1,stemC2); }
      if(v%2===1&&vx>=2){ px(vx-2,vy,3,2,leafD2); px(vx-1,vy,1,1,leafM2); }
    }
  }
  // one pothos on each side of the neon sign (sign is at sx=54,sy=8,sw=36)
  drawPothos2(33, 15);
  drawPothos2(96, 18);
}

function drawKitchen(frame){
  const gw=Math.ceil(CW/S);
  const gh=Math.ceil(CH/S);
  const cooking=G.cookSlots&&G.cookSlots.length>0;

  // Kitchen is now at the BOTTOM of the canvas — bigger and more spacious
  // Kitchen occupies the bottom 36 rows of the grid
  const kitchenH=36;
  const kitY=gh-kitchenH; // top of kitchen zone

  // pass-through ledge at the TOP of the kitchen (separates dining from kitchen)
  for(let x=0;x<gw;x++)px(x,kitY,1,2,PAL.accent);
  for(let x=0;x<gw;x++)px(x,kitY+2,1,4,PAL.wall);
  for(let x=0;x<gw;x+=10)px(x,kitY+3,1,3,PAL.dot);

  // back wall at the very bottom
  for(let x=0;x<gw;x++)px(x,gh-18,1,18,PAL.dark);
  for(let y=gh-17;y<gh-1;y++)for(let x=0;x<gw;x++)
    if((x+y)%2===0)px(x,y,1,1,PAL.wallAlt);

  // kitchen floor tiles
  for(let y=kitY+6;y<gh-18;y++)for(let x=0;x<gw;x++)
    px(x,y,1,1,(x+y)%2===0?'#22202e':'#1c1a28');

  // ── BLENDERS (left side, replacing the stove) ──
  const blenderBaseX=2, blenderBaseY=gh-16;
  // Countertop
  px(blenderBaseX,blenderBaseY-2,64,3,PAL.accent);
  px(blenderBaseX,blenderBaseY+1,64,12,PAL.stove);
  px(blenderBaseX,blenderBaseY+12,64,1,'#15101f');

  // Draw up to 4 blenders, one per cook slot
  const blenderPositions=[blenderBaseX+4,blenderBaseX+18,blenderBaseX+34,blenderBaseX+50];
  blenderPositions.forEach((bx,i)=>{
    const active=cooking&&i<G.cookSlots.length;
    const spinFrame=Math.floor(frame/2+i*3)%4;
    const glowFlick=Math.floor(frame/3+i)%2;

    // Base / motor unit
    px(bx,blenderBaseY+2,10,9,'#c0c8d0');
    px(bx,blenderBaseY+2,10,2,'#e0e8f0');
    px(bx+1,blenderBaseY+10,8,1,'#8a929a');

    // Jug (glass pitcher)
    px(bx+1,blenderBaseY-9,8,11,'#d8eef8');
    px(bx+1,blenderBaseY-9,8,2,'#eef6fc');   // rim highlight
    px(bx+2,blenderBaseY-8,6,9,'#bcd8ee');    // glass tint
    // Jug lid
    px(bx,blenderBaseY-10,10,2,'#9aa5ad');
    px(bx+3,blenderBaseY-13,4,4,'#b8c2cc');   // lid knob

    if(active){
      // Liquid swirling inside (color cycles through boba colours)
      const drinkCols=['#f7a8d0','#8ed870','#d4a8f0','#f8c0b0','#e8d060','#a0f0d0'];
      const col=drinkCols[i%drinkCols.length];
      // Fill level
      px(bx+2,blenderBaseY-7+spinFrame%2,6,6,col);
      // Spinning blades (4-frame animation)
      const bladeCol='#ffffff';
      if(spinFrame===0){px(bx+3,blenderBaseY-3,4,1,bladeCol);px(bx+4,blenderBaseY-5,1,4,bladeCol);}
      else if(spinFrame===1){px(bx+2,blenderBaseY-5,2,1,bladeCol);px(bx+6,blenderBaseY-2,2,1,bladeCol);px(bx+3,blenderBaseY-4,1,2,bladeCol);px(bx+5,blenderBaseY-1,1,2,bladeCol);}
      else if(spinFrame===2){px(bx+3,blenderBaseY-3,4,1,bladeCol);px(bx+4,blenderBaseY-5,1,4,bladeCol);}
      else{px(bx+2,blenderBaseY-2,2,1,bladeCol);px(bx+6,blenderBaseY-5,2,1,bladeCol);px(bx+5,blenderBaseY-4,1,2,bladeCol);px(bx+3,blenderBaseY-1,1,2,bladeCol);}
      // Glow button on base
      px(bx+3,blenderBaseY+4,4,3,glowFlick?'#44ff88':'#22aa55');
      // Bubbles rising
      const bubbleOff=(Math.floor(frame/4)+i)%6;
      px(bx+3,blenderBaseY-8+bubbleOff,2,2,'rgba(255,255,255,0.6)');
    } else {
      // Idle button (off)
      px(bx+3,blenderBaseY+4,4,3,'#445566');
    }
  });

  // ── CHEF — stationary at the blender station, bobs slightly when cooking ──
  const cookX=72;
  const bob=cooking?Math.floor(frame/6)%2:0; // only bobs when actively cooking
  const cy=gh-27+bob;
  const facingRight=false; // faces the blenders (left)

  // chef hat
  px(cookX+1,cy-3,9,4,'#ffffff');
  px(cookX+2,cy-5,7,3,'#ffffff');
  px(cookX+2,cy-2,7,1,'#e0e0e8');
  // head
  px(cookX,cy+1,11,6,'#f0c8a0');
  // eyes (facing left toward blenders)
  px(cookX+1,cy+3,2,2,'#241433');
  px(cookX+6,cy+3,2,2,'#241433');
  px(cookX+3,cy+5,5,1,'#c87040'); // mouth
  // body / apron
  px(cookX-2,cy+7,15,9,'#ffffff');
  px(cookX-2,cy+7,15,2,'#cfd6e0');
  px(cookX+4,cy+11,6,4,'#d0d8e0');
  // legs
  px(cookX+1,cy+16,4,4,'#caa24a');
  px(cookX+8,cy+16,4,4,'#caa24a');

  // arms — reach toward blender when cooking, relaxed otherwise
  if(cooking){
    // Both arms forward (reaching to press blender / hold cup)
    px(cookX-4,cy+8,4,5,'#f0c8a0');   // left arm reaching out
    px(cookX-7,cy+7,4,3,'#f0c8a0');   // hand
    px(cookX+11,cy+9,4,4,'#f0c8a0');  // right arm
    // cup in hand
    px(cookX-9,cy+8,3,5,'#d8eef8');
    px(cookX-9,cy+8,3,1,'#eef6fc');
  } else {
    // Arms relaxed at sides
    px(cookX-4,cy+8,4,5,'#f0c8a0');
    px(cookX+11,cy+8,4,5,'#f0c8a0');
  }

  // big hanging shelf above middle area (more items)
  const shelfX=100;
  px(shelfX,gh-18,50,3,PAL.trim);
  px(shelfX+2,gh-15,7,7,'#9aa5ad');px(shelfX+2,gh-15,7,3,'#c4ccd2');
  px(shelfX+14,gh-15,4,8,'#caa24a');px(shelfX+22,gh-15,4,8,'#caa24a');
  px(shelfX+32,gh-15,7,7,'#caa24a');
  px(shelfX+42,gh-15,4,8,'#9aa5ad');px(shelfX+42,gh-15,4,3,'#c4ccd2');

  // BIGGER prep counter right side
  const prepX=142;
  px(prepX,gh-16,58,14,PAL.wallAlt);
  px(prepX,gh-16,58,3,PAL.trim);
  // cutting boards and ingredients
  px(prepX+5,gh-11,22,6,'#caa24a');
  px(prepX+5,gh-11,22,1,'#e0bb5e');
  px(prepX+7,gh-10,4,4,'#ff5544');
  px(prepX+13,gh-10,4,4,'#27ae60');
  px(prepX+19,gh-10,4,4,'#ff8833');
  // spice rack
  px(prepX+32,gh-14,6,10,'#caa24a');
  px(prepX+33,gh-13,3,4,'#9aa5ad');
  px(prepX+33,gh-8,3,4,'#a060b0');
  // sink
  px(prepX+42,gh-14,14,11,'#b8c2cc');
  px(prepX+42,gh-14,14,3,'#e4e9ee');
  px(prepX+48,gh-14,2,4,'#9aa5ad'); // faucet
  px(prepX+44,gh-5,10,1,'#7a838c');

  // KITCHEN LABEL on wall
  // (drawn as pixel text approximation — small decorative tiles)
  px(160,gh-18,40,2,'#2a1a3a');
}

function drawCounter(){
  // kept for compatibility; kitchen now drawn via drawKitchen()
}

// ===== BACK WALL (plain — no staff chill room) =====
function drawBackWall(frame){
  const gw=Math.ceil(CW/S);
  const chillH=28;
  // plain back wall — dark checkerboard texture
  for(let x=0;x<gw;x++)px(x,0,1,chillH,PAL.wall||'#1a1428');
  for(let y=0;y<chillH;y++)for(let x=0;x<gw;x++)
    if((x+y)%2===0)px(x,y,1,1,PAL.wallAlt||'#1e1830');
  // baseboard
  for(let x=0;x<gw;x++)px(x,chillH-1,1,2,'#3a2a4a');
  for(let x=0;x<gw;x++)px(x,chillH+1,1,3,'#2e2244');
}

// ===== FAIRY LIGHTS =====
// Strung along the back wall just above the dining floor.
function drawFairyLights(frame){
  const gw=Math.ceil(CW/S);
  const ropeY=27;
  const BULB_COLS=['#ff4488','#ff8800','#ffdd00','#44ff99','#44aaff','#cc44ff','#ff6644'];
  // wire
  for(let x=2;x<gw-2;x++) px(x,ropeY,1,1,'#3a2040');
  // bulbs
  for(let bx=4;bx<gw-4;bx+=6){
    const col=BULB_COLS[(bx*3+5)%BULB_COLS.length];
    const droopExtra=(bx%3===0)?1:0;
    const by=ropeY+1+droopExtra;
    const twinklePhase=Math.floor((frame+bx*7)/10)%18;
    const isOff=(twinklePhase<2);
    const isDim=(twinklePhase===2||twinklePhase===3);
    if(isOff){
      px(bx,by,1,2,'#2a1438');
    } else {
      if(!isDim){
        ctx.save();
        ctx.globalAlpha=0.22;
        ctx.fillStyle=col;
        ctx.fillRect((bx-1)*S,by*S,3*S,3*S);
        ctx.restore();
      }
      const glowCol=isDim?lerpCol(col,'#1a1428',0.55):col;
      px(bx,ropeY,1,1,'#3a2040');
      px(bx,by,1,1,glowCol);
      px(bx-1,by+1,3,1,glowCol);
      px(bx,by+2,1,1,lerpCol(glowCol,'#000',0.3));
      if(!isDim) px(bx-1,by+1,1,1,lerpCol(glowCol,'#fff',0.45));
    }
  }
}


// ===== CAT BED =====
function drawCatBed(){
  // Cozy cat bed in the bottom-left corner of the dining area
  const bx=3, by=48; // grid pos
  // Bed base (oval cushion)
  px(bx,by+2,10,4,'#c97c4a');       // outer cushion
  px(bx+1,by+1,8,5,'#e8a870');      // inner cushion
  px(bx+2,by+2,6,3,'#f0c090');      // lightest centre
  // Rim/edge
  px(bx,by+1,10,1,'#a05a30');
  px(bx,by+5,10,1,'#a05a30');
  // Little heart patch
  px(bx+4,by+2,1,1,'#e06080');
  px(bx+5,by+2,1,1,'#e06080');
  px(bx+4,by+3,1,1,'#e06080');
  px(bx+6,by+3,1,1,'#e06080');
  px(bx+5,by+4,1,1,'#e06080');
}
// ===== SHOP CAT =====
// A tabby who wanders the dining floor, blinks, and wags tail when idle.
function drawCat(frame){
  if(G.hotelMode)return;
  if(!G.cat)G.cat={x:20,y:45,tx:20,ty:45,dir:1,idleMs:0,walkMs:0,state:'idle'};
  const cat=G.cat;

  // Sleeping in bed pose
  if(cat.napping){
    const bx=3, by=48;
    // Cat curled up on bed
    const FUR='#6a5040', FUR2='#7a6050', EYE='#44cc88';
    px(bx+2,by+1,6,3,FUR);   // curled body
    px(bx+3,by+1,4,1,FUR2);  // back highlight
    px(bx+2,by,3,2,FUR);     // head tucked in
    px(bx+7,by+2,2,2,FUR);   // tail curl
    px(bx+8,by+1,2,2,FUR2);
    // closed sleepy eyes
    px(bx+3,by+1,1,1,'#3a2820');
    // ZZZ floaty above
    const zzz=Math.floor(frame/30)%3;
    ctx.save();
    ctx.globalAlpha=0.7-zzz*0.15;
    ctx.fillStyle='#c8b0e8';
    ctx.font=`bold ${(zzz+1)*S}px monospace`;
    ctx.fillText('z',(bx+8+zzz)*S,(by-zzz*2)*S);
    ctx.restore();
    return;
  }
  const cx=Math.round(cat.x);
  const cy=Math.round(cat.y);
  const walking=(cat.state==='walk');
  const dir=cat.dir||1; // 1=right, -1=left

  const blink=(Math.floor(frame/90)%12===0)&&!walking;
  const tailPhase=walking?Math.floor(frame/12)%4:Math.floor(frame/22)%4;
  const legPhase=Math.floor(cat.walkMs/6)%4; // leg cycle when walking
  const bob=walking?Math.floor(frame/8)%2:Math.floor(frame/60)%2;

  const FUR='#6a5040', FUR2='#7a6050', BELLY='#c8b090', EAR_IN='#e09090', EYE='#44cc88', NOSE='#ff8899', DARK='#3a2820';

  // Draw flipped if facing left — use ctx transform
  ctx.save();
  if(dir===-1){
    // mirror around the cat's centre
    ctx.translate((cx+4)*S,0);
    ctx.scale(-1,1);
    ctx.translate(-cx*S,0);
  }

  if(walking){
    // walking pose: body stretched slightly, legs stepping
    const legUp=(legPhase===0||legPhase===2)?1:0;
    // back legs
    px(cx+1,cy+6+(legUp?-1:0),2,1,FUR2);
    px(cx+4,cy+6+(legUp?0:-1),2,1,FUR2);
    // body
    px(cx,cy+2,8,3,FUR);
    px(cx+1,cy+2,6,1,FUR2);
    px(cx+2,cy+3,4,2,BELLY);
    // head (forward, slightly lower)
    px(cx+4,cy,5,3,FUR);
    px(cx+5,cy,3,1,FUR2);
    // ears
    px(cx+4,cy-2,2,2,FUR);
    px(cx+7,cy-1,2,2,FUR);
    px(cx+4,cy-1,1,1,EAR_IN);
    px(cx+7,cy-1,1,1,EAR_IN);
    // eyes (alert, forward-facing)
    px(cx+5,cy+1,1,1,EYE);
    px(cx+7,cy+1,1,1,EYE);
    px(cx+5,cy+1,1,1,lerpCol(EYE,'#fff',0.4));
    px(cx+6,cy+2,1,1,NOSE);
    // tail up/behind
    px(cx-1,cy+3,2,2,FUR);
    px(cx-2,cy+2,2,2,FUR);
    px(cx-2+(tailPhase%2),cy+1,2,2,FUR2);
  } else {
    // loaf / sitting pose
    // tail — wags at the side
    const tailSegs=[
      [cx+6,cy+5+bob],[cx+7,cy+4+bob],[cx+8,cy+3+bob],
      [cx+8+(tailPhase<2?1:0),cy+2+bob-(tailPhase===1||tailPhase===2?1:0)],
    ];
    tailSegs.forEach(([tx,ty])=>px(tx,ty,2,2,FUR));
    px(tailSegs[3][0],tailSegs[3][1],2,2,FUR2);
    // body (loaf)
    px(cx,cy+3,7,4,FUR);
    px(cx+1,cy+3,5,1,FUR2);
    px(cx+2,cy+5,3,2,BELLY);
    // paws tucked
    px(cx+1,cy+7,2,1,FUR2);
    px(cx+4,cy+7,2,1,FUR2);
    // head
    px(cx+1,cy,5,3,FUR);
    px(cx+2,cy,3,1,FUR2);
    // ears
    px(cx+1,cy-2,2,2,FUR);
    px(cx+4,cy-2,2,2,FUR);
    px(cx+1,cy-1,1,1,EAR_IN);
    px(cx+4,cy-1,1,1,EAR_IN);
    // face
    if(blink){
      px(cx+2,cy+1,2,1,DARK);
      px(cx+4,cy+1,2,1,DARK);
    } else {
      px(cx+2,cy+1,1,1,EYE);
      px(cx+4,cy+1,1,1,EYE);
      px(cx+2,cy+1,1,1,lerpCol(EYE,'#fff',0.4));
    }
    px(cx+3,cy+2,1,1,NOSE);
    // whiskers
    px(cx-1,cy+2,2,1,'rgba(200,180,160,0.6)');
    px(cx+5,cy+2,2,1,'rgba(200,180,160,0.6)');
    px(cx-1,cy+3,1,1,'rgba(200,180,160,0.4)');
    px(cx+6,cy+3,1,1,'rgba(200,180,160,0.4)');
  }

  ctx.restore();
}

/* ===== FOOD TRUCK (final world) =====
   Parked truck with a cook visible in the service window, plus an
   awning over the counter where the line forms. Customers queue up
   single-file to its right (see tablePositions' truckScroll branch). */
function drawTruck(frame){
  const cooking=G.cookSlots&&G.cookSlots.length>0;
  const gh=Math.ceil(CH/S);
  const roadY=Math.floor(gh*0.55);
  const shift=roadY-33; // keep the truck's wheels flush with the curb at any canvas height
  const tx0=4,ty0=4+shift;

  // ground shadow under the truck
  px(tx0,ty0+26,68,2,'rgba(0,0,0,0.28)');

  // cab (front, lower-left bump)
  px(tx0,ty0+12,12,14,PAL.accent);
  px(tx0+1,ty0+13,8,5,PAL.windowGl);
  px(tx0,ty0+10,12,2,PAL.trim);

  // main box body
  px(tx0+10,ty0,58,26,PAL.wall);
  px(tx0+10,ty0,58,3,PAL.trim);
  px(tx0+10,ty0+23,58,3,PAL.accent);

  // wheels
  const wob=Math.floor(frame/3)%2;
  px(tx0+6,ty0+22+wob,7,6,'#15101f');px(tx0+7,ty0+23+wob,5,4,'#3a3a44');
  px(tx0+48,ty0+22+wob,7,6,'#15101f');px(tx0+49,ty0+23+wob,5,4,'#3a3a44');

  // service window cut into the right wall of the box
  const winX=tx0+38,winY=ty0+5;
  px(winX,winY,24,12,PAL.windowGl);
  px(winX,winY,24,1,PAL.trim);px(winX,winY+11,24,1,PAL.trim);
  // serving counter ledge sticking out below the window
  px(winX-2,ty0+18,28,4,PAL.trim);
  px(winX-2,ty0+18,28,1,'#fff6c8');

  // striped awning above the window, angled out toward the queue
  for(let i=0;i<7;i++){
    px(winX-4+i*4,ty0-4,4,4,i%2===0?PAL.accent:PAL.trim);
  }
  px(winX-6,ty0,2,6,'#2a1c0a');px(winX+26,ty0,2,8,'#2a1c0a');

  // roof vent + steam when something's cooking
  px(tx0+24,ty0-2,6,2,'#3a3a44');
  if(cooking){
    const steamF=Math.floor(frame/6)%3;
    px(tx0+25,ty0-5-steamF*2,3,3,'#cfd6e0');
    px(tx0+27,ty0-8-((steamF+1)%3)*2,3,3,'#cfd6e0');
  }

  // cook peeking through the service window
  const bob=cooking?Math.floor(frame/8)%2:0;
  const cy=winY+1+bob;
  px(winX+8,cy,7,3,'#e8e8f0');
  px(winX+7,cy+3,9,4,'#f0c8a0');
  px(winX+9,cy+5,1,1,'#241433');px(winX+13,cy+5,1,1,'#241433');
  px(winX+6,cy+7,11,4,'#ffffff');
}

/* Ground shadow + status marker used for truck-world queue spots,
   replacing the dining-room table/chair furniture. */
function drawQueueShadow(t){
  if(t.state==='empty')return;
  px(t.px-1,t.py+9,7,1,'rgba(0,0,0,0.25)');
}
function drawQueueMarker(t){
  if(t.state==='empty')return;
  const sp=G.sprites.find(s=>s.tableIdx===t.idx);
  if(sp&&sp.walking)return;
  const col=t.state==='waiting'?'#ff4444':t.state==='ready'?'#ffcc00':'#33cc66';
  px(t.px+1,t.py-4,3,3,col);
}

function drawTable(t){
  const{px:tx,py:ty,state}=t;

  // Status glow — thin ring behind the whole booth
  if(state==='waiting') px(tx-3,ty-14,26,36,'#ff4444');
  else if(state==='eating') px(tx-3,ty-14,26,36,'#33cc66');
  else if(state==='ready') px(tx-3,ty-14,26,36,'#ffcc00');

  // ── TOP SOFA (facing down) ──
  // back rest
  px(tx-1,ty-14,22,5,PAL.chair);
  px(tx-1,ty-14,22,2,PAL.tableTop);
  // seat cushion
  px(tx-1,ty-9,22,7,PAL.cloth);
  px(tx-1,ty-9,22,2,PAL.tableTop);
  // cushion divider & pillows
  px(tx+9,ty-9,2,7,'rgba(0,0,0,0.15)');
  px(tx+1,ty-11,5,3,'rgba(255,255,255,0.18)');
  px(tx+14,ty-11,5,3,'rgba(255,255,255,0.18)');
  // armrests
  px(tx-2,ty-14,2,12,PAL.chair); px(tx+20,ty-14,2,12,PAL.chair);

  // ── COFFEE TABLE ──
  px(tx+1,ty-1,18,6,PAL.table);
  px(tx+1,ty-1,18,2,PAL.tableTop);
  // cloth runner
  px(tx+3,ty,14,2,PAL.cloth);
  // candle
  px(tx+9,ty-3,2,4,'#d4c09a');
  px(tx+9,ty-4,2,1,'#ff9944');
  px(tx+9,ty-5,1,1,'#ffee88');
  // cups/plates either side
  px(tx+3,ty+1,4,2,'#e8e0d0');
  px(tx+13,ty+1,4,2,'#e8e0d0');

  // ── BOTTOM SOFA (facing up) ──
  // seat cushion
  px(tx-1,ty+6,22,7,PAL.cloth);
  px(tx-1,ty+12,22,1,PAL.tableTop);
  px(tx+9,ty+6,2,7,'rgba(0,0,0,0.15)');
  px(tx+1,ty+10,5,3,'rgba(255,255,255,0.18)');
  px(tx+14,ty+10,5,3,'rgba(255,255,255,0.18)');
  px(tx-2,ty+6,2,12,PAL.chair); px(tx+20,ty+6,2,12,PAL.chair);
  // back rest
  px(tx-1,ty+13,22,5,PAL.chair);
  px(tx-1,ty+16,22,2,PAL.tableTop);
}

function drawCustomer(t,frame){
  if(t.state==='empty')return;
  const sp=G.sprites.find(s=>s.tableIdx===t.idx);
  if(!sp)return;
  const x=Math.round(sp.x),y=Math.round(sp.y);

  // ── WALKING IN ──
  if(sp.walking){
    const leg=Math.floor(frame/4)%2;
    px(x+1,y,3,2,t.hairCol);
    px(x,y+2,5,3,t.skinCol);
    px(x-1,y+3,7,3,t.shirtCol);
    if(leg===0){px(x,y+6,2,2,t.shirtCol);px(x+3,y+6,2,3,t.shirtCol);}
    else{px(x,y+6,2,3,t.shirtCol);px(x+3,y+6,2,2,t.shirtCol);}
    return;
  }

  const bob=Math.floor(frame/8)%2;
  const dy=bob?1:0;

  // ── TOP CHAIR — main customer (facing down toward table) ──
  if(t.state==='eating'){
    // lean forward slightly, fork raised
    px(x+1,y+dy,3,2,t.hairCol);
    px(x,y+2+dy,5,3,t.skinCol);
    px(x-1,y+4+dy,7,2,t.shirtCol);
    px(x+1,y+3+dy,3,1,'#ffcc44'); // food on fork
    px(x,y+6,2,2,t.shirtCol);px(x+3,y+6,2,2,t.shirtCol);
  } else {
    // waiting / ready — relaxed upright
    px(x+1,y+dy,3,2,t.hairCol);
    px(x,y+2+dy,5,3,t.skinCol);
    px(x+1,y+3+dy,1,1,'#222');px(x+3,y+3+dy,1,1,'#222'); // eyes
    px(x-1,y+4+dy,7,3,t.shirtCol);
    px(x,y+7,2,2,t.shirtCol);px(x+3,y+7,2,2,t.shirtCol);
  }

  // ── BOTTOM CHAIR — companion guest (facing up) ──
  // Pick a complement colour so they look like a different person
  const cHair=HAIR_COLS[(t.idx+2)%HAIR_COLS.length];
  const cShirt=SHIRT_COLS[(t.idx+1)%SHIRT_COLS.length];
  const bx=x, by=t.py+8; // bottom chair position
  const cbob=(bob+1)%2; // slight offset so they don't bob in sync
  const cdy=cbob?1:0;
  if(t.state==='eating'){
    px(bx+1,by-cdy,3,2,cHair);
    px(bx,by-2-cdy,5,3,t.skinCol);
    px(bx-1,by-4-cdy,7,2,cShirt);
    px(bx+1,by-3-cdy,3,1,'#ffcc44');
    px(bx,by-7,2,2,cShirt);px(bx+3,by-7,2,2,cShirt);
  } else {
    px(bx+1,by-cdy,3,2,cHair);
    px(bx,by-2-cdy,5,3,t.skinCol);
    px(bx+1,by-3-cdy,1,1,'#222');px(bx+3,by-3-cdy,1,1,'#222');
    px(bx-1,by-4-cdy,7,3,cShirt);
    px(bx,by-7,2,2,cShirt);px(bx+3,by-7,2,2,cShirt);
  }
}

function drawPuddles(){
  if(!G.puddles||!G.puddles.length)return;
  G.puddles.forEach(p=>{
    // draw a dark blue translucent blob made of pixel blocks
    const baseCol='#1e2a3a';
    const shineCol='#263545';
    // main puddle body
    for(let dy=0;dy<p.h;dy++){
      for(let dx=0;dx<p.w;dx++){
        if(dy===0&&(dx===0||dx===p.w-1))continue; // round corners
        const col=(dy===0||dx===1&&dy===1)?shineCol:baseCol;
        px(p.x+dx,p.y+dy,1,1,col);
      }
    }
  });
}

function drawWindows(frame){
  const gw=Math.ceil(CW/S);
  const wallH=7;
  const dayT=G&&G.tm!=null?Math.max(0,Math.min(1,(G.tm-8*60)/(21*60-8*60))):0.3;
  const sky=skyColour(dayT);
  const isNight=dayT>0.85;
  const isDusk=(dayT>0.72&&dayT<=0.92);
  const isDawn=(dayT<0.18);

// Draw each window — tall arched frames with curtains, sill, live sky scene
  for(let wx of[5,40,75,110,150]){
    if(wx+14>gw)continue;

    // Window geometry — much taller, reaches from y=0 to y=wallH+8 (into dining room)
    const frameX=wx, frameY=0;
    const frameW=14, frameH=wallH+9;   // full height: wall strip + into dining room
    const winX=wx+1, winY=1;
    const winW=12, winH=frameH-3;      // interior glass area

    // ── Sky fill inside glass ──
    for(let dy=0;dy<winH;dy++){
      const skyT=dy/(winH-1);
      const rowCol=lerpCol(sky.top,sky.bot,skyT);
      px(winX,winY+dy,winW,1,rowCol);
    }

    // Stars at night/dusk — deterministic positions
    if(isNight||isDusk){
      const starAlpha=isNight?1:Math.max(0,(dayT-0.72)/0.13);
      const starPositions=[[1,0],[4,2],[7,1],[10,3],[2,4],[9,0],[5,5],[11,2]];
      starPositions.forEach(([sx2,sy2])=>{
        if(sy2<winH-2)
          px(winX+sx2,winY+sy2,1,1,lerpCol(sky.top,'#ffffff',0.65*starAlpha));
      });
    }

    // Sun (travels left→right across the window top half)
    if(!isNight){
      const sunPosX=Math.round(winX+1+(winW-3)*Math.min(dayT/0.85,1));
      const sunPosY=winY+Math.round((winH*0.2)*(dayT<0.5?dayT*2:2-dayT*2));
      const sunCol=(isDusk||isDawn)?'#ffdd44':'#ffe870';
      px(Math.min(sunPosX,winX+winW-2),sunPosY,2,2,sunCol);
      px(Math.min(sunPosX,winX+winW-2),sunPosY,2,1,lerpCol(sunCol,'#fff',0.5)); // glint
    } else {
      // Moon — crescent near top right
      px(winX+9,winY+1,2,2,'#d8d8e8');
      px(winX+10,winY+1,1,2,sky.top);
    }

    // Clouds — drift gently, 3 per window
    if(!isNight){
      const drift=Math.floor(frame/10)%winW;
      for(let c=0;c<3;c++){
        const cx=((wx*4+c*5+drift)%winW)+winX;
        const cy=winY+1+c*2;
        const cloudCol=lerpCol(sky.bot,'#ffffff',isDusk?0.3:0.5);
        if(cx+3<=winX+winW){ px(cx,cy,3,1,cloudCol); px(cx+1,cy-1,2,1,cloudCol); }
      }
    }

    // Distant city/tree silhouette on horizon (bottom third of window)
    const horizY=winY+Math.round(winH*0.65);
    const buildCol=lerpCol(sky.bot,'#1a1428',isNight?0.85:0.25);
    // Silhouette blobs — deterministic per window
    const blobs=[[0,3,4],[3,5,3],[6,2,4],[9,4,3],[11,3,2]];
    blobs.forEach(([bx,by,bh])=>{
      const absBx=winX+bx, absBy=horizY-by;
      if(absBy>=winY&&absBx+bh<=winX+winW)
        px(absBx,absBy,Math.min(bh,winX+winW-absBx),winY+winH-absBy,buildCol);
    });

    // Rain streaks
    const rainDay=G&&G.day?((G.day*7+wx)%5===0):false;
    if(rainDay){
      const rainShift=Math.floor(frame/2)%4;
      for(let ry=0;ry<winH;ry++){
        const rx=(wx*3+ry+rainShift)%winW;
        if(rx>=0&&rx<winW) px(winX+rx,winY+ry,1,1,lerpCol(sky.bot,'#a0c8e0',0.5));
      }
    }

    // ── Outer window frame ──
    // Left/right sides full height
    px(frameX,frameY,1,frameH,PAL.trim);
    px(frameX+frameW-1,frameY,1,frameH,PAL.trim);
    // Top arch — 3 rows
    px(frameX,frameY,frameW,1,PAL.trim);
    px(frameX+1,frameY-1,frameW-2,1,PAL.trim); // arch peak (1 row above)
    // Bottom sill (thick)
    px(frameX-1,frameY+frameH-1,frameW+2,2,PAL.trim);
    px(frameX-1,frameY+frameH+1,frameW+2,1,lerpCol(PAL.trim,'#000',0.3));
    // Cross divider (horizontal mid-pane & vertical centre mullion)
    const midY=frameY+Math.round(frameH*0.5);
    px(frameX,midY,frameW,1,PAL.trim);
    px(frameX+Math.round(frameW/2)-1,frameY,1,frameH,PAL.trim);

    // ── Curtains (left and right drape, partial overlap onto glass) ──
    const curtainCol=lerpCol(PAL.accent,'#ffffff',0.35);
    const curtainShadow=lerpCol(curtainCol,'#000000',0.25);
    const curtainW=3;
    // Left curtain — tie-back fold halfway down
    for(let dy=0;dy<frameH-2;dy++){
      const fold=dy<Math.round(frameH*0.55)?0:Math.round((dy-frameH*0.55)*0.4);
      px(frameX+1,frameY+dy,curtainW-fold,1,curtainCol);
      px(frameX+1,frameY+dy,1,1,curtainShadow); // inner shadow
    }
    // Right curtain
    for(let dy=0;dy<frameH-2;dy++){
      const fold=dy<Math.round(frameH*0.55)?0:Math.round((dy-frameH*0.55)*0.4);
      const rx=frameX+frameW-1-curtainW+fold;
      px(rx,frameY+dy,curtainW-fold,1,curtainCol);
      px(frameX+frameW-2,frameY+dy,1,1,curtainShadow);
    }
    // Curtain rod above frame
    px(frameX-1,frameY-2,frameW+2,1,lerpCol(PAL.trim,'#888',0.4));
    // Tie-back knot dots
    const tieDy=Math.round(frameH*0.55);
    px(frameX+curtainW,frameY+tieDy,2,2,curtainShadow);
    px(frameX+frameW-curtainW-2,frameY+tieDy,2,2,curtainShadow);

    // Subtle glow wash on wall/floor below window at dusk/dawn
    if(isDusk||isDawn){
      const glowCol=lerpCol(PAL.wall,isDusk?'#c04018':'#e07030',0.15);
      px(wx-1,frameY+frameH+2,frameW+2,2,glowCol);
    }
    // Night glow (moonlight spill)
    if(isNight){
      const moonGlow=lerpCol(PAL.wall,'#8090c0',0.12);
      px(wx,frameY+frameH+2,frameW,2,moonGlow);
    }
  }

}

function drawScene(frame){
  ctx.clearRect(0,0,CW,CH);
  if(G.hotelMode){
    drawHotelFloor();
    drawHotelLounge(frame);
    drawHotelDesk(frame);
    drawHotelDoors(frame);
    drawHotelQueueGuests(frame);
    return;
  }
  drawFloor();
  const isTruck=WORLDS[G.worldIdx]&&WORLDS[G.worldIdx].truckScroll;
  if(!isTruck)drawWall(frame);
  if(isTruck){drawTruck(frame);}else{drawKitchen(frame);drawBackWall(frame);drawFairyLights(frame);}
  if(!isTruck)drawCatBed();
  drawWindows(frame);
  drawPuddles();
  if(isTruck){
    G.tables.forEach(t=>drawQueueShadow(t));
    G.tables.forEach(t=>drawCustomer(t,frame));
    G.tables.forEach(t=>drawQueueMarker(t));
  } else {
    G.tables.forEach(t=>drawTable(t));
    G.tables.forEach(t=>drawCustomer(t,frame));
  }
  if(!isTruck)drawCat(frame);
  G.sprites.forEach(sp=>{
    if(sp.leaving){
      const x=Math.round(sp.x),y=Math.round(sp.y);
      const frame2=Math.floor(sp.leaveFrame/4)%2;
      const waving=sp.leaveFrame<40;
      const waveArm=waving?Math.floor(sp.leaveFrame/8)%2:0;
      px(x+1,y,3,2,sp.hairCol);
      px(x,y+2,5,3,sp.skinCol);
      px(x-1,y+3,7,3,sp.shirtCol);
      if(waving){
        // Standing still, waving arm up
        px(x,y+6,2,4,sp.shirtCol); px(x+3,y+6,2,4,sp.shirtCol); // legs
        // Wave arm: alternates high/low
        px(x-2,y+(waveArm?1:2),2,3,sp.skinCol); // waving arm
        // little sparkle/star near hand
        if(waveArm)px(x-3,y,1,1,'#ffe066');
      } else {
        if(frame2===0){px(x,y+6,2,2,sp.shirtCol);px(x+3,y+6,2,3,sp.shirtCol);}
        else{px(x,y+6,2,3,sp.shirtCol);px(x+3,y+6,2,2,sp.shirtCol);}
      }
    }
  });
  drawAssistants(animFrame);

  // ── Closing-time fade overlay ──
  if(G.closingFade>0&&!G.hotelMode){
    ctx.save();
    ctx.globalAlpha=G.closingFade*0.55;
    ctx.fillStyle='#0a0510';
    ctx.fillRect(0,0,CW,CH);
    ctx.restore();
    // "CLOSING" text in centre when fade is strong enough
    if(G.closingFade>0.3){
      const alpha=Math.min(1,(G.closingFade-0.3)/0.4);
      ctx.save();
      ctx.globalAlpha=alpha;
      ctx.fillStyle='#f0e8ff';
      ctx.font=`bold ${Math.round(S*5)}px monospace`;
      ctx.textAlign='center';
      ctx.textBaseline='middle';
      ctx.fillText('CLOSING TIME',CW/2,CH/2-S*3);
      ctx.font=`${Math.round(S*2.5)}px monospace`;
      ctx.fillStyle='#b8a0e0';
      ctx.fillText('see you tomorrow ☕',CW/2,CH/2+S*3);
      ctx.restore();
    }
  }
}

// ===== ASSISTANT SPRITES =====
const APRON_COLS=['#e8e8f0','#f0e8d0','#d0e8f0','#f0d0e8'];
const ASSISTANT_HAIR=['#2c1a0e','#f0c040','#1a1a1a','#c0392b'];
let assistantSeq=0;

function spawnAssistant(tableIdx){
  const t=G.tables[tableIdx];
  if(!t)return;
  const startX=Math.round(CW/S/2);
  const startY=Math.round(CH/S)-20; // spawn from kitchen at bottom
  const hairCol=ASSISTANT_HAIR[Math.floor(Math.random()*ASSISTANT_HAIR.length)];
  const apronCol=APRON_COLS[Math.floor(Math.random()*APRON_COLS.length)];
  const uid=++assistantSeq;
  G.assistants.push({
    uid,tableIdx,
    x:startX,y:startY,
    tx:t.px+3,ty:t.py+5,
    phase:'toTable',
    pauseFrames:0,
    hairCol,apronCol,
    frame:0,
    dish:G.tables[tableIdx]?.order?.em||'🍽',
  });
}

function updateAssistants(){
  const speed=1.8*G.spd;
  G.assistants=G.assistants.filter(as=>{
    as.frame++;
    if(as.phase==='toTable'){
      const dx=as.tx-as.x,dy=as.ty-as.y;
      const dist=Math.sqrt(dx*dx+dy*dy);
      if(dist<speed){as.x=as.tx;as.y=as.ty;as.phase='pause';as.pauseFrames=0;}
      else{as.x+=dx/dist*speed;as.y+=dy/dist*speed;}
    } else if(as.phase==='pause'){
      as.pauseFrames++;
      if(as.pauseFrames>18/Math.max(G.spd,1)){
        as.phase='returning';
        as.tx=Math.round(CW/S/2);
        as.ty=Math.round(CH/S)-20;
      }
    } else if(as.phase==='returning'){
      const dx=as.tx-as.x,dy=as.ty-as.y;
      const dist=Math.sqrt(dx*dx+dy*dy);
      if(dist<speed){as.phase='done';}
      else{as.x+=dx/dist*speed;as.y+=dy/dist*speed;}
    }
    return as.phase!=='done';
  });
}

function drawAssistants(frame){
  G.assistants.forEach(as=>{
    const x=Math.round(as.x),y=Math.round(as.y);
    const walking=as.phase==='toTable'||as.phase==='returning';
    const leg=Math.floor(as.frame/3)%2;
    const bob=(!walking)?Math.floor(as.frame/8)%2:0;
    const dy=bob;
    // hair
    px(x+1,y+dy,5,2,as.hairCol);
    // face
    px(x,y+2+dy,7,3,'#f0c8a0');
    px(x+1,y+3+dy,2,1,'#332211');
    px(x+4,y+3+dy,2,1,'#332211');
    // apron
    px(x-1,y+5+dy,9,5,as.apronCol);
    px(x+1,y+5+dy,5,5,'#e0e0ef');
    px(x+2,y+4+dy,3,2,'#ddd8c8');
    if(as.phase==='pause'){
      // reaching out to deliver
      px(x+7,y+4+dy,4,2,'#f0c8a0');
      px(x+10,y+3+dy,4,4,'#c8a878');
      px(x+11,y+3+dy,2,1,'#e8e0d0');
    } else if(walking){
      if(leg===0){px(x,y+10,3,3,as.apronCol);px(x+4,y+10,3,4,as.apronCol);}
      else{px(x,y+10,3,4,as.apronCol);px(x+4,y+10,3,3,as.apronCol);}
      // carrying dish
      px(x+7,y+5+dy,4,2,'#f0c8a0');
      px(x+9,y+4+dy,4,4,'#c8a878');
      px(x+10,y+4+dy,2,1,'#e8e0d0');
    } else {
      px(x,y+10,3,4,as.apronCol);
      px(x+4,y+10,3,4,as.apronCol);
    }
  });
}

let animFrame=0;
function loop(){
  animFrame++;
  if(G.open&&WORLDS[G.worldIdx]&&WORLDS[G.worldIdx].truckScroll){
    truckScrollX=(truckScrollX+1.5*G.spd)%(110*S);
  }
  updateSprites();
  updateAssistants();
  updateCat();
  drawScene(animFrame);
  requestAnimationFrame(loop);
}

function updateCat(){
  if(G.hotelMode)return;
  if(!G.cat)G.cat={x:20,y:45,tx:20,ty:45,dir:1,idleMs:0,walkMs:0,state:'idle'};
  const cat=G.cat;
  const gw=Math.ceil(CW/S), gh=Math.ceil(CH/S);
  // bounds: floor area only — below the back wall, above the kitchen counter
  const CAT_TOP=32, CAT_BOT=gh-18, CAT_LEFT=2, CAT_RIGHT=gw-12;
  const SPEED=0.18*G.spd;

  if(cat.state==='idle'){
    cat.idleMs+=(1000/60)*G.spd;
    // after a random idle pause (1.5–5s game time), pick a new destination
    const idleTarget=1500+Math.random()*3500;
    if(cat.idleMs>idleTarget){
      cat.idleMs=0;
      cat.state='walk';
      cat.walkMs=0;
      // pick a spot anywhere on the dining floor
      cat.tx=CAT_LEFT+Math.random()*(CAT_RIGHT-CAT_LEFT);
      cat.ty=CAT_TOP+Math.random()*(CAT_BOT-CAT_TOP);
    }
  } else {
    // walking toward target
    const dx=cat.tx-cat.x, dy=cat.ty-cat.y;
    const dist=Math.sqrt(dx*dx+dy*dy);
    cat.dir=dx<0?-1:1; // face direction of travel
    if(dist<SPEED+0.5){
      cat.x=cat.tx; cat.y=cat.ty;
      cat.state='idle';
      cat.idleMs=0;
    } else {
      cat.x+=dx/dist*SPEED;
      cat.y+=dy/dist*SPEED;
    }
    cat.walkMs++;
  }

  // Cat tax: if cat is near the kitchen pass (bottom of dining area) and there's a ready drink, occasionally knock one off
  const nearCounter=(cat.y>42&&cat.x>10&&cat.x<50);
  if(nearCounter&&G.ready&&G.ready.length>0&&cat.state==='idle'){
    if(!cat.taxCooldown)cat.taxCooldown=0;
    cat.taxCooldown--;
    if(cat.taxCooldown<=0){
      // ~0.3% chance per frame when near counter and idle
      if(Math.random()<0.003){
        const knocked=G.ready.splice(Math.floor(Math.random()*G.ready.length),1)[0];
        if(knocked){
          addLog(`🐱 The cat knocked over ${knocked.em} ${knocked.nm}! Cat tax collected.`,'s');
          cat.taxCooldown=600; // 10s cooldown before next tax
          if(typeof rKitchen==='function')rKitchen();
        }
      }
    }
  }

  // Occasionally head to the cat bed for a nap
  if(cat.state==='idle'&&!cat.napping){
    if(Math.random()<0.002){ // small chance per frame to decide to nap
      cat.state='walk';
      cat.walkMs=0;
      cat.tx=5; cat.ty=49; // bed position
      cat.headingToBed=true;
    }
  }
  if(cat.headingToBed&&cat.state==='idle'&&Math.abs(cat.x-5)<3&&Math.abs(cat.y-49)<3){
    cat.napping=true;
    cat.headingToBed=false;
    cat.napMs=0;
  }
  if(cat.napping){
    cat.napMs=(cat.napMs||0)+1;
    if(cat.napMs>400){ // wake up after ~6s
      cat.napping=false;
      cat.napMs=0;
    }
  }

}

function updateSprites(){
  const speed=2*G.spd;
  G.sprites=G.sprites.filter(sp=>{
    if(sp.leaving){
      // Wave for 40 frames before walking off
      if(sp.leaveFrame<40){ sp.leaveFrame++; return true; }
      sp.x-=speed;
      sp.leaveFrame++;
      return sp.x>-10;
    }
    if(sp.walking){
      const dx=sp.tx-sp.x,dy=sp.ty-sp.y;
      const dist=Math.sqrt(dx*dx+dy*dy);
      if(dist<speed){
        sp.x=sp.tx;sp.y=sp.ty;sp.walking=false;
      } else {
        sp.x+=dx/dist*speed;
        sp.y+=dy/dist*speed;
      }
    }
    return true;
  });
}

function spawnSprite(tableIdx){
  const t=G.tables[tableIdx];
  if(!t)return;
  const existing=G.sprites.findIndex(s=>s.tableIdx===tableIdx);
  if(existing>=0)G.sprites.splice(existing,1);
  // Seat the customer in the top chair (above table, facing downward)
  G.sprites.push({
    tableIdx,
    x:Math.round(CW/S)+2,
    y:t.py-10,
    tx:t.px+3,
    ty:t.py-10,
    walking:true,
    leaving:false,
    leaveFrame:0,
    hairCol:t.hairCol,
    shirtCol:t.shirtCol,
    skinCol:t.skinCol,
  });
}

function removeSprite(tableIdx,mad){
  const sp=G.sprites.find(s=>s.tableIdx===tableIdx);
  if(!sp)return;
  if(mad){
    sp.leaving=true;sp.walking=false;sp.tableIdx=-1;
    sp.hairCol=G.tables[tableIdx]?.hairCol||'#2c1a0e';
    sp.shirtCol=G.tables[tableIdx]?.shirtCol||'#c0392b';
    sp.skinCol=G.tables[tableIdx]?.skinCol||'#f5c5a3';
  } else {
    G.sprites=G.sprites.filter(s=>s!==sp);
  }
}

let lastTick=Date.now();
function tick(){
  if(!G.open)return;
  const now=Date.now();
  const dtMs=(now-lastTick)*G.spd;
  lastTick=now;
  G.tm+=dtMs/1000*5;
  const closeTime=21*60;
  const warnTime=20*60; // 8 PM warning

  // ── Closing-soon warning at 8 PM ──
  if(G.tm>=warnTime&&!G.closingWarnShown){
    G.closingWarnShown=true;
    addLog('⏰ Closing in 1 hour — last call for boba!','s');
    // flash the status badge
    const el=document.getElementById('st');
    el.textContent='CLOSING SOON';el.className='cst';
    setTimeout(()=>{if(G.open){el.textContent='OPEN';el.className='ost bl';}},3000);
  }

  // ── Closing fade: last 5 in-game minutes (1 min real ≈ 12 game mins at spd×5) ──
  const fadeStart=closeTime-5;
  if(G.tm>=fadeStart){
    G.closingFade=Math.min(1,(G.tm-fadeStart)/5);
  } else {
    G.closingFade=0;
  }

  if(G.tm>=closeTime){endDay();return;}
  G.cT+=dtMs/1000;
  const emptyCount=G.tables.filter(t=>t.state==='empty').length;
  if(G.cT>=spawnSecs()&&emptyCount>0&&!G.spawnCooldown){G.cT=0;trySpawn();}
  refreshEvolveBtn();
  // spawn puddles gradually from 8am, more as day goes on
  if(!G.hotelMode&&G.open){
    const gw=Math.ceil(CW/S),gh=Math.ceil(CH/S);
    const puddleTop=32; // floor area starts after chill room zone
    const puddleBot=Math.round(gh*0.72); // stop before kitchen zone at bottom
    const dayProgress=(G.tm-8*60)/(21*60-8*60); // 0 to 1
    const maxPuddles=Math.floor(dayProgress*18);
    if(G.puddles.length<maxPuddles&&Math.random()<0.008*G.spd){
      G.puddles.push({
        x:Math.round(4+Math.random()*(gw-8)),
        y:Math.round(puddleTop+Math.random()*(puddleBot-puddleTop-2)),
        w:Math.round(3+Math.random()*5),
        h:Math.round(2+Math.random()*3),
        alpha:0.55+Math.random()*0.3
      });
    }
  }
  G.tables.forEach(t=>{
    if(t.state==='waiting'&&G.ready.some(r=>r.id===t.order.id)){
      t.state='ready';
    } else if(t.state==='eating'){
      t.eatMs+=dtMs;
      if(t.eatMs>=t.maxEatMs){t.state='empty';t.order=null;t.custNm='';removeSprite(t.idx,false);}
    }
  });
  if(STAFF.cook.done)autoCookTables();
  checkCookSlots();
  if(G.cookSlots.length)rKitchenProgress();
  if(STAFF.waiter.done)tryAutoServe();
  document.getElementById('ck').textContent=fd();
  document.getElementById('mn').textContent='$'+G.money.toFixed(2);
  document.getElementById('dM').textContent=G.tables.filter(t=>t.state!=='empty').length;
  rTables();
}

/* The hired Cook automatically starts a cook job for any table that's
   waiting on an order and doesn't already have one in progress. */
function autoCookTables(){
  G.tables.forEach(t=>{
    if(t.state==='waiting'&&t.order&&!t.autoCooking){
      t.autoCooking=true;
      startCook(t.order.id);
    }
  });
}

/* The hired Waiter automatically delivers any ready dish to a matching
   table, no manual pick-up/click needed. */
function tryAutoServe(){
  if(!G.ready.length)return;
  for(let i=G.ready.length-1;i>=0;i--){
    const item=G.ready[i];
    const table=G.tables.find(t=>t.state==='ready'&&t.order&&t.order.id===item.id);
    if(table)deliverItemToTable(item,table.idx);
  }
}

function trySpawn(){
  const empty=G.tables.find(t=>t.state==='empty');if(!empty)return;
  const menu=activeMenu();

  // Decide whether to spawn a regular
  const regularNames=Object.keys(G.regulars).filter(n=>G.regulars[n].visits>=REGULAR_THRESHOLD);
  let spawnedRegular=false;
  if(regularNames.length>0&&Math.random()<REGULAR_SPAWN_CHANCE){
    const nm=regularNames[Math.floor(Math.random()*regularNames.length)];
    const reg=G.regulars[nm];
    empty.custNm=nm;
    // Regulars order their favourite 70% of the time, random otherwise
    const favItem=reg.favId?menu.find(m=>m.id===reg.favId):null;
    empty.order=(favItem&&Math.random()<0.7)?favItem:menu[Math.floor(Math.random()*menu.length)];
    empty.state='waiting';
    empty.autoCooking=false;
    // Consistent look
    empty.skinCol=reg.skinCol;
    empty.shirtCol=reg.shirtCol;
    empty.hairCol=reg.hairCol;
    const isVIP=reg.visits>=10;
    const greetPool=isVIP?VIP_GREETINGS:REGULAR_GREETINGS;
    const greet=greetPool[Math.floor(Math.random()*greetPool.length)](nm);
    addLog(`${greet} · ${empty.order.em} ${empty.order.nm}`,isVIP?'s':'i');
    spawnedRegular=true;
  }

  if(!spawnedRegular){
    const namePool=NS;
    empty.custNm=namePool[Math.floor(Math.random()*namePool.length)];
    empty.order=menu[Math.floor(Math.random()*menu.length)];
    empty.state='waiting';
    empty.autoCooking=false;
    empty.skinCol=SKIN_COLS[Math.floor(Math.random()*SKIN_COLS.length)];
    empty.shirtCol=SHIRT_COLS[Math.floor(Math.random()*SHIRT_COLS.length)];
    empty.hairCol=HAIR_COLS[Math.floor(Math.random()*HAIR_COLS.length)];
    addLog(`${empty.custNm} seated · ordering ${empty.order.em} ${empty.order.nm}`,'i');
  }

  G.spawnCooldown=true;
  spawnSprite(empty.idx);
  setTimeout(()=>{G.spawnCooldown=false;},2000/G.spd);
}

/* Multiple dishes can cook at once now. Each slot in G.cookSlots is
   {item, startedAt, durMs, id}. A slot finishes when (now-startedAt)*spd >= durMs.
   RUSH pays money to instantly finish a slot. */
let cookSlotSeq=0;
function rushCost(item){return Math.ceil(item.price*1.5);}

function startCook(id){
  const item=MENU_IDX[id];
  G.cookSlots.push({uid:++cookSlotSeq,item,startedAt:Date.now(),durMs:Math.round(item.time/cookMult())});
  addLog(`Cooking ${item.em} ${item.nm}...`,'i');
  rKitchen();
}

function rushSlot(uid){
  const slot=G.cookSlots.find(s=>s.uid===uid);if(!slot)return;
  const cost=rushCost(slot.item);
  if(G.money<cost){addLog(`Need $${cost.toFixed(2)} to rush this dish.`,'i');return;}
  G.money-=cost;
  document.getElementById('mn').textContent='$'+G.money.toFixed(2);
  slot.startedAt=0;slot.durMs=0; // forces it to finish on next tick check
  addLog(`Paid $${cost.toFixed(2)} to rush ${slot.item.em} ${slot.item.nm}!`,'u');
  checkCookSlots();
  rKitchen();
}

function checkCookSlots(){
  if(!G.cookSlots.length)return;
  const now=Date.now();
  const stillCooking=[];
  G.cookSlots.forEach(slot=>{
    const elapsed=(now-slot.startedAt)*G.spd;
    if(elapsed>=slot.durMs){
      const item=slot.item;
      const readyItem={...item,_uid:Symbol()};
      G.ready.push(readyItem);
      addLog(`${item.em} ${item.nm} ready! Pick it up.`,'i');
      G.tables.forEach(t=>{if(t.state==='waiting'&&t.order&&t.order.id===item.id)t.state='ready';});
    } else {
      stillCooking.push(slot);
    }
  });
  if(stillCooking.length!==G.cookSlots.length){
    G.cookSlots=stillCooking;
    rKitchen();rQueue();
  }
}

function pickUp(idx){
  if(idx<0||idx>=G.ready.length)return;
  G.held=G.ready[idx];
  // find tables waiting/ready for this dish
  const matches=G.tables.filter(t=>(t.state==='waiting'||t.state==='ready')&&t.order&&t.order.id===G.held.id);
  if(matches.length===1){
    // single match — auto-deliver immediately, no second click needed
    deliverTo(matches[0].idx);
  } else if(matches.length>1){
    addLog(`Picked up ${G.held.em} ${G.held.nm} — click a seat to serve!`,'i');
    rQueue();rTables();
  } else {
    addLog(`Picked up ${G.held.em} ${G.held.nm} — no one waiting for this!`,'i');
    G.held=null;
    rQueue();rTables();
  }
}

function deliverTo(idx){
  const t=G.tables[idx];if(!t)return;
  if(!G.held){addLog('Pick up a dish from the queue first!','i');return;}
  if(t.state!=='ready'&&t.state!=='waiting'){addLog('No one waiting at that table.','i');return;}
  if(t.order.id!==G.held.id){addLog(`Wrong drink! ${t.custNm} wants ${t.order.em} ${t.order.nm}.`,'m');return;}
  deliverItemToTable(G.held,idx);
}

/* Core delivery logic, shared by manual deliverTo() (player picks up +
   clicks a table) and the auto-Waiter (tryAutoServe), which calls this
   directly without needing G.held to be set first. */
function deliverItemToTable(item,idx){
  const t=G.tables[idx];if(!t)return false;
  if(t.state!=='ready'&&t.state!=='waiting')return false;
  if(!t.order||t.order.id!==item.id)return false;
  const readyIdx=G.ready.indexOf(item);
  if(readyIdx>=0)G.ready.splice(readyIdx,1);
  let earned=item.price;
  {
    let mult=1;
    if(UPGRADES.tipjar.done)mult*=1.15;
    if(UPGRADES.dailyspecial.done)mult*=1.15;
    if(UPGRADES.comboplate.done)mult*=1.12;
    if(UPGRADES.omakase.done)mult*=1.15;
    if(UPGRADES.garlicknot.done)mult*=1.12;
    if(UPGRADES.thali.done)mult*=1.15;
    if(UPGRADES.punchcard.done)mult*=1.15;
    if(mult>1)earned=Math.round(earned*mult);
  }
  earned=Math.round(earned*repMult());
  // Prestige bonus: +20% per prestige level
  if(G.prestige>0)earned=Math.round(earned*(1+G.prestige*0.2));

  // ── Regulars: record visit + apply loyalty tip bonus ──
  {
    const nm=t.custNm;
    if(!G.regulars[nm]){
      // First time seeing this customer — give them a consistent look
      G.regulars[nm]={
        visits:0,favId:null,orders:{},
        skinCol:t.skinCol,shirtCol:t.shirtCol,hairCol:t.hairCol,
        tipBonus:1
      };
    }
    const reg=G.regulars[nm];
    reg.visits++;
    reg.orders[t.order.id]=(reg.orders[t.order.id]||0)+1;
    // Update favourite (most-ordered item that still exists in the menu)
    const favId=Object.keys(reg.orders).sort((a,b)=>reg.orders[b]-reg.orders[a])[0];
    reg.favId=favId;
    // tipBonus scales with visits: 1.0 → 1.05 → 1.10 → 1.20 (VIP)
    if(reg.visits>=10) reg.tipBonus=1.20;
    else if(reg.visits>=REGULAR_THRESHOLD) reg.tipBonus=1.10+(reg.visits-REGULAR_THRESHOLD)*0.01;
    // Apply bonus
    if(reg.visits>=REGULAR_THRESHOLD){
      earned=Math.round(earned*reg.tipBonus);
    }
    // Milestone messages
    if(reg.visits===REGULAR_THRESHOLD){
      addLog(`${nm} is now a regular! They'll be back. ☕`,'s');
    } else if(reg.visits===10){
      addLog(`★ ${nm} is now a VIP! Top-tier loyalty. 👑`,'s');
    }
  }
  if(G.held===item)G.held=null;
  G.money+=earned;G.ds+=earned;G.totalEarned+=earned;G.served++;
  G.rep=Math.min(5,G.rep+(t.order.rep>=3?0.4:0.2));
  // Smoothed $/sec estimate, used to project earnings while the player is away.
  // Gaps over 20s (idle, away, just logged in) aren't counted as "active pace".
  const _nowTs=Date.now();
  if(G.lastEarnTs){
    const _dtSec=(_nowTs-G.lastEarnTs)/1000;
    if(_dtSec>0&&_dtSec<=20){
      const _instRate=earned/Math.max(_dtSec,0.1);
      G.earnRateEWMA=G.earnRateEWMA?(G.earnRateEWMA*0.8+_instRate*0.2):_instRate;
    }
  }
  G.lastEarnTs=_nowTs;
  t.state='eating';t.eatMs=0;t.maxEatMs=(5+Math.random()*5)*1000*eatMult();
  addLog(`${t.custNm} served ${t.order.em} · +$${earned.toFixed(2)}`,'s');
  spawnAssistant(idx);
  if(WORLDS[G.worldIdx]&&WORLDS[G.worldIdx].truckScroll){
    const waveSize=tableCount();
    G.truckWaveServed=(G.truckWaveServed||0)+1;
    if(G.truckWaveServed>=waveSize){
      G.truckWaveServed=0;
      addLog(`🚚 That line's done — next group of ${waveSize} rolling up!`,'i');
      G.cT=spawnSecs(); // next line starts arriving right away
    }
  }
  document.getElementById('dS').textContent='$'+G.ds.toFixed(2);
  document.getElementById('dC').textContent=G.served;
  document.getElementById('mn').textContent='$'+G.money.toFixed(2);
  updateRep();rQueue();rKitchen();rTables();rRegulars();
  checkWorldProgress();
  return true;
}

function updateRep(){
  const r=Math.round(G.rep);
  document.getElementById('dR').textContent='★'.repeat(r)+'☆'.repeat(5-r);
  const lbl=document.getElementById('dRLabel');
  if(lbl){
    const pct=Math.round((repMult()-1)*100);
    lbl.textContent=pct===0?'REPUTATION':`REPUTATION ${pct>0?'+':''}${pct}%`;
  }
}

function endDay(){
  G.open=false;
  const el=document.getElementById('st');el.textContent='CLOSED';el.className='cst';
  showSummary();
}

// ===== HOTEL TYCOON =====
// After the restaurant closes each day, the player runs a hotel next door.
// Guests arrive, want rooms assigned, pay per night. Upgrades improve
// the hotel tier, capacity, and revenue.

const HOTEL_GUESTS=[
  'Mr. Kim','The Johnsons','Lady Vera','Prof. Osei','Ms. Park','The Nguyens',
  'Baron Holt','Biz Traveler','Honeymooners','Dr. Cruz','Tour Group A','CEO Webb',
  'Ms. Tanaka','The Garcias','Count Leo','Backpacker Sam','VIP Suite Guest','Mr. Adebayo'
];
const HOTEL_ROOMS=[
  {id:'standard',nm:'Standard Room',   em:'🛏',basePrice:45, time:8000},
  {id:'deluxe',  nm:'Deluxe Room',     em:'🛎',basePrice:75, time:10000},
  {id:'suite',   nm:'Suite',           em:'🌟',basePrice:120,time:14000},
  {id:'penthouse',nm:'Penthouse',      em:'💎',basePrice:200,time:18000},
];

// Hotel state (lives alongside G)
const H={
  rooms:[],        // {id, type, state:'vacant'|'occupied'|'checkout', guest, checkInMs, stayMs, earned}
  queue:[],        // guests waiting for a room
  totalEarned:0,
  open:false,
  frame:0,
  spawnCooldown:false,
  spawnTimer:0,
};

const HOTEL_UPGRADES={
  lobby:   {nm:'Grand Lobby',      cost:300, ds:'Guests arrive 30% faster',done:false},
  bellhop: {nm:'Hire Bellhop',     cost:400, ds:'Auto-assigns waiting guests to vacant rooms',done:false},
  minibar: {nm:'Minibar',          cost:350, ds:'+20% revenue on all room types',done:false},
  pool:    {nm:'Rooftop Pool',     cost:600, ds:'+30% revenue on all room types',done:false},
  concierge:{nm:'Concierge Desk',  cost:800, ds:'Guests check out 25% faster (room turns over sooner)',done:false},
  spa:     {nm:'Spa & Wellness',   cost:1000,ds:'+25% revenue on all room types'},
  valet:   {nm:'Valet Parking',    cost:500, ds:'Guests arrive even faster'},
};

/* ===== HOTEL LOBBY VISUALS (canvas) =====
   A modern boutique hotel lobby — concrete floors, muted sage/teal walls,
   white-oak doors, soft warm pendant lighting, low modular sofas, and a
   minimal plywood reception desk. No marble, no gold, no red carpet. */
const HOTEL_PAL={
  wall:'#2a3530',wallAlt:'#263230',wallAccent:'#1e2a26',
  trim:'#8ab5a0',trimDark:'#5a8870',
  floor1:'#3a3a3a',floor2:'#353535',floorGrout:'#2a2a2a',
  carpet:'#4a6660',carpetEdge:'#3d5650',carpetTrim:'#8ab5a0',
  desk:'#c8b89a',deskTop:'#d8c8aa',deskFront:'#b8a88a',
  door:'#d4c4a8',doorFrame:'#a89878',doorPanel:'#c8b898',doorGlass:'#a0c4b8',
  sofa:'#4a5e58',sofaLight:'#5a7068',sofaLeg:'#8a7858',
  accent:'#e8b870',accentDim:'#c09050'
};
// Precomputed scatter points for subtle concrete texture
const HOTEL_VEIN_PTS=(()=>{
  const gw=Math.ceil(CW/S),gh=Math.ceil(CH/S);
  const pts=[];
  for(let i=0;i<60;i++)pts.push({x:(i*41+7)%gw,y:(i*53+11)%gh});
  return pts;
})();

function drawHotelFloor(){
  const gw=Math.ceil(CW/S),gh=Math.ceil(CH/S);
  // polished concrete — large tiles with grout lines every 8px
  for(let y=0;y<gh;y++)for(let x=0;x<gw;x++){
    const tileX=Math.floor(x/8),tileY=Math.floor(y/8);
    const onGrout=(x%8===0||y%8===0);
    px(x,y,1,1,onGrout?HOTEL_PAL.floorGrout:(tileX+tileY)%2===0?HOTEL_PAL.floor1:HOTEL_PAL.floor2);
  }
  // subtle texture dots
  HOTEL_VEIN_PTS.forEach(p=>px(p.x,p.y,1,1,'rgba(255,255,255,0.04)'));
  // centre runner strip — muted teal, no border fuss
  const rW=28,rX=Math.round(gw/2)-Math.round(rW/2);
  for(let y=0;y<gh;y++)px(rX,y,rW,1,(y%4<2)?HOTEL_PAL.carpet:HOTEL_PAL.carpetEdge);
}

// Top zone: clean flat wall, floor-to-ceiling sliding glass door,
// pendant lights, low modular sofa, and a big monstera plant.
function drawHotelLounge(frame){
  const gw=Math.ceil(CW/S);
  const entH=30;

  // flat sage/teal back wall
  for(let x=0;x<gw;x++)px(x,0,1,entH,HOTEL_PAL.wall);
  // subtle horizontal stripe texture
  for(let y=2;y<entH-2;y+=4)for(let x=0;x<gw;x++)px(x,y,1,1,HOTEL_PAL.wallAccent);
  // thin accent strip at top
  for(let x=0;x<gw;x++)px(x,0,1,2,HOTEL_PAL.trim);

  // sliding glass entrance — full height, frameless look
  const doorCx=Math.round(gw/2);
  const doorW=44,doorX=doorCx-doorW/2,doorY=2,doorH=24;
  px(doorX,doorY,doorW,doorH,HOTEL_PAL.doorGlass);
  // vertical divider
  px(doorX+doorW/2-1,doorY,2,doorH,'rgba(255,255,255,0.15)');
  // horizontal reflections
  for(let dy=doorY+4;dy<doorY+doorH;dy+=7)px(doorX+2,dy,doorW-4,1,'rgba(255,255,255,0.08)');
  // thin frame
  px(doorX-1,doorY-1,doorW+2,1,HOTEL_PAL.trim);
  px(doorX-1,doorY+doorH,doorW+2,1,HOTEL_PAL.trim);
  // door handles — small horizontal bars
  px(doorX+doorW/2-7,doorY+doorH-9,5,2,HOTEL_PAL.trimDark);
  px(doorX+doorW/2+2,doorY+doorH-9,5,2,HOTEL_PAL.trimDark);

  // 3 pendant lights hanging from ceiling
  const twinkle=Math.floor(frame/18)%3;
  [Math.round(gw*0.25),Math.round(gw*0.5),Math.round(gw*0.75)].forEach((px2,i)=>{
    const lit=(i+twinkle)%3!==2;
    px(px2,0,1,8,'#3a3030');          // cord
    px(px2-2,8,5,4,'#2a2828');        // shade (cylinder)
    px(px2-3,12,7,2,'#1e1e1e');
    px(px2-1,9,3,5,lit?HOTEL_PAL.accent:HOTEL_PAL.accentDim); // warm glow inside
  });

  // low modular sofa — L-shape, charcoal/slate
  const sofaY=entH-11;
  px(4,sofaY,22,8,HOTEL_PAL.sofa);
  px(4,sofaY,22,2,HOTEL_PAL.sofaLight);     // seat highlight
  px(4,sofaY-5,4,13,HOTEL_PAL.sofa);        // back arm
  px(22,sofaY-5,4,5,HOTEL_PAL.sofa);        // side arm
  px(5,sofaY+8,3,2,HOTEL_PAL.sofaLeg);px(19,sofaY+8,3,2,HOTEL_PAL.sofaLeg);
  // coffee table — small white rectangle
  px(10,sofaY+3,10,4,'#c8c4bc');
  px(10,sofaY+3,10,1,'#e8e4dc');
  // magazine on table
  px(12,sofaY+3,5,2,'#e05858');

  // big monstera plant, left corner
  const plantX=1,plantY=entH-16;
  px(plantX+3,plantY+9,4,7,'#5a4a38');    // pot
  px(plantX+2,plantY+9,6,2,'#6a5a48');
  px(plantX+4,plantY+2,2,8,'#3a6040');    // main stem
  // leaves
  px(plantX,plantY-1,8,6,'#2a7a48');
  px(plantX+6,plantY+1,7,5,'#348050');
  px(plantX-1,plantY+4,6,5,'#2e7044');
  px(plantX+5,plantY+5,6,4,'#3a7850');
  // leaf splits (darker notches)
  px(plantX+4,plantY+1,1,4,'#1a4a28');
  px(plantX+9,plantY+3,1,3,'#1a4a28');

  // luggage trolley, right side — minimal chrome frame
  const cartX=gw-28,cartY=entH-12;
  px(cartX,cartY+7,18,2,'#9a9a9a');       // top bar
  px(cartX,cartY+9,2,4,'#7a7a7a');px(cartX+16,cartY+9,2,4,'#7a7a7a'); // legs
  px(cartX+2,cartY+2,8,6,'#c8c0b0');      // bag 1
  px(cartX+2,cartY+2,8,1,'#e0d8c8');
  px(cartX+11,cartY-1,8,9,'#8a98b0');     // bag 2 (navy)
  px(cartX+11,cartY-1,8,2,'#a0aec0');

  // divider line
  for(let x=0;x<gw;x++)px(x,entH-1,1,2,HOTEL_PAL.trim);
}

// Bottom zone: minimal plywood reception desk, slim modern staff,
// tablet on counter, and a fiddle-leaf fig behind.
function drawHotelDesk(frame){
  const gw=Math.ceil(CW/S),gh=Math.ceil(CH/S);
  const deskH=34,deskZoneY=gh-deskH;

  // divider accent line
  for(let x=0;x<gw;x++)px(x,deskZoneY,1,2,HOTEL_PAL.trim);
  // back wall — same sage as top
  for(let y=deskZoneY+2;y<gh;y++)for(let x=0;x<gw;x++)
    px(x,y,1,1,(y%4<2)?HOTEL_PAL.wall:HOTEL_PAL.wallAccent);

  // simple key/slot display behind desk — thin grid, no ornate cubbies
  const keyWallX=Math.round(gw/2)-36,keyWallY=deskZoneY+4;
  for(let col=0;col<9;col++){
    const bx=keyWallX+col*8;
    px(bx,keyWallY,6,12,'#1e2a26');
    px(bx,keyWallY,6,1,HOTEL_PAL.wallAccent);
    // key fob — only some slots occupied
    if(col%3!==0)px(bx+2,keyWallY+4,2,4,HOTEL_PAL.accent);
  }
  // label strip above
  px(keyWallX,keyWallY-2,73,2,HOTEL_PAL.trimDark);

  // reception counter — plywood look (warm sand tone, clean)
  const deskX=6,deskY2=gh-14,deskW=gw-12;
  px(deskX,deskY2,deskW,12,HOTEL_PAL.desk);
  px(deskX,deskY2,deskW,2,HOTEL_PAL.deskTop);      // top surface highlight
  px(deskX,deskY2+2,deskW,1,'rgba(0,0,0,0.1)');
  // wood-grain lines
  for(let x=deskX+6;x<deskX+deskW;x+=10)px(x,deskY2,1,12,'rgba(0,0,0,0.07)');
  // front panel
  px(deskX,deskY2+2,deskW,10,HOTEL_PAL.deskFront);

  // STAFF — casual modern look: t-shirt, relaxed posture
  const sx=Math.round(gw/2)-7;
  const bob=Math.floor(frame/16)%2;
  const cy=deskZoneY+13+bob;
  // hair
  px(sx+2,cy-5,10,4,'#3a2a1a');
  px(sx+3,cy-4,8,2,'#4a3828');
  // face
  px(sx+1,cy,12,7,'#f0c8a0');
  px(sx+3,cy+3,2,1,'#241433');px(sx+8,cy+3,2,1,'#241433');
  px(sx+5,cy+5,4,1,'#c87040');
  // t-shirt (muted teal/slate)
  px(sx-1,cy+7,16,10,'#5a7068');
  px(sx-1,cy+7,16,2,'#6a8078');
  // arms
  const wave=Math.floor(frame/18)%2;
  px(sx-4,cy+9,4,6,'#5a7068');
  px(sx+13,cy+(wave?7:9),4,6,'#5a7068');
  px(sx+14,cy+(wave?5:8),3,3,'#f0c8a0');  // waving hand

  // tablet on desk — modern touch
  const tabX=sx+18,tabY=deskY2-4;
  px(tabX,tabY,8,6,'#2a2e30');
  px(tabX+1,tabY+1,6,4,'#3a8888');    // screen glow
  px(tabX+2,tabY+2,4,1,'rgba(255,255,255,0.3)');

  // small cactus on desk, left side
  const cacX=deskX+14,cacY=deskY2-6;
  px(cacX+1,cacY+3,4,6,'#3a7040');
  px(cacX,cacY+3,2,3,'#3a7040');
  px(cacX+4,cacY+4,2,3,'#3a7040');
  px(cacX+1,cacY+2,4,2,'#4a8050');
  px(cacX,cacY+9,6,3,'#8a6a48');   // tiny pot

  // fiddle-leaf fig behind counter, right side
  const figX=gw-14,figY=deskZoneY+4;
  px(figX+2,figY+10,4,8,'#5a4a38');
  px(figX+3,figY+3,2,8,'#3a6040');
  px(figX-1,figY,8,5,'#2a7848');
  px(figX+4,figY+2,7,5,'#308050');
  px(figX,figY+6,8,4,'#2a7040');
  px(figX+5,figY+8,7,4,'#358048');
  px(figX+1,figY+1,1,3,'#1a4a28');
  px(figX+7,figY+4,1,3,'#1a4a28');
}

// Middle zone: white-oak flat-panel room doors with a small round LED
// status indicator above each one. No heavy gold frames — just a thin
// inset shadow border.
function drawHotelDoors(frame){
  if(!H.rooms||!H.rooms.length)return;
  const gw=Math.ceil(CW/S);
  const doorW=28,doorH=48,gap=16;
  const totalW=H.rooms.length*doorW+(H.rooms.length-1)*gap;
  const startX=Math.round((gw-totalW)/2);
  const doorTopY=40;

  // Lobby centre — where guests start their walk (queue area)
  const lobbyCx=Math.round(gw/2);
  const lobbyY=116; // just above the desk zone

  H.rooms.forEach((r,i)=>{
    const dx=startX+i*(doorW+gap),dy=doorTopY;
    const isEntering=r.state==='walking'&&r.walkAnim&&r.walkAnim.entering;

    // door shadow/border
    px(dx-1,dy-1,doorW+2,doorH+2,'#1e2018');
    // door face — flash lighter when guest enters
    const doorCol=isEntering?'#eee8d8':HOTEL_PAL.door;
    px(dx,dy,doorW,doorH,doorCol);
    // inset panel
    px(dx+3,dy+4,doorW-6,doorH-20,isEntering?'#e0d8c0':HOTEL_PAL.doorPanel);
    px(dx+3,dy+4,doorW-6,1,'rgba(255,255,255,0.2)');
    // door number plate
    px(dx+doorW/2-3,dy+doorH-13,6,4,'#d0c0a0');
    px(dx+doorW/2-2,dy+doorH-12,4,2,'#a89878');
    // handle
    px(dx+doorW-7,dy+doorH/2-1,3,3,HOTEL_PAL.trimDark);

    // LED status dot
    let ledCol='#3a3a3a';
    if(r.state==='walking') ledCol='#f0c030'; // amber = incoming
    if(r.state==='occupied') ledCol='#50c878';
    if(r.state==='checkout'){
      const blink=Math.floor(frame/8)%2;
      ledCol=blink?'#f0a030':'#7a5010';
    }
    px(dx+doorW/2-1,dy-8,3,3,ledCol);

    // ── WALKING ANIMATION ──
    if(r.state==='walking'&&r.walkAnim&&!r.walkAnim.entering){
      const t=r.walkAnim.progress; // 0→1
      // destination: just in front of the door
      const destX=dx+doorW/2-3;
      const destY=dy+doorH+2;
      // source: lobby centre (queue line)
      const srcX=lobbyCx-3;
      const srcY=lobbyY;
      // ease-in-out
      const et=t<0.5?2*t*t:1-Math.pow(-2*t+2,2)/2;
      const gx=Math.round(srcX+(destX-srcX)*et);
      const gy=Math.round(srcY+(destY-srcY)*et);
      const bob=Math.floor((frame+i*7)/8)%2; // faster walk bob
      const hair=r.walkAnim.hair;
      const shirt=r.walkAnim.shirt;
      px(gx+1,gy+bob,4,3,hair);
      px(gx,gy+3+bob,6,4,'#f0c8a0');
      px(gx-1,gy+6+bob,8,5,shirt);
      px(gx,gy+11,3,3,'#2a1a10');px(gx+4,gy+11,3,3,'#2a1a10');
      // small suitcase bobbing alongside
      px(gx+7,gy+7+bob,5,5,'#7a6050');
      px(gx+7,gy+7+bob,5,1,'#9a8070');
      px(gx+8,gy+12,4,1,'#5a4838');
    }

    // ── STANDING OUTSIDE DOOR (occupied/checkout) ──
    if(r.state==='occupied'||r.state==='checkout'){
      const gx=dx+doorW/2-3,gy=dy+doorH+3;
      const bob=Math.floor((frame+i*7)/10)%2;
      px(gx+1,gy+bob,4,3,HAIR_COLS[i%HAIR_COLS.length]);
      px(gx,gy+3+bob,6,4,'#f0c8a0');
      px(gx-1,gy+6+bob,8,5,SHIRT_COLS[i%SHIRT_COLS.length]);
      px(gx,gy+11,3,3,'#2a1a10');px(gx+4,gy+11,3,3,'#2a1a10');
    }
  });
}

// Guests waiting in line for a room — replaces restaurant queue markers.
function drawHotelQueueGuests(frame){
  if(!H.queue||!H.queue.length)return;
  const gw=Math.ceil(CW/S);
  const qY=118;
  const startX=Math.round(gw/2)-Math.round(H.queue.length*16/2);
  H.queue.forEach((g,i)=>{
    const gx=startX+i*16,gy=qY;
    const bob=Math.floor((frame+i*5)/12)%2;
    px(gx+1,gy+bob,4,3,HAIR_COLS[(i+1)%HAIR_COLS.length]);
    px(gx,gy+3+bob,6,4,'#f0c8a0');
    px(gx+1,gy+5+bob,1,1,'#241433');px(gx+4,gy+5+bob,1,1,'#241433');
    px(gx-1,gy+6+bob,8,5,SHIRT_COLS[(i+2)%SHIRT_COLS.length]);
    px(gx,gy+11,3,3,'#2a1a10');px(gx+5,gy+11,3,3,'#2a1a10');
    px(gx+8,gy+8+bob,4,4,'#7a4020');
  });
}

function hotelRoomCount(){
  return 4; // always 4 rooms in the hotel for now
}

function hotelRevMult(){
  let m=1;
  if(HOTEL_UPGRADES.minibar.done)m*=1.2;
  if(HOTEL_UPGRADES.pool.done)m*=1.3;
  if(HOTEL_UPGRADES.spa&&HOTEL_UPGRADES.spa.done)m*=1.25;
  return m;
}

function hotelSpawnSecs(){
  let s=12;
  if(HOTEL_UPGRADES.lobby.done)s*=0.7;
  if(HOTEL_UPGRADES.valet&&HOTEL_UPGRADES.valet.done)s*=0.75;
  return Math.max(4,s);
}

function hotelStayMult(){
  let m=1;
  if(HOTEL_UPGRADES.concierge.done)m*=0.75;
  return m;
}

function initHotel(){
  H.rooms=[];
  for(let i=0;i<hotelRoomCount();i++){
    H.rooms.push({id:i,type:HOTEL_ROOMS[Math.floor(Math.random()*2)],state:'vacant',guest:'',checkInMs:0,stayMs:0,earned:0,walkAnim:null});
  }
  H.queue=[];H.open=true;H.totalEarned=0;H.spawnCooldown=false;H.spawnTimer=0;
}

function assignRoom(roomId){
  const room=H.rooms[roomId];
  if(room.state!=='vacant'){addLog('That room is occupied!','m');return;}
  if(!H.queue.length){addLog('No guests waiting for a room.','i');return;}
  const guest=H.queue.shift();
  const stayMs=Math.round(room.type.time*hotelStayMult()/G.spd);
  room.state='walking'; // intermediate state during walk-in animation
  room.guest=guest.nm;
  room.checkInMs=0; // will be set when walk completes
  room.stayMs=stayMs;
  room.earned=0;
  // Pick stable colours for this guest (reuse index based on roomId)
  const hIdx=roomId%HAIR_COLS.length, sIdx=roomId%SHIRT_COLS.length;
  room.walkAnim={progress:0, hair:HAIR_COLS[hIdx], shirt:SHIRT_COLS[sIdx]};
  addLog(`🛎 ${guest.nm} checked into ${room.type.em} ${room.type.nm}!`,'s');
  rHotel();
}

function checkoutRoom(roomId){
  const room=H.rooms[roomId];
  if(room.state!=='checkout'){return;}
  const earned=Math.round(room.type.basePrice*hotelRevMult());
  G.money+=earned;H.totalEarned+=earned;
  addLog(`${room.guest} checked out · +$${earned.toFixed(2)}`,'s');
  room.state='vacant';room.guest='';
  document.getElementById('mn').textContent='$'+G.money.toFixed(2);
  rHotel();
}

function upgradeHotelRoom(roomId){
  const room=H.rooms[roomId];
  if(room.state!=='vacant')return;
  const cur=HOTEL_ROOMS.indexOf(room.type);
  if(cur<0||cur>=HOTEL_ROOMS.length-1){addLog('Already max tier!','i');return;}
  const next=HOTEL_ROOMS[cur+1];
  const upgCost=next.basePrice*2;
  if(G.money<upgCost){addLog(`Need $${upgCost} to upgrade to ${next.nm}.`,'m');return;}
  G.money-=upgCost;
  room.type=next;
  addLog(`Room ${roomId+1} upgraded to ${next.em} ${next.nm}!`,'u');
  document.getElementById('mn').textContent='$'+G.money.toFixed(2);
  rHotel();
}

let hotelTick;
// Toggles the whole UI between the restaurant theme and a completely
// different gold/maroon hotel theme (panels, buttons, header all reskin
// via CSS variables on body.hotelTheme).
function setHotelTheme(on){
  document.body.classList.toggle('hotelTheme',on);
  const titleEl=document.getElementById('worldTitle');
  if(on){
    if(titleEl)titleEl.textContent='🏨 PIXEL HOTEL 🏨';
  } else if(titleEl){
    applyWorld(G.worldIdx); // restores restaurant title + panel labels
  }
}
function startHotel(){
  G.hotelMode=true;
  initHotel();
  setHotelTheme(true);
  addLog('🏨 Hotel is now open for check-ins! Assign rooms to waiting guests.','i');
  const stEl=document.getElementById('st');stEl.textContent='🏨 HOTEL';stEl.className='ost bl';
  // Show hotel UI in left panel
  const kL=document.getElementById('kitchenLabel');
  if(kL)kL.textContent='HOTEL ROOMS';
  const rL=document.getElementById('readyLabel');
  if(rL)rL.textContent='GUEST QUEUE';
  const dL=document.getElementById('diningLabel');
  if(dL)dL.textContent='HOTEL UPGRADES';
  document.getElementById('kv').innerHTML='';
  document.getElementById('qv').innerHTML='';
  document.getElementById('tv').innerHTML='';
  rHotel();
  hotelTick=setInterval(tickHotel,500);
}

function stopHotel(){
  clearInterval(hotelTick);
  G.hotelMode=false;
  H.open=false;
  setHotelTheme(false);
  // collect any remaining checkouts
  H.rooms.forEach(r=>{if(r.state==='checkout')checkoutRoom(r.id);});
}

function tickHotel(){
  if(!H.open)return;
  H.frame++;
  const now=Date.now();

  // Advance walk-in animations
  H.rooms.forEach(r=>{
    if(r.state==='walking'&&r.walkAnim){
      r.walkAnim.progress+=0.06*G.spd; // ~17 ticks = ~8.5s at 1x, or tune with G.spd
      if(r.walkAnim.progress>=1){
        r.walkAnim.progress=1;
        r.walkAnim.entering=true; // door-open flash frame
        // Complete check-in after a brief door-flash delay
        setTimeout(()=>{
          r.state='occupied';
          r.checkInMs=Date.now();
          r.walkAnim=null;
          rHotel();
        },300/G.spd);
      }
    }
  });

  // Advance room stays
  H.rooms.forEach(r=>{
    if(r.state==='occupied'){
      const elapsed=(now-r.checkInMs)*G.spd;
      if(elapsed>=r.stayMs){
        r.state='checkout';
        addLog(`🔔 ${r.guest} is ready to check out!`,'i');
      }
    }
  });
  // Auto check-in: always assign waiting guests to vacant rooms (free, no upgrade needed)
  if(H.queue.length){
    const vacant=H.rooms.find(r=>r.state==='vacant');
    if(vacant)assignRoom(vacant.id);
  }
  // Spawn new guests
  H.spawnTimer+=0.5*G.spd;
  if(!H.spawnCooldown&&H.spawnTimer>=hotelSpawnSecs()&&H.queue.length<4){
    H.spawnTimer=0;
    const nm=HOTEL_GUESTS[Math.floor(Math.random()*HOTEL_GUESTS.length)];
    const pref=HOTEL_ROOMS[Math.min(Math.floor(Math.random()*3),HOTEL_ROOMS.length-1)];
    H.queue.push({nm,pref});
    addLog(`${nm} arrived — wants a ${pref.em} ${pref.nm}!`,'i');
    H.spawnCooldown=true;
    setTimeout(()=>{H.spawnCooldown=false;},3000/G.spd);
  }
  // Hotel session lasts 3 hours (until 3am / tm=27*60 in game time)
  // We run it for 90 real seconds at 1x speed
  if(H.frame>=180){ // 180 * 500ms = 90s at 1x
    H.open=false;
    clearInterval(hotelTick);
    addLog('🏨 Hotel closes for the night. Good work!','i');
    showHotelSummary();
  }
  rHotel();
}

function rHotel(){
  // Render rooms into kv panel
  const roomsHtml=H.rooms.map(r=>{
    const pct=r.state==='occupied'?Math.min(100,Math.round((Date.now()-r.checkInMs)*G.spd/r.stayMs*100)):0;
    const earns=Math.round(r.type.basePrice*hotelRevMult());
    if(r.state==='vacant'){
      const upgCur=HOTEL_ROOMS.indexOf(r.type);
      const canUpg=upgCur<HOTEL_ROOMS.length-1;
      const upgNext=canUpg?HOTEL_ROOMS[upgCur+1]:null;
      const upgCost=upgNext?upgNext.basePrice*2:0;
      return`<div class="cookSlot">
        <div>${r.type.em} Room ${r.id+1} · ${r.type.nm} <span style="color:var(--color-text-secondary);float:right;font-size:14px">$${earns}/stay</span></div>
        <div style="color:var(--color-text-secondary);font-size:14px">VACANT</div>
        <div style="display:flex;gap:4px;margin-top:4px">
          <button class="rushBtn" onclick="assignRoom(${r.id})" style="flex:2">🛎 CHECK IN GUEST</button>
          ${canUpg?`<button class="rushBtn" onclick="upgradeHotelRoom(${r.id})" style="flex:1;border-color:var(--color-text-secondary)">⬆ $${upgCost}</button>`:''}
        </div>
      </div>`;
    } else if(r.state==='walking'){
      const wpct=Math.round((r.walkAnim?r.walkAnim.progress:0)*100);
      return`<div class="cookSlot" style="border-color:var(--color-text-success)">
        <div>${r.type.em} Room ${r.id+1} · ${r.type.nm}</div>
        <div>${r.guest} — <span style="color:var(--color-text-success)">🚶 heading to room…</span></div>
        <div class="sbb"><div class="sbf" style="width:${wpct}%;background:var(--color-text-success)"></div></div>
      </div>`;
    } else if(r.state==='occupied'){
      return`<div class="cookSlot">
        <div>${r.type.em} Room ${r.id+1} · ${r.type.nm} <span style="color:var(--color-text-secondary);float:right;font-size:14px">${pct}%</span></div>
        <div>${r.guest} — checking out soon</div>
        <div class="sbb"><div class="sbf" style="width:${pct}%;background:#5533aa"></div></div>
      </div>`;
    } else {
      return`<div class="cookSlot" style="border-color:var(--color-text-warning)">
        <div>${r.type.em} Room ${r.id+1} · ${r.type.nm}</div>
        <div>${r.guest} — <span style="color:var(--color-text-warning)">READY TO CHECK OUT</span></div>
        <button class="rushBtn" onclick="checkoutRoom(${r.id})" style="margin-top:4px;border-color:var(--color-text-warning);color:var(--color-text-warning)">💰 COLLECT $${earns}</button>
      </div>`;
    }
  }).join('');
  document.getElementById('kv').innerHTML=`<div style="font-size:14px;color:var(--color-text-secondary);margin-bottom:6px">Hotel earnings tonight: <b style="color:var(--color-text-primary)">$${H.totalEarned.toFixed(2)}</b></div>`+roomsHtml;

  // Render guest queue into qv
  if(!H.queue.length){
    document.getElementById('qv').innerHTML=`<span style="color:var(--color-text-secondary);font-size:15px">Waiting for guests...</span>`;
  } else {
    document.getElementById('qv').innerHTML=H.queue.map((g,i)=>
      `<span class="qchip">${g.nm} · ${g.pref.em}</span>`
    ).join('');
  }

  // Render hotel upgrades into tv
  document.getElementById('tv').innerHTML=
    Object.entries(HOTEL_UPGRADES).map(([k,u])=>{
      if(!u.cost)return'';
      const canBuy=!u.done&&G.money>=u.cost;
      return`<button class="ub${u.done?' bgt':''}" onclick="buyHotelUpgrade('${k}')" ${(!canBuy&&!u.done)?'disabled':''}><div>${u.nm}<span style="color:var(--color-text-secondary);float:right;font-size:15px">${u.done?'✓ done':'$'+u.cost}</span></div><div style="color:var(--color-text-secondary);font-size:15px">${u.ds}</div></button>`;
    }).join('');
}

function buyHotelUpgrade(k){
  const u=HOTEL_UPGRADES[k];
  if(!u||u.done||G.money<u.cost)return;
  G.money-=u.cost;u.done=true;
  addLog(`Hotel upgrade: ${u.nm}!`,'u');
  document.getElementById('mn').textContent='$'+G.money.toFixed(2);
  rHotel();
}

function showHotelSummary(){
  const overlay=document.createElement('div');
  overlay.id='summaryOverlay';
  overlay.className='adminOverlay';
  overlay.innerHTML=`
    <div class="adminBox" style="text-align:center;max-width:360px">
      <div class="adminTitle">🏨 HOTEL CLOSES</div>
      <div style="margin:10px 0;font-size:20px">HOTEL REVENUE<br><span class="gm" style="font-size:28px">$${H.totalEarned.toFixed(2)}</span></div>
      <div style="margin:8px 0;font-size:15px;color:var(--color-text-secondary)">Rooms occupied, guests served, money made.</div>
      <button class="loginBtn" id="newDayBtn" style="font-size:20px;margin-top:12px">☀ NEXT DAY →</button>
    </div>`;
  document.body.appendChild(overlay);
  document.getElementById('newDayBtn').addEventListener('click',()=>{
    overlay.remove();
    stopHotel();
    newDay();
  });
}

function showSummary(){
  // Find top regular today (most visits overall, as a proxy for loyalty)
  const regEntries=Object.entries(G.regulars||{}).filter(([,r])=>r.visits>=REGULAR_THRESHOLD);
  regEntries.sort((a,b)=>b[1].visits-a[1].visits);
  const topReg=regEntries[0];
  const topRegLine=topReg
    ? `<div style="margin:8px 0;font-size:14px;color:var(--color-text-secondary)">
        ⭐ Most loyal regular: <b style="color:var(--color-text-primary)">${topReg[0]}</b>
        <span style="color:#f7c800">${topReg[1].visits>=10?'★VIP':''}</span>
        · ${topReg[1].visits} visits
       </div>`
    : `<div style="margin:8px 0;font-size:13px;color:var(--color-text-secondary)">No regulars yet — keep serving! ☕</div>`;

  const repStars='★'.repeat(Math.round(G.rep))+'☆'.repeat(5-Math.round(G.rep));

  const overlay=document.createElement('div');
  overlay.id='summaryOverlay';
  overlay.className='adminOverlay';
  overlay.style.cssText='animation:fadeIn 0.6s ease;';
  overlay.innerHTML=`
    <div class="adminBox" style="text-align:center;max-width:380px;padding:28px 24px">
      <div style="font-size:28px;margin-bottom:4px">🌙</div>
      <div class="adminTitle" style="margin-bottom:4px">DAY ${G.day} COMPLETE</div>
      <div style="font-size:12px;color:var(--color-text-secondary);margin-bottom:16px;letter-spacing:1px">THE SHOP IS CLOSED</div>
      <div style="background:rgba(255,255,255,0.04);border-radius:8px;padding:14px;margin-bottom:12px">
        <div style="font-size:13px;color:var(--color-text-secondary);letter-spacing:1px;margin-bottom:6px">TODAY'S SALES</div>
        <div class="gm" style="font-size:36px;letter-spacing:2px">$${G.ds.toFixed(2)}</div>
      </div>
      <div style="display:flex;gap:10px;margin-bottom:12px">
        <div style="flex:1;background:rgba(255,255,255,0.04);border-radius:8px;padding:10px">
          <div style="font-size:11px;color:var(--color-text-secondary);margin-bottom:4px">CUSTOMERS</div>
          <div style="font-size:22px;font-weight:bold">${G.served}</div>
        </div>
        <div style="flex:1;background:rgba(255,255,255,0.04);border-radius:8px;padding:10px">
          <div style="font-size:11px;color:var(--color-text-secondary);margin-bottom:4px">REPUTATION</div>
          <div style="font-size:16px" class="lw">${repStars}</div>
        </div>
      </div>
      ${topRegLine}
      <div style="margin:14px 0 18px;font-size:13px;color:var(--color-text-secondary)">
        Your hotel next door is open for the night 🏨
      </div>
      <button class="loginBtn" id="openHotelBtn" style="font-size:18px;letter-spacing:2px;width:100%">CHECK IN GUESTS →</button>
    </div>`;
  document.body.appendChild(overlay);
  document.getElementById('openHotelBtn').addEventListener('click',()=>{
    overlay.remove();
    G.puddles=[];
    startHotel();
  });
}

function newDay(){
  G.day++;G.tm=8*60;G.ds=0;G.served=0;G.open=true;G.cT=0;
  G.hotelMode=false;G.puddles=[];G.closingWarnShown=false;G.closingFade=0;
  document.body.classList.remove('hotelTheme');
  lastTick=Date.now();
  G.tables.forEach(t=>{t.state='empty';t.order=null;t.custNm='';t.eatMs=0;t.autoCooking=false;});
  G.sprites=[];G.assistants=[];G.ready=[];G.held=null;G.cookSlots=[];G.spawnCooldown=false;G.truckWaveServed=0;
  const el=document.getElementById('st');el.textContent='OPEN';el.className='ost bl';
  addLog(`--- Day ${G.day} is open! ---`,'i');
  document.getElementById('dS').textContent='$0.00';
  document.getElementById('dC').textContent='0';
  document.getElementById('dM').textContent='0';
  updateRep();rKitchen();rQueue();rTables();
}

/* ===== WORLD PROGRESSION =====
   Checked after every sale. Once money crosses the current world's
   threshold, the day pauses and the player is offered the next
   restaurant. Money, upgrades and staff all carry over — only the
   menu, customers and decor change. */
function checkWorldProgress(){ /* single world — nothing to progress to */ }

/* Welcome-back popup shown when the player returns after being away long
   enough to have earned a meaningful offline bonus (see enterGameAs). */
function showOfflineBonus(awayMs,amount){
  const hrs=Math.floor(awayMs/3600000);
  const mins=Math.floor((awayMs%3600000)/60000);
  const timeStr=hrs>0?`${hrs}h ${mins}m`:`${mins}m`;
  addLog(`🌙 Welcome back! Your restaurant earned $${amount.toFixed(2)} while you were away (${timeStr}).`,'s');
  const overlay=document.createElement('div');
  overlay.className='adminOverlay';
  overlay.innerHTML=`
    <div class="adminBox" style="text-align:center;max-width:380px">
      <div class="adminTitle">🌙 WELCOME BACK</div>
      <div style="margin:10px 0;font-size:15px;color:var(--color-text-secondary)">You were away for <b style="color:var(--color-text-primary)">${timeStr}</b>.</div>
      <div class="gm" style="margin:10px 0;font-size:30px;font-weight:bold">+$${amount.toFixed(2)}</div>
      <div style="margin-bottom:14px;font-size:13px;color:var(--color-text-secondary)">Your restaurant kept running at half pace while you were gone.</div>
      <button class="loginBtn" id="offlineBonusOk" style="font-size:16px;width:100%">Nice! Keep going →</button>
    </div>`;
  document.body.appendChild(overlay);
  document.getElementById('offlineBonusOk').addEventListener('click',()=>overlay.remove());
}

function openEvolveChoice(){ /* no other worlds */ }

function switchWorld(idx){ /* no other worlds */ }

function ft(m){const h=Math.floor(m/60)%24,mn=Math.floor(m%60),ap=h>=12?'PM':'AM',hh=h%12||12;return`${hh}:${mn.toString().padStart(2,'0')}${ap}`;}
function fd(){const h=Math.floor(G.tm/60)%24;return`${h<12?'☀':h<18?'◑':'☾'} Day ${G.day} · ${ft(G.tm)}`;}

function addLog(msg,t){
  const el=document.getElementById('lv'),d=document.createElement('div');
  d.className='l'+t;d.textContent=`[${ft(G.tm)}] ${msg}`;
  el.prepend(d);while(el.children.length>50)el.removeChild(el.lastChild);
}

function rKitchen(){
  const menuHtml=activeMenu().map(item=>{
    const secs=Math.round(item.time/cookMult());
    return`<button class="bb" onclick="startCook('${item.id}')">${item.em} ${item.nm}<span style="color:var(--color-text-secondary);float:right;font-size:15px">$${item.price} · ${secs}s</span></button>`;
  }).join('');
  const slotsHtml=G.cookSlots.length?`<div class="pt" style="margin-top:10px">COOKING (${G.cookSlots.length})</div>`+
    G.cookSlots.map(slot=>{
      const elapsed=Math.max(0,(Date.now()-slot.startedAt)*G.spd);
      const pct=slot.durMs>0?Math.min(100,Math.round(elapsed/slot.durMs*100)):100;
      const cost=rushCost(slot.item);
      return`<div class="cookSlot">
        <div>${slot.item.em} ${slot.item.nm}<span class="slotPct" data-uid="${slot.uid}" style="float:right;color:var(--color-text-secondary);font-size:14px">${pct}%</span></div>
        <div class="sbb"><div class="sbf slotBar" data-uid="${slot.uid}" style="width:${pct}%;background:var(--color-text-warning)"></div></div>
        <button class="rushBtn" onclick="rushSlot(${slot.uid})">⚡ RUSH $${cost.toFixed(2)}</button>
      </div>`;
    }).join('')
    :'';
  document.getElementById('kv').innerHTML=menuHtml+slotsHtml;
}

function rKitchenProgress(){
  // only update progress bars/percentages in place — no DOM wipe, keeps buttons clickable
  G.cookSlots.forEach(slot=>{
    const elapsed=Math.max(0,(Date.now()-slot.startedAt)*G.spd);
    const pct=slot.durMs>0?Math.min(100,Math.round(elapsed/slot.durMs*100)):100;
    const bar=document.querySelector(`.slotBar[data-uid="${slot.uid}"]`);
    const pctEl=document.querySelector(`.slotPct[data-uid="${slot.uid}"]`);
    if(bar)bar.style.width=pct+'%';
    if(pctEl)pctEl.textContent=pct+'%';
  });
}

function rQueue(){
  const el=document.getElementById('qv');
  if(!G.ready.length){el.innerHTML=`<span style="color:var(--color-text-secondary);font-size:15px">Nothing ready yet...</span>`;return;}
  el.innerHTML=G.ready.map((item,idx)=>`<span class="qchip${G.held===item?' held':''}" onclick="pickUp(${idx})">${item.em} ${item.nm}</span>`).join('');
}

function rTables(){
  const isTruck=WORLDS[G.worldIdx]&&WORLDS[G.worldIdx].truckScroll;
  const lbl=isTruck?'Spot':'Table';
  document.getElementById('tv').innerHTML=G.tables.map(t=>{
    if(t.state==='empty')return`<div class="trow tr-empty">${lbl} ${t.idx+1} — <span style="color:var(--color-text-secondary)">empty</span></div>`;
    const sp=G.sprites.find(s=>s.tableIdx===t.idx);
    const arriving=sp&&sp.walking;
    if(arriving)return`<div class="trow tr-waiting">${lbl} ${t.idx+1} · ${t.custNm} — <span style="color:var(--color-text-secondary)">walking in...</span></div>`;
    const isTarget=G.held&&(t.state==='waiting'||t.state==='ready')&&t.order&&t.order.id===G.held.id;
    const rowCls=t.state==='eating'?'tr-eating':isTarget?'tr-target':t.state==='ready'?'tr-ready':'tr-waiting';
    let label=t.state==='eating'?`sipping ${t.order.em}`:t.state==='ready'?`<span class="lw">${isTarget?'DELIVER — click here':'DRINK READY — pick it up first'}</span>`:`wants ${t.order.em} ${t.order.nm}`;
    return`<div class="trow ${rowCls}" onclick="deliverTo(${t.idx})" style="cursor:pointer"><span style="color:var(--color-text-secondary);font-size:15px">${lbl} ${t.idx+1} · ${t.custNm}</span> · ${label}</div>`;
  }).join('');
}

function rUpg(){
  document.getElementById('uv').innerHTML=Object.entries(UPGRADES).map(([k,u])=>{
    if(u.unlockWorld>G.worldIdx){
      return'';
    }
    const canBuy=!u.done&&G.money>=u.cost;
    return`<button class="ub${u.done?' bgt':''}" onclick="buyUp('${k}')" ${(!canBuy&&!u.done)?'disabled':''}><div>${u.nm}<span style="color:var(--color-text-secondary);float:right;font-size:15px">${u.done?'✓ done':'$'+u.cost}</span></div><div style="color:var(--color-text-secondary);font-size:15px">${u.ds}</div></button>`;
  }).join('');
}

function rStaff(){
  const el=document.getElementById('sv');
  if(!el)return;
  el.innerHTML=Object.entries(STAFF).map(([k,s])=>{
    if((s.unlockWorld||0)>G.worldIdx)return'';
    const locked=s.requires&&!STAFF[s.requires].done;
    const canBuy=!s.done&&!locked&&G.money>=s.cost;
    const rightLabel=s.done?'✓ hired':locked?`needs ${STAFF[s.requires].nm}`:'$'+s.cost;
    return`<button class="ub${s.done?' bgt':''}" onclick="buyStaff('${k}')" ${(!canBuy&&!s.done)?'disabled':''}><div>${s.nm}<span style="color:var(--color-text-secondary);float:right;font-size:15px">${rightLabel}</span></div><div style="color:var(--color-text-secondary);font-size:15px">${s.ds}</div></button>`;
  }).join('');
}

function buyUp(key){
  const u=UPGRADES[key];
  if(!u||u.done)return;
  if(u.unlockWorld>G.worldIdx){addLog('This upgrade is not available yet.','u');return;}
  if(G.money<u.cost){addLog(`Not enough money for ${u.nm}!`,'m');return;}
  G.money-=u.cost;
  u.done=true;
  document.getElementById('mn').textContent='$'+G.money.toFixed(2);
  addLog(`Purchased: ${u.nm} ✓`,'s');
  // Apply immediate effects that change table count
  if(key==='seat'||key==='seat2') initTables();
  rUpg();rStaff();rKitchen();rTables();
  persistCurrentProfile();
}

function buyStaff(key){
  const s=STAFF[key];
  if(!s||s.done)return;
  if((s.unlockWorld||0)>G.worldIdx){addLog('This staff member is not available yet.','u');return;}
  if(s.requires&&!STAFF[s.requires].done){addLog(`You need to ${STAFF[s.requires].nm} first.`,'u');return;}
  if(G.money<s.cost){addLog(`Not enough money to ${s.nm}!`,'m');return;}
  G.money-=s.cost;
  s.done=true;
  document.getElementById('mn').textContent='$'+G.money.toFixed(2);
  addLog(`Hired: ${s.nm} ✓`,'s');
  rStaff();rUpg();
  persistCurrentProfile();
}

function rRegulars(){
  const el=document.getElementById('regv');
  if(!el)return;
  const regs=Object.entries(G.regulars)
    .filter(([,r])=>r.visits>=REGULAR_THRESHOLD)
    .sort((a,b)=>b[1].visits-a[1].visits);
  if(!regs.length){
    el.innerHTML=`<div style="color:var(--color-text-secondary);font-size:13px">Serve customers repeatedly to build regulars.</div>`;
    return;
  }
  el.innerHTML=regs.map(([nm,r])=>{
    const isVIP=r.visits>=10;
    const badge=isVIP?'<span style="color:#f7c800;font-size:12px"> ★VIP</span>':'';
    const fav=r.favId&&MENU_IDX[r.favId]?` · fav: ${MENU_IDX[r.favId].em}`:'';
    const bonus=isVIP?'+20% tip':r.visits>=REGULAR_THRESHOLD?`+${Math.round((r.tipBonus-1)*100)}% tip`:'';
    return`<div style="display:flex;justify-content:space-between;align-items:center;padding:2px 0;border-bottom:1px solid rgba(255,255,255,0.05)">
      <span><span style="color:var(--color-text-primary)">${nm}</span>${badge}${fav}</span>
      <span style="font-size:12px;color:var(--color-text-secondary)">${r.visits}✓ <span style="color:#6ab04c">${bonus}</span></span>
    </div>`;
  }).join('');
}


function doPrestige(){ /* no other worlds */ }

function updatePrestigeBadge(){
  let badge=document.getElementById('prestigeBadge');
  if(G.prestige<=0){if(badge)badge.remove();return;}
  if(!badge){
    badge=document.createElement('span');
    badge.id='prestigeBadge';
    badge.style.cssText='font-size:13px;font-weight:700;letter-spacing:1px;padding:4px 10px;background:#6a0dad;color:#f7c800;border-radius:4px;margin-left:6px;';
    const whoEl=document.getElementById('whoAmI');
    if(whoEl)whoEl.appendChild(badge);
  }
  badge.textContent=`👑×${G.prestige} +${G.prestige*20}%`;
}

function refreshEvolveBtn(){
  // single world — hide evolve UI
  const eb=document.getElementById('evolveBtn');
  const tile=document.getElementById('evolveTile');
  if(eb)eb.style.display='none';
  if(tile)tile.style.display='none';
}

function startGame(){
  initTables();
  addLog(`Welcome to ${WORLDS[G.worldIdx].name}!`,'i');
  addLog('Brew a drink, pick it up, then click a seat to serve.','i');
  document.getElementById('dS').textContent='$'+G.ds.toFixed(2);
  document.getElementById('dC').textContent=G.served;
  document.getElementById('dM').textContent='0';
  updateRep();
  rKitchen();rQueue();rTables();rUpg();rStaff();rRegulars();
  refreshEvolveBtn();
  lastTick=Date.now();
  setInterval(tick,100);
  loop();
}

/* =====================================================================
   PROFILES + LOGIN
   This is a private, local-only game (no server). Profiles and their
   save data live in this browser's localStorage. There is no real
   network account system here — "passwords" are a light gate between
   family members on a shared computer, not real security. Don't reuse
   a password here that you use anywhere else.
   ===================================================================== */
const SAVE_KEY='pixelBistro.profiles';
const ADMIN_NAME='mzx';
const ADMIN_PASS='00415';
const SESSION_KEY='pixelBistro.session';

function loadProfiles(){
  try{return JSON.parse(localStorage.getItem(SAVE_KEY))||{};}catch(e){return{};}
}
function saveProfiles(p){
  localStorage.setItem(SAVE_KEY,JSON.stringify(p));
}
function defaultSave(){
  return{money:50,day:1,ds:0,served:0,rep:3,upgrades:{},staff:{},worldIdx:0,regulars:{}};
}

let currentProfile=null;

function renderProfileList(){
  const profiles=loadProfiles();
  const names=Object.keys(profiles);
  const el=document.getElementById('profileList');
  if(!names.length){el.innerHTML=`<div style="font-size:14px;color:var(--color-text-secondary);text-align:center">No players yet — add one below!</div>`;return;}
  el.innerHTML=names.map(n=>{
    const isAdmin=n.toLowerCase()===ADMIN_NAME;
    return`<button class="profChip" onclick="selectProfile('${n.replace(/'/g,"\\'")}')">${n}${isAdmin?'<span class="tag">ADMIN</span>':''}</button>`;
  }).join('');
}

function showErr(msg){
  document.getElementById('loginErr').textContent=msg;
}

let pendingProfileName=null;
function selectProfile(name){
  const profiles=loadProfiles();
  const rec=profiles[name];
  if(!rec){showErr('Profile not found.');return;}
  showErr('');
  if(rec.pass){
    pendingProfileName=name;
    document.getElementById('passPromptName').textContent=name;
    document.getElementById('newProfForm').style.display='none';
    document.getElementById('passPrompt').style.display='block';
    document.getElementById('passInput').value='';
    document.getElementById('passInput').focus();
  } else {
    enterGameAs(name);
  }
}

function submitPass(){
  const val=document.getElementById('passInput').value;
  const profiles=loadProfiles();
  const rec=profiles[pendingProfileName];
  if(!rec){showErr('Profile not found.');return;}
  if(val!==rec.pass){showErr('Wrong password.');return;}
  showErr('');
  enterGameAs(pendingProfileName);
}

function createProfile(){
  const name=document.getElementById('newProfName').value.trim();
  const pass=document.getElementById('newProfPass').value;
  if(!name){showErr('Enter a name.');return;}
  const profiles=loadProfiles();
  if(profiles[name]){showErr('That name is taken.');return;}
  if(name.toLowerCase()===ADMIN_NAME&&pass!==ADMIN_PASS){
    showErr(`The "${ADMIN_NAME}" name is reserved.`);return;
  }
  const save=defaultSave();
  if(pass)save.pass=pass;
  profiles[name]=save;
  saveProfiles(profiles);
  showErr('');
  enterGameAs(name);
}

function enterGameAs(name){
  const profiles=loadProfiles();
  let rec=profiles[name];
  if(!rec){rec=defaultSave();profiles[name]=rec;saveProfiles(profiles);}
  currentProfile=name;
  localStorage.setItem(SESSION_KEY,name);
  // load save into G
  G.money=rec.money??50;G.day=rec.day??1;G.ds=rec.ds??0;G.served=rec.served??0;G.rep=rec.rep??3;
  G.prestige=rec.prestige??0;
  G.regulars=rec.regulars??{};
  G.worldIdx=Math.min(rec.worldIdx??0,WORLDS.length-1);
  const _minEarned=G.worldIdx>0?WORLDS[G.worldIdx-1].threshold:0;
  G.totalEarned=rec.totalEarned??Math.max(G.money,_minEarned);
  G.earnRateEWMA=rec.earnRate||0;G.lastEarnTs=null;
  // Offline earnings: estimate $/sec from the rate the player was actually
  // achieving last session, project it across the time they were away (at
  // half efficiency, capped at 12h), and hand it over as a welcome-back bonus.
  let _offlineBonus=0,_awayMs=0;
  if(rec.lastSave){
    _awayMs=Math.min(Date.now()-rec.lastSave,12*60*60*1000);
    if(_awayMs>=60*1000&&G.earnRateEWMA>0){
      _offlineBonus=Math.round(G.earnRateEWMA*0.5*(_awayMs/1000)*100)/100;
      G.money+=_offlineBonus;G.totalEarned+=_offlineBonus;
    }
  }
  const _lw=WORLDS[G.worldIdx];
  const _hasNext=!!WORLDS[G.worldIdx+1];
  const _threshold=_hasNext?_lw.threshold:300000;
  const _autoThresh=G.totalEarned>=(_threshold+500);
  G.worldTransitionPending=G.totalEarned>=_threshold;
  Object.keys(UPGRADES).forEach(k=>{UPGRADES[k].done=!!(rec.upgrades&&rec.upgrades[k]);});
  Object.keys(STAFF).forEach(k=>{STAFF[k].done=!!(rec.staff&&rec.staff[k]);});
  applyWorld(G.worldIdx);
  document.getElementById('loginScreen').style.display='none';
  document.getElementById('gameScreen').style.display='block';
  const who=document.getElementById('whoAmI');
  const isAdmin=name.toLowerCase()===ADMIN_NAME;
  who.innerHTML=`👤 ${name} <span class="logoutLink" onclick="logOut()">log out</span>`;
  document.getElementById('adminTile').style.display=isAdmin?'block':'none';
  document.getElementById('statsRow').classList.toggle('has-admin',isAdmin);
  document.getElementById('mn').textContent='$'+G.money.toFixed(2);
  startGame();
  updatePrestigeBadge();
  if(_offlineBonus>0)showOfflineBonus(_awayMs,_offlineBonus);
  if(_hasNext&&_autoThresh){
    addLog(`⚡ Auto-evolved to ${WORLDS[G.worldIdx+1].icon} ${WORLDS[G.worldIdx+1].name}!`,'i');
    setTimeout(()=>switchWorld(G.worldIdx+1),1500);
  } else {
    refreshEvolveBtn();
  }
}

function logOut(){
  persistCurrentProfile();
  localStorage.removeItem(SESSION_KEY);
  location.reload();
}

function tryAutoLogin(){
  const saved=localStorage.getItem(SESSION_KEY);
  if(!saved)return false;
  const profiles=loadProfiles();
  if(!profiles[saved])return false;
  enterGameAs(saved);
  return true;
}

function persistCurrentProfile(){
  if(!currentProfile)return;
  const profiles=loadProfiles();
  const rec=profiles[currentProfile]||defaultSave();
  rec.money=G.money;rec.day=G.day;rec.ds=G.ds;rec.served=G.served;rec.rep=G.rep;rec.worldIdx=G.worldIdx;rec.totalEarned=G.totalEarned;rec.prestige=G.prestige;
  rec.earnRate=G.earnRateEWMA||0;rec.lastSave=Date.now();
  rec.regulars=G.regulars||{};
  rec.upgrades=rec.upgrades||{};
  Object.keys(UPGRADES).forEach(k=>{rec.upgrades[k]=UPGRADES[k].done;});
  rec.staff=rec.staff||{};
  Object.keys(STAFF).forEach(k=>{rec.staff[k]=STAFF[k].done;});
  profiles[currentProfile]=rec;
  saveProfiles(profiles);
}
setInterval(persistCurrentProfile,2000);
window.addEventListener('beforeunload',persistCurrentProfile);

// If mzx grants/deducts money for a profile that's actively open in
// another tab/window, pick up that change live instead of letting the
// open tab's next autosave silently overwrite it with a stale balance.
window.addEventListener('storage',e=>{
  if(e.key!==SAVE_KEY||!currentProfile)return;
  try{
    const profiles=JSON.parse(e.newValue)||{};
    const rec=profiles[currentProfile];
    if(rec&&typeof rec.money==='number'&&rec.money!==G.money){
      G.money=rec.money;
      document.getElementById('mn').textContent='$'+G.money.toFixed(2);
      addLog(`Balance updated by admin → $${G.money.toFixed(2)}`,'u');
    }
  }catch(err){/* ignore malformed storage payloads */}
});

/* ===== Admin panel: view balances & grant/deduct money =====
   Deliberately does NOT show other players' passwords — passwords
   aren't something even an admin should be able to read back. Money
   controls give the real oversight/parental-control ability without
   that. */
function openAdmin(){
  if(!currentProfile||currentProfile.toLowerCase()!==ADMIN_NAME)return;
  persistCurrentProfile();
  renderAdminList();
  document.getElementById('adminOverlay').style.display='flex';
}
function closeAdmin(){
  document.getElementById('adminOverlay').style.display='none';
}
function renderAdminList(){
  const profiles=loadProfiles();
  const names=Object.keys(profiles);
  const el=document.getElementById('adminList');
  if(!names.length){el.innerHTML='No players yet.';return;}
  el.innerHTML=names.map(n=>{
    const rec=profiles[n];
    const safeName=n.replace(/'/g,"\\'");
    return`<div class="adminRow">
      <span class="nm">${n}</span><span class="bal">$${(rec.money??0).toFixed(2)}</span>
      <div class="adminCtrls">
        <input type="number" id="amt_${cssId(n)}" placeholder="0.00" step="0.01">
        <button onclick="adminAdjust('${safeName}',1)">GRANT</button>
        <button onclick="adminAdjust('${safeName}',-1)">DEDUCT</button>
      </div>
    </div>`;
  }).join('');
}
function cssId(n){return n.replace(/[^a-zA-Z0-9]/g,'_');}
function adminAdjust(name,sign){
  const input=document.getElementById('amt_'+cssId(name));
  let amt=parseFloat(input.value);
  if(isNaN(amt)||amt<0)return;
  const profiles=loadProfiles();
  const rec=profiles[name];if(!rec)return;
  rec.money=Math.max(0,(rec.money??0)+sign*amt);
  profiles[name]=rec;
  saveProfiles(profiles);
  if(name===currentProfile){G.money=rec.money;document.getElementById('mn').textContent='$'+G.money.toFixed(2);}
  renderAdminList();
}

/* ===== wire up login screen events ===== */
document.getElementById('showNewProf').addEventListener('click',()=>{
  document.getElementById('passPrompt').style.display='none';
  document.getElementById('newProfForm').style.display='block';
  document.getElementById('newProfName').focus();
  showErr('');
});
document.getElementById('createProfBtn').addEventListener('click',createProfile);
document.getElementById('passSubmitBtn').addEventListener('click',submitPass);
document.getElementById('adminCloseBtn').addEventListener('click',closeAdmin);
document.getElementById('newProfName').addEventListener('keydown',e=>{if(e.key==='Enter')createProfile();});
document.getElementById('newProfPass').addEventListener('keydown',e=>{if(e.key==='Enter')createProfile();});
document.getElementById('passInput').addEventListener('keydown',e=>{if(e.key==='Enter')submitPass();});

if(!tryAutoLogin())renderProfileList();

/* ===== LOFI MUSIC ENGINE — MP3 playlist + synth ambiance ===== */
(function(){

  /* ── Playlist ──────────────────────────────────────────────── */
  const TRACKS=[
    {file:'track1.mp3', label:'Monda Music'},
    {file:'track2.mp3', label:'Mirostar'},
    {file:'track3.mp3', label:'The Mountain'},
    {file:'track4.mp3', label:'Leberch'},
  ];
  let trackIdx=0, isPlaying=false;
  const audio=new Audio();
  audio.volume=0.72;
  audio.addEventListener('ended',()=>nextTrack());

  function loadTrack(idx){
    audio.src=TRACKS[idx].file;
    updateTrackLabel();
  }

  function nextTrack(){ trackIdx=(trackIdx+1)%TRACKS.length; loadTrack(trackIdx); if(isPlaying) audio.play(); }
  function prevTrack(){ trackIdx=(trackIdx-1+TRACKS.length)%TRACKS.length; loadTrack(trackIdx); if(isPlaying) audio.play(); }

  /* ── Web Audio synth — vinyl crackle + sub-bass pulse only ── */
  let audioCtx=null, synthGain=null, schedulerTimer=null;
  let step=0, nextNoteTime=0.0;
  const BPM=75, STEP=60/BPM/4;
  const BASS_NOTES=[130.81,110.00,87.31,98.00];
  const KICK=[1,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0];

  function initSynth(){
    audioCtx=new(window.AudioContext||window.webkitAudioContext)();
    synthGain=audioCtx.createGain(); synthGain.gain.value=0.28;
    const lpf=audioCtx.createBiquadFilter(); lpf.type='lowpass'; lpf.frequency.value=800;
    synthGain.connect(lpf); lpf.connect(audioCtx.destination);
    startVinylCrackle();
  }

  function env(g,t,peak,decay){
    g.gain.setValueAtTime(0.0001,t);
    g.gain.linearRampToValueAtTime(peak,t+0.005);
    g.gain.exponentialRampToValueAtTime(0.0001,t+decay);
  }

  function kick(t){
    const o=audioCtx.createOscillator(),g=audioCtx.createGain();
    o.frequency.setValueAtTime(120,t); o.frequency.exponentialRampToValueAtTime(0.01,t+0.35);
    env(g,t,0.55,0.35); o.connect(g); g.connect(synthGain); o.start(t); o.stop(t+0.38);
  }

  function bassNote(t,idx){
    const o=audioCtx.createOscillator(),f=audioCtx.createBiquadFilter(),g=audioCtx.createGain();
    o.type='sine'; o.frequency.value=BASS_NOTES[idx];
    f.type='lowpass'; f.frequency.value=260;
    g.gain.setValueAtTime(0,t); g.gain.linearRampToValueAtTime(0.28,t+0.02);
    g.gain.setValueAtTime(0.28,t+STEP*3.5); g.gain.linearRampToValueAtTime(0,t+STEP*4);
    o.connect(f); f.connect(g); g.connect(synthGain); o.start(t); o.stop(t+STEP*4.1);
  }

  function startVinylCrackle(){
    const sr=audioCtx.sampleRate, dur=5;
    const buf=audioCtx.createBuffer(1,sr*dur,sr);
    const d=buf.getChannelData(0);
    for(let i=0;i<d.length;i++) d[i]=Math.random()<0.0015?(Math.random()*2-1)*0.5:0;
    const src=audioCtx.createBufferSource(); src.buffer=buf; src.loop=true;
    const bpf=audioCtx.createBiquadFilter(); bpf.type='bandpass'; bpf.frequency.value=2000; bpf.Q.value=0.5;
    const g=audioCtx.createGain(); g.gain.value=0.06;
    src.connect(bpf); bpf.connect(g); g.connect(synthGain); src.start();
  }

  function schedule(){
    while(nextNoteTime<audioCtx.currentTime+0.12){
      const s=step%16, bar=Math.floor(step/16), ci=Math.floor(bar/2)%4;
      if(KICK[s]) kick(nextNoteTime);
      if(s===0||s===8) bassNote(nextNoteTime,ci);
      nextNoteTime+=STEP; step++;
    }
  }

  function startSynth(){
    if(!audioCtx) initSynth();
    if(audioCtx.state==='suspended') audioCtx.resume();
    step=0; nextNoteTime=audioCtx.currentTime+0.05;
    schedulerTimer=setInterval(schedule,22);
  }

  function stopSynth(){
    clearInterval(schedulerTimer); schedulerTimer=null;
  }

  /* ── Unified controls ──────────────────────────────────────── */
  function startAll(){
    loadTrack(trackIdx);
    audio.play().catch(()=>{});
    startSynth();
    isPlaying=true; updateUI();
  }

  function stopAll(){
    audio.pause(); audio.currentTime=0;
    stopSynth();
    isPlaying=false; updateUI();
  }

  /* ── UI helpers ────────────────────────────────────────────── */
  function updateUI(){
    const btn=document.getElementById('musicBtn');
    const lbl=document.getElementById('musicTrackLabel');
    if(btn){ btn.textContent=isPlaying?'\u258e\u258e':'\u25ba'; btn.classList.toggle('on',isPlaying); }
    if(lbl) lbl.classList.toggle('playing',isPlaying);
    updateTrackLabel();
  }

  function updateTrackLabel(){
    const lbl=document.getElementById('musicTrackLabel');
    if(lbl) lbl.textContent=isPlaying?TRACKS[trackIdx].label:'\u2014 OFF \u2014';
  }

  /* expose globally */
  window.toggleLofiMusic=function(){ isPlaying?stopAll():startAll(); };
  window.lofiNext=nextTrack;
  window.lofiPrev=prevTrack;

})();
