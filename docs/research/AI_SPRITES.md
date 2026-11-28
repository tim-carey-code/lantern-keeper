# AI for NPC and monster sprites: options brief

Researched 2026-11-27. This answers the owner's question: "Can we get GPT or a space on hugging face that can draw our NPC sprites and monster sprites?" ([DECISIONS][dec]).

**Key:** **UNVERIFIED** means I couldn't confirm it from an accessible primary source. *Inference* marks my own reasoning. I ran no model or Space, signed up for nothing and paid for nothing.

**Our targets** (from our own docs, not the web):
- Source art uses 16×16 tiles drawn at 2× (32 px on screen) ([DECISIONS §art style][dec]).
- People and the keeper use **32×32 frames**. The keeper sheet is 24×8. NPCs need idle loops of 2–4 frames ([ART_CHECKLIST][art]).
- One **14-colour palette**: `source/palette/lantern-keeper-14.gpl` ([ART_CHECKLIST][art]).
- Policy already decided: **AI images are concept references unless the owner says otherwise** ([DECISIONS][dec]).
- This machine has an **RTX 2070 with 8 GB VRAM** (checked with `nvidia-smi`). That rules out most modern local models (§2).

## Summary

1. GPT Image can't draw a 32×32 sprite directly. The smallest output is 655,360 px, about 810×810 ([OpenAI guide][oai-guide]). Every GPT sprite has to be shrunk and cleaned up.
2. OpenAI warns that the models "may occasionally struggle to maintain visual consistency for recurring characters". That is exactly the animation-frame problem ([guide, Limitations][oai-guide]).
3. GPT Image does support reference images, edits, masks and transparent PNG/WebP output ([guide][oai-guide]). That makes it a strong **concept** tool and a usable rough-sprite tool.
4. Under OpenAI's API terms we own the output ([Services Agreement §4.1][oai-sa]). Copyright in the US still needs human authorship. Prompts alone aren't enough, but human edits and arrangement count ([US Copyright Office][usco]).
5. On Hugging Face, the cleanest licence chains are Apache-2.0 LoRAs on Apache-2.0 bases ([FLUX.2-klein-4B][klein], [Z-Image-Turbo][zit]). Both bases need 13–16 GB of VRAM, which is more than our 8 GB.
6. Older SDXL and SD1.5 pixel models fit smaller GPUs. They're unmaintained (last updated 2023), and their OpenRAIL licences come with use restrictions ([pixel-art-xl][pxl], [OpenRAIL-M][railm]).
7. Paid, purpose-built tools (Retro Diffusion, PixelLab) claim true-grid pixel art, 4/8-direction rotations and animation from one image. I have **not tested** any of these claims.
8. Steam requires an AI disclosure in the Content Survey for any pre-generated AI content that ships ([Steamworks][steam]). itch.io requires the AI Disclosure tag and "strictly enforc[es]" it for some page types ([itch.io][itch]).
9. **Gemini ("Nano Banana")**, added after the owner asked:
   - Google's docs claim strong multi-reference character consistency: up to 14 references, 4–5 of them characters. Gemini 3 Pro Image also takes 3 style references ([Gemini guide][gem-guide]).
   - It costs roughly $0.03–0.13 per 1K image ([pricing][gem-price]), and every image carries a SynthID watermark.
   - There's no transparent-background option, no pixel mask and no free API tier for these models (§1b). It's a useful second opinion for concept art, not a replacement.
10. **Recommendation:** use GPT Image for concept sheets now. Pilot it for rough sprite drafts that the owner redraws in Pixelorama, with one monster as a test. Keep the keeper, the final palette pass and the attack telegraphs hand-made. Don't run local Hugging Face models on this GPU.

---

## 1. OpenAI image models (what we already have)

