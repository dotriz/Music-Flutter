import 'package:path_provider/path_provider.dart';

import 'package:Music/helpers/db.dart';
import 'package:Music/models/models.dart';

import "./napster.dart" show getAlbumInfo;
import "./downloader.dart" show downloadImage;

/// addAlbum()
///
/// @param {string} albumId The id of the album
/// @param {string} artist The name of the artist who made it
/// @param numSongs the number of songs in the album, defaults to 1
///
/// Adds an album and downloads the image for the album if they dont exist
Future<void> updateAlbum(String albumId, String artist,
    {int numSongs = 1}) async {
  var root = await getApplicationDocumentsDirectory();
  var imagePath = "${root.path}/album_images/$albumId.jpg";

  downloadImage(albumId);

  var db = await getDB();

  if ((await db.query(Tables.Albums, where: "id = ?", whereArgs: [albumId]))
          .length >
      0) {
    db.execute("UPDATE albumdata SET numSongs = numSongs + 1 WHERE id LIKE ?",
        [albumId]);
    return db.close();
  }

  var albumInfo = await getAlbumInfo(albumId);

  if (albumInfo == null) {
    print("Failed album $albumId");
  }

  print("Adding album ${albumInfo.name}.");

  var album = Album(
    id: albumInfo.id,
    name: albumInfo.name,
    imagePath: imagePath,
    numSongs: numSongs,
    artist: artist,
  );

  await db.insert(Tables.Albums, Album.toMap(album));

  await db.close();
}