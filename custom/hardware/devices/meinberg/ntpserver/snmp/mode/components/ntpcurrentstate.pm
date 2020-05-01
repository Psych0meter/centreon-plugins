package custom::hardware::devices::meinberg::ntpserver::snmp::mode::components::ntpcurrentstate;

use strict;
use warnings;

my %map_states_ntpcurrentstate = (
    0 => 'notAvailable',
    1 => 'notSynchronized',
    2 => 'synchronized',
);

my $mapping = {
    NTPCurrentStatus => { oid => '.1.3.6.1.4.1.5597.30.0.2.1', map => \%map_states_ntpcurrentstate },
};
my $oid_NTPCurrentStatus = '.1.3.6.1.4.1.5597.30.0.2.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_NTPCurrentStatus };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking NTP Current State");
    $self->{components}->{ntpcurrentstate} = {name => 'ntpcurrentstates', total => 0, skip => 0};
    return if ($self->check_filter(section => 'ntpcurrentstate'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_NTPCurrentStatus}})) {
        next if ($oid !~ /^$mapping->{NTPCurrentStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_NTPCurrentStatus}, instance => $instance);

        next if ($self->check_filter(section => 'ntpcurrentstate', instance => $instance));

        $self->{components}->{ntpcurrentstate}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("NTP CurrentState '%s' status is '%s'",
                                                        $instance, $result->{NTPCurrentStatus}));
        my $exit = $self->get_severity(section => 'ntpcurrentstate', value => $result->{NTPCurrentStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("NTP CurrentState '%s' status is '%s'", $instance, $result->{NTPCurrentStatus}));
        }
    }
}

1;
