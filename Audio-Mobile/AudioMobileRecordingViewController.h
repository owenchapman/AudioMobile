//
//  AudioMobileRecordingViewController.h
//  Audio-Mobile
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MessageUI/MessageUI.h>

#import "AudioMobilePostRecordViewController.h"
#import <CoreLocation/CoreLocation.h>

@interface AudioMobileRecordingViewController : UIViewController<AVAudioRecorderDelegate,MFMailComposeViewControllerDelegate,CLLocationManagerDelegate,AVAudioPlayerDelegate> {
    bool isUpdatingLocation;
    bool isRecordingInitialLocationDetermined;
}

@property (weak, nonatomic) IBOutlet UIImageView *displayImageView;
@property (strong, nonatomic) UIImage* displayImage;
@property (weak, nonatomic) IBOutlet UILabel *timerLabel;

@property (assign,nonatomic) NSTimeInterval startDate;

@property (assign, nonatomic) AVCaptureSession* captureSession;
@property (strong, nonatomic) AVAudioRecorder* audioRecorder;

@property (strong, nonatomic) CLLocationManager* locationManager;

@property (strong, nonatomic) NSTimer* recordingTimer;
@property (strong, nonatomic) NSTimer* locationCaptureIntervalTimer;

@property (nonatomic) NSTimeInterval recordingLength;

@property (nonatomic) bool recording;

@property (nonatomic, strong) AVAudioPlayer* player;

@property (nonatomic) NSUInteger locationUpdateFailedCount;


@property (nonatomic) CLLocationCoordinate2D recordingInitialLocation;
@property (strong, nonatomic) NSMutableArray* subsequentRecordingLocations;
@property (strong, nonatomic) NSMutableArray* subsequentRecordingTimepoints;


@end
