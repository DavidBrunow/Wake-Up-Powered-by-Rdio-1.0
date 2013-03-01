//
//  AlarmNavController.h
//  Rdio Alarm
//
//  Created by David Brunow on 3/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface AlarmNavController : UINavigationController <RdioDelegate>
{
    UIBarButtonItem *logIn;
    UIViewController *alarmVC;
    
}

- (void) loginClicked;

@end