**What the API offers** ([image generation guide][oai-guide]):
- **Two endpoints.** Generations creates from a prompt. Edits creates from "one or more images as a reference", or edits a region under a mask. The guide's own example uses 4 input images.
- **Multi-turn editing** is available through the Responses API.
- **Transparent backgrounds:** set `background: "transparent"` with PNG or WebP output. The guide doesn't list which models support this. Per-model support for our `gpt-image-2` and `gpt-image-1.5` is **UNVERIFIED**; the brief says our tool supports it.
- **Size limits:** edges must be multiples of 16, the longest edge 3840 px or less, and between **655,360** and 8,294,400 pixels in total. `gpt-image-2` follows the same rules ([guide, earlier models][oai-guide]). *Inference:* a native 32×32 or 128×128 output is impossible, so every sprite needs downscaling.
- **Input fidelity:** `gpt-image-2` always processes input images at high fidelity, so detail from a reference image carries through. The trade-off is more input tokens ([guide][oai-guide]).
- **Animated GIF output** (2–16 frames) exists, but only on the GPT-Image-2.6 Sunburst and Flare models ([guide][oai-guide]). Our tool has 2.5, 2 and 1.5, so we can't use it until 2.6 is configured. *Inference:* a GIF would still need re-gridding frame by frame.
- **Documented limits** ([guide, Limitations][oai-guide]):
  - consistency for recurring characters can slip;
  - "Composition Control … may have difficulty placing elements precisely in structured or layout-sensitive compositions". That covers sprite-sheet grids.

**What it does badly at pixel art.** *Inference, not tested here:*
- It produces *pixel-style* images, with soft edges, a drifting grid and hundreds of colours. It doesn't produce a true grid.
- Asking for a whole sheet in one image tends to give unevenly spaced frames, and proportions change from frame to frame. This follows from the two documented limits above.
- Retro Diffusion sells a "Pixel Art Fixer" aimed squarely at this ("760×760 soft input → 115×116 true pixels") ([Retro Diffusion][rd]). That's a vendor claim, but it shows the problem is well known.

**Ownership and terms:**
- **API (our setup):** "Customer … owns all Output. OpenAI hereby assigns to Customer all OpenAI's right, title, and interest, if any, in and to Output." Customer Content isn't used for training unless we opt in ([Services Agreement §4.1–4.2][oai-sa]).
- **Restrictions:** don't use output to build competing models, and don't violate third parties' rights ([§3.3][oai-sa]).
- **Consumer Terms of Use:** they also assign Output to the user, and add that output "may not be unique" ([Terms of Use][oai-tou]). They also forbid "Represent[ing] that Output was human-generated when it was not" ([Terms of Use][oai-tou]).
- **Sharing & Publication Policy:** asks that AI content be labelled "in a way no user could reasonably miss" ([Sharing & Publication][oai-share]).
- **Pricing:** GPT-Image-2.5 charges $8 per million image-input tokens and $30 per million image-output tokens ([guide, costs][oai-guide]). I have no cost per sprite; that depends on size and quality.

## 1b. Google Gemini image models ("Nano Banana")

Added 2026-11-27 after the owner asked "What about gemini?". Our tool can't use these until a `GEMINI_API_KEY` is set, and none is set now.

**Names (verified).** Google officially uses "Nano Banana" as "the name for Gemini's native image generation capabilities" ([Gemini image guide][gem-guide]):

| Nickname | Model ID | Status (model page) | Google's positioning |
|---|---|---|---|
| Nano Banana 2 | `gemini-3.1-flash-image` | Stable, updated Feb 2026 ([model page][gem-flash]) | "Previous-generation high-efficiency workhorse". Google recommends **Nano Banana 2.1** (`gemini-nano-banana-2.1`) for new projects ([guide][gem-guide]) |
| Nano Banana Pro | `gemini-3-pro-image` | Stable, updated Nov 2025 ([model page][gem-pro]) | "Premium choice for complex visual tasks", using "Thinking" ([guide][gem-guide]) |
| Nano Banana | `gemini-2.5-flash-image` | Legacy | Google points users to newer models ([guide][gem-guide]) |

