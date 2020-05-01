package custom::network::stonesoft::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    %{$self->{modes}} = (
                         'cluster-state'	=> 'custom::network::stonesoft::snmp::mode::clusterstate',
                         );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Stonesoft firewall with SNMP.

=cut

