package Tpda3::Utils;

# ABSTRACT: Various utility functions

use strict;
use warnings;
use utf8;

use Encode qw(is_utf8 decode);

require Tpda3::Exceptions;

=head1 SYNOPSIS

Various utility functions used by all other modules.

    use Tpda3::Utils;

    my $foo = Tpda3::Utils->function_name();

=head2 transformations

Global hash reference.

=cut

my $transformations = {
    datey   => \&year_month,
    dateym  => \&year_month,
    datemy  => \&year_month,
    dateiso => \&date_string,
    dateamb => \&date_string,
    nothing => \&do_error,
    error   => \&do_error,
};

=head2 trim

Trim strings or arrays.

=cut

sub trim {
    my ( $self, @text ) = @_;

    for (@text) {
        s/^\s+//;
        s/\s+$//;
    }

    return wantarray ? @text : "@text";
}

=head2 dateentry_parse_date

Parse date for Tk::DateEntry.

=cut

sub dateentry_parse_date {

    my ( $self, $format, $date ) = @_;

    return unless $date;

    my ( $y, $m, $d );

    # Default date style format
    $format = 'iso' unless $format;

  SWITCH: for ($format) {
        /^$/ && warn "Error in 'dateentry_parse_date'\n";
        /german/i && do {
            ( $d, $m, $y )
                = ( $date =~ m{([0-9]{2})\.([0-9]{2})\.([0-9]{4})} );
            last SWITCH;
        };
        /iso/i && do {
            ( $y, $m, $d )
                = ( $date =~ m{([0-9]{4})\-([0-9]{2})\-([0-9]{2})} );
            last SWITCH;
        };
        /usa/i && do {
            ( $m, $d, $y )
                = ( $date =~ m{([0-9]{2})\/([0-9]{2})\/([0-9]{4})} );
            last SWITCH;
        };

        # DEFAULT
        warn "Wrong date format: $format\n";
    }

    return ( $y, $m, $d );
}

=head2 dateentry_format_date

Format date for Tk::DateEntry.

=cut

sub dateentry_format_date {

    my ( $self, $format, $y, $m, $d ) = @_;

    return unless $y and $m and $d;

    my $date;

    # Default date style format
    $format = 'iso' unless $format;

  SWITCH: for ($format) {
        /^$/ && warn "Error in 'dateentry_format_date'\n";
        /german/i && do {
            $date = sprintf( "%02d.%02d.%4d", $d, $m, $y );
            last SWITCH;
        };
        /iso/i && do {
            $date = sprintf( "%4d-%02d-%02d", $y, $m, $d );
            last SWITCH;
        };
        /usa/i && do {
            $date = sprintf( "%02d/%02d/%4d", $m, $d, $y );
            last SWITCH;
        };

        # DEFAULT
        warn "Unknown date format: $format\n";
    }

    return $date;
}

=head2 sort_hash_by_id

Use ST to sort hash by value (Id), returns an array or an array
reference of the sorted items.

=cut

sub sort_hash_by_id {
    my ( $self, $attribs ) = @_;

    #-- Sort by id
    #- Keep only key and id for sorting
    my %temp = map { $_ => $attribs->{$_}{id} } keys %{$attribs};

    #- Sort with  ST
    my @attribs = map { $_->[0] }
        sort { $a->[1] <=> $b->[1] }
        map { [ $_ => $temp{$_} ] }
        keys %temp;

    return wantarray ? @attribs : \@attribs;
}

=head2 filter_hash_by_keyvalue

Use ST to sort hash by value (Id), returns an array ref of the sorted
items, filtered by key => value.

=cut

sub filter_hash_by_keyvalue {
    my ($self, $attribs, $key, $value) = @_;

    #- Keep only key and id for sorting and filter by key -> value
    my %temp = map {
        $attribs->{$_}{$key} eq $value
            ? ( $_ => $attribs->{$_}{id} )
            : ()
    } keys %{$attribs};

    #- Sort with  ST by id
    my @attribs = map { $_->[0] }
        sort { $a->[1] <=> $b->[1] }
        map { [ $_ => $temp{$_} ] }
        keys %temp;

    return \@attribs;
}

=head2 quote4like

Surround text with '%', by default, for SQL LIKE.  An optional second
parameter can be used for 'start with' or 'end with' sintax.

If option parameter is not 'C', 'S', or 'E', 'C' is assumed.

=cut

sub quote4like {
    my ( $self, $text, $option ) = @_;

    if ( $text =~ m{%}xm ) {
        return $text;
    }
    else {
        $option ||= q{C};    # default 'C'
        return qq{$text%} if $option eq 'S';    # (S)tart with
        return qq{%$text} if $option eq 'E';    # (E)nd with
        return qq{%$text%};                     # (C)ontains
    }
}

=head2 special_ops

SQL::Abstract special ops for EXTRACT (YEAR|MONTH FROM field) = word1.

Note: Not compatible with SQLite.

=cut

