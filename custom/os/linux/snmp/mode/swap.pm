package custom::os::linux::snmp::mode::swap;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"               => { name => 'warning' },
                                  "critical:s"              => { name => 'critical' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_ssSwapIn = '.1.3.6.1.4.1.2021.11.3.0';
    my $oid_ssSwapOut = '.1.3.6.1.4.1.2021.11.4.0';
    
    my $oids = [$oid_ssSwapIn, $oid_ssSwapOut];
    my $result = $self->{snmp}->get_leef(oids => $oids, 
                                         nothing_quit => 1);

    my $swapin = $result->{$oid_ssSwapIn} * 1024;
    my $swapout = $result->{$oid_ssSwapOut} * 1024;

    my ($swapin_value, $swapin_unit) = $self->{perfdata}->change_bytes(value => $swapin);
    my ($swapout_value, $swapout_unit) = $self->{perfdata}->change_bytes(value => $swapout);

    my $exit = "OK";
    
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Swap In : %s, Swap Out : %s", 
												$swapin_value . " " . $swapin_unit,
                                                $swapout_value . " " . $swapout_unit,));
   
    $self->{output}->perfdata_add(label => "swap_in", unit => 'B',
                                  value => $swapin,
                                  min => 0); 

    $self->{output}->perfdata_add(label => "swap_out", unit => 'B',
                                  value => $swapout,
                                  min => 0);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check physical memory (UCD-SNMP-MIB).

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut
