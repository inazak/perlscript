# perlscript

for me, it's still useful.


## mailsend.pl

simple mail sender.

```
mailsend.pl [-debug] [-from] [-to] [-subject] [-message] [files ...]
  -debug   ... not send
  -from    ... email address
  -to      ... email address
  -subject ... subject string
  -message ... sjis textfile for mailbody
  files    ... attach files
```



## texttable.pl

a command-line tool convert TSV into ascii-text-table.

```
texttable.pl [options] file
    -d,   --delim=s   field Delimiter
    -t,   --title     divide first line as Title
    -r,   --right     Right Align
    -n,   --noline    No line
```

```
$ cat a.tsv.txt
Name OS Since
alice MacOS 2013/11/01
bob Windows 2012/03/03
john Linux 2001/07/01

$ texttable.pl -t a.tsv.txt
+-------+---------+------------+
| Name  | OS      | Since      |
+-------+---------+------------+
| alice | MacOS   | 2013/11/01 |
| bob   | Windows | 2012/03/03 |
| john  | Linux   | 2001/07/01 |
+-------+---------+------------+
```



## merge.pl

merge two files using a key. key is the string before tab for each line.

```
$ cat a.txt
001     AAAA
002     BBBB
003     CCCC
004     DDDD
005     EEEE
$ cat b.txt
001     XXX
003     YYY
005     ZZZ
$ perl merge.pl a.txt b.txt
001     AAAA    XXX
002     BBBB
003     CCCC    YYY
004     DDDD
005     EEEE    ZZZ
```


## pingb.pl

run ping in background.

```
pingb.pl [options]        ipaddress_or_hostname  (foreground)
pingb.pl [options] --exec ipaddress_or_hostname  (background)


Options:

  -i, --interval n  time to wait interval for ping, in second
                    default is 10 sec

  -d, --days n      number of days to continue
                    default is 7 days

  -h, --help        display this help


example below is performed `ping` every 5 second for 3 days.
  ./pingb.pl -i 5 -d 3 localhost

example below is performed `ping` background.
logfile is recorded in /tmp/YYYYMMDD-hhmmss_hostname_pingb.log .
  ./pingb.pl --exec localhost
```

current pingb use below command pipeline.

```
ping -W 1 -q -c 3 $host |\
  awk -F'/' 'END{ print (/^rtt/? "ok "$6" ms":"NG") }' |\
  xargs -I_ date +"%c $host _"

```



## lift1.pl

move folder in subfolder to current folder. this script works on *windows only*.

```
  there is no option, no argument.
  
  $ lift1.pl

  For example, if the folder structure is as follows,

  current/ ---+-- a/ ---+--- 001/
              |         +--- 002/
              |         +--- 003/
              |
              +-- b/ ---+--- 004/
                        +--- 005/

  The result is as follows.

  current/ ---+--- 001/
              +--- 002/
              +--- 003/
              +--- 004/
              +--- 005/
```


## rip1.pl

move files in subfolder to current folder.
this script works on *windows only*.

```
  there is no option, no argument.
  
  $ rip1.pl

  For example, if the folder structure is as follows,

  current/ ---+-- a/ ---+--- 001.jpg
              |         +--- 002.jpg
              |         +--- 003.jpg
              |
              +-- b/ ---+--- 004.jpg
                        +--- 005.jpg

  The result is as follows.

  current/ ---+--- a___001.jpg
              +--- a___002.jpg
              +--- a___003.jpg
              +--- b___004.jpg
              +--- b___005.jpg
```

failsafe interruption works if the target
file is not one of the following.

```
jpg|jpeg|png|bmp|tiff|txt|zip|rar|lnk|url|mp3|pdf
```


## zeropad.pl

if the number in the file name is not within the specified width,
this script will be completed with zero.

```
  $ zeropad.pl

  For example, if the folder structure is as follows,

  current/ ---+--- any1.jpg
              +--- any10.jpg
              +--- any100.jpg

  The result is as follows.

  current/ ---+--- any001.jpg
              +--- any010.jpg
              +--- any100.jpg

  OPTION
    -width=N       N is padding width.

  $ zeropad.pl -width=5

  current/ ---+--- any00001.jpg
              +--- any00010.jpg
              +--- any00100.jpg
```


## only_in_that_file.pl

extract lines only in one file.

```
  $ only_in_that_file.pl [-that=FILE] FILE1 FILE2 [..FILE]

  For example,

  $ cat a.txt
  good
  news
  bad
  news

  $ cat b.txt
  world
  news

  $ cat c.txt
  beautiful
  world

  $ perl only_in_that_file.pl a.txt b.txt c.txt
  only in file 'c.txt':   beautiful
  only in file 'a.txt':   good
  only in file 'a.txt':   bad

  $ perl only_in_that_file.pl -that=c.txt a.txt b.txt c.txt
  only in file 'c.txt':   beautiful
```


## asciitab.pl

create guitar tablature from formatted text.

```
$ cat text.txt
% Title  : Test tune
% Author : suki yaki
%
/
12 23 32
13
12
512 40 39 20
17 27
/
%
% 
/
  34 44 54
  25
  612 39 20
  612 310 29
/
  34 44 54
  25
  612 39 20
  612 310 29
/
$
$ perl asciitab.pl test.txt
 Title  : Test tune
 Author : suki yaki

|-2-3-2----7-|
|-3------0-7-|
|-2------9---|
|--------0---|
|-------12---|
|------------|


|-----------|-----------|
|---5--0--9-|---5--0--9-|
|-4----9-10-|-4----9-10-|
|-4---------|-4---------|
|-4---------|-4---------|
|-----12-12-|-----12-12-|
$
```