**Character consistency and editing** ([guide][gem-guide]):
- **References:** up to 14 in total.
  - Flash Image and Nano Banana 2.1: up to **4 character** images and 10 object images.
  - 3 Pro Image: up to **5 character** images, 6 object images and **3 style references**.
  - *Inference:* Pro's style slots are the closest fit for "match the owner's hand-made sprite". It's also more than our OpenAI tool's 5 references (that limit comes from the task brief).
- **Multi-turn editing.** For turnarounds, the guide's own tip is "include previously generated images in subsequent prompts to maintain consistency". That's the same edit-from-the-previous-frame method as §4.
- **"Inpainting (Semantic masking)"** is done by prompt ("change only the [element] … keep everything else exactly the same"). The guide doesn't document an uploaded pixel mask. OpenAI's Edits endpoint does take one ([OpenAI guide][oai-guide]).
- **Limits:** the guide says the model "won't always follow the exact number of image outputs" requested. It doesn't document any consistency limit for frames. *Inference:* expect the same frame drift as GPT, and test it before trusting it.

**Pixel art** (*inference*; Google makes no pixel-art claim):
- **Output sizes:** 1:1 outputs are 1024, 2048 or 4096 px. **Flash Image alone adds 512×512** ([guide, sizes][gem-guide]). 512 is exactly 32×32 at 16×, the smallest native size of any API here, which makes a clean 1/16 nearest-neighbour downscale easier. Nano Banana 2.1 drops the 512 size.
- **No transparent-background option** is documented ([guide, output configuration][gem-guide]). The guide's sticker template asks for a plain coloured background instead. So we'd need a flat chroma-key colour (e.g. magenta) and a colour-key step in Pixelorama. *Inference.*
- **True grids:** the same fake-pixel, palette-creep and drift traps as GPT (§5) apply. **UNVERIFIED** until we test it.

**Terms, ownership and SynthID:**
- **Ownership:** "Google won't claim ownership over that content. You acknowledge that Google may generate the same or similar content for others" ([Gemini API Additional Terms][gem-terms]). That's a non-claim, not an assignment like OpenAI's (§1). *Inference:* in practice it's similar for us, and US copyright still depends on the human pass ([USCO][usco]).
- **Age and audience:** users must be 18 or older. The services can't be used in an app "directed towards or is likely to be accessed by individuals under the age of 18" ([terms][gem-terms]). *Inference:* we'd only use it offline to make art, and the game never calls the API.
- **Free data use:** on free use (AI Studio or unpaid quota), Google may use inputs and outputs to improve products, and "human reviewers may read" them. That doesn't apply on Paid Services, or if the account has active billing ([terms][gem-terms]). *Inference:* only send the owner's hand-made art on a paid key.
- **Prohibited Use Policy:** bans "misrepresenting the provenance of generated content by claiming it was created solely by a human" ([policy][gem-pup]).
- **SynthID:**
  - "All generated images include a SynthID watermark" ([guide][gem-guide]).
  - Google says it's invisible, doesn't change quality and is "designed to stand up to modifications like cropping, adding filters … or lossy compression" ([SynthID][synthid]).
  - The Additional Terms don't mention SynthID (searched). Whether it survives a 1/16–1/32 downscale, palette quantising and a hand redraw is **UNVERIFIED**. Either way, disclose on Steam and itch.io (§5).

**API pricing** (paid tier; checked 2026-11-27 on [Gemini pricing][gem-price]):

| Model | Per image (standard) | Free tier |
|---|---|---|
| `gemini-nano-banana-2.1` | $0.0336 at 1K, $0.0504 at 2K | "Not available" |
| `gemini-3.1-flash-image` | $0.045 at 512px, $0.067 at 1K, $0.101 at 2K | "Not available" |
| `gemini-3-pro-image` | $0.134 at 1K or 2K, $0.24 at 4K; plus about $0.0011 per input image | "Not available" |

