package custom::hardware::devices::meinberg::ntpserver::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_overload_check_section_option} = '^(fan|psu|portstate|ntpcurrentstate|clockstate)$';

    $self->{cb_hook2} = 'snmp_execute';

    $self->{thresholds} = {
        fan => [
            ['yes', 'CRITICAL'],
            ['notAvailable', 'UNKNOWN'],
            ['no', 'OK'],
        ],
        psu => [
            ['up', 'OK'],
            ['down', 'CRITICAL'],
            ['.*', 'UNKNOWN'],
        ],
        portstate => [
            ['up', 'OK'],
            ['down', 'CRITICAL'],
            ['.*', 'CRITICAL'],
        ],
        ntpcurrentstate => [
            ['synchronized', 'OK'],
            ['.*', 'CRITICAL'],
        ],
        clockstate => [
            ['synchronized', 'OK'],
            ['.*', 'CRITICAL'],
        ],
    };

    $self->{components_path} = 'custom::hardware::devices::meinberg::ntpserver::snmp::mode::components';
    $self->{components_module} = ['fan', 'psu', 'portstate', 'ntpcurrentstate', 'clockstate'];
}

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_performance => 1, no_absent => 1);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                });

    return $self;
}

1;

__END__

=head1 MODE

Check hardware (fans, power supplies, portstate, ntpcurrentstate).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'psu', 'fan', 'portstate', 'ntpcurrentstate'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=fan --filter=psu)
Can also exclude specific instance: --filter=psu,1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='fan,CRITICAL,^(?!(false)$)'

=back

=cut
