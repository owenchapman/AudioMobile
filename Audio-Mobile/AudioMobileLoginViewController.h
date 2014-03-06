//
//  AudioMobileLoginViewController.h
//  Audio-Mobile
//
//

#import <UIKit/UIKit.h>
#import "AudioMobileRestAPIManager.h"
#import "AudioMobileAppDelegate.h"
#import "Reachability.h"

@interface AudioMobileLoginViewController : UIViewController<UITextFieldDelegate,AudioMobileRestAsyncResponseNotifier> {
        Reachability* internetReachable;
}

@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIScrollView *containerScrollView;

@end
