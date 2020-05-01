package custom::hardware::devices::meinberg::ntpserver::snmp::mode::components::clockstate;

use strict;
use warnings;

my %map_states_clockstate = (
	0 => 'notAvailable',
    2 => 'notSynchronized',
    1 => 'synchronized',
);

my $mapping = {
    ClockState => { oid => '.1.3.6.1.4.1.5597.30.0.1.2.1.4', map => \%map_states_clockstate },
};
my $oid_ClockState = '.1.3.6.1.4.1.5597.30.0.1.2.1.4';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_ClockState };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking NTP Current State");
    $self->{components}->{clockstate} = {name => 'clockstates', total => 0, skip => 0};
    return if ($self->check_filter(section => 'clockstate'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_ClockState}})) {
        next if ($oid !~ /^$mapping->{ClockState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_ClockState}, instance => $instance);

        next if ($self->check_filter(section => 'clockstate', instance => $instance));

        $self->{components}->{clockstate}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("ClockState '%s' status is '%s'",
                                                        $instance, $result->{ClockState}));
        my $exit = $self->get_severity(section => 'clockstate', value => $result->{ClockState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("ClockState '%s' status is '%s'", $instance, $result->{ClockState}));
        }
    }
}

1;
