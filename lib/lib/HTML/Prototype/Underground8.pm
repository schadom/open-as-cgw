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


package HTML::Prototype::Underground8;
use base qw/Class::Accessor::Fast HTML::Prototype/;
use strict;
use warnings;

# overriden
sub define_javascript_functions
{
    my $prototype = '/static/js/prototype.js';
    my $scriptaculous = '/static/js/scriptaculous.js';
    
    my $script = "<script src=\"$prototype\" type=\"text/javascript\"/>
                  <script src=\"$scriptaculous\" type=\"text/javascript\"/>";
    return $script; 
}

sub _loading_func ($$)
{
    my $self = shift;
    my $field = shift;
    my $size = shift;

    my $spinner;
    if ($size =~ qr/small/)
    {
       $spinner = '<img src=/static/images/ai_small.gif />';
    }
    else
    {
       $spinner = '<img src=/static/images/ai_big.gif />';
    }

    my $func = $self->update_element_function($field,{
                                                        action => 'update',
                                                        content => $spinner,
                                                     }
                                             );
    return $func;
}

sub _highlight_effect ($$)
{
    my $self = shift;
    my $field = shift;
    
    my $effect = $self->visual_effect('highlight',$field, {
                                                            duration => '1.0',
                                                            startcolor => '\'#FF9900\'',
                                                          }
                                     );
    return $effect;
}

sub _infobar_effect ($$)
{
    my $self = shift;
    my $field = shift;

    my $effect = "Effect.toggle('$field','slide',{duration: 0.2})";
    
    return $effect;
} 

sub _helpbar_effect ($$)
{
    my $self = shift;
    my $field = shift;

    my $effect = "new Effect.Appear('$field',{duration: 0.5, to: 0.95})";
    
    return $effect;
} 

sub link_with_indicator ($$$)
{
    my $self = shift;
    my $text = shift;
    my $opts = shift;

    my $field = $opts->{'update'};
    my $indicator = $opts->{'indicator'} || $field;
    my $indicator_size = $opts->{'indicator_size'} || 'normal';
    my $highlight = $opts->{'highlight'};
    my $infobar = $opts->{'infobar'};
    my $helpbar = $opts->{'helpbar'};
    my $class = $opts->{'class'}; # css class of the html tag

    my $check_exception = "redirect_on_event();";
    $opts->{'after'} = $self->_loading_func($indicator, $indicator_size);
    $opts->{'complete'} = $self->_highlight_effect($highlight) if $highlight;
    $opts->{'complete'} = $self->_infobar_effect($infobar) if $infobar;
    $opts->{'complete'} = $self->_helpbar_effect($helpbar) if $helpbar;
    $opts->{'complete'} = $check_exception . ($opts->{'complete'} ? $opts->{'complete'} : "");

    my $link = $self->link_to_remote($text,$opts);

    if ($class)
    {
        $link =~ s/(href)/class="$class" $1/;
    }

    return $link;
}

sub form_with_indicator ($$$)
{
    my $self = shift;
    my $opts = shift;

    my $field = $opts->{'update'};
    my $indicator = $opts->{'indicator'} || $field;
    my $indicator_size = $opts->{'indicator_size'} || 'normal';
    my $highlight = $opts->{'highlight'};
    my $infobar = $opts->{'infobar'};

    my $check_exception = "redirect_on_event();";
    $opts->{'complete'} = $check_exception . ($opts->{'complete'} ? $opts->{'complete'} : "");
    $opts->{'after'} = $self->_loading_func($indicator,$indicator_size);
    $opts->{'complete'} .= $self->_highlight_effect($highlight) if $highlight;
    $opts->{'complete'} .= $self->_infobar_effect($infobar) if $infobar;
    #$opts->{'loaded'} = $check_exception;

    my $form = $self->form_remote_tag($opts);
    return $form;
}

# overridden
sub form_remote_tag {
    my ( $self, $options ) = @_;
    $options->{form} = 1;
    $options->{html_options}->{id}= $options->{id};
    $options->{html_options} ||= {};
    $options->{html_options}->{action} ||= $options->{url} || '#';
    $options->{html_options}->{method} ||= 'post';
    
    $options->{html_options}->{onsubmit} =
      HTML::Prototype::_remote_function($options) . '; return false';
    return $self->tag( 'form', $options->{html_options}, 1 );
}
 

sub button_with_indicator ($$$)
{
    my $self = shift;
    my $text = shift;
    my $opts = shift;

    my $name        = $opts->{'name'};
    my $url         = $opts->{'url'}; 
    my $field       = $opts->{'update'};
    my $class       = $opts->{'class'};
    my $effect      = $opts->{'effect'};
    my $indicator   = $opts->{'indicator'} || $field;
    my $indicator_size = $opts->{'indicator_size'} || 'normal';
    my $infobar     = $opts->{'infobar'};

    my $loading_func = $self->_loading_func($indicator,$indicator_size);
    my $effect_func = "redirect_on_event();";
    $effect_func .= $self->_infobar_effect($infobar) if $infobar;
    $effect_func .= "; $effect" if $effect;
    
    my $code='<input type="submit" id="%s" class="%s" onclick ="new Ajax.Updater(\'%s\',\'%s\', { asynchronous: 1, onComplete: function(request){%s} } ); %s; return false;" value="%s"/>';
    my $button = sprintf ($code,
                            $name,
                            $class, 
                            $field,
                            $url,
                            $effect_func,                            
                            $loading_func,
                            $text);

    #'<button id="delete" class="save" onclick="new Ajax.Updater(\'[% id_domain_name %]\',  \'[% url_domain_delete %]', { asynchronous: 1,onComplete: function(request){new Effect.DropOut('[% id_domain_name %]',{duration: 0.5, to: 0.95})} } )  ; $('[% id_domain_name_submit %]').innerHTML = '&lt;img src=/static/images/spinning_wheel.gif /&gt;';; return false">[% Catalyst.localize('delete') %]</button>';
    return $button;
}

# overridden
sub link_to_remote
{
    my ( $self, $id, $options, $html_options ) = @_;

    my $link = $self->link_to_function( $id, HTML::Prototype::_remote_function($options),
                $html_options, $$options{url} );
    if ($link =~ qr/(\<a href=".+"\>).*\<\/a\>/)
    {
        my $link_href = $1;
        $link = $link_href . $id . "</a>";
    }

    #print Dumper $link;
    return $link;
}

1;
