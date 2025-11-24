import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class VBottomNavigationBar extends StatefulWidget {
  final Function(int)? onTap;
  final int currentIndex;
  final Color? color;
  final List<BottomNavigationBarItem> items;

  const VBottomNavigationBar({
    super.key,
    this.onTap,
    this.currentIndex = 0,
    required this.items,
    this.color,
  });

  @override
  State<VBottomNavigationBar> createState() => _VBottomNavigationBarState();
}

class _VBottomNavigationBarState extends State<VBottomNavigationBar> {
  int selectedIndex = 0;
  static const kBarHeight = 62.0;

  int get count => widget.items.length;
  var tabRects = <Rect>[];
  final selectedTabRect = ValueNotifier<Rect?>(null);
  final containerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(covariant VBottomNavigationBar oldWidget) {
    if (oldWidget.currentIndex != widget.currentIndex) {
      setState(() {
        selectedIndex = widget.currentIndex;
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.color ?? Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            offset: const Offset(0, -3),
            blurRadius: 3,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            offset: const Offset(0, -1),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 8, right: 8),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: kBarHeight,
          child: Row(
            children: [
              ...widget.items.mapIndexed((idx, e) {
                bool isSelected = idx == selectedIndex;

                return Expanded(
                  child: _TabIcon(
                    key: e.key,
                    label: e.label ?? "",
                    icon: isSelected ? e.activeIcon : e.icon,
                    isSelected: isSelected,
                    onTapDown: () => widget.onTap?.call(idx),
                    color: widget.color,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabIcon extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTapDown;
  final Color? color;

  const _TabIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    this.onTapDown,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final style = const TextStyle().copyWith(
      fontSize: 11,
      height: 1.0,
      color: isSelected ? Colors.indigoAccent : Colors.black,
    );
    return Material(
      color: color ?? Colors.white,
      child: InkWell(
        onTapDown: (_) => onTapDown?.call(),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    icon,
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: style,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VBottomBarPadding extends StatelessWidget {
  const VBottomBarPadding({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      top: false,
      left: false,
      right: false,
      child: SizedBox(),
    );
  }
}
