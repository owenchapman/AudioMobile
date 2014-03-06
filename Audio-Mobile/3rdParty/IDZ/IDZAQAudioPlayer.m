//
//  IDZAQAudioPlayer.m
//  IDZAQAudioPlayer
//
// Copyright (c) 2013 iOSDeveloperZone.com
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
#import <AudioToolbox/AudioToolbox.h>

#import "IDZAQAudioPlayer.h"
#import "IDZAudioDecoder.h"
#import "IDZTrace.h"

//encoder example imports
#include <vorbis/vorbisenc.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>

#define READ 1024
signed char readbuffer[READ*4+44]; /* out of the data segment, not the stack */


#include "IDZOggVorbisFileDecoder.h"
///encoder



/*
 * Apple uses 3 buffers in the AQPlayer example. We'll do the same.
 * See: http://developer.apple.com/library/ios/#samplecode/SpeakHere/Listings/Classes_AQPlayer_mm.html
 */
#define IDZ_BUFFER_COUNT 3


typedef enum IDZAudioPlayStateTag
{
    IDZAudioPlayerStateStopped,
    IDZAudioPlayerStatePrepared,
    IDZAudioPlayerStatePlaying,
    IDZAudioPlayerStatePaused,
    IDZAudioPlayerStateStopping
    
} IDZAudioPlayerState;

/**
 * @brief IDZAudioPlayer private internals.
 */
@interface IDZAQAudioPlayer ()
{
@private
    AudioQueueRef mQueue;
    AudioQueueBufferRef mBuffers[IDZ_BUFFER_COUNT];
    BOOL mStopping;
    NSTimeInterval mQueueStartTime;
}
/**
 * @brief Queries the value of the Audio Queue's kAudioQueueProperty_IsRunning property.
 */
- (UInt32)queryIsRunning;
/**
 * @brief Reads data from the audio source and enqueues it on the audio queue.
 */
- (void)readBuffer:(AudioQueueBufferRef)buffer;
/**
 * @brief Stops playback
 * @param immediate if YES playback stops immediately, otherwise playback stops after all enqueued buffers 
 * have finished playing.
 */
- (BOOL)stop:(BOOL)immediate;
/**
 * @brief YES if the player is playing, NO otherwise.
 */
@property (readwrite, getter=isPlaying) BOOL playing;
/**
 * @brief The decoder associated with this player.
 */
@property (readonly, strong) id<IDZAudioDecoder> decoder;
/**
 * @brief The current player state.
 */
@property (nonatomic, assign) IDZAudioPlayerState state;
@end


@implementation IDZAQAudioPlayer
@dynamic currentTime;
@dynamic numberOfChannels;
@dynamic duration;
@synthesize playing = mPlaying;
@synthesize decoder = mDecoder;
@synthesize state = mState;

// MARK: - Static Callbacks
static void IDZOutputCallback(void *                  inUserData,
                              AudioQueueRef           inAQ,
                              AudioQueueBufferRef     inCompleteAQBuffer)
{
    IDZAQAudioPlayer* pPlayer = (__bridge IDZAQAudioPlayer*)inUserData;
    [pPlayer readBuffer:inCompleteAQBuffer];
    AudioQueueLevelMeterState levelMeterState[2];
    UInt32 levelMeterStateSize = sizeof(levelMeterState);
    
    
    OSStatus status = AudioQueueGetProperty(inAQ, kAudioQueueProperty_CurrentLevelMeter, &levelMeterState, &levelMeterStateSize);
    //        NSAssert(status == noErr, @"Audio queue property query successful.");
    NSLog(@"level meter state is: average: %f, peak: %f",levelMeterState[0].mAveragePower,levelMeterState[0].mPeakPower);
    UInt32 levelMeteringEnabled;
    UInt32 levelMeteringEnabledSize = sizeof(levelMeteringEnabled);
    status = AudioQueueGetProperty(inAQ, kAudioQueueProperty_EnableLevelMetering, &levelMeteringEnabled, &levelMeteringEnabledSize);
    NSLog(@"Is level metering enabled? %d",levelMeteringEnabled);
    
    if (levelMeteringEnabled == 0) {
        UInt32 enableLevelMetering = 1;
        AudioQueueSetProperty(inAQ, kAudioQueueProperty_EnableLevelMetering, &enableLevelMetering, levelMeteringEnabledSize);
        //            status = AudioQueueSetProperty(inAQ, kAudioQueueProperty_EnableLevelMetering, 1, levelMeteringEnabledSize);
    }
    
}

