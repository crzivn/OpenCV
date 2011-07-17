//
//  OpenCVViewController.m
//  OpenCV
//
//  Created by Ivan Navarrete on 5/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <opencv2/imgproc/imgproc_c.h>
#import <opencv2/objdetect/objdetect.hpp>

#import "OpenCVViewController.h"


@interface OpenCVViewController()
  - (void)getImage:(UIImagePickerControllerSourceType)sourceType;
  - (IplImage *)createIplImageFromUIImage:(UIImage *)image;
  - (UIImage *)createUIImageFromIplImage:(IplImage *)image;
  - (UIImage *)scaleAndRotateImage:(UIImage *)image;
  - (void)showProgressIndicator:(NSString *)text;
  - (void)hideProgressIndicator;
@end


@implementation OpenCVViewController

@synthesize imageView;


#pragma mark - View lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];

  //[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
  [self loadImage];
}


- (void)viewDidUnload {
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
}

  
- (void)dealloc {
  [super dealloc];
}


- (void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Release any cached data, images, etc that aren't in use.
}


#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  imageView.image = [info valueForKey:@"UIImagePickerControllerOriginalImage"];
  [[picker parentViewController] dismissModalViewControllerAnimated:YES];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [[picker parentViewController] dismissModalViewControllerAnimated:YES];
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  UIImagePickerControllerSourceType sourceType;

  switch (buttonIndex) {
    case 0: sourceType = UIImagePickerControllerSourceTypePhotoLibrary; break;
    case 1: sourceType = UIImagePickerControllerSourceTypeCamera; break;
    case 2: break;
    default: return;      // do nothing on Cancel
  }

  [self getImage:sourceType];
}


#pragma mark - Actions

- (IBAction)loadImage {
  UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:@"Photo Library", @"Camera", @"Default image", nil];

  actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
  [actionSheet showInView:self.view];
  [actionSheet release];
}


- (IBAction)saveImage {
  if (imageView.image) {
    [self showProgressIndicator:@"Saving"];

    UIImageWriteToSavedPhotosAlbum(imageView.image,
                                   self, @selector(image:didFinishSavingWithError:contextInfo:),
                                   nil);
  }
}


- (IBAction)faceDetect {
  imageView.image = [self scaleAndRotateImage:imageView.image];
  [self showProgressIndicator:@"Scanning"];
  [self performSelectorInBackground:@selector(opencvFaceDetect:) withObject:nil];
}


- (IBAction)edgeDetect {
  [self showProgressIndicator:@"Scanning"];
  [self performSelectorInBackground:@selector(opencvEdgeDetect) withObject:nil];
}


#pragma mark - Private methods

- (void)getImage:(UIImagePickerControllerSourceType)sourceType {
  // get image from photo library or camera
  if ([UIImagePickerController isSourceTypeAvailable:sourceType]) {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = sourceType;
    picker.delegate = self;
    picker.allowsEditing = NO;
    [self presentModalViewController:picker animated:YES];
    [picker release];

  // or use default image
  } else {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"lena" ofType:@"jpg"];
    imageView.image = [UIImage imageWithContentsOfFile:path];
  }
}


