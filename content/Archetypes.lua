--!strict
-- TD visual brief: recognisable anime ARCHETYPES for every unit (owner decision 2026-11-07).
-- Goal: a player reads the genre type at a glance ("the shadow ninja", "the big-sword spirit
-- warrior", "the pirate captain"), but no unit is a specific existing character.
--
-- Rules for anyone making models, portraits or icons from this file:
--   1. Build from Look. Keep every detail listed in Own: those make the character ours.
--   2. Never add anything from Avoid, and never combine two or more signature traits of one
--      well-known character (hair + outfit + weapon + mark). One shared trope is fine; a set is not.
--   3. No franchise symbols, logos, crests, clan marks, exact weapon designs or catchphrases.
--   4. Names stay as they are in Config (chosen by meaning, not by sound).
-- Look here replaces the Look field in content/Units.lua and content/Evolutions.lua.
-- Keyed by live unit id. Style for all: chibi 3D, bold silhouette, readable at TD camera distance.

local A = {}

------------------------------------------------ original 6 (live)
A.Spark = { -- Ren Voltblade
	Archetype = "Hot-headed lightning swordsman (shonen rival type)",
	Look = "Teen swordsman with sharp silver-white hair swept back, yellow lightning-bolt streak, short dark-blue jacket with high collar, fingerless gloves, a straight single-edged blade crackling with electricity, confident grin",
	Own = { "single yellow streak in silver hair", "high-collar dark-blue jacket", "blade with a copper coil guard" },
	Avoid = { "headbands with metal plates", "chidori-style hand lightning", "spiky raven hair with blue outfit" },
}
A.Mortar = { -- Mira Emberfall
	Archetype = "Fiery battle-mage girl (explosive spell caster)",
	Look = "Energetic mage girl with long crimson hair in a high ponytail, short red-and-black robe with golden trim, oversized witch-style hat with ember charms, staff topped with a glowing meteor stone",
	Own = { "meteor-stone staff", "ember charms on hat brim", "golden trim robe" },
	Avoid = { "eyepatch with red-black witch outfit", "crimson cape with a star pattern" },
}
A.Frost = { -- Yuki Frostveil
	Archetype = "Calm ice princess (cool-headed control mage)",
	Look = "Composed girl with straight pale-blue hair to the waist, white and ice-blue layered kimono-dress, a snowflake hair ornament, holding a crystal fan that releases frost",
	Own = { "crystal fan weapon", "single snowflake ornament", "layered kimono-dress cut" },
	Avoid = { "half-white half-red hair", "ice queen with a single braid and blue gown" },
}
A.Tycoon = { -- Baron Goldmane
	Archetype = "Rich noble patron (economy mentor type)",
	Look = "Broad-shouldered noble with a big golden lion-like mane and beard, white suit with gold coat-tails, monocle, cane topped with a coin, smug smile",
	Own = { "coin-topped cane", "lion mane in gold", "white suit with gold tails" },
	Avoid = { "pirate captain coat", "green hair with three swords" },
}
A.Kaze = {
	Archetype = "Quiet wind archer (calm sniper type)",
	Look = "Slim teen with messy dark-green hair over one eye, green hooded scout cloak, light leather armour, tall recurve bow with feather charms, wind ribbons trailing from the arrows",
	Own = { "feather charms on the bow", "hood with a single leaf pin", "wind ribbons on arrows" },
	Avoid = { "hero-of-time green tunic and pointed cap", "green jacket with a wind-sword" },
}
A.Tora = {
	Archetype = "Brawler martial artist (tiger-style fighter)",
	Look = "Stocky muscular teen with short orange hair, tiger-stripe headband tied at the back, sleeveless martial-arts gi with ripped sleeves, wrapped fists, battle-ready stance",
	Own = { "tiger-stripe headband", "ripped-sleeve gi", "tape-wrapped fists" },
	Avoid = { "red headband with white gi and red gloves", "orange gi with a kanji on the back" },
}

------------------------------------------------ pack, first batch (live)
A.Pip = {
	Archetype = "Gadget kid inventor (tinkerer sidekick)",
	Look = "Small teen with spiky copper hair and huge goggles on the forehead, yellow overalls with patches and tool pockets, tesla-coil pistol wrapped in tape, sparks around the hands",
	Own = { "taped tesla pistol", "patched yellow overalls", "copper hair" },
	Avoid = { "blonde girl mechanic with a wrench and pink outfit" },
}
A.Hana = {
	Archetype = "Forest kunoichi (nature ninja girl)",
	Look = "Agile girl with mossy-green twin buns, dark green ninja garb with leaf-shaped shoulder guards, vine slingshot, glowing seed pouch, half-mask of woven leaves",
	Own = { "woven leaf half-mask", "vine slingshot", "twin buns" },
	Avoid = { "pink-haired kunoichi with a forehead protector", "leaf-symbol forehead plates" },
}
A.Gus = {
	Archetype = "Earth-fist bruiser (big friendly tank)",
	Look = "Stocky boy with a buzz cut and headband, sleeveless brown gi, huge stone gauntlets with glowing orange cracks, bare feet, wide stance",
	Own = { "cracked stone gauntlets", "orange glow in the cracks" },
	Avoid = { "bald monk with six dots on the forehead" },
}
A.Rin = {
	Archetype = "Paper-talisman courier girl (shikigami user)",
	Look = "Cheerful girl with a short white bob and a long red scarf, courier satchel, a swarm of folded paper kites and talismans circling her",
	Own = { "paper-kite swarm", "long red scarf", "courier satchel" },
	Avoid = { "paper-angel with blue hair and a paper flower", "shrine-maiden red-white with a gohei" },
}
A.Momo = {
	Archetype = "Tiny shrine helper (mascot support)",
	Look = "Round-cheeked little girl in an orange festival yukata, carrying a paper lantern on a long pole with a small flame spirit inside, bell on the hair ribbon",
	Own = { "flame spirit in the lantern", "bell ribbon", "festival yukata" },
	Avoid = { "fox-eared shrine girl", "small fire-demon mascot with a face" },
}
A.Kaito = {
	Archetype = "Shadow ninja (silent assassin)",
	Look = "Lean ninja with ash-grey hair covering one eye, charcoal hooded haori with torn hem, lower-face mask, twin short daggers trailing purple smoke",
	Own = { "purple smoke daggers", "torn-hem charcoal haori", "ash-grey hair" },
	Avoid = { "silver hair with face mask and one covered eye together with a forehead protector", "black-red cloud cloaks", "single red eye with tomoe" },
}
A.Jin = {
	Archetype = "Blacksmith warrior girl (forge hammer type)",
	Look = "Strong girl with a high brown ponytail and soot on the cheek, leather apron over a red tunic, giant hammer whose head is a blooming iron flower",
	Own = { "iron-flower hammer head", "soot-marked cheek", "leather apron" },
	Avoid = { "red-haired armoured knight girl with a huge hammer and rose motif" },
}
A.Nami = {
	Archetype = "Sea-wind archer (sailor sharpshooter)",
	Look = "Archer with teal side-swept hair and a feather earring, light green hunter coat with sailor collar, recurve bow with spinning wind rings on the tips",
	Own = { "wind rings on the bow tips", "feather earring", "sailor-collar hunter coat" },
	Avoid = { "orange-haired navigator with a staff", "the name used as a nod to any navigator character" },
}
A.Akane = {
	Archetype = "Flame-whip acrobat (circus fighter)",
	Look = "Acrobat with crimson twin tails, black and red ringmaster jacket with gold buttons, burning chain-whip coiled around one arm, playful smirk",
	Own = { "ringmaster jacket", "burning chain-whip", "crimson twin tails" },
	Avoid = { "red-haired whip queen in black leather" },
}
A.Seren = {
	Archetype = "Star scholar (rune-writing support mage)",
	Look = "Scholar with long navy hair and round glasses, star-map cloak, floating open book and a quill that writes glowing runes in the air",
	Own = { "glowing quill runes", "star-map cloak", "floating book" },
	Avoid = { "gold-haired elf mage with a staff and white robes" },
}

------------------------------------------------ pack, second batch (live)
A.Sora = {
	Archetype = "Beach-boy tide caller (water bender type)",
	Look = "Boy with messy sea-blue hair, rolled-up navy shorts, sailor-collar shirt, giant conch shell that sprays water, fish charm necklace",
	Own = { "spraying conch shell", "fish charm" },
	Avoid = { "arrow tattoo on the head", "fish-man with a karate gi" },
}
A.Lumi = {
	Archetype = "Idol priestess (song buffer)",
	Look = "Idol-priestess with pale lilac long hair and star hairpins, white-gold layered stage dress, microphone-shaped staff topped with a glowing flower",
	Own = { "microphone staff with flower", "star hairpins" },
	Avoid = { "twin-tail teal idol", "magical girl with a heart wand and pink bows" },
}
A.Haru = {
	Archetype = "Stoic ice swordsman (cool captain type)",
	Look = "Calm young swordsman with frosty white hair tied low, pale blue haori with a snowflake crest, translucent ice katana resting on the shoulder, breath visible",
	Own = { "ice katana", "snowflake crest", "hair tied low" },
	Avoid = { "short white spiky hair with a turquoise scarf and a dragon-shaped ice blade", "captain haori with a division number" },
}
A.Daichi = {
	Archetype = "Mountain monk (earth-stomp giant)",
	Look = "Huge-shouldered monk with a shaved head and prayer beads made of round boulders, earth-brown robes, stomping pose with cracks under his feet",
	Own = { "boulder prayer beads", "crack effects under feet" },
	Avoid = { "blind giant monk with a stone ball and chain" },
}
A.Valka = {
	Archetype = "Storm warrior queen (lightning valkyrie)",
	Look = "Proud warrior queen with silver braided hair, jagged gold crown crackling with lightning, dark-blue armoured dress with cape, spear shaped like a frozen lightning bolt",
	Own = { "lightning-bolt spear", "jagged gold crown" },
	Avoid = { "blonde armoured knight with an invisible sword and blue dress" },
}
A.Ryu = {
	Archetype = "Dragon-winged sky rider (flame ace)",
	Look = "Sky-rider with black hair streaked ember orange, aviator jacket with fur collar, mechanical wings of charred metal feathers, flame lance",
	Own = { "charred metal wings", "aviator jacket", "flame lance" },
	Avoid = { "pink-haired fire boy with a scale scarf", "black-flame dragon on the arm" },
}
A.Ozu = {
	Archetype = "Old tea merchant (wise money mentor)",
	Look = "Old merchant with a long white mustache and gold-leaf straw hat, emerald robe with coin embroidery, abacus on the back, teapot pouring golden light",
	Own = { "golden-light teapot", "abacus", "gold-leaf straw hat" },
	Avoid = { "short old master with a turtle shell", "bald old man with a long beard and a staff" },
}
A.Kurenai = {
	Archetype = "Eclipse swordswoman (dark elegant blade master)",
	Look = "Elegant swordswoman with black hair fading to crimson tips, eclipse-ring eyes, black kimono with a red moon pattern, long nodachi trailing dark mist, half-moon halo",
	Own = { "eclipse-ring eyes", "red moon kimono pattern", "half-moon halo" },
	Avoid = { "six-eyed demon samurai", "purple-eyed swordsman with a moon-breath style", "tomoe or ripple-pattern eyes" },
}
A.Aeris = {
	Archetype = "Dawn paladin (holy archer knight)",
	Look = "Radiant paladin with short golden hair and a sunburst halo, white and sky-blue plate armour with feather motifs, greatbow shaped like a rising sun",
	Own = { "rising-sun greatbow", "sunburst halo", "feather-motif plate" },
	Avoid = { "blonde knight with a blue skirt and golden sword", "angel-winged archer in white with a heart bow" },
}
A.Tokiya = {
	Archetype = "Time keeper (mysterious clockwork mage)",
	Look = "Mysterious mage with silver hair and one clock-face eye, long dark-teal coat with brass gears, floating pocket-watch shield, hourglass staff with sand flowing upward",
	Own = { "clock-face eye", "upward-flowing hourglass staff", "pocket-watch shield" },
	Avoid = { "red-black gothic girl with a clock eye", "silver-haired maid with throwing knives" },
}

------------------------------------------------ evolved (fall back to base model until made)
A.KaitoNightveil = { Archetype = "Shadow ninja, elite form", Look = "Kaito older: long midnight hooded coat with silver crow-feather trim, hair tied back, curved shadow blades leaving violet afterimages, crow mask at the hip", Own = { "crow mask at the hip", "violet afterimages" }, Avoid = { "red cloud cloak", "masked ninja with a swirl mask" } }
A.KazeGalehawk = { Archetype = "Wind archer, ranger form", Look = "Kaze as a valley scout: hawk-feather cloak, longbow wrapped in red charm paper, ash-grey scarf, a hawk on the shoulder", Own = { "hawk companion", "charm-paper longbow" }, Avoid = { "green hooded archer with a mask and a bow" } }
A.ToraStoneclaw = { Archetype = "Brawler, master form", Look = "Tora as a mountain-temple brawler: tiger-stripe gi, iron tiger-claw gauntlets, shaved sides with a short topknot, prayer beads", Own = { "iron tiger claws", "topknot" }, Avoid = { "red-haired demon karate master" } }
A.HanaBriarshade = { Archetype = "Forest kunoichi, elite form", Look = "Hana as a forest kunoichi: dark green garb with leaf armour, bamboo blowpipe with thorn darts, single long braid, woven-vine mask", Own = { "bamboo blowpipe", "vine mask" }, Avoid = { "leaf-symbol forehead plates" } }
A.YukiPalemoon = { Archetype = "Ice princess, spirit guardian form", Look = "Yuki as a border guardian: white kimono with a pale blue moon crest, translucent ice katana with spirit flame, long silver hair, floating snow lanterns", Own = { "moon crest", "snow lanterns" }, Avoid = { "white kimono snow woman with a single purple sash and ice breath" } }
A.MomoSoulbell = { Archetype = "Shrine helper, spirit form", Look = "Momo as a dusk-city shrine keeper: dark blue yukata with lantern pattern, pole lantern with pale blue spirit fire, big bell on the ribbon", Own = { "blue spirit-fire lantern" }, Avoid = { "fox mask and fox ears together" } }
A.SerenInkveil = { Archetype = "Scholar, spirit archivist form", Look = "Seren as a spirit archivist: ink-black robe with glowing white calligraphy, floating ledger of names, brush-pen staff dripping blue ink, cracked round glasses", Own = { "ledger of names", "brush-pen staff" }, Avoid = { "black notebook with a shinigami", "apple-eating death god" } }
A.RinTalismancer = { Archetype = "Talisman courier, spirit form", Look = "Rin as a spirit courier: white and red courier outfit (not a shrine-maiden cut), swarm of folded talisman-kites, long red scarf, bell earring", Own = { "talisman-kite swarm", "bell earring" }, Avoid = { "red-white shrine maiden with a gohei" } }
A.BaronGoldtide = { Archetype = "Noble patron, merchant-admiral form", Look = "Baron as a merchant-admiral: navy and gold captain's coat, tricorn with a lion crest, golden mane, a floating treasure chest spilling coins", Own = { "lion-crest tricorn", "floating treasure chest" }, Avoid = { "straw hat", "giant pirate with a white crescent mustache" } }
A.NamiStormsail = { Archetype = "Sea archer, ship lookout form", Look = "Nami as a ship's lookout: sailcloth coat, compass on the belt, bow carved from a ship's mast with rope string, teal hair blown by sea wind", Own = { "mast-wood bow", "belt compass" }, Avoid = { "orange-haired navigator with a weather staff" } }
A.AkaneScarletCorsair = { Archetype = "Flame acrobat, corsair form", Look = "Akane as a corsair: crimson long coat with gold trim, black tricorn with a red plume, flaming chain-whip ending in a grappling hook, eyepatch with a flame symbol", Own = { "hook-ended flame whip", "flame-symbol eyepatch" }, Avoid = { "straw hat", "red-haired captain with a missing arm" } }
A.PipCannonwright = { Archetype = "Gadget kid, ship gunner form", Look = "Pip as a ship's gunner-mechanic: brass goggles, sailor vest with tool pockets, hand cannon covered in copper coils, powder-burnt cheeks", Own = { "coil hand cannon" }, Avoid = { "cyborg shipwright with a star-shaped nose and blue hair" } }
A.RenGatebreaker = { Archetype = "Lightning swordsman, ranked hunter form", Look = "Ren as a ranked hunter: dark tactical jacket with a glowing rank badge, lightning blade with a crystal core, sparking hair, fingerless gloves", Own = { "crystal-core blade", "rank badge" }, Avoid = { "black-haired hunter with purple shadow soldiers rising behind" } }
A.MiraCinderqueen = { Archetype = "Battle-mage, S-rank queen form", Look = "Mira as an S-rank fire mage: black and ember robe with crystal shoulder plates, crown of floating embers, staff topped with a red Gate shard", Own = { "ember crown", "Gate-shard staff" }, Avoid = { "red-black witch with an eyepatch" } }
A.JinRunesmith = { Archetype = "Blacksmith, rune smith form", Look = "Jin as a guild smith: rune-etched apron and gauntlets, hammer with a glowing orange rune head, crystal goggles, metal ponytail clasp", Own = { "rune hammer", "crystal goggles" }, Avoid = { "dwarf smith with a braided beard" } }
A.GusCrystalfist = { Archetype = "Earth bruiser, dungeon tank form", Look = "Gus as a dungeon tank: purple crystal gauntlets grown from Gate shards, padded brown armour, scar across the nose, headband with a rank tag", Own = { "Gate-shard gauntlets", "rank-tag headband" }, Avoid = { "rock-skinned giant with a dragon tattoo" } }

return A
