#!/usr/bin/perl

# Bright Pixel Scan - Scan the pixels of a black image for bright spots
# Copyright (C) 2011 Shannon Wynter
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

use feature qw/state/;
use strict;
use warnings;

use Imager;
use Getopt::Long;

my %option = (
	threshold => 0.3,
);

sub usage {

print <<EOU;
$0 - Scan for bright pixels in a dark iamge
--------------------------------------------------------------
Synopsis:
    $0 -i a.jpg -t 0.3

Arguments:
    -i --image     - Source image to scan
    -t --threshold - Maximum pixel value threshold
    -c --clip      - Save 10x10px clips around the pixel

Default threshold is $option{threshold}

EOU
exit;
}

sub clip {
	my ($src, $x, $y) = @_;
	state $dir;

	my ($startX, $startY) = ($x - 5, $y - 5);

	my $img = Imager->new(xsize=>10, ysize=>10);
	$img->compose(
		src      => $src,
		tx       => 0,
		ty       => 0,
		src_minx => $startX,
		src_miny => $startY,
		src_maxx => $startX + 10,
		src_maxy => $startY + 10,
	);

	unless ($dir) {
		$dir = $option{image};
		$dir =~ s/\..+$//;
		mkdir $dir;
	}

	my $file = sprintf '%dx%d.%dx%x.jpg', $x, $y, $startX, $startY;
	my $path = "$dir/$file";

	$img->write(file => $path);

	return $path;
}

usage unless GetOptions(\%option,
	'image|i=s',
	'threshold|t=f',
	'clip|c',
);

usage unless $option{image};

my $img = Imager->new(file => $option{image}) or die "Unable to open " . $option{image} . ": $!\n";
my $height = $img->getheight();
my $width = $img->getwidth();
for my $y (0..$height-1) {
	for my $x (0..$width-1) {
		my %hsva;
		@hsva{qw/hue saturation value alpha/} = $img->getpixel(x => $x, y => $y)->hsv;
		if ($hsva{value} > $option{threshold}) {
			printf "Threshold exceeded @ %dx%d value: %-10.9f", $x, $y, $hsva{value};
			print " - 10x10px saved as " . clip($img, $x, $y) if $option{clip};
			print "\n";
		}
	}
}
