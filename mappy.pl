#!/usr/bin/perl
use strict;
use warnings;

if (not defined $ARGV[0]) {  ## This program requires an input file.
    die "Needs an input file\n";
}

## Reading:
my $in = $ARGV[0];
open(IN, $in) or die "Could not open file: '$in'\n\"$!\"";
my @lines = <IN>;

## Writing:
my $out = $ARGV[1];
if (not defined $ARGV[1]) {
    $out = 'output.kml';
}
system("rm $out");
system("touch $out");
open(OUT, ">$out") or die "Could not open file: $out\n\"$!\"";

## Options:
my $only_polygons = 0;
if (defined $ARGV[2] && ($ARGV[2] eq '-p' || $ARGV[2] eq '--poly')) {
    $only_polygons = 1;
}

## Fill in some document information
print "Document Name (optional): ";
chomp(my $name = <STDIN>);
print "Document Description (optional): ";
chomp(my $description = <STDIN>);
print "Folder Name: ";
chomp(my $folder_name = <STDIN>);

## Open the kml file
print OUT <<"EOT";
<?xml version='1.0' encoding='UTF-8'?>
<kml xmlns='http://www.opengis.net/kml/2.2'>
<Document>
<name>$name</name>
<description><![CDATA[$description]]></description>
<Folder>
<name>$folder_name</name>
EOT

my $inside_begin_block = 0;
my $number_of_lines = scalar(@lines);
my $polygon_count = 0;
my $symbol_count = 0;
my $line_count = 0;
my $note_count = 0;
my $coords_count = 0;
my %icons = (
    'HOUSE' => 'http://maps.google.com/mapfiles/kml/pal3/icon56.png',
    'CHURCH' => 'http://maps.google.com/mapfiles/kml/pal2/icon11.png',
    'DEFAULT' => 'http://maps.google.com/mapfiles/ms/micons/red-dot.png',
);

my %dispatch = ( ## Each of these functions returns the current line number.
    "BEGIN POLY" => \&poly,
    "BEGIN SYMBOL" => \&sym,
    "BEGIN NOTE" => \&note,
    "BEGIN LINE" => \&line,
    );

for (my $current_line = 0; $current_line < $number_of_lines; $current_line++) {
    my $line = $lines[$current_line];
    chop $line;
    chop $line; ## I don't know why this makes it work, but it does and I don't have time to figure it out.  Something to do with tab/space settings coming from the delorme file I think.
    if (exists $dispatch{$line}) {
	$current_line = $dispatch{$line}->($current_line);
    }
    elsif ($line eq ' ') {
	next;
    }
    else {
	close(OUT);
	die "Input file has a syntax error on line $current_line:  '$line'\n Expecting a BEGIN block or an END.\n";
    }
} 

print OUT "</Folder>\n</Document>\n</kml>";
close(OUT);
print "SYMBOLS WRITTEN (AS PLACEMARKS): $symbol_count\n";
print "LINES WRITTEN: $line_count\n";
print "NOTES WRITTEN: $note_count\n";
print "POLYGONS WRITTEN: $polygon_count\n";
print "TOTAL POINTS WRITTEN: $coords_count\n";
print "SELECTED OUTPUT FILE: $out\n";

## Dispatch Table Functions:
sub poly {
    $polygon_count++;
    my $current_line = shift; ## I.e. the line number of 'BEGIN POLY'
    $current_line++; ## next line
    
    ## Define a Polygon
    print OUT <<"EOT";
<Placemark>\n<Polygon>\n<outerBoundaryIs>\n<LinearRing>\n<tessellate>1</tessellate>\n
EOT

   print OUT "<coordinates>";

    my $first_coord = $lines[$current_line];
    my $polygon_closed = 0;
    
    my $line = $lines[$current_line];
    chop $line;
    chop $line;
    
    until ($line eq 'END') {
	$polygon_closed = 1 if $line eq $first_coord;  # The Polygon's first point should be the last point as well.
	$coords_count++;
	$line = kml_coord($line);
	print OUT $line;
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
    return $current_line;
}

sub sym {
    my $current_line = shift;
    $current_line++;

    my $line = $lines[$current_line];
    chop $line;
    chop $line;
        
    until ($line eq 'END') {  # A symbol looks like '40.776647,-74.160386,FOO,HOUSE'
	my @symbol_csv = split(',', $line);
	my $coords = kml_coord("$symbol_csv[0],$symbol_csv[1]");
	my $note = $symbol_csv[2];
	my $description = $symbol_csv[3];

	if (not defined $icons{$symbol_csv[3]}) {
	    warn "Symbol $symbol_csv[3] not defined at $in line $current_line.\nIt's possible that there is a syntax error in the input file.  But it may also be that you have attempted to use an undefined symbol. (Since symbol support is sparse, feel free to contribute to this project on github: https://github.com/alex0112/mappy)\nUsing Default Symbol...\n";
	    $symbol_csv[3] = 'DEFAULT';
	}

	print OUT <<"EOT";
	<Placemark>
	<name>$name</name>
        <description>$description</description>
        <Point>
          <coordinates>$coords</coordinates>
        </Point>
<description>$symbol_csv[2]</description>
<styleUrl>$icons{$symbol_csv[3]}</styleUrl>

 </Placemark>
EOT
#<IconStyle> <Icon> <href>$icons{$symbol_csv[3]}</href> </Icon></IconStyle>
	$coords_count++;
	$current_line++;
	$line = $lines[$current_line];
	chop $line;
	chop $line;
	$symbol_count++;
    }

    return $current_line;
}

sub note {
    my $current_line = shift;
    $current_line++;
    my $line = $lines[$current_line];
    chop $line;
    chop $line;
    
    until ($line eq 'END') { # A note looks like '40.709302,-74.355980,Note text'
	my @note_csv = split(',', $line);
	my $coords = kml_coord("$note_csv[0],$note_csv[1]");
	my $note = $note_csv[2];

	print OUT <<"EOT";
<Placemark>
    <name>Note: </name>
    <description>$note</description>
    <Point>
      <coordinates>$coords</coordinates>
    </Point>
  </Placemark>
EOT
	$current_line++;
	$line = $lines[$current_line];
	chop $line;
	chop $line;
    }

    return $current_line;
}

sub line {
    my $current_line = shift;
    $current_line++;
        
    my $line = $lines[$current_line];
    chop $line;
    chop $line;

    
    my $line_after_next = $current_line + 2;
    if ($only_polygons && ($lines[$line_after_next] ne 'END')) {  ## There should be no lines! (if this option is set)  If you see any lines make the first point the last point and create a polygon. (This excludes lines that are only two points long)
	$current_line--; # Because poly() will increment $current_line on its own.
	$current_line = poly($current_line);
    }
    else {  ## Draw a line
	until ($line eq 'END') { # A line looks like '40.725148,-74.323791'
	    my $coords = kml_coord($line);
	    print OUT <<"EOT";
<LineString>
      <extrude>1</extrude>
      <tessellate>1</tessellate>
      <coordinates>
$coords
      </coordinates>
    </LineString>
EOT
	    $coords_count++;
	    $line_count++;
	    $current_line++;
	    $line = $lines[$current_line];
	    chop $line;
	    chop $line;
	}
    }

    return $current_line;
}

## Utility Functions:
sub kml_coord {
    my $line = shift;
    $line = join(',', reverse(split(',', $line))) . ",0"; # Because KML expects long,lat,alt instead of lat,long,alt  (Altitude will always be zero in this program)
    return $line;
}


END {
    close(OUT);
}