- (void)opencvFaceDetect:(UIImage *)overlayImage {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  if (imageView.image) {
    cvSetErrMode(CV_ErrModeParent);

    IplImage *image = [self createIplImageFromUIImage:imageView.image];

    // scaling down
    IplImage *small_image = cvCreateImage(cvSize(image->width/2, image->height/2), IPL_DEPTH_8U, 3);
    cvPyrDown(image, small_image, CV_GAUSSIAN_5x5);
    int scale = 2;

    // load xml
    NSString *path = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default"
                                                     ofType:@"xml"];

    CvHaarClassifierCascade *cascade = (CvHaarClassifierCascade *)cvLoad([path cStringUsingEncoding:NSASCIIStringEncoding], NULL, NULL, NULL);
    CvMemStorage *storage = cvCreateMemStorage(0);

    // detect faces and draw rectangle on them
    CvSeq *faces = cvHaarDetectObjects(small_image, cascade, storage, 1.2, 2, CV_HAAR_DO_CANNY_PRUNING, cvSize(0, 0), cvSize(20, 20));
    cvReleaseImage(&small_image);

    // create canvas to show the result
    CGImageRef imageRef = imageView.image.CGImage;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 imageView.image.size.width,
                                                 imageView.image.size.height,
                                                 8,
                                                 imageView.image.size.width * 4,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast |
                                                 kCGBitmapByteOrderDefault);
    CGContextDrawImage(context,
                       CGRectMake(0, 0, imageView.image.size.width, imageView.image.size.height),
                       imageRef);
    CGContextSetLineWidth(context, 4);
    CGContextSetRGBStrokeColor(context, 0.0, 0.0, 1.0, 0.5);

    // draw results on the image
    for (int i = 0; i < faces->total; i++) {
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

      // calc the rest of the faces
      CvRect cvrect = *(CvRect *)cvGetSeqElem(faces, i);
      CGRect face_rect = CGContextConvertRectToDeviceSpace(context, CGRectMake(cvrect.x * scale,
                                                                               cvrect.y * scale,
                                                                               cvrect.width * scale,
                                                                               cvrect.height *scale));

      CGContextStrokeRect(context, face_rect);

      [pool drain];
    }

    imageView.image = [UIImage imageWithCGImage:CGBitmapContextCreateImage(context)];

    // release memory
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    cvReleaseMemStorage(&storage);
    cvReleaseHaarClassifierCascade(&cascade);

    [self hideProgressIndicator];
  }

  [pool drain];
}


- (void)opencvEdgeDetect {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  if (imageView.image) {
    cvSetErrMode(CV_ErrModeParent);

    // create grayscale IplImage from UIImage
    IplImage *color_image = [self createIplImageFromUIImage:imageView.image];
    IplImage *grayscale_image = cvCreateImage(cvGetSize(color_image), IPL_DEPTH_8U, 1);
    cvCvtColor(color_image, grayscale_image, CV_BGR2GRAY);
    cvReleaseImage(&color_image);

    // detect edges
    IplImage *edge_image = cvCreateImage(cvGetSize(grayscale_image), IPL_DEPTH_8U, 1);
    cvCanny(grayscale_image, edge_image, 64, 128, 3);
    cvReleaseImage(&grayscale_image);

    // convert black and white to 24-bit image
    IplImage *image = cvCreateImage(cvGetSize(edge_image), IPL_DEPTH_8U, 3);
    for (int y = 0; y < edge_image->height; y++) {
      for (int x = 0; x < edge_image->width; x++) {
        char *p = image->imageData + y * image->widthStep + x * 3;
        *p = *(p + 1) = *(p + 2) = edge_image->imageData[y * edge_image->widthStep + x];
      }
    }

    // convert to UIImage
    cvReleaseImage(&edge_image);
    imageView.image = [self createUIImageFromIplImage:image];
    cvReleaseImage(&image);

    [self hideProgressIndicator];
  }

  [pool release];
}


- (IplImage *)createIplImageFromUIImage:(UIImage *)image {
  // get CGImage from UIImage
  CGImageRef imageRef = image.CGImage;
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

  // create temp IplImage for drawing
  IplImage *iplImage = cvCreateImage(cvSize(image.size.width, image.size.height),
                                     IPL_DEPTH_8U,
                                     4);

  // create CGContext for temp IplImage
  CGContextRef context = CGBitmapContextCreate(iplImage->imageData,
                                                  iplImage->width,
                                                  iplImage->height,
                                                  iplImage->depth,
                                                  iplImage->widthStep,
                                                  colorSpace,
                                                  kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);

  // draw CGImage to CGContext
  CGContextDrawImage(context, CGRectMake(0, 0, image.size.width, image.size.height), imageRef);

  CGContextRelease(context);
  CGColorSpaceRelease(colorSpace);

  // create result IplImage
  IplImage *retImage = cvCreateImage(cvGetSize(iplImage), IPL_DEPTH_8U, 3);
  cvCvtColor(iplImage, retImage, CV_RGBA2BGR);

  cvReleaseImage(&iplImage);

  return retImage;
}


