import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_colors.dart';

class MainShellPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellPage({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
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
          _NavDestination(label: 'Profile', asset: AppIcons.navProfile),
        ],
      ),
    );
  }
}

class _NavDestination extends NavigationDestination {
  _NavDestination({
    required super.label,
    required String asset,
  }) : super(
          icon: _SvgIcon(asset: asset, isSelected: false),
          selectedIcon: _SvgIcon(asset: asset, isSelected: true),
        );
}

class _SvgIcon extends StatelessWidget {
  final String asset;
  final bool isSelected;

  const _SvgIcon({required this.asset, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.neutralMid;
    return SvgPicture.asset(
      asset,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: asset,
    );
  }
}

