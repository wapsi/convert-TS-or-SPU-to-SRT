#!/bin/bash
PATH=/usr/local/bin:/usr/bin:/bin:/sbin:/usr/sbin
#
# v0.1 - Initial Release - Miikka Veijonen
#
# This script is tested only on Linux (Debian, CentOS) and it needs some external tools to work
# (like tesseract-ocr, ImageMagick (convert), iconv, ccextractor, bc). These tools could be found
# from Debian / Ubuntu repos or you can grab the sources and install them manually:
# https://github.com/tesseract-ocr/
# https://imagemagick.org/index.php
# https://www.gnu.org/software/libc/libc.html (iconv)
# https://github.com/CCExtractor/ccextractor
# https://www.gnu.org/software/bc/
#
# Thx to Jiku, kamara from Ubuntu FI forums: https://forum.ubuntu-fi.org/index.php?topic=51035.20
#


# Fine tune convert arguments if needed
CONVERTASRGS="-trim -bordercolor black -border 50x5 -resize 300% -negate -alpha remove -background black"
# Fine tune tesseract arguments if needed
TESSERACTARGS=""
# Fine tune ccextractor arguments if needed
CCEXTRACTORARGS="-out=spupng -noteletext"

function printHelp() {
	echo "convert-TS-or-SPU-to-SRT.sh is a script which converts DVB subtitles (directly from TS stream or from
extracted SPU (XML + PNGs) format to SRT format. It uses ImageMagick (needs to be installed) to convert
PNGs to more OCR detectable format and then tesseract-ocr (needs to be installed) to perform the OCR.

If TS stream is set as input the script uses ccextractor (needs to be installed) to extract the
subtitles into SPU (XML + PNGs) format first.

This script has been tested with HD DVB subtitles used by the Finnish national broadcast company YLE.

convert-TS-or-SPU-to-SRT.sh usage:
-i --input:    input file (could be a TS stream or SPU XML file) - mandatory
-l --lang:     select subtitle language to be extraceted (fin, swe, eng for example) - mandatory
-o --output:   output file (SRT file) - mandatory
-f --force:    force overwrite if output file exists
-c --charset:  charset for the output SRT file (utf8, iso-8859-1 or ascii for example, using console default if not set)
-s --shift:    shift subtitle timing by +- seconds (+10.5 or -3 for example)
-t --tempdir:  set custom temporary dir (using /tmp/convert-TS-or-SPU-to-SRT if not set)"
}

function convertTimeToHMSs() {
	msecs=$(echo "$ttconvert"|awk -F'[,.]' '{print $2}')
	secs=$(echo "$ttconvert"|awk -F'[,.]' '{print $1}')
	if [ "$SSHIFT" != "0" ]; then
		nt=$(echo "${secs}.${msecs} + $SSHIFT" | bc -l | awk '{printf "%.3f\n", $0}')
		msecs=$(echo "$nt"|awk -F'.' '{print $2}')
		secs=$(echo "$nt"|awk -F'.' '{print $1}')
	fi
	if [ $secs -lt 0 ]; then
		echo "-1"
		return
	fi
	hms=$(date -d@$secs -u +%H:%M:%S)
	echo "${hms},${msecs}"
}

bold=$(tput bold)
normal=$(tput sgr0)

VERBOSE=0
FORCEOVERWRITE=0
CHARSET=NUL
SSHIFT=0
TEMPDIR="/tmp/convert-TS-or-SPU-to-SRT"
# Processing arguments
POSITIONAL=()
while [[ $# -gt 0 ]]; do
	key="$1"
	case $key in
		-i|--input)
			IFILE="$2"
		shift
		shift
		;;
		-l|--lang)
			LANG="$2"
		shift
		shift
		;;
		-c|--charset)
			CHARSET="$2"
		shift
		shift
		;;
		-s|--shift)
			SSHIFT="$2"
		shift
		shift
		;;
		-o|--output)
			OFILE="$2"
		shift
		shift
		;;
		-v|--verbose)
			VERBOSE=1
		shift
		;;
		-f|--force)
			FORCEOVERWRITE=1
		shift
		;;
		-t|--tempdir)
			TEMPDIR="$2"
		shift
		shift
		;;
		-h|--help)
			printHelp
			exit 0
		shift
		shift
		;;
		*)
			echo "Unknown argument: ${1}, please see -h or --help to see valid arguments"
			exit 1
		;;
	esac
done

# Checking mandatory arguments
if [ "$IFILE" == "" ] || [ "$OFILE" == "" ] || [ "$LANG" == "" ]; then
	printHelp
	exit 1
fi

# Checking tesseract-ocr and its detection languages
bintesseract=$(which tesseract)
if [ $? -ne 0 ]; then
	echo "Could not find tesseract binary, aborting."
	exit 1
