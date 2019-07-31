#!/usr/bin/fish

function return_tempname
#
# returns a filename suitable for temporary files
# takes no arguments
#
set fsuffix tiff
set therandom (random 1587 55000)
set thefinal (echo 'tmp'$therandom)
echo (string join . $thefinal $fsuffix)
end

function return_integer
#
# converts any variable to the sequence of digits present in the original string
# if empty, i.e. if no digits are present, defaults to the number 0
# typically used to parse user input where an integer is the expected result
#
set newint (echo $argv | tr -cd [:digit:])
set newint (math $newint + 0)
echo $newint
end

function return_alphanum
#
# converts any variable to the sequence of any alphanumeric characters present
# takes 2 arguments; the variable and the default string
#
set newstr (echo $argv[1] | tr -cd [:alnum:])
if test -z $newstr
set newstr $argv[2]
end
echo $newstr
end

function return_coords
# returns random co-ordinates on the canvas as a string
# takes as arguments the x dimension and y dimension
#
set xloc (random 1 $argv[1])
set yloc (random 1 $argv[2])
echo (string join , $xloc $yloc)
end

function low_range
# returns lowest range of color channel
# takes as arguments the previous value and the fuzz
#
set minval (math $argv[1] - $argv[2])
if test $minval -lt 1
set minval 1
end
echo $minval
end

function high_range
# returns highest range of color channel
# setup similar to low_range
#
set maxval (math $argv[1] + $argv[2])
if test $maxval -gt 255
set maxval 255
end
echo $maxval
end

# constants
set maxpics 50
set defpics 5
set minpixels 16
set maxpixels 500
# maxpixels may be set higher if desired, but is set to 500 here
# because of the relatively long time taken to generate a 500 x 500 px image
set defpixels 200
set colorfuzz 45
# colorfuzz = how narrow the range of colors is within one image.
# low colorfuzz = little variation in color, high colorfuzz = high variation in color
# values are 1 to 254, but in practice 10 to 80 produces esthetically pleasing results
set deffilebase Default-image

# get desired number of images
echo "How many images do you want to generate? [ 1 - $maxpics ]"
read --prompt-str="default $defpics : " userinput
set totpics (return_integer $userinput)
if test $totpics -eq 0
set totpics $defpics
else if test $totpics -gt $maxpics
set totpics $maxpics
end
echo $totpics images will be generated. \n

# get desired X and Y dimensions of image in pixels
# x dimension
echo "How wide in the X dimension should each image be? [ $minpixels - $maxpixels ]"
read --prompt-str="default $defpixels : " userx
set xpixels (return_integer $userx)
if test $xpixels -eq 0
set xpixels $defpixels
else if test $xpixels -lt $minpixels
set xpixels $minpixels
else if test $xpixels -gt $maxpixels
set xpixels $maxpixels
end
echo Images will have a width of $xpixels pixels. \n
# y dimension
echo "How tall in the Y dimension should each image be? [ $minpixels - $maxpixels ]"
read --prompt-str="default $xpixels : " usery
set ypixels (return_integer $usery)
if test $ypixels -eq 0
set ypixels $xpixels
else if test $ypixels -lt $minpixels
set ypixels $minpixels
else if test $ypixels -gt $maxpixels
set ypixels $maxpixels
end
echo Images will have a height of $ypixels pixels. \n

# get base filename for output images
echo "Enter the base filename for the image files."
echo "Base filenames will have a number appended onto them."
echo "If your base filename is foo your image files will be foo_1.jpg foo_2.jpg ..."
read --prompt-str="Default basename is $deffilebase : " userfile
if test -z $userfile
set fbase $deffilebase
else
set fbase (return_alphanum $userfile $deffilebase)
end
echo Image files will begin with $fbase \n
set tmp1 (return_tempname)
set tmp2 (return_tempname)
set imgcount 0

# generate images
for imagenum in (seq $totpics)
set paintradius (math $xpixels / 7)
set paintradius (math "round($paintradius)")
set paintradius1 (math $paintradius - 10)
if test $paintradius1 -lt 1
 set paintradius1 1
 end
set currfbase (string join _ $fbase $imagenum)
set currfilename (string join . $currfbase jpg)
if test -e $currfilename
echo File $currfilename already exists. Skipping - no image generated.
else
echo Generating $currfilename
set r[1] (random 0 255)
set g[1] (random 0 255)
set b[1] (random 0 255)
for i in (seq 3)
set point[$i] (return_coords $xpixels $ypixels)
if test $i -gt 1
set colorfuzz (math $colorfuzz + 5)
# calc r g b with fuzz factor
set minrange (low_range $r[1] $colorfuzz)
set maxrange (high_range $r[1] $colorfuzz)
set r[$i] (random $minrange $maxrange)
set minrange (low_range $g[1] $colorfuzz)
set maxrange (high_range $g[1] $colorfuzz)
set g[$i] (random $minrange $maxrange)
set minrange (low_range $b[1] $colorfuzz)
set maxrange (high_range $b[1] $colorfuzz)
set b[$i] (random $minrange $maxrange)
end
# just ended testing if i is 2 or 3
end
# just ended the loop for i in seq 3
set z (string join x $xpixels $ypixels)
convert -size $z canvas\:black $tmp1
set bary1 $point[1] rgb\($r[1],$g[1],$b[1]\)
set bary2 $point[2] rgb\($r[2],$g[2],$b[2]\)
set bary3 $point[3] rgb\($r[3],$g[3],$b[3]\)
set bary (string join ' ' $bary1 $bary2 $bary3)
set first convert $tmp1 -sparse-color Barycentric \'
set last \' $tmp2
eval $first $bary $last
convert $tmp2 -auto-gamma -paint $paintradius -gaussian-blur 2x0.5 -paint $paintradius1 -gaussian-blur 2x0.5 -paint 3 -gaussian-blur 2x0.5 $currfilename
rm $tmp1
rm $tmp2
set imgcount (math $imgcount + 1)
end
# ended the else part of the filename check
end
# just ended the loop for each image to be generated
echo Generated $imgcount images
