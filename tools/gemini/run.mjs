// Stapellauf: node run.mjs [filter]   (Filter = Teilstring der Job-Namen)
import { connect } from './lib.mjs';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const SRC = path.join(ROOT, 'strategie');
const OUT = path.join(SRC, 'neu');
const DONE = path.join(OUT, 'manifest.json');
fs.mkdirSync(OUT, { recursive: true });
const done = fs.existsSync(DONE) ? JSON.parse(fs.readFileSync(DONE)) : {};
for (const f of fs.readdirSync(OUT)) if (f.endsWith('.jpg')) done[f.replace('.jpg', '')] = true;

const ref = k => path.join(SRC, `Gemini_Generated_Image_${fs.readdirSync(SRC).find(f => f.includes(k)).split('Image_')[1]}`);

const FIG = {
  maedchen_baer: ['o9escf', 'Mira, the girl with long brown braided hair, red leather vest, shoulder armor, and her pet bear cub on her shoulder'],
  ritter: ['3qn25o', 'the old knight with grey hair and beard, steel armor with golden eagle emblem, blue cape and sword'],
  samurai: ['356iau', 'the samurai in red-brown lamellar armor with golden horned helmet and katana'],
  kungfu: ['51gj00', 'the kung fu fighter with red sleeveless mandarin jacket, white sash and long wooden staff'],
  ninjas: ['6bzmcc', 'the two ninja sisters together as ONE image (yellow suit sister and red suit sister with red face mask), both visible'],
  elisabeth: ['6nooi7', 'Elisabeth the pirate girl with long blonde hair, tricorn hat, brass telescope and small cannon'],
  museklaugust: ['1zbg22', 'the baroque king with white curled wig, crown, red uniform with sash and absurdly huge muscles, fists raised'],
  robo: ['96miwt', 'the steampunk brass robot with glowing cyan eye, gears and steam'],
  hund: ['btb16a', 'the anthropomorphic blue heeler dog fighter in leather vest holding a heavy bone in each hand'],
  wendy: ['455gim', 'Wendy Wolle the anthropomorphic sheep healer in green and white robe holding a crystal staff'],
  claude: ['yh4g19', 'the genie with turban and moustache floating above his magic lamp, casting sparkling magic'],
  bienenmaedchen: ['1ilw25', 'the creepy bee girl with insect wings, antennae, black-yellow fur armor, stinger and dripping green poison'],
  braumeisterin: ['kq5h0v', 'the muscular female brewmaster with red braided hair and headband, leather apron, carrying a big beer barrel on her shoulder'],
};
const STYLE_REF = '3qn25o'; // Ritter als Stilvorlage fuer neue Figuren
const GREEN = 'Flat solid bright green chroma-key background, no shadow, no text, no border, no watermark.';
const jobs = [];
for (const [id, [k, d]] of Object.entries(FIG))
  jobs.push({ name: `${id}_chibi`, refs: [ref(k)], prompt:
    `Create a chibi version of exactly this character: ${d}. Keep the same face, colors, outfit and props. Output exactly ONE single character: no second figure, no copy, ghost or faded duplicate of the reference image anywhere in the picture. IMPORTANT: strict FULL BODY from head to toe, both feet / boots / shoes clearly visible standing on the ground, nothing cropped at the bottom, the entire figure fully inside the image with a margin all around. Tiny cute chibi proportions (about 2.5 heads tall), standing, facing right, small game-map sprite that will be moved over a map. Keep exactly the same pixel-art style as the attached image. ${GREEN}` });
