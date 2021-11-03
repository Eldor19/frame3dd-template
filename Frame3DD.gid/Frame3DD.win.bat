rem OutputFile: %1.log
rem ErrorFile: %1.err
del %1.3dd
del %1.out
del %1.plt
del %1.if*
del %1.log
del %1.err
del %1.post.res
set FRAME3DD_OUTDIR=%2\outdir
del outdir\%1-m-*
del outdir\%1-msh*
del outdir\frame3dd.3dd
md %2\outdir
rename %1.dat %1.3dd
rem In FRAME3DD version: 20140514+ ANSI escape sequences used to print output with colours
rem are printed in stderr too! so we can not use it to check if there are errors. so we're 
rem redirecting stderr to file .garbage and if .out doesn't exists rename to .err to show it
rem %3\exe\frame3dd.exe -i %1.3dd -o %1.out -x > %1.log 2> %1.err
%3\exe\frame3dd.exe -i %1.3dd -o %1.out -x > %1.log 2> %1.garbage
del %1.plt
del outdir
if not exist %1.out rename %1.garbage %1.err
del %1.garbage