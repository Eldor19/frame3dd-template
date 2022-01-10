#!/bin/sh
# OutputFile: $1.log
rm -f "$1.3dd"
rm -f "$1.out"
rm -f "$1.plt"
rm -f "$1.if*"
rm -f "$1.log"
#rm -f "$1.err"
rm -f "$1.post.res"
mv "$1.dat" "$1.3dd"
# ANSI escape sequences used to print output with colours
# are printed in stderr too! so we can not use it to check
# if there are errors. so we're redirecting stderr to stdout
#"$3/exe/frame3dd-osx" -i "$1.3dd" -o "$1.out" -x > "$1.log" 2> "$1.err"
#"$3/exe/frame3dd-linux" -i "$1.3dd" -o "$1.out" -x > "$1.log" 2> "$1.err"
"$3/exe/frame3dd" -i "$1.3dd" -o "$1.out" -x > "$1.log" 2>&1
