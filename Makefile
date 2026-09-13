tool_nsconv := tool/nullstars-conv

map_proj := world/nullstars.tiled-project
map_src_dir := world/world
map_dst_dir := source/datafiles/base/world

map_targets := $(wildcard $(map_src_dir)/*.tmj)
map_outputs := $(patsubst %.tmj,%.nsm,$(foreach x,$(notdir $(map_targets)),$(map_dst_dir)/$(x)))

asset_src_dir := asset
asset_dst_dir := source/datafiles/base

all: $(map_outputs) $(map_dst_dir)/root.nsw $(asset_dst_dir)/tiles.png

$(map_dst_dir)/%.nsm: $(map_src_dir)/%.tmj
	cargo +nightly -Z unstable-options -C $(tool_nsconv) build
	$(tool_nsconv)/target/debug/nullstars-conv room $< $@

$(map_dst_dir)/root.nsw: $(map_src_dir)/root.world
	cargo +nightly -Z unstable-options -C $(tool_nsconv) build
	$(tool_nsconv)/target/debug/nullstars-conv world $< $@

$(asset_dst_dir)/%.png: $(asset_src_dir)/%.aseprite
	aseprite $< -b --save-as $@
