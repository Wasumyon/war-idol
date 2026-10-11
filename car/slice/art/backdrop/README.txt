Slice backdrop layers
=====================

io_battlefield.webp  The original single painting (opaque). Still used by the VN.
                     Kept here as the flat fallback.
io_sky.webp          Sky layer. The original, with the band just under the
                     terrain silhouette replaced by a *mirrored* sky fill (real
                     sky pixels, continuous, no terrain). Opaque.
io_terrain.png       Terrain layer. The original with alpha 0 above the
                     silhouette, RGBA.

Wiring (slice.tscn -> Backdrop):
  Sky     albedo_texture = io_sky.webp       forward_factor 0.002
  Far     albedo_texture = io_terrain.png    forward_factor 0.014   (transparency = alpha)

Both sit at z=-340, y=24, scale 0.78 - coplanar, so at rest they composite
pixel-identically to the original. The terrain layer sinks ~7x faster, so the
terrain drifts down against the sky/planet as you drive. Over a 90s run that is
roughly 30px of terrain sink and ~28px of relative drift; the sky fill covers it.

The terrain layer needs at most (differential) px of fill above the silhouette;
FILLD in the split tool is 80, so there is plenty of headroom.

Revert to the single flat image:
  set BackFar_1.albedo_texture = io_battlefield.webp
  remove BackFar_1's "transparency = 1"
