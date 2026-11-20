---
name: war-idol-image-gen
description: Generate War Idol art (characters, sheets, vehicles, emblems, backgrounds) with the gpt-image tools, using the designated reference sheets in source_art/REFERENCES.md. Use whenever Wesley asks for any image, sheet, concept or study for this project.
---

# War Idol image generation

The list of what counts is `source_art/REFERENCES.md`. This file is only the steps; never
copy descriptions or paths in here.

1. **Look up.** Read `source_art/REFERENCES.md`. Find every subject in the request (a
   character, the insignia, the Cheiro, Io…). If a subject has no entry, or the request
   contradicts its entry, stop and ask Wesley. Don't guess a design.
2. **Write the prompt** for GPT Image, complete and in this order:
   - the aspect ratio in words, from the Sizes line;
   - the house style line (for sheets);
   - for each reference image, one sentence on what to take from it ("use the attached sheet
     for Tank's design: face, hair, outfit, palette");
   - each subject's Prompt line, then what Wesley asked for (pose, scene, mood);
   - any text that must appear, in quotes, spelled exactly;
   - `Avoid:` followed by the subjects' Never lines.
   No file paths in the prompt.
3. **Generate** with `mcp__gpt-image__generate_image`:
   - `reference_images`: the subjects' **Attach** files as absolute paths
     (`E:/Work/AI/war-idols/source_art/...`), at most 16;
   - `model: "gpt-6.1-terra"` (the command-line Codex the tool runs does not know the
     config default, gpt-6.2-astra, and fails without this);
   - `prompt_mode: "exact"` (never "enhance": a rewrite can drop canon details);
   - `output_path`: an absolute path to the subject's **Save to** folder plus a short
     kebab-case file name, e.g. `E:/Work/AI/war-idols/source_art/characters/tank-garage-welding.png`;
   - `count` 1 unless Wesley asks for options; `background: true` for more than one image.
4. **Show Wesley** the result, the saved path, and anything the tool reports changing in
   the prompt. Check it against the Never lines and say plainly where it drifted.
5. **Only on Wesley's say-so**, add or swap the file in the subject's REFERENCES.md entry.
   A generated image is a candidate until then. Commit the image (and any index change).
