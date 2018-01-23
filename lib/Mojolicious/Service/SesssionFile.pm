package Mojolicious::Service::SesssionFile;
use Mojo::Base 'Mojolicious::Service';

use Mojo::JSON qw/from_json to_json/;
use Mojo::File 'path';
use Mojo::ByteStream 'b';

has path => "session";

sub fetch{
  my $self = shift;
  my $session_id = shift;
  my $home = $self->app->home;
  my $file = $home->child($self->path, $session_id);
  my $file_content = -e $file ? $file->slurp : undef;
  if($file_content){
    my $session = from_json($file_content);
    if($session){
      if($session->{expires} && $session->{expires} > time){
        return $session;
      }
    }
    ## 因为cookie也会过期，所以正常情况下是无法执行到下面的代码的
    $self->remove($session_id);
  }
  return undef;
}

sub remove{
  my $self = shift;
  my $session_id = shift;
  my $home = $self->app->home;
  $home->child($self->path, $session_id)->remove_tree;
}

sub store{
  my $self = shift;
  my $session_id = shift;
  my $session = shift;
  my $home = $self->app->home;
  $home->child($self->path, $session_id)->spurt(b(to_json($session))->encode("utf8"));
}







1; # End of Mojolicious::Sessions::Storage::File
