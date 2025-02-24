export type { IPlaybackState } from './types/playback-state';

export * from './types/song';

export * from './types/artist';

export * from './types/genre';

export * from './types/playlist';

export * from './types/playback-status';

export * from './types/catalog-search';

export * from './types/auth-status';

export * from './types/check-subscription';

export * from './types/music-item';

export * from './types/tracks-from-library';

import useCurrentSong from './hooks/use-current-song';
import useIsPlaying from './hooks/use-is-playing';
import useLocalCurrentSong from './hooks/use-local-current-song';
import useLocalIsPlaying from './hooks/use-local-is-playing';
import Auth from './modules/auth';
import MusicKit from './modules/music-kit';
import Player from './modules/player';

export {
  useCurrentSong,
  useLocalIsPlaying,
  useLocalCurrentSong,
  useIsPlaying,
  Auth,
  Player,
  MusicKit,
};
