import 'package:flutter/material.dart';
import '../theme.dart';

/// Gradient header + white rounded sheet body used on every screen.
class GradientScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? drawer;
  final List<Widget>? actions;
  final Widget? header;

  const GradientScaffold({
    super.key,
    required this.title,
    required this.body,
    this.drawer,
    this.actions,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: drawer,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: actions,
      ),
      body: Stack(
        children: [
          Container(
            height: 280,
            decoration: const BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: kToolbarHeight - 8),
                if (header != null) header!,
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
