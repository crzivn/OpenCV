//
//  OpenCVViewController.h
//  OpenCV
//
//  Created by Ivan Navarrete on 5/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OpenCVViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate> {
}

@property (nonatomic, retain) IBOutlet UIImageView *imageView;

- (IBAction)loadImage;
- (IBAction)saveImage;
- (IBAction)faceDetect;
- (IBAction)edgeDetect;

@end
