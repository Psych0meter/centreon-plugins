package custom::network::fortinet::fortigate::snmp::plugin;

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
                         'hardware'               => 'custom::network::fortinet::fortigate::snmp::mode::hardware',
                         'vdom-sessions'          => 'custom::network::fortinet::fortigate::snmp::mode::vdomsessions',
                         );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Fortigate hardware in SNMP.
Requires: centreon::plugins::misc

=cut
