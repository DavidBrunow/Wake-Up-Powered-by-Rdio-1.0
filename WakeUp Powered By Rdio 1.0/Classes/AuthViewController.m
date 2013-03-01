//
//  AuthViewController.m
//  Rdio Alarm
//
//  Created by David Brunow on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AuthViewController.h"
#import "AppDelegate.h"

@interface AuthViewController ()

@end

@implementation AuthViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [[AppDelegate rdioInstance] setDelegate:self];
    //[[AppDelegate rdioInstance] logout];
    
    UIImage *navBarLogo = [UIImage imageNamed:@"navbarclockicon"];
    UIImageView *navBarLogoView = [[UIImageView alloc] initWithImage:navBarLogo];
    [navBarLogoView setFrame:CGRectMake(140.0, 0.0, 40.0, 40.0)];
    [self.view addSubview:navBarLogoView];
    
    [self.view setBackgroundColor:[UIColor colorWithRed:68.0/255 green:11.0/255 blue:104.0/255 alpha:1.0]];
    CGRect signInFrame = CGRectMake(40, 190, 240, 80);
    UIButton *signInButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [signInButton setFrame:signInFrame];
    
    [signInButton setTitle:@"Sign In to Rdio®" forState: UIControlStateNormal];
    [signInButton setBackgroundColor:[UIColor clearColor]];
    [signInButton addTarget:self action:@selector(rdioUserAuth) forControlEvents:UIControlEventTouchUpInside];
    [signInButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:signInButton];
    
    CGRect noSignInFrame = CGRectMake(100, 370, 120, 27);
    UIButton *noSignInButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [noSignInButton setFrame:noSignInFrame];
    
    [noSignInButton setTitle:@"Don't Sign In" forState: UIControlStateNormal];
    [noSignInButton setBackgroundColor:[UIColor clearColor]];
    [noSignInButton addTarget:self action:@selector(tryThisApp) forControlEvents:UIControlEventTouchUpInside];
    [noSignInButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:noSignInButton];
    
}

- (void) rdioUserAuth
{
    [[AppDelegate rdioInstance] authorizeFromController:self];
}

- (void) tryThisApp
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    AlarmNavController *mainNav = [[AlarmNavController alloc] init];
    [mainNav.navigationBar setTintColor:[UIColor colorWithRed:68.0/255 green:11.0/255 blue:104.0/255 alpha:1.0]];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
    [appDelegate.window setRootViewController:mainNav];
    
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

#pragma mark -
#pragma mark RdioDelegate
- (void) rdioDidAuthorizeUser:(NSDictionary *)user withAccessToken:(NSString *)accessToken {
    NSLog(@"got here");
    [self setLoggedIn:YES];
    NSLog(@"got here");
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    bool success = [SFHFKeychainUtils storeUsername:@"rdioUser" andPassword:accessToken forServiceName:@"rdioAlarm" updateExisting:TRUE error:nil]; 
    if(!success)
    {
        NSLog(@"Saving keychain entry not successful.");
    }
    AlarmNavController *mainNav = [[AlarmNavController alloc] init];
    [mainNav.navigationBar setTintColor:[UIColor colorWithRed:68.0/255 green:11.0/255 blue:104.0/255 alpha:1.0]];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
    [appDelegate.window setRootViewController:mainNav];
    
}

- (void) rdioAuthorizationFailed:(NSString *)error {
    [self setLoggedIn:NO];
}

- (void) rdioAuthorizationCancelled {
    [self setLoggedIn:NO];
}

- (void) rdioDidLogout {
    [self setLoggedIn:NO];

    bool success = [SFHFKeychainUtils deleteItemForUsername:@"rdioUser" andServiceName:@"rdioAlarm" error:nil];
    if(!success)
    {
        NSLog(@"Deleting keychain entry not successful.");
    }
}

- (void) setLoggedIn:(BOOL)logged_in {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.loggedIn = logged_in;
    if (logged_in) {
        //[logIn setTitle:@"Sign Out"];
    } else {
        //[logIn setTitle:@"Sign In"];
    }
}

@end
