#import "RNSound.h"
#import "RCTUtils.h"
@import MediaPlayer;

@implementation RNSound {
  NSMutableDictionary* _playerPool;
  NSMutableDictionary* _callbackPool;
  AVAudioPlayer* _lastPlayer;
  NSString* _lastKey;
  MPRemoteCommandCenter *_commandCenter;
  NSMutableDictionary* _remotePauseCallbackPool;
  NSMutableDictionary* _remotePlayCallbackPool;
  NSMutableDictionary* _trackInformation;
}
- (id)init
{
    self = [super init];
    if (self)
    {
        _commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
        _commandCenter.playCommand.enabled = YES;
        _commandCenter.pauseCommand.enabled = YES;
        _commandCenter.previousTrackCommand.enabled = YES;
        _commandCenter.nextTrackCommand.enabled = YES;


        //listen for commands
        [_commandCenter.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
            [self play:_lastKey];
            RCTResponseSenderBlock cb = [self remotePlayCallbackForKey:_lastKey];
            if(cb) {
                cb(@[]);
            }
            return MPRemoteCommandHandlerStatusSuccess;
        }];
        [_commandCenter.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
            [self pause:_lastKey];
            RCTResponseSenderBlock cb = [self remotePauseCallbackForKey:_lastKey];
            if(cb) {
                cb(@[]);
            }

            return MPRemoteCommandHandlerStatusSuccess;
        }];
    }
    return self;
}

/**
  Stores track information
 */
-(NSMutableDictionary*) trackInformation {
    if (!_trackInformation) {
        _trackInformation = [NSMutableDictionary new];
    }
    return _trackInformation;
}

-(NSMutableDictionary*) remotePauseCallbackPool {
    if (!_remotePauseCallbackPool) {
        _remotePauseCallbackPool = [NSMutableDictionary new];
    }
    return _remotePauseCallbackPool;
}

-(NSMutableDictionary*) remotePlayCallbackPool {
    if (!_remotePlayCallbackPool) {
        _remotePlayCallbackPool = [NSMutableDictionary new];
    }
    return _remotePlayCallbackPool;
}

-(NSMutableDictionary*) playerPool {
  if (!_playerPool) {
    _playerPool = [NSMutableDictionary new];
  }
  return _playerPool;
}

-(NSMutableDictionary*) callbackPool {
  if (!_callbackPool) {
    _callbackPool = [NSMutableDictionary new];
  }
  return _callbackPool;
}

-(AVAudioPlayer*) playerForKey:(nonnull NSNumber*)key {
  return [[self playerPool] objectForKey:key];
}

-(NSNumber*) keyForPlayer:(nonnull AVAudioPlayer*)player {
  return [[[self playerPool] allKeysForObject:player] firstObject];
}

-(NSMutableDictionary*) trackInfoForKey:(nonnull NSNumber*)key {
    return [[self trackInformation] objectForKey:key];
}

-(RCTResponseSenderBlock) callbackForKey:(nonnull NSNumber*)key {
  return [[self callbackPool] objectForKey:key];
}

-(RCTResponseSenderBlock) remotePauseCallbackForKey:(nonnull NSNumber*)key {
    return [[self remotePauseCallbackPool] objectForKey:key];
}
-(RCTResponseSenderBlock) remotePlayCallbackForKey:(nonnull NSNumber*)key {
    return [[self remotePlayCallbackPool] objectForKey:key];
}

-(NSString *) getDirectory:(int)directory {
  return [NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES) firstObject];
}

-(void) audioPlayerDidFinishPlaying:(AVAudioPlayer*)player
                       successfully:(BOOL)flag {
  NSNumber* key = [self keyForPlayer:player];
  if (key != nil) {
    RCTResponseSenderBlock callback = [self callbackForKey:key];
    if (callback) {
      callback(@[@(flag)]);
    }
  }
}

RCT_EXPORT_MODULE();

-(NSDictionary *)constantsToExport {
  return @{@"MainBundlePath": [[NSBundle mainBundle] bundlePath],
           @"NSDocumentDirectory": [self getDirectory:NSDocumentDirectory],
           @"NSLibraryDirectory": [self getDirectory:NSLibraryDirectory],
           @"NSCachesDirectory": [self getDirectory:NSCachesDirectory],
           };
}

RCT_EXPORT_METHOD(enable:(BOOL)enabled) {
  AVAudioSession *session = [AVAudioSession sharedInstance];
  [session setCategory: AVAudioSessionCategoryAmbient error: nil];
  [session setActive: enabled error: nil];
}

RCT_EXPORT_METHOD(enableInSilenceMode:(BOOL)enabled) {
  AVAudioSession *session = [AVAudioSession sharedInstance];
  [session setCategory: AVAudioSessionCategoryPlayback error: nil];
  [session setActive: enabled error: nil];
}

