# svg_to_m3u
Playlists downloaded with, for example, [exportify](https://github.com/watsonbox/exportify),
that result in .svg files can be converted to .m3u files with this script.
This script searches for the songs in a specified directory and converts them to a playlist. 

**Warning**, this is quiet a simple script, so there are limitatons to what it can do.
Future implementations might fix some of these:
- This script currently only works, if your music files are formatted as `%artist - *- %title`.
Any other format must be changed in the script directly.
- If there are multiple matches, only the first one will be chosen
