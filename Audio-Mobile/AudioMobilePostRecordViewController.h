//
//  AudioMobilePostRecordViewController.h
//  Audio-Mobile
//
//

#import <UIKit/UIKit.h>
#import "AudioMobilePlaybackViewController.h"
#import "AudioMobileOggVorbisEncoder.h"
#import "AudioMobileAppDelegate.h"
#import "AudioMobileRestAPIManager.h"
#import "AudioMobileDataModel.h"

#import <MessageUI/MessageUI.h> 

#import <CoreLocation/CoreLocation.h>

@interface AudioMobilePostRecordViewController : UIViewController<UITextFieldDelegate,AudioMobileOggVorbisEncoderDelegate,AudioMobileRestAsyncResponseNotifier, UIAlertViewDelegate, UIImagePickerControllerDelegate,MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *displayImageView;
@property (strong, nonatomic) UIImage* displayImage;
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UITextField *notesTextField;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@property (nonatomic) CLLocationCoordinate2D nodeStartLocation;

@property (weak, nonatomic) IBOutlet UIImageView *sunnyImage;
@property (weak, nonatomic) IBOutlet UIImageView *rainyImage;
@property (weak, nonatomic) IBOutlet UIImageView *windyImage;
@property (weak, nonatomic) IBOutlet UIImageView *coldImage;
@property (weak, nonatomic) IBOutlet UIImageView *hotImage;
@property (weak, nonatomic) IBOutlet UIImageView *cloudyImage;
@property (weak, nonatomic) IBOutlet UISegmentedControl *weatherControl;

@property (strong, nonatomic) NSArray* segmentToWeatherMap; //this maps segments of our hidden (alpha:0) segmented weather control in the storyboard to the weather types they are labeled with

@property (weak, nonatomic) IBOutlet UIProgressView *progressIndicator;
@property (weak, nonatomic) IBOutlet UILabel *progressStatusLabel;

@property (strong, nonatomic) AudioMobileOggVorbisEncoder* encoder;

@property (strong,nonatomic) NSURL* wavFileRecordingURL;

@property (nonatomic) NSTimeInterval recordingLength;

@property (strong, nonatomic) NSURL* oggVorbisFileRecordingURL;
@property (weak, nonatomic) IBOutlet UIButton *uploadButton;
@property (strong, nonatomic) UIActivityIndicatorView* activityIndicator;

//@property (strong, nonatomic) AudioNode1* offlineNode;
@property ( nonatomic) NSUInteger offlineNodeIndex;

@property (strong, nonatomic) UIAlertView* deleteNodeDialog;
@property (strong, nonatomic) UIAlertView* changeImageDialog;

@property (strong, nonatomic) UIImagePickerController* imagePicker;

@property (weak, nonatomic) IBOutlet UISegmentedControl *publicPrivateControl;
@property (weak, nonatomic) IBOutlet UITextField *locationDescriptionField;

@end