Notes:
- Nano Banana 2.1 batch output costs half ($15 per million tokens instead of $30).
- The general pricing page offers a free tier with "limited access to certain models", but each of these image models lists the free tier as "Not available".
- Whether image generation is free to try in Google AI Studio is **UNVERIFIED**. The page only says certain grounding features "can be tested" there.

**Compared with OpenAI for our pipeline:**

| Need | OpenAI (configured) | Gemini (not configured) |
|---|---|---|
| Transparent PNG | Yes, `background: "transparent"` ([guide][oai-guide]) | Not documented, so chroma-key it |
| Smallest square output | About 810 px (655,360 px minimum) | **512 px** (Flash Image only) |
| Style or character references | Several reference images (5 in our tool) | Up to 14; Pro has 5 character and 3 style slots |
| Region edits | Pixel mask on the first image | Prompt-only "semantic masking" |
| Frame animation | GIF output on 2.6 only (not ours) | None documented |
| Output rights | Assigned to us | Google "won't claim ownership" |
| Watermark | Not researched | SynthID on every image |
| Cost per 1K-class image | Not stated per image (token-based) | $0.034–0.134 |

## 2. Hugging Face options

Hosted Spaces are mostly 2022–2023 wrappers around the models below. The most-liked "pixel art" Spaces date from 2022–2024 ([HF Spaces search][hf-spaces]). *Inference:* a Space runs on someone else's account and can sleep or vanish. Treat Spaces as demos, not as a pipeline.

A LoRA's own licence isn't enough: the **base model's** licence also applies. Model cards checked 2026-11-27 via the HF API.

| # | Model (card) | What it does | Licence: LoRA / base | Commercial outputs? | Local VRAM | Last updated | Hosted Space? |
|---|---|---|---|---|---|---|---|
| 1 | [Limbicnation/pixel-art-lora][limb] | Pixel character sprites, 512×512 **RGBA with transparency**, 4 steps, ComfyUI workflow included | Apache-2.0 / Apache-2.0 ([FLUX.2-klein-4B][klein]) | Yes. Base is "available for commercial use". The card says the training data is all CC0 | Base ~**13 GB** ([klein][klein]); CPU offload is shown as a way to save VRAM | 2026-05-28 | None listed |
| 2 | [tarn59/pixel_art_style_lora_z_image_turbo][tarn] | General pixel-art style; trigger "Pixel art style." | Apache-2.0 / Apache-2.0 ([Z-Image-Turbo][zit]) | Licences allow it. The card **doesn't state its training data (UNVERIFIED provenance)** | Base "fits comfortably within **16G** VRAM" ([zit][zit]) | 2025-11-30 | Yes, 17 Spaces (e.g. Z-Image-Turbo-LoRA-DLC) |
| 3 | [nerijs/pixel-art-xl][pxl] | Most-used SDXL pixel LoRA (40k downloads/month); "Downscale 8 times … (use Nearest Neighbors)" | CreativeML OpenRAIL-M / OpenRAIL++ (SDXL) | Yes, with use restrictions. "Licensor claims no rights in the Output" ([OpenRAIL-M][railm]) | **UNVERIFIED** (not on card); SDXL is the most likely to fit 8 GB | 2023-11-09 (unmaintained) | Yes, ~100 Spaces |
| 4 | [Onodofthenorth/SD_PixelArt_SpriteSheet_Generator][ono] | SD checkpoint for **front/back/left/right** views (trigger words `PixelartFSS/BSS/LSS/RSS`) | Tagged Apache-2.0. The base SD1.x model isn't named, so the **licence chain is UNVERIFIED** | Unclear | **UNVERIFIED** | 2023-05-05 (unmaintained) | Yes, 17 Spaces |
| 5 | [Angais/MOSS-Image-PixelArt-16x16][moss] | **16×16 item icons** on magenta for colour-keying; reports 0.988 grid purity. "No … characters in poses" | Apache-2.0 / Apache-2.0 | Yes. The training data is listed as CC0 synthetic | About **30 GB** | 2026-11-08 | None |