sub special_ops {
    my $self = shift;

    return [

        {   regex   => qr/^extractyear$/i,
            handler => sub {
                my ( $self, $field, $op, $arg ) = @_;
                $arg = [$arg] if not ref $arg;
                my $label         = $self->_quote($field);
                my ($placeholder) = $self->_convert('?');
                my $sql           = $self->_sqlcase('extract (year from')
                    . " $label) = $placeholder ";
                my @bind = $self->_bindtype( $field, @$arg );
                return ( $sql, @bind );
                }
        },
        {   regex   => qr/^extractmonth$/i,
            handler => sub {
                my ( $self, $field, $op, $arg ) = @_;
                $arg = [$arg] if not ref $arg;
                my $label         = $self->_quote($field);
                my ($placeholder) = $self->_convert('?');
                my $sql           = $self->_sqlcase('extract (month from')
                    . " $label) = $placeholder ";
                my @bind = $self->_bindtype( $field, @$arg );
                return ( $sql, @bind );
                }
        },
    ];
}

=head2 process_date_string

Try to identify the input string as full date, year or month and year
and return a where clause.

=cut

sub process_date_string {
    my ( $self, $search_input ) = @_;

    my $dtype = $self->identify_date_string($search_input);
    my $where = $self->format_query($dtype);

    return $where;
}

=head2 identify_date_string

Identify format of the I<input> I<string> from a date type field and
return the matched pieces in a string as separate values where the
separator is the colon character.

=cut

sub identify_date_string {
    my ( $self, $is ) = @_;

    #                When date format is...                     Type is ...
    return
          $is eq q{} ? 'nothing'
        : $is =~ m/^(\d{4})[\.\/-](\d{2})[\.\/-](\d{2})$/ ? "dateiso:$is"
        : $is =~ m/^(\d{2})[\.\/-](\d{2})[\.\/-](\d{4})$/ ? "dateamb:$is"
        : $is =~ m/^(\d{4})[\.\/-](\d{1,2})$/             ? "dateym:$1:$2"
        : $is =~ m/^(\d{1,2})[\.\/-](\d{4})$/             ? "datemy:$2:$1"
        : $is =~ m/^(\d{4})$/                             ? "datey:$1"
        :                                                   "dataerr:$is";
}

=head2 format_query

Execute the appropriate sub and return the where attributes Choices
are defined in the I<$transformations> hash.

=cut

sub format_query {
    my ( $self, $type ) = @_;

    my ( $directive, $year, $month ) = split /:/, $type, 3;

    my $where;
    if ( exists $transformations->{$directive} ) {
        $where = $transformations->{$directive}->( $year, $month );
    }
    else {

        # warn "Unrecognized directive '$directive'";
        $where = $directive;
    }

    return $where;
}

=head2 year_month

Case of string identified as year and/or month.

=cut

sub year_month {
    my ( $year, $month ) = @_;

    my $where = {};
    $where->{-extractyear}  = [$year]  if ($year);
    $where->{-extractmonth} = [$month] if ($month);

    return $where;
}

=head2 date_string

Case of string identified as full date string, regardless of the format.

=cut

sub date_string {
    my ($date) = @_;
    return $date;
}

=head2 do_error

Case of string not identified or empty.

=cut

sub do_error {
    my ($date) = @_;
    print "String not identified or empty!\n";
    return;
}

=head2 ins_underline_mark

Insert ampersand character for underline mark in menu.

=cut

sub ins_underline_mark {
    my ( $self, $label, $position ) = @_;

    die "Wrong parameters for 'ins_underline_mark'"
        unless $label and defined $position;

    substr( $label, $position, 0 ) = '&';

    return $label;
}

=head2 deaccent

Remove Romanian accented characters.

TODO: Add other accented characters, especially for German and Hungarian.

=cut

sub deaccent {
    my ( $self, $text ) = @_;

    $text =~ tr/ăĂãÃâÂîÎșȘşŞțȚţŢ/aAaAaAiIsSsStTtT/;

    return $text;
}

=head2 check_path

Check a path and throw an exception if not valid.

=cut

sub check_path {
    my ($self, $path) = @_;

    unless ($path and -d $path) {
        Exception::IO::PathNotFound->throw(
            pathname => $path,
            message  => 'Path not found',
        );
    }

    return;
}

=head2 check_file

Check a file path and throw an exception if not valid.

=cut

sub check_file {
    my ($self, $file) = @_;

    unless ($file and -f $file) {
        Exception::IO::FileNotFound->throw(
            filename => $file,
            message  => 'File not found',
        );
    }

    return;
}

=head2 decode_unless_utf

Decode a string if is not utf8.

=cut

sub decode_unless_utf {
    my ($self, $value) = @_;
    $value = decode( 'utf8', $value ) unless is_utf8($value);
    return $value;
}

=head2 parse_message

Parse a message text in the following format:

   error#Message text
   info#Message text
   warn#Message text

and return the coresponding mesage text and color.

=cut

sub parse_message {
    my ($self, $text) = @_;

    (my $type, $text) = split /#/, $text, 2;

    # Allow empty type
    unless ($text) {
        $text = $type;
        $type = q{};
    }

    my $color;
  SWITCH: {
        $type eq 'error' && do { $color = 'darkred';   last SWITCH; };
        $type eq 'info'  && do { $color = 'darkgreen'; last SWITCH; };
        $type eq 'warn'  && do { $color = 'orange';    last SWITCH; };
        $color = 'black';                    # default
    }

    return ($text, $color);
}

1;
