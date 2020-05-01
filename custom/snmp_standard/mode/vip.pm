package custom::snmp_standard::mode::vip;

use base qw(centreon::plugins::mode);
use centreon::plugins::statefile;

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    $self->{statefile_cache}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_hostname = '.1.3.6.1.2.1.1.5.0';

    my $oids = [$oid_hostname];
    my $result = $self->{snmp}->get_leef(oids => $oids,
                                         nothing_quit => 1);

    my $active_hostname = $result->{$oid_hostname};

    # Cache file
    my $datas = {};
    my $cache_file = 'custom_cache_vip_' . $self->{snmp}->get_hostname();
    $self->{statefile_cache}->read(statefile => $cache_file);

    my $vip = $self->{statefile_cache}->get(name => 'vip');
    ### If Cache file does not exist then create it
    if (!defined($vip)) {
        $datas->{vip} = $active_hostname;
        $self->{statefile_cache}->write(data => $datas);
        print "Creating VIP cache file...\n";
        exit 3;
    }

    # Check current VIP vs Cache VIP
    my $exit;
    if ($vip eq $active_hostname) {
        $exit = 'OK';
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Active node is currently %s", $active_hostname));
    } else {
        $exit = 'CRITICAL';
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("VIP active node has changed. Active node is currently %s (was %s)", $active_hostname, $vip));
        $datas->{vip} = $active_hostname;
        $self->{statefile_cache}->write(data => $datas);
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;
