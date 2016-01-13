//
//  CameraViewController.m
//  whalecode
//
//  Created by Kleiber J Perez on 8/12/15.
//  Copyright © 2015 Kleiber J Perez. All rights reserved.
//

#import "CameraViewController.h"
#import "AFNetworking.h"

@interface CameraViewController ()

@end

@implementation CameraViewController

AVCaptureSession *session;
AVCaptureStillImageOutput *stillImageOutput;
UIView *frameImage;
UIImageView *imageCaptured;
UIButton *btnCancel, *btnSend, *btnCapture, *btnSwitch;



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated{
    [self setAVCapture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setting View

-(void)setAVCapture {
    CGFloat screenHeight, screenWidht;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    screenHeight = screenRect.size.height;
    screenWidht = screenRect.size.width;
    
    CGFloat xPosition = (screenWidht / 2) - 32;
    CGFloat yPosition = screenHeight - 120;
    btnCapture = [[UIButton alloc] initWithFrame:CGRectMake(xPosition, yPosition, 64, 64)];
    [btnCapture setBackgroundImage:[UIImage imageNamed:@"capture"] forState:UIControlStateNormal];
    [btnCapture addTarget:self action:@selector(captureImage:) forControlEvents:UIControlEventTouchUpInside];
    
    btnSwitch = [[UIButton alloc] initWithFrame:CGRectMake(screenWidht - 32 , 32, 32, 32)];
    [btnSwitch setBackgroundImage:[UIImage imageNamed:@"switch"] forState:UIControlStateNormal];
    [btnSwitch addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
    
    session = [[AVCaptureSession alloc] init];
    [session setSessionPreset:AVCaptureSessionPresetPhoto];
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    if ([session canAddInput:input]) {
        [session addInput:input];
    }
    
    previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    CALayer *rootLayer = [[self view] layer];
    [rootLayer setMasksToBounds:YES];
    CGRect frame = frameCamera.frame;
    
    [previewLayer setFrame:frame];
    
    [rootLayer addSublayer:previewLayer];
    [self.view addSubview:btnCapture];
    [self.view addSubview:btnSwitch];
    
    stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [stillImageOutput setOutputSettings:outputSettings];
    
    [session addOutput:stillImageOutput];
    [session startRunning];
    
}


#pragma mark - Actions Camera

- (void)captureImage:(id)sender {
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in stillImageOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                videoConnection = connection;
                break;
            }
        }
    }
    
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer != NULL) {
            imageTaked= [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            imageSelected = [UIImage imageWithData:imageTaked];
            [self setView:self.view withImage:imageSelected];
        }
    }];

}

- (void)cancelImage:(id)sender {
    [frameImage removeFromSuperview];
    [self setAVCapture];
}


