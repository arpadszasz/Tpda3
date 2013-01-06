package Tpda3::Config::Screen;

use strict;
use warnings;
use Ouch;

use Log::Log4perl qw(get_logger);
use File::Spec::Functions;

require Tpda3::Config;
require Tpda3::Config::Utils;
require Tpda3::Utils;

use base qw(Class::Accessor);

=head1 NAME

Tpda3::Config::Screen - Configuration module for screen

=head1 VERSION

Version 0.62

=cut

our $VERSION = 0.62;

=head1 SYNOPSIS

Load the screen configuration.

    use Tpda3::Config::Screen;

    my $foo = Tpda3::Config::Screen->new();
    ...

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {
    my ( $class, $args ) = @_;

    my $self = {
        _cfg => Tpda3::Config->instance(),
    };

    bless $self, $class;

    $self->config_screen_load($args);
    $self->alter_toolbar_config();

    return $self;
}

=head2 _make_accessors

Automatically make accessors for the hash keys.

=cut

sub _make_accessors {
    my ( $self, $cfg_hr ) = @_;

    __PACKAGE__->mk_accessors( keys %{$cfg_hr} );

    # Add data to object
    foreach my $name ( keys %{$cfg_hr} ) {
        $self->$name( $cfg_hr->{$name} );
    }

    return;
}

=head2 config_screen_load

Load a Screen configuration files at request and make accessors.

=cut

sub config_screen_load {
    my ( $self, $scrcls ) = @_;

    my $log = get_logger();

    my $cfg_data = $self->config_screen_load_file($scrcls);

    my @accessor = keys %{$cfg_data};
    $log->info("Making accessors for: @accessor");

    $self->_make_accessors($cfg_data);

    return;
}

=head2 config_screen_load_file

Load a screen configuration file.

=cut

sub config_screen_load_file {
    my ( $self, $scrcls ) = @_;

    my $cfg_file = $self->_cfg->config_scr_file_name($scrcls);

    return $self->_cfg->config_load_file($cfg_file);
}

=head2 config_screen_load_yml

TODO: Refactor this ;)

=cut

sub config_screen_load_yml {
    my ( $self, $scrcls ) = @_;

    my $cfg_file = $self->_cfg->config_scr_file_name($scrcls);

    return $self->_cfg->config_load_file($cfg_file);
}

=head2 _cfg

Return config instance variable

=cut

sub _cfg {
    my $self = shift;

    return $self->{_cfg};
}

=head2 alter_toolbar_config

Fine tune the configuration for screens, alter behavior of toolbar
buttons per screen.

=cut

sub alter_toolbar_config {
    my $self = shift;

    my $tb_m = $self->_cfg->toolbar();
    my $tb_a = $self->screen_alter_toolbar();

    foreach my $tb ( keys %{$tb_a} ) {
        foreach my $pg ( keys %{ $tb_a->{$tb}{state} } ) {
            while ( my ( $k, $v ) = each( %{ $tb_a->{$tb}{state}{$pg} } ) ) {
                $tb_m->{$tb}{state}{$pg}{$k} = $v;
            }
        }
    }

    $self->_cfg->toolbar($tb_m);

    return;
}

=head2 app_dateformat

Date format configuration.

=cut

sub app_dateformat {
    my $self = shift;

    return $self->_cfg->application->{dateformat} || 'iso';
}

=head2 get_defaultreport_file

Return default report path and file, used by the print tool button.

=cut

sub get_defaultreport_file {
    my $self = shift;

    return catfile( $self->_cfg->configdir, 'rep',
        $self->defaultreport->{file} )
        if $self->defaultreport->{file};

    return;
}

=head2 get_defaultreport_name

Return default report description, used by the print tool button, as
the baloon label.

=cut

sub get_defaultreport_name {
    my $self = shift;

    return $self->defaultreport->{name};
}

=head2 get_defaultdocument_file

Return default document description, used by the generate tool button,
as the baloon label.

=cut

sub get_defaultdocument_file {
    my $self = shift;

    return catfile( $self->_cfg->config_tex_path('model'),
        $self->defaultdocument->{file} )
        if $self->defaultdocument->{file};

    return;
}

=head2 get_defaultdocument_name

Return default document description, used by the edit tool button, for
the baloon label.

=cut

sub get_defaultdocument_name {
    my $self = shift;

    return $self->defaultdocument->{name};
}

=head2 get_defaultdocument_datasource

Return default document datasource.

=cut

sub get_defaultdocument_datasource {
    my $self = shift;

    return $self->defaultdocument->{datasource};
}

=head2 screen_name

Screen name.

=cut

sub screen_name {
    my $self = shift;

    return $self->screen->{name};
}

=head2 screen_style

Return screen style attribute.

=cut

sub screen_style {
    my $self = shift;

    return $self->screen->{style};
}

=head2 screen_description

