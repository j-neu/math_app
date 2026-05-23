import 'package:flutter/material.dart';

class DiagnosticCompleteScreen extends StatelessWidget {
  const DiagnosticCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF77CDD5),
                size: 96,
              ),
              const SizedBox(height: 32),
              Text(
                'Super gemacht!',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF154761),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'Fertig!\nBitte zeig deiner Lehrkraft den Bildschirm.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.black87,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