Notes:
- **#1 is the best fit on paper:** sprites, transparency, a clean licence chain and a CC0 data claim. Its weak points:
  - it needs a development build of diffusers (`>= 0.37.0.dev0`) ([card][limb]);
  - 13 GB is more than our 8 GB, so it would need CPU offload;
  - *Inference:* the RTX 2070 doesn't support bf16 natively, so it would be slow, and whether it works at all is **UNVERIFIED**.
- **#4 is the only model aimed at multi-view sheets.** Its own card says consistency needs merging with another model plus img2img work. It suggests mirroring left and right ([card][ono]).
- **#5 suits loot and inventory icons** (relevant to the ARPG gear plan), not monsters. It's too large to run on this machine.
- **Avoid:**
  - [UmeAiRT FLUX.1-dev LoRA][ume]: the LoRA is MIT, but its base is FLUX.1-dev, which is gated. I couldn't read its output terms (**UNVERIFIED**).
  - Krea-2 LoRAs such as [e-n-v-y/Krea-2-Pixel-Art][krea]: the base uses a gated "krea-2-community-license" (**UNVERIFIED**).
  - [sWizad/pokemon-trainer-sprite-pixelart][hf-models]: licence "other", and it's trained to imitate one franchise's look. That conflicts with our original-content rule.

## 3. Dedicated pixel-art and sprite tools

**Retro Diffusion** ([site][rd], [pricing][rd-price]):
- **Pricing:** pay as you go, no subscription. RD Lite costs $0.05 per image, RD Core $0.10 and RD Pro $0.18. "Advanced Animations" start at $0.10 per run; most moves cost $0.14.
- **Animation:** 4–16 looping frames from one image of your own character, with transparent backgrounds and sheet export.
- **Free in-browser tools:** Pixel Art Fixer, K-Centroid downscale, Palette Converter and Color Reducer. The site says these run on your device, with "nothing … uploaded".
- **Also offered:** API and MCP server.
- **Output ownership and commercial terms: UNVERIFIED.** The terms page renders by script and I couldn't read it.

**PixelLab** ([site][pl], [terms][pl-tos]):
- **Features:** 4 and 8 directional rotations from concept art plus an optional reference sprite; animation from text or a skeleton; "style-consistent generation" from reference images; a browser editor and an Aseprite extension.
- **Terms:** "You own the copyrights to your creations, permitting usage for both commercial and non-commercial purposes". Outputs may not train other models. Users must also follow the CreativeML Open RAIL-M ([ToS §1.3, 3.3, 4.1][pl-tos]).
- **Subscription prices: UNVERIFIED** (the plans load by script).

**Aseprite** ([site][ase]): paid editor, not AI. It has tagged animations, onion skin, sprite-sheet and texture-atlas export, and RotSprite rotation. The exact price is **UNVERIFIED**.

