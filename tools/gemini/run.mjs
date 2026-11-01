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

// Haendler "Wulle": lebender Sack aus blauer Haekelwolle (Vorbild: strategie/haendler_vorbild.jpg, ein echtes Haekeltier).
const SACK_REF = path.join(SRC, 'haendler_vorbild.jpg');
const SACK_TAIL = ' IMPORTANT: the FIRST attached image is the character reference (a real crocheted plush toy): redraw exactly this character as a pixel-art game character, keeping its design: a trapezoid sack body of slate-blue crocheted wool (wider at the bottom, narrower at the top), the top gathered and tied shut with a beige string tied in a bow, two tiny rounded ear-like nubs at the top corners, two big round cream-beige crocheted eyes with small dark brown pupils, a small round blue nose in the middle, two thin long tube arms of the same blue wool, and two short tube legs with big rounded oval feet. Visible fine knitted/crocheted stitch texture. He is a friendly traveling merchant: a little coin pouch hangs from his string and a few wares (a potion bottle, a scroll) peek out above the tied top. The SECOND attached image is ONLY a pixel-art style reference, do NOT draw its character.';
const MERCHANT = 'Wulle, a living sack merchant made of blue crocheted wool';
jobs.push({ name: 'haendler', refs: [SACK_REF, ref(STYLE_REF)], prompt: `Create a dialogue portrait of ${MERCHANT}, with a friendly inviting look.` + SACK_TAIL + PORTRAIT_TAIL });
jobs.push({ name: 'haendler_lachend', refs: [SACK_REF, ref(STYLE_REF)], prompt: `Create a dialogue portrait of ${MERCHANT}, happy, eyes crinkled with joy, the wool body bouncing with laughter.` + SACK_TAIL + PORTRAIT_TAIL });
jobs.push({ name: 'haendler_chibi', refs: [SACK_REF, path.join(OUT, 'ritter_chibi.jpg')], prompt: `Create ${MERCHANT}.` + SACK_TAIL + CHIBI_TAIL });

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

// Kapitel 6: Elisabeths Piratenschiff als Karten-Sprite (Seitenansicht, schraeg von vorn).
jobs.push({ name: 'fx_schiff', refs: [path.join(OUT, 'fx_fireball.jpg')], prompt: 'Create Captain Elisabeth\'s pirate ship: a small, charming wooden pirate sailing ship with two masts, patched cream-colored sails with a skull-and-crossed-cutlasses emblem, a carved figurehead, a row of black cannons along the side, rope rigging, a little crow\'s nest and a red-gold stern with lanterns, seen from the side slightly from the front, floating (no water around it). Game sprite.' + FX_STYLE });

// Hafen-Hindernisse (Kapitel 6): drei Sprites statt einfacher Klotz-Modelle.
const HAFEN = {
  fx_kiste: 'a stack of three weathered wooden cargo crates with iron corner brackets, stenciled harbor marks, a coil of rope and a torn canvas cloth on top, harbor barricade',
  fx_fass: 'two large tarred wooden barrels with black iron hoops standing side by side, one with a wooden lid and a rope around it, a small crate leaning against them, harbor barricade',
  fx_saecke: 'a pile of plump burlap grain sacks tied with string, a small crate and a rolled fishing net beside them, harbor barricade',
};
for (const [name, d] of Object.entries(HAFEN))
  jobs.push({ name, refs: [path.join(OUT, 'fx_fireball.jpg')], prompt: `Create ${d}, game sprite, seen slightly from above and the front, sturdy and chunky, readable at small size.` + FX_STYLE });

// Karten-Gebaeude und -Objekte als Pixel-Sprites (konsistente Optik, statt Klotz-Modellen).
const GEBAEUDE = {
  fx_teehaus: 'a small Chinese-style roadside tea house: red wooden pillars, cream plaster walls, a two-tier dark-red curved tiled roof with golden ridge ornaments, hanging red paper lanterns, a tea sign and a little porch with steps',
  fx_waisenhaus: 'a cozy but shabby orphanage house: two-story half-timbered cottage with patched brown roof, a smoking chimney, round windows with warm light, a wooden sign with a small teddy bear on it, a tiny garden fence and a few flower pots',
  fx_bienenstock: 'a traditional straw beehive (bee skep) on a small wooden stand, with an entrance hole, a few bees buzzing around it and a drip of golden honey',
  fx_glocke: 'a tall wooden bell post: two thick posts with a crossbeam on top and a big golden bell with a rope hanging from the beam, too high to reach, small moss on the wood',
};
for (const [name, d] of Object.entries(GEBAEUDE))
  jobs.push({ name, refs: [path.join(OUT, 'fx_fireball.jpg')], prompt: `Create ${d}, game sprite, seen slightly from above and the front, sturdy and chunky, readable at small size.` + FX_STYLE });

