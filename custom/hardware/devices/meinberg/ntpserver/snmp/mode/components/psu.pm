package custom::hardware::devices::meinberg::ntpserver::snmp::mode::components::psu;

use strict;
use warnings;

my %map_states_psu = (
    0 => 'notAvailable',
    1 => 'down',
    2 => 'up',
);

my $mapping = {
    powerSupplyStatus => { oid => '.1.3.6.1.4.1.5597.30.0.5.0.2.1.2', map => \%map_states_psu },
};
my $oid_powerSupplyStatus = '.1.3.6.1.4.1.5597.30.0.5.0.2.1.2';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_powerSupplyStatus };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_powerSupplyStatus}})) {
        next if ($oid !~ /^$mapping->{powerSupplyStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_powerSupplyStatus}, instance => $instance);

        next if ($self->check_filter(section => 'psu', instance => $instance));

        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Power supply '%s' status is '%s'",
                                                        $instance, $result->{powerSupplyStatus}));
        my $exit = $self->get_severity(section => 'psu', value => $result->{powerSupplyStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Power supply '%s' status is '%s'", $instance, $result->{powerSupplyStatus}));
        }
    }
}

1;
