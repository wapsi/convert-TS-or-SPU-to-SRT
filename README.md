# convert-TS-or-SPU-to-SRT
## Bash script to convert DVB subtitles from SPU (XML + PNGs) or directly from MPEG-TS stream into SRT subtitle file

convert-TS-or-SPU-to-SRT.sh is a script which converts DVB subtitles (directly from TS stream or from
extracted SPU (XML + PNGs) format to SRT format. It uses ImageMagick (needs to be installed) to convert
PNGs to more OCR detectable format and then tesseract-ocr (needs to be installed) to perform the OCR.

If TS stream is set as input the script uses ccextractor (needs to be installed) to extract the
subtitles into SPU (XML + PNGs) format first.

This script has been tested with HD DVB subtitles used by the Finnish national broacast company YLE.

convert-TS-or-SPU-to-SRT.sh usage:
-i --input:    input file (could be a TS stream or SPU XML file) - mandatory

-l --lang:     select subtitle language to be extraceted (fin, swe, eng for example) - mandatory

-o --output:   output file (SRT file) - mandatory

-f --force:    force overwrite if output file exists

-c --charset:  charset for the output SRT file (utf8, iso-8859-1 or ascii for example, using console default if not set)

-s --shift:    shift subtitle timing by +- seconds (+10.5 or -3 for example)

-t --tempdir:  set custom temporary dir (using /tmp/convert-TS-or-SPU-to-SRT if not set)

Pleas note that This script is tested only on Linux (Debian, CentOS) and it needs some external tools to work
(like **tesseract-ocr** (mandatory), **ImageMagick (convert)** (mandatory), **iconv**, **ccextractor**, **bc**). These tools could be found
from Debian / Ubuntu repos or you can grab the sources and install them manually:
- https://github.com/tesseract-ocr/
- https://imagemagick.org/index.php
- https://www.gnu.org/software/libc/libc.html (iconv)
- https://github.com/CCExtractor/ccextractor
- https://www.gnu.org/software/bc/

Thx to Jiku, kamara from Ubuntu FI forums: https://forum.ubuntu-fi.org/index.php?topic=51035.20
