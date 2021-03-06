package # hide from PAUSE
    C3MethodDispatchOrder;

use strict;
use warnings;

use Carp 'confess';
use Algorithm::C3;

our $VERSION = '0.03';

use parent 'Class::MOP::Class';

my $_find_method = sub {
    my ($class, $method) = @_;
    foreach my $super ($class->class_precedence_list) {
        return $super->meta->get_method($method)
            if $super->meta->has_method($method);
    }
};

C3MethodDispatchOrder->meta->add_around_method_modifier('initialize' => sub {
    my $cont = shift;
    my $meta = $cont->(@_);

    # we need to look at $AUTOLOAD in the package where the coderef belongs
    # if subname works, then it'll be where this AUTOLOAD method was installed
    # otherwise, it'll be $C3MethodDispatchOrder::AUTOLOAD. get_code_info
    # tells us where AUTOLOAD will look
    my $autoload;
    $autoload = sub {
        my ($package) = Class::MOP::get_code_info($autoload);
        my $label = ${ $package->meta->get_package_symbol('$AUTOLOAD') };
        my $method_name = (split /\:\:/ => $label)[-1];
        my $method = $_find_method->($_[0]->meta, $method_name);
        (defined $method) || confess "Method ($method_name) not found";
        goto &$method;
    };

    $meta->add_method('AUTOLOAD' => $autoload)
        unless $meta->has_method('AUTOLOAD');

    $meta->add_method('can' => sub {
        $_find_method->($_[0]->meta, $_[1]);
    }) unless $meta->has_method('can');

    return $meta;
});

sub superclasses {
    my $self = shift;

    $self->add_package_symbol('@SUPERS' => [])
        unless $self->has_package_symbol('@SUPERS');

    if (@_) {
        my @supers = @_;
        @{$self->get_package_symbol('@SUPERS')} = @supers;
    }
    @{$self->get_package_symbol('@SUPERS')};
}

sub class_precedence_list {
    my $self = shift;
    return map {
        $_->name;
    } Algorithm::C3::merge($self, sub {
        my $class = shift;
        map { $_->meta } $class->superclasses;
    });
}

1;

__END__

=pod

=head1 NAME

C3MethodDispatchOrder - An example attribute metaclass for changing to C3 method dispatch order

=head1 SYNOPSIS

  # a classic diamond inheritence graph
  #
  #    <A>
  #   /   \
  # <B>   <C>
  #   \   /
  #    <D>

  package A;
  use metaclass 'C3MethodDispatchOrder';

  sub hello { return "Hello from A" }

  package B;
  use metaclass 'C3MethodDispatchOrder';
  B->meta->superclasses('A');

  package C;
  use metaclass 'C3MethodDispatchOrder';
  C->meta->superclasses('A');

  sub hello { return "Hello from C" }

  package D;
  use metaclass 'C3MethodDispatchOrder';
  D->meta->superclasses('B', 'C');

  print join ", " => D->meta->class_precedence_list; # prints C3 order D, B, C, A

  # later in other code ...

  print D->hello; # print 'Hello from C' instead of the normal 'Hello from A'

=head1 DESCRIPTION

This is an example of how you could change the method dispatch order of a
class using L<Class::MOP>. Using the L<Algorithm::C3> module, this repleces
the normal depth-first left-to-right perl dispatch order with the C3 method
dispatch order (see the L<Algorithm::C3> or L<Class::C3> docs for more
information about this).

This example could be used as a template for other method dispatch orders
as well, all that is required is to write a the C<class_precedence_list> method
which will return a linearized list of classes to dispatch along.

=head1 AUTHORS

Stevan Little E<lt>stevan@iinteractive.comE<gt>

Yuval Kogman E<lt>nothingmuch@woobling.comE<gt>

=cut
