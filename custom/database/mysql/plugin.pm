package custom::database::mysql::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_sql);

sub new {
    my ($class, %options) = @_;
    
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    # $options->{options} = options object

    $self->{version} = '0.1';
    %{$self->{modes}} = (
							'replication-master-master'    => 'custom::database::mysql::mode::replicationmastermaster',
							'sql-value'                    => 'custom::centreon::common::protocols::sql::mode::sql',
                         );
    $self->{sql_modes}{mysqlcmd} = 'database::mysql::mysqlcmd';

    return $self;
}

sub init {
    my ($self, %options) = @_;

    $self->{options}->add_options(
                                   arguments => {
                                                'host:s@'  => { name => 'db_host' },
                                                'port:s@'  => { name => 'db_port' },
                                                'socket:s@'  => { name => 'db_socket' },
                                                }
                                  );
    $self->{options}->parse_options();
    my $options_result = $self->{options}->get_options();
    $self->{options}->clean();

    if (defined($options_result->{db_host})) {
        @{$self->{sqldefault}->{dbi}} = ();
        @{$self->{sqldefault}->{mysqlcmd}} = ();
        for (my $i = 0; $i < scalar(@{$options_result->{db_host}}); $i++) {
            $self->{sqldefault}->{dbi}[$i] = { data_source => 'mysql:host=' . $options_result->{db_host}[$i] };
            $self->{sqldefault}->{mysqlcmd}[$i] = { host => $options_result->{db_host}[$i] };
            if (defined($options_result->{db_port}[$i])) {
                $self->{sqldefault}->{dbi}[$i]->{data_source} .= ';port=' . $options_result->{db_port}[$i];
                $self->{sqldefault}->{mysqlcmd}[$i]->{port} = $options_result->{db_port}[$i];
            }
            if (defined($options_result->{db_socket}[$i])) {
                $self->{sqldefault}->{dbi}[$i]->{data_source} .= ';mysql_socket=' . $options_result->{db_socket}[$i];
                $self->{sqldefault}->{mysqlcmd}[$i]->{socket} = $options_result->{db_socket}[$i];
            }
        }
    }

    $self->SUPER::init(%options);    
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check MySQL Server.
Requires : custom::centreon::common::protocols::sql::mode::sql

=over 8

You can use following options or options from 'sqlmode' directly.

=item B<--host>

Hostname to query.

=item B<--port>

Database Server Port.

=back

=cut
