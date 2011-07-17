//
//  OpenCVAppDelegate.h
//  OpenCV
//
//  Created by Ivan Navarrete on 5/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OpenCVViewController;

@interface OpenCVAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet OpenCVViewController *viewController;

@end