static void IDZPropertyListener(void* inUserData,
                                AudioQueueRef inAQ,
                                AudioQueuePropertyID inID)
{
    IDZAQAudioPlayer* pPlayer = (__bridge IDZAQAudioPlayer*)inUserData;
    if(inID == kAudioQueueProperty_IsRunning)
    {
        UInt32 isRunning = [pPlayer queryIsRunning];
        NSLog(@"isRunning = %lu", isRunning);
        BOOL bDidFinish = (pPlayer.playing && !isRunning);
        pPlayer.playing = isRunning ? YES : NO;
        if(bDidFinish)
        {
            [pPlayer.delegate audioPlayerDidFinishPlaying:pPlayer
                                              successfully:YES];
            /*
             * To match AVPlayer's behavior we need to reset the file.
             */
            pPlayer.currentTime = 0;
        }
        if(!isRunning)
            pPlayer.state = IDZAudioPlayerStateStopped;
    }
    
}


-(void) changeDecoder:(id<IDZAudioDecoder>)decoder error:(NSError *__autoreleasing *)error  {
    NSParameterAssert(decoder);
//    if(self)
    {
        mDecoder = decoder;
        AudioStreamBasicDescription dataFormat = decoder.dataFormat;
        OSStatus status = AudioQueueNewOutput(&dataFormat, IDZOutputCallback,
                                              (__bridge void*)self,
                                              CFRunLoopGetCurrent(),
                                              kCFRunLoopCommonModes,
                                              0,
                                              &mQueue);
        NSAssert(status == noErr, @"Audio queue creation was successful.");
        AudioQueueSetParameter(mQueue, kAudioQueueParam_Volume, 1.0);
        status = AudioQueueAddPropertyListener(mQueue, kAudioQueueProperty_IsRunning,
                                               IDZPropertyListener, (__bridge void*)self);
        
        for(int i = 0; i < IDZ_BUFFER_COUNT; ++i)
        {
            UInt32 bufferSize = 128 * 1024;
            status = AudioQueueAllocateBuffer(mQueue, bufferSize, &mBuffers[i]);
            if(status != noErr)
            {
                if(*error)
                {
                    *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
                }
                AudioQueueDispose(mQueue, true);
                mQueue = 0;
                NSLog(@"error changing decoder");
                return;
            }
            
        }
    }
    mState = IDZAudioPlayerStateStopped;
    mQueueStartTime = 0.0;
}

- (id)initWithDecoder:(id<IDZAudioDecoder>)decoder error:(NSError *__autoreleasing *)error  
{
    NSParameterAssert(decoder);
    if(self = [super init])
    {
        mDecoder = decoder;
        AudioStreamBasicDescription dataFormat = decoder.dataFormat;
        OSStatus status = AudioQueueNewOutput(&dataFormat, IDZOutputCallback,
                                              (__bridge void*)self,
                                              CFRunLoopGetCurrent(),
                                              kCFRunLoopCommonModes,
                                              0,
                                              &mQueue);
        NSAssert(status == noErr, @"Audio queue creation was successful.");
        AudioQueueSetParameter(mQueue, kAudioQueueParam_Volume, 1.0);
        status = AudioQueueAddPropertyListener(mQueue, kAudioQueueProperty_IsRunning,
                                               IDZPropertyListener, (__bridge void*)self);
        
        for(int i = 0; i < IDZ_BUFFER_COUNT; ++i)
        {
            UInt32 bufferSize = 128 * 1024;
            status = AudioQueueAllocateBuffer(mQueue, bufferSize, &mBuffers[i]);
            if(status != noErr)
            {
                if(*error)
                {
                    *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
                }
                AudioQueueDispose(mQueue, true);
                mQueue = 0;
                return nil;
            }
            
        }
    }
    mState = IDZAudioPlayerStateStopped;
    mQueueStartTime = 0.0;
    return self;
}

