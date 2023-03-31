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

ignoreerrors=false

# Check if input file exists
[[ -f ${input} ]] || { echo "File $input doesn't exist."; exit; }
# Check output file ending
[[ "$output" =~ ".m3u" ]] || output="${output}.m3u"

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
search() { #$1 songtitle
	result=$(find "$music" -iname "$1")
	if [[ -z "$musicfile" ]] && (( $(grep -c . <<<"$result") > 1 )); then
		echo "found more than one entry for $1"
		echo "$result"
		songtochose=1
		# let user choose
		[[ $ignoreerrors == false ]] && {
			tput bel
			read -p "   Please chose song (1-$(echo "$result" | wc -l)): " songtochose < /dev/tty
		}
		result="$(echo "$result" | head -$songtochose | tail -1)"
		echo "   chose $songtochose: ${result}"
	fi
	musicfile="$result"
}
notfound() { #$1 artist, $2 title
	# try removing "remastered" ending
	newtitle="$2"
	[[ "$newtitle" =~ "Remaster" ]] && {
		newtitle="$(cut -d'-' -f1 <<<"$newtitle" | xargs)"
	}
	search "$1 -*- $newtitle*"
	[[ -z "$musicfile" ]] || { addline "$musicfile"; return; }
	# try without artist
	search "*- $newtitle*"
	[[ -z "$musicfile" ]] && NOT_FOUND_ARR+=("$file") || addline "$musicfile"
}
findfile() { #$1 artist, $2 title
	file="$1 -*- $2.*"
	search "$file"
	[[ -z "$musicfile" ]] && notfound "$1" "$2" || addline "$musicfile"
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

# write songs into file
touch ".${output:0:${#output}-4}_notfound"
for entry in "${NOT_FOUND_ARR[@]}"; do
	echo "$entry"
done

# finish
