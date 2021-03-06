package # hide the package from PAUSE
    AttributesWithHistory;

use strict;
use warnings;

our $VERSION = '0.05';

use parent 'Class::MOP::Attribute';

# this is for an extra attribute constructor
# option, which is to be able to create a
# way for the class to access the history
AttributesWithHistory->meta->add_attribute('history_accessor' => (
    reader    => 'history_accessor',
    init_arg  => 'history_accessor',
    predicate => 'has_history_accessor',
));

# this is a place to store the actual
# history of the attribute
AttributesWithHistory->meta->add_attribute('_history' => (
    accessor => '_history',
    default  => sub { {} },
));

sub accessor_metaclass { 'AttributesWithHistory::Method::Accessor' }

AttributesWithHistory->meta->add_after_method_modifier('install_accessors' => sub {
    my ($self) = @_;
    # and now add the history accessor
    $self->associated_class->add_method(
        $self->_process_accessors('history_accessor' => $self->history_accessor())
    ) if $self->has_history_accessor();
});

package # hide the package from PAUSE
    AttributesWithHistory::Method::Accessor;

use strict;
use warnings;

our $VERSION = '0.01';

use parent 'Class::MOP::Method::Accessor';

# generate the methods

sub _generate_history_accessor_method {
    my $attr_name = (shift)->associated_attribute->name;
    eval qq{sub {
        unless (ref \$_[0]->meta->get_attribute('$attr_name')->_history()->\{\$_[0]\}) \{
            \$_[0]->meta->get_attribute('$attr_name')->_history()->\{\$_[0]\} = [];
        \}
        \@\{\$_[0]->meta->get_attribute('$attr_name')->_history()->\{\$_[0]\}\};
    }};
}

sub _generate_accessor_method {
    my $attr_name = (shift)->associated_attribute->name;
    eval qq{sub {
        if (scalar(\@_) == 2) {
            unless (ref \$_[0]->meta->get_attribute('$attr_name')->_history()->\{\$_[0]\}) \{
                \$_[0]->meta->get_attribute('$attr_name')->_history()->\{\$_[0]\} = [];
            \}
            push \@\{\$_[0]->meta->get_attribute('$attr_name')->_history()->\{\$_[0]\}\} => \$_[1];
            \$_[0]->{'$attr_name'} = \$_[1];
        }
        \$_[0]->{'$attr_name'};
    }};
}

sub _generate_writer_method {
    my $attr_name = (shift)->associated_attribute->name;
    eval qq{sub {
        unless (ref \$_[0]->meta->get_attribute('$attr_name')->_history()->\{\$_[0]\}) \{
            \$_[0]->meta->get_attribute('$attr_name')->_history()->\{\$_[0]\} = [];
        \}
        push \@\{\$_[0]->meta->get_attribute('$attr_name')->_history()->\{\$_[0]\}\} => \$_[1];
        \$_[0]->{'$attr_name'} = \$_[1];
    }};
}

1;

=pod

=head1 NAME

AttributesWithHistory - An example attribute metaclass which keeps a history of changes

=head1 SYSNOPSIS

  package Foo;

  Foo->meta->add_attribute(AttributesWithHistory->new('foo' => (
      accessor         => 'foo',
      history_accessor => 'get_foo_history',
  )));

  Foo->meta->add_attribute(AttributesWithHistory->new('bar' => (
      reader           => 'get_bar',
      writer           => 'set_bar',
      history_accessor => 'get_bar_history',
  )));

  sub new  {
      my $class = shift;
      $class->meta->new_object(@_);
  }

=head1 DESCRIPTION

This is an example of an attribute metaclass which keeps a
record of all the values it has been assigned. It stores the
history as a field in the attribute meta-object, and will
autogenerate a means of accessing that history for the class
which these attributes are added too.

=head1 AUTHORS

Stevan Little E<lt>stevan@iinteractive.comE<gt>

Yuval Kogman E<lt>nothingmuch@woobling.comE<gt>

=cut
