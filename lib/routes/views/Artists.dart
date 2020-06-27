import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:focused_menu/modals.dart";

import "package:Music/bloc/notification_bloc.dart";
import "package:Music/bloc/queue_bloc.dart";
import "package:Music/constants.dart";
import "package:Music/helpers/db.dart";
import "package:Music/helpers/generateSubtitle.dart";
import "package:Music/models/models.dart";
import "package:Music/routes/widgets/CoverImage.dart";

class Artists extends StatefulWidget {
  @override
  _ArtistsState createState() => _ArtistsState();
}

class _ArtistsState extends State<Artists> {
  List<ArtistData> _artists = [];

  @override
  void initState() {
    super.initState();
    getArtists();
  }

  getArtists() async {
    var db = await getDB();

    var preSongs = PreArtist.fromMapArray(await db.rawQuery(
        "SELECT artist as name, COUNT(*) as numSongs FROM songdata GROUP BY artist;"));

    List<ArtistData> artists = [];

    for (var preSong in preSongs) {
      var images = await db.query(
        Tables.Albums,
        where: "artist LIKE ?",
        whereArgs: [preSong.name],
        columns: ["imagePath"],
        orderBy: "numSongs DESC",
        limit: 4,
      );

      artists.add(ArtistData.fromMapAndPreArtist(images, preSong));
    }

    if (!mounted) return;

    setState(() {
      _artists = artists;
    });
  }

  @override
  Widget build(BuildContext context) {
    var width10 = MediaQuery.of(context).size.shortestSide / 10;

    return MultiBlocListener(
      listeners: [
        BlocListener<NotificationBloc, NotificationState>(
          listener: (_, state) {
            if (state is DownloadedNotification) {
              getArtists();
            }
          },
        ),
        BlocListener<QueueBloc, QueueState>(
          listener: (_, state) {
            if (state.updateData) {
              getArtists();
            }
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(left: width10 / 4 * 2, top: 30, bottom: 7),
            child:
                Text("Artists", style: Theme.of(context).textTheme.headline3),
          ),
          Expanded(
            child: GridView.builder(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.all(0.3 * width10),
              itemCount: _artists.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: (4.1 * width10) / (4.1 * width10 + 3 * rem),
              ),
              itemBuilder: (ctx, index) {
                var artist = _artists[index];

                var mozaic = artist.images.length == 4;

                return CoverImage(
                  image: mozaic ? null : artist.images[0],
                  images: mozaic ? artist.images : null,
                  title: artist.name,
                  subtitle: generateSubtitle(
                      type: "Artist", numSongs: artist.numSongs),
                  isBig: true,
                  tag: artist.name,
                  onClick: () {
                    Navigator.of(context)
                        .pushNamed("/artist", arguments: artist);
                  },
                  focusedMenuItems: [
                    FocusedMenuItem(
                      onPressed: () async {
                        var db = await getDB();
                        var songs = SongData.fromMapArray(await db.query(
                          Tables.Songs,
                          where: "artist LIKE ?",
                          whereArgs: [artist.name],
                          orderBy: "LOWER(title), title",
                        ));
                        BlocProvider.of<QueueBloc>(context)
                            .add(EnqueueSongs(songs: songs));
                      },
                      title: Text("Play"),
                      trailingIcon: Icon(Icons.playlist_play),
                      backgroundColor: Colors.transparent,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