Return screen description string.

=cut

sub screen_description {
    my $self = shift;

    return $self->screen->{description};
}

=head2 screen_detail

Return details screen data structure.  Used for loading a different
screen modules in the B<Details> tab, based on a field value from the
B<Record> tab.

In the screen config example below C<cod_tip> can be B<CS> or B<CT>,
and for each the corresponding screen module is loaded.  The C<filter>
parametere is the foreign key of the database table.

  <screen>
      version             = 4
      ...
      <details>
          match           = cod_tip
          filter          = id_act
          <detail>
              value       = CS
              name        = Cursuri
          </detail>
          <detail>
              value       = CT
              name        = Consult
          </detail>
      </details>
  </screen>

=cut

sub screen_detail {
    my $self = shift;

    return $self->screen->{details};
}

=head2 has_screen_detail

Return true if the main screen has details screen.

=cut

sub has_screen_detail {
    my $self = shift;

    my $screen = $self->screen_detail;
    if ( ref $screen ) {
        return scalar keys %{$screen};
    }
    else {
        return $screen;
    }
}

=head2 main_table

Return the main table configuration data structure.

=cut

sub main_table {
    my $self = shift;

    return $self->maintable if $self->can('maintable');
}

=head2 main_table_name

Return the main table name.

=cut

sub main_table_name {
    my $self = shift;

    return $self->main_table->{name};
}

=head2 main_table_view

Return the main table view name.

=cut

sub main_table_view {
    my $self = shift;

    return $self->main_table->{view};
}

=head2 main_table_pkcol

Return the main table primary key column name.

=cut

sub main_table_pkcol {
    my $self = shift;

    return $self->main_table->{pkcol}{name};
}

=head2 main_table_fkcol

Return the main table foreign key column name.

=cut

sub main_table_fkcol {
    my $self = shift;

    if ( exists $self->main_table->{fkcol} ) {
        return $self->main_table->{fkcol}{name};
    }

    return;
}

=head2 main_table_columns

Return the main table columns configuration data structure.

=cut

sub main_table_columns {
    my $self = shift;

    return $self->main_table->{columns};
}

=head2 main_table_column

Return a column from the main table columns configuration data
structure.

=cut

sub main_table_column {
    my ( $self, $column ) = @_;

    return $self->main_table_columns->{$column};
}

=head2 main_table_column_attr

Return a column attribute from the main table columns configuration
data structure.

=cut

sub main_table_column_attr {
    my ( $self, $column, $attr ) = @_;

    return $self->main_table_column($column)->{$attr};
}

=head2 dep_table

Return the dependent table configuration data structure.

=cut

sub dep_table {
    my ( $self, $tm_ds ) = @_;

    return $self->deptable->{$tm_ds} if $self->can('deptable');
}

=head2 dep_table_name

Return the dependent table name.

=cut

sub dep_table_name {
    my ( $self, $tm_ds ) = @_;

    return $self->dep_table($tm_ds)->{name};
}

=head2 dep_table_view

Return the dependent table view name.

=cut

sub dep_table_view {
    my ( $self, $tm_ds ) = @_;

    return $self->dep_table($tm_ds)->{view};
}

=head2 dep_table_updatestyle

Return the dependent table I<update style> attribute.

=cut

sub dep_table_updatestyle {
    my ( $self, $tm_ds ) = @_;

    return $self->dep_table($tm_ds)->{updatestyle};
}

=head2 dep_table_selectorcol

Return the dependent table I<selector column> attribute.

=cut

sub dep_table_selectorcol {
    my ( $self, $tm_ds ) = @_;

    return $self->dep_table($tm_ds)->{selectorcol};
}

=head2 dep_table_has_selectorcol

Return true if the dependent table has I<selector column> attribute
set.

=cut

sub dep_table_has_selectorcol {
    my ( $self, $tm_ds ) = @_;

    my $sc = $self->dep_table_selectorcol($tm_ds);

    return if $sc eq 'none';

    return $sc;
}

=head2 dep_table_orderby

Return the dependent table I<order by> attribute.

=cut

sub dep_table_orderby {
    my ( $self, $tm_ds ) = @_;

    return $self->dep_table($tm_ds)->{orderby};
}

=head2 dep_table_colstretch

Return the dependent table I<colstretch> attribute.

=cut

sub dep_table_colstretch {
    my ( $self, $tm_ds ) = @_;

    return $self->dep_table($tm_ds)->{colstretch};
}

=head2 dep_table_selectorstyle

Return the dependent table I<selectorstyle> attribute.

=cut

sub dep_table_selectorstyle {
    my ( $self, $tm_ds ) = @_;

    return $self->dep_table($tm_ds)->{selectorstyle};
}

=head2 dep_table_datasources

Return the datasources config from the dependent table section.

=cut