**Pixelorama** (the owner's tool):
- Open source under MIT; latest release v1.2.4, 2026-11-03 ([GitHub][pxo-gh]).
- **Import:** opens a PNG as a "Spritesheet (new project)" with a frame grid or "smart slice" ([Import][pxo-imp]).
- **Palette quantising:**
  - **Palettize** maps "each color … to the nearest color in the palette" ([Image effects][pxo-fx]).
  - Palettes can be built "From Current Sprite" ([Palettes][pxo-pal]).
- **Pixelize** averages blocks. That is useful for a quick look, but it isn't a clean downscale ([Image effects][pxo-fx]).
- **Export:** a sprite sheet with chosen rows and columns, with Nearest interpolation for resizing ([Save and export][pxo-exp]).
- **Effects:** loads Godot 4 `canvas_item` shaders as custom effects ([Image effects][pxo-fx]).

*Inference:* Pixelorama covers every clean-up and sheet step below. Neither AI tool needs Aseprite, because PixelLab also runs in the browser ([PixelLab FAQ][pl]).

## 4. Practical pipeline (GPT Image, then Pixelorama, then Godot)

1. **Reference pack.** Use the owner's hand-made sprite (e.g. the Post Lamp `.pxo`, or a 32×32 person) scaled up 16–32× with nearest-neighbour. Add a palette swatch image of `lantern-keeper-14.png`. Edits accept several reference images ([guide][oai-guide]).
2. **Generate large, one pose per image.**
   - Use the Edits endpoint with the references, `background: "transparent"`, PNG and 1024×1024 ([guide][oai-guide]).
   - Prompt for "pixel art, 32×32 sprite scaled up 32×, hard edges, no anti-aliasing, top-down three-quarter view, limited to the colours in the swatch".
   - *Inference:* one frame per image is safer than whole sheets, given the composition limit.
3. **Downscale with nearest-neighbour** to 32×32. That's 1/32 for a 1024 output, the same "downscale … nearest" method the pixel-art-xl card recommends ([pxl][pxl]).
   - If the model's implied grid isn't a clean 32 px, plain nearest-neighbour picks the wrong pixels (*inference*).
   - Retro Diffusion's free in-browser Fixer and K-Centroid tools target this case ([rd][rd]). Try them before redrawing.
4. **Quantise** in Pixelorama: load the 14-colour palette, then run Image effects → **Palettize** ([fx][pxo-fx]).
5. **Hand clean-up in Pixelorama:**
   - outline continuity;
   - remove stray single pixels ("orphans");
   - re-light from our light direction;
   - check the silhouette at 1×.
   *Inference:* expect most of the craft to happen here.
6. **Build the sheet:** frames go in the timeline, then **Export → Spritesheet** with fixed rows and columns ([export][pxo-exp]). Match existing layouts (the keeper uses 32×32 frames in a 24×8 sheet) ([ART_CHECKLIST][art]).
7. **Godot:**
   - Create an AnimatedSprite2D, then New SpriteFrames → "Add frames from a Sprite Sheet". Set the horizontal and vertical counts and pick frames ([Godot 2D sprite animation][g-anim]).
   - Since Godot 4.0, texture filtering is set on CanvasItem, with a project default ([Importing images][g-imp]). Our `project.godot` already sets `default_texture_filter=0` (Nearest).
   - Keep Lossless compression, "the recommended setting for pixel art" ([Importing images][g-imp]).
   - Use integer scaling for crisp pixels ([Multiple resolutions][g-res]).

**Keeping a character consistent across frames:**
- **Reference images:** always send the approved idle frame as the first reference.
- **Pose sheet:** generate one front/side/back turnaround as concept art, then work from it. Onodofthenorth's card describes the same approach: choose the best view and mirror left and right ([ono][ono]).
- **Edit from the previous frame:** pass frame *n* as the input and ask for frame *n+1* (a small change), using a **mask** over only the moving limbs. Masks apply to the first input image ([guide][oai-guide]).
- **Small frame counts by hand.** NPCs need 2–4-frame idles ([ART_CHECKLIST][art]). *Inference:* it's often faster for the owner to draw frames 2–4 from an AI-assisted frame 1 than to fight drift.

**Known limits:**
- OpenAI documents consistency drift and layout imprecision ([guide][oai-guide]).
- *Inference:* at 32×32 a single drifted pixel on an eye or outline is visible, so expect a hand pass on every frame.
- Attack *telegraphs* (owner priority) depend on timing and readable anticipation frames. Design those by hand.

## 5. Risks

**Licence and commercial use:**
- **OpenAI API:** we own the output ([§4.1][oai-sa]), but it "may not be unique" ([ToS][oai-tou]). We must not infringe third-party rights ([§3.3][oai-sa]), so never prompt with another game's characters or names.
- **Copyright:** the US Copyright Office says AI output is protected only where a human determined "sufficient expressive elements". Prompts alone don't qualify; creative modification does ([USCO Part 2][usco]). *Inference:* the hand clean-up pass is also what makes our sprites protectable.
- **HF models:** check both the LoRA and the base. OpenRAIL models carry use restrictions that pass down to users ([OpenRAIL-M §5][railm]). FLUX.1-dev and Krea-2 bases are gated and their terms are UNVERIFIED.

**Storefront disclosure:**
- **Steam:** the Content Survey's Generative AI section covers "content that ships with your game and is consumed by players … created with the help of AI tools during development". Valve reviews AI content like any other content, including that it is not "infringing" ([Steamworks Content Survey][steam]). *Inference:* if any AI-derived sprite ships, we disclose it.
- **itch.io:** projects that contain generative-AI material must be tagged in the **AI Disclosure** section and appear on the "AI Assisted" browse page. Enforcement is strict for asset, soundtrack, physical game, comic and book pages ([itch.io quality guidelines][itch]). itch.io also de-indexes games "predominantly created by … AI with minimal human intervention" ([same][itch]).
- **OpenAI** asks for clear AI labelling when sharing ([Sharing & Publication][oai-share]).
- *Inference:* concept-only use that doesn't ship is generally outside these rules. The Steam text targets content "that ships". Keep a log of which assets had AI input.

**Quality traps** (*inference* unless cited):
- fake pixels: mixed pixel sizes and sub-pixel anti-aliasing (the problem the RD "Fixer" exists for, [rd][rd]);
- palette creep;
- inconsistent outline thickness;
- wrong perspective (side view instead of our top-down three-quarter);
- proportions changing between frames;
- text or glyph garbage ([guide: text rendering][oai-guide]);
- a look that drifts from the owner's hand-made style, making AI sprites stand out next to hand-drawn ones.

## 6. Recommendation for us

- **Concept art: GPT Image (already configured).**
  - Make monster and NPC concept sheets at full resolution, with the owner's sprite and the palette swatch as references.
  - This matches "concept images first" ([DECISIONS][dec]). It needs no new spend or accounts, and the API terms give us ownership.
- **In-game sprites: AI as an underlay, the owner as the artist.**
  - Pilot one monster (idle plus attack telegraph): GPT edit, then 1/32 nearest-neighbour downscale, then Palettize, then a Pixelorama redraw.
  - Budget for the hand pass on every frame. If the pilot's clean-up takes longer than drawing from scratch, drop AI for sprites.
  - If we want an AI tool that outputs true grids and animations, **trial Retro Diffusion** (pay-per-image, $0.50 free credit; [pricing][rd-price]) or PixelLab. Both need the owner's approval for an account and spend, and Retro Diffusion's terms must be read first.
- **Gemini: an optional second tool, not the main one.**
  - The recommendation **hasn't changed in substance**. OpenAI stays primary because it's already configured, outputs transparent PNGs and takes real pixel masks.
  - If the owner wants it, set a **paid** `GEMINI_API_KEY`. That's a billing account, so it needs the owner's approval.
  - Run the pilot monster through both: Gemini 3 Pro Image with the owner's sprite as a style reference, and `gemini-3.1-flash-image` at 512 px for draft frames on a magenta background.
  - Keep whichever needs less Pixelorama clean-up.
  - Don't send the owner's art through free AI Studio use, because of the training and human-review terms.
- **Hugging Face:**
  - Don't run local models on this machine. The cleanly licensed options need 13–16 GB of VRAM; we have 8 GB.
  - If a bigger GPU becomes available, **Limbicnation/pixel-art-lora on FLUX.2-klein-4B** is the first candidate: Apache-2.0 throughout, with a CC0 data claim.
  - Treat hosted Spaces as demos only.
- **Stays hand-made:**
  - the keeper;
  - every final palette and outline pass;
  - attack telegraph and anticipation frames;
  - any sprite the owner wants to be distinctly theirs.
- **Disclose** AI-assisted shipped sprites on Steam and itch.io, and record AI use per asset in `assets/CREDITS.md`.

## UNVERIFIED items

- Transparent output support per model for `gpt-image-2` and `gpt-image-1.5`. The guide doesn't list it per model.
- Our tool's "up to 5 reference images" limit. That comes from the brief, not the API docs.
- Local VRAM needs for pixel-art-xl and the Onodofthenorth model. Whether FLUX.2-klein runs usefully on an 8 GB RTX 2070 with offload.
- The base model and licence chain of the Onodofthenorth checkpoint. The training data of the tarn59 LoRA.
- The FLUX.1-dev and Krea-2 licence terms (gated).
- Retro Diffusion's terms on output ownership and commercial use. PixelLab's subscription prices. Aseprite's price.
- All quality claims from Retro Diffusion and PixelLab (vendor marketing, not tested).
- Gemini pixel-art quality and frame-to-frame consistency (no official claim; untested).
- Whether SynthID survives our downscale, palette pass and redraw.
- Whether Gemini image generation is free to try in Google AI Studio.
- A Gemini transparent-background option. None is documented, so I treat it as absent.
- Steam's original January 2024 AI announcement wouldn't render. I used the Steamworks Content Survey documentation instead.

[dec]: ../DECISIONS.md
[art]: ../ART_CHECKLIST.md
[oai-guide]: https://developers.openai.com/api/docs/guides/image-generation
[oai-sa]: https://openai.com/policies/services-agreement/
[oai-tou]: https://openai.com/policies/terms-of-use/
[oai-share]: https://openai.com/policies/sharing-publication-policy/
[usco]: https://www.copyright.gov/newsnet/2025/1060.html
[steam]: https://partner.steamgames.com/doc/gettingstarted/contentsurvey
[itch]: https://itch.io/docs/creators/quality-guidelines#accurately-tag-your-use-of-generative-ai
[hf-spaces]: https://huggingface.co/spaces?search=pixel%20art&sort=likes
[hf-models]: https://huggingface.co/models?search=pixel%20art&sort=downloads
[limb]: https://huggingface.co/Limbicnation/pixel-art-lora
[klein]: https://huggingface.co/black-forest-labs/FLUX.2-klein-4B
[tarn]: https://huggingface.co/tarn59/pixel_art_style_lora_z_image_turbo
[zit]: https://huggingface.co/Tongyi-MAI/Z-Image-Turbo
[pxl]: https://huggingface.co/nerijs/pixel-art-xl
[railm]: https://github.com/CompVis/stable-diffusion/blob/main/LICENSE
[ono]: https://huggingface.co/Onodofthenorth/SD_PixelArt_SpriteSheet_Generator
[moss]: https://huggingface.co/Angais/MOSS-Image-PixelArt-16x16
[ume]: https://huggingface.co/UmeAiRT/FLUX.1-dev-LoRA-Modern_Pixel_art
[krea]: https://huggingface.co/e-n-v-y/Krea-2-Pixel-Art
[rd]: https://retrodiffusion.ai/
[rd-price]: https://retrodiffusion.ai/pricing
[pl]: https://www.pixellab.ai/
[pl-tos]: https://www.pixellab.ai/termsofservice
[ase]: https://www.aseprite.org/
[pxo-gh]: https://github.com/Orama-Interactive/Pixelorama
[pxo-imp]: https://www.pixelorama.org/user_manual/Import
[pxo-fx]: https://www.pixelorama.org/user_manual/image_effects
[pxo-pal]: https://pixelorama.org/user_manual/palettes/
[pxo-exp]: https://www.pixelorama.org/user_manual/save_and_export
[gem-guide]: https://ai.google.dev/gemini-api/docs/image-generation
[gem-flash]: https://ai.google.dev/gemini-api/docs/models/gemini-3.1-flash-image
[gem-pro]: https://ai.google.dev/gemini-api/docs/models/gemini-3-pro-image
[gem-price]: https://ai.google.dev/gemini-api/docs/pricing
[gem-terms]: https://ai.google.dev/gemini-api/terms
[gem-pup]: https://policies.google.com/terms/generative-ai/use-policy
[synthid]: https://deepmind.google/models/synthid/
[g-anim]: https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html
[g-imp]: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html
[g-res]: https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html