- (BOOL)prepareToPlay
{
    for(int i = 0; i < IDZ_BUFFER_COUNT; ++i)
    {
        [self readBuffer:mBuffers[i]];
    }
    self.state = IDZAudioPlayerStatePrepared;
    return YES;
}
//Encoding function based on example on xiph.org site
-(BOOL) encode {
    ogg_stream_state os; /* take physical pages, weld into a logical
                          stream of packets */
    ogg_page         og; /* one Ogg bitstream page.  Vorbis packets are inside */
    ogg_packet       op; /* one raw packet of data for decode */
    
    vorbis_info      vi; /* struct that stores all the static vorbis bitstream
                          settings */
    vorbis_comment   vc; /* struct that stores all the user comments */
    
    vorbis_dsp_state vd; /* central working state for the packet->PCM decoder */
    vorbis_block     vb; /* local working space for packet->PCM decode */
    
    int eos=0,ret;
    int i, founddata;
    
    FILE* wavIn;
    FILE* vorbOut;
    
//    NSString* wavFilePath =[[[NSBundle mainBundle] URLForResource:@"cricket" withExtension:@"wav"] path];
    NSString* wavFilePath =[[[NSBundle mainBundle] URLForResource:@"pinkunoizu" withExtension:@"wav"] path];
//    NSData* wavData = [NSData dataWithContentsOfFile:wavFilePath ] ;
    NSArray *paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* vorbFilePath = [documentsDirectory stringByAppendingPathComponent:@"out.ogg"];
    
    wavIn = fopen([wavFilePath UTF8String], "r");
    NSAssert(wavIn, @"fopen wave file succeeded.");
    
    vorbOut = fopen([vorbFilePath UTF8String], "w");
    NSAssert(vorbOut, @"fopen vorbis out file succeeded.");
    
    NSDateFormatter *formatter;
    
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd-MM-yyyy HH:mm"];
    
    NSLog(@"start encoding at %@",[formatter stringFromDate:[NSDate date]]);
    
#if defined(macintosh) && defined(__MWERKS__)
    int argc = 0;
    char **argv = NULL;
    argc = ccommand(&argv); /* get a "command line" from the Mac user */
    /* this also lets the user set stdin and stdout */
#endif
    
    /* we cheat on the WAV header; we just bypass 44 bytes (simplest WAV
     header is 44 bytes) and assume that the data is 44.1khz, stereo, 16 bit
     little endian pcm samples. This is just an example, after all. */
    
#ifdef _WIN32 /* We need to set stdin/stdout to binary mode. Damn windows. */
    /* if we were reading/writing a file, it would also need to in
     binary mode, eg, fopen("file.wav","wb"); */
    /* Beware the evil ifdef. We avoid these where we can, but this one we
     cannot. Don't add any more, you'll probably go to hell if you do. */
    _setmode( _fileno( stdin ), _O_BINARY );
    _setmode( _fileno( stdout ), _O_BINARY );
#endif
    
    
    /* we cheat on the WAV header; we just bypass the header and never
     verify that it matches 16bit/stereo/44.1kHz.  This is just an
     example, after all. */
    //TODO fix this kludge
    readbuffer[0] = '\0';
    
    feof(wavIn);
    for (i=0, founddata=0; i<30 && ! feof(wavIn) && ! ferror(wavIn); i++)
    {
        fread(readbuffer,1,2,wavIn);
        
        if ( ! strncmp((char*)readbuffer, "da", 2) ){
            founddata = 1;
            fread(readbuffer,1,6,wavIn);
            break;
        }
    }
    
    /********** Encode setup ************/
    
    vorbis_info_init(&vi);
    
    /* choose an encoding mode.  A few possibilities commented out, one
     actually used: */
    
    /*********************************************************************
     Encoding using a VBR quality mode.  The usable range is -.1
     (lowest quality, smallest file) to 1. (highest quality, largest file).
     Example quality mode .4: 44kHz stereo coupled, roughly 128kbps VBR
     
     ret = vorbis_encode_init_vbr(&vi,2,44100,.4);
     
     ---------------------------------------------------------------------
     
     Encoding using an average bitrate mode (ABR).
     example: 44kHz stereo coupled, average 128kbps VBR
     
     ret = vorbis_encode_init(&vi,2,44100,-1,128000,-1);
     
     ---------------------------------------------------------------------
     
     Encode using a quality mode, but select that quality mode by asking for
     an approximate bitrate.  This is not ABR, it is true VBR, but selected
     using the bitrate interface, and then turning bitrate management off:
     
     ret = ( vorbis_encode_setup_managed(&vi,2,44100,-1,128000,-1) ||
     vorbis_encode_ctl(&vi,OV_ECTL_RATEMANAGE2_SET,NULL) ||
     vorbis_encode_setup_init(&vi));
     
     *********************************************************************/
    
    ret=vorbis_encode_init_vbr(&vi,2,44100,0.1);
    
    /* do not continue if setup failed; this can happen if we ask for a
     mode that libVorbis does not support (eg, too low a bitrate, etc,
     will return 'OV_EIMPL') */
    
    if(ret)exit(1);
    
    /* add a comment */
    vorbis_comment_init(&vc);
    vorbis_comment_add_tag(&vc,"ENCODER","encoder_example.c");
    
    /* set up the analysis state and auxiliary encoding storage */
    vorbis_analysis_init(&vd,&vi);
    vorbis_block_init(&vd,&vb);
    
    /* set up our packet->stream encoder */
    /* pick a random serial number; that way we can more likely build
     chained streams just by concatenation */
    srand(time(NULL));
    ogg_stream_init(&os,rand());
    
    /* Vorbis streams begin with three headers; the initial header (with
     most of the codec setup parameters) which is mandated by the Ogg
     bitstream spec.  The second header holds any comment fields.  The
     third header holds the bitstream codebook.  We merely need to
     make the headers, then pass them to libvorbis one at a time;
     libvorbis handles the additional Ogg bitstream constraints */
    
    {
        ogg_packet header;
        ogg_packet header_comm;
        ogg_packet header_code;
        
        vorbis_analysis_headerout(&vd,&vc,&header,&header_comm,&header_code);
        ogg_stream_packetin(&os,&header); /* automatically placed in its own
                                           page */
        ogg_stream_packetin(&os,&header_comm);
        ogg_stream_packetin(&os,&header_code);
        
        /* This ensures the actual
         * audio data will start on a new page, as per spec
         */
        while(!eos){
            int result=ogg_stream_flush(&os,&og);
            if(result==0)break;
            fwrite(og.header,1,og.header_len,vorbOut);
            fwrite(og.body,1,og.body_len,vorbOut);
            
//            fwrite(og.header,1,og.header_len,stdout);
//            fwrite(og.body,1,og.body_len,stdout);
            
        }
        
    }
    
    while(!eos){
        long i;
        
        
        long bytes=fread(readbuffer,1,READ*4,wavIn); /* stereo hardwired here */
        
//        NSData* wavData = [NSData dataWithContentsOfFile:[[[NSBundle mainBundle] URLForResource:@"cricket" withExtension:@"wav"] path] ] ;
        
//        long bytes = [[NSNumber numberWithUnsignedInteger:[wavData length]] longValue] ;
        
        if(bytes==0){
            /* end of file.  this can be done implicitly in the mainline,
             but it's easier to see here in non-clever fashion.
             Tell the library we're at end of stream so that it can handle
             the last frame and mark end of stream in the output properly */
            vorbis_analysis_wrote(&vd,0);
            
        }else{
            /* data to encode */
            
            /* expose the buffer to submit data */
            float **buffer=vorbis_analysis_buffer(&vd,READ);
            
            /* uninterleave samples */
            for(i=0;i<bytes/4;i++){
                buffer[0][i]=((readbuffer[i*4+1]<<8)|
                              (0x00ff&(int)readbuffer[i*4]))/32768.f;
                buffer[1][i]=((readbuffer[i*4+3]<<8)|
                              (0x00ff&(int)readbuffer[i*4+2]))/32768.f;
            }
            
            /* tell the library how much we actually submitted */
            vorbis_analysis_wrote(&vd,i);
        }
        
        /* vorbis does some data preanalysis, then divvies up blocks for
         more involved (potentially parallel) processing.  Get a single
         block for encoding now */
        while(vorbis_analysis_blockout(&vd,&vb)==1){
            
            /* analysis, assume we want to use bitrate management */
            vorbis_analysis(&vb,NULL);
            vorbis_bitrate_addblock(&vb);
            
            while(vorbis_bitrate_flushpacket(&vd,&op)){
                
                /* weld the packet into the bitstream */
                ogg_stream_packetin(&os,&op);
                
                /* write out pages (if any) */
                while(!eos){
                    int result=ogg_stream_pageout(&os,&og);
                    if(result==0)break;
                    fwrite(og.header,1,og.header_len,vorbOut);
                    fwrite(og.body,1,og.body_len,vorbOut);
                    
                    /* this could be set above, but for illustrative purposes, I do
                     it here (to show that vorbis does know where the stream ends) */
                    
                    if(ogg_page_eos(&og))eos=1;
                }
            }
        }
    }
    
    /* clean up and exit.  vorbis_info_clear() must be called last */
    
    ogg_stream_clear(&os);
    vorbis_block_clear(&vb);
    vorbis_dsp_clear(&vd);
    vorbis_comment_clear(&vc);
    vorbis_info_clear(&vi);
    
    /* ogg_page and ogg_packet structs always point to storage in
     libvorbis.  They're never freed or manipulated directly */
    
//    fprintf(stderr,"Done.\n");
    NSLog(@"Done");
    NSLog(@"end encoding at %@",[formatter stringFromDate:[NSDate date]]);
    
    fclose(vorbOut); //TODO ensure this file is closed/cleaned up in other branches of this function.
    
//    [formatter release];
    
    NSURL* vorbFileURL = [NSURL fileURLWithPath:vorbFilePath];
    NSLog(@"vorb file url is %@",vorbFileURL);
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:vorbFilePath]) {
        NSLog(@"file doesn't exist at path: %@",vorbFilePath);
    }
    else {
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:vorbFilePath error:nil];
        
        NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
        long long fileSize = [fileSizeNumber longLongValue];
        NSLog(@"size of output ogg file is: %@",fileSizeNumber);
    }
    
    

    
        IDZOggVorbisFileDecoder* decoder = [[IDZOggVorbisFileDecoder alloc] initWithContentsOfURL:vorbFileURL error:nil];
    [self changeDecoder:decoder error:nil];
    return(0);
    
}

