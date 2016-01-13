//
//  CameraViewController.h
//  whalecode
//
//  Created by Kleiber J Perez on 8/12/15.
//  Copyright © 2015 Kleiber J Perez. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface CameraViewController : UIViewController{
    IBOutlet UIView *frameCamera;
    AVCaptureVideoPreviewLayer *previewLayer;
    BOOL usingFrontCamera;
    NSData *imageTaked;
    UIImage *imageSelected;
}

@property (nonatomic, strong) NSString *latitude;
@property (nonatomic, strong) NSString *longitude;


-(void) setPositionLatitude: (NSString *) latitude withLongitude: (NSString *) longitude;
@end