- (UIImage *)createUIImageFromIplImage:(IplImage *)image {
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

  // allocate buffer for CGImage
  NSData *data = [NSData dataWithBytes:image->imageData length:image->imageSize];
  CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);

  // create CGImage from chunk of IplImage
  CGImageRef imageRef = CGImageCreate(image->width,
                                      image->height,
                                      image->depth,
                                      image->depth * image->nChannels,
                                      image->widthStep,
                                      colorSpace,
                                      kCGImageAlphaNone | kCGBitmapByteOrderDefault,
                                      provider,
                                      NULL,
                                      false,
                                      kCGRenderingIntentDefault);

  // getting UIImage from CGImage
  UIImage *ret = [UIImage imageWithCGImage:imageRef];

  // release memory
  CGImageRelease(imageRef);
  CGDataProviderRelease(provider);
  CGColorSpaceRelease(colorSpace);

  return ret;
}


- (UIImage *)scaleAndRotateImage:(UIImage *)image {
	static int kMaxResolution = 640;
	
	CGImageRef imgRef = image.CGImage;
	CGFloat width = CGImageGetWidth(imgRef);
	CGFloat height = CGImageGetHeight(imgRef);
	
	CGAffineTransform transform = CGAffineTransformIdentity;
	CGRect bounds = CGRectMake(0, 0, width, height);
	if (width > kMaxResolution || height > kMaxResolution) {
		CGFloat ratio = width/height;
		if (ratio > 1) {
			bounds.size.width = kMaxResolution;
			bounds.size.height = bounds.size.width / ratio;
		} else {
			bounds.size.height = kMaxResolution;
			bounds.size.width = bounds.size.height * ratio;
		}
	}
	
	CGFloat scaleRatio = bounds.size.width / width;
	CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
	CGFloat boundHeight;
	
	UIImageOrientation orient = image.imageOrientation;
	switch(orient) {
		case UIImageOrientationUp:
			transform = CGAffineTransformIdentity;
			break;
		case UIImageOrientationUpMirrored:
			transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			break;
		case UIImageOrientationDown:
			transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
			transform = CGAffineTransformRotate(transform, M_PI);
			break;
		case UIImageOrientationDownMirrored:
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
			transform = CGAffineTransformScale(transform, 1.0, -1.0);
			break;
		case UIImageOrientationLeftMirrored:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
			break;
		case UIImageOrientationLeft:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
			break;
		case UIImageOrientationRightMirrored:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeScale(-1.0, 1.0);
			transform = CGAffineTransformRotate(transform, M_PI / 2.0);
			break;
		case UIImageOrientationRight:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
			transform = CGAffineTransformRotate(transform, M_PI / 2.0);
			break;
		default:
			[NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
	}
	
	UIGraphicsBeginImageContext(bounds.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
		CGContextScaleCTM(context, -scaleRatio, scaleRatio);
		CGContextTranslateCTM(context, -height, 0);
	} else {
		CGContextScaleCTM(context, scaleRatio, -scaleRatio);
		CGContextTranslateCTM(context, 0, -height);
	}
	CGContextConcatCTM(context, transform);
	CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
	UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return imageCopy;
}


- (void)showProgressIndicator:(NSString *)text {
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  self.view.userInteractionEnabled = FALSE;
}


- (void)hideProgressIndicator {
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  self.view.userInteractionEnabled = TRUE;
}


#pragma mark - Callbacks

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
  [self hideProgressIndicator];
}


@end
