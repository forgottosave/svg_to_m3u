#!/bin/bash

# Define Structure
TAG_ARTIST="Artist Name(s)"
TAG_TITLE="Track Name"

art_id=-1
tit_id=-1

NOT_FOUND_ARR=()

music=$1
input=$2
output=$3

# Check if input file exists
[[ -f ${input} ]] || { echo "File $input doesn't exist."; exit; }

# Playlist conversion
echo "Starting playlist conversion: ${input} -> ${output}..."
exec < $input

# Check for author & song-name position
read header
IFS=',' read -ra ARR <<< "${header}"
ctr=0
for i in "${ARR[@]}"; do
	i="${i:1:${#i}-2}"
	[[ "${i}" == "${TAG_ARTIST}" ]] && art_id=${ctr}
	[[ "${i}" == "${TAG_TITLE}" ]] && tit_id=${ctr}
	ctr=$(($ctr+1))
done

# create m3u file
rm "$output"
touch "$output"
echo "#EXTM3U" >> "$output"
addline() { #$1 filename
	echo "#EXTINF" >> "$output"
	echo "$1" >> "$output"
}

# File finders
notfound() { #$1 artist, $2 title
	# try removing "remastered" ending
	newtitle="$2"
	[[ "$newtitle" =~ "Remaster" ]] && {
		newtitle="$(cut -d'-' -f1 <<<"$newtitle" | xargs)"
	}
	echo "try $newtitle instead of $2"
	search=$(find "$music" -iname "$1 -*- $newtitle*")
	[[ -z "$search" ]] && NOT_FOUND_ARR+=("$file") || addline "$search"
	# try without artist
	search=$(find "$music" -iname "*- $newtitle*")
}
findfile() { #$1 artist, $2 title
	file="$1 -*- $2.*"
	search=$(find "$music" -iname "$file")
	[[ -z "$search" ]] && notfound "$1" "$2" || addline "$search"
}

# Parse every line
while read entry
do
   IFS=',' read -ra ARR <<< "${entry}"
   artist=${ARR[$art_id]}
   artist=$(sed -r "s/[']+/*/g" <<< ${artist:1:${#artist}-2})
   title=${ARR[$tit_id]}
   title=$(sed -r "s/[']+/*/g" <<< ${title:1:${#title}-2})
   findfile "$artist" "$title"
done

# Output not found songs
echo ""
echo "Some songs could not found in your specified music direcory:"
for entry in "${NOT_FOUND_ARR[@]}"; do
	echo "$entry"
done

# finish
