//
//  AudioMobileConsentViewController.m
//  Audio-Mobile
//
//

#import "AudioMobileConsentViewController.h"
#import "AudioMobileAppDelegate.h"

@interface AudioMobileConsentViewController ()

@end

@implementation AudioMobileConsentViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    NSURL* consentFormURL = [[NSBundle mainBundle] URLForResource:@"AUDIO_MOBILE_APP_Consent_Form" withExtension:@"html"];
    [[self consentWebView] loadData:[NSData dataWithContentsOfURL:consentFormURL] MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}
- (IBAction)userGivesConsent:(id)sender {
    [[AudioMobileAppDelegate sharedInstance] userAcceptsTermsOfUse];
    [self dismissViewControllerAnimated:true completion:nil];
}

@end
