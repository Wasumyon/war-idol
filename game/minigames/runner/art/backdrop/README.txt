Slice backdrop layers
=====================

io_battlefield.webp  The original single painting (opaque). Still used by the VN.
                     Kept here as the flat fallback.
io_sky.webp          Sky layer. The original, with the band just under the
                     terrain silhouette replaced by a *mirrored* sky fill (real
                     sky pixels, continuous, no terrain). Opaque.
io_terrain.png       Terrain layer. The original with alpha 0 above the
                     silhouette, RGBA.

Wiring (run.tscn -> Backdrop):
  Sky     albedo_texture = io_sky.webp       forward_factor 0.002
  Far     albedo_texture = io_terrain.png    forward_factor 0.014   (transparency = alpha)

The two layers must NOT be coplanar. On the same plane the alpha-blended
terrain loses the depth test against the opaque sky on some frames and the sky
fill is drawn over it (a flicker). So Far is at z=-340, y=24, scale 0.78 and Sky
is behind it at z=-707, y=45.7, scale 1.605: the same apparent size seen from
the camera's rest position (0, 3.5, 7), so at rest they still composite like the
original. If you move one layer, rescale it about the camera the same way.

The depth gap gives real parallax on a strafe or jump (the terrain slides about
twice as far as the sky). The terrain layer also sinks ~7x faster, so it drifts
down against the sky/planet as you drive: roughly 30px over a 90s run; the sky
fill covers it.

The terrain layer needs at most (differential) px of fill above the silhouette;
FILLD in the split tool is 80, so there is plenty of headroom.

Revert to the single flat image:
  set BackFar_1.albedo_texture = io_battlefield.webp
  remove BackFar_1's "transparency = 1"
