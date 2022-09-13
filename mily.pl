#!/usr/bin/perl
use strict;
use warnings;

use List::Util qw(max min);
use Data::Dumper;
use Getopt::Long;
use Pod::Usage;

my $debug  = undef;
my $trans  = 0;
my $guitar = undef;
my $finger = undef;
my $notab  = undef;

GetOptions(
  'd|debug'    => \$debug,
  't|trans=i'  => \$trans,
  'g|guitar=s' => \$guitar,
  'f|finger'   => \$finger,
  'n|notab'    => \$notab,
) or do{ pod2usage( -exitval => 1 ); };

if ((@ARGV < 1) or (! -e $ARGV[0])) {
  pod2usage( -exitval => 1);
}

if (defined $debug) {
  $::DEBUG_PRINT_ON = 1;
}


if (!defined $guitar) {
  $guitar = "EADGBE"; #default tuning
}

my $tune = undef;
$tune = parse_tuning_text($guitar);

if (! defined $tune) {
  die "ERROR: tuning text invalid '$guitar'";
}

my $BASE_TPQN = 96;

## subroutine prototype
sub group_by (&@);
sub ___(@);


my $sourcefile = $ARGV[0];

___ "===== SMF Load : $sourcefile";
my $smf = smf_load_from_file($sourcefile);

___ "format   : $smf->{meta}->{format}";
___ "tracks   : $smf->{meta}->{tracks}";
___ "tpqn     : $smf->{meta}->{division}";

my @events = @{ $smf->{events} };
my $tpqn   = $smf->{meta}->{division};



___ "===== Pitch Transpose";
if ($trans) {

  ___ "transpose value : $trans";

  my $old_pitch = 0;
  my $old_shift = 0;
  for my $e (@events) {

    if ($e->{type} eq 'NOTE') {
      $old_pitch   = $e->{pitch};
      $e->{pitch} += $trans;
      ___ "change note pitch : $old_pitch => $e->{pitch}";
    }

    if ($e->{type} eq 'KEY') {
      $old_shift  = $e->{shift};
      $e->{shift} = signature_key_trans($e->{shift}, $trans);
      ___ "change key shift  : $old_shift => $e->{shift}";
    }
  }
}


___ "===== Tick Normalize and Adjustment";
{
  my $old_tpqn = $tpqn;
  $tpqn        = $BASE_TPQN;
  ___ "tpqn $old_tpqn => $tpqn";

  my $old_time = 0;
  my $old_gate = 0;

  ___ "---"; #each events
  for my $e (@events) {

    ## normalize
    $old_time  = $e->{time};
    $e->{time} = tick_normalize($old_time, $old_tpqn, $tpqn);
    ___ "event time normalize  $old_time => $e->{time}";

    ## adjustment
    $old_time  = $e->{time};
    $e->{time} = time_adjustment($old_time, $tpqn);
    ___ "event time adjustment $old_time => $e->{time}";

    if (defined $e->{gate}) {

      ## normalize
      $old_gate  = $e->{gate};
      $e->{gate} = tick_normalize($old_gate, $old_tpqn, $tpqn);
      ___ "event gate normalize  $old_gate => $e->{gate}";

      ## adjustment
      $old_gate  = $e->{gate};
      $e->{gate} = gate_adjustment($old_gate, $tpqn);
      ___ "event gate adjustment $old_gate => $e->{gate}";

    }
    ___ "---";
  }
}

___ "===== Fingering";
if (defined $finger) {
  ___ "use Fingering calculator";
  ___ "tuning $guitar => @{$tune}";

  my @grouped = group_by { $_->{time } }
                    sort { $a->{time} <=> $b->{time} }
                    grep { $_->{type} eq 'NOTE' }
                    @events;

  my $fretboard       = fretboard(20, $tune);
  my $form_iteratable = make_form_iteratable($fretboard);

  for my $group (@grouped) {

    ___ "------";
  
    my $form_iterator = $form_iteratable->($group);
    my $best_form   = undef;
    my $lowest_cost = 999;
  
    while (my $form = $form_iterator->()) {
      next if ! is_pressable_form($form);
  
      my $cost = calc_cost_of_form($form);
      if ($cost < $lowest_cost) {
        $lowest_cost = $cost;
        $best_form   = $form;
      }

      ___ "-";
      ___ "Cost: $cost";
      for my $e (@$form) {
        ___ "pitch $e->{org_event}->{pitch} $e->{string}/$e->{fret}"
      }
    }

    map { commit_fingering($_) } @$best_form;

    ___ "-";
    ___ "Lowest Cost: $lowest_cost";
    for my $e (@$best_form) {
      ___ "pitch $e->{org_event}->{pitch} $e->{string}/$e->{fret}"
    }
  }

  ___ "------";
}
else {
  ___ "Fingering calculator option is not set";
}


