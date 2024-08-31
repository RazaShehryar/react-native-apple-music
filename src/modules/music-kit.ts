import type { IAlbum } from '../types/album';
import type { IArtist } from '../types/artist';
import type { CatalogSearchType, ICatalogSearch } from '../types/catalog-search';
import type { IGenre } from '../types/genre';
import type { MusicItem } from '../types/music-item';
import type { IPlaylist } from '../types/playlist';
import type { ISong } from '../types/song';
import type { ITracksFromLibrary } from '../types/tracks-from-library';

interface IEndlessListOptions {
  offset?: number;
  limit?: number;
}
declare class MusicKit {
  /**
   * Searches the Apple Music catalog using the specified search terms, types, and options.
   * @param {string} search - The search query string.
   * @param {CatalogSearchType[]} types - The types of catalog items to search for.
   * @param {IEndlessListOptions} [options] - Additional options for the search.
   * @returns {Promise<ISong[]>} A promise that resolves to the search results.
   */
  /**
   * Searches the Apple Music catalog using the specified search terms, types, and options.
   * @param {string} search - The search query string.
   * @param {CatalogSearchType[]} types - The types of catalog items to search for.
   * @param {IEndlessListOptions} [options] - Additional options for the search.
   * @returns {Promise<ISong[]>} A promise that resolves to the search results.
   */
  static catalogSearch(
    search: string,
    types: CatalogSearchType[],
    options?: IEndlessListOptions,
  ): Promise<ICatalogSearch | undefined>;
  /**
   * @param itemId - ID of collection to be set in a player's queue
   * @param {MusicItem} type - Type of collection to be found and set
   * @returns {Promise<boolean>} A promise is resolved when tracks successfully added to a queue
   */
  /**
   * @param itemId - ID of collection to be set in a player's queue
   * @param {MusicItem} type - Type of collection to be found and set
   * @returns {Promise<boolean>} A promise is resolved when tracks successfully added to a queue
   */
  static setPlaybackQueue(itemId: string, type: MusicItem): Promise<void>;
  /**
   * @param itemId - ID of the song to be played
   * @returns {Promise<void>} A promise is resolved when the song is successfully added to a queue
   */
  static fetchSongAndPlay(itemId: string): Promise<void>;
  /**
   * @param persistentID - ID of collection to be set in a player's queue
   * @param {MusicItem} type - Type of collection to be found and set
   * @returns {Promise<boolean>} A promise is resolved when tracks successfully added to a queue and played
   */
  /**
   * @param persistentID - ID of collection to be set in a player's queue
   * @param {MusicItem} type - Type of collection to be found and set
   * @returns {Promise<boolean>} A promise is resolved when tracks successfully added to a queue and played
   */
  static setLocalPlaybackQueue(persistentID: string, type: MusicItem): Promise<void>;
  /**
   * @returns {Promise<boolean>} when tracks are successfully added to a queue
   */
  /**
   * @returns {Promise<boolean>} when tracks are successfully added to a queue
   */
  static setLocalPlaybackQueueAll(): Promise<void>;
  /**
   * Get a list of recently played items in user's library
   * @return {Promise<ITracksFromLibrary[]>} A promise returns a list of recently played items including tracks, playlists, stations, albums
   */
  /**
   * Get a list of recently played items in user's library
   * @return {Promise<ITracksFromLibrary[]>} A promise returns a list of recently played items including tracks, playlists, stations, albums
   */
  static getTracksFromLibrary(): Promise<ITracksFromLibrary>;
  /**
   * Get a list of song items in user's library
   * @returns {Promise<{items: ISong[]}>} A promise returns a list of songs
   */
  /**
   * Get a list of song items in user's library
   * @returns {Promise<{items: ISong[]}>} A promise returns a list of songs
   */
  static getUserLibrarySongs(
    options?: IEndlessListOptions,
  ): Promise<{ items: ISong[] } | undefined>;
  /**
   * Get a list of album items in user's library
   * @returns {Promise<{items: IAlbum[]}>} A promise returns a list of albums
   */
  /**
   * Get a list of album items in user's library
   * @returns {Promise<{items: IAlbum[]}>} A promise returns a list of albums
   */
  static getUserLibraryAlbums(
    options?: IEndlessListOptions,
  ): Promise<{ items: IAlbum[] } | undefined>;
  /**
   * Get a list of playlist items in user's library
   * @returns {Promise<{items: ISong[]}>} A promise returns a list of playlist songs
   */
  /**
   * Get a list of playlist items in user's library
   * @returns {Promise<{items: ISong[]}>} A promise returns a list of playlist songs
   */
  static getUserLibraryPlaylistSongs(playlistId: string): Promise<{ items: ISong[] } | undefined>;
  /**
   * Get a list of playlist items in user's library
   * @returns {Promise<{items: IAlbum[]}>} A promise returns a list of playlists
   */
  /**
   * Get a list of playlist items in user's library
   * @returns {Promise<{items: IAlbum[]}>} A promise returns a list of playlists
   */
  static getUserLibraryPlaylists(
    options?: IEndlessListOptions,
  ): Promise<{ items: IPlaylist[] } | undefined>;
  /**
   * Get a list of artist items in user's library
   * @returns {Promise<{items: IAlbum[]}>} A promise returns a list of artists
   */
  /**
   * Get a list of artist items in user's library
   * @returns {Promise<{items: IAlbum[]}>} A promise returns a list of artists
   */
  static getUserLibraryArtists(
    options?: IEndlessListOptions,
  ): Promise<{ items: IArtist[] } | undefined>;
  /**
   * Get a list of genre items in user's library
   * @returns {Promise<{items: IAlbum[]}>} A promise returns a list of genres
   */
  /**
   * Get a list of genre items in user's library
   * @returns {Promise<{items: IAlbum[]}>} A promise returns a list of genres
   */
  static getUserLibraryGenres(
    options?: IEndlessListOptions,
  ): Promise<{ items: IGenre[] } | undefined>;
}

export default MusicKit;
