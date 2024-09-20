import { NativeModules } from "react-native";
import { IAlbum } from "types/album";
import { IArtist } from "types/artist";
import { CatalogSearchType, ICatalogSearch } from "types/catalog-search";
import { IGenre } from "types/genre";
import { MusicItem } from "types/music-item";
import { IPlaylist } from "types/playlist";
import { ISong } from "types/song";
import { ITracksFromLibrary } from "types/tracks-from-library";

const { MusicModule } = NativeModules;

interface IEndlessListOptions {
  offset?: number;
  limit?: number;
}
class MusicKit {
  /**
   * Searches the Apple Music catalog using the specified search terms, types, and options.
   * @param {string} search - The search query string.
   * @param {CatalogSearchType[]} types - The types of catalog items to search for.
   * @param {IEndlessListOptions} [options] - Additional options for the search.
   * @returns {Promise<ISong[]>} A promise that resolves to the search results.
   */
  public static async catalogSearch(
    search: string,
    types: CatalogSearchType[],
    options?: IEndlessListOptions
  ): Promise<ICatalogSearch | undefined> {
    try {
      return (await MusicModule.catalogSearch(
        search,
        types,
        options
      )) as ICatalogSearch;
    } catch (error) {
      console.error("Apple Music Kit: Catalog Search failed.", error);

      return {
        songs: [],
        albums: [],
      };
    }
  }
  /**
   * @param itemId - ID of collection to be set in a player's queue
   * @param {MusicItem} type - Type of collection to be found and set
   * @returns {Promise<void>} A promise is resolved when tracks successfully added to a queue
   */
  public static async setPlaybackQueue(
    itemId: string,
    type: MusicItem
  ): Promise<void> {
    try {
      await MusicModule.setPlaybackQueue(itemId, type);
    } catch (error) {
      console.error("Apple Music Kit: Setting Playback Failed.", error);
    }
  }
  /**
   * @param itemId - ID of the song to be played
   * @returns {Promise<void>} A promise is resolved when the song is successfully added to a queue
   */
  public static async fetchSongAndPlay(itemId: string): Promise<void> {
    try {
      await MusicModule.fetchSongAndPlay(itemId);
    } catch (error) {
      console.error("Apple Music Kit: Playing Song Failed.", error);
    }
  }
  /**
   * @param itemId - ID of the song to be played
   * @param playlistId - ID of the current playlist
   * @returns {Promise<void>} A promise is resolved when the song is successfully added to a queue
   */
  public static async fetchPlaylistSongAndPlay(
    itemId: string,
    playlistId: string
  ): Promise<void> {
    try {
      await MusicModule.fetchPlaylistSongAndPlay(itemId, playlistId);
    } catch (error) {
      console.error(
        "Apple Music Kit: Playing Song Failed. method fetchPlaylistSongAndPlay",
        error
      );
    }
  }
  /**
   * @param persistentID - ID of collection to be set in a player's queue
   * @param {MusicItem} type - Type of collection to be found and set
   * @returns {Promise<void>} A promise is resolved when tracks successfully added to a queue and plays
   */
  public static async setLocalPlaybackQueue(
    persistentID: string,
    type: MusicItem
  ): Promise<void> {
    try {
      await MusicModule.setLocalPlaybackQueue(persistentID, type);
    } catch (error) {
      console.error("Apple Music Kit: Setting Playback Failed.", error);
    }
  }
  /**
   * @returns {Promise<void>} when tracks are successfully added to a queue
   */
  public static async setLocalPlaybackQueueAll(): Promise<void> {
    try {
      await MusicModule.setLocalPlaybackQueueAll();
    } catch (error) {
      console.error("Apple Music Kit: Setting Playback Failed.", error);
    }
  }
  /**
   * Get a list of recently played items in user's library
   * @return {Promise<ITracksFromLibrary[]>} A promise returns a list of recently played items including tracks, playlists, stations, albums
   */
  public static async getTracksFromLibrary(): Promise<ITracksFromLibrary> {
    try {
      const result = await MusicModule.getTracksFromLibrary();
      return result;
    } catch (error) {
      console.error(
        "Apple Music Kit: Getting tracks from user library failed.",
        error
      );
      return {
        recentlyPlayedItems: [],
      };
    }
  }
  /**
   * Searches the user's Apple Music library songs using the specified options.
   * @param {IEndlessListOptions} [options] - Additional options for the search.
   * @returns {Promise<{items: ISong[]}>} A promise that resolves to the search results.
   */
  public static async getUserLibrarySongs(
    options: IEndlessListOptions
  ): Promise<{ items: ISong[] }> {
    try {
      return await MusicModule.getUserLibrarySongs(options);
    } catch (error) {
      console.error(
        "Apple Music Kit: Failed to fetch user library songs.",
        error
      );
      return { items: [] };
    }
  }
  /**
   * Searches the user's Apple Music library albums using the specified options.
   * @param {IEndlessListOptions} [options] - Additional options for the search.
   * @returns {Promise<{items: IAlbum[]}>} A promise that resolves to the search results.
   */
  public static async getUserLibraryAlbums(
    options: IEndlessListOptions
  ): Promise<{ items: IAlbum[] }> {
    try {
      return await MusicModule.getUserLibraryAlbums(options);
    } catch (error) {
      console.error(
        "Apple Music Kit: Failed to fetch user library albums.",
        error
      );
      return { items: [] };
    }
  }
  /**
   * Searches the user's Apple Music library playlists using the specified options.
   * @param {IEndlessListOptions} [options] - Additional options for the search.
   * @returns {Promise<{items: IPlaylist[]}>} A promise that resolves to the search results.
   */
  public static async getUserLibraryPlaylists(
    options: IEndlessListOptions
  ): Promise<{ items: IPlaylist[] }> {
    try {
      return await MusicModule.getUserLibraryPlaylists(options);
    } catch (error) {
      console.error(
        "Apple Music Kit: Failed to fetch user library playlists.",
        error
      );
      return { items: [] };
    }
  }
  /**
   * Get a list of playlist items in user's library
   * @returns {Promise<{items: ISong[]}>} A promise returns a list of playlist songs
   */
  /**
   * Get a list of playlist items in user's library
   * @returns {Promise<{items: ISong[]}>} A promise returns a list of playlist songs
   */
  public static async getUserLibraryPlaylistSongs(
    playlistId: string
  ): Promise<{ items: ISong[] }> {
    try {
      return await MusicModule.getUserLibraryPlaylistSongs(playlistId);
    } catch (error) {
      console.error(
        "Apple Music Kit: Failed to fetch user library playlist songs.",
        error
      );
      return { items: [] };
    }
  }
  /**
   * Searches the user's Apple Music library artists using the specified options.
   * @param {IEndlessListOptions} [options] - Additional options for the search.
   * @returns {Promise<{items: IArtist[]}>} A promise that resolves to the search results.
   */
  public static async getUserLibraryArtists(
    options: IEndlessListOptions
  ): Promise<{ items: IArtist[] }> {
    try {
      return await MusicModule.getUserLibraryArtists(options);
    } catch (error) {
      console.error(
        "Apple Music Kit: Failed to fetch user library artists.",
        error
      );
      return { items: [] };
    }
  }
  /**
   * Searches the user's Apple Music library genres using the specified options.
   * @param {IEndlessListOptions} [options] - Additional options for the search.
   * @returns {Promise<{items: IGenre[]}>} A promise that resolves to the search results.
   */
  public static async getUserLibraryGenres(
    options: IEndlessListOptions
  ): Promise<{ items: IGenre[] }> {
    try {
      return await MusicModule.getUserLibraryGenres(options);
    } catch (error) {
      console.error(
        "Apple Music Kit: Failed to fetch user library genres.",
        error
      );
      return { items: [] };
    }
  }
}

export { MusicKit as default };
//# sourceMappingURL=music-kit.js.map
