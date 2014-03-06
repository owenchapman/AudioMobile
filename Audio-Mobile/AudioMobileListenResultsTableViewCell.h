//
//  AudioMobileListenResultsTableViewCell.h
//  Audio-Mobile
//
//

#import <UIKit/UIKit.h>
#import "AudioMobileDataModel.h"

@interface AudioMobileListenResultsTableViewCell : UITableViewCell

@property (strong,nonatomic) NSDictionary* itemInfo;
@property (nonatomic) bool isOffline;
@property (nonatomic, strong) AudioNode1* offlineItemInfo;
@property (nonatomic) NSUInteger offlineItemIndex;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailView;


@end
