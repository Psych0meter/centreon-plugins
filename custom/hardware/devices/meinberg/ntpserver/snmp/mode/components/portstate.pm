package custom::hardware::devices::meinberg::ntpserver::snmp::mode::components::portstate;

use strict;
use warnings;

my %map_states_portstate = (
    0 => 'down',
    1 => 'up',
);

my $mapping = {
    portStateStatus => { oid => '.1.3.6.1.4.1.5597.30.0.7.1.1.2', map => \%map_states_portstate },
};
my $oid_portStateStatus = '.1.3.6.1.4.1.5597.30.0.7.1.1.2';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_portStateStatus };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{portstate} = {name => 'portstates', total => 0, skip => 0};
    return if ($self->check_filter(section => 'portstate'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_portStateStatus}})) {
        next if ($oid !~ /^$mapping->{portStateStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_portStateStatus}, instance => $instance);

        next if ($self->check_filter(section => 'portstate', instance => $instance));

        $self->{components}->{portstate}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Power supply '%s' status is '%s'",
                                                        $instance, $result->{portStateStatus}));
        my $exit = $self->get_severity(section => 'portstate', value => $result->{portStateStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Port '%s' status is '%s'", $instance, $result->{portStateStatus}));
        }
    }
}

1;
