package Tpda3::Tk::TMSHR;

use strict;
use warnings;
use utf8;
use Carp;

use Math::Symbolic;

use Tpda3::Utils;

use Tk;
use base qw{Tk::Derived Tk::TableMatrix::SpreadsheetHideRows};

Tk::Widget->Construct('TMSHR');

=head1 NAME

Tpda3::Tk::TMSHR - Create a table matrix SpreadsheetHideRows widget.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Tpda3::Tk::TMSHR;

    my ($xtvar, $expand_data) = ( {}, {} );
    my $xtable = $frame->Scrolled(
        'TMSHR',
        -rows           => 6,
        -cols           => 1,
        -width          => -1,
        -height         => -1,
        -ipadx          => 3,
        -titlerows      => 1,
        -variable       => $xtvar,
        -selectmode     => 'single',
        -colstretchmode => 'unset',
        -resizeborders  => 'none',
        -bg             => 'white',
        -scrollbars     => 'osw',
        -expandData     => $expand_data,
    );
    $xtable->pack( -expand => 1, -fill => 'both' );

    $xtable->make_header($header);
    $xtable->fill_main($record_aoh, 'rowcountcolname');
    $xtable->fill_details($expanddata);

=head1 METHODS

=head2 ClassInit

Constructor method.

=cut

sub ClassInit {
    my ( $class, $mw ) = @_;

    $class->SUPER::ClassInit($mw);

    return;
}

=head2 Populate

Constructor method.

=cut

sub Populate {
    my ( $self, $args ) = @_;

    $self->SUPER::Populate($args);

    return $self;
}

=head2 init

Write header on row 0 of TableMatrix

=cut

sub make_header {
    my ( $self, $args ) = @_;

    $self->{columns}    = $args->{columns};
    $self->{colstretch} = $args->{colstretch};

    $self->set_tags();

    return;
}

=head2 set_tags

Set tags for the table matrix.

=cut

sub set_tags {
    my $self = shift;

    my $cols = scalar keys %{ $self->{columns} };
    $cols++;                    # increase cols number with 1

    # Tags for the detail data:
    $self->tagConfigure(
        'detail',
        -bg     => 'darkseagreen2',
        -relief => 'sunken',
    );
    $self->tagConfigure(
        'detail2',
        -bg     => 'burlywood2',
        -relief => 'sunken',
    );
    $self->tagConfigure(
        'detail3',
        -bg     => 'lightyellow',
        -relief => 'sunken',
    );

    $self->tagConfigure(
        'expnd',
        -bg     => 'grey85',
        -relief => 'raised',
    );
    $self->tagCol( 'expnd', 0 );

    # Make enter do the same thing as return:
    $self->bind( '<KP_Enter>', $self->bind('<Return>') );

    if ($cols) {
        $self->configure( -cols => $cols );

        # $self->configure( -rows => 1 ); # Keep table dim in grid
    }
    $self->tagConfigure(
        'active',
        -bg     => 'lightyellow',
        -relief => 'sunken',
    );
    $self->tagConfigure(
        'title',
        -bg     => 'tan',
        -fg     => 'black',
        -relief => 'raised',
        -anchor => 'n',
    );
    $self->tagConfigure( 'find_left', -anchor => 'w', -bg => 'lightgreen' );
    $self->tagConfigure(
        'find_center',
        -anchor => 'n',
        -bg     => 'lightgreen',
    );
    $self->tagConfigure(
        'find_right',
        -anchor => 'e',
        -bg     => 'lightgreen',
    );
    $self->tagConfigure( 'ro_left',      -anchor => 'w', -bg => 'lightgrey' );
    $self->tagConfigure( 'ro_center',    -anchor => 'n', -bg => 'lightgrey' );
    $self->tagConfigure( 'ro_right',     -anchor => 'e', -bg => 'lightgrey' );
    $self->tagConfigure( 'enter_left',   -anchor => 'w', -bg => 'white' );
    $self->tagConfigure( 'enter_center', -anchor => 'n', -bg => 'white' );
    $self->tagConfigure(
        'enter_center_blue',
        -anchor => 'n',
        -bg     => 'lightblue',
    );
    $self->tagConfigure( 'enter_right', -anchor => 'e', -bg => 'white' );
    $self->tagConfigure( 'find_row', -bg => 'lightgreen' );

    # TableMatrix header, Set Name, Align, Width, and skip
    foreach my $field ( keys %{ $self->{columns} } ) {
        my $col = $self->{columns}{$field}{id};
        $self->tagCol( $self->{columns}{$field}{tag}, $col );
        $self->set( "0,$col", $self->{columns}{$field}{label} );

        # If colstretch = 'n' in screen config file, don't set width,
        # because of the -colstretchmode => 'unset' setting, col 'n'
        # will be of variable width
        next if $self->{colstretch} and $col == $self->{colstretch};

        my $width = $self->{columns}{$field}{width};
        if ( $width and ( $width > 0 ) ) {
            $self->colWidth( $col, $width );
        }
    }

    $self->tagRow( 'title', 0 );
    if ( $self->tagExists('expnd') ) {

        # Change the tag priority
        $self->tagRaise( 'expnd', 'title' );
    }

    return;
}

=head2 clear_all

Clear all data from the Tk::TableMatrix widget, but preserve the header.

=cut

