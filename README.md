# convert-TS-or-SPU-to-SRT
## Bash script to convert DVB subtitles from SPU (XML + PNGs) or directly from MPEG-TS stream into SRT subtitle file

convert-TS-or-SPU-to-SRT.sh is a **bash script** which converts DVB subtitles (directly from TS stream or from
extracted SPU (XML + PNGs) format to SRT format. It uses ImageMagick (needs to be installed) to convert
PNGs to more OCR detectable format and then tesseract-ocr (needs to be installed) to perform the OCR.

If TS stream is set as input the script uses ccextractor (needs to be installed) to extract the
subtitles into SPU (XML + PNGs) format first.

This script has been tested with HD DVB subtitles used by the Finnish national broacast company YLE.

convert-TS-or-SPU-to-SRT.sh usage:
* -i --input:    input file (could be a TS stream or SPU XML file) - mandatory
* -l --lang:     select subtitle language to be extraceted (fin, swe, eng for example) - mandatory
* -o --output:   output file (SRT file) - mandatory
* -f --force:    force overwrite if output file exists
* -c --charset:  charset for the output SRT file (utf8, iso-8859-1 or ascii for example, using console default if not set)
* -s --shift:    shift subtitle timing by +- seconds (+10.5 or -3 for example)
* -t --tempdir:  set custom temporary dir (using /tmp/convert-TS-or-SPU-to-SRT if not set)

Pleas note that This script is tested only on Linux (Debian, CentOS) and it needs some external tools to work
(like **tesseract-ocr** (mandatory), **ImageMagick (convert)** (mandatory), **iconv**, **ccextractor**, **bc**). These tools could be found
from Debian / Ubuntu repos or you can grab the sources and install them manually:
- https://github.com/tesseract-ocr/
- https://imagemagick.org/index.php
- https://www.gnu.org/software/libc/libc.html (iconv)
- https://github.com/CCExtractor/ccextractor
- https://www.gnu.org/software/bc/

Please note that I'm not responsible if this software does not work as it should (if it damages your computer or files eg.). Please be free to make it better by sending pull requests or submitting issues if you find any!

You can fine tune tesseract, convert or ccextractor arguments by editing following lines at the beginning of the script:
```
# Fine tune convert arguments if needed
CONVERTSRGS="-trim -bordercolor black -border 50x5 -resize 300% -negate -alpha remove -background black"
# Fine tune tesseract arguments if needed
TESSERACTARGS=""
# Fine tune ccextractor arguments if needed
CCEXTRACTORARGS="-out=spupng -noteletext"
```

Thx to Jiku, kamara from Ubuntu FI forums: https://forum.ubuntu-fi.org/index.php?topic=51035.20

## Examples:

Converting existing SPU (XML + PNGs) file into SRT using (using Finnish language, needed for OCR):
```
$ ./convert-TS-or-SPU-to-SRT.sh -i /tsmuxer/test/subs/subs.xml -o /tsmuxer/OUT.srt -l fin
Starting to process SPU (XML + PNGs) subtitle file: /tsmuxer/test/subs/subs.xml
Processing subpicture no. 17
Output file /tsmuxer/OUT.srt created, script finished
```

Converting MPEG-TS file's Finnish DVB subtitles into SRT, verbose mode activated, shifting timing +15.5 seconds, converting the final SRT file into iso-8869-1 charset and using custom temporary directory
```
$ ./convert-TS-or-SPU-to-SRT.sh -i /tsmuxer/test/TestiTeema.ts -o /tsmuxer/OUT.srt -l fin -v -s +15.5 -f -c iso-8859-1 --tempdir /tmp/TSTEMP
Input file is TS stream, extracting fin DVB subtitles from the stream to SPU format first (by using ccextractor)...
CCExtractor 0.88, Carlos Fernandez Sanz, Volker Quetschke.
Teletext portions taken from Petr Kutalek's telxcc
--------------------------------------------------------------------------
Input: /tsmuxer/test/TestiTeema.ts
[Extract: 1] [Stream mode: Autodetect]
[Program : Auto ] [Hauppage mode: No] [Use MythTV code: Auto]
[Timing mode: Auto] [Debug: No] [Buffer input: No]
[Use pic_order_cnt_lsb for H.264: No] [Print CC decoder traces: No]
[Target format: .xml] [Encoding: UTF-8] [Delay: 0] [Trim lines: No]
[Add font color data: Yes] [Add font typesetting: Yes]
[Convert case: No] [Video-edit join: No]
[Extraction start time: not set (from start)]
[Extraction end time: not set (to end)]
[Live stream: No] [Clock frequency: 90000]
[Teletext page: Autodetect]
[Start credits text: None]
[Quantisation-mode: CCExtractor's internal function]

-----------------------------------------------------------------
Opening file: /tsmuxer/test/TestiTeema.ts
File seems to be a transport stream, enabling TS mode
Analyzing data in general mode
Ignoring stream language 'swe' not equal to dvblang 'fin'
100%  |  03:30
Number of NAL_type_7: 0
Number of VCL_HRD: 0
Number of NAL HRD: 0
Number of jump-in-frames: 0
Number of num_unexpected_sei_length: 0

Min PTS:				00:00:02:795
Max PTS:				00:03:33:196
Length:				 00:03:30:401
Done, processing time = 4 seconds

No captions were found in input.
Issues? Open a ticket here
https://github.com/CCExtractor/ccextractor/issues
ccextractor's exit code was 10: There were some issues most probably (try to run this script in verbose mode to see possible errors / warnings)!
Starting to process SPU (XML + PNGs) subtitle file: /tmp/TSTEMP/subs.xml

Processing subpicture no. 1
Start (shifted): 00:00:15,500
End (shifted):   00:00:17,660
Converting subs.d/sub0001.png to more OCR detectable format
Runnung OCR against subpicture no. 1
Warning: Invalid resolution 0 dpi. Using 70 instead.
Estimating resolution as 905
OCR returned text:
Jokaisella aistilla, -

Processing subpicture no. 2
Start (shifted): 00:00:17,700
End (shifted):   00:00:21,819
Converting subs.d/sub0002.png to more OCR detectable format
Runnung OCR against subpicture no. 2
Warning: Invalid resolution 0 dpi. Using 70 instead.
Estimating resolution as 901
OCR returned text:
näkö-, kuulo-,
maku-, tunto- ja hajuaistilla, -

Processing subpicture no. 3
Start (shifted): 00:00:21,900
End (shifted):   00:00:24,620
Converting subs.d/sub0003.png to more OCR detectable format
Runnung OCR against subpicture no. 3
Warning: Invalid resolution 0 dpi. Using 70 instead.
Estimating resolution as 864
OCR returned text:
voi nauttia kauneudesta.

Processing subpicture no. 4
Start (shifted): 00:00:24,700
End (shifted):   00:00:29,461
Converting subs.d/sub0004.png to more OCR detectable format
Runnung OCR against subpicture no. 4
Warning: Invalid resolution 0 dpi. Using 70 instead.
Estimating resolution as 866
OCR returned text:
Kauneudentaju
saattaa olla tärkein vaistomme.

Processing subpicture no. 5
Start (shifted): 00:02:07,023
End (shifted):   00:02:12,740
Converting subs.d/sub0005.png to more OCR detectable format
Runnung OCR against subpicture no. 5
Warning: Invalid resolution 0 dpi. Using 70 instead.
Estimating resolution as 875
OCR returned text:
Kauneudella ja kulttuurilla voi olla
myönteisiä vaikutuksia terveyteen.

Processing subpicture no. 6
Start (shifted): 00:02:13,779
End (shifted):   00:02:20,459
Converting subs.d/sub0006.png to more OCR detectable format
Runnung OCR against subpicture no. 6
Warning: Invalid resolution 0 dpi. Using 70 instead.
Estimating resolution as 869
OCR returned text:
Aihe herättää kiinnostusta,
ja väite on osoitettu todeksi.

Processing subpicture no. 7
Start (shifted): 00:02:20,902
End (shifted):   00:02:24,220
Converting subs.d/sub0007.png to more OCR detectable format
Runnung OCR against subpicture no. 7
Warning: Invalid resolution 0 dpi. Using 70 instead.
Estimating resolution as 870
OCR returned text:
Tieteelliset tutkimukset osoittavat, -

Processing subpicture no. 8
Start (shifted): 00:02:24,261
End (shifted):   00:02:33,501
Converting subs.d/sub0008.png to more OCR detectable format
Runnung OCR against subpicture no. 8
Warning: Invalid resolution 0 dpi. Using 70 instead.
Estimating resolution as 873
OCR returned text:
että taideteokset, teatteriesitykset
ja kaikenlaiset kulttuurielämykset -

Processing subpicture no. 9
Start (shifted): 00:02:33,622
End (shifted):   00:02:37,260
Converting subs.d/sub0009.png to more OCR detectable format
Runnung OCR against subpicture no. 9
Warning: Invalid resolution 0 dpi. Using 70 instead.
Estimating resolution as 905
OCR returned text:
lisäävät paitsi
psykofyysistä hyvinvointia -

Processing subpicture no. 10
Start (shifted): 00:02:37,462
End (shifted):   00:02:39,701
Converting subs.d/sub0010.png to more OCR detectable format
Runnung OCR against subpicture no. 10
Warning: Invalid resolution 0 dpi. Using 70 instead.
Estimating resolution as 869
OCR returned text:
myös elimistön hyvinvointia.

Processing subpicture no. 11
Start (shifted): 00:02:40,020
End (shifted):   00:02:46,699
Converting subs.d/sub0011.png to more OCR detectable format
Runnung OCR against subpicture no. 11
Warning: Invalid resolution 0 dpi. Using 70 instead.
Estimating resolution as 864
OCR returned text:
Voimme esimerkiksi mitata
kortisolin eli stressihormonin tasoa -

Processing subpicture no. 12
Start (shifted): 00:02:46,740
End (shifted):   00:02:50,901
Converting subs.d/sub0012.png to more OCR detectable format
Runnung OCR against subpicture no. 12
Warning: Invalid resolution 0 dpi. Using 70 instead.
Estimating resolution as 902
OCR returned text:
koehenkilöillä
ennen taidenäyttelyyn menemistä.

Processing subpicture no. 13
Start (shifted): 00:02:51,021
End (shifted):   00:02:57,700
Converting subs.d/sub0013.png to more OCR detectable format
Runnung OCR against subpicture no. 13
Warning: Invalid resolution 0 dpi. Using 70 instead.
Estimating resolution as 873
OCR returned text:
Kun tehdään uusi mittaus
taidenäyttelyssä käynnin jälkeen, -

Processing subpicture no. 14
Start (shifted): 00:02:58,261
End (shifted):   00:03:02,780
Converting subs.d/sub0014.png to more OCR detectable format
Runnung OCR against subpicture no. 14
Warning: Invalid resolution 0 dpi. Using 70 instead.
Estimating resolution as 868
OCR returned text:
kortisolitaso
on laskenut huomattavasti.

Processing subpicture no. 15
Start (shifted): 00:03:02,901
End (shifted):   00:03:04,661
Converting subs.d/sub0015.png to more OCR detectable format
Runnung OCR against subpicture no. 15
Warning: Invalid resolution 0 dpi. Using 70 instead.
Estimating resolution as 867
OCR returned text:
Mistä se kertoo?

Processing subpicture no. 16
Start (shifted): 00:03:04,702
End (shifted):   00:03:10,579
Converting subs.d/sub0016.png to more OCR detectable format
Runnung OCR against subpicture no. 16
Warning: Invalid resolution 0 dpi. Using 70 instead.
Estimating resolution as 868
OCR returned text:
Se kertoo siitä,
että esteettinen elämys -

Processing subpicture no. 17
Start (shifted): 00:03:10,660
End (shifted):   00:03:16,458
Converting subs.d/sub0017.png to more OCR detectable format
Runnung OCR against subpicture no. 17
Warning: Invalid resolution 0 dpi. Using 70 instead.
Estimating resolution as 871
OCR returned text:
on lievittänyt stressiä
ja lisännyt hyvinvointia.

Converting the SRT to iso-8859-1 format
Output file /tsmuxer/OUT.srt created, script finished
```
