//
//  ViewController.m
//  whalecode
//
//  Created by Kleiber J Perez on 8/12/15.
//  Copyright © 2015 Kleiber J Perez. All rights reserved.
//

#import "ViewController.h"
#import "CameraViewController.h"

@interface ViewController ()

@end

@implementation ViewController{
    CLLocationManager *locationManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_spinner startAnimating];
    // Do any additional setup after loading the view, typically from a nib.
    if ([CLLocationManager locationServicesEnabled])
    {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.distanceFilter = kCLDistanceFilterNone;
        if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
        {
            [locationManager requestAlwaysAuthorization];
        }
        [locationManager requestLocation];
    }else{
        NSString *titulo = @"Servicio de ubicación desactivado";
        NSString *message = @"El servicio de ubicacion esta desactivado, puedes activarlo en Settings->Location->location services->on";
        [self showAlertWithTitle:titulo withMessage:message andRequestSetting:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)showAlertWithTitle:(NSString *) titulo withMessage:(NSString *) message andRequestSetting:(BOOL) request{
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:titulo
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *alert = [UIAlertAction actionWithTitle:@"OK"
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction * _Nonnull action) {
                                                      [alertController dismissViewControllerAnimated:YES
                                                                                          completion:nil];
                                                  }];
    
    
    UIAlertAction *alertConfig = [UIAlertAction actionWithTitle:@"Configuración"
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction * _Nonnull action) {
                                                         [[UIApplication sharedApplication] openURL:[NSURL  URLWithString:UIApplicationOpenSettingsURLString]];
                                                  }];
    
    
    [alertController addAction:alert];
    
    if(request){
        if(![[[UIDevice currentDevice] systemVersion] floatValue]<8.0){
             [alertController addAction:alertConfig];
        }
    }
    
    [self presentViewController:alertController animated:YES completion:nil];
    
    
}


#pragma mark - CLlocationManagerDelegate

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error"
                                                                             message:@"Ha ocurrido un error obteniendo tu ubicación"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *alert = [UIAlertAction actionWithTitle:@"OK"
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction * _Nonnull action) {
                                                      [alertController dismissViewControllerAnimated:YES
                                                                                          completion:nil];
                                                  }];
    
    [alertController addAction:alert];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    
    currentLocation = [locations lastObject];
    
    if (currentLocation != nil) {
        NSLog(@"Latitude: %.8f , Longitude: %.8f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude);
        dispatch_async(dispatch_get_main_queue(), ^{
            [locationManager stopUpdatingLocation];
            [_spinner stopAnimating];
            [self performSegueWithIdentifier:@"goToCamera" sender:self];
        });
    }
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
        {
            // do some error handling
        }
            break;
        default:{
            [locationManager startUpdatingLocation];
        }
            break;
    }
}


#pragma mark - Navigation
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    //goToCamera
    
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"goToCamera"]) {
        CameraViewController *cameraView = [segue destinationViewController];
        [cameraView setPositionLatitude:[NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude]
                          withLongitude:[NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude]];
    }
    
    
    
}




@end