// Neue Heiler (Backlog 4): Magical Girl "Lumi" und Quaksalber-Arzt "Dr. Humbug", jeweils Portrait, lachend, wuetend, Chibi.
const HEALERS = {
  magical_girl: 'Lumi Sternenglanz, a cheerful magical girl healer: bright pink hair in two long twin-tails with star-shaped hair clips, big sparkling eyes, a frilly pastel pink-and-white dress with a big ribbon and a heart brooch, white gloves, holding a star-tipped magic wand that glows softly, tiny sparkles around her',
  quacksalber: 'Dr. Humbug, a shady but charming quack doctor: tall top hat, round golden spectacles, a big curled moustache, a long patched mustard-yellow coat with dozens of tiny bottles and vials pinned inside, a worn leather doctor bag and a big bottle labeled miracle elixir in one hand, a sly confident grin',
};
const H_EMO = { lachend: 'laughing with joy and confidence', wuetend: 'angry and indignant, frowning and pointing' };
for (const [hid, d] of Object.entries(HEALERS)) {
  jobs.push({ name: hid, refs: [ref(STYLE_REF)], prompt: `Create a dialogue portrait of ${d}.` + PORTRAIT_TAIL });
  jobs.push({ name: `${hid}_chibi`, refs: [path.join(OUT, `${hid}.jpg`)], prompt:
    'Create a chibi version of exactly this character. Keep the same face, hair, colors, outfit and props. IMPORTANT: strict FULL BODY from head to toe, both feet clearly visible standing on the ground, nothing cropped, entire figure inside the image with margin. Tiny cute chibi proportions (about 2.5 heads tall), standing, facing right, small game-map sprite. Keep exactly the same pixel-art style. Output exactly ONE single character: no second figure, no ghost duplicate. NO ground line, NO floor strip, NO shadow or platform under the feet: the feet stand directly on the flat green background. ' + GREEN });
  for (const [e, t] of Object.entries(H_EMO))
    jobs.push({ name: `${hid}_${e}`, refs: [path.join(OUT, `${hid}.jpg`)], prompt:
      `Redraw exactly this character in the identical pixel-art style, outfit, colors, size and framing: character on the left side of the image, facing right, nothing on the right half, solid bright green background like the reference. Change ONLY the facial expression and body language to: ${t}. Any glow stays inside the head: no light beams, streaks or glow extending outside the face. No text, no border.` });
}
// Wueste (Backlog 1): Karten-Sprites fuer das neue Biom.
const WUESTE = {
  fx_kaktus: 'a cluster of two or three green desert cacti (a tall saguaro with arms and a round barrel cactus) with small pink flowers and a few sand-colored pebbles around the base',
  fx_palme: 'a lone desert oasis date palm with a curved trunk, a lush crown of green fronds and a few dates, with a small tuft of grass at the foot',
  fx_zelt: 'a striped desert market tent in faded red and cream with a wooden pole, a small awning, a hanging oil lamp and a stack of woven baskets and clay pots in front',
};
for (const [name, d] of Object.entries(WUESTE))
  jobs.push({ name, refs: [path.join(OUT, 'fx_fireball.jpg')], prompt: `Create ${d}, game sprite, seen slightly from above and the front, sturdy and chunky, readable at small size.` + FX_STYLE });