- (BOOL)play
{
    switch(self.state)
    {
        case IDZAudioPlayerStatePlaying:
            return NO;
        case IDZAudioPlayerStatePaused:
        case IDZAudioPlayerStatePrepared:
            break;
        default:
            [self prepareToPlay];
    }
    OSStatus osStatus = AudioQueueStart(mQueue, NULL);
    NSAssert(osStatus == noErr, @"AudioQueueStart failed");
    self.state = IDZAudioPlayerStatePlaying;
    self.playing = YES;
    return (osStatus == noErr);
    
}
- (BOOL)pause
{
    if(self.state != IDZAudioPlayerStatePlaying) return NO;
    OSStatus osStatus = AudioQueuePause(mQueue);
    NSAssert(osStatus == noErr, @"AudioQueuePause failed");
    self.state = IDZAudioPlayerStatePaused;
    return (osStatus == noErr);
    
    
}

- (BOOL)stop
{
    return [self stop:YES];
}

- (BOOL)stop:(BOOL)immediate
{
    self.state = IDZAudioPlayerStateStopping;
    OSStatus osStatus = AudioQueueStop(mQueue, immediate);

    NSAssert(osStatus == noErr, @"AudioQueueStop failed");
    return (osStatus == noErr);    
}

- (void)readBuffer:(AudioQueueBufferRef)buffer
{
    if(self.state == IDZAudioPlayerStateStopping)
        return;
    
    NSAssert(self.decoder, @"self.decoder is valid.");
    if([self.decoder readBuffer:buffer])
    {
        OSStatus status = AudioQueueEnqueueBuffer(mQueue, buffer, 0, 0);
        if(status != noErr)
        {
            NSLog(@"Error: %s status=%ld", __PRETTY_FUNCTION__, status);
        }
    }
    else
    {
        /*
         * Signal to the audio queue that we have run out of data,
         * but set the immediate flag to false so that playback of
         * currently enqueued buffers completes.
         */
        self.state = IDZAudioPlayerStateStopping;
        Boolean immediate = false;
        AudioQueueStop(mQueue, immediate);
    }
}

