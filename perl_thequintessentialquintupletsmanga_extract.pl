#!/usr/bin/perl -w -s

# thequintessentialquintupletsmanga
# -- use chrome console for download html
# javascript:(function(b,c,d,e,f,g,h,a){g=c.createElement('div').appendChild(c.getElementsByTagName('html')[0].cloneNode(true));f=g.querySelectorAll('[href],[src]');for(var i=0,n=f.length;i<n;i++){if(f[i].href){f[i].href=f[i].href}if(f[i].src){f[i].src=f[i].src}}h=g.innerHTML;e=c.doctype;e='<!DOCTYPE '+e.name+(e.publicId?' PUBLIC "'+e.publicId+'"':'')+(e.systemID?' "'+e.systemID+'"':'')+'>';a=c.createElement('a');a.download=decodeURI(d.pathname+d.hash).replace(/\//g,'__').replace(/#/g,'--')+'.html';a.href=(b.URL||b.webkitURL).createObjectURL(new Blob([e,'\n',h]));a.click()})(window,document,location);

our $chapter;
unless(defined($chapter)){ $chapter = "-----" }

my $text = do { local $/; <> };

my $done = undef;
while ($text =~ m{ href="(https://1.bp.blo..pot.c.m/.*?/s1600/)(\d+[.](jpg|jpeg|png|webp)) }xmsig ) {
  print "curl -A \"Mozilla/5.0\" -k ${1}${2} > ./${chapter}${2}\n";
  $done = 1;
}

unless (defined $done) {
while ($text =~ m{ src="(https://1.bp.blo..pot.c.m/.*?/s1600/)(\d+[.](jpg|jpeg|png|webp)) }xmsig ) {
  print "curl -A \"Mozilla/5.0\" -k ${1}${2} > ./${chapter}${2}\n";
  $done = 1;
}}

unless (defined $done) {
my $count = 1;
while ($text =~ m{ src="?(https://i.im.ur.c.m/)(.*?[.](jpg|jpeg|png|webp)) }xmsig ) {
  my $number = sprintf("%03d", $count); $count++;
  print "curl -A \"Mozilla/5.0\" -k ${1}${2} > ./${chapter}${number}${2}\n";
  $done = 1;
}}

unless (defined $done) {
my $count = 1;
while ($text =~ m{ url="?(https://i.im.ur.c.m/)(.*?[.](jpg|jpeg|png|webp)) }xmsig ) {
  my $number = sprintf("%03d", $count); $count++;
  print "curl -A \"Mozilla/5.0\" -k ${1}${2} > ./${chapter}${number}${2}\n";
  $done = 1;
}}

unless (defined $done) {
while ($text =~ m{ src="(https://v93.man....ast.com/manga/Go-......-..-......../)(.*?[.](jpg|jpeg|png|webp)) }xmsig ) {
  print "curl -A \"Mozilla/5.0\" -k ${1}${2} > ./${chapter}${2}\n";
  $done = 1;
}}

