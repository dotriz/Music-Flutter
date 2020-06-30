import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "package:Music/bloc/notification_bloc.dart";
import "package:Music/bloc/queue_bloc.dart";
import "package:Music/helpers/db.dart";
import "package:Music/helpers/generateSubtitle.dart";
import "package:Music/models/models.dart";
import "package:Music/constants.dart";
import "./widgets/SongPage.dart";

class LikedPage extends StatefulWidget {
  @override
  _LikedPageState createState() => _LikedPageState();
}

class _LikedPageState extends State<LikedPage>
    with SingleTickerProviderStateMixin {
  List<SongData> _songs = [];
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    beginAnimation();
    getSongs();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  Future<void> beginAnimation() async {
    await Future.delayed(const Duration(milliseconds: 450));
    await _controller.forward();
  }

  Future<void> getSongs() async {
    var db = await getDB();

    var songs = SongData.fromMapArray(await db.query(
      Tables.Songs,
      where: "liked",
      orderBy: "LOWER(title), title",
    ));

    if (!mounted) return;

    setState(() {
      _songs = songs;
    });
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    return MultiBlocListener(
      listeners: [
        BlocListener<NotificationBloc, NotificationState>(
          listener: (_, state) {
            if (state is UpdateData) {
              getSongs();
            }
          },
        ),
        BlocListener<QueueBloc, QueueState>(
          listener: (context, state) {
            if (state.updateData) {
              getSongs();
            }
          },
        ),
      ],
      child: SongPage(
        controller: _controller,
        title: "Liked",
        subtitle: generateSubtitle(type: "Album", numSongs: _songs.length),
        hero: Hero(
          tag: "liked-songs",
          child: Image.asset(
            "$imgs/liked.png",
            width: screenWidth,
            height: screenWidth,
            fit: BoxFit.cover,
          ),
        ),
        songs: _songs,
      ),
    );
  }
}
