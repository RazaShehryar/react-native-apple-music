// MusicModule.swift
import Foundation
import React
import StoreKit
import MusicKit
import Combine
import MediaPlayer

let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    
@available(iOS 15.0, *)
@objc(MusicModule)
class MusicModule: RCTEventEmitter {
    
    private var queueObservation: AnyCancellable?
    private var stateObservation: AnyCancellable?
    private var currentPlaybackStatus: MusicKit.MusicPlayer.PlaybackStatus?
    private var lastReportedPlaybackStatus: MusicKit.MusicPlayer.PlaybackStatus?
    
    override init() {
        super.init()
        startObservingPlaybackState()
        startObservingQueueChanges()
        startObservingLocalQueueChanges()
    }
    
    override func supportedEvents() -> [String]! {
        return ["onPlaybackStateChange", "onCurrentSongChange", "onLocalCurrentSongChange"]
    }
    
    private func startObservingPlaybackState() {
        stateObservation = SystemMusicPlayer.shared.state.objectWillChange.sink { [weak self] _ in
            self?.sendPlaybackStateUpdate()
        }
    }
    
    private func startObservingLocalQueueChanges() {
        queueObservation = SystemMusicPlayer.shared.queue.objectWillChange.sink { [weak self] _ in
            self?.sendLocalCurrentSongUpdate()
        }
    }
    
    private func startObservingQueueChanges() {
        queueObservation = SystemMusicPlayer.shared.queue.objectWillChange.sink { [weak self] _ in
            self?.sendCurrentSongUpdate()
        }
    }
    
