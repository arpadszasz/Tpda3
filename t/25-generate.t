#
# Tpda3::Generator test script
#

use strict;
use warnings;

use Cwd;
use File::Spec::Functions;
use Test::More tests => 4;

use lib qw( lib ../lib );

use Tpda3::Config;
use Tpda3::Generator;

my $args = {
    cfname => 'test-tk',
    user   => 'user',
    pass   => 'pass',
};

my $c1 = Tpda3::Config->instance($args);
ok( $c1->isa('Tpda3::Config'), 'created Tpda3::Config instance 1' );

ok(my $gen = Tpda3::Generator->new(), 'new Generator');

#--

my $record = [
    {   'data' => {
            name1 => 'Muskehounds',
            name2 => 'Top Cat',
            init2 => 'T.C.',
        },
        'metadata' => {
            'table' => 'v_contracte_imobil',
            'where' => { 'id_contr' => '1' }
        }
    }
];

my $cwd        = Cwd::cwd();
my $model_file = catfile( $cwd, qw{t tex model test.tt} );
my $out_path   = catdir( $cwd, qw{t tex output} );

ok( my $tex_file = $gen->tex_from_template( $record, $model_file, $out_path ),
    'Generate LaTeX from template' );

ok( $gen->pdf_from_latex($tex_file, $out_path), 'Generate PDF from LaTeX' );

# end test
