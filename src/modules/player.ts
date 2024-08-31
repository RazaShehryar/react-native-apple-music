import {
  EmitterSubscription,
  NativeEventEmitter,
  NativeModules,
} from "react-native";
import type { IPlaybackState } from "types/playback-state";
import type { ISong } from "types/song";

const { MusicModule } = NativeModules;
const nativeEventEmitter = new NativeEventEmitter(MusicModule);
interface IPlayerEvents {
  onPlaybackStateChange: IPlaybackState;
  onCurrentSongChange: ISong;
  onLocalCurrentSongChange: ISong;
}
class Player {
  /**
   * Skips to the previous entry in the playback queue.
   */
  public static skipToPreviousEntry(): void {
    MusicModule.skipToPreviousEntry();
  }
  /**
   * Skips to the previous entry in the playback queue.
   */
  public static skipLocalToPreviousEntry(): void {
    MusicModule.skipLocalToPreviousEntry();
  }
  /**
   * Skips to the previous local entry in the playback queue.
   */
  public static skipLocalToNextEntry(): void {
    MusicModule.skipLocalToNextEntry();
  }
  /**
   * Skips to the next entry in the playback queue.
   */
  public static skipToNextEntry(): void {
    MusicModule.skipToNextEntry();
  }
  /**
   * Toggles the local playback state between play and pause.
   */
  public static toggleLocalPlayerState(): void {
    MusicModule.toggleLocalPlayerState();
  }
  /**
   * Toggles the playback state between play and pause.
   */
  public static togglePlayerState(): void {
    MusicModule.togglePlayerState();
  }
  /**
   * Starts local playback of the current song.
   */
  public static playLocal(): void {
    MusicModule.playLocal();
  }
  /**
   * Starts playback of the current song.
   */
  public static play(): void {
    MusicModule.play();
  }
  /**
   * @param persistentID - ID of collection to be set in a player's queue
   * @returns {Promise<boolean>} when tracks successfully plays
   */
  public static async playLocalSongInQueue(
    persistentID: string
  ): Promise<void> {
    MusicModule.playLocalSongInQueue(persistentID);
  }
  /**
   * Pauses local playback of the current song.
   */
  public static pauseLocal(): void {
    MusicModule.pauseLocal();
  }
  /**
   * Pauses playback of the current song.
   */
  public static pause(): void {
    MusicModule.pause();
  }
  /**
   * Retrieves the local current playback state from the native music player.
   * This function returns a promise that resolves to the local current playback state.
   * @returns {Promise<IPlaybackState>} A promise that resolves to the local current playback state of the music player.
   */
  public static getLocalCurrentState(): Promise<IPlaybackState> {
    return new Promise((res, rej) => {
      try {
        MusicModule.getLocalCurrentState(res);
      } catch (error) {
        console.error("Apple Music Kit: getLocalCurrentState failed.", error);
        rej(error);
      }
    });
  }
  /**
   * Retrieves the current playback state from the native music player.
   * This function returns a promise that resolves to the current playback state.
   * @returns {Promise<IPlaybackState>} A promise that resolves to the current playback state of the music player.
   */
  public static getCurrentState(): Promise<IPlaybackState> {
    return new Promise((res, rej) => {
      try {
        MusicModule.getCurrentState(res);
      } catch (error) {
        console.error("Apple Music Kit: getCurrentState failed.", error);

        rej(error);
      }
    });
  }
  /**
   * Method to add a listener for an event.
   * @param eventType - Type of the event to listen for.
   * @param listener - Function to execute when the event is emitted.
   * @returns An EmitterSubscription which can be used to remove the listener.
   */
  public static addListener(
    eventType: keyof IPlayerEvents,
    listener: (eventData: any) => void
  ): EmitterSubscription {
    return nativeEventEmitter.addListener(eventType, listener);
  }
  /**
   * Method to remove all listeners of event
   * @param eventType - Type of the event to remove listener for.
   */
  public static removeAllListeners(eventType: keyof IPlayerEvents): void {
    return nativeEventEmitter.removeAllListeners(eventType);
  }
}

export { Player as default };
//# sourceMappingURL=player.js.map
