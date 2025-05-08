import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: Colors.black26,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final DraggableScrollableController sheetController = DraggableScrollableController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Belum terhubung internet"),
        backgroundColor: Colors.yellow,
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Cuan Cuan Cuan',
                  style: TextStyle(
                    color: Colors.white
                  ),
                ),
              ],
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.12,
            minChildSize: 0.12,
            maxChildSize: 0.5,
            builder: (BuildContext context, scrollController) {
              return Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).hintColor,
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                          ),
                          height: 4,
                          width: 40,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SliverAppBar(
                      title: Text('Apakah sesuai?'),
                      primary: false,
                      pinned: true,
                      centerTitle: true,
                    ),
                    SliverList.list(children: const [
                      ListTile(title: Text('Jane Doe')),
                      ListTile(title: Text('Jack Reacher')),
                      ListTile(title: Text('Jack Reacher')),
                      ListTile(title: Text('Jack Reacher')),
                      ListTile(title: Text('Jack Reacher')),
                      ListTile(title: Text('Jack Reacher')),
                    ])
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
