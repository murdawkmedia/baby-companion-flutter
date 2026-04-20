import 'package:flutter/material.dart';

const milestoneNames = <String>[
  'Social Smile',
  'First Laugh',
  'Holds Head Up',
  'Tracks Objects',
  'Rolls Fwd-Back',
  'Rolls Back-Fwd',
  'Sits w/ Support',
  'Sits Alone',
  'First Solid Food',
  'Crawling',
  'Pulls to Stand',
  'First Steps',
  'First Word',
  'Points at Things',
  'Waves Bye-Bye',
];

class MilestonesScreen extends StatelessWidget {
  const MilestonesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Milestones')),
      body: ListView.builder(
        itemCount: milestoneNames.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(milestoneNames[i]),
          trailing: const Icon(Icons.radio_button_unchecked),
        ),
      ),
    );
  }
}
