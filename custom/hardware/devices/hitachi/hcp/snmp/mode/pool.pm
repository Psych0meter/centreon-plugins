package custom::hardware::devices::hitachi::hcp::snmp::mode::pool;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {});
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_pool_status = '.1.3.6.1.4.1.116.5.46.2.3.1.4.1';

    my $result = $self->{snmp}->get_leef(oids => [$oid_pool_status],
                                         nothing_quit => 1);

    my $exit;

    if ($result->{$oid_pool_status} eq 0) {
	$exit = "OK";
    } elsif ($result->{$oid_pool_status} eq 1) {
	$exit = "WARNING";
    } else {
	$exit = "CRITICAL";
    }

    my $output = "Pool is $exit";

    $self->{output}->output_add(	severity => $exit,
					short_msg => $output);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__
