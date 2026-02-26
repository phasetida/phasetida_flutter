import 'package:flutter/material.dart';
import 'package:phasetida_flutter_example/chart_page.dart';
import 'package:phasetida_flutter_example/home_page.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<StatefulWidget> createState() => AppState();
}

class AppState extends State<App> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [HomePage(), ChartPage()][_index],
      bottomNavigationBar: _navBar(),
    );
  }

  BottomNavigationBar _navBar() {
    return BottomNavigationBar(
      currentIndex: _index,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(
          icon: Icon(Icons.multiline_chart),
          label: "Charts",
        ),
      ],
      onTap: (i) {
        setState(() {
          _index = i;
        });
      },
    );
  }
}
