import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:stelliberty/clash/providers/clash_provider.dart';
import 'package:stelliberty/i18n/i18n.dart';
import 'package:stelliberty/ui/widgets/modern_tooltip.dart';

// 代理组选择器组件
class ProxyGroupSelector extends StatefulWidget {
  final ClashProvider clashProvider;
  final int currentGroupIndex;
  final ScrollController scrollController;
  final Function(int) onGroupChanged;
  final double mouseScrollSpeedMultiplier;
  final double tabScrollDistance;

  const ProxyGroupSelector({
    super.key,
    required this.clashProvider,
    required this.currentGroupIndex,
    required this.scrollController,
    required this.onGroupChanged,
    this.mouseScrollSpeedMultiplier = 2.0,
    this.tabScrollDistance = 300.0,
  });

  @override
  State<ProxyGroupSelector> createState() => _ProxyGroupSelectorState();
}

class _ProxyGroupSelectorState extends State<ProxyGroupSelector> {
  // 样式常量

  // 滚动判断阈值
  static const double _scrollThreshold = 0.5;

  // 动画时长
  static const Duration _buttonScrollDuration = Duration(milliseconds: 200);
  static const Duration _mouseScrollDuration = Duration(milliseconds: 100);
  static const Duration _underlineAnimationDuration = Duration(
    milliseconds: 200,
  );

  // 布局间距
  static const double _outerPaddingTop = 4.0;
  static const double _outerPaddingBottom = 12.0;
  static const double _groupSpacing = 24.0;
  static const double _buttonSpacing = 12.0;

  // 标签样式
  static const double _tabHorizontalPadding = 8.0;
  static const double _tabVerticalPadding = 2.0;
  static const double _tabTextHorizontalPadding = 4.0;
  static const double _tabTextVerticalPadding = 4.0;
  static const double _tabBorderRadius = 8.0;
  static const double _tabFontSize = 14.0;

  // 透明度
  static const double _hoverAlphaLight = 0.5;
  static const double _hoverAlphaDark = 0.3;
  static const double _unselectedTextAlpha = 0.7;

  // 下划线样式
  static const double _underlineHeight = 2.0;
  static const double _underlineWidth = 40.0;
  static const double _underlineBorderRadius = 1.0;

  // 按钮样式
  static const double _iconButtonSize = 20.0;

  int? _hoveredIndex;
  bool _needsScrolling = false;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    // 监听滚动位置变化（普通滚动）
    widget.scrollController.addListener(_updateButtonStates);
    // 延迟初始化按钮状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateButtonStates();
    });
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_updateButtonStates);
    super.dispose();
  }

  void _updateButtonStates() {
    if (!mounted || !widget.scrollController.hasClients) return;

    final position = widget.scrollController.position;
    if (!position.hasContentDimensions) return;

    final needsScrolling = position.maxScrollExtent > _scrollThreshold;
    final canScrollLeft = needsScrolling && position.pixels > _scrollThreshold;
    final canScrollRight =
        needsScrolling &&
        position.pixels < position.maxScrollExtent - _scrollThreshold;

    // 只有状态真正改变时才调用 setState
    if (_needsScrolling != needsScrolling ||
        _canScrollLeft != canScrollLeft ||
        _canScrollRight != canScrollRight) {
      setState(() {
        _needsScrolling = needsScrolling;
        _canScrollLeft = canScrollLeft;
        _canScrollRight = canScrollRight;
      });
    }
  }

  void _scrollByDistance(double distance) {
    if (!widget.scrollController.hasClients) return;

    final offset = widget.scrollController.offset + distance;
    widget.scrollController.animateTo(
      offset.clamp(0.0, widget.scrollController.position.maxScrollExtent),
      duration: _buttonScrollDuration,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: _outerPaddingTop,
        bottom: _outerPaddingBottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent &&
                    widget.scrollController.hasClients) {
                  final offset =
                      widget.scrollController.offset +
                      pointerSignal.scrollDelta.dy *
                          widget.mouseScrollSpeedMultiplier;
                  widget.scrollController.animateTo(
                    offset.clamp(
                      0.0,
                      widget.scrollController.position.maxScrollExtent,
                    ),
                    duration: _mouseScrollDuration,
                    curve: Curves.easeOut,
                  );
                }
              },
              child: NotificationListener<ScrollMetricsNotification>(
                onNotification: (notification) {
                  // 监听滚动指标改变（包括滚动和窗口大小改变）
                  _updateButtonStates();
                  return false;
                },
                child: SingleChildScrollView(
                  controller: widget.scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: List.generate(
                      widget.clashProvider.proxyGroups.length,
                      (index) {
                        final group = widget.clashProvider.proxyGroups[index];
                        final isSelected = index == widget.currentGroupIndex;
                        final isHovered = _hoveredIndex == index;

                        return Padding(
                          padding: const EdgeInsets.only(right: _groupSpacing),
                          child: MouseRegion(
                            onEnter: (_) =>
                                setState(() => _hoveredIndex = index),
                            onExit: (_) => setState(() => _hoveredIndex = null),
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => widget.onGroupChanged(index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: _tabHorizontalPadding,
                                  vertical: _tabVerticalPadding,
                                ),
                                decoration: BoxDecoration(
                                  color: isHovered && !isSelected
                                      ? Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(
                                              alpha:
                                                  Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.light
                                                  ? _hoverAlphaLight
                                                  : _hoverAlphaDark,
                                            )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    _tabBorderRadius,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // 代理组名称
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: _tabTextHorizontalPadding,
                                        vertical: _tabTextVerticalPadding,
                                      ),
                                      child: Text(
                                        group.name,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(
                                                      alpha:
                                                          _unselectedTextAlpha,
                                                    ),
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          fontSize: _tabFontSize,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    // 底部下划线
                                    AnimatedContainer(
                                      duration: _underlineAnimationDuration,
                                      height: _underlineHeight,
                                      width: isSelected ? _underlineWidth : 0,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(
                                          _underlineBorderRadius,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: _buttonSpacing),
          _buildScrollButtons(context),
        ],
      ),
    );
  }

  Widget _buildScrollButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ModernTooltip(
          message: context.translate.proxy.scrollLeft,
          child: IconButton(
            onPressed: _canScrollLeft
                ? () => _scrollByDistance(-widget.tabScrollDistance)
                : null,
            icon: const Icon(Icons.chevron_left),
            iconSize: _iconButtonSize,
            visualDensity: VisualDensity.compact,
          ),
        ),
        ModernTooltip(
          message: context.translate.proxy.scrollRight,
          child: IconButton(
            onPressed: _canScrollRight
                ? () => _scrollByDistance(widget.tabScrollDistance)
                : null,
            icon: const Icon(Icons.chevron_right),
            iconSize: _iconButtonSize,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}
