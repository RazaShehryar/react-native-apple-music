// MusicModule.m
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(MusicModule, NSObject)

RCT_EXTERN_METHOD(authorization:(RCTResponseSenderBlock)callback)

RCT_EXTERN_METHOD(checkSubscription:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(catalogSearch:(NSString *)term types:(NSArray<NSString *> *)types options:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getUserLibrarySongs:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getUserLibraryAlbums:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getUserLibraryPlaylists:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getUserLibraryPlaylistSongs:(NSString *)playlistId resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getUserLibraryArtists:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getUserLibraryGenres:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(setPlaybackQueue:(NSString *)itemId type:(NSString *)type resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(setLocalPlaybackQueue:(NSString *)persistentID type:(NSString *)type resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(setLocalPlaybackQueueAll:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getTracksFromLibrary:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(playLocalSongInQueue:(NSString *)persistentID)

RCT_EXTERN_METHOD(fetchSongAndPlay:(NSString *)itemId resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(play)
RCT_EXTERN_METHOD(pause)
RCT_EXTERN_METHOD(stop)
RCT_EXTERN_METHOD(skipToNextEntry)
RCT_EXTERN_METHOD(skipToPreviousEntry)
RCT_EXTERN_METHOD(togglePlayerState)
RCT_EXTERN_METHOD(playLocal)
RCT_EXTERN_METHOD(pauseLocal)
RCT_EXTERN_METHOD(skipLocalToNextEntry)
RCT_EXTERN_METHOD(skipLocalToPreviousEntry)
RCT_EXTERN_METHOD(toggleLocalPlayerState)
RCT_EXTERN_METHOD(getCurrentState:(RCTResponseSenderBlock)callback)
RCT_EXTERN_METHOD(getLocalCurrentState:(RCTResponseSenderBlock)callback)

// Определение, что этот модуль имеет события, которые могут быть отправлены в JavaScript.
// Эта функция сообщает React Native о событиях, которые этот модуль может отправить.
- (NSArray<NSString *> *)supportedEvents {
  return @[@"onPlaybackStateChange", @"onCurrentSongChange", @"onLocalCurrentSongChange"]; // Список событий
}

@end