// MARK: - Properties

- (UInt32)queryIsRunning
{
    UInt32 oRunning = 0;
    UInt32 ioSize = sizeof(oRunning);
    OSStatus result = AudioQueueGetProperty(mQueue, kAudioQueueProperty_IsRunning, &oRunning, &ioSize);
    return oRunning;
}
- (NSTimeInterval)duration
{
    NSTimeInterval duration = mDecoder.duration;
    return duration;
}

- (NSTimeInterval)currentTime
{
    
    AudioTimeStamp outTimeStamp;
    Boolean outTimelineDiscontinuity;
    /*
     * can fail with -66678
     */
    OSStatus status = AudioQueueGetCurrentTime(mQueue, NULL, &outTimeStamp, &outTimelineDiscontinuity);
    NSTimeInterval currentTime;
    switch(status)
    {
        case noErr:
            currentTime = (NSTimeInterval)outTimeStamp.mSampleTime/self.decoder.dataFormat.mSampleRate + mQueueStartTime;
            break;
        case kAudioQueueErr_InvalidRunState:
            currentTime = 0.0;
            break;
        default:
            currentTime = -1.0;
            
    }
    return mQueueStartTime + currentTime;
}

- (void)setCurrentTime:(NSTimeInterval)currentTime
{
    IDZAudioPlayerState previousState = self.state;
    switch(self.state)
    {
        case IDZAudioPlayerStatePlaying:
            [self stop:YES];
            break;
        default:
            break;
    }
    [self.decoder seekToTime:currentTime error:nil];
    mQueueStartTime = currentTime;
    switch(previousState)
    {
        case IDZAudioPlayerStatePrepared:
            [self prepareToPlay];
            break;
        case IDZAudioPlayerStatePlaying:
            [self play];
            break;
        default:
            break;
    }
}

- (NSUInteger)numberOfChannels
{
    return self.decoder.dataFormat.mChannelsPerFrame;
}


- (void)setState:(IDZAudioPlayerState)state
{
    switch(state)
    {
        case IDZAudioPlayerStatePaused:
            NSLog(@"IDZAudioPlayerStatePaused");
            break;
        case IDZAudioPlayerStatePlaying:
            NSLog(@"IDZAudioPlayerStatePlaying");
            break;
        case IDZAudioPlayerStatePrepared:
            NSLog(@"IDZAudioPlayerStatePrepared");
            break;
        case IDZAudioPlayerStateStopped:
            NSLog(@"IDZAudioPlayerStateStopped");
            break;
        case IDZAudioPlayerStateStopping:
            NSLog(@"IDZAudioPlayerStateStopping");
            break;
    }
    mState = state;
}
@end
