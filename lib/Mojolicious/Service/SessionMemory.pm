package Mojolicious::Service::SessionMemory;
use Mojo::Base 'Mojolicious::Service';

has storage => sub{{}};


sub fetch{
  my $self = shift;
  my $session_id = shift;
  my $session = $self->storage->{$session_id};
  if($session){
    if($session->{expires} && $session->{expires} > time){
      return $session;
    }
    ## 因为cookie也会过期，所以正常情况下是无法执行到下面的代码的
    $self->remove($session_id);
  }
  return undef;
}

sub remove{
  my $self = shift;
  my $session_id = shift;
  delete $self->storage->{$session_id} if(defined $session_id && $session_id ne "");
}

sub store{
  my $self = shift;
  my $session_id = shift;
  my $session = shift;
  $self->storage->{$session_id} = $session;
}




1; # End of Mojolicious::Sessions::Storage::Memory