sub clear_all {
    my $self = shift;

    my $rows_no  = $self->cget( -rows );
    my $rows_idx = $rows_no - 1;
    my $r;

    $self->configure( -expandData => {} );   # clear detail data

    for my $row ( 1 .. $rows_idx ) {
        $self->deleteRows( $row, 1 );
    }

    return;
}

=head2 fill_main

Fill TableMatrix widget with data from the main table.

=cut

sub fill_main {
    my ( $self, $record_ref, $countcol ) = @_;

    my $xtvar = $self->cget( -variable );

    my $rows = 0;

    #- Scan DS and write to table

    foreach my $record ( @{$record_ref} ) {
        my $row = $record->{$countcol};
        foreach my $field ( keys %{ $record } ) {
            my ( $cell_value, $col )
                = $self->compute_format_value( $field, $row, $record );
            $xtvar->{"$row,$col"} = $cell_value;
        }

        $rows = $row;
    }

    $self->configure( -rows => $rows + 1 );      # refreshing the table...

    return;
}

=head2 fill_details

Fill TableMatrix widget expand data from the dependent table(s).

=cut

sub fill_details {
    my ( $self, $record_ref ) = @_;

    $self->configure( -expandData => $record_ref );

    return;
}

=head2 compute_format_value

Compute and/or format value.

=cut

sub compute_format_value {
    my ($self, $field, $row, $record) = @_;

    my $fld_cfg = $self->{columns}{$field};

    croak "$field field's config is EMPTY\n" unless %{$fld_cfg};

    my ( $col, $validtype, $width, $places, $datasource )
        = @$fld_cfg{ 'id', 'validation', 'width', 'places', 'datasource' };

    my $value;
    if ( $datasource =~ m{=count} ) {

        # Count
        $value = $row;    # number the rows
    }
    elsif ( $datasource =~ m{=(.*)} ) {
        my $funcdef = $1;
        if ($funcdef) {

            # Formula
            my $ret = $self->get_function( $field, $funcdef );
            my ( $func, $vars ) = @{$ret};

            # Function args are numbers, avoid undef
            my @args = map { defined( $record->{$_} ) ? $record->{$_} : 0 }
                @{$vars};
            $value = $func->(@args);
        }
    }
    else {
        $value = $record->{$field};
    }

    $value = q{} unless defined $value;    # empty value
    $value =~ s/[\n\t]//g;                 # delete control chars

    if ( $validtype eq 'numeric' ) {
        $value = 0 unless $value;
        if ( defined $places ) {
            $value = sprintf( "%.${places}f", $value );
        }
        else {
            $value = sprintf( "%.0f", $value );
        }
    }

    return ($value, $col);
}

=head2 get_function

Make a reusable anonimous function to compute a field's value, using
the definition from the screen configuration and the Math::Symbolic
module.

It's intended use is for simple functions, like in this example:

  datasource => '=quantityordered*priceeach'

Suported operations: arithmetic (-+/*).

=cut

sub get_function {
    my ($self, $field, $funcdef) = @_;

    return $self->{$field} if exists $self->{$field}; # don't recreate it

    unless ($field and $funcdef) {
        croak "$field field's compute is EMPTY\n" unless $funcdef;
        return;
    }

    # warn "new function for: $field = ($funcdef)\n";

    ( my $varsstr = $funcdef ) =~ s{[-+/*]}{ }g; # replace operator with space

    my $tree = Math::Symbolic->parse_from_string($funcdef);
    my @vars = split /\s+/, $varsstr; # extract the names of the variables
    unless ($self->check_varnames(\@vars) ) {
        croak "Config error: computed variable names doesn't match field names!";
    }

    my ($sub) = Math::Symbolic::Compiler->compile_to_sub( $tree, \@vars );

    $self->{$field} = [$sub, \@vars];        # save for later use

    return $self->{$field};
}

=head2 check_varnames

Check if arguments variable names match field names.

=cut

sub check_varnames {
    my ( $self, $vars ) = @_;

    my $check = 1;
    foreach my $field ( @{$vars} ) {
        unless ( exists $self->{columns}{$field} ) {
            $check = 0;
            last;
        }
    }

    return $check;
}

sub get_expdata {
    my $self = shift;

    return $self->cget( -expandData );
}

=head2 get_main_data

Read main data from the widget.

=cut

sub get_main_data {
    my $self = shift;

    my $xtvar = $self->cget( -variable );

    my $rows_no  = $self->cget( -rows );
    my $cols_no  = $self->cget( -cols );
    my $rows_idx = $rows_no - 1;
    my $cols_idx = $cols_no - 1;

    my $fields_cfg = $self->{columns};
    my $cols_ref   = Tpda3::Utils->sort_hash_by_id($fields_cfg);

    # # Read table data and create an AoH
    my @tabledata;

    # The first row is the header
    for my $row ( 1 .. $rows_idx ) {

        my $rowdata = {};
        for my $col ( 0 .. $cols_idx ) {
            my $cell_value = $self->get("$row,$col");
            my $col_name   = $cols_ref->[$col-1];

            next unless $col_name;

            $rowdata->{$col_name} = $cell_value;
        }

        push @tabledata, $rowdata;
    }

    return (\@tabledata);
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at user.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2012 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1;    # end of Tpda3::Tk::TMSHR