fi
if ! $bintesseract --list-langs|egrep -q "^${LANG}$"; then
	echo "Looks like tesseract-ocr is missing the language you set (${LANG}), please install it first before using it"
	exit 1
fi

# Checking for ImageMagick's convert
binconvert=$(which convert)
if [ $? -ne 0 ]; then
	echo "Could not find convert binary (part of ImageMagick), aborting"
	exit 1
fi

# Checking for iconv
if [ "$CHARSET" != "NUL" ]; then
	biniconv=$(which iconv)
	if [ $? -ne 0 ]; then
		echo "Could not find iconv binary, aborting"
		exit 1
	fi
fi

# Checking for ccextractor if input file is TS file
ifext=$(echo "$IFILE"|awk -F'.' '{print $NF}'|tr '[A-Z]' '[a-z]')
if [ "$ifext" == "ts" ]; then
	binccextractor=$(which ccextractor)
	if [ $? -ne 0 ]; then
		echo "Could not find ccextractor binary (needed to extract DVB subs from TS stream), aborting"
		exit 1
	fi
fi

# Cleaning shift arguments and checking for bc
st=$(echo "$SSHIFT"|sed 's/[^0-9\+-.]*//g;s/^+//')
if [ "$st" == "" ]; then
	SSHIFT=0
else
	SSHIFT="$st"
	if [ "$SSHIFT" != "0" ]; then
		binbc=$(which bc)
		if [ $? -ne 0 ]; then
			echo "Could not find bc binary (needed when using -s --shift functionality), aborting"
			exit 1
		fi
	fi
fi

# Verifying temp dir
mkdir -p "$TEMPDIR"
if [ $? -ne 0 ]; then
	echo "Could not create temporary directory (${TEMPDIR}), aborting"
	exit 1
fi
TMPFILE1="$TEMPDIR/convert-spu-to-srt.tmp.xml"
TMPFILE2="$TEMPDIR/convert-spu-to-srt.tmp2.xml"
TMPPNGFILE="$TEMPDIR/imgforocr.png"
touch "$TMPFILE1"
if [ $? -ne 0 ]; then
	echo "Could not create temp file(s) under TMPDIR (${TEMPDIR}), aborting"
	exit 1
fi
touch "$TMPFILE2"
if [ $? -ne 0 ]; then
	echo "Could not create temp file(s) under TMPDIR (${TEMPDIR}), aborting"
	exit 1
fi
touch "$TMPPNGFILE"
if [ $? -ne 0 ]; then
	echo "Could not create temp file(s) under TMPDIR (${TEMPDIR}), aborting"
	exit 1
fi

# Verifying output file
if [ -f "$OFILE" ] && [ $FORCEOVERWRITE -eq 0 ]; then
	echo "Output file $OFILE already exist, aborting (use -f or --force argument to overwrite the output file in case it exists)"
	exit 1
fi
touch "$OFILE"
if [ $? -ne 0 ]; then
	echo "Could not create output file (${OFILE}), aborting"
	exit 1
fi

# Processing input file in case it's a TS stream
INSUBFILE="$IFILE"
if [ "$ifext" == "ts" ]; then
	echo "Input file is TS stream, extracting $LANG DVB subtitles from the stream to SPU format first (by using ccextractor)..."
	INSUBFILE="$TEMPDIR/subs.xml"
	if [ $VERBOSE -eq 0 ]; then
		"$binccextractor" $CCEXTRACTORARGS -dvblang $LANG -o "$INSUBFILE" "$IFILE" > /dev/null 2>&1
	else
		"$binccextractor" $CCEXTRACTORARGS -dvblang $LANG -o "$INSUBFILE" "$IFILE"
	fi
	rt=$?
	if [ $rt -eq 0 ]; then
		echo "ccextractor's exit code was 0: OK"
	else
		echo "ccextractor's exit code was ${rt}: There were some issues most probably (try to run this script in verbose mode to see possible errors / warnings)!"
	fi
fi
INSUBDIR=$(dirname "$INSUBFILE")

echo "Starting to process SPU (XML + PNGs) subtitle file: $INSUBFILE"
echo ""
# Parsing subtitles from input file
cat "$INSUBFILE"|tr -d "\n\r"|sed 's/<spu/\n<spu/g' > "$TMPFILE1"
grep -oP '(?<=<spu).*?(?=>)' "$TMPFILE1" > "$TMPFILE2"
if [ $( wc -l "$TMPFILE2"|awk '{print $1}' ) -lt 1 ]; then
	echo "The script didn't find any subtitles from ${INSUBFILE}, if this is not correct please check the input file or run this script in verbose mode if the SPU subtitles were extracted directly from TS stream"
	exit 1
