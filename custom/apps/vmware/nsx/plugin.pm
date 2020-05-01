package custom::apps::vmware::nsx::plugin;

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
                         'component'        => 'custom::apps::vmware::nsx::mode::component',
                         'cpu'              => 'custom::apps::vmware::nsx::mode::cpu',
                         'edge'             => 'custom::apps::vmware::nsx::mode::edge',
                         'ntp'              => 'custom::apps::vmware::nsx::mode::ntp',
                         'storage'          => 'custom::apps::vmware::nsx::mode::storage',
                         'uptime'           => 'custom::apps::vmware::nsx::mode::uptime',
                         'version'          => 'custom::apps::vmware::nsx::mode::version',
                         );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check VMWare NSX
Requires : XML::Simple

=cut
