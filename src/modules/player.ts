import type { EmitterSubscription } from 'react-native';
import type { IPlaybackState } from '../types/playback-state.js';
import type { ISong } from '../types/song.js';

interface IPlayerEvents {
  onPlaybackStateChange: IPlaybackState;
  onCurrentSongChange: ISong;
  onLocalCurrentSongChange: ISong;
}
declare class Player {
  /**
   * Skips to the previous local entry in the playback queue.
   */
  /**
   * Skips to the previous local entry in the playback queue.
   */
  static skipLocalToPreviousEntry(): void;
  /**
   * Skips to the previous entry in the playback queue.
   */
  /**
   * Skips to the previous entry in the playback queue.
   */
  static skipToPreviousEntry(): void;
  /**
   * Skips to the next local entry in the playback queue.
   */
  /**
   * Skips to the next local entry in the playback queue.
   */
  static skipLocalToNextEntry(): void;
  /**
   * Skips to the next entry in the playback queue.
   */
  /**
   * Skips to the next entry in the playback queue.
   */
  static skipToNextEntry(): void;
  /**
   * Toggles the local playback state between play and pause.
   */
  /**
   * Toggles the local playback state between play and pause.
   */
  static toggleLocalPlayerState(): void;
  /**
   * Toggles the playback state between play and pause.
   */
  /**
   * Toggles the playback state between play and pause.
   */
  static togglePlayerState(): void;
  /**
   * Starts local playback of the current song.
   */
  /**
   * Starts local playback of the current song.
   */
  static playLocal(): void;
  /**
   * Starts playback of the current song.
   */
  /**
   * Starts playback of the current song.
   */
  static play(): void;
  /**
   * Play a song from the queue.
   */
  /**
   * Play a song from the queue.
   */
  static playLocalSongInQueue(persistentID: string): void;
  /**
   * Pauses local playback of the current song.
   */
  /**
   * Pauses local playback of the current song.
   */
  static pauseLocal(): void;
  /**
   * Pauses playback of the current song.
   */
  /**
   * Pauses playback of the current song.
   */
  static pause(): void;
  /**
   * Retrieves the local current playback state from the native music player.
   * This function returns a promise that resolves to the local current playback state.
   * @returns {Promise<IPlaybackState>} A promise that resolves to the local current playback state of the music player.
   */
  /**
   * Retrieves the local current playback state from the native music player.
   * This function returns a promise that resolves to the local current playback state.
   * @returns {Promise<IPlaybackState>} A promise that resolves to the local current playback state of the music player.
   */
  static getLocalCurrentState(): Promise<IPlaybackState>;
  /**
   * Retrieves the current playback state from the native music player.
   * This function returns a promise that resolves to the current playback state.
   * @returns {Promise<IPlaybackState>} A promise that resolves to the current playback state of the music player.
   */
  /**
   * Retrieves the current playback state from the native music player.
   * This function returns a promise that resolves to the current playback state.
   * @returns {Promise<IPlaybackState>} A promise that resolves to the current playback state of the music player.
   */
  static getCurrentState(): Promise<IPlaybackState>;
  /**
   * Method to add a listener for an event.
   * @param eventType - Type of the event to listen for.
   * @param listener - Function to execute when the event is emitted.
   * @returns An EmitterSubscription which can be used to remove the listener.
   */
  /**
   * Method to add a listener for an event.
   * @param eventType - Type of the event to listen for.
   * @param listener - Function to execute when the event is emitted.
   * @returns An EmitterSubscription which can be used to remove the listener.
   */
  static addListener(
    eventType: keyof IPlayerEvents,
    listener: (eventData: any) => void,
  ): EmitterSubscription;
  /**
   * Method to remove all listeners of event
   * @param eventType - Type of the event to remove listener for.
   */
  /**
   * Method to remove all listeners of event
   * @param eventType - Type of the event to remove listener for.
   */
  static removeAllListeners(eventType: keyof IPlayerEvents): void;
}

export default Player;
