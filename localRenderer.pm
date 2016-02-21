#!/usr/bin/perl
#------------------------------------------------------------
# localRenderer.pm
#------------------------------------------------------------
# An object that can be registered with the pure perl
# DLNARenderer class as a local renderer.
#
# This object must be created in SHARED MEMORY and
# contain all the necessary member fields:
#
#       id
#       name
#       maxVol
#       canMute
#       canLoud
#       maxBal
#       maxFade
#       maxBass
#       maxMid
#       maxHigh
#
# By convention it should probably also provide
# blank values for the following:
#
#       ip
#       port
#       transportURL
#       controlURL
#
# It must provide the following APIs
#
#    getState()
#
#        Returns undef if renderer is not online or there
#            is a problem with the return value (no status)
#        Otherwise, returns the state of the DLNA renderer
#            PLAYING, TRANSITIONING, ERROR, etc
#
#    getDeviceData()
#
#        If getState() returns 'PLAYING' this method may be called.
#        Returns undef if renderer is not online.
#        Otherwise, returns a $data hash with interesting fields:
#
#			duration
#           reltime
#           vol			- 0 (not supported)
#           mute		- 0 (not supported)
#           uri			- that the renderer used to get the song
#           song_id     - our song_id, if any, by RE from the uri
#           type        - song "type" from RE on the uri, or metadata mime type
#			metadata    - hash containing
#				artist
#				title
#				album
#			    track_num
#  				albumArtURI
#				genre
#				date
#				size
#				pretty_size
#
#    public doCommand(command,args)
#		 'stop'
#        'set_song', song_id
#        'play'
#        'seek', reltime
#        'pause'
#
#------------------------------------------------------------
# IMPLEMENTATION
#------------------------------------------------------------
# The question is how to get this shared memory object to
# communicate with an activeX control.  First try, just
# keep a member variable to it.


package localRenderer;
use strict;
use warnings;
use threads;
use threads::shared;
use Utils;
use Database;
use Library;


BEGIN
{
 	use Exporter qw( import );
	our @EXPORT = qw (
        @lr_command_stack
    );
}

our @lr_command_stack:shared;


sub new
{
    my ($class) = @_;
    my $this = shared_clone({

        # basic state variables
        # managed by mediaPlayerWindow
        # and returned in getState() and getDeviceData()

        state   => 'INIT',      # state of this player
        song_id => '',          # currently playing song, if any
        
        # these are returned in getDeviceData()
        # and are set in the named mediaPlayerWindow method
        
        duration => '',         # in hh::mm:ss format - from onMediaLoaded()
        reltime => '',          # in hh::mm:ss format - from onIdle() PLAYING
        
        # these are the normal DLNAServer member variables
        # that a derived class must provide, and which are
        # returned returned directly to the ui as a hash of
        # this object.
        
        id      => 'local_renderer',
        name    => 'Local Renderer',
        maxVol  => 100,
        canMute => 0,
        canLoud => 0,
        maxBal  => 0,
        maxFade => 0,
        maxBass => 0,
        maxMid  => 0,
        maxHigh => 0,

        # there are unused normal DLNARenderer fields
        # that arebut set for safety
        
        ip      => '',
        port    => '',
        transportURL => '',
        controlURL => '',
    });
    
    bless $this, $class;
    return $this;
    
}


sub getState
{
    my ($this) = @_;
    return $this->{state};
}


sub getDBTrack
{
    my ($id) = @_;
    my $dbh = db_connect();
    my $track = get_track($dbh,$id);
    db_disconnect($dbh);
    return $track;
}


sub getDeviceData()
{
    my ($this) = @_;
    my $song_id = $this->{song_id};
    $song_id ||= '';

    my $track = $song_id ? getDBTrack($song_id) : undef;
    if ($song_id && !$track)
    {
        error("Could not get track($song_id)");
    }
    
    my $metadata = shared_clone({
        artist      => $track ? $track->{ARTIST}    : '',
        title       => $track ? $track->{TITLE}     : '',
        album       => $track ? $track->{ALBUM}     : '',
        track_num   => $track ? $track->{TRACKNUM}  : '',
        albumArtURI => $track ? "http://$server_ip:$server_port/get_art/$track->{PARENT_ID}/folder.jpg" : '',        
        genre       => $track ? $track->{GENRE}     : '',
        date        => $track ? $track->{YEAR}      : '',
        size        => $track ? $track->{SIZE}      : '',
        pretty_size => $track ? pretty_bytes($track->{SIZE}) : '',
    });
    
    my $data = shared_clone({
        song_id     => $song_id,
        duration    => $this->{duration} ? $this->{duration} :
                      $track ? Renderer::secs_to_time($track->{DURATION})
                      : '',
        uri			=> $track ? $track->{FULLPATH}  : '',
        type        => $track ? $track->{TYPE}      : '',
        reltime     => $this->{reltime} ? $this->{reltime} : '',  
        vol			=> 0,
        mute		=> 0,
        metadata    => $metadata,
    });
        
    return $data;
            
}



sub doCommand
    # This code can be runs on a thread from the HTTP Server,
    # so it cannot access the media_player directly.
    #
    # Instead, we push commands commands on a shared stack,
    # and the mediaPlayer object *does* them during an onIdle
    # loop in the mediaPlayerWindow;
{
    my ($this,$command,$arg) = @_;
    $arg ||= '';
    
    display(0,0,"localRenderer::command($command,"._def($arg).")");
    push @lr_command_stack,"$command\t$arg";
    return 1;
}
    



1;