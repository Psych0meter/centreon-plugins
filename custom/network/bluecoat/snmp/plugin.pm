package custom::network::bluecoat::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    # $options->{options} = options object

    $self->{version} = '1.0';
    %{$self->{modes}} = (
                         'CAS-cpu1'	=> 'custom::network::bluecoat::snmp::mode::cpu1_CAS',
                         );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Bluecoat hardware with SNMP.

=cut
