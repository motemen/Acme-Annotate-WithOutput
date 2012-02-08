use strict;
use Test::More tests => 2;
use File::Temp;

my $IN = <<'__IN__';
use strict;
use Acme::Annotate::WithOutput;

print 1 + 2, "\n";
print "foo\nbar";
__IN__

my $OUT = <<'__OUT__';
use strict;
# use Acme::Annotate::WithOutput;

print 1 + 2, "\n"; # => 3
print "foo\nbar";
# foo
# bar
__OUT__

my $temp = File::Temp->new;
print $temp $IN;
close $temp;

open (my $pipe, '-|') || exec $^X, ( map "-I$_", @INC ), $temp->filename;
is do { local $/; <$pipe> }, "3\nfoo\nbar";

open my $fh, '<', $temp->filename;

is do { local $/; <$fh> }, $OUT;