sub dep_table_datasources {
    my ( $self, $tm_ds ) = @_;

    return $self->dep_table($tm_ds)->{datasources};
}

=head2 dep_table_rowcount

Return the dependent table I<rowcount> attribute.

=cut

sub dep_table_rowcount {
    my ( $self, $tm_ds ) = @_;

    return $self->dep_table($tm_ds)->{rowcount};
}

=head2 dep_table_pkcol

Return the dependent table primary key column name.

=cut

sub dep_table_pkcol {
    my ( $self, $tm_ds ) = @_;

    return $self->dep_table($tm_ds)->{pkcol}{name};
}

=head2 dep_table_fkcol

Return the dependent table foreign key column name.

=cut

sub dep_table_fkcol {
    my ( $self, $tm_ds ) = @_;

    return $self->dep_table($tm_ds)->{fkcol}{name};
}

=head2 dep_table_columns

Return the dependent table columns configuration data structure bound
to the related Tk::TableMatrix widget.

=cut

sub dep_table_columns {
    my ( $self, $tm_ds ) = @_;

    return $self->dep_table($tm_ds)->{columns};
}

=head2 dep_table_columns_by_level

Return the dependent table columns configuration data structure bound
to the related Tk::TableMatrix widget, filtered by the I<level>.

Columns with no level ...

=cut

sub dep_table_columns_by_level {
    my ( $self, $tm_ds, $level ) = @_;

    my $cols = $self->dep_table_columns($tm_ds);

    $level = 'level' . $level;
    my $dss;

    foreach my $col ( keys %{$cols} ) {
        my $ds = ref $cols->{$col}{datasource}
               ? $cols->{$col}{datasource}{$level}
               : $cols->{$col}{datasource};
        next unless $ds;
        $dss->{$ds} = [] unless exists $dss->{$ds};
        push @{ $dss->{$ds} }, $col;
    }

    return $dss;
}

=head2 dep_table_column

Return a column from the dependent table columns configuration data
structure bound to the related Tk::TableMatrix widget.

=cut

sub dep_table_column {
    my ( $self, $tm_ds, $column ) = @_;

    return $self->dep_table_columns($tm_ds)->{$column};
}

=head2 dep_table_column_attr

Return a column attribute from the dependent table columns
configuration data structure bound to the related Tk::TableMatrix
widget.

=cut

sub dep_table_column_attr {
    my ( $self, $tm_ds, $column, $attr ) = @_;

    return $self->dep_table($tm_ds)->{columns}{$column}{$attr};
}

=head2 screen_alter_toolbar

Return the toolbar config.

=cut

sub screen_alter_toolbar {
    my $self = shift;

    return $self->toolbar;
}

=head2 app_toolbar_attribs

Return the toolbar configuration data structure defined for the
current application, in the etc/toolbar.yml file.

=cut

sub app_toolbar_attribs {
    my $self = shift;

    return $self->_cfg->toolbar2;
}

=head2 screen_toolbars

Return the C<scrtoolbar> configuration data structure defined for the
curren screen.

If there is only one toolbar button then return it as an array reference.

=cut

sub _screen_toolbars {
    my ( $self, $name ) = @_;

    ouch 404, "Screen toolbar name is required" unless $name;

    my $scrtb = $self->scrtoolbar->{$name};
    my @toolbars;
    if (ref($scrtb) eq 'ARRAY') {
        @toolbars = @{$scrtb};
    }
    else {
        @toolbars = ($scrtb);
    }

    return \@toolbars;
}

=head2 scr_toolbar_names

Return the toolbar names and their method names configured for the
current screen.

=cut

sub scr_toolbar_names {
    my ($self, $name) = @_;

    my $attribs = $self->_screen_toolbars($name);
    my @tbnames = map { $_->{name} } @{$attribs};
    my %tbattrs = map { $_->{name} => $_->{method} } @{$attribs};

    return (\@tbnames, \%tbattrs);
}

=head2 scr_toolbar_groups

The scrtoolbar are grouped with a label that used to be the same as
the TM label, because each group was considered to be attached to a TM
widget.  Now screen toolbars can be defined separately.

This method returns the labels.

=cut

sub scr_toolbar_groups {
    my $self = shift;

    my @group_labels = keys %{$self->scrtoolbar};

    return \@group_labels;
}

=head2 dep_table_header_info

Return the table header configuration data structure bound to the
related Tk::TableMatrix widget.

=cut

sub dep_table_header_info {
    my ( $self, $tm_ds ) = @_;

    return {
        columns       => $self->dep_table_columns($tm_ds),
        selectorcol   => $self->dep_table_selectorcol($tm_ds),
        colstretch    => $self->dep_table_colstretch($tm_ds),
        selectorstyle => $self->dep_table_selectorstyle($tm_ds),
    };
}

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tpda3::Config::Screen

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Stefan Suciu.

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

1;    # End of Tpda3::Config::Screen
