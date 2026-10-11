extends RichTextEffect

## Subscript / superscript for the VN.
##
## Stock Godot BBCode has no [sub] or [sup], so the VN ships its own effect.
## Two instances are registered per label with different .bbcode values:
##
##   ^x^    -> superscript   (rise negative: up)
##   ,,x,,  -> subscript     (rise positive: down)
##
## Tilde was avoided for subscript because Chip's lines use ~ as a style mark.

var bbcode := "sub"
var rise := 5.0


func _process_custom_fx(c: CharFXTransform) -> bool:
	c.offset.y += rise
	return true
