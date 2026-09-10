# GPT Image 2.5: production workflow for Circus Overflow

Updated 2026-09-10 after reviewing the official OpenAI release notes, prompting guide, and image editor documentation.

The sprite pass also follows OpenAI's public `game-studio/sprite-pipeline`: one
approved seed, one complete strip per action and direction, shared scale and anchor,
then an in-engine preview. This is more consistent than generating frames separately.

## Model strategy

- Use GPT Image 2.5 Sunburst for approved key art, character masters, difficult transparent cutouts, and edits where consistency matters more than latency.
- Use Flare only for exploration or after it passes the same acceptance checks as Sunburst. Keep prompt, references, dimensions, and quality fixed during comparison.
- Keep generation parameters separate from the creative brief. High quality is a testable setting, not a descriptive word in the prompt.
- Generate at a useful master resolution; downscale only in the engine or deterministic asset pipeline.

## Strengths we should exploit

- Reference-led subject preservation: approve one character master and use it as the anchor for later poses.
- Precise edits: request one local change at a time and explicitly repeat what must remain unchanged.
- Multi-turn consistency: continue from the accepted image instead of regenerating a complex asset from scratch.
- Transparent backgrounds: request actual transparency for characters and props, save PNG/WebP, and inspect the alpha channel.
- Complex layouts and richer textures: use the model for room key art and detailed props, then build gameplay geometry separately.

## Weaknesses and safeguards

- A beautiful room image does not contain collision data. Rebuild all walkable bounds and interactive hotspots in Godot.
- A generated pose is not automatically a coherent animation. Never trust a large sprite sheet without checking silhouette, scale, foot contact, anatomy, and identity frame by frame.
- Selection-based edits may extend outside the selection. Restate invariants and compare the complete image after every edit.
- More detail can reduce gameplay readability. Reserve the brightest values for the player, exits, and active props; keep the central walking floor calm.
- Higher quality settings do not guarantee a better result. Change one variable at a time and keep the first result that passes acceptance criteria.
- GPT Image 2.5 may visually draw a checkerboard instead of encoding alpha. Check
  the exported file rather than trusting the preview. This project retains raw
  sheets and runs `tools/clean_checker_alpha.py` to produce verified RGBA assets.

## Prompt structure

Use this order for every production request:

1. Asset type and in-game use.
2. Scene or character subject.
3. Camera and composition.
4. Original visual language, palette, materials, and lighting.
5. Gameplay constraints: readable floor, silhouette, padding, scale, transparency.
6. Invariants and explicit avoid list.

Do not request a direct imitation of an existing title. Translate references into broad qualities: surreal digital theatre, playful unease, readable retro-RPG staging, handmade detail, and our plum/cyan/gold palette.

## Character pipeline

1. Approve a single full-body Miro master on transparent background.
2. Lock identity: porcelain face shape, cyan diamond eye, gold round eye, asymmetric teal/magenta tails, plum jacket, curled shoes.
3. Create one full strip per direction as an edit of that master. Do not generate
   individual frames independently.
4. Specify exact ordered phases: contact, recoil, passing, high point, then the
   mirrored phases for the opposite foot.
5. Normalize canvas, pivot, foot line, scale, and alpha with deterministic tooling.
6. Preview at gameplay size and tune frame duration in Godot. Animation quality is judged in motion, not on the sprite sheet.

The vertical slice uses separate eight-frame GPT Image 2.5 strips for walking up,
down, and right. Left is mirrored from right to avoid unnecessary identity drift.
Godot adds smooth acceleration, shadow response, and playback timing.

## Room pipeline

1. Generate an orthographic 16:9 room with a clearly empty central walking zone.
2. Treat the accepted image as a visual layer, not level geometry.
3. Add collision shapes around walls and painted props.
4. Place separate interaction coordinates and visual feedback.
5. Add deterministic particles, light pulses, UI, and sound in Godot so the room feels alive without regenerating it.

## Acceptance checklist

- Character identity survives every frame and edit.
- Feet share one ground line; no crop, extra limbs, halo, or opaque background.
- Player remains readable at 100–140 px tall.
- Room has an uninterrupted navigable area and obvious object silhouettes.
- Collisions match the painting closely enough that the player never walks through furniture.
- Each interactive prop has feedback before input and a clear response after input.
- Test the full sequence, not only individual generated images.

## Official sources

- https://openai.com/index/introducing-chatgpt-images-2-5/
- https://developers.openai.com/api/docs/guides/image-prompting
- https://help.openai.com/en/articles/11084440-im
- https://developers.openai.com/blog/how-to-build-games-with-astra
- https://github.com/openai/plugins/blob/main/plugins/game-studio/skills/sprite-pipeline/SKILL.md