// Doerfer als Sprites (statt Klotz-Haeuschen): Einzelhaeuser (brennbar), Ruinen, Dorfplatz fuer Dorf-Felder. Wiese und Wueste.
const DORF = {
  fx_haus1: 'a small cozy one-story half-timbered village cottage with a steep red-brown tiled roof, a stone chimney, a wooden door and two lit windows',
  fx_haus2: 'a two-story half-timbered village house with an overhanging upper floor, a patched brown roof with a dormer window, a chimney, flower boxes on the windows',
  fx_haus3: 'a small thatched-roof farm cottage with plaster walls, a round door, a tiny porch with a barrel and a stack of firewood beside it',
  fx_haus_wueste1: 'a small flat-roofed sand-colored adobe desert house with a wooden door, a small turquoise window shutter, a ladder to the roof and a clay pot',
  fx_haus_wueste2: 'a two-level sand-colored mud-brick desert house with a rounded top, striped cloth awning over the door, small square windows and hanging red chili strings',
  fx_ruine1: 'the burnt-out ruin of a half-timbered house: charred black beams standing up, collapsed roof, scorched stone foundation, a little smoke and glowing embers',
  fx_ruine2: 'the smoldering ruin of a small cottage: broken blackened walls, a fallen chimney, charred rafters and ash on the ground, a thin smoke trail',
  fx_dorf: 'a small village square: two little half-timbered houses with red roofs side by side, a stone well with a tiny roof in the middle, a wooden fence and a haystack',
  fx_dorf_wueste: 'a small desert village square: two little sand-colored adobe houses side by side, a stone well with a palm leaf shade in the middle, clay pots and a small striped awning',
};
for (const [name, d] of Object.entries(DORF))
  jobs.push({ name, refs: [path.join(OUT, 'fx_fireball.jpg')], prompt: `Create ${d}, game sprite, seen slightly from above and the front, sturdy and chunky, readable at small size.` + FX_STYLE });

// Letzte Klotz-Modelle ersetzen: Truhe (zu und offen), Burg, Beutesack-Markierung, Hebel (Schalter), Fesselpfahl.
const REST = {
  fx_truhe: 'a closed wooden treasure chest with iron bands, a golden lock and a rounded lid, slightly worn, sturdy and chunky',
  fx_truhe_offen: 'the same kind of wooden treasure chest with iron bands and a golden lock, but standing open with the lid tilted back and gold coins and a gem glittering inside, sturdy and chunky',
  fx_burg: 'a small grey stone castle keep: a square fortified building with a crenellated wall, four round corner towers with blue conical roofs, a gate and a red banner on top',
  fx_beutel: 'a single small brown leather coin pouch tied with a string, with a gold coin peeking out and a sparkle, simple icon-like sprite',
  fx_hebel: 'a small mossy grey stone block with a metal pull lever handle sticking up from it, tilted to the left, with a round red knob on top, like a railway switch',
  fx_pfahl: 'a sturdy wooden post with coiled ropes wrapped around it, a few loose rope ends hanging down, a hostage stake',
};
for (const [name, d] of Object.entries(REST))
  jobs.push({ name, refs: [path.join(OUT, 'fx_fireball.jpg')], prompt: `Create ${d}, game sprite, seen slightly from above and the front, readable at small size.` + FX_STYLE });

// Dr. Humbugs "aeusserst seriöse" Praxis (Mission 3): Fachwerkhaus mit Schild, rotem Kreuz und Flaschen im Fenster.
jobs.push({ name: 'fx_haus_praxis', refs: [path.join(OUT, 'fx_haus1.jpg')], prompt: 'Create a small half-timbered village house that is a shady quack doctor\'s practice, in exactly the same pixel-art style as the attached image (use it ONLY as a style reference): a wooden hanging sign with a red cross and a skull-and-bones joke, a big window full of colorful potion bottles and jars, a mortar and pestle on a barrel by the door, a steep red tiled roof with a chimney, readable at small size, game sprite, seen slightly from above and the front.' + FX_STYLE });

