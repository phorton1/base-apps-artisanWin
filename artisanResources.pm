#!/usr/bin/perl
#-------------------------------------------------------------
# rtisanResources.pm
#-------------------------------------------------------------
# All appBase applications may provide resources that contain the
# app_title, main_menu, command_data, notebook_data, and so on.
# Derived classes should merge their values into the base
# class $resources member.

package artisanResources;
use strict;
use warnings;
use MyWX::Resources;
use Wx qw(wxAUI_NB_BOTTOM);
use Wx::AUI;


BEGIN
{
 	use Exporter qw( import );
	our @EXPORT = qw (
        $resources
		$COMMAND_TEST
        $WINDOW_MEDIA_PLAYER

		$WINDOW_LIBRARY
		$WINDOW_EXPLORER
		$WINDOW_STATIONS
		$WINDOW_SEARCH
		$WINDOW_SONGLIST
		$WINDOW_NOW_PLAYING
		$BEGIN_PANE_RANGE
		$END_PANE_RANGE
		
        $VIEW_OUTPUT_NB
    );
}


our (
	$COMMAND_TEST,
    $WINDOW_MEDIA_PLAYER,
	
	# ranged windows
	
	$WINDOW_LIBRARY,
	$WINDOW_EXPLORER,
	$WINDOW_STATIONS,
	$WINDOW_SEARCH,
	$WINDOW_SONGLIST,
	$WINDOW_NOW_PLAYING,
	
	# end (system pane command)
	
    $VIEW_OUTPUT_NB )= (10000..11000);


# RANGED RESOURCES

our $BEGIN_PANE_RANGE = $WINDOW_LIBRARY;
our $END_PANE_RANGE = $WINDOW_NOW_PLAYING;


# Command data for this application.
# Notice the merging that takes place

my %command_data = (%{$resources->{command_data}},

	$WINDOW_LIBRARY			=> ['&Library',		'Library Administrator Window'	],
	$WINDOW_EXPLORER		=> ['&Explorer',	'Explorer and modify the library'	],
	$WINDOW_STATIONS		=> ['S&tations',	'Manage Stations'	],
	$WINDOW_SEARCH			=> ['&Search',		'Search for songs by Artist, Title, etc'	],
	$WINDOW_SONGLIST		=> ['Song&list',	'View and Modify List of Songs'	],
	$WINDOW_NOW_PLAYING		=> ['Now &Playing',	'The Now-Playing Window'	],
	
	$COMMAND_TEST 			=> ['Test','Test'],
    $WINDOW_MEDIA_PLAYER 	=> ['Media Player',    'Media Player Window' ],
	
    $VIEW_OUTPUT_NB     	=> ['Output Notebook','Open the output notebook (the output monitor)' ],
);

# Pane data for lookup of notebook by window_id

my %pane_data = (
	$WINDOW_LIBRARY			=> ['library',		'content'	],
	$WINDOW_EXPLORER		=> ['explorer',		'content'	],
	$WINDOW_STATIONS		=> ['stations',		'content'	],
	$WINDOW_SEARCH			=> ['search',		'content'	],
	$WINDOW_SONGLIST		=> ['songlist',		'content'	],
	$WINDOW_NOW_PLAYING		=> ['now_playing',	'content'	],

	$WINDOW_MEDIA_PLAYER	=> ['media_player',	'content'	],
	$ID_MONITOR         	=> ['Monitor',		'output'	],
);



# Notebook data includes an array "in order",
# and a lookup by id for notebooks to be opened by
# command id's

my %notebook_data = (
	content  => {
        name => 'content',
        row => 1,
        pos => 1,
        direction => '',
        title => 'Content Notebook' },
	'output' => {
        command_id => $VIEW_OUTPUT_NB,
        name => 'output',
        row => 1,
        pos => 2,
        direction => 'bottom',
        title => 'Output Notebook',
        style => wxAUI_NB_BOTTOM }
);


my @notebooks = (
    $notebook_data{content},
    $notebook_data{output} );


my %notebook_name = (
	$VIEW_OUTPUT_NB		 => 'output'
);


#-------------------------------------
# Menus
#-------------------------------------

my @main_menu = (
    'view_menu,&View',
	'windows_menu,&Windows',
    'test_menu,&Test' );


my @windows_menu = (
	$WINDOW_LIBRARY,
	$WINDOW_EXPLORER,
	$WINDOW_STATIONS,
	$WINDOW_SEARCH,
	$WINDOW_SONGLIST,
	$WINDOW_NOW_PLAYING,
);


my @test_menu = (
	$WINDOW_MEDIA_PLAYER,
	$COMMAND_TEST
);


#-----------------------------------------
# Merge and reset the single public object
#-----------------------------------------

$resources = { %$resources,
    app_title       => 'Artisan',

    command_data    => \%command_data,
    notebooks       => \@notebooks,
    notebook_data   => \%notebook_data,
    notebook_name   => \%notebook_name,
    pane_data       => \%pane_data,

    main_menu       => \@main_menu,
    windows_menu    => \@windows_menu,
    test_menu    	=> \@test_menu,

};


1;
