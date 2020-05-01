package custom::network::f5::bigip::snmp::mode::request;

use base qw(centreon::plugins::mode);
use IO::Socket;

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};

    # OIDs
    my $oid_total_requests = '.1.3.6.1.4.1.3375.2.1.1.2.4.7.0';
    my $oid_posts = '.1.3.6.1.4.1.3375.2.1.1.2.4.9.0';
    my $oid_gets = '.1.3.6.1.4.1.3375.2.1.1.2.4.8.0';

    # Get requests
    my $result = $self->{snmp}->get_table(oid => '.1.3.6.1.4.1.3375.2.1.1.2.4');

    my $total_requests = $result->{$oid_total_requests};
    my $posts = $result->{$oid_posts};
    my $gets = $result->{$oid_gets};

    # Cache
    my $last_total = 0;
    my $last_post  = 0;
    my $last_get   = 0;
    my $last_check_time = 0;
    my $flg_created = 0;

    my $file_path = "/var/lib/centreon/centplugins/custom_cache_f5_requests_".$self->{option_results}->{host};

    if (-e $file_path) {
        open(FILE,"<".$file_path);
        while(my $row = <FILE>){
                my @last_values = split(":",$row);
                $last_check_time = $last_values[0];
                $last_total = $last_values[1];
                $last_post  = $last_values[2];
                $last_get   = $last_values[3];
                $flg_created = 1;
        }
        close(FILE);
    } else {
        $flg_created = 0;
    }

    my $update_time = time();

    unless (open(FILE,">".$file_path)){
        $self->{output}->add_option_msg(short_msg => "Check mod for temporary file : ".$file_path." !");
        $self->{output}->option_exit();
    } 

    print FILE "$update_time:$total_requests:$posts:$gets";

    close(FILE);

    if ($flg_created == 0){
        $self->{output}->output_add(        severity => 'OK',
                                            short_msg => "First execution : Buffer in creation.... ");
        $self->{output}->display();
        $self->{output}->option_exit();
    }

    my $display_total = $total_requests - $last_total;
    my $display_post  = $posts - $last_post;
    my $display_get = $gets - $last_get;

    # Print output
    $self->{output}->output_add(severity => 'OK', 
				short_msg => sprintf ("Gets: %s, Posts: %s, Total: %s", $display_get, $display_post, $display_total));

    $self->{output}->perfdata_add(label => 'get',
                                  value => $display_get);

    $self->{output}->perfdata_add(label => 'post',
                                  value => $display_post);

    $self->{output}->perfdata_add(label => 'total',
                                  value => $display_total);


    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

