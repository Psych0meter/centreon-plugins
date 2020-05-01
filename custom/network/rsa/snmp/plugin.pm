package custom::network::rsa::snmp::plugin;

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
                         'replication'	=> 'custom::network::rsa::snmp::mode::replication',
                         );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

RSA plugin.
Requires: IO::Socket

=cut
