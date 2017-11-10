# This file is part of the Open AS Communication Gateway.
#
# The Open AS Communication Gateway is free software: you can redistribute it
# and/or modify it under theterms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
#
# The Open AS Communication Gateway is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero
# General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License along
# with the Open AS Communication Gateway. If not, see http://www.gnu.org/licenses/.


package Underground8::Service::Postfwd::SLAVE;
use base Underground8::Service::SLAVE;

use strict;
use warnings;

use Underground8::Utils;
use Underground8::Exception; 
use Underground8::Exception::FileOpen; 
use Underground8::Exception::Execution;
use Error; 
use Template;
use XML::Dumper;


sub new ($$) {
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->{'_initialized'} = 0;
    return $self;
}
	
sub load_config_xml($){
    my $self = instance(shift, __PACKAGE__);
	my $config = {};

	my $dump = new XML::Dumper;

	# If config doesn't exist yet, write default config
	if(! -e $g->{'cfg_postfwd'}) {
		$self->write_config_xml_default();
	}

	$config = $dump->xml2pl( $g->{'cfg_postfwd'} );
	return $config;
}

sub write_config_xml($$) {
    my $self = instance(shift, __PACKAGE__);
	my $config = shift;

	my $dump = new XML::Dumper;
	$dump->pl2xml( $config, $g->{'cfg_postfwd'} );
}

sub write_config_xml_default {
	my $self = instance(shift);
	
	my $dump = new XML::Dumper;
	my %default_config = ( 
		status => 'disabled',
		status_bwman => 'disabled',
		status_rbl => 'disabled',
		status_greylisting => 'disabled',
		status_selective_greylisting => 'disabled',
		rbl_threshold => '2',

		blacklist => [ ],
		whitelist => [ ],
		rbls => { },
	);

	# Dump default XML & re-read
	$dump->pl2xml( \%default_config, $g->{'cfg_postfwd'} );
}

sub write_config_postfwd($$){
    my $self = instance(shift, __PACKAGE__);
	my $config = shift;

	my $rbls_hash = $config->{'rbls'};
	my @rbls_list = sort { $rbls_hash->{$a}->{'rank'} <=> $rbls_hash->{$b}->{'rank'} } keys %$rbls_hash;

	my $options = {
		'blacklist' => $config->{'blacklist'},
		'whitelist' => $config->{'whitelist'},
		'rbls' => $config->{'rbls'},
		'rbls_list' => \@rbls_list,
		'rbl_threshold' => $config->{'rbl_threshold'} || "2",

		'status_bwman' => $config->{'status_bwman'},
		'status_rbl' => $config->{'status_rbl'},
		'status_greylisting' => $config->{'status_greylisting'},
		'status_selective_greylisting' => $config->{'status_selective_greylisting'},
	};


	# Process template
	my $postfwd_cf_content;
    my $template = Template->new({ INCLUDE_PATH => $g->{'cfg_template_dir'}, });

	$template->process( $g->{'template_postfwd_cf'}, $options, \$postfwd_cf_content )
		or throw Underground8::Exception( $template->error );

	# Whitespace removal (doing this within TT code totally scrambles its structure)
	$postfwd_cf_content =~ s/^\s*//gm;

	# Write postfwd.cf
	open(POSTFWD_CF, '>', $g->{'file_postfwd_cf'} )
		or throw Underground8::Exception::FileOpen( $g->{'file_postfwd_cf'} );
	print POSTFWD_CF $postfwd_cf_content;
	close(POSTFWD_CF);



	# In addition, we'll have to write /etc/default/postfwd
	my $postfwd_default_content;
	my $template_def = Template->new({ INCLUDE_PATH => $g->{'cfg_template_dir'}, });

	$template_def->process( $g->{'template_postfwd_default'}, $options, \$postfwd_default_content )
		or throw Underground8::Exception( $template_def->error );

	# Write it
	open(POSTFWD_DEFAULT, '>', $g->{'file_postfwd_default'} )
		or throw Underground8::Exception::FileOpen( $g->{'file_postfwd_default'} );
	print POSTFWD_DEFAULT $postfwd_default_content;
	close(POSTFWD_DEFAULT);

}

sub commit($$){
    my $self = instance(shift, __PACKAGE__);
	my $config = shift;

	$self->write_config_xml($config);
	$self->write_config_postfwd($config);

}

sub service_restart ($)
{
    my $self = instance(shift);
	# this is -SO- bad
	try {
		#safe_system( $g->{'cmd_postfwd_kill'} . " || true" );
		#safe_system( $g->{'cmd_postfwd_start'} . " || true" );
		safe_system( $g->{'cmd_postfwd_restart'} . " || true" );
	} catch Underground8::Exception with {
		return 1;
	};

}

1;
