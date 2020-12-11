import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jiggy3/blocs/chooser_bloc.dart';
import 'package:jiggy3/pages/chooser_page.dart';
import 'package:provider/provider.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// import 'blocs/bloc_provider.dart';
// import 'blocs/bloc_provider.dart';
import 'blocs/counter_bloc.dart';
import 'blocs/puzzles_bloc.dart';
import 'blocs/puzzles_bloc.dart';
import 'data/repository.dart';

void main() {
  runApp(Jiggy3());
}

class Jiggy3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
//    globals.createDatabase = createDatabaseFlag?.toLowerCase() == "true";
    final title = 'Jiggy!';


   // Repository.dropAndRebuildDatabase();


    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: title,
        theme: ThemeData(
          textTheme: Theme
              .of(context)
              .textTheme
              .apply(
            bodyColor: Colors.black,
            displayColor: Colors.grey[600],
            fontFamily: 'Raleway',
            ),
          // This colors the [InputOutlineBorder] when it is selected
          primaryColor: Colors.grey[500],
          textSelectionHandleColor: Colors.green[500],
          ),
        // Inject the PuzzleCardsBloc to get the latest data later

      home: MultiProvider(
        providers: [
          BlocProvider(create: (BuildContext context) => CounterBloc()),
          // BlocProvider(create: (BuildContext context) => PuzzlesBloc()),
          BlocProvider(create: (BuildContext context) => ChooserBloc()),
        ],
        // child: MyHomePage(title: 'Jiggy!'),
        child: ChooserPage(title: 'Jiggy!'),
      ),

      // home: BlocProvider(
        //   bloc: CounterBloc(),
        //   child: BlocProvider(
        //     bloc: PuzzlesBloc(),
        //       child: MyHomePage(title: 'Jiggy!')),
        //   )



        );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // CounterBloc _counterBloc;
  // PuzzlesBloc _puzzlesBloc;

  @override
  void initState() {
    super.initState();
    // _counterBloc = BlocProvider.of<CounterBloc>(context);
    // _puzzlesBloc = BlocProvider.of<PuzzlesBloc>(context);
  }

  // void _incrementCounter(BuildContext context) {
  //   CounterBloc _counterBloc = Provider.of<CounterBloc>(context);
  //   _counterBloc.increment();
  // }
  //
  // void _decrementCounter(BuildContext context) {
  //   CounterBloc _counterBloc = Provider.of<CounterBloc>(context);
  //   _counterBloc.decrement();
  // }

  @override
  Widget build(BuildContext context) {
    CounterBloc _counterBloc = Provider.of<CounterBloc>(context);
    // Stream<int> ii = BlocProvider.of<CounterBloc>(context).counterStream;
    return StreamBuilder<int>(
      stream: BlocProvider.of<CounterBloc>(context).counterStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: Container(
              height: 180.0,
              width: 180.0,
              child: CircularProgressIndicator(),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'You have pushed the button this many times:', textScaleFactor: 3.0,
                ),
                Text(
                  '${snapshot.data}',
                  style: Theme.of(context).textTheme.headline4,
                  textScaleFactor: 3.0,
                ),




              ],
            ),
          ),
          floatingActionButton: Row(mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: FloatingActionButton(
                  heroTag: Key('1'),
                  onPressed: () => _counterBloc.increment(),
                  tooltip: 'Increment',
                  child: Icon(Icons.add),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: FloatingActionButton(
                  heroTag: Key('2'),
                  onPressed: () => _counterBloc.decrement(),
                  tooltip: 'Decrement',
                  child: Icon(Icons.remove),
                  ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                child: FloatingActionButton(
                  heroTag: Key('3'),
                  onPressed: () async {
                    await _navigateToSecondPage();
                  },
                  tooltip: 'Next Page',
                  child: Icon(Icons.navigate_next),
                  ),
                ),
            ],
          ),
        );
      }
    );
  }

  void _navigateToSecondPage() async {
    CounterBloc _counterBloc = Provider.of<CounterBloc>(context, listen: false);
    int update = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (BuildContext context) => CounterBloc() ,
          child: MySecondPage(
            title: 'My Second Page',
            ),
        ),
        ),
      );

    // Update contains the changed counter value, or null if the counter didn't change.
    if (update != null) {
      _counterBloc.setCounter(update);
    }
  }
}


class MySecondPage extends StatefulWidget {
  MySecondPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MySecondPageState createState() => _MySecondPageState();
}

class _MySecondPageState extends State<MySecondPage> {
  // CounterBloc _counterBloc;


  @override
  void initState() {
    super.initState();
    // _counterBloc = BlocProvider.of<CounterBloc>(context);
  }

  // void _incrementCounter() {
  //   _counterBloc.increment();
  // }
  //
  // void _decrementCounter() {
  //   _counterBloc.decrement();
  // }

  @override
  Widget build(BuildContext context) {
    CounterBloc _counterBloc = Provider.of<CounterBloc>(context);
    return StreamBuilder<int>(
      stream: BlocProvider.of<CounterBloc>(context).counterStream,
      builder: (context, snapshot) {

        if ( ! snapshot.hasData) {
          return Center(
            child: Container(
              height: 180.0,
              width: 180.0,
              child: CircularProgressIndicator(),
            ),
          );
        }
        return WillPopScope(
          child: Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'You have pushed the button this many times:', textScaleFactor: 3.0,
                      ),
                    Text(
                      '${snapshot.data}',
                      style: Theme.of(context).textTheme.headline4,
                      textScaleFactor: 3.0,
                      ),
                  ],
                ),
              ),
                floatingActionButton: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FloatingActionButton(
                        heroTag: Key('4'),
                        onPressed: () => _counterBloc.increment(),
                        tooltip: 'Increment',
                        child: Icon(Icons.add),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FloatingActionButton(
                        heroTag: Key('5'),
                        onPressed: () => _counterBloc.decrement(),
                        child: Icon(Icons.remove),
                      ),
                    ),
                  ],
                ), // This trailing comma makes auto-formatting nicer for build methods.
            ),
          onWillPop: () {
            Navigator.pop(context, snapshot.data);

            return Future.value(false);
          }
        );
      }
    );
  }
}
