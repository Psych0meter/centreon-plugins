package custom::snmp_standard::mode::psc_memory;

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

    my $oid_memTotalReal = '.1.3.6.1.2.1.25.2.3.1.5.14';
    my $oid_memUsedReal = '.1.3.6.1.2.1.25.2.3.1.6.14';
#    my $oid_memBuffer    = '.1.3.6.1.2.1.25.2.3.1.6.6';
#    my $oid_memCached    = '.1.3.6.1.2.1.25.2.3.1.6.7';
    
#    my $oids = [$oid_memTotalReal, $oid_memUsedReal,$oid_memBuffer, $oid_memCached];
    my $oids = [$oid_memTotalReal, $oid_memUsedReal];
    my $result = $self->{snmp}->get_leef(oids => $oids, 
                                         nothing_quit => 1);

#    my $cached_used = $result->{$oid_memCached} * 1024;
#    my $buffer_used = $result->{$oid_memBuffer} * 1024;
    my $physical_used = $result->{$oid_memUsedReal} * 1024;
#    my $nobuf_used = $physical_used - $buffer_used - $cached_used;
    my $nobuf_used = $physical_used;

    my $total_size = $result->{$oid_memTotalReal} * 1024;
    
    my $prct_used = $nobuf_used * 100 / $total_size;
    my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $total_size);
    my ($nobuf_value, $nobuf_unit) = $self->{perfdata}->change_bytes(value => $nobuf_used);
#    my ($buffer_value, $buffer_unit) = $self->{perfdata}->change_bytes(value => $buffer_used);
#    my ($cached_value, $cached_unit) = $self->{perfdata}->change_bytes(value => $cached_used);
    
    $self->{output}->output_add(severity => $exit,
#                                short_msg => sprintf("Ram Total: %s, Used: %s (%.2f%%), Buffer: %s, Cached: %s",
                                short_msg => sprintf("Ram Total: %s, Used: %s (%.2f%%)",                                
                                            $total_value . " " . $total_unit,
                                            $nobuf_value . " " . $nobuf_unit, $prct_used,
#                                            $buffer_value . " " . $buffer_unit,
#                                            $cached_value . " " . $cached_unit,));
                                            ));
   
    $self->{output}->perfdata_add(label => "physical_memory", unit => 'B',
                                  value => $total_size,
                                  min => 0); 
#    $self->{output}->perfdata_add(label => "cached_memory", unit => 'B',
#                                  value => $cached_used,
#                                  min => 0);
#    $self->{output}->perfdata_add(label => "buffer_memory", unit => 'B',
#                                  value => $buffer_used,
#                                  min => 0);
    $self->{output}->perfdata_add(label => "used_memory", unit => 'B',
                                  value => $nobuf_used,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $total_size, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $total_size, cast_int => 1),
                                  min => 0, max => $total_size);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

