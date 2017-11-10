#!/usr/bin/perl -w

use strict;
use warnings;

use CGI;
use GD;

use gui;
use limesfunctions;

our %cgi = gui::get_cgi();

#sub get_cgi
#{
#	my $q = new CGI;
#	my %cgi;
#	my @tmp = $q->param;
#	for(@tmp)
#	{
#		$cgi{$_} = join(',',$q->param($_));
#		$cgi{$_} =~ s/'/\\'/g;
#		$cgi{$_} =~ s/"/\\"/g;
#	}
#
#	return(%cgi);
#}

if (limesfunctions::deflen($cgi{'width'}) && limesfunctions::deflen($cgi{'height'}))
{
	my $width  = int($cgi{'width'});
	my $height  = int($cgi{'height'});

	my $imgtype = "png";

	my $image = new GD::Image($width,$height,1);

	for (my $y = 0; $y <= $height; $y++)
	{
		my $x = 0;
		foreach (split(',', $cgi{"r".$y}))
		{
			my ($hex, $repeat) = split(':', $_);
			$hex = hex($hex);
			$image->setPixel($x,$y,$hex);
			if (limesfunctions::deflen($repeat))
			{
				my $i = 1;
				while ($i < $repeat)
				{
					$x++;
					$image->setPixel($x,$y,$hex);
					$i++;
				}
			}
			$x++;
		}
	}

	my $query = new CGI;
	print $query->header(	-type => 'image/$imgtype',
				-attachment => 'graph.png'
	);
	binmode STDOUT;
	print $image->$imgtype;
}
