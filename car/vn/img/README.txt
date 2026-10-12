Image files for the visual novel live here.

NAME CONVENTION
  A directive `@ img leg_pool` loads, in order:
      vn/img/leg_pool.png
      vn/img/leg_pool.webp
      vn/img/leg_pool.jpg
  So drop a file named after the image and use that name in the script.
  A full path also works: `@ img res://vn/img/whatever.png`.

BUILT-IN NAMES (no file needed)
  none / off    clears the illustration
  black         flat black backdrop
  white         flat white backdrop

PROLOGUE - one plate, camera does the work
  The prologue used to call four separate illustrations. It is now ONE painted
  plate with the camera doing the work (@ img / @ zoom / @ pan / @ tremble), so
  the two names below both point at the same image. The intention is to collapse
  them into a single `@ img chaac_pov`.

  The plate: Jupiter dead centre above, a single piece of powered armour - a leg,
  boot plate and knee joint - lying discarded and pointing away, with a dark red
  trail spilling from it across the ground toward the viewer, curling.
  No figure in frame.

  leg_pool    both = the same plate   (chaac_pov_v1; source: chaac_pov_src)
  stomp

  Note: because the image is identical, re-issuing `@ img` returns early and
  keeps the current zoom/pan instead of fading the same picture in again.

  Still missing: the glitch-reveal image (the figure he sees in the camera feed).
  Add a `# ART:` note and an `@ img <id>` on that beat when it exists.

A missing file does not crash - it logs a warning and shows the plain backdrop.

SUPPORTED FORMATS
  .png (recommended), .webp, .jpg
