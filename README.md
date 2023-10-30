# Map Downloader

Automatically download missing maps.

[Download Plugin](https://github.com/spiretf/mapdownloader/raw/master/plugin/mapdownloader.smx)

## Usage

To use the plugin simple change the level using `rcon changelevel ...` as normal, the plugin will detect when you're trying to load a non existing map and will automatically attempt to download the map before changing to it.

## Configuration

You can control the location where it tries to download the map from by setting `sm_map_download_base` (defaults to `'https://fastdl.serveme.tf/maps'`)

The plugin looks for maps at `${sm_map_download_base}/${map_name}.bsp`