const SOLD = {
  infanterie: 'a generic infantry soldier with sword and round shield, simple steel helmet, crimson and black tabard',
  beritten: 'a generic mounted cavalry soldier riding a armored brown warhorse, holding a lance, simple steel helmet, crimson and black tabard',
  bogenschuetze: 'a generic archer soldier with a longbow and quiver, hooded leather cap, crimson and black tunic',
  priester: 'a generic priest/cleric soldier with a staff topped by a glowing orb, hooded robe in crimson and black with gold trim',
};
for (const [id, d] of Object.entries(SOLD)) {
  jobs.push({ name: `soldat_${id}_chibi`, refs: [path.join(OUT, 'soldat_infanterie_chibi.jpg')], prompt:
    `Using the attached chibi game-sprite style as reference (it is only a style reference of a DIFFERENT character: do not include, copy or imitate that character), create a NEW chibi map sprite of ${d}. IMPORTANT: strict FULL BODY from head to toe, both feet / boots clearly visible on the ground (for the cavalry: all four hooves), nothing cropped, entire figure inside the image with margin. Tiny cute chibi proportions (about 2.5 heads tall), standing, facing right. Same pixel-art style as the attached image. Output exactly ONE single character: no second figure, no copy, ghost or faded duplicate of the reference image anywhere in the picture. ${GREEN}` });
}
for (const [id, d] of Object.entries(SOLD)) {
  jobs.push({ name: `soldat_${id}`, refs: [ref(STYLE_REF)], prompt:
    `Create a new dialogue portrait of ${d}, in exactly the same pixel-art style, framing and composition as the attached image: character on the left side of the image, upper body / three-quarter view, facing right, nothing on the right half. Solid bright green background, no text, no border.` });
}
const EMO = {
  lachend: 'laughing out loud with joy: eyes squeezed shut happily, wide open smiling mouth, relaxed cheerful body language',
  wuetend: 'furious and angry: deep scowl, furrowed brows, gritted teeth or shouting mouth, tense aggressive body language',
};
for (const [e, t] of Object.entries(EMO))
  for (const [id, [k, d]] of Object.entries(FIG))
    jobs.push({ name: `${id}_${e}`, refs: [ref(k)], prompt:
      `Redraw exactly this character (${d}) in the identical pixel-art style, outfit, colors, size and framing: character on the left side of the image, facing right, nothing on the right half, solid bright green background like the reference. Change ONLY the facial expression and body language to: ${t}. (Adapt it to the character's species/robot design.) No text, no border.` });

// Effekt-Sprites (Kampfanimationen). Stilvorlage: Ritter-Chibi, ausdruecklich ohne Figur im Ergebnis.
const FX_STYLE = ' Same pixel-art style, palette feel and level of detail as the attached image (use it ONLY as a style reference; do NOT draw any character or any copy of it). Single object only, centered, nothing else in the picture. Flat solid bright green chroma-key background (#00FF00), no shadow, no text, no border, no watermark.';
const FX = {
  fx_cannonball: 'a single round black iron cannonball with a bright highlight and a short motion streak, game sprite',
  fx_fireball: 'a single big explosion fireball with white-yellow core, orange body, red edges and flying sparks, game VFX sprite',
  fx_smoke: 'a soft round puff of grey-white smoke cloud with shaded lumps, game VFX sprite',
  fx_bone: 'a single large cartoon dog bone, cream white with brown shading, drawn diagonally, game sprite',
  fx_star: 'a bright yellow-white comic impact starburst with eight pointy rays (a hit spark), game VFX sprite',
  fx_exclaim: 'a red angry exclamation mark inside a jagged burst shape with thick dark outline, comic emote symbol',
  fx_claw: 'three diagonal orange-red claw scratch slash marks with white-hot cores, game VFX sprite',
  fx_slash: 'a white-blue curved sword slash crescent arc with a bright edge and a motion streak, game VFX sprite',
  fx_arrow_up: 'a glowing golden upward-pointing arrow with small sparkles, game sprite',
  fx_cross: 'a glowing green plus sign (healing cross) with small sparkles, game sprite',
  fx_bubble: 'a shiny toxic green poison bubble with a white highlight, game sprite',
  fx_glob: 'a blob of toxic green slime poison goo with a dripping tail, game sprite',
  fx_barrel: 'a wooden beer barrel with iron hoops, game sprite',
  fx_foam: 'a splash of white beer foam and golden-brown beer droplets, game VFX sprite',
  fx_leaf: 'a single green leaf, game sprite',
  fx_rune: 'a glowing violet magic circle with runes seen from directly above, flat game VFX decal',
  fx_frog: 'a cute green frog sitting and looking up, game sprite',
  fx_sweat: 'a single blue sweat drop, comic emote, game sprite',
  fx_flower: 'a small white and pink flower with a short green stem, game sprite',
  fx_arrow: 'a wooden arrow with feathers pointing to the right, game sprite',
  fx_bolt: 'a glowing cyan magic energy orb with trailing sparkles, game VFX sprite',
  fx_shuriken: 'a steel ninja throwing star shuriken, game sprite',
};
for (const [name, d] of Object.entries(FX))
  jobs.push({ name, refs: [path.join(OUT, name === 'fx_fireball' || name === 'fx_cannonball' ? 'ritter_chibi.jpg' : 'fx_fireball.jpg')], prompt: `Create ${d}.` + FX_STYLE });

