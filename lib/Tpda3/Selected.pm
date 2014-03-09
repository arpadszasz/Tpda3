package Tpda3::Selected;

use strict;
use warnings;
use utf8;

=head1 NAME

Tpda3::Selected - Selected field values in dictionary like tables

=head1 VERSION

Version 0.80

=cut

our $VERSION = 0.80;

=head1 SYNOPSIS

    use Tpda3::Selected;

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my ($type, $opts) = @_;

    my $self = {};

    bless( $self, $type );

    my $cfg = Tpda3::Config->instance();
    my $ws  = $cfg->application->{widgetset};
    $self->{_ws} = $ws;

    if ( $ws =~ m{wx}i ) {
        # require Tpda3::Wx::Dialog::Select;
        # $self->{dlg} = Tpda3::Wx::Dialog::Select->new($opts);
    }
    elsif ( $ws =~ m{tk}i ) {
        require Tpda3::Tk::Dialog::Select;
        $self->{dlg} = Tpda3::Tk::Dialog::Select->new($opts);
    }
    else {
        warn "Unknown widget set!\n";
        exit;
    }

    return $self;
}

=head2 selected

Show dialog and return selected record.

=cut

sub selected {
    my ( $self, $view, $para ) = @_;

    my $record;
    if ( $self->{_ws} =~ m{tk}ix ) {
        $record = $self->{dlg}->select_dialog( $view, $para );
    }
    elsif ( $self->{_ws} =~ m{wx}ix ) {
        # my $dialog = $self->{dlg}->select_dialog( $view, $para );
        # if ( $dialog->ShowModal == &Wx::wxID_CANCEL ) {
        #     print "Dialog cancelled\n";
        # }
        # else {
        #     $record = $self->{dlg}->get_selected_item();
        # }
    }

    return $record;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tpda3::Selected

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Stefan Suciu.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut

1;    # End of Tpda3::Selected
