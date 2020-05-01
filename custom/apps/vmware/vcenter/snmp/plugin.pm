package custom::apps::vmware::vcenter::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    # $options->{options} = options object

    $self->{version} = '0.1';
    %{$self->{modes}} = (
							'memory'	=> 'custom::apps::vmware::vcenter::snmp::mode::memory',
                         );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check VMWare vCenter memory.

=cut
