package Tpda3::Generator;

use strict;
use warnings;

use IPC::Run3 qw( run3 );
use File::Spec::Functions;
use File::Basename;
use Template;

use Log::Log4perl qw(get_logger :levels);
use Try::Tiny;

use Tpda3::Config;

=head1 NAME

Tpda3::Generator - The Generator

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

   use Tpda3::Generator;

   my $gen = Tpda3::Generator->new();

   my $tex_file = $gen->tex_from_template($record, $model, $output_path);

   my $pdf_file = $gen->pdf_from_latex($tex_file);

=head1 METHODS

=head2 new

Constructor method.

=cut

sub new {

    my $type = shift;

    my $self = {
        _cfg => Tpda3::Config->instance(),
        _log => get_logger(),
    };

    bless( $self, $type );

    return $self;
}

=head2 _log

Return log instance variable.

=cut

sub _log {
    my $self = shift;

    return $self->{_log};
}

=head2 _cfg

Return config instance variable.

=cut

sub _cfg {
    my $self = shift;

    return $self->{_cfg};
}

=head2 tex_from_template

Generate LaTeX source from TT template.

=cut

sub tex_from_template {
    my ($self, $record, $model_file, $output_path) = @_;

    my ($model, $path, $ext) = fileparse( $model_file, qr/\Q.tt\E/ );

    my $file_out = "$model.tex";

    $self->_log->info("Generating '$model.tex' from '$model.tt'");

    my $cnt = unlink $file_out;
    if ($cnt == 1) {
        $self->_log->info("Removed temporary file: $file_out");
    }

    my $tt = Template->new({
        ENCODING     => 'utf8',
        INCLUDE_PATH => './',
        OUTPUT_PATH  => $output_path,
        ABSOLUTE     => 1,
        RELATIVE     => 1,
        PLUGIN_BASE  => 'Tpda3::Template::Plugin',
    });

    my $rec = $record->[0]{data};    # only the data

    #- Cleanup values and prepare for LaTeX, (translate '&' in '\&')

    foreach my $field ( keys %{$rec} ) {
        if (defined $rec->{$field}) {
            $rec->{$field} =~ s/^\s+//;
            $rec->{$field} =~ s/\s+$//;
            $rec->{$field} =~ s/[\n\r]/ /;
            $rec->{$field} =~ s/,(\w)/, $1/;
            $rec->{$field} =~ s/&/\\&/;
        }
    }

    try {
        $tt->process(
            $model_file, { r => $rec },
            $file_out, binmode => ':utf8'
        )
            || die $tt->error(), "\n";
    }
    catch {
        $self->_log->error('TT Error: ' . $tt->error )
            or print STDERR 'TT Error: ', $tt->error, "\n";
        return;
    };

    return catfile($output_path, "$model.tex");
}

=head2 pdf_from_latex

Generate PDF from LaTeX source using L<pdflatex>. On success
L<pdflatex> returns 0.

=cut

sub pdf_from_latex {
    my ($self, $tex_file) = @_;

    $self->_log->info("Generating PDF from '$tex_file'");

    my $pdflatex_exe = $self->_cfg->cfextapps->{pdflatex}{exe_path};
    my $pdflatex_opt = $self->_cfg->cfextapps->{pdflatex}{options};
    my $docspath     = $self->_cfg->cfrun->{docspath};

    my ($name, $path, $ext) = fileparse( $tex_file, qr/\Q.tex\E/ );
    my $output_pdf = catfile($docspath, "$name.pdf");
    my $cnt = unlink $output_pdf;
    if ($cnt == 1) {
        $self->_log->info("Removed temporary file: $output_pdf");
    }

    $pdflatex_opt .= q{ -output-directory=} . qq{"$docspath"};

    my $cmd = qq{"$pdflatex_exe" $pdflatex_opt "$tex_file"};

    run3 $cmd, undef, \undef;

    my $error_str;
    if ($? == -1) {
        $error_str = "failed to execute: $!";
    }
    elsif ($? & 127) {
        $error_str = sprintf "child died with signal %d, %s coredump\n",
            ($? & 127),  ($? & 128) ? 'with' : 'without';
    }

    if ($error_str) {
        $self->_log->debug("CMD: $cmd");
        $self->_log->debug("EE: $error_str");
        return;
    }

    return $output_pdf;
}

=head1 AUTHOR

Stefan Suciu, C<< <stefansbv at users.sourceforge.net> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tpda3::Generator

=head1 ACKNOWLEDGEMENTS

PerlMonks: ikegami (http://www.perlmonks.org/index.pl?node_id=766502)

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Stefan Suciu.

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

1;    # End of Tpda3::Generator