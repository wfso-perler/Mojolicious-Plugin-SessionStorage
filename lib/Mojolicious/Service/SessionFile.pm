package Mojolicious::Service::SessionFile;
use Mojo::Base 'Mojolicious::Service';

use Mojo::JSON qw/from_json to_json/;
use Mojo::File 'path';
use Encode qw/decode_utf8 encode_utf8/;
use Mojo::Cache;

has path => "session";
has max_cache_keys => 100;
has cache => sub{Mojo::Cache->new(max_keys => shift->max_cache_keys)};

sub fetch{
  my $self = shift;
  my $session_id = shift;
  
  # 先从缓存中取
  my $session = $self->cache->get($session_id);
  
  # 缓存中没有，则从session文件中取
  unless($session){
    my $home = $self->app->home;
    my $file = $home->child($self->path, $session_id);
    my $file_content = -e $file ? $file->slurp : undef;
    if($file_content){
      $session = from_json(decode_utf8 $file_content);
      # 从session文件中取到后需要设置缓存
      $self->cache->set($session_id => $session);
    }
  }
  
  if($session){
    if($session->{expires} && $session->{expires} > time){
      return $session;
    }
  }
  
  ## 因为cookie也会过期，所以正常情况下是无法执行到下面的代码的
  $self->remove($session_id);
  
  return undef;
}

sub remove{
  my $self = shift;
  my $session_id = shift;
  my $home = $self->app->home;
  $home->child($self->path, $session_id)->remove_tree if(defined $session_id && $session_id ne "");
  # 删除session文件后需要删除缓存
  $self->cache->set($session_id => undef);
}

sub store{
  my $self = shift;
  my $session_id = shift;
  my $session = shift;
  my $home = $self->app->home;
  $home->child($self->path, $session_id)->spurt(encode_utf8(to_json($session)));
  # 存储session文件后需要设置缓存
  $self->cache->set($session_id => $session);
}







1; # End of Mojolicious::Sessions::Storage::File
