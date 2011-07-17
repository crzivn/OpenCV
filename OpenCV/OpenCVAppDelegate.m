//
//  OpenCVAppDelegate.m
//  OpenCV
//
//  Created by Ivan Navarrete on 5/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OpenCVAppDelegate.h"
#import "OpenCVViewController.h"

@implementation OpenCVAppDelegate

@synthesize window=_window;
@synthesize viewController=_viewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.window.rootViewController = self.viewController;
  [self.window makeKeyAndVisible];
  return YES;
}


- (void)dealloc {
  [_window release];
  [_viewController release];
  [super dealloc];
}

@end
