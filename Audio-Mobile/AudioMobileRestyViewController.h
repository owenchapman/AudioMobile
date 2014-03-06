//
//  AudioMobileRestyViewController.h
//  Audio-Mobile
//
//

#import <UIKit/UIKit.h>
#import "AudioMobileRestAPIManager.h"

@interface AudioMobileRestyViewController : UIViewController<NSURLConnectionDelegate,NSURLConnectionDataDelegate,AudioMobileRestAsyncResponseNotifier>
@property (weak, nonatomic) IBOutlet UITextView *resultsTextView;

@end
