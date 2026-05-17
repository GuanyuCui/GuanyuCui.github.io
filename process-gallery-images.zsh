#!/bin/zsh
set -euo pipefail

# Usage:
#   ./process-gallery-images.zsh
#   ./process-gallery-images.zsh path/to/gallery
#
# This script uses macOS built-in `sips`.
# It moves image files from gallery/ into gallery/originals/ and creates lighter thumbnails in gallery/thumbs/.
# The HTML version I provided expects the same filename under both folders:
#   gallery/originals/example.jpg
#   gallery/thumbs/example.jpg

GALLERY_DIR="${1:-gallery}"
ORIGINALS_DIR="$GALLERY_DIR/originals"
THUMBS_DIR="$GALLERY_DIR/thumbs"
THUMB_MAX_EDGE="${THUMB_MAX_EDGE:-1800}"
JPEG_QUALITY="${JPEG_QUALITY:-78}"

if [[ ! -d "$GALLERY_DIR" ]]; then
	printf 'Error: directory not found: %s\n' "$GALLERY_DIR" >&2
	exit 1
fi

mkdir -p "$ORIGINALS_DIR" "$THUMBS_DIR"

printf 'Moving root gallery images into %s ...\n' "$ORIGINALS_DIR"

find "$GALLERY_DIR" -maxdepth 1 -type f \( \
	-iname '*.jpg' -o \
	-iname '*.jpeg' -o \
	-iname '*.png' -o \
	-iname '*.heic' -o \
	-iname '*.tif' -o \
	-iname '*.tiff' \
\) -print0 | while IFS= read -r -d $'\0' file; do
	name="${file:t}"
	dest="$ORIGINALS_DIR/$name"

	if [[ -e "$dest" ]]; then
		printf 'Skip move, original already exists: %s\n' "$dest"
	else
		mv "$file" "$dest"
		printf 'Moved: %s -> %s\n' "$file" "$dest"
	fi
done

printf '\nGenerating thumbnails in %s ...\n' "$THUMBS_DIR"

count=0
find "$ORIGINALS_DIR" -maxdepth 1 -type f \( \
	-iname '*.jpg' -o \
	-iname '*.jpeg' -o \
	-iname '*.png' -o \
	-iname '*.heic' -o \
	-iname '*.tif' -o \
	-iname '*.tiff' \
\) -print0 | while IFS= read -r -d $'\0' original; do
	name="${original:t}"
	thumb="$THUMBS_DIR/$name"

	if [[ -e "$thumb" && "$thumb" -nt "$original" ]]; then
		printf 'Up to date: %s\n' "$thumb"
		continue
	fi

	/usr/bin/sips \
		-Z "$THUMB_MAX_EDGE" \
		--setProperty formatOptions "$JPEG_QUALITY" \
		"$original" \
		--out "$thumb" >/dev/null

	printf 'Created thumb: %s\n' "$thumb"
	count=$((count + 1))
done

printf '\nDone. Thumbnail max edge: %s px, JPEG quality hint: %s.\n' "$THUMB_MAX_EDGE" "$JPEG_QUALITY"
printf 'You can override them like this:\n'
printf '  THUMB_MAX_EDGE=1400 JPEG_QUALITY=72 ./process-gallery-images.zsh\n'