// Bösewicht (Regent) und Trainingsattrappe: Portrait wie die Helden (links, Oberkörper), Chibi ganzkörper mit Füßen.
const VILLAIN = 'the villain: a stereotypical evil noble warlord prince, tall and lean, sharp cruel face with a thin pointed moustache and goatee, slicked-back black hair, a thin jeweled iron circlet, heavy black plate armor with crimson trim and a high spiked collar, flowing crimson-lined black cape, holding a dark jeweled scepter';
const DUMMY = 'a martial-arts wooden training dummy (wing-chun style): a thick wooden post with three stubby wooden arms and one leg peg, wrapped in rope and patched burlap, painted red target marks on the chest, a faded cloth headband, scuffed and dented, with a simple friendly painted face';
const PORTRAIT_TAIL = ' Same pixel-art style, framing and composition as the attached image (use it ONLY as a style reference, do NOT draw its character): character on the left side of the image, upper body, facing right, nothing on the right half. Output exactly ONE character. Solid bright green background, no text, no border.';
const CHIBI_TAIL = ' Chibi version for a game map: strict FULL BODY from head to toe, both feet clearly visible standing on the ground, nothing cropped, entire figure inside the image with margin. Tiny cute chibi proportions (about 2.5 heads tall), standing, facing right. Use the attached image ONLY as a style reference (do NOT draw its character). Output exactly ONE character. Flat solid bright green chroma-key background, no shadow, no text, no border, no watermark.';
const EMO_V = { lachend: 'with a wicked, gloating grin and narrowed eyes, mocking laugh', wuetend: 'furious, snarling, eyes blazing, pointing accusingly' };
jobs.push({ name: 'fuerst', refs: [ref(STYLE_REF)], prompt: `Create a dialogue portrait of ${VILLAIN}, with a cold smug sneer.` + PORTRAIT_TAIL });
jobs.push({ name: 'fuerst_chibi', refs: [path.join(OUT, 'ritter_chibi.jpg')], prompt: `Create ${VILLAIN}.` + CHIBI_TAIL });
for (const [e, t] of Object.entries(EMO_V))
  jobs.push({ name: `fuerst_${e}`, refs: [ref(STYLE_REF)], prompt: `Create a dialogue portrait of ${VILLAIN}, ${t}.` + PORTRAIT_TAIL });
jobs.push({ name: 'dummy', refs: [ref(STYLE_REF)], prompt: `Create a dialogue portrait of ${DUMMY}.` + PORTRAIT_TAIL });
jobs.push({ name: 'dummy_chibi', refs: [path.join(OUT, 'ritter_chibi.jpg')], prompt: `Create ${DUMMY}.` + CHIBI_TAIL });

