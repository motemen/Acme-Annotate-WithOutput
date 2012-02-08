package Acme::Annotate::WithOutput;
use strict;
use warnings;
use Symbol ();
use Scalar::Util qw(refaddr);

our $VERSION = '0.01';

our $Prefix = '=> ';
our %Instances;

sub import {
    my ($class, %args) = @_;

    my (undef, $file, undef) = caller;

    my $self = $class->new(
        handle => \*STDOUT,
        file   => $file,
        prefix => $Prefix,
        %args,
    );
    $self->setup;
}

sub new {
    my ($class, %args) = @_;
    $args{results} = {};
    return bless \%args, $class;
}

sub setup {
    my $self = shift;

    my $symbol = Symbol::gensym();
    my $handle = tie *$symbol, 'Acme::Annotate::WithOutput::Handle';

    open $self->{original_handle}, '>&', $self->{handle} or die $!;

    *{$self->{handle}} = $symbol;

    $Instances{ refaddr $handle } = $self;

    return $self;
}

sub from_handle {
    my ($class, $handle) = @_;
    return $Instances{ refaddr $handle };
}

sub write {
    my $self = shift;
    my $class = ref $self;

    local $/ = "\n";

    my @in = do {
        open my $in, '<', $self->{file} or die $!;
        <$in>;
    };

    my @out;
    for my $i (0 .. $#in) {
        $in[$i] =~ s/^(use \Q$class\E\b)/# $1/;

        my @results = split /\n/, join '', @{ $self->{results}->{$i+1} || [] };
        if (@results == 1) {
            $in[$i] =~ s/$/ # $self->{prefix}$results[0]/;
            push @out, $in[$i];
        } else {
            push @out, $in[$i], map { "# $_\n" } @results;
        }
    }

    open my $out, '>', $self->{file};
    print $out join '', @out;

    $self->{wrote}++;
}

sub DESTROY {
    my $self = shift;
    $self->write unless $self->{wrote};
}

package
    Acme::Annotate::WithOutput::Handle;
use Tie::Handle;
use parent -norequire => 'Tie::StdHandle';

sub PRINT {
    my $self = shift;

    my $aaw = Acme::Annotate::WithOutput->from_handle($self);
    print { $aaw->{original_handle} } @_;

    my $depth = 0;
    while (my ($pkg, $file, $line) = caller($depth++)) {
        if ($file eq $aaw->{file}) {
            push @{ $aaw->{results}->{$line} ||= [] }, @_;
            return;
        }
    }
}

sub PRINTF {
    my $self = shift;
    my $format = shift;
    @_ = ( $self, sprintf $format, @_ );
    goto \&PRINT;
}

1;

__END__

=head1 NAME

Acme::Annotate::WithOutput - embed output to your script after execution

=head1 SYNOPSIS

write your script:

  use Acme::Annotate::WithOutput;
  use Data::Dumper;
  
  print 1 + 2;
  print Dumper { a => 1 };

after running, comments are added to the script like:

  # use Acme::Annotate::WithOutput;
  use Data::Dumper;
  
  print 1 + 2; # => 3;
  print Dumper { a => 1 };
  # $VAR1 = {
  #           'a' => 1
  #         };

=head1 DESCRIPTION

Acme::Annotate::WithOutput captures script outputs and
embeds the outputs to the script.

=head1 OPTIONS

  use Acme::Annotate::WithOutput;

is equivalent to

  use Acme::Annotate::WithOutput handle => \*STDOUT, file => __FILE__, prefix => '=> ';

=head1 AUTHOR

motemen E<lt>motemen@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