fi
sc=0
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
# Empty the output file
> "$OFILE"
echo -n ""
while IFS= read -r l; do
	# Sub count (needed for SRT file format)
	sc=$(( $sc + 1 ))
	if [ $VERBOSE -eq 1 ]; then
		echo "Processing subpicture no. $sc"
	else
		echo -en "\e[1A"
		echo -e "Processing subpicture no. $sc"
	fi
	# Parsing timestamps and image filename
	times=$(echo "$l"|awk -F'start="' '{print $2}'|awk -F'"' '{print $1}')
	timee=$(echo "$l"|awk -F'end="' '{print $2}'|awk -F'"' '{print $1}')
	img=$(echo "$l"|awk -F'image="' '{print $2}'|awk -F'"' '{print $1}')
	# Converting timestamp from SPU XML to SRT format
	ttconvert=$times
	srttimes=$(convertTimeToHMSs)
	ttconvert=$timee
	srttimee=$(convertTimeToHMSs)
	if [ "$srttimes" == "-1" ] || [ "$srttimee" == "-1" ]; then
		if [ $VERBOSE -eq 1 ]; then
			echo "Skipping this subpicture because its start/end time is before 00:00:00,000 after shifting"
		fi
		continue
	fi
	if [ $VERBOSE -eq 1 ] && [ "$SSHIFT" != "0" ]; then
		echo "Start (shifted): $srttimes"
		echo "End (shifted):   $srttimee"
	elif [ $VERBOSE -eq 1 ]; then
		echo "Start: $srttimes"
		echo "End:   $srttimee"
	fi
	# Converting image file to more detectable format by OCR
	dimg=$(basename "$img")
	IFS=$SAVEIFS
	if [ $VERBOSE -eq 0 ]; then
		"$binconvert" "$INSUBDIR"/"$img" $CONVERTASRGS "$TMPPNGFILE" 2>/dev/null
	else
		echo "Converting $img to more OCR detectable format"
		"$binconvert" "$INSUBDIR"/"$img" $CONVERTASRGS "$TMPPNGFILE"
	fi
	# Running OCR
	if [ $VERBOSE -eq 1 ]; then
		echo "Runnung OCR against subpicture no. $sc"
		subtext=$("$bintesseract" -l $LANG $TESSERACTARGS "$TMPPNGFILE" stdout|sed -r '/^\s*$/d')
		echo "OCR returned text:
${bold}$subtext${normal}
"
	else
		subtext=$("$bintesseract" -l $LANG $TESSERACTARGS "$TMPPNGFILE" stdout 2> /dev/null|sed -r '/^\s*$/d')
	fi
	IFS=$(echo -en "\n\b")
	if [ $( echo "$subtext"|wc -l ) -eq 0 ]; then
		echo "${bold}Warning:${normal} Subpicture no. $sc returned empty result (no text) from OCR, original PNG file name: $img"
	fi
	# Writing new subpicture in output file
	echo "$sc" >> "$OFILE"
	echo "$srttimes --> $srttimee" >> "$OFILE"
	echo "$subtext"|sed '/^$/d' >> "$OFILE"
	echo "" >> "$OFILE"
done < "$TMPFILE2"
IFS=$SAVEIFS

# Charset conversion
if [ "$CHARSET" != "NUL" ]; then
	echo "Converting the SRT to $CHARSET format"
	# Detecting current charset
	ccset=$(file -bi "$OFILE" | awk -F'charset=' '{print $2}' | awk -F';' '{print $1}')
	if [ "$ccset" == "" ]; then
		echo "Could not detect the current charset of ${OFILE}, skipping charset conversion"
	else
		if [ $VERBOSE -eq 0 ]; then
			"$biniconv" -f "$ccset" -c -t "$CHARSET" "$OFILE" > "$TMPFILE1" 2> /dev/null
			rt=$?
		else
			"$biniconv" -f "$ccset" -c -t "$CHARSET" "$OFILE" > "$TMPFILE1"
			rt=$?
		fi
		if [ $rt -eq 0 ]; then
			rm -f "$OFILE"
			mv "$TMPFILE1" "$OFILE"
		else
			echo "Exit code of iconv was ${rt}, this means errors, renamed the erroneous to ${OFILE}.conv-err, original output file is $OFILE"
			mv "$TMPFILE1" "${OFILE}.conv-err"
		fi
	fi
fi

# Removing temporary files and dir
rm -f "$TMPFILE1" "$TMPFILE2" "$TMPPNGFILE" "$TEMPDIR/subs.d/"*.png
if [ "$ifext" == "ts" ]; then
	rm -f "$INSUBFILE"
fi
rmdir "$TEMPDIR/subs.d" 2> /dev/null
rmdir "$TEMPDIR"

# Script finished
echo "Output file $OFILE created, script finished"