// Neue Faehigkeiten (docs/faehigkeiten_plan.md): Effekt-Sprites und Statussymbole.
const ABIL = {
  fx_wolle: 'a fluffy white wool coat / cloak mid-air with soft curly wool tufts and a few loose wool flecks, cozy, game sprite',
  fx_bruell: 'a comic roar shockwave: a big jagged cone-shaped sound burst in orange and cream with three curved sound-wave arcs and speed lines, game VFX sprite',
  fx_stab: 'a long wooden kung-fu staff (bo) with red cloth wraps at both ends and a faint white motion arc, drawn diagonally, game sprite',
  fx_dampf: 'two puffs of hot white steam with a reddish glow, rising upward, cartoon angry steam, game VFX sprite',
  fx_wutader: 'the manga anger mark: four thick curved red angry-vein arcs arranged around an empty center like a throbbing burst (the classic anger pop symbol), red with dark outline and a small highlight, clearly NOT a plus sign and NOT a medical cross, comic emote symbol',
  fx_bierkrug: 'a big wooden beer mug with iron hoops, overflowing golden beer with white foam on top, a few drops flying, game sprite',
  fx_krack: 'the comic sound word KRACK in bold jagged yellow and red letters with a burst outline, crack lines around it, game VFX sprite',
  fx_bombe: 'a round black iron bomb with a lit sparkling fuse and a glowing orange stripe, small and chunky, game sprite',
  fx_flamme: 'a single lively orange-yellow flame with red edges and a white-hot core, small flickering fire, game VFX sprite',
  fx_flasche: 'a round glass potion flask with a cork, glowing green bubbling liquid and purple smoke wisps, tilted as thrown, game sprite',
  fx_wuff: 'a comic speech bubble with the word WUFF in bold white letters on dark outline, with small bark lines, game sprite',
  fx_sternschnuppe: 'a bright magical shooting star: a golden-pink five-pointed star with a long glittering tail of pink and white sparkles, drawn diagonally falling to the lower right, game VFX sprite',
  fx_rauchkugel: 'a small round grey smoke bomb pellet with a short fuse and a puff of purple-grey smoke leaking out, game sprite',
  fx_fluegelschuh: 'a small brown leather boot with two white feather wings on its sides and a speed streak, icon-like game sprite',
  fx_uebel: 'a sick green cartoon face with swirly eyes and a queasy wobbly mouth and a few green bubbles, thick dark outline, comic emote symbol',
};
for (const [name, d] of Object.entries(ABIL))
  jobs.push({ name, refs: [path.join(OUT, 'fx_fireball.jpg')], prompt: `Create ${d}.` + FX_STYLE });

// Geheime Interaktionen (docs/geheimnisse.md): Spezial-Posen und Hintergrund fuer die Szene "Betrunkener Meister".
const SEC_ID = ' IMPORTANT: the FIRST attached image shows the character: keep exactly the same face, hair, colors and outfit. The SECOND attached image is ONLY a pixel-art style reference (do NOT draw its character).';
jobs.push({ name: 'sec_brunhilde_fass', refs: [ref('kq5h0v'), ref(STYLE_REF)], prompt: 'Create a dynamic dialogue portrait of Brunhilde, the muscular female brewmaster with red braided hair and headband and leather apron, caught mid-throw: she hurls a huge wooden beer barrel with both arms to the right across the picture, the barrel flying right at the edge of the frame with foamy beer splashing out of it, fierce but cheerful grin, strong dramatic action pose, leaning forward, upper body.' + SEC_ID + PORTRAIT_TAIL });
jobs.push({ name: 'sec_lin_betrunken', refs: [ref('51gj00'), ref(STYLE_REF)], prompt: 'Create a dynamic dialogue portrait of Master Lin, the kung fu fighter with red sleeveless mandarin jacket and white sash, now in drunken-master style: soaked in golden beer, flushed red cheeks, a goofy confident half-lidded grin, swaying in a loose drunken stance with one arm holding his long wooden staff behind his back and the other hand held up in a beckoning gesture, a small gourd flask hanging from his sash, little dizzy stars and beer drops around him, upper body, seen from slightly below like a hero shot.' + SEC_ID + PORTRAIT_TAIL.replace('character on the left side of the image, upper body, facing right, nothing on the right half', 'character on the right side of the image, upper body, facing left, nothing on the left half') });
jobs.push({ name: 'bg_betrunken', refs: [ref(STYLE_REF)], prompt: 'Create a wide cinematic pixel-art background (no characters at all): a cozy village tavern courtyard at golden dusk, wooden barrels and long tables, strings of warm glowing paper lanterns, a stone well, tavern building with lit windows in the distance, warm amber light shafts, a few foam bubbles and beer-gold sparkles floating in the air, painterly pixel-art with depth, empty center space for two characters. Same pixel-art style as the attached image (use it ONLY as a style reference, do NOT draw its character). Wide 16:9 landscape image, no text, no border.' });

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
