#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;

## Reading:
my $in = "Delorme_english.txt";
open(IN, $in) or die "Could not open file: '$in'\n\"$!\"";
my @lines = <IN>;

## Writing:
system('rm ~/test/maps/output.kml');
system('touch ~/test/maps/output.kml');
my $out = "output.kml";
open(OUT, ">$out") or die "Could not open file: $out\n\"$!\"";

## Open the kml file
print OUT <<"EOT";
<?xml version='1.0' encoding='UTF-8'?><kml xmlns='http://www.opengis.net/kml/2.2'><Document><name>A map program by any other name would be just as sweet.</name><description><![CDATA[Areas in the New Jersey Morristown Mission]]></description><Folder><name>Auto Generated Layer From Delorme</name>
EOT

my $inside_begin_block = 0;
my $number_of_lines = scalar(@lines);
my $polygon_count = 0;
my $coords_count = 0;


my %dispatch = ( ## Each of these functions returns the line it is on when it is finished.
    "BEGIN POLY" => \&poly,
    "BEGIN SYMBOL" => \&sym,
    "BEGIN NOTE" => \&note,
    "BEGIN LINE" => \&line,
    );

for (my $current_line = 0; $current_line < $number_of_lines; $current_line++) {
    my $line = $lines[$current_line];
    chop $line;
    chop $line; ## I don't know why this makes it work, but it does and I don't have time to figure it out.  Sorry.
    if (exists $dispatch{$line}) {
	$current_line = $dispatch{$line}->($current_line);
    }
    else {
	close(OUT);
	die "Input file has a syntax error line $current_line:  '$line'\n Expecting a BEGIN block or an END.\n";
    }
} 


sub poly() {
    print "BEGIN POLY...\n";
    $polygon_count++;
    my $current_line = shift; ## I.e. the line number of 'BEGIN POLY'
    $current_line++; ## next line
    
    ## Define a Polygon
    print OUT <<"EOT";
<Placemark><Polygon><outerBoundaryIs><LinearRing><tessellate>1</tessellate>
EOT

   print OUT "<coordinates>";

    my $first_coord = $lines[$current_line];
    my $polygon_closed = 0;
    
    my $line = $lines[$current_line];
    chop $line;
    chop $line;
    
    until ($line eq 'END') {
	$polygon_closed = 1 if $line eq $first_coord;  #The Polygon's first point should be the last point as well.
	$coords_count++;
	$line = kml_coord($line);
	print OUT $line;
	print OUT ",0\n";
	$current_line++;
	$line = $lines[$current_line];
	chop $line;
	chop $line;
    }
    unless ($polygon_closed) {
	print OUT kml_coord($first_coord);
    }
    print OUT "</coordinates>";
    print OUT <<"EOT";
</LinearRing>
</outerBoundaryIs>
</Polygon>
</Placemark>
EOT
    print "END\n";
    return $current_line;
}

sub sym() {
    print "BEGIN SYM...\n";
    my $current_line = shift;
    $current_line++;

    my $line = $lines[$current_line];
    chop $line;
    chop $line;
        
    until ($line eq 'END') {
	#	print OUT $line;
	$current_line++;
	$line = $lines[$current_line];
	chop $line;
	chop $line;
    }
    print "END\n";
    return $current_line;
}

sub note() {
    print "BEGIN NOTE..\n";
    my $current_line = shift;
    $current_line++;

    
    my $line = $lines[$current_line];
    chop $line;
    chop $line;
    
    until ($line eq 'END') {
#	print OUT $line;
	$current_line++;
	$line = $lines[$current_line];
	chop $line;
	chop $line;
    }

    print "END\n";
    return $current_line;
}

sub line() {
    print "BEGIN LINE...\n";
    my $current_line = shift;
    $current_line++;
        
    my $line = $lines[$current_line];
    chop $line;
    chop $line;
    
    until ($line eq 'END') {
	# print OUT $line;
	$current_line++;
	$line = $lines[$current_line];
	chop $line;
	chop $line;
    }

    print "END\n";
    return $current_line;
}

sub kml_coord {
    my $line = shift;
    $line = join(',', reverse(split(',', $line))); # Because KML expects long/lat instead of lat/long
    return $line;
}


END {
    print OUT "</Folder></Document></kml>";
    close(OUT);
    print "POLYGONS WRITTEN: $polygon_count\n";
    print "TOTAL POINTS WRITTEN: $coords_count\n";
    print "SELECTED OUTPUT FILE: $out\n";
    print "END OF LINE.\n";
}