-(void)sendImage:(id)sender {
    NSURL *baseUrl = [NSURL URLWithString:@"http://whalecode.com:4212"];
    NSData *imageData = UIImageJPEGRepresentation(imageSelected, 1.0);
    NSUInteger len = imageData.length;
    uint8_t *bytes = (uint8_t *)[imageData bytes];
    NSMutableString *result = [NSMutableString stringWithCapacity:len * 3];
    [result appendString:@"["];
    for (NSUInteger i = 0; i < len; i++) {
        if (i) {
            [result appendString:@","];
        }
        [result appendFormat:@"%d", bytes[i]];
    }
    [result appendString:@"]"];
    
    NSInputStream *stream = [[NSInputStream alloc] initWithData:imageData];
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseUrl];
    NSMutableSet *contentTypes = [NSMutableSet setWithSet:manager.responseSerializer.acceptableContentTypes];
    [contentTypes addObject:@"text/plain"];
    [contentTypes addObject:@"binary/octet-stream"];
    manager.responseSerializer.acceptableContentTypes = contentTypes;

    NSDictionary *data = @{@"lat": _latitude, @"long" : _longitude};
    AFHTTPRequestOperation *operation = [manager POST:@"/index/searcher"
                                           parameters:data
                            constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                                [formData appendPartWithInputStream:stream name:@"request" fileName:@"request.jpg" length:[imageData length] mimeType:@"image/jpeg"];
                                /*[formData appendPartWithFileData:imageData
                                                            name:@"request"
                                                        fileName:@"request.jpg"
                                                        mimeType:@"image/jpeg"];*/
                                
        
                            }
                                              success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        
                                                  NSLog(@"Success: %@ ***** %@", operation.responseString, responseObject);
                                                  NSDictionary *data = (NSDictionary *)responseObject;
                                                  [self showAlert:@"Success" withMessage:[NSString stringWithFormat:@"%@", data]];
        
                                              }
                                              failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        
                                                  NSLog(@"Error: %@ ***** %@", operation.responseString, error);
                                                  [self showAlert:@"Error" withMessage:[NSString stringWithFormat:@"%@", error]];
    
                                              }];
    [operation start];
    /*NSString *urlRequest = [NSString stringWithFormat:@"%@%@", baseUrl, @"/index/searcher"];
    NSMutableURLRequest *request = [manager.requestSerializer multipartFormRequestWithMethod:@"PUT" URLString:urlRequest parameters:data constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFileData:[imageTaked base64EncodedDataWithOptions:NSDataBase64Encoding64CharacterLineLength]
                                    name:@"file"
                                fileName:@"request.jpg"
                                mimeType:@"image/jpeg"];
    } error:nil];
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request
                                                                         success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
                                                                             
                                                                             NSLog(@"Success: %@ ***** %@", operation.responseString, responseObject);
                                                                             NSDictionary *data = (NSDictionary *)responseObject;
                                                                             [self showAlert:@"Success"
                                                                                 withMessage:[NSString stringWithFormat:@"%@", data]];
                                                                             
                                                                         }
                                                                         failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
                                                                             
                                                                             NSLog(@"Error: %@ ***** %@", operation.responseString, error);
                                                                             [self showAlert:@"Error"
                                                                                 withMessage:[NSString stringWithFormat:@"%@", error]];
                                                                         }];
    [operation start]; */
}


-(void)switchCamera:(id)sender {
    AVCaptureDevicePosition desiredPosition;
    if (usingFrontCamera) {
        desiredPosition = AVCaptureDevicePositionBack;
    } else {
        desiredPosition = AVCaptureDevicePositionFront;
    }
    
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([device position] == desiredPosition) {
            [[previewLayer session] beginConfiguration];
            NSError *error;
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
            for (AVCaptureInput *oldInput in [[previewLayer session] inputs]) {
                [[previewLayer session] removeInput:oldInput];
            }
            [[previewLayer session] addInput:input];
            [[previewLayer session] commitConfiguration];
            break;
        }
    }
    usingFrontCamera = !usingFrontCamera;
}


-(void)setView:(UIView *)superView withImage:(UIImage*)image {
    
    CGFloat screenHeight, screenWidht;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    screenHeight = screenRect.size.height;
    screenWidht = screenRect.size.width;
    
    frameImage = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidht, screenHeight)];
    [superView addSubview:frameImage];
    
    imageCaptured = [[UIImageView alloc] initWithImage:image];
    [imageCaptured setFrame:CGRectMake(0, 0, screenWidht, screenHeight)];
    
    
    CGFloat xPosition = (screenWidht / 2) - 32;
    CGFloat yPosition = screenHeight - 120;
    btnSend = [[UIButton alloc] initWithFrame:CGRectMake(xPosition, yPosition, 64, 64)];
    [btnSend setBackgroundImage:[UIImage imageNamed:@"upload"] forState:UIControlStateNormal];
    [btnSend addTarget:self action:@selector(sendImage:) forControlEvents:UIControlEventTouchUpInside];
    
    btnCancel = [[UIButton alloc] initWithFrame:CGRectMake(31, 31, 32, 32)];
    [btnCancel setBackgroundImage:[UIImage imageNamed:@"cancel"] forState:UIControlStateNormal];
    [btnCancel addTarget:self action:@selector(cancelImage:) forControlEvents:UIControlEventTouchUpInside];
    
    [frameImage addSubview:imageCaptured];
    [frameImage addSubview:btnCancel];
    [frameImage addSubview:btnSend];
}


#pragma mark - Extra Functions


-(void) setPositionLatitude:(NSString *)latitude withLongitude:(NSString *)longitude {
    _latitude = latitude;
    _longitude = longitude;
}


-(void) showAlert:(NSString *)title withMessage:(NSString *)message {

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
