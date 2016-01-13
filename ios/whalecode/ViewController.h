//
//  ViewController.h
//  whalecode
//
//  Created by Kleiber J Perez on 8/12/15.
//  Copyright © 2015 Kleiber J Perez. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController : UIViewController <CLLocationManagerDelegate>{
    CLLocation *currentLocation;
}

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end

