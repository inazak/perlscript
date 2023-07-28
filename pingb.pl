#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use Cwd;

## check ping utilities option
`ping -h 2>&1 | grep -e "W timeout" > /dev/null 2>&1`;
if ($? != 0) {
  print("current os's ping version is not available\n");
  exit 2;
}


my $exec = undef;
my $ival = 10;
my $days = 7;

GetOptions(
  'i|interval=i' => \$ival,  
  'd|days=i'     => \$days,  
  'x|exec'       => \$exec,  
  'h|help'       => sub { pod2usage( -exitval => 1 ) },
) or do { pod2usage( -exitval => 1) };


my $host = shift or pod2usage( -exitval => 1 );
my $starttime = time();

## run in background
if (defined $exec) {

  my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time); $year += 1900; $mon += 1;
  my $date = sprintf("%04d%02d%02d-%02d%02d%02d", $year ,$mon, $mday, $hour, $min, $sec);

  system( join(" ", (
    "nohup",
    "$0 $host",
    "-i $ival",
    "-d $days",
    ">> /tmp/${date}_${host}_pingb.log",
    "2>&1",
    "< /dev/null",
    "&",
  )));
  exit 0;
}


## run in foreground
while(1) {
  system( join( " ", (
    "ping",
    "-W 1 -q -c 3",
    "$host",
    "|",
    qq{awk -F'/' 'END{ print (/^rtt/? "ok "\$6" ms":"NG") }'},
    "|",
    "xargs -I_ date +'%c $host _'",
  )));

  sleep $ival;

  if ((($starttime - time()) / 86400 ) > $days) {
    exit 0;
  }
}

__END__

=head1 NAME

pingb -- run ping in background 

=head1 SYNOPSIS

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



=head1 OVERVIEW

  pingb.pl make it easy to call the linux ping utility with 
  usefull parameters.

  current pingb use below command pipeline.

  ```
  ping -W 1 -q -c 3 $host |\
    awk -F'/' 'END{ print (/^rtt/? "ok "$6" ms":"NG") }' |\
    xargs -I_ date +"%c $host _"
  
  ```

  the following operations are intended.

  1) ping timeout is 1000msec.
  2) ping count is 3 times.
  3) check ping summary output, and get avg rtt.
  4) display with date


=cut