    private func sendCurrentSongUpdate() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            
            self.getCurrentSongInfo { songInfo in
                if let songInfo = songInfo {
                    self.sendEvent(withName: "onCurrentSongChange", body: ["currentSong": songInfo])
                }
            }
        }
    }
    
    private func sendLocalCurrentSongUpdate() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            
            self.getLocalCurrentSongInfo { songInfo in
                if let songInfo = songInfo {
                    self.sendEvent(withName: "onLocalCurrentSongChange", body: ["currentSong": songInfo])
                }
            }
        }
    }
    
    private func sendPlaybackStateUpdate() {
        let state = SystemMusicPlayer.shared.state
        let playbackTime = SystemMusicPlayer.shared.playbackTime
        let playbackStatusDescription = describePlaybackStatus(state.playbackStatus)
        let playbackRate = state.playbackRate
        
        if lastReportedPlaybackStatus != state.playbackStatus {
            self.getCurrentSongInfo { songInfo in
                var playbackInfo: [String: Any] = [
                    "playbackRate": playbackRate,
                    "playbackStatus": playbackStatusDescription,
                    "playbackTime": playbackTime
                ]
                
                if let songInfo = songInfo {
                    playbackInfo["currentSong"] = songInfo
                }
                
                self.sendEvent(withName: "onPlaybackStateChange", body: playbackInfo)
            }
            
            lastReportedPlaybackStatus = state.playbackStatus
        }
    }
    
    @objc(getLocalCurrentState:)
    func getLocalCurrentState(_ callback: @escaping RCTResponseSenderBlock) {
        let state = musicPlayer.playbackState
        let playbackTime = musicPlayer.currentPlaybackTime
        let playbackStatusDescription = describeLocalPlaybackStatus(state)
        let playbackRate = musicPlayer.currentPlaybackRate
        
        self.getCurrentSongInfo { songInfo in
            var currentState: [String: Any] = [
                "playbackRate": playbackRate,
                "playbackStatus": playbackStatusDescription,
                "playbackTime": playbackTime
            ]
            
            if let songInfo = songInfo {
                currentState["currentSong"] = songInfo
            }
            
            callback([currentState])
        }
    }
    
    @objc(getCurrentState:)
    func getCurrentState(_ callback: @escaping RCTResponseSenderBlock) {
        let state = SystemMusicPlayer.shared.state
        let playbackTime = SystemMusicPlayer.shared.playbackTime
        let playbackStatusDescription = describePlaybackStatus(state.playbackStatus)
        let playbackRate = state.playbackRate
        
        self.getCurrentSongInfo { songInfo in
            var currentState: [String: Any] = [
                "playbackRate": playbackRate,
                "playbackStatus": playbackStatusDescription,
                "playbackTime": playbackTime
            ]
            
            if let songInfo = songInfo {
                currentState["currentSong"] = songInfo
            }
            
            callback([currentState])
        }
    }
    
    private func getLocalCurrentSongInfo(completion: @escaping ([String: Any]?) -> Void) {
        guard let currentEntry = musicPlayer.nowPlayingItem else {
            print("No current entry in the playback queue")
            completion(nil)
            return
        }
        
        Task {
            do {
                let songInfo = try self.convertMPSongToDictionary(currentEntry)
                DispatchQueue.main.async {
                    completion(songInfo)
                }
            }
            catch {
                print("Error requesting song: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
            
        }
    }
    
    private func getCurrentSongInfo(completion: @escaping ([String: Any]?) -> Void) {
        guard let currentEntry = SystemMusicPlayer.shared.queue.currentEntry else {
            print("No current entry in the playback queue")
            completion(nil)
            return
        }
        
        
        switch currentEntry.item {
        case .song(let song):
            Task {
                let songID = song.id
                let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: songID)
                do {
                    let response = try await request.response()
                    if let foundSong = response.items.first {
                        let songInfo = self.convertSongToDictionary(foundSong)
                        DispatchQueue.main.async {
                            completion(songInfo)
                        }
                    } else {
                        print("Song not found in the response.")
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                    }
                } catch {
                    print("Error requesting song: \(error)")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }
            
        case .musicVideo(let musicVideo):
            Task {
                print("The current item is a music video: \(musicVideo.title)")
                
                let request = MusicCatalogResourceRequest<MusicVideo>(matching: \.id, equalTo: musicVideo.id)
                do {
                    let response = try await request.response()
                    if let foundMusicVideo = response.items.first {
                        if #available(iOS 16.0, *) {
                            let songInfo = self.convertMusicVideosToDictionary(foundMusicVideo)
                            DispatchQueue.main.async {
                                completion(songInfo)
                            }
                        } else {
                            print("Update your IOS version to 16.0>")
                            DispatchQueue.main.async {
                                completion(nil)
                            }
                        }
                    } else {
                        print("Music video not found in the response.")
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                    }
                } catch {
                    print("Error requesting music video: \(error)")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }
            
        case .some(let some):
            print("The current item is some item:\(some.id)")
            completion(nil)
            
        default:
            print("The current item is neither a song nor a music video")
            completion(nil)
        }
    }
    
    
    private func describePlaybackStatus(_ status: MusicKit.MusicPlayer.PlaybackStatus) -> String {
        switch status {
        case .playing:
            return "playing"
        case .paused:
            return "paused"
        case .stopped:
            return "stopped"
        case .interrupted:
            return "interrupted"
        case .seekingForward:
            return "seekingForward"
        case .seekingBackward:
            return "seekingBackward"
        default:
            return "unknown"
        }
    }
    
    private func describeLocalPlaybackStatus(_ status: MPMusicPlaybackState) -> String {
        switch status {
        case MPMusicPlaybackState.stopped:
            return "stopped"
        case MPMusicPlaybackState.playing:
            return "playing"
        case MPMusicPlaybackState.paused:
            return "paused"
        case MPMusicPlaybackState.interrupted:
            return "interrupted"
        case MPMusicPlaybackState.seekingForward:
            return "seekingForward"
        case MPMusicPlaybackState.seekingBackward:
            return "seekingBackward"
        default:
            return "unknown"
        }
    }
    
    @objc
    static override func requiresMainQueueSetup() -> Bool {
        return false
    }
    
    @objc(checkSubscription:rejecter:)
    func checkSubscription(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        SKCloudServiceController().requestCapabilities { (capabilities, error) in
            if let error = error {
                reject("ERROR", "Failed to get subscription details: \(error)", error)
                return
            }
            
            let canPlayCatalogContent = capabilities.contains(.musicCatalogPlayback)
            let hasCloudLibraryEnabled = capabilities.contains(.addToCloudMusicLibrary)
            let isMusicCatalogSubscriptionEligible = capabilities.contains(.musicCatalogSubscriptionEligible)
            
            let subscriptionDetails: [String: Any] = [
                "canPlayCatalogContent": canPlayCatalogContent,
                "hasCloudLibraryEnabled": hasCloudLibraryEnabled,
                "isMusicCatalogSubscriptionEligible": isMusicCatalogSubscriptionEligible
            ]
            
            resolve(subscriptionDetails)
        }
    }
    
    @objc(togglePlayerState)
    func togglePlayerState() {
        let playbackState = SystemMusicPlayer.shared.state.playbackStatus
        
        switch playbackState {
        case .playing:
            SystemMusicPlayer.shared.pause()
            musicPlayer.pause()
        case .paused, .stopped, .interrupted:
            Task {
                do {
                    try await SystemMusicPlayer.shared.play()
                    musicPlayer.play()
                } catch {
                    print("Error attempting to play music: \(error)")
                }
            }
        default:
            Task {
                do {
                    try await SystemMusicPlayer.shared.play()
                } catch {
                    print("Error attempting to play music: \(error)")
                }
            }
        }
    }
    
    @objc(toggleLocalPlayerState)
    func toggleLocalPlayerState() {
        let playbackState = musicPlayer.playbackState
        
        switch playbackState {
        case MPMusicPlaybackState.playing:
            musicPlayer.pause()
        case MPMusicPlaybackState.paused, MPMusicPlaybackState.stopped, MPMusicPlaybackState.interrupted:
            musicPlayer.play()
        default:
            musicPlayer.play()
        }
    }
    
    @objc(play)
    func play() {
        Task {
            do {
                try await SystemMusicPlayer.shared.play()
                musicPlayer.play()
            } catch {
                print("Play failed: \(error)")
            }
        }
    }
    
    @objc(playLocal)
    func playLocal() {
        musicPlayer.play()
    }
    
    @objc(pause)
    func pause() {
        SystemMusicPlayer.shared.pause()
    }
    
    @objc(playLocalSongInQueue:)
    func playLocalSongInQueue(withPersistentID persistentID: String) {
        if let queueAsQuery = musicPlayer.value(forKey: "queueAsQuery") as? MPMediaQuery,
               let items = queueAsQuery.items {
        
            for mediaItem in items {
                let mediaItemPersistentID = String(mediaItem.persistentID)
                print("current item id: \(mediaItemPersistentID), incoming id: \(persistentID)")
                           if mediaItemPersistentID == persistentID {
                            musicPlayer.nowPlayingItem = mediaItem
                            musicPlayer.play()
                            return
                        }
                    }
            
            } else {
                print("Failed to retrieve items from the queue.")
            }
    }
    
    @objc(pauseLocal)
    func pauseLocal() {
        musicPlayer.pause()
    }
    
    @objc(skipToNextEntry)
    func skipToNextEntry() {
        Task {
            do {
                try await SystemMusicPlayer.shared.skipToNextEntry()
            } catch {
                print("Next failed: \(error)")
            }
        }
    }
    
    @objc(skipLocalToNextEntry)
    func skipLocalToNextEntry() {
        musicPlayer.skipToNextItem()
    }
    
    @objc(skipToPreviousEntry)
    func skipToPreviousEntry() {
        Task {
            do {
                try await SystemMusicPlayer.shared.skipToPreviousEntry()
            } catch {
                print("Previous failed: \(error)")
            }
        }
    }
    
    @objc(skipLocalToPreviousEntry)
    func skipLocalToPreviousEntry() {
        musicPlayer.skipToPreviousItem()
    }
    
    @objc(authorization:)
    func authorization(_ callback: @escaping RCTResponseSenderBlock) {
        SKCloudServiceController.requestAuthorization { (status) in
            switch status {
            case .authorized:
                callback(["authorized"])
            case .denied:
                callback(["denied"])
            case .notDetermined:
                callback(["notDetermined"])
            case .restricted:
                callback(["restricted"])
            @unknown default:
                callback(["unknown"])
            }
        }
    }
    
    func convertTrackToDictionary(_ track: Song) -> [String: Any] {
        var artworkUrlString: String = ""
        if let artwork = track.artwork {
            let artworkUrl = artwork.url(width: 200, height: 200)
            
            if let url = artworkUrl, url.scheme == "musicKit" {
                print("Artwork URL is a MusicKit URL, may not be directly accessible: \(url)")
            } else {
                artworkUrlString = artworkUrl?.absoluteString ?? ""
            }
        }
        
        return [
            "id": String(describing: track.id),
            "title": track.title,
            "artistName": track.artistName,
            "artworkUrl": artworkUrlString,
            "duration": String(track.duration ?? 0)
        ]
    }
    
    func convertSongToDictionary(_ song: Song) -> [String: Any] {
        var artworkUrlString: String = ""
        if let artwork = song.artwork {
            let artworkUrl = artwork.url(width: 200, height: 200)
            
            if let url = artworkUrl, url.scheme == "musicKit" {
                print("Artwork URL is a MusicKit URL, may not be directly accessible: \(url)")
            } else {
                artworkUrlString = artworkUrl?.absoluteString ?? ""
            }
        }
        
        return [
            "id": String(describing: song.id),
            "title": song.title,
            "artistName": song.artistName,
            "artworkUrl": artworkUrlString,
            "duration": String(song.duration ?? 0)
        ]
    }
    
    func convertMPSongToDictionary(_ song: MPMediaItem) throws -> [String : Any] {
        let artworkUrlString: String = ""
     
        
        return [
            "id": String(describing: song.persistentID),
            "title": song.title ?? "",
            "artistName": song.artist ?? "",
            "artworkUrl": artworkUrlString,
            "duration": String(song.playbackDuration),
            "albumId": String(song.albumPersistentID)
        ]
    }
    
    func convertAlbumToDictionary(_ album: Album) -> [String: Any] {
        var artworkUrlString: String = ""
        
        if let artwork = album.artwork {
            let artworkUrl = artwork.url(width: 200, height: 200)
            
            if let url = artworkUrl, url.scheme == "musicKit" {
                print("Artwork URL is a MusicKit URL, may not be directly accessible: \(url)")
            } else {
                artworkUrlString = artworkUrl?.absoluteString ?? ""
            }
        }
        
        return [
            "id": String(describing: album.id),
            "title": album.title,
            "artistName": album.artistName,
            "artworkUrl": artworkUrlString,
            "trackCount": String(album.trackCount)
        ]
    }
    
    func convertMPAlbumToDictionary(_ album: MPMediaItem) -> [String: Any] {
        let artworkUrlString: String = ""
        
        return [
            "id": String(describing: album.albumPersistentID),
            "title": String(album.albumTitle ?? ""),
            "artistName":String(album.albumArtist ?? ""),
            "artworkUrl": artworkUrlString,
            "trackCount": String(album.albumTrackCount),
            "artistId": String(album.artistPersistentID)
        ]
    }
    
    func convertMPPlaylistToDictionary(_ playlist: MPMediaPlaylist) -> [String: Any] {
        let artworkUrlString: String = ""
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let date = playlist.value(forProperty: "dateCreated")
        
        let dateAddedString = dateFormatter.string(from: date != nil ? date as! Date : Date())
        
       return [
                "id": String(describing: playlist.persistentID),
                "title": playlist.name ?? "",
                "description": playlist.descriptionText ?? "",
                "artworkUrl": artworkUrlString,
                "dateAdded": dateAddedString
            ]
    }
    
    @available(iOS 16.0, *)
    func convertPlaylistToDictionary(_ playlist: Playlist) -> [String: Any] {
        var artworkUrlString: String = ""
        
        if let artwork = playlist.artwork {
            let artworkUrl = artwork.url(width: 200, height: 200)
            
            if let url = artworkUrl, url.scheme == "musicKit" {
                print("Artwork URL is a MusicKit URL, may not be directly accessible: \(url)")
            } else {
                artworkUrlString = artworkUrl?.absoluteString ?? ""
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        
        
        return [
            "id": String(describing: playlist.id),
            "title": playlist.name,
            "description": playlist.description,
            "artworkUrl": artworkUrlString,
            "dateAdded": dateFormatter.string(from: playlist.lastModifiedDate ?? Date())
        ]
    }
    
    func convertArtistToDictionary(_ artist: Artist) -> [String: Any] {
        var artworkUrlString: String = ""
        
        if let artwork = artist.artwork {
            let artworkUrl = artwork.url(width: 200, height: 200)
            
            if let url = artworkUrl, url.scheme == "musicKit" {
                print("Artwork URL is a MusicKit URL, may not be directly accessible: \(url)")
            } else {
                artworkUrlString = artworkUrl?.absoluteString ?? ""
            }
        }
        
        return [
            "id": String(describing: artist.id),
            "title": artist.name,
            "description": artist.description,
            "artworkUrl": artworkUrlString,
            "albumCount": String(artist.albums?.count ?? 0)
        ]
    }
    
    func convertMPArtistToDictionary(_ artist: MPMediaItem) -> [String: Any] {
        let artworkUrlString: String = ""
        
        return [
            "id": String(artist.artistPersistentID == 0 ? artist.albumArtistPersistentID : artist.artistPersistentID),
            "title": String((artist.artist == "" ? artist.albumArtist : artist.artist) ?? ""),
            "description": "",
            "artworkUrl": artworkUrlString,
            "albumCount": "",
        ]
    }
    
    func convertGenreToDictionary(_ genre: Genre) -> [String: Any] {
        return [
            "id": String(describing: genre.id),
            "title": genre.name,
            "description": genre.description,
        ]
    }
    
    @available(iOS 16.0, *)
    func convertMusicItemsToDictionary(_ track: RecentlyPlayedMusicItem) -> [String: Any] {
        var resultCollection: [String: Any] = [
            "id": String(describing: track.id),
            "title": track.title,
            "subtitle": String(describing: track.subtitle ?? "")
        ]
        
        switch track {
        case .album:
            resultCollection["type"] = "album"
            break
        case .playlist:
            resultCollection["type"] = "playlist"
            break
        case .station:
            resultCollection["type"] = "station"
            break
        default:
            resultCollection["type"] = "unknown"
        }
        
        return resultCollection
    }
    
    @available(iOS 16.0, *)
    func convertMusicVideosToDictionary(_ musicVideo: MusicVideo) -> [String: Any] {
        var artworkUrlString: String = ""
        
        if let artwork = musicVideo.artwork {
            let artworkUrl = artwork.url(width: 200, height: 200)
            
            if let url = artworkUrl, url.scheme == "musicKit" {
                print("Artwork URL is a MusicKit URL, may not be directly accessible: \(url)")
            } else {
                artworkUrlString = artworkUrl?.absoluteString ?? ""
            }
        }
        
        return [
            "id": String(describing: musicVideo.id),
            "title": musicVideo.title,
            "artistName": musicVideo.artistName,
            "artworkUrl": artworkUrlString,
            "duration": musicVideo.duration!
        ]
    }
    
    
    @objc(catalogSearch:types:options:resolver:rejecter:)
    func catalogSearch(_ term: String, types: [String], options: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        Task {
            let searchTypes = types.compactMap { typeString -> MusicCatalogSearchable.Type? in
                switch typeString {
                case "songs":
                    return Song.self
                case "albums":
                    return Album.self
                default:
                    return nil
                }
            }
            
            let limit = options["limit"] as? Int ?? 25
            let offset = options["offset"] as? Int ?? 0
            
            var request = MusicCatalogSearchRequest(term: term, types: searchTypes)
            request.limit = limit
            request.offset = offset
            
            do {
                let response = try await request.response()
                print("Response received: \(response)")
                
                let songs = response.songs.compactMap(convertSongToDictionary)
                let albums = response.albums.compactMap(convertAlbumToDictionary)
                
                resolve(["songs": songs, "albums": albums])
            } catch {
                reject("ERROR", "Failed to perform catalog search: \(error)", error)
            }
        }
    }
    
    @objc(fetchSongAndPlay:resolver:rejecter:)
    func fetchSongAndPlay(_ itemId: String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock)
    {
        Task {
            // Replace this with your actual API call logic
            let url = URL(string: "https://api.music.apple.com/v1/me/library/songs/\(itemId)/catalog")!
            
            do {
                let request = MusicDataRequest(urlRequest: URLRequest(url: url))
                let response = try await request.response()
                
                let catalogSongs = try JSONDecoder().decode(MusicItemCollection<Song>.self, from: response.data)
                
                guard let catalogSong = catalogSongs.first else {
                                reject("ERROR", "No songs found", nil)  // Use reject to pass the error context to JS
                                return  // Exit the function since there's no song to play
                            }
                
                let player = SystemMusicPlayer.shared
                
                try await player.queue.insert(catalogSong, position: MusicPlayer.Queue.EntryInsertionPosition.afterCurrentEntry)
                
//                player.queue = [catalogSong] /// <- directly add items to the queue
                try await player.prepareToPlay()
                try await player.play()
                resolve("Song is added to queue")
            } catch {
                reject("ERROR", "Failed to fetch song details: \(error)", error)
            }
        }
    }
    
    
    
    func fetchPlaylistSongs(for playlistId: String) async -> [Song] {
        // Replace this with your actual API call logic
        let url = URL(string: "https://api.music.apple.com/v1/me/library/playlists/\(playlistId)?include=tracks")!
        
        do {
            let request = MusicDataRequest(urlRequest: URLRequest(url: url))
            let response = try await request.response()
            
            let playlists = try JSONDecoder().decode(MusicItemCollection<Playlist>.self, from: response.data)
            guard let playlist = playlists.first else { return [] }
            
            if let tracks = playlist.tracks {
                // Collect all Song objects into an array
                let songs: [Song] = tracks.compactMap { track in
                    if case .song(let song) = track {
                        return song
                    }
                    return nil
                }
                
                // You can now use the `songs` array as needed
                print("These are all the playlist fetched songs \(songs)")
                
                let player = SystemMusicPlayer.shared
                player.queue = [playlist]
                
                return songs
            }
            
            return []
            
        } catch {
            print("Error fetching details for song \(playlistId): \(error)")
            return []
        }
    }
    
    func fetchAlbumDetails(for album: Album) async -> Album? {
        // Replace this with your actual API call logic
        let url = URL(string: "https://api.music.apple.com/v1/me/library/albums/\(album.id.rawValue)")!
        
        do {
            let request = MusicDataRequest(urlRequest: URLRequest(url: url))
            let response = try await request.response()
            
            let catalogAlbums = try JSONDecoder().decode(MusicItemCollection<Album>.self, from: response.data)
            
            guard let catalogAlbum = catalogAlbums.first else { return nil }
            return catalogAlbum
        } catch {
            print("Error fetching details for album \(album.id): \(error)")
            return nil
        }
    }
    
    func fetchAllSongs(limit: Int, offset: Int) async -> [Song] {
        // Replace this with your actual API call logic
        let url = URL(string: "https://api.music.apple.com/v1/me/library/songs?limit=\(limit)&offset=\(offset)")!
        
        do {
            let request = MusicDataRequest(urlRequest: URLRequest(url: url))
            let response = try await request.response()
            
            let decoder = try JSONDecoder().decode(MusicItemCollection<Song>.self, from: response.data)
            
            let result = Array(decoder)
            
            return result
           
        } catch {
            print("Error fetching songs")
            return []
        }
    }
    
    func fetchAllAlbums(limit: Int, offset: Int) async -> [Album] {
        // Replace this with your actual API call logic
        let url = URL(string: "https://api.music.apple.com/v1/me/library/albums?limit=\(limit)&offset=\(offset)")!
        
        do {
            let request = MusicDataRequest(urlRequest: URLRequest(url: url))
            let response = try await request.response()
            
            let decoder = try JSONDecoder().decode(MusicItemCollection<Album>.self, from: response.data)
            
            let result = Array(decoder)
            
            return result
           
        } catch {
            print("Error fetching albums")
            return []
        }
    }
    
    func fetchAllPlaylists(limit: Int, offset: Int) async -> [Playlist] {
        // Replace this with your actual API call logic
        let url = URL(string: "https://api.music.apple.com/v1/me/library/playlists?limit=\(limit)&offset=\(offset)")!
        
        do {
            let request = MusicDataRequest(urlRequest: URLRequest(url: url))
            let response = try await request.response()
            
            let decoder = try JSONDecoder().decode(MusicItemCollection<Playlist>.self, from: response.data)
            
            let result = Array(decoder)
            
            return result
           
        } catch {
            print("Error fetching songs")
            return []
        }
    }
    
    func fetchAllArtists(limit: Int, offset: Int) async -> [Artist] {
        // Replace this with your actual API call logic
        let url = URL(string: "https://api.music.apple.com/v1/me/library/artists?limit=\(limit)&offset=\(offset)")!
        
        do {
            let request = MusicDataRequest(urlRequest: URLRequest(url: url))
            let response = try await request.response()
            
            let decoder = try JSONDecoder().decode(MusicItemCollection<Artist>.self, from: response.data)
            
            let result = Array(decoder)
            
            return result
           
        } catch {
            print("Error fetching songs")
            return []
        }
    }
    
    func fetchPlaylistDetails(for playlist: Playlist) async -> Playlist? {
        // Replace this with your actual API call logic
        let url = URL(string: "https://api.music.apple.com/v1/me/library/playlists/\(playlist.id.rawValue)/catalog")!
        
        do {
            let request = MusicDataRequest(urlRequest: URLRequest(url: url))
            let response = try await request.response()
            
            let catalogPlaylists = try JSONDecoder().decode(MusicItemCollection<Playlist>.self, from: response.data)
            
            guard let catalogPlaylist = catalogPlaylists.first else { return nil }
            return catalogPlaylist
        } catch {
            print("Error fetching details for playlist \(playlist.id): \(error)")
            return nil
        }
    }
    
    func fetchArtistDetails(for artist: Artist) async -> Artist? {
        // Replace this with your actual API call logic
        let url = URL(string: "https://api.music.apple.com/v1/me/library/artists/\(artist.id.rawValue)/catalog")!
        
        do {
            let request = MusicDataRequest(urlRequest: URLRequest(url: url))
            let response = try await request.response()
            
            let catalogArtists = try JSONDecoder().decode(MusicItemCollection<Artist>.self, from: response.data)
            
            guard let catalogArtist = catalogArtists.first else { return nil }
            return catalogArtist
        } catch {
            print("Error fetching details for artist \(artist.id): \(error)")
            return nil
        }
    }
    
    func fetchGenreDetails(for genre: Genre) async -> Genre? {
        // Replace this with your actual API call logic
        let url = URL(string: "https://api.music.apple.com/v1/me/library/genres/\(genre.id.rawValue)/catalog")!
        
        do {
            let request = MusicDataRequest(urlRequest: URLRequest(url: url))
            let response = try await request.response()
            
            let catalogGenres = try JSONDecoder().decode(MusicItemCollection<Genre>.self, from: response.data)
            
            guard let catalogGenre = catalogGenres.first else { return nil }
            return catalogGenre
        } catch {
            print("Error fetching details for genre \(genre.id): \(error)")
            return nil
        }
    }
    
    @available(iOS 16.0, *)
    @objc(getUserLibrarySongs:resolver:rejecter:)
    func getUserLibrarySongs(options: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        Task {
            
            
            let limit = options["limit"] as? Int ?? 100
            let offset = options["offset"] as? Int ?? 0
            
            do {
                
                let query = MPMediaQuery.songs()
                
                let response = await self.fetchAllSongs(limit: limit, offset: offset)
                
                var items = response.compactMap(convertSongToDictionary)
                let songs = try query.items?.compactMap(convertMPSongToDictionary)
                
                for i in 0..<items.count {
                    var item = items[i]
                    
                    if let song = songs!.first(where: { songDict -> Bool in
                        guard
                            let artistName = (songDict["artistName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                            let title = (songDict["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                        else {
                            return false
                        }
                        
                        let appleMusicArtistName = (item["artistName"] as! String).trimmingCharacters(in: .whitespacesAndNewlines)
                        let appleMusicTitle = (item["title"] as! String).trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        print("local artistName: \(artistName), Apple Music artistName: \(appleMusicArtistName), \(artistName == appleMusicArtistName)")
                        
                        print("local title: \(title), Apple Music title: \(appleMusicTitle), \(title == appleMusicTitle)")
                        
                        let result = artistName == appleMusicArtistName && title == appleMusicTitle
                        return result
                    }) {
                        item["localId"] = song["id"]
                        item["albumId"] = song["albumId"]
                    } else {
                        item["localId"] = ""
                        item["albumId"] = ""
                    }
                    items[i] = item
                }
                                
                resolve(["items": items])
            }
        }
    }
    
    
    @available(iOS 16.0, *)
    @objc(getUserLibraryAlbums:resolver:rejecter:)
    func getUserLibraryAlbums(options: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        Task {
            
            
            let limit = options["limit"] as? Int ?? 100
            let offset = options["offset"] as? Int ?? 0
            
            do {
                
                let query = MPMediaQuery.albums()
                
                let response = await self.fetchAllAlbums(limit: limit, offset: offset)
                
                var items = response.compactMap(convertAlbumToDictionary)
                let albums = query.items?.compactMap(convertMPAlbumToDictionary)
                
                for i in 0..<items.count {
                    var item = items[i]
                    
                    if let album = albums!.first(where: { albumDict -> Bool in
                        guard
                            let artistName = (albumDict["artistName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                            let title = (albumDict["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                        else {
                            return false
                        }
                        
                        let appleMusicArtistName = (item["artistName"] as! String).trimmingCharacters(in: .whitespacesAndNewlines)
                        let appleMusicTitle = (item["title"] as! String).trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        print("local artistName: \(artistName), Apple Music artistName: \(appleMusicArtistName), \(artistName == appleMusicArtistName)")
                        
                        print("local title: \(title), Apple Music title: \(appleMusicTitle), \(title == appleMusicTitle)")
                        
                        let result = artistName == appleMusicArtistName && title == appleMusicTitle
                        return result
                    }) {
                        item["localId"] = album["id"]
                        item["artistId"] = album["artistId"]
                    } else {
                        item["localId"] = ""
                        item["artistId"] = ""
                    }
                    items[i] = item
                }
                                
                resolve(["items": items])
            }
        }
    }
    
    @available(iOS 16.0, *)
    @objc(getUserLibraryPlaylists:resolver:rejecter:)
    func getUserLibraryPlaylists(options: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        Task {
            
            
            let limit = options["limit"] as? Int ?? 25
            let offset = options["offset"] as? Int ?? 0
            
            do {
                
//                let query = MPMediaQuery.playlists()
                
                let response = await self.fetchAllPlaylists(limit: limit, offset: offset)
                    
                var items = response.compactMap(convertPlaylistToDictionary)
//                let playlists = query.items?.compactMap(convertMPPlaylistToDictionary)
                
                // Get all the playlists from the query
//                let playlists = query.collections as? [MPMediaPlaylist] ?? []
//                let playlistsDetails = playlists.map { convertMPPlaylistToDictionary($0) }
                
//                for i in 0..<items.count {
//                    var item = items[i]
//                    
//                    if let playlist = playlistsDetails.first(where: { playlistDict -> Bool in
//                        guard
//                            let dateAdded = (playlistDict["dateAdded"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
//                            let title = (playlistDict["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
//                        else {
//                            return false
//                        }
//                        let appleMusicDateAdded = (item["dateAdded"] as! String).trimmingCharacters(in: .whitespacesAndNewlines)
//                        let appleMusicTitle = (item["title"] as! String).trimmingCharacters(in: .whitespacesAndNewlines)
//                        
//                        print("local dateAdded: \(dateAdded), Apple Music dateAdded: \(appleMusicDateAdded), \(dateAdded == appleMusicDateAdded)")
//                        
//                        print("local title: \(title), Apple Music title: \(appleMusicTitle), \(title == appleMusicTitle)")
//                        
//                        let result = dateAdded == appleMusicDateAdded && title == appleMusicTitle
//                        return result
//                    }) {
//                        item["localId"] = playlist["id"]
//                    } else {
//                        item["localId"] = ""
//                    }
//                    items[i] = item
//                }
                
                print("These are the user fetched playlists \(items)")
                
                resolve(["items": items])
            }
        }
    }
    
    @available(iOS 16.0, *)
    @objc(getUserLibraryPlaylistSongs:resolver:rejecter:)
    func getUserLibraryPlaylistSongs(_ persistentID: String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        Task {
            
            do {
                
                let query = MPMediaQuery.songs()
                
                let response = await self.fetchPlaylistSongs(for: persistentID)
                
                var items = response.compactMap(convertTrackToDictionary)
                let songs = try query.items?.compactMap(convertMPSongToDictionary)
                
                print("these are the items: \(items), these are the songs: \(String(describing: songs))")
                
                for i in 0..<items.count {
                    var item = items[i]
                    
                    if let song = songs!.first(where: { songDict -> Bool in
                        guard
                            let artistName = (songDict["artistName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                            let title = (songDict["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                        else {
                            return false
                        }
                        
                        let appleMusicArtistName = (item["artistName"] as! String).trimmingCharacters(in: .whitespacesAndNewlines)
                        let appleMusicTitle = (item["title"] as! String).trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        print("local artistName: \(artistName), Apple Music artistName: \(appleMusicArtistName), \(artistName == appleMusicArtistName)")
                        
                        print("local title: \(title), Apple Music title: \(appleMusicTitle), \(title == appleMusicTitle)")
                        
                        let result = artistName == appleMusicArtistName && title == appleMusicTitle
                        return result
                    }) {
                        item["localId"] = song["id"]
                        item["albumId"] = song["albumId"]
                    } else {
                        item["localId"] = ""
                        item["albumId"] = ""
                    }
                    items[i] = item
                }
                
//                var sortedSongs: [[String: Any]] {
//                    return items.sorted { (first, second) -> Bool in
//                        guard let firstId = first["localId"] as? String, let secondId = second["localId"] as? String else {
//                            return false
//                        }
//                        return firstId < secondId
//                    }
//                }
                                
                resolve(["items": items])
            }
        }
    }
    
    @available(iOS 16.0, *)
    @objc(getUserLibraryArtists:resolver:rejecter:)
    func getUserLibraryArtists(options: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        Task {
            
            
            let limit = options["limit"] as? Int ?? 25
            let offset = options["offset"] as? Int ?? 0
            
            do {
                let query = MPMediaQuery.artists()
                let response = await self.fetchAllArtists(limit: limit, offset: offset)
                                
                var items = response.compactMap(convertArtistToDictionary)
                let artists = query.items?.compactMap(convertMPArtistToDictionary)
                
                print("these are the artists fetched from local: \(String(describing: artists))")
                
                for i in 0..<items.count {
                    var item = items[i]
                    
                    if let artist = artists!.first(where: { albumDict -> Bool in
                        guard
                            let title = (albumDict["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                        else {
                            return false
                        }
        
                        let appleMusicTitle = (item["title"] as! String).trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        print("local title: \(title), Apple Music title: \(appleMusicTitle), \(title == appleMusicTitle)")
                        
                        let result = title == appleMusicTitle
                        return result
                    }) {
                        item["localId"] = artist["id"]
                    } else {
                        item["localId"] = ""
                    }
                    items[i] = item
                }
                
                resolve(["items": items])
            }
        }
    }
    
    @available(iOS 16.0, *)
    @objc(getUserLibraryGenres:resolver:rejecter:)
    func getUserLibraryGenres(options: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        Task {
            
            
            let limit = options["limit"] as? Int ?? 25
            let offset = options["offset"] as? Int ?? 0
            
            do {
                
                let response = await self.fetchAllArtists(limit: limit, offset: offset)
                
                let items = response.compactMap(convertArtistToDictionary)
                
                print("These are the user fetched artists \(items)")
                
                resolve(["items": items])
            }
        }
    }
    
    @available(iOS 16.0, *)
    @objc(getTracksFromLibrary:rejecter:)
    func getTracksFromLibrary(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        Task {
            do {
                let request = MusicRecentlyPlayedContainerRequest()
                let response = try await request.response()
                
                let tracks = response.items.compactMap(convertMusicItemsToDictionary)
                
                resolve(["recentlyPlayedItems": tracks])
            } catch {
                reject("ERROR", "Failed to get recently played tracks: \(error)", error)
            }
        }
    }
    
    @objc(setLocalPlaybackQueue:type:resolver:rejecter:)
    func setLocalPlaybackQueue(_ persistentID: String, type: String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        Task {
            do {
                if (type == "playlist") {
                    // Create a media query for playlists
                       let playlistQuery = MPMediaQuery.playlists()

                       // Fetch all playlists
                       guard let playlists = playlistQuery.collections as? [MPMediaPlaylist] else {
                           print("No playlists found")
                           return []
                       }

                       // Find the playlist with the given persistent ID
                       guard let playlist = playlists.first(where: { String($0.persistentID) == persistentID }) else {
                           print("Playlist with persistent ID \(persistentID) not found")
                           return []
                       }
                    
                    let songs = playlist.items

                    var sortedSongs: [MPMediaItem] {
                        return songs.sorted { $0.persistentID < $1.persistentID }
                    }
                    musicPlayer.setQueue(with: MPMediaItemCollection(items: sortedSongs))
                    try await musicPlayer.prepareToPlay()
                    resolve("Track(s) are added to queue")
                }
                else {
                    let query = MPMediaQuery.songs()
                    let predicate = MPMediaPropertyPredicate(value: persistentID, forProperty: MPMediaItemPropertyAlbumPersistentID)
                    query.addFilterPredicate(predicate)
                    
                    var sortedSongs: [MPMediaItem] {
                        if let items = query.items {
                            return items.sorted { $0.persistentID < $1.persistentID }
                        }
                        return []
                    }
                    
                    musicPlayer.setQueue(with: MPMediaItemCollection(items: sortedSongs))
                    try await musicPlayer.prepareToPlay()
                    resolve("Track(s) are added to queue")
                }
            }
            catch {
                reject("ERROR", "Failed to set tracks to queue: \(error)", error)
            }
            
            return []
            
        }
    }
    
    
    @objc(setLocalPlaybackQueueAll:rejecter:)
    func setLocalPlaybackQueueAll(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        Task {
            do {
                let query = MPMediaQuery.songs()
                musicPlayer.setQueue(with: query)
                try await musicPlayer.prepareToPlay()
                resolve("Track(s) are added to queue")
            }
            catch {
                reject("ERROR", "Failed to set tracks to queue: \(error)", error)
            }
        }
    }
    
    @objc(setPlaybackQueue:type:resolver:rejecter:)
    func setPlaybackQueue(_ itemId: String, type: String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        Task {
            do {
                let musicItemId = MusicItemID.init(itemId)
                
                if let requestType = MediaType.getRequest(forType: type, musicItemId: musicItemId) {
                    switch requestType {
                    case .song(let request):
                        // Use request for song type
                        let response = try await request.response()
                        
                        guard let tracksToBeAdded = response.items.first else { return }
                        
                        let player = SystemMusicPlayer.shared
                        
                        player.queue = [tracksToBeAdded] /// <- directly add items to the queue
                        
                        try await player.prepareToPlay()
                        
                        resolve("Track(s) are added to queue")
                        
                        return
                        
                    case .album(let request):
                        // Use request for album type
                        let response = try await request.response()
                        
                        guard let tracksToBeAdded = response.items.first else { return }
                        
                        let player = SystemMusicPlayer.shared
                        
                        player.queue = [tracksToBeAdded] /// <- directly add items to the queue
                        
                        try await player.prepareToPlay()
                        
                        resolve("Album is added to queue")
                        
                        return
                        
                    case .playlist(let request):
                        // Use request for playlist type
                        let response = try await request.response()
                        
                        guard let tracksToBeAdded = response.items.first else { return }
                        
                        let player = SystemMusicPlayer.shared
                        
                        player.queue = [tracksToBeAdded] /// <- directly add items to the queue
                        
                        try await player.prepareToPlay()
                        
                        resolve("Playlist is added to queue")
                        
                        return
                        
                    case .station(let request):
                        // Use request for station type
                        let response = try await request.response()
                        
                        guard let tracksToBeAdded = response.items.first else { return }
                        
                        let player = SystemMusicPlayer.shared
                        
                        player.queue = [tracksToBeAdded] /// <- directly add items to the queue
                        
                        try await player.prepareToPlay()
                        
                        resolve("Station is added to queue")
                        
                        return
                        
                    }
                } else {
                    print("Unknown media type.")
                    
                    return
                }
            } catch {
                reject("ERROR", "Failed to set tracks to queue: \(error)", error)
            }
        }
    }
    
    enum MediaType {
        case song(MusicCatalogResourceRequest<Song>)
        case album(MusicCatalogResourceRequest<Album>)
        case playlist(MusicCatalogResourceRequest<Playlist>)
        case station(MusicCatalogResourceRequest<Station>)
        
        static func getRequest(forType type: String, musicItemId: MusicItemID) -> MediaType? {
            switch type {
            case "song":
                return .song(MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: musicItemId))
            case "album":
                return .album(MusicCatalogResourceRequest<Album>(matching: \.id, equalTo: musicItemId))
            case "playlist":
                return .playlist(MusicCatalogResourceRequest<Playlist>(matching: \.id, equalTo: musicItemId))
            case "station":
                return .station(MusicCatalogResourceRequest<Station>(matching: \.id, equalTo: musicItemId))
            default:
                return nil
            }
        }
    }
}
