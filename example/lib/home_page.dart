import 'package:flutter/material.dart';
import 'package:phasetida_flutter/phasetida_flutter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("「拉尔瓦不会为一株龙珠果从一而终」", style: textTheme.titleLarge),
          SizedBox(height: 8,),
          Text("「而常世之人却一厢情愿」", style: textTheme.titleLarge),
          SizedBox(height: 32,),
          Text("phasetida_flutter/phasetida-core: $phasetidaFlutterVersion/$phasetidaCoreVersion"),
          Text("Resources are powered by somnia.xtower.site"),
        ],
      ),
    );
  }
}
