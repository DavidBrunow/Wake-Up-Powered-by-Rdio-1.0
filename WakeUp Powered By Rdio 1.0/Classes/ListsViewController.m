//
//  ListsViewController.m
//  Rdio Alarm
//
//  Created by David Brunow on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ListsViewController.h"
#import "AppDelegate.h"

@interface ListsViewController ()

@end

@implementation ListsViewController

@synthesize typesInfo = _typesInfo, playlistsInfo = _playlistsInfo, tracksInfo = _tracksInfo, numberOfPlaylistsOwned = _numberOfPlaylistsOwned, numberOfPlaylistsCollab = _numberOfPlaylistsCollab, numberOfPlaylistsSubscr = _numberOfPlaylistsSubscr, selectedPlaylistPath = _selectedPlaylistPath, selectedPlaylist = _selectedPlaylist;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    CGRect chooseMusicFrame = [[UIScreen mainScreen] bounds];
    chooseMusicFrame.size.height = [[UIScreen mainScreen] bounds].size.height - self.navigationController.navigationBar.bounds.size.height;
    
    UITableView *chooseMusic = [[UITableView alloc] initWithFrame:chooseMusicFrame style:UITableViewStyleGrouped];
    //[self setTitle:@"Playlists"];
    
    [chooseMusic setBackgroundColor:[UIColor clearColor]];
    [chooseMusic setBackgroundView:nil];
    [chooseMusic setDelegate:self];
    [chooseMusic setDataSource:self];
    
    [self.view addSubview:chooseMusic];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    int numberOfRows = 0;
    
    if (section == 0) {
        numberOfRows = appDelegate.numberOfPlaylistsCollab;
    } else if (section == 1) {
        numberOfRows = appDelegate.numberOfPlaylistsOwned;
    } else {
        numberOfRows = appDelegate.numberOfPlaylistsSubscr;
    }
    
    return numberOfRows;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"shoppingListCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"shoppingListCell"];
    }
    
    NSString *cellLabel = @"";
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    if (indexPath.section == 0) {
        cellLabel = [appDelegate.playlistsInfo objectAtIndex:(indexPath.row)];
    } else if (indexPath.section == 1) {
        cellLabel = [appDelegate.playlistsInfo objectAtIndex:(indexPath.row)+appDelegate.numberOfPlaylistsCollab];
    } else {
        cellLabel = [appDelegate.playlistsInfo objectAtIndex:(indexPath.row)+appDelegate.numberOfPlaylistsCollab+appDelegate.numberOfPlaylistsOwned];
    }

    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.text = cellLabel;

    //[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    //UILabel *sectionView = [[UILabel alloc] initWithFrame:[tableView rectForHeaderInSection:section]];
    UILabel *sectionView = [[UILabel alloc] initWithFrame:CGRectMake(40.0, 0.0, 200.0, 30.0)];
    
    [sectionView setTextColor:[UIColor whiteColor]];
    [sectionView setBackgroundColor:[UIColor clearColor]];
    [sectionView setFont:[UIFont boldSystemFontOfSize:16.0]];
    
    if (section == 0) {
        sectionView.text = [NSString stringWithFormat:NSLocalizedString(@"COLLAB HEADER", nil)];
    } else if (section == 1) {
        sectionView.text = [NSString stringWithFormat:NSLocalizedString(@"OWNED HEADER", nil)];
    } else {
        sectionView.text = [NSString stringWithFormat:NSLocalizedString(@"SUBSCRIBED HEADER", nil)];
    }
    
    return sectionView;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionName = @"";
    
    if (section == 0) {
        sectionName = [NSString stringWithFormat:NSLocalizedString(@"COLLAB", nil)];
    } else if (section == 1) {
        sectionName = [NSString stringWithFormat:NSLocalizedString(@"OWNED", nil)];
    } else {
        sectionName = [NSString stringWithFormat:NSLocalizedString(@"SUBSCRIBED", nil)];    }
    
    return sectionName;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    //UIViewController *listsViewController = [[ListsViewController alloc] init];
    [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO animated:YES];
    //[[tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
    
    //[self.navigationController pushViewController:listsViewController animated:YES];
    appDelegate.selectedPlaylistPath = indexPath;

    NSLog(@"section selected: %d, row selected: %d", indexPath.section, indexPath.row);
    appDelegate.selectedPlaylist = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
