//
//  ListsViewController.h
//  Rdio Alarm
//
//  Created by David Brunow on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ListsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    NSMutableArray *_typesInfo;
    NSMutableArray *_playlistsInfo;
    NSMutableArray *_tracksInfo;
    int _numberOfPlaylistsOwned;
    int _numberOfPlaylistsCollab;
    int _numberOfPlaylistsSubscr;
    NSIndexPath *_selectedPlaylistPath;
    NSString *_selectedPlaylist;
}

@property (nonatomic, retain) NSMutableArray *typesInfo;
@property (nonatomic, retain) NSMutableArray *playlistsInfo;
@property (nonatomic, retain) NSMutableArray *tracksInfo;
@property (nonatomic) int numberOfPlaylistsOwned;
@property (nonatomic) int numberOfPlaylistsCollab;
@property (nonatomic) int numberOfPlaylistsSubscr;
@property (nonatomic) NSIndexPath *selectedPlaylistPath;
@property (nonatomic) NSString *selectedPlaylist;

@end
