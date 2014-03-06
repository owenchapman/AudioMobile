//
//  AudioMobileRecordTabViewController.h
//  Audio-Mobile
//
//

#import <UIKit/UIKit.h>

enum {
    AMFLASHMODEAUTO = 0,
    AMFLASHMODEON = 1,
    AMFLASHMODEOFF = 2
    
};
typedef NSUInteger AMFLASHMODE;

@interface AudioMobileRecordTabViewController : UIViewController<UIImagePickerControllerDelegate,UIAlertViewDelegate>

@property (assign, nonatomic) UIImagePickerController* cameraPicker;
@property (assign, nonatomic) UIImage* imageToDisplay;
@property (weak, nonatomic) IBOutlet UIView *cameraPaneContainerView;
@property (weak, nonatomic) IBOutlet UIButton *flashButton;
@property (nonatomic) AMFLASHMODE flashMode;
@property (weak, nonatomic) IBOutlet UIButton *takePictureButton;

@end