// Haendler (Platzhalter "Hoppel"): anthropomorpher Hase mit riesigem Rucksack voller Waren.
const MERCHANT = 'a friendly anthropomorphic rabbit merchant (bunny shopkeeper): tall upright ears with one ear folded over, warm brown and cream fur, a cheeky grin with big front teeth, a green traveling coat and a wide-brimmed hat with a feather, wearing a huge overstuffed backpack piled high with potion bottles, scrolls, a rolled-up blanket, pots and a lantern, a coin pouch at the belt';
jobs.push({ name: 'haendler', refs: [ref(STYLE_REF)], prompt: `Create a dialogue portrait of ${MERCHANT}, smiling invitingly.` + PORTRAIT_TAIL });
jobs.push({ name: 'haendler_lachend', refs: [ref(STYLE_REF)], prompt: `Create a dialogue portrait of ${MERCHANT}, laughing out loud with joy.` + PORTRAIT_TAIL });
jobs.push({ name: 'haendler_chibi', refs: [path.join(OUT, 'ritter_chibi.jpg')], prompt: `Create ${MERCHANT}.` + CHIBI_TAIL });

// Neue Gegenspieler: Wart, Xiulan, Oskar, Maja. Reihenfolge wichtig: Maja nutzt Oskars Portrait als Vorlage (Zwillinge).
const VILLAINS = {
  wart: 'Wart, an anthropomorphic wild boar mercenary: huge tusks, scarred snout, bristly dark mohawk, small mean eyes with an evil grin, muscular, wearing patched spiked leather armor, crossed bandoliers of bullets and grenades, knives in his belt and boots, and a big rocket launcher resting on his shoulder; armed to the teeth',
  xiulan: 'Xiulan, a small elderly Chinese grandmother kung fu master: grey hair in a tight bun with chopsticks, deeply wrinkled face with a sly toothless grin, a faded red-and-gold silk jacket with frog buttons, wide trousers and cloth shoes, hands in a praying-mantis claw stance, and in one hand she is holding up a set of false teeth (dentures) ready to throw',
  oskar: 'Oskar, a young, very handsome blond general: swept-back golden hair, sharp blue eyes, a confident charming smirk, an ornate crimson and black officer uniform with gold braid and epaulettes, a short black cape, a sabre at his hip, one hand raised commandingly as if rallying troops',
  maja: 'Maja, the twin sister of the attached general: same face structure, same golden blond hair color and blue eyes but feminine, extremely beautiful and cruel, long flowing blond hair, a cold intimidating smile and a piercing icy gaze, wearing an elegant crimson and black dress-armor with high collar and gold trim, holding a black riding crop; she looks menacing and makes opponents shrink',
};
const V_EMO = { lachend: 'laughing wickedly with delight, head thrown back slightly', wuetend: 'furious and snarling, eyes blazing with rage' };
const SELF_TAIL = ' Solid bright green background, no text, no border. Output exactly ONE character, no duplicates or ghost copies.';
for (const [vid, d] of Object.entries(VILLAINS)) {
  const base = vid === 'maja' ? path.join(OUT, 'oskar.jpg') : ref(STYLE_REF);
  const intro = vid === 'maja'
    ? `Create a dialogue portrait of ${d}. Same pixel-art style, framing and composition as the attached image: character on the left side of the image, upper body, facing right, nothing on the right half.`
    : `Create a dialogue portrait of ${d}.` + PORTRAIT_TAIL;
  jobs.push({ name: vid, refs: [base], prompt: intro + (vid === 'maja' ? SELF_TAIL : '') });
  jobs.push({ name: `${vid}_chibi`, refs: [path.join(OUT, `${vid}.jpg`)], prompt:
    `Create a chibi version of exactly this character. Keep the same face, hair, colors, outfit and props. IMPORTANT: strict FULL BODY from head to toe, both feet clearly visible standing on the ground, nothing cropped, entire figure inside the image with margin. Tiny cute chibi proportions (about 2.5 heads tall), standing, facing right, small game-map sprite. Keep exactly the same pixel-art style.` + ' Output exactly ONE single character: no second figure, no ghost duplicate. NO ground line, NO floor strip, NO shadow or platform under the feet: the feet stand directly on the flat green background. ' + GREEN });
  for (const [e, t] of Object.entries(V_EMO))
    jobs.push({ name: `${vid}_${e}`, refs: [path.join(OUT, `${vid}.jpg`)], prompt:
      `Redraw exactly this character in the identical pixel-art style, outfit, colors, size and framing: character on the left side of the image, facing right, nothing on the right half, solid bright green background like the reference. Change ONLY the facial expression and body language to: ${t}. Any glow stays inside the head: no light beams, streaks or glow extending outside the face. No text, no border.` });
}

