#!/usr/bin/perl
use strict;
use warnings;


#default parameter
my %param = (
  strings => 6,
);

my $RE_BLANK   = qr{ \A \s*         \z }xms;
my $RE_COMMENT = qr{ \A [#]  .*     \z }xms;
my $RE_NEWLINE = qr{ \A [%] (.*)    \z }xms;
my $RE_BAR     = qr{ \A \s* [/] \s* \z }xms;
my $RE_POINT   = qr{
                   ([1-9])           #string
                   ([12][0-9]|[0-9]) #fret
                   ([hp]?)           #tech
                 }xms;
my $RE_POINTS  = qr{
                   \A \s*             #line head
                   ($RE_POINT         #one or
                     (\s+ $RE_POINT)* #more POINT
                   )                  #captchered
                   \s* \z             #line tail
                 }xms;

my @points_list = ();
my @output_text_list = ();

while (<>) {
  my $line = $_;
  my $lineno = $.;
  chomp $line;

  if ($line =~ m{ $RE_BLANK }xms) {
    #blank line
  }
  elsif ($line =~ m{ $RE_COMMENT }xms) {
    #comment line
  }
  elsif ($line =~ m{ $RE_BAR }xms) {
    push @points_list, [];
  }
  elsif ($line =~ m{ $RE_NEWLINE }xms) {
    my $text = $1;
    if (@points_list > 0) {
      push @output_text_list,
           points_list_to_string_list(\@points_list, $param{strings});
      @points_list = ();
    }
    push @output_text_list, $text;
  }
  elsif ($line =~ m{ $RE_POINTS }xms) {
    my $text = $1;
    my @points = map { string_to_point($_) } (split /\s+/, $text);
    push @points_list, \@points;
  }
  else {
    print "parse error [line $lineno]\n";
    exit 1;
  }
}

if (@points_list > 0) {
  push @output_text_list,
       points_list_to_string_list(\@points_list, $param{strings});
}

print join("\n", @output_text_list);


exit 0;
### script end ###



sub string_to_point {
  my $s = shift;
  if ($s =~ m{ $RE_POINT }xms) {
    return { string => $1,
             fret   => $2,
             tech   => $3 };
  }
  return;
}


sub point_to_string {
  my $point = shift;
  return sprintf("%d", $point->{fret});
}

sub max_width {
  my ($form, $strings) = @_;
  my @form_length = ();
  for my $i (1..$strings) {
    push @form_length, length($form->{$i});
  }
  return (sort { $b <=> $a } @form_length)[0];
}

sub padding {
  my ($s, $width) = @_;
  $width = $width - length($s);
  # when $width is zero, return value is "" . $s
  return ("-" x $width) . $s;
}

sub points_to_form {
  my ($points, $strings) = @_;
  my %form;
  if (@$points) {
    for my $i (1..$strings) {
      my @greped = grep { $_->{string} == $i } @$points;
      if (@greped) {
        $form{$i} = point_to_string($greped[0]);
      } else {
        $form{$i} = "";
      }
    }
  } else { 
    @form{(1..$strings)} = map { "|" } (1..$strings);
  }
  return \%form;
}

sub fill_form {
  my ($form, $strings) = @_;
  my $width = max_width($form, $strings);
  for my $i (1..$strings) {
    $form->{$i} = padding($form->{$i}, $width);
  }
  return $form;
}

sub points_list_to_forms {
  my ($points_list, $strings) = @_;
  my @forms = map { fill_form(points_to_form($_, $strings), $strings) }
                  @$points_list;
  return \@forms;
}

sub get_line {
  my ($forms, $string_number) = @_;
  my @frets = map { $_->{$string_number} } @$forms;
  return join('-', @frets);
}

sub points_list_to_string_list {
  my ($points_list, $strings) = @_;
  my $forms = points_list_to_forms($points_list, $strings);
  return map { get_line($forms, $_) } (1..$strings);
}

__END__

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

