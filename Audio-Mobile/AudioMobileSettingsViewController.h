//
//  AudioMobileSettingsViewController.h
//  Audio-Mobile
//
//

#import <UIKit/UIKit.h>
#import "AudioMobileAppDelegate.h"
#import "Reachability.h"

@interface AudioMobileSettingsViewController : UIViewController<UIImagePickerControllerDelegate,UIAlertViewDelegate,AudioMobileRestAsyncResponseNotifier> {
    Reachability* internetReachable;
}

@property (weak, nonatomic) IBOutlet UIButton *publicAudioB;
@property (weak, nonatomic) IBOutlet UIButton *privateAudioB;

@property (weak, nonatomic) IBOutlet UISegmentedControl *gpsIntervalSelector;

@property (weak, nonatomic) IBOutlet UISegmentedControl *audioTypeSelector;

@property (weak, nonatomic) IBOutlet UIButton *profileImageThumb;

@property (weak, nonatomic) IBOutlet UIButton *loginLogoutButton;

@property (weak, nonatomic) IBOutlet UISegmentedControl *gpsIntervalControl;

@property (assign,nonatomic) UIImage* uploadedProfilePicRef;

@property (assign, nonatomic) UIActivityIndicatorView* actInd;

@end
