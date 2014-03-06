//
//  AudioMobileFeaturedItemCellView.h
//  Audio-Mobile
//
//

#import <UIKit/UIKit.h>
#import "AudioMobileAppDelegate.h"

@interface AudioMobileFeaturedItemCellView : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (nonatomic, assign) UIColor* customViewColor;
@property (nonatomic,assign) NSString* title;
@property (nonatomic,assign) NSString* creatorName;

@property (weak, nonatomic) IBOutlet UILabel *creatorNameLabel;
@property (strong, nonatomic) UIImage* nodeMainImage;

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;


@property (strong, nonatomic) NSURL* nodeMainImageURL;

@property (strong, nonatomic) NSString* creatorID;

@property (nonatomic) NSUInteger featuredItemIndex;

-(void) setLabelAlpha:(CGFloat) alpha;

-(void) cachedImageAvailableForURL:(NSURL*)imageURL;

@end
