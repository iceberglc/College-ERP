import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_hero_card.dart';

class StudentNotificationsScreen extends StatelessWidget {
  const StudentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: IceHeroCard(
              title: 'Notifications',
              subtitle: 'Push notifications from your school',
            ),
          ),
          SliverFillRemaining(
            child: Center(
              child: Text('No notifications yet.',
                  style: TextStyle(color: IceColors.muted)),
            ),
          ),
        ],
      ),
    );
  }
}
