map_proj := world/nullstars.tiled-project
map_src_dir := world/world
map_dst_dir := nullstars/datafiles/base/world

map_targets := $(wildcard $(map_src_dir)/*.tmx)
map_outputs := $(patsubst %.tmx,%.nsm,$(foreach x,$(notdir $(map_targets)),$(map_dst_dir)/$(x)))

asset_src_dir := assets
asset_dst_dir := nullstars/datafiles/base

all: $(map_outputs) $(asset_dst_dir)/tiles.png

$(map_dst_dir)/%.nsm: $(map_src_dir)/%.tmx
	tiled --project $(map_proj) --export-map nsmap $< $@

$(asset_dst_dir)/%.png: $(asset_src_dir)/%.aseprite
	aseprite $< -b --save-as $@
