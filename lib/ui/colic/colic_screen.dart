import 'package:flutter/material.dart';

class ColicScreen extends StatelessWidget {
  const ColicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Colic Timer')),
      body: const Center(child: Text('Colic — TODO')),
    );
  }
}