RCT_EXPORT_METHOD(setCategory:(nonnull NSNumber*)key withValue:(NSString*)categoryName) {
  AVAudioSession *session = [AVAudioSession sharedInstance];
    _lastKey = key;
  if ([categoryName isEqual: @"Ambient"]) {
    [session setCategory: AVAudioSessionCategoryAmbient error: nil];
  } else if ([categoryName isEqual: @"SoloAmbient"]) {
    [session setCategory: AVAudioSessionCategorySoloAmbient error: nil];
  } else if ([categoryName isEqual: @"Playback"]) {
    [session setCategory: AVAudioSessionCategoryPlayback error: nil];
    [session setActive: YES error: nil];
  } else if ([categoryName isEqual: @"Record"]) {
    [session setCategory: AVAudioSessionCategoryRecord error: nil];
  } else if ([categoryName isEqual: @"PlayAndRecord"]) {
    [session setCategory: AVAudioSessionCategoryPlayAndRecord error: nil];
  } else if ([categoryName isEqual: @"AudioProcessing"]) {
    [session setCategory: AVAudioSessionCategoryAudioProcessing error: nil];
  } else if ([categoryName isEqual: @"MultiRoute"]) {
    [session setCategory: AVAudioSessionCategoryMultiRoute error: nil];
  }
}

RCT_EXPORT_METHOD(prepare:(NSString*)fileName withKey:(nonnull NSNumber*)key
                  withTrackOptions: (NSDictionary*) trackInformation
                  withCallback:(RCTResponseSenderBlock)callback) {


  NSError* error;
  AVAudioPlayer* player = [[AVAudioPlayer alloc]
                           initWithContentsOfURL:[NSURL fileURLWithPath:fileName] error:&error];
  if (player) {
      //store track information
      if(trackInformation) {
          [[self trackInformation] setObject:trackInformation forKey:key];
      }


    player.delegate = self;
    [player prepareToPlay];
    [[self playerPool] setObject:player forKey:key];
    callback(@[[NSNull null], @{@"duration": @(player.duration),
                                @"numberOfChannels": @(player.numberOfChannels)}]);
  } else {
    callback(@[RCTJSErrorFromNSError(error)]);
  }
}


-(void) play:(nonnull NSNumber*)key {
    AVAudioPlayer* player = [self playerForKey:key];
    if (player) {
        [player play];
    }
}
RCT_EXPORT_METHOD(play:(nonnull NSNumber*)key withCallback:(RCTResponseSenderBlock)callback) {
  AVAudioPlayer* player = [self playerForKey:key];
  NSDictionary* trackInfo = [self trackInfoForKey:key];

  if (player) {
    [[self callbackPool] setObject:[callback copy] forKey:key];
    [player play];

      if(trackInfo) {
          // set sound properties if defined
          MPNowPlayingInfoCenter *np = [MPNowPlayingInfoCenter defaultCenter];

          np.nowPlayingInfo = @{
                                MPMediaItemPropertyTitle:trackInfo[@"title"],
                                MPMediaItemPropertyArtist:trackInfo[@"artist"],
                                MPMediaItemPropertyPlaybackDuration:[NSNumber numberWithDouble:player.duration],
                                MPNowPlayingInfoPropertyElapsedPlaybackTime: [NSNumber numberWithDouble:player.currentTime]
                                };
      }


  }
}

RCT_EXPORT_METHOD(pause:(nonnull NSNumber*)key) {
  AVAudioPlayer* player = [self playerForKey:key];
  if (player) {
    [player pause];
  }
}

RCT_EXPORT_METHOD(stop:(nonnull NSNumber*)key) {
  AVAudioPlayer* player = [self playerForKey:key];
  if (player) {
    [player stop];
    player.currentTime = 0;
  }
}

RCT_EXPORT_METHOD(release:(nonnull NSNumber*)key) {
  AVAudioPlayer* player = [self playerForKey:key];
  if (player) {
    [player stop];
    [[self callbackPool] removeObjectForKey:player];
    [[self playerPool] removeObjectForKey:key];
  }
}


RCT_EXPORT_METHOD(setVolume:(nonnull NSNumber*)key withValue:(nonnull NSNumber*)value) {
  AVAudioPlayer* player = [self playerForKey:key];
  if (player) {
    player.volume = [value floatValue];
  }
}

RCT_EXPORT_METHOD(setPan:(nonnull NSNumber*)key withValue:(nonnull NSNumber*)value) {
  AVAudioPlayer* player = [self playerForKey:key];
  if (player) {
    player.pan = [value floatValue];
  }
}

RCT_EXPORT_METHOD(setNumberOfLoops:(nonnull NSNumber*)key withValue:(nonnull NSNumber*)value) {
  AVAudioPlayer* player = [self playerForKey:key];
  if (player) {
    player.numberOfLoops = [value intValue];
  }
}

RCT_EXPORT_METHOD(setCurrentTime:(nonnull NSNumber*)key withValue:(nonnull NSNumber*)value) {
  AVAudioPlayer* player = [self playerForKey:key];
  if (player) {
    player.currentTime = [value doubleValue];
  }
}

RCT_EXPORT_METHOD(getCurrentTime:(nonnull NSNumber*)key
                  withCallback:(RCTResponseSenderBlock)callback) {
  AVAudioPlayer* player = [self playerForKey:key];
  if (player) {
    callback(@[@(player.currentTime), @(player.isPlaying)]);
  } else {
    callback(@[@(-1), @(false)]);
  }
}

RCT_EXPORT_METHOD(onRemotePlay: (nonnull NSNumber*)key withCallback:(RCTResponseSenderBlock)callback) {
    [[self remotePlayCallbackPool] setObject:callback forKey:key];
};
RCT_EXPORT_METHOD(onRemotePause: (nonnull NSNumber*)key withCallback:(RCTResponseSenderBlock)callback) {
[[self remotePauseCallbackPool] setObject:callback forKey:key];
};


@end
