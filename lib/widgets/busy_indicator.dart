import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jiggy3/blocs/chooser_bloc.dart';

class BusyIndicator extends StatelessWidget {
  final Progress progress;

  const BusyIndicator(this.progress);

  @override
  Widget build(BuildContext context) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 180.0,
              width: 180.0,
              child: CircularProgressIndicator(
                value: progress?.percent,
                backgroundColor: Colors.orange,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
          if (progress != null)
            Padding(
              padding: const EdgeInsets.only(top: 32.0),
              child: Text(progress.progress, textScaleFactor: 2.0),
            ),
          ],
        ),
      );
  }
}