my @measures = ();

___ "===== Dividing Measures";
{
  my $measure_gate   = $tpqn * 4; #4/4
  my $measure_time = 0;
  my %measure = (
       events => [],
       time   => $measure_time,
       gate   => $measure_gate,
     );
  ___ "--- add measure : time $measure_time gate $measure_gate";

  @events = sort { $a->{time} <=> $b->{time} } @events;

  for my $e (@events) {

    ADD_MEASURES:
    while (1) {

      last ADD_MEASURES
        if $e->{time} < $measure_time + $measure_gate;

      push @measures, { %measure };
      $measure_time += $measure_gate;
      %measure = (
        events => [],
        time   => $measure_time,
        gate   => $measure_gate,
      );
      ___ "--- add measure : time $measure_time gate $measure_gate";
    }

    if ($e->{type} eq 'TIME') {
      $measure_gate = int(($tpqn*4) / $e->{beatunit}) * $e->{beats};
      $measure{signature}->{time} = "$e->{beats}/$e->{beatunit}";
      $measure{gate}              = $measure_gate;
      ___ "set time signature $e->{beats}/$e->{beatunit}";
      ___ "set measure gate $measure_gate";
    }

    if ($e->{type} eq 'KEY') {
      $measure{signature}->{key} = $e->{shift};
      ___ "set key signature $e->{shift}";
    }

    if ($e->{type} eq 'NOTE') {
      push @{$measure{events}}, $e;
      ___ "push note into measures :", smf_note_event_dump($e);
    }
  }

  ## push rest data
  if (@{$measure{events}}) {
    push @measures, { %measure };
  }
  ___ "---";
}

## dispose
@events = undef;


___ "===== Dividing Ties";
{
  my @tied = ();
  my $measure_no = 1;

  for my $m (@measures) {

    if (@tied) {
      push @{$m->{events}}, @tied;
      @tied = ();
    }

    for my $e (@{$m->{events}}) {

      if (($e->{time} + $e->{gate}) > ($m->{time} + $m->{gate})) {
        ___ "measure $measure_no : note is need to divide and tie";
        ___ "original note :", smf_note_event_dump($e);

        my $org_event_gate = $m->{time} + $m->{gate} - $e->{time};
        my $new_event_gate = $e->{gate} - $org_event_gate;

        ## tie from
        my %new_event = %$e;
        $new_event{time} = $e->{time} + $org_event_gate;
        $new_event{gate} = $new_event_gate;
        $new_event{tiefrom} = 1;
        push @tied, { %new_event };

        ## tie to
        $e->{gate}  = $org_event_gate;
        $e->{tieto} = 1;

        ___ "  => tie to   :", smf_note_event_dump($e);
        ___ "  => tie from :", smf_note_event_dump(\%new_event);
        ___ "---";
      }
    }

    $measure_no++;
  } #measures loop
}


