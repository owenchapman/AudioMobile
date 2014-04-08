//
//  AudioMobilePlaybackViewController.h
//  Audio-Mobile
//
//

#import <UIKit/UIKit.h>
#import "IDZAQAudioPlayer.h"
#import "IDZAudioDecoder.h"//

#import "IDZOggVorbisFileDecoder.h"
#import "AFNetworking.h"
#import "Reachability.h"

#import <MessageUI/MessageUI.h>


@interface AudioMobilePlaybackViewController : UIViewController<IDZAudioPlayerDelegate,MFMailComposeViewControllerDelegate> {
    Reachability* internetReachable;
}

@property (strong, nonatomic) UIImage* nodeImage;
@property (strong, nonatomic) UIImage* creatorThumbnail;

@property (strong, nonatomic) IBOutlet UIImageView *nodeImageView;
@property (weak, nonatomic) IBOutlet UIImageView *creatorThumbnailView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *creatorNameLabel;

@property (assign, nonatomic) NSString* title;
@property (assign, nonatomic) NSString* creatorName;
@property (assign, nonatomic) NSString* creatorID;

@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *heartButton;
@property (weak, nonatomic) IBOutlet UIButton *flagOffensiveButton;
@property (nonatomic) bool isLiked;
@property ( nonatomic) bool isPlaying;

@property (weak, nonatomic) IBOutlet UINavigationItem *titleBarNavItem;

@property (strong, nonatomic) NSDictionary* itemInfo;

@property (nonatomic) bool beganBuffering;
@property (nonatomic) bool bufferingComplete;

@property (nonatomic,strong) AFURLConnectionOperation* oggDownloadOperation;

@property (nonatomic,strong) IDZAQAudioPlayer* player;

@property (nonatomic,strong) NSURL* oggFileURL;

@end
