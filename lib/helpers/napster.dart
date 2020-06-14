import 'dart:convert';
import "package:http/http.dart" as http;

import "./generateUri.dart";
import "../apiKeys.dart";

class NapsterAlbumData {
  String id;
  String name;

  NapsterAlbumData({this.id, this.name});

  toString() {
    return "{\n\tid: $id,\n\tname: $name\n}";
  }
}

class NapsterSongData {
  String artist;
  String title;
  int length;
  String thumbnail;
  String albumId;

  NapsterSongData({
    this.artist,
    this.length,
    this.albumId,
    this.thumbnail,
    this.title,
  });

  toString() {
    return "{\n\tartist: $artist,\n\ttitle: $title,\n\talbumId: $albumId,\n\tlength: $length,\n\tthumbnail: $thumbnail\n}";
  }
}

/// getAlbumInfo()
///
/// @param {string} albumId The id of the album
///
/// Gets the info for an album
Future<NapsterAlbumData> getAlbumInfo(String albumId) async {
  try {
    var response = await http
        .get(generateUri("https://api.napster.com/v2.2/albums/${albumId}", {
      "apikey": NAPSTER_API_KEY,
    }));

    if (response.statusCode != 200) throw response.headers["status"];

    return formatAlbumData(jsonDecode(response.body)["albums"][0]);
  } catch (error) {
    print(error);
    return null;
  }
}

/// getSongInfo()
///
/// @param {string} query The search term
///
/// Gets the info for only one particular song, and downloads the thumbnail for it
Future<NapsterSongData> getSongInfo(String query) async {
  try {
    var response =
        await http.get(generateUri("https://api.napster.com/v2.2/search", {
      "apikey": NAPSTER_API_KEY,
      "type": "track",
      "per_type_limit": "1",
      "query": query,
    }));
    if (response.statusCode != 200) throw response.headers["status"];

    var track = jsonDecode(response.body)["search"]["data"]["tracks"][0];

    return formatTrackData(track);
  } catch (error) {
    print(error);
    return null;
  }
}

/// search()
///
/// @param {string} query The search query
///
/// Returns the top 10 songs which fit the query
Future<List<NapsterSongData>> search(String query) async {
  try {
    var response =
        await http.get(generateUri("https://api.napster.com/v2.2/search", {
      "apikey": NAPSTER_API_KEY,
      "type": "track",
      "per_type_limit": "10",
      "query": query,
    }));

    if (response.statusCode != 200) throw response.headers["status"];

    var songs = <NapsterSongData>[];

    jsonDecode(response.body)["search"]["data"]["tracks"].forEach((track) {
      songs.add(formatTrackData(track));
    });

    return songs;
  } catch (error) {
    print(error);
    return null;
  }
}

/// formatAlbumData()
///
/// @param data The album object returned by napster api
///
/// Returns the id and name for the album object
NapsterAlbumData formatAlbumData(Map<String, String> data) => NapsterAlbumData(
      id: data["id"],
      name: data["name"],
    );

/// formatTrackData()
///
/// @param track track The track object given by the napster api
///
/// Returns the song details required from the track data
NapsterSongData formatTrackData(Map<String, dynamic> track) => NapsterSongData(
      artist: track["artistName"],
      title: track["name"],
      length: track["playbackSeconds"],
      thumbnail:
          "https://api.napster.com/imageserver/v2/albums/${track["albumId"]}/images/200x200.jpg",
      albumId: track["albumId"],
    );