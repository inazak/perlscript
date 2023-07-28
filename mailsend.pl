#!/usr/bin/perl -s -wl
#----------------------
# Script      : mailsend.pl
# Description : send mail with files
# Modified    : 2018/09/16
# Usage       : mailsend.pl [-debug] [-from] [-to] [-subject] [-message] [files ...]
#             :   -debug   ... not send
#             :   -from    ... email address
#             :   -to      ... email address
#             :   -subject ... subject string
#             :   -message ... sjis textfile for mailbody
#             :   files    ... attach files
# --------------------
use strict;
use File::Basename;
use Net::SMTP;
use MIME::Base64;
use Encode;

#-- Update here when you want to change the default parameter
my $smtp_server = 'localhost';
my $mail_from   = 'set-default-address@example';
my $mail_to     = 'set-default-address@example';
my $mail_subject= '[mailsend]';

#-- Do not change follows
our ($debug, $from, $to, $subject, $message);
my $boundary = 'i1n7ai1n7a';

if(defined $from)    { $mail_from    = $from;   }
if(defined $to)      { $mail_to      = $to;     }
if(defined $subject) { $mail_subject = $subject;}
if(defined $message){
  if(! -e $message){
    die "$message not found.";
  }
}
foreach my $file (@ARGV){
  if(! -e $file){
    die "$file not found.";
  }
}

if(defined $debug){
}

if(!defined $debug){
  my $smtp = Net::SMTP->new($smtp_server,Timeout=>60);
  $smtp->mail($mail_from);
  $smtp->to($mail_to);
  $smtp->data();
  $smtp->datasend("MIME-Version: 1.0\n");
  $smtp->datasend("Content-Type: Multipart/Mixed; boundary=$boundary\n");
  $smtp->datasend("Content-Transfer-Encoding: base64\n");
  $smtp->datasend("Subject: ${mail_subject}\n");
  $smtp->datasend("From: ${mail_from}\n");
  $smtp->datasend("To: ${mail_to}\n");
  $smtp->datasend("\n");
  if(defined $message){
    open(FILE, $message) or die "$!";
    read(FILE, my $text, (-s $message));
    close(FILE);
    Encode::from_to($text, 'shiftjis', 'iso-2022-jp');
    $smtp->datasend("--$boundary\n");
    $smtp->datasend("Content-Type: text/plain; charset=ISO-2022-JP\n");
    $smtp->datasend("Content-Transfer-Encoding: 7bit\n");
    $smtp->datasend("\n");
    $smtp->datasend("$text\n");
  }
  foreach my $file (@ARGV){
    my $filename = basename($file,"");
    my $base64filebody = '';
    open(FILE, $file) or die "$!";
    while (read(FILE, my $buf, 60*57)) {
      $base64filebody .= encode_base64($buf);
    }
    $smtp->datasend("--$boundary\n");
    $smtp->datasend("Content-Type: application/octet-stream; name=$filename\n");
    $smtp->datasend("Content-Transfer-Encoding: base64\n");
    $smtp->datasend("Content-Disposition: attachment; filename=$filename\n");
    $smtp->datasend("\n");
    $smtp->datasend("$base64filebody\n");
  }
  $smtp->datasend("--$boundary--\n");
  $smtp->dataend();
  $smtp->quit;
}


