//
//  AudioMobileOggVorbisEncoder.h
//  Audio-Mobile
//
//

#import <Foundation/Foundation.h>

enum {
    AMENCODINGSUCCESS = 1,
    AMENCODINGFAILURE = 2,
    
};
typedef NSUInteger AMENCODINGSTATUS;

@protocol AudioMobileOggVorbisEncoderDelegate <NSObject>

-(void) encodingCompletedWithStatus:(AMENCODINGSTATUS)status;

@end

@interface AudioMobileOggVorbisEncoder : NSObject


@property (strong,nonatomic) id<AudioMobileOggVorbisEncoderDelegate> delegate;

-(void) encodeWav:(NSURL*)wavURL toOggVorbisDestination:(NSURL*)oggURL;

@end