// Mission 4 (Teehaus): Mutter mit Baby (Geisel, Platzhalter "Lieselotte") und Xiulans Wurf-Gebiss als Effekt-Sprite.
const MOTHER = 'a young village mother: warm brown hair in a loose braid with a headscarf, a worn green-and-cream peasant dress with an apron, soft kind face, carrying a tiny baby wrapped in a cream blanket in her arms (the baby has a little tuft of hair and big round eyes)';
const MOTHER_EMO = { '': 'frightened and worried, eyes wide, protectively hugging the baby', lachend: 'beaming with relief and gratitude, tears of joy, hugging the baby', wuetend: 'fierce mother-bear anger, glaring and scolding, shielding the baby' };
for (const [e, t] of Object.entries(MOTHER_EMO))
  jobs.push({ name: e ? `mutter_${e}` : 'mutter', refs: [ref(STYLE_REF)], prompt: `Create a dialogue portrait of ${MOTHER}, ${t}.` + PORTRAIT_TAIL });
jobs.push({ name: 'mutter_chibi', refs: [path.join(OUT, 'ritter_chibi.jpg')], prompt: `Create ${MOTHER}.` + CHIBI_TAIL + ' NO ground line, NO floor strip, NO shadow under the feet.' });
jobs.push({ name: 'fx_gebiss', refs: [path.join(OUT, 'fx_fireball.jpg')], prompt: 'Create a single set of cartoon false teeth (dentures): pink gums with two rows of white teeth, slightly open as if chomping, with a short white motion streak, game sprite.' + FX_STYLE });

// Kapitel 5 (Waisenhaus): Waisenkinder als Gruppen-Portrait (drei Kinder, alle Emotionen) und drei Karten-Figuren.
const KIDS = 'three orphan children huddled close together: a girl of about ten with two brown braids and a patched green dress (Lotte, the oldest, protective), a small boy of about six with messy red hair, a too-big flat cap and a missing front tooth (Pip), and a tiny girl of about four with curly blond hair holding a worn teddy bear (Mia); all in poor, patched, mended clothes, big expressive eyes';
const KIDS_EMO = { '': 'scared but brave, clinging to each other, looking up wide-eyed', lachend: 'laughing and cheering with joy and relief, big happy smiles', wuetend: 'angry and defiant, fists clenched and sticking out their tongues at an unseen enemy' };
const KIDS_TAIL = ' Same pixel-art style, framing and composition as the attached image (use it ONLY as a style reference, do NOT draw its character): the children on the left side of the image, upper body, facing right, nothing on the right half. Output exactly these three children, no duplicates or ghost copies. Solid bright green background, no text, no border.';
for (const [e, t] of Object.entries(KIDS_EMO))
  jobs.push({ name: e ? `waisenkinder_${e}` : 'waisenkinder', refs: [ref(STYLE_REF)], prompt: `Create a dialogue portrait of ${KIDS}, ${t}.` + KIDS_TAIL });
const KID = {
  kind_lotte: 'Lotte, a girl of about ten with two brown braids and a patched green dress, protective, hands on hips',
  kind_pip: 'Pip, a small boy of about six with messy red hair, a too-big flat cap and a missing front tooth, patched trousers, holding a wooden toy sword',
  kind_mia: 'Mia, a tiny girl of about four with curly blond hair in a patched yellow dress, hugging a worn teddy bear',
};
for (const [name, d] of Object.entries(KID))
  jobs.push({ name: `${name}_chibi`, refs: [path.join(OUT, 'ritter_chibi.jpg')], prompt: `Create ${d}.` + CHIBI_TAIL + ' NO ground line, NO floor strip, NO shadow under the feet.' });

