#!/usr/bin/perl -s -wl
# netftp_sample.pl

use strict;
use Net::FTP;

#-- Update here when you want to change the default parameter
my $ftp_server = 'server1';
my $ftp_dir    = '/dokoka';
my $ftp_user   = "";
my $ftp_pass   = "";
#--

our ($debug, $dir);

if(defined $dir) { $ftp_dir = $dir; }

foreach my $file (@ARGV){
  if(! -e $file){
    die "ERROR: $file not found.";
  }
}

if(defined $debug){
}

if(!defined $debug){
  my $ftp = Net::FTP->new($ftp_server) or die "ERROR: FTP Connect Fail";
  $ftp->login($ftp_user, $ftp_pass)    or die "ERROR: FTP Login Fail";
  $ftp->cwd($ftp_dir)                  or die "ERROR: FTP ChangeWD Fail";
  $ftp->binary                         or die "ERROR: FTP ChangeMode Fail";
  foreach my $file (@ARGV){
    $ftp->put($file)                   or die "ERROR: FTP Put Fail";
  }
  $ftp->quit;
}

exit(0);

