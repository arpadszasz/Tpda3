package Tpda3::Tk::Tools::TemplDet;

use strict;
use warnings;
use utf8;

use Tk::widgets qw(Table Checkbutton);
use File::Spec::Functions;
use List::Compare;
use Scalar::Util qw(blessed);
use List::MoreUtils qw(any);
#use Locale::TextDomain 1.20 qw(Tpda3); # has problems on page change
use POSIX qw (strftime);

require Tpda3::Generator;

use base q{Tpda3::Tk::Screen};

use Data::Printer;

=head1 NAME

Tpda3::Tk::Tools::TemplDet screen

=head1 VERSION

Version 0.83

=cut

our $VERSION = '0.83';

=head1 SYNOPSIS

    require Tpda3::Tk::Tools::TemplDet;

    my $scr = Tpda3::Tk::Tools::TemplDet->new;

    $scr->run_screen($args);

=head1 METHODS

=head2 _init

Initializations.

=cut

sub _init {
    my ($self) = @_;

    $self->{_cfg} = Tpda3::Config->instance;
    $self->{_db}  = Tpda3::Db->instance;
    $self->{widgets} = [];
    $self->{req_no}  = 0;

    return;
}

=head2 run_screen

The screen layout

=cut

sub run_screen {
    my ( $self, $nb ) = @_;

    $self->_init();

    my $rec_page   = $nb->page_widget('rec');
    my $det_page   = $nb->page_widget('det');
    $self->{view}  = $nb->toplevel;
    $self->{model} = $self->{view}{_model};
    $self->{bg}    = $self->{view}->cget('-background');

    my $validation
        = Tpda3::Tk::Validation->new( $self->{scrcfg}, $self->{view} );

    my $date_format = $self->{scrcfg}->app_dateformat();

    # For DateEntry day names
    my @daynames = ();
    foreach ( 0..6 ) {
        push @daynames, strftime( "%a", 0, 0, 0, 1, 1, 1, $_ );
    }

    #-  Top frame

    my $frm_top = $det_page->LabFrame(
        -foreground => 'blue',
        -label      => 'Template',
        -labelside  => 'acrosstop'
    )->pack(
        -expand => 0,
        -fill   => 'x',
    );

    #-  Bottom frame

    my $frm_bott = $det_page->Frame()->pack(
        -side   => 'bottom',
        -expand => 1,
        -fill   => 'both',
    );

    my $f1d = 110;              # distance from left

    #- id_tt (id_tt)

    my $lid_tt = $frm_top->Label( -text => 'ID', );
    $lid_tt->form(
        -top     => [ %0, 0 ],
        -left    => [ %0, 0 ],
        -padleft => 5,
    );

    my $eid_tt = $frm_top->MEntry(
        -width              => 10,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $eid_tt->form(
        -top  => [ '&', $lid_tt, 0 ],
        -left => [ %0,  $f1d ],
    );

    #- tt_file (tt_file)

    my $ltt_file = $frm_top->Label( -text => 'File', );
    $ltt_file->form(
        -top     => [ $lid_tt, 8 ],
        -left    => [ %0,      5 ],
    );

    my $ett_file = $frm_top->MEntry(
        -width              => 50,
        -disabledbackground => $self->{bg},
        -disabledforeground => 'black',
    );
    $ett_file->form(
        -top  => [ '&', $ltt_file, 0 ],
        -left => [ %0,  $f1d ],
        -padbottom => 5,
    );
    $ett_file->bind(
        '<KeyPress-Return>' => sub {
            $self->template_file();
        }
    );

    #-- Bottom left

    my $frm_tl = $frm_bott->LabFrame(
        -foreground => 'blue',
        -label      => 'Template variables',
        -labelside  => 'acrosstop'
    )->pack(
        -side   => 'left',
        -expand => 0,
        -fill   => 'both',
    );

    $self->{table} = $frm_tl->Table(
        -columns    => 4,
        -rows       => 8,
        -fixedrows  => 1,
        -scrollbars => 'oe',
        -relief     => 'raised',
        -background => $self->{bg},
    );

    $self->{table}->pack(
        -expand => 1,
        -fill   => 'both',
        -padx   => 5,
        -pady   => 5,
    );

    # Header (inspired from: http://www.perltk.de/tk_widgets/wtk_table.html)
    $self->{table}->put( 0, 0, $self->header_label('#', 'crt_label') );
    $self->{table}->put( 0, 1, $self->header_label('Variable', 'fld_label') );
    $self->{table}->put( 0, 2, $self->header_label('Req', 'state_label') );
    $self->{table}->put( 0, 3, $self->header_label('State', 'cbx_require') );

    #-- Bottom right

    my $frm_br = $frm_bott->Frame(
    )->pack(
        -side   => 'right',
        -expand => 1,
        -fill   => 'both',
    );

    my $statis_fr = $frm_br->LabFrame(
        -foreground => 'blue',
        -label      => 'Statistics',
        -labelside  => 'acrosstop',
    )->pack(
        -side   => 'top',
        -expand => 0,
        -fill   => 'both',
        -ipady  => 10,
    );

    #-- Required

    $statis_fr->Label(
        -text   => 'Req.',
        -anchor => 'w',
    )->grid(
        -row    => 0,
        -column => 0,
        -sticky => 'e',
        -padx   => 3,
    );

    $self->{req_fields_no} = $statis_fr->Label(
        -text   => '0',
        -width  => 3,
        -relief => 'ridge',
        -anchor => 'e',
        -fg     => 'blue',
    )->grid(
        -row    => 0,
        -column => 1,
    );

    $statis_fr->Label(
        -text   => '/',
        -width  => 1,
    )->grid(
        -row    => 0,
        -column => 2,
    );

    $self->{tot_fields_no} = $statis_fr->Label(
        -text   => '0',
        -width  => 3,
        -relief => 'ridge',
        -anchor => 'e',
        -fg     => 'blue',
    )->grid(
        -row    => 0,
        -column => 3,
    );

    # #-- Frame Select

    # my $frm_bs = $frm_br->LabFrame(
    #     -foreground => 'blue',
    #     -label      => 'Select',
    #     -labelside  => 'acrosstop'
    # )->pack(
    #     -expand => 1,
    #     -fill   => 'both',
    # );

    # #--- Buttons select / deselect

    # $self->{btn_selall} = $frm_bs->Button(
    #     -text  => 'All',
    #     -font  => 'small',
    #     -width => 9,
    #     -command => sub { $self->select_req(1) }, # all
    # )->grid(
    #     -row    => 0,
    #     -column => 0,
    #     -pady   => 2,
    # );

    # $self->{btn_selnone} = $frm_bs->Button(
    #     -text => 'None',
    #     -font => 'small',
    #     -width  => 9,
    #     -command => sub { $self->select_req(0) }, # none
    # )->grid(
    #     -row    => 1,
    #     -column => 0,
    #     -pady   => 2,
    # );

    # $self->{btn_inverse} = $frm_bs->Button(
    #     -text => 'Inverse',
    #     -font => 'small',
    #     -width  => 9,
    #     -command => sub { $self->select_req() }, # inverse
    # )->grid(
    #     -row    => 2,
    #     -column => 0,
    #     -pady   => 2,
    # );

    #-- Frame toolbar

    my $frm_tb = $frm_br->LabFrame(
        -foreground => 'blue',
        -label      => 'Save/Update',
        -labelside  => 'acrosstop'
    )->pack(
        -side   => 'bottom',
        -expand => 1,
        -fill   => 'both',
    );

    #--- Buttons

    $self->{btn_save} = $frm_tb->Button(
        -text  => 'Save',
        -font  => 'small',
        -width => 9,
        -state => 'disabled',
        -command => sub { $self->update_db_table() },
    )->grid(
        -row    => 0,
        -column => 0,
        -pady   => 2,
    );

    $self->{btn_update} = $frm_tb->Button(
        -text => 'Update',
        -font => 'small',
        -width  => 9,
        -command => sub { $self->update_table_widget() },
    )->grid(
        -row    => 1,
        -column => 0,
        -pady   => 2,
    );

    # Entry objects: var_asoc, var_obiect
    # Other configurations in '.conf'
    $self->{controls} = {
        id_tt   => [ undef, $eid_tt ],
        tt_file => [ undef, $ett_file ],
    };

    return;
}

sub header_label {
    my ($self, $text, $name) = @_;
    my $label = $self->{table}->Label(
        -text   => $text,
        -relief => 'raised',
        -width  => get_col_width($name),
        -bg     => 'tan',
    );
    return $label;
}

sub colors {
    return {
        new => 'darkgreen',
        upd => 'black',
        del => 'darkred',
    };
}

sub widths {
    return {
        crt_label   => 3,
        fld_label   => 25,
        state_label => 5,
        cbx_require => 5,
    };
}

=head2 dbc

Return the Connection module handler.

=cut

sub dbc {
    my $self = shift;
    return $self->{_db}->dbc;
}

sub dbh {
    my $self = shift;
    return $self->{_db}->dbh;
}

sub cfg {
    my $self = shift;
    return $self->{_cfg};
}

sub model {
    my $self = shift;
    return $self->{model};
}

sub list_of_variables {
    my $self = shift;

    my $tt_file = $self->{controls}{tt_file}[1]->get;

    # Model file name
    my $model_file
        = catfile( $self->cfg->configdir, 'tex', 'model', $tt_file );
    unless ( -f $model_file ) {
        die "Template file not found: $model_file\n";
        return;
    }

    my $gen = Tpda3::Generator->new();
    my $fields_aref = $gen->extract_tt_fields($model_file);
    return $fields_aref;
}

sub on_load_record {
    my $self = shift;
    my $db_data = $self->read_db_table();
    $self->add_table_widgets($db_data);
    return;
}

sub read_table_widget {
    my $self = shift;

    my $rows  = $self->{table}->totalRows;
    my $id_tt = $self->{controls}{id_tt}[1]->get;

    my @records;
    foreach my $widget ( @{ $self->{widgets} } ) {
        my $crt_no   = $widget->{crt_label}->cget('-text');
        my $field    = $widget->{field};
        my $required = ${ $widget->{required} } // 0;
        my $state    = $widget->{state_label}->cget('-text');
        push @records, {
            id_tt    => $id_tt,
            id_art   => $crt_no,
            var_name => $field,
            required => $required,
        };
    }

    return \@records;
}

sub update_db_table {
    my $self = shift;

    my $id_tt   = $self->{controls}{id_tt}[1]->get;
    my $records = $self->read_table_widget;
    # print "to Save:\n";
    # p $records;

    # Table metadata
    my $table = 'templates_req';
    my $where = { id_tt => $id_tt };

    # Delete all articles and reinsert
    $self->model->table_record_delete( $table, $where );
    $self->model->table_batch_insert( $table, $records );

    $self->{btn_update}->configure(-state => 'normal');
    $self->{btn_save}->configure(  -state => 'disabled');

    $self->upd_table_widgets_state_all('rec');

    return;
}

sub update_labels {
    my ($self, $name, $value) = @_;
    $self->{$name}->configure(-text => $value) if defined $value;
    return;
}

sub read_db_table {
    my $self = shift;

    my $id_tt = $self->{controls}{id_tt}[1]->get;

    # From table
    my $args = {};
    $args->{table}    = 'templates_req';
    $args->{colslist} = [qw{var_name required}];
    $args->{where}    = {id_tt => $id_tt};
    $args->{order}    = 'var_name';
    my $db_data = $self->model->table_batch_query($args);

    return $db_data;
}

=head2 get_data_diff

Diference between databse table and file

=cut

sub get_data_diff {
    my $self = shift;

    my $db_data = $self->read_db_table();
    my $tt_data = $self->list_of_variables();
    #my $tw_data = $self->read_table_widget;

    my @fields = map { $_->{var_name} } @{$db_data};

    my $lc = List::Compare->new( $tt_data, \@fields );
    my @update = $lc->get_intersection;
    my @insert = map { { var_name => $_ } } $lc->get_unique;
    my @delete = $lc->get_complement;

    return (\@update, \@delete, \@insert);
}

sub get_color {
    my ($self, $state) = @_;
    return unless defined $state;
    return $self->colors->{$state};
}

sub get_col_width {
    my $name = shift;
    return widths->{$name};
}

sub update_table_widget {
    my $self = shift;

    my ($to_update, $to_delete, $to_insert ) = $self->get_data_diff();

    my $no_to_del = scalar @{$to_delete};
    print "to Delete [$no_to_del]:\n";
    # p $to_delete;
    $self->upd_table_widgets_state($to_delete, 'del');
    # Delete all and reinsert?
    # $self->{table}->clear;

    my $no_to_upd = scalar @{$to_update};
    print "to Update [$no_to_upd]:\n";
    # p $to_update;

    my $no_to_ins = scalar @{$to_insert};
    print "to Insert [$no_to_ins]:\n";
    # p $to_insert;
    $self->add_table_widgets($to_insert, 'new');

    $self->{btn_update}->configure('-state' => 'disabled');
    $self->{btn_save}->configure('-state' => 'normal');

    return;
}

# sub select_req {
#     my ($self, $state) = @_;
#     my $inverse = defined $state ? 0 : 1;
#     my $rows = $self->{table}->totalRows;
#     my $max_idx = $rows ? $rows - 2 : 0;
#     foreach my $i ( 0..$max_idx ) {
#         my $w = $self->{widgets}[$i]{cbx_require};
#         next unless blessed $w;
#         $inverse
#             ? $w->toggle
#             : ( $state ? $w->select : $w->deselect );
#     }
#     return;
# }

sub upd_table_widgets_state {
    my ( $self, $where, $state ) = @_;
    my $rows    = $self->{table}->totalRows;
    my $max_idx = $rows ? $rows - 2 : 0;
    foreach my $i ( 0 .. $max_idx ) {
        my $w = $self->{widgets}[$i]{state_label};
        next unless blessed $w;
        my $field = $self->{widgets}[$i]{field};
        if ( any { $field eq $_ } @{ $where } ) {
            my $fg = $self->get_color($state) || 'black';
            $w->configure( -text => $state, -fg => $fg );
        }
    }
    return;
}

sub upd_table_widgets_state_all {
    my ( $self, $state ) = @_;
    my $rows    = $self->{table}->totalRows;
    my $max_idx = $rows ? $rows - 2 : 0;
    foreach my $i ( 0 .. $max_idx ) {
        my $w = $self->{widgets}[$i]{state_label};
        next unless blessed $w;
        $w->configure( -text => $state );
    }
    return;
}

sub add_table_widgets {
    my ($self, $records, $state) = @_;

    my $rec_no = scalar @{$records};
    my $rows   = $self->{table}->totalRows;
    $state   //= 'rec';

    print "Add table widgets\n";
    print " table has $rows rows\n";
    print " add $rec_no records\n";

    my $req_no = 0;
    my $ri = $rows;             #  row index
    foreach my $rec ( @{$records} ) {
        my $ai = $ri ? $ri - 1 : 0; #  array index

        my $field    = $rec->{var_name};
        my $required = $rec->{required};

        my $crt_label   = $self->add_label($ri, 'crt_label');
        my $fld_label   = $self->add_label($field, 'fld_label', 'sunken', 'w');
        my $state_label = $self->add_label($state, 'state_label');

        # Require - checkbox
        my $v_required   = $required;
        my $cbx_require = $self->{table}->Checkbutton(
            -text        => 'yes',
            -indicatoron => 0,
            -selectcolor => 'LemonChiffon1',
            -state       => 'normal',
            -variable    => \$v_required,
            -relief      => 'raised',
            -width       => get_col_width('cbx_require'),
            -command     => sub { $self->req_state_change($v_required) },
        );

        $self->{table}->put( $ri, 0, $crt_label );
        $self->{table}->put( $ri, 1, $fld_label );
        $self->{table}->put( $ri, 2, $cbx_require );
        $self->{table}->put( $ri, 3, $state_label );

        $self->{widgets}[$ai] = {
            field       => $field,
            crt_label   => $crt_label,
            fld_label   => $fld_label,
            state_label => $state_label,
            cbx_require => $cbx_require,
            required    => \$v_required,
        };
        $ri++;

        $req_no++ if $required;
    }

    $self->update_labels('req_fields_no', $req_no);
    $self->update_labels('tot_fields_no', $rec_no);
    $self->{req_no} = $req_no;

    return;
}

sub add_label {
    my ($self, $label, $column, $relief, $anchor) = @_;

    # Label - field label
    return $self->{table}->Label(
        -text   => $label,
        -width  => get_col_width($column),
        -relief => $relief // 'sunken',
        -anchor => $anchor // 'c',
        -bg     => 'white',
    );
}

sub req_state_change {
    my ($self, $check) = @_;

    $self->{btn_update}->configure(-state => 'disabled');
    $self->{btn_save}->configure(  -state => 'normal');

    # Update label
    $check
        ? $self->{req_no}++
        : $self->{req_no}--;
    $self->update_labels('req_fields_no', $self->{req_no});

    return;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan at s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Stefan Suciu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut

1; # End of Tpda3::Tk::Tools::TemplDet