___ "===== Dividing Voices";
{
  for my $m (@measures) {
    my @sorted = sort { $a->{pitch} <=> $b->{pitch} }
                 sort { $a->{time} <=> $b->{time} }
                      @{$m->{events}};
    $m->{events} = \@sorted;
  }

  my $measure_no = 1;
  for my $m (@measures) {
  
    my $voice_no = 0;
    my @prevpool = ();

    $m->{voices} = [];
  
    ___ "measure $measure_no";
    ___ "baseline selection";
    
    EVENTS:
    for my $e (@{$m->{events}}) {
  
      for my $p (@prevpool) {
        unless (($e->{time} + $e->{gate} <= $p->{time}) ||
                ($p->{time} + $p->{gate} <= $e->{time})) {
          last EVENTS;
        }
      }
  
      $e->{voice_no} = $voice_no;
      push @prevpool, $e;
      ___ "voice $voice_no :", smf_note_event_dump($e);
    }
  
    push @{$m->{voices}}, [ @prevpool ];
  

    ___ "otherline selection";
  
    while (1) {

      my @rest = grep { ! defined $_->{voice_no} } @{$m->{events}};
      last if @rest == 0;
      $voice_no++;
  
      my @prevpool = ();
  
      REST_EVENTS:
      for my $e (@rest) {
        
        for my $p (@prevpool) {
          unless (($e->{time} + $e->{gate} <= $p->{time}) ||
                  ($p->{time} + $p->{gate} <= $e->{time}) ||
                  (($e->{time} == $p->{time}) &&
                   ($e->{time} + $e->{gate} == $p->{time} + $p->{gate}))) {
            last REST_EVENTS;
          }
        }
  
        $e->{voice_no} = $voice_no;
        push @prevpool, $e;
        ___ "voice $voice_no :", smf_note_event_dump($e);
      }
  
      push @{$m->{voices}}, [ @prevpool ];
    }

    ## move baseline to second voice
    if (@{$m->{voices}} > 1) {
      @{$m->{voices}}[0,1] = @{$m->{voices}}[1,0];
    }

    ## dispose
    delete $m->{events};

    ___ "---";
    $measure_no++;
  } #measures loop
}


___ "===== Chunking Chord";
{
  for my $m (@measures) {

    for my $v (@{$m->{voices}}) {

      my @new_voice = ();
      my @grouped = group_by { "$_->{time}$_->{gate}" .
                               (defined $_->{tieto}?   "tieto":   "") .
                               (defined $_->{tiefrom}? "tiefrom": "")
                             } @{$v};

      for my $g (@grouped) {

        my %new_event = %{$g->[0]};

        my %chord  = ();
        my @chords = ();
        for my $e (@$g) {
          %chord            = ( pitch => $e->{pitch} );
          $chord{fingering} = { %{$e->{fingering}} }
            if defined $e->{fingering};
          push @chords, { %chord };
        }

        delete $new_event{pitch};
        delete $new_event{voice_no};
        delete $new_event{fingering};

        $new_event{chord} = [ @chords ];

        push @new_voice, { %new_event };
      }

      $v = [ @new_voice ];
    }

  } #measures loop
}


___ "===== Insert Rest";
{
  my $measure_no = 1;
  for my $m (@measures) {
  
    for my $v (@{$m->{voices}}) {

      $v = [ sort { $a->{time} <=> $b->{time} } @{$v} ];

      my $curr_time = $m->{time};
      my @rests = ();

      for my $e (@{$v}) {

        while ($curr_time < $e->{time}) {

          my $gate = $e->{time} - $curr_time > $tpqn?
                     $tpqn: $e->{time} - $curr_time;

          push @rests, {
            type => 'REST',
            time => $curr_time,
            gate => $gate,
          };
          ___ "measure $measure_no : rest time $curr_time gate $gate";

          $curr_time += $gate;
        }

        $curr_time += $e->{gate};
      } #events in voice

      #rest in voice tail
      while ($curr_time < $m->{time} + $m->{gate}) {

        my $gate = $m->{time} + $m->{gate} - $curr_time > $tpqn?
                   $tpqn: $m->{time} + $m->{gate} - $curr_time;

        push @rests, {
          type => 'REST',
          time => $curr_time,
          gate => $gate,
        };
        ___ "measure $measure_no : rest time $curr_time gate $gate";

        $curr_time += $gate;
      }

      push @{$v}, @rests;
    }

    $measure_no++;
  } #measures loop
}


___ "===== Cleanup Measures";
{
  for my $m (@measures) {

    for my $v (@{$m->{voices}}) {
      my @sorted = sort { $a->{time} <=> $b->{time} } @{$v};
      $v = { events => [ @sorted ] };
    }

    delete $m->{gate};
    delete $m->{time};
  }
}


___ "===== Dump Measures";
{
  $Data::Dumper::Indent = 1;
  ___ Dumper(\@measures);
}



___ "===== Create Lilypond Text";

my $LY_TEXT =<<"__LY_TEXT__";
\\version "2.16.0"
\\pointAndClickOff

