//
//  AudioMobileListenResultsTableViewCell.m
//  Audio-Mobile
//
//

#import "AudioMobileListenResultsTableViewCell.h"

@implementation AudioMobileListenResultsTableViewCell



- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {

    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

}

-(void) prepareForReuse {
    [self setItemInfo:nil];
    [self setOfflineItemIndex:0];
    [self setOfflineItemInfo:nil];
    [self setIsOffline:false];
}

@end
