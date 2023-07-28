#!/usr/bin/perl -wl -s
our $that;

if (scalar @ARGV < 2) {
  print "Usage: $0 [-that=FILE] FILE1 FILE2 [..FILE]";
  exit 1;
}

my %table;
my %files;
my $file_number = 1;
my $that_file_number;

for my $file ( @ARGV ) {

  unless ( -e $file ) {
    print "file is not exist: $file";
    exit 1;
  }

  $files{$file_number} = $file;

  if (defined $that and $that eq $file) {
    $that_file_number = $file_number;
  }

  open my $handle, "<", $file or die "$!";

  while ( <$handle> ) {
    chomp;
    my $line = $_;
    unless ( $line =~ /^\s*$/ ) {
      $table{$line} |= $file_number
    }
  }

  close $handle;
  $file_number = $file_number << 1;
}

if (defined $that and $that_file_number == 0) {
  print "there is no file: ${that}";
}

## print result
for my $line (keys %table) {

  ## for Debug
  ## printf("%08b:%s\n", $table{$line}, $line);

  # print line only in file specified
  if ($that_file_number) {
    if ($table{$line} == $that_file_number) {
      print "only in file '${that}':\t$line";
    }

  # print line only in ALL files
  } else {
    unless (is_not_single_bit($table{$line})) {
      my $file = $files{$table{$line}};
      print "only in file '${file}':\t$line";
    }
  }
}

exit 0;


sub is_not_single_bit {
  my $n = shift;
  if ($n & 0x1) {
    return $n >>1;
  }
  return is_not_single_bit($n >>1);
}

__END__

=head1 NAME

  only_in_that_file

=head1 OVERVIEW

  extract lines only in one file

=head1 SYNOPSIS

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

=cut

