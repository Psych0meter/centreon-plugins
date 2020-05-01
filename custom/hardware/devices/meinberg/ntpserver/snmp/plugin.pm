package custom::hardware::devices::meinberg::ntpserver::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
        my ($class, %options) = @_;
        my $self = $class->SUPER::new(package => __PACKAGE__, %options);
        bless $self, $class;

        # Plugin version
        $self->{version} = '0.1';

        # Plugin modes
        %{$self->{modes}} = (
                'clockleapsecond' 	=> 'custom::hardware::devices::meinberg::ntpserver::snmp::mode::clockleapseconddate',
                'hardware' 			=> 'custom::hardware::devices::meinberg::ntpserver::snmp::mode::hardware',
        );

        return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Plugin to monitor Meinberg NTP Server

=cut