\\header {
title       = \\markup { \\fontsize #3 "NoTitle" }
composer    = "NoOne"
tagline     = ##f
breakbefore = ##t
%%TUNING_TEXT%%
}

measures = {
##LY_MEASURES##
}

\\new StaffGroup <<

\\new Staff {
\\clef "treble_8"
\\override Staff.StringNumber #'stencil = ##f
\\measures
}

%%TAB_STAFF%%

>>
__LY_TEXT__


if (!defined $notab) {
  my $lytune = join(" ", map { pitch_to_ly($_+12) } reverse @$tune);
  my $TAB_STAFF =<<"__TAB_STAFF__";
\\new TabStaff {
\\set TabStaff.stringTunings = \\stringTuning <$lytune>
\\measures
}
__TAB_STAFF__
  $LY_TEXT =~ s{%%TAB_STAFF%%}{$TAB_STAFF};

  my $lyheadertune = 'piece = "Tuning: ' .
                     tune_to_header_text($tune) . qq("\n);
  $LY_TEXT =~ s{%%TUNING_TEXT%%}{$lyheadertune};
}

{
  my $ly = '';

  ## each measures
  my $flatmode   = 0;
  my $measure_no = 1;
  for my $m (@measures) {

    $ly .= "%%% Measure $measure_no\n";
    $ly .= "<<\n";

    ## signature
    if (defined $m->{signature}->{time}) {
      $ly .= "\\numericTimeSignature \\time $m->{signature}->{time}\n";
    }
    if (defined $m->{signature}->{key}) {
      $ly .= "\\key " . signature_key_to_ly($m->{signature}->{key}) . "\n";
      $flatmode = $m->{signature}->{key} < 0 ? 1 : 0;
    }


    my $voice_no = 1;
    for my $v (@{$m->{voices}}) {

      $ly .=   "   { " if $voice_no == 1;
      $ly .= "\\\\ { " if $voice_no != 1;

      my @voice = ();

      for my $e (@{$v->{events}}) {

        my $gate_ly = gate_to_ly($e->{gate}, $tpqn);
      
        if ($e->{type} eq 'REST') {
          push @voice, "r$gate_ly";
          next;
        }

        my @note_ly = map { 
          pitch_to_ly($_->{pitch}, $flatmode) .
          (defined $_->{fingering}? "\\$_->{fingering}->{string}": "")
        } @{$e->{chord}};

        # String numbers must be defined inside a chord construct
        # even if there is only a single note.
        push @voice, '<' . join(' ', @note_ly) . '>' . $gate_ly;
  
        if (defined $e->{tieto}) {
          push @voice, '~ \tieNeutral';
        }
      }

      $ly .= join(' ', @voice);
      $ly .= "} \n";

      $voice_no++;
    } #voices loop

    $ly .= ">> | \n";

    $measure_no++;
  } #measures loop

  $LY_TEXT =~ s{##LY_MEASURES##}{$ly};
}


___ "===== Print Lilypond Text";
print $LY_TEXT;


exit 0;
#######################################

sub smf_load_from_file {
  my ($filename) = @_;

  open my $FH, '<', $filename or die "$!";
  binmode $FH;

  my $hdsg = interpret($FH, 4, "A4", "Header Signature");
  $hdsg eq "MThd" or
    die "ERROR: unknown header signature '$hdsg'";
  
  my $hdsz = interpret($FH, 4, "N", "Header Size");
  $hdsz == 6 or
    die "ERROR: unmatch header size '$hdsz'";
  
  my $format   = interpret($FH, 2, "n", "Header Format");
  my $tracks   = interpret($FH, 2, "n", "Header Tracks");
  my $division = interpret($FH, 2, "n", "Header Division");

  my @events = ();
  
  ## for each tracks
  for my $track (0..$tracks-1) {
  
    my $trsg = interpret($FH, 4, "A4", "Track Signature");
    $trsg eq "MTrk" or
      die "ERROR: unknown track signature '$trsg'";
  
    my $size = interpret($FH, 4, "N", "Track Size");
    my $offset = tell($FH);
  
    my $prev_status = 0;
    my $abstime = 0;
  
    my $noteon = [];
    for my $c (0..15) {
      for my $p (0..127) {
        $noteon->[$c]->[$p]->{ontime}   = -1;
        $noteon->[$c]->[$p]->{velocity} = -1;
      }
    }
  
    ## for each events
    while (1) {
  
      tell($FH) - $offset <= $size or
        die "ERROR: unmatch track size";
  
      last if tell($FH) - $offset == $size;
  
      ## read deltatime
      my $deltatime = 0;
      while (1) {
        my $b = interpret($FH, 1, "C", "Delta Time");
        $deltatime = ($deltatime << 7) + ($b & 0x7F);
        last unless $b & 0x80;
      }
      $abstime += $deltatime;
  
      my $status = interpret($FH, 1, "C", "Event Type");
  
      ## running status
      unless ($status & 0x80) {
        seek($FH, -1, 1);
        $status = $prev_status;
      }
      $prev_status = $status;
  
      ## note off
      if (($status >= 0x80) && ($status <= 0x8F)) {
        my $pitch    = interpret($FH, 1, "C", "NoteOff Pitch");
        my $velocity = interpret($FH, 1, "C", "NoteOff Velocity");
        my $channel  = $status & 0x0F;

        if ($noteon->[$channel]->[$pitch]->{ontime} == -1) {
          # This NoteOff has no preceded NoteOn
        }
        elsif (($pitch < 0) || ($pitch > 127)) {
          die "ERROR: NoteOff pitch is over range";
        }
        else {
          my $gate = $abstime - $noteon->[$channel]->[$pitch]->{ontime};
          push @events, {
            time => $noteon->[$channel]->[$pitch]->{ontime},
            type => 'NOTE',
            pitch => $pitch,
            gate => $gate,
          };
          $noteon->[$channel]->[$pitch]->{ontime}   = -1;
          $noteon->[$channel]->[$pitch]->{velocity} = -1;
        }
      }
      ## note on
      if (($status >= 0x90) && ($status <= 0x9F)) {
        my $pitch    = interpret($FH, 1, "C", "NoteOn Pitch");
        my $velocity = interpret($FH, 1, "C", "NoteOn Velocity");
        my $channel  = $status & 0x0F;

        if ($noteon->[$channel]->[$pitch]->{ontime} != -1) {
          if ($velocity == 0) {
            my $gate = $abstime - $noteon->[$channel]->[$pitch]->{ontime};
            push @events, {
              time => $noteon->[$channel]->[$pitch]->{ontime},
              type => 'NOTE',
              pitch => $pitch,
              gate => $gate,
            };
            $noteon->[$channel]->[$pitch]->{ontime} = -1;
            $noteon->[$channel]->[$pitch]->{velocity} = -1;
          }
          else {
            # NoteOn pitch is overlaped
          }
        }
        elsif (($pitch < 0) || ($pitch > 127)) {
          die "ERROR: NoteOn pitch is over range";
        }
        else {
          $noteon->[$channel]->[$pitch]->{ontime}   = $abstime;
          $noteon->[$channel]->[$pitch]->{velocity} = $velocity;
        }
      }
      ## aftertouch
      if (($status >= 0xA0) && ($status <= 0xAF)) {
        my $pitch = interpret($FH, 1, "C", "NoteOff Pitch");
        my $touch = interpret($FH, 1, "C", "After Touch");
      }
      ## parameter
      if (($status >= 0xB0) && ($status <= 0xBF)) {
        my $number  = interpret($FH, 1, "C", "Parameter Number");
        my $setting = interpret($FH, 1, "C", "Parameter Setting");
      }
      ## program
      if (($status >= 0xC0) && ($status <= 0xCF)) {
        my $program = interpret($FH, 1, "C", "Program Number");
      }
      ## key pressure
      if (($status >= 0xD0) && ($status <= 0xDF)) {
        my $pressure = interpret($FH, 1, "C", "Pressure");
      }
      ## pitch wheel
      if (($status >= 0xE0) && ($status <= 0xEF)) {
        my $value = interpret($FH, 2, "n", "PitchWheel Value");
      }
      ## system exclusive
      if (($status == 0xF0) || ($status == 0xF7)) {
        while (1) {
          my $eventdata = interpret($FH, 1, "C", "SysEx Data");
          last if $eventdata == 0xF7;
        }
      }
      ## meta event
      if ($status == 0xFF) {
        my $eventtype = interpret($FH, 1, "C", "MetaEvent Type");
        my $eventsize = interpret($FH, 1, "C", "MetaEvent Size");
        ## time signature
        ## FF 58 04 nn dd cc bb
        ## nn/2^dd   eg: 6/8 would be specified using nn=6, dd=3
        ## nn Time signature, numerator
        ## dd Time signature, denominator expressed as a power of 2
        ## cc MIDI Clocks per metronome tick
        ## bb Number of 1/32 notes per 24 MIDI clocks (8 is standard)
        if (($eventtype == 0x58) && ($eventsize == 4)) {
          my $numerator   = interpret($FH, 1, "C", "TimeSignature");
          my $denominator = interpret($FH, 1, "C", "TimeSignature");
          seek($FH, 2, 1);
          push @events, {
            time => $abstime,
            type => 'TIME',
            beats => $numerator,
            beatunit => 2**$denominator,
          };
        }
        ## key signature
        ## FF 59 02 sf mi
        ## sf Number of sharps or flats 
        ## 0 represents a key of C, negative numbers represent 'flats'
        ## while positive numbers represent 'sharps'.
        ## mi Flag of major or minor
        ## 0 = major key, 1 = minor key
        elsif (($eventtype == 0x59) && ($eventsize == 2)) {
          my $shift = interpret($FH, 1, "c", "KeySignature");
          my $flag  = interpret($FH, 1, "C", "KeySignature");
          push @events, {
            time => $abstime,
            type => 'KEY',
            shift => $shift,
            minor => $flag,
          };
        }
        else {
          seek($FH, $eventsize, 1);
        }
      }
      ## unknown
      if (($status < 0x80) || (($status > 0xF0) && ($status < 0xFF))) {
        die "ERROR: unknown eventtype '$status'";
      }
    }
  }
  
  unless(eof($FH)) {
    die "ERROR: expect file end, but has rest data";
  }
  
  close $FH;

  ## Return value is hashref
  ## ---
  ## meta:
  ##   format:   0 | 1
  ##   tracks:   0 ..N
  ##   division: N
  ## events:
  ##   - type:  'NOTE'
  ##     time:  N
  ##     gate:  N
  ##     pitch: N
  ##   - type:  'TIME'
  ##     time:  N
  ##     beats:    N  eg) 3 of 3/4
  ##     beatunit: N  eg) 4 of 3/4
  ##   - type:  'KEY'
  ##     time:  N
  ##     shift: N   # 0=C  1,2..=sharps  -1,-2..=flats..
  ##     minor: 0 | 1   # 0=major,1=minor
  ##   ...
  return {
    meta => {
      format   => $format,
      tracks   => $tracks,
      division => $division,
    },
    events => [ @events ],
  };
}

sub smf_note_event_dump {
  my ($note_event) = @_;

  my $hex  = sprintf("0x%02x", $note_event->{pitch});
  my $text = pitch_to_text($note_event->{pitch});
  my $time = $note_event->{time};
  my $gate = $note_event->{gate};

  return "pitch $hex ($text) time $time gate $gate";
}

sub pitch_to_text {
  my ($pitch, $flatmode) = @_;
  
  my @pitchname = defined $flatmode?
    ("C","Db","D","Eb","E","F","Gb","G","Ab","A","Bb","B"):
    ("C","C#","D","D#","E","F","F#","G","G#","A","A#","B");

  return int($pitch / 12) . $pitchname[ $pitch % 12 ];
}

sub interpret {
  my ($FH, $size, $template, $message) = @_;
  my $data;
  my $bytes = read($FH, $data, $size);
  if ($bytes != $size) {
    die "ERROR: unexpected file end when reading '$message'";
  }
  return unpack($template, $data);
}

sub tick_normalize {
  my ($tick, $old_tpqn, $new_tpqn) = @_;
  return int( $tick / $old_tpqn * $new_tpqn);
}

sub time_adjustment {
  my ($time, $tpqn) = @_;
  my $basetime = $tpqn / 8;

  return $time % $basetime > $basetime / 2 ?
         $time + $basetime - ($time % $basetime):
         $time -           + ($time % $basetime);
}

sub gate_adjustment {
  my ($gate, $division) = @_;

#  return $division / 8      if $gate < int(($division / 8) * 1.2); #32
#  return $division / 16 * 3 if $gate < int(($division / 8) * 1.3); #32.
#  return $division / 4      if $gate < int(($division / 4) * 1.2); #16
#  return $division / 8  * 3 if $gate < int(($division / 4) * 1.3); #16.
#  return $division / 2      if $gate < int(($division / 2) * 1.2); #8
#  return $division / 4  * 3 if $gate < int(($division / 2) * 1.3); #8.
#  return $division          if $gate < int( $division      * 1.2); #4
#  return $division / 2  * 3 if $gate < int( $division      * 1.3); #4.
#  return $division * 2      if $gate < int(($division * 2) * 1.2); #2
#  return $division      * 3 if $gate < int(($division * 2) * 1.3); #2.
#  return $division * 4      if $gate < int(($division * 4) * 1.2); #1

  #if $gate is longer than full-note
  return $gate;
}

sub signature_key_to_ly {
  my ($key_shift) = @_;

  my %pattern = (
     0=>'c',
     1=>'g',  2=>'d',    3=>'a',    4=>'e',    5=>'b'   , 6=>'fis',
    -1=>'f', -2=>'bes', -3=>'ees', -4=>'aes', -5=>'des', -6=>'ges',
  );

  return $pattern{$key_shift} . " \\major";
}

sub gate_to_ly {
  my ($gate, $tpqn) = @_;

  return "32"  if $gate <= $tpqn / 8;
  return "32." if $gate <= $tpqn / 16 * 3;
  return "16"  if $gate <= $tpqn / 4;
  return "16." if $gate <= $tpqn / 8  * 3;
  return "8"   if $gate <= $tpqn / 2;
  return "8."  if $gate <= $tpqn / 4  * 3;
  return "4"   if $gate <= $tpqn;
  return "4."  if $gate <= $tpqn / 2  * 3;
  return "2"   if $gate <= $tpqn * 2;
  return "2."  if $gate <= $tpqn      * 3;
  return "1";
}

sub pitch_to_ly {
  my ($pitch, $flatmode) = @_;

  my $name = "";
  my @pitchname = $flatmode?
    ("c","des","d","ees","e","f","ges","g","aes","a","bes","b"):
    ("c","cis","d","dis","e","f","fis","g","gis","a","ais","b");
  my %octave_mark = (
    0 => ",,,,", 1 => ",,,",  2 => ",,",  3 => ",", 4 => "",
    5 => "'",    6 => "''",   7 => "'''", 8 => "''''",
  );

  $name .= $pitchname[ $pitch % 12 ];
  $name .= $octave_mark{ int($pitch / 12) -1 };

  return $name;
}

sub signature_key_trans {
  my ($key_shift, $trans) = @_;

  my $index = $key_shift < 0 ? 12 - abs($key_shift) : $key_shift;
  my @cycle = ( 0,1,2,3,4,5,6,-5,-4,-3,-2,-1);

  return $cycle[ ($index + $trans * 7) % 12 ];
}

sub parse_tuning_text {
  my ($tuning_text) = @_;

  $tuning_text =~ m{ \A ([A-G][#b]?) ([A-G][#b]?) ([A-G][#b]?)
                        ([A-G][#b]?) ([A-G][#b]?) ([A-G][#b]?) \z }xms;
  return if ! defined $1;

             #6th,5th, ...        1st
  my @text = ($1, $2, $3, $4, $5, $6);
  my @base = (40, 45, 50, 55, 59, 64);
  my @tune = ();

  for my $i (0..$#base) {
    my $r = "$text[$i]\$";
    for my $d (0..4) {
      $tune[$i] = $base[$i]+$d if pitch_to_text($base[$i]+$d)   =~ /${r}$/;
      $tune[$i] = $base[$i]+$d if pitch_to_text($base[$i]+$d,1) =~ /${r}$/;
      $tune[$i] = $base[$i]-$d if pitch_to_text($base[$i]-$d)   =~ /${r}$/;
      $tune[$i] = $base[$i]-$d if pitch_to_text($base[$i]-$d,1) =~ /${r}$/;
    }
    ## nomatch
    $tune[$i] = $base[$i] if ! defined $tune[$i];
  }

  return [ reverse @tune ];
}

sub tune_to_header_text {
  my ($tune) = @_;

  my $base = [ 64, 59, 55, 50, 45, 40 ];
  my @name = ("C","C#","D","D#","E","F","F#","G","G#","A","A#","B");
  
  my @result = ();
  
  for my $s (1..6) {
    my $text = $name[ $tune->[ $s-1 ] % 12 ];
    $text .= "(-)" if $tune->[$s-1] < $base->[$s-1];
    $text .= "(+)" if $tune->[$s-1] > $base->[$s-1];
    push @result, $text;
  }
  @result = reverse @result;

  return "@result";
}

sub fretboard {
  my ($depth, $tune) = @_; # $tune is arrayref [1st,2nd,...,6th]

  return sub {
    my ($note_event) = @_;

    my @fingering_events = ();

    for my $s (0..$#$tune) {
      for my $f (0..$depth) {
        if ($note_event->{pitch} == ($tune->[$s] + $f)) {
          push @fingering_events, {
            org_event => $note_event,
            fret      => $f,
            string    => $s + 1,
          };
        }
      }
    }
   
    # no fret/string mapping
    if (scalar @fingering_events == 0) {
      warn "!! no fret/string mapping";
    }
    return [ @fingering_events ];
  }
}

sub make_form_iteratable {
  my ($fretboard) = @_;

  return sub {
    my ($note_events) = @_;

    my @pattern = grep { scalar @{$_} > 0 }
                  map  { &$fretboard($_)  } @$note_events;

    return sub { return; } if @pattern == 0;
    return cartesian_product(@pattern);
  }
}

sub commit_fingering {
  my ($e) = @_;
  if ((defined $e->{fret}) && (defined $e->{string})) {
    $e->{org_event}->{fingering}->{fret}   = $e->{fret};
    $e->{org_event}->{fingering}->{string} = $e->{string};
  }
}

sub is_pressable_form {
  my ($form) = @_;

  return 1 if @$form < 2;

  my @strings = map  { $_->{string} } @$form;
  return ! has_duplicate(@strings);
}


sub calc_cost_of_form {
  my ($form) = @_;

  my $width    = 0;
  my $maximum  = 0;
  my $adjoined = 1;
  my $cost     = 0;

  my @frets   = grep { $_ != 0 }   map { $_->{fret}   } @$form;
  my @strings = sort { $b <=> $a } map { $_->{string} } @$form;

  if (@frets != 0) {
    $width   = max(@frets) - min(@frets);
    $maximum = max(@frets);
  }

  if (@strings > 1) {
    for my $i (0..$#strings-1) {
      $adjoined = 0 if ($strings[$i] - $strings[$i+1]) > 1;
    }
  }

  $cost  = $width * 2 + $maximum;
  $cost += $adjoined? 0: $width;

  return $cost;
}
sub cartesian_product {
  my @list = @_;
  my @index = map {    0 } @list;
  my @limit = map { $#$_ } @list;

  return sub {
    
    return if ! @list;

    my @result = map { $list[$_]->[$index[$_]] } (0..$#list);

    # generate next pattern
    for my $i (0..$#index) {
      if ($index[$i]  < $limit[$i]) { $index[$i] += 1; last; }
      if ($index[$i] == $limit[$i]) { $index[$i]  = 0; next; }
    }

    # when iterator exhausted
    unless (grep { $_ != 0 } @index) {
      @list = @index = @limit = ();
    }

    # return scalar value
    return \@result;
  }
}


sub has_duplicate {
  my @copy = @_;
  my %exists = ();

  for my $item (@copy) {
    return !0 if defined $exists{$item};
    $exists{$item} = 1;
  }
  return !1;
}


sub group_by (&@) {
  my ($create_key, @copy) = @_;
  my @key_queue = ();
  my %key_index = ();
  my $index = 0;

  local $_;
  foreach (@copy) {
    my $val = $_;
    my $key = &$create_key();
    if (!defined $key_index{$key}) {
      $key_queue[$index] = [$val];
      $key_index{$key} = $index++;
    }
    else {
      push @{$key_queue[$key_index{$key}]}, $val;
    }
  }
  return @key_queue;
}

sub ___(@) {
  print STDERR "@_\n" if defined $::DEBUG_PRINT_ON;
}

__END__

=head1 NAME

mily -- A command-line tool convert SMF(midifile) into lilypond text

=head1 SYNOPSIS

mily.pl [options] file

Options:

    -d,   --debug     Export debugging information.
    -t=i, --trans=i   Transpose pitch
    -g=s, --guitar=s  Guitar tuning  eg) -g=EADGBE
    -f,   --finger    use Fingering calculator
    -n,   --notab     no Tablature

Single-character options may be stacked.

=head1 OVERVIEW

mily is a command-line tool convert SMF(midifile) into lilypond text

=head1 AUTHORS

Keisuke Inazaki

=head1 COPYRIGHT

Copyright 2014 by Keisuke Inazaki

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>.

=cut

