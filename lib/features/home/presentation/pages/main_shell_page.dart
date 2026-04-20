import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../notifications/presentation/bloc/notifications_bloc.dart';
import '../../../notifications/presentation/bloc/notifications_state.dart';

class MainShellPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellPage({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.select<NotificationsBloc, int>((bloc) {
      final state = bloc.state;
      if (state is NotificationsListLoaded) {
        return state.unreadCount;
      }
      return 0;
    });

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        backgroundColor: AppColors.surfaceWhite,
        indicatorColor: Colors.transparent,
        destinations: [
          _NavDestination(label: 'Work', asset: AppIcons.navWork),
          _NavDestination(label: 'Orders', asset: AppIcons.navPaper),
          _NavDestination(label: 'History', asset: AppIcons.navChat),
          _NavDestination(
            label: 'Profile',
            asset: AppIcons.navProfile,
            badgeCount: unreadCount,
          ),
        ],
      ),
    );
  }
}

class _NavDestination extends NavigationDestination {
  _NavDestination({
    required super.label,
    required String asset,
    int badgeCount = 0,
  }) : super(
         icon: _SvgIcon(
           asset: asset,
           isSelected: false,
           badgeCount: badgeCount,
         ),
         selectedIcon: _SvgIcon(
           asset: asset,
           isSelected: true,
           badgeCount: badgeCount,
         ),
       );
}

class _SvgIcon extends StatelessWidget {
  final String asset;
  final bool isSelected;
  final int badgeCount;

  const _SvgIcon({
    required this.asset,
    required this.isSelected,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.neutralMid;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SvgPicture.asset(
          asset,
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          semanticsLabel: asset,
        ),
        if (badgeCount > 0)
          Positioned(
            right: -8,
            top: -6,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: const BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Text(
                badgeCount > 99 ? '99+' : badgeCount.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
