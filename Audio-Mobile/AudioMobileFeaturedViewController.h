//
//  AudioMobileFeaturedViewController.h
//  Audio-Mobile
//
//

#import <UIKit/UIKit.h>
#import "AudioMobileFeaturedItemCellView.h"
#import "AudioMobilePlaybackViewController.h"
#import "AudioMobileAppDelegate.h"

#import "AudioMobileRestAPIManager.h"

#import "IDZAQAudioPlayer.h"

@interface AudioMobileFeaturedViewController : UICollectionViewController<UICollectionViewDelegate,UICollectionViewDataSource>

@property (nonatomic,strong) NSIndexPath* currentlySelectedItemIndex;
@property (nonatomic,strong) NSMutableArray* featuredItems;
@property (nonatomic,strong) NSMutableDictionary* imageCache;
@property (nonatomic) NSUInteger featuredItemPagesRetrieved;

@property (nonatomic, strong) IDZAQAudioPlayer* player;

@property (nonatomic) bool retrieivingItems;


@end