// Kapitel 5: Bienenkrieger (Schwarm-Gegner), Honigtopf und Honig-Effekt. Stachelia-Chibi dient als Stilvorlage.
jobs.push({ name: 'bienenkrieger_chibi', refs: [path.join(OUT, 'bienenmaedchen_chibi.jpg')], prompt: 'Create a small bee warrior soldier in exactly the same pixel-art style as the attached image (use it ONLY as a style reference, do NOT draw its character): a humanoid bee with a striped yellow-and-black body, translucent wings, two antennae, a tiny helmet made of a honeycomb, a small round amber shield and a short stinger-spear, hovering slightly above the ground. Chibi proportions, strict FULL BODY, nothing cropped, facing right. Output exactly ONE character. NO ground line, NO shadow. ' + GREEN });
jobs.push({ name: 'fx_honigtopf', refs: [path.join(OUT, 'fx_fireball.jpg')], prompt: 'Create a single clay honey pot overflowing with thick golden honey that drips down its sides, with a small wooden honey dipper, game sprite.' + FX_STYLE });
jobs.push({ name: 'fx_honig', refs: [path.join(OUT, 'fx_fireball.jpg')], prompt: 'Create a single splash of golden sticky honey: a glossy amber blob with drips and a few flying droplets, game VFX sprite.' + FX_STYLE });

async function generate(page, job) {
  await page.goto('https://gemini.google.com/app', { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('div[role=textbox], .ql-editor', { timeout: 30000 });
  await page.waitForTimeout(2500);
  await page.locator('input[type=file][accept="image/*,video/*"]').first().setInputFiles(job.refs);
  await page.waitForTimeout(3000);
  await page.getByRole('button', { name: 'Uploads & Tools' }).first().click();
  await page.getByText('Bild erstellen', { exact: true }).click();
  await page.waitForTimeout(600);
  await page.locator('div[role=textbox], .ql-editor').first().click();
  await page.keyboard.insertText(job.prompt);
  await page.keyboard.press('Enter');
  const dl = page.getByRole('button', { name: 'Bild in Originalgröße herunterladen' }).last();
  const limit = page.getByText(/Limit|Kontingent|später erneut|nicht mehr möglich|zu viele/i).first();
  const r = await Promise.race([
    dl.waitFor({ timeout: 240000 }).then(() => 'ok'),
    limit.waitFor({ timeout: 240000 }).then(() => 'limit'),
  ]);
  if (r === 'limit') { const t = await limit.innerText().catch(() => ''); const e = new Error('LIMIT: ' + t); e.limit = true; throw e; }
  await page.waitForTimeout(2500);
  const [d] = await Promise.all([page.waitForEvent('download', { timeout: 90000 }), dl.click({ force: true })]);
  await d.saveAs(path.join(OUT, job.name + '.jpg'));
}

const filter = process.argv[2] ?? '';
const { b, page } = await connect();
let n = 0;
for (const job of jobs) {
  if (!job.name.includes(filter) || done[job.name]) continue;
  const t0 = Date.now();
  try {
    await generate(page, job);
    done[job.name] = true; n++;
    console.log(`OK   ${job.name} (${Math.round((Date.now() - t0) / 1000)}s)`);
  } catch (e) {
    console.log(`FAIL ${job.name}: ${e.message.split('\n')[0]}`);
    await page.screenshot({ path: path.join(OUT, `_fail_${job.name}.png`) }).catch(() => {});
    if (e.limit) { console.log('Limit erreicht, Abbruch.'); break; }
  }
  fs.writeFileSync(DONE, JSON.stringify(done, null, 1));
  await page.waitForTimeout(4000);
}
console.log(`Fertig: ${n} neue Bilder.`);
await b.close();
