import 'package:best_flutter_ui_templates/app_theme.dart';
import 'package:best_flutter_ui_templates/custom_drawer/home_drawer.dart';
import 'package:best_flutter_ui_templates/theme_controller.dart';
import 'package:flutter/material.dart';

class DrawerUserController extends StatefulWidget {
  const DrawerUserController({
    super.key,
    this.drawerWidth = 250,
    this.onDrawerCall,
    this.screenView,
    this.animatedIconData = AnimatedIcons.arrow_menu,
    this.menuView,
    this.drawerIsOpen,
    this.screenIndex,
  });

  final double drawerWidth;
  final Function(DrawerIndex)? onDrawerCall;
  final Widget? screenView;
  final Function(bool)? drawerIsOpen;
  final AnimatedIconData? animatedIconData;
  final Widget? menuView;
  final DrawerIndex? screenIndex;

  @override
  State<DrawerUserController> createState() => _DrawerUserControllerState();
}

class _DrawerUserControllerState extends State<DrawerUserController>
    with TickerProviderStateMixin {
  ScrollController? scrollController;
  AnimationController? iconAnimationController;
  AnimationController? animationController;

  double scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 0),
    );

    iconAnimationController?.animateTo(
      1.0,
      duration: const Duration(milliseconds: 0),
      curve: Curves.fastOutSlowIn,
    );

    scrollController = ScrollController(
      initialScrollOffset: widget.drawerWidth,
    );

    scrollController?.addListener(drawerScrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      getInitState();
    });
  }

  void drawerScrollListener() {
    if (scrollController == null) {
      return;
    }

    if (scrollController!.offset <= 0) {
      if (scrollOffset != 1.0) {
        setState(() {
          scrollOffset = 1.0;
        });

        try {
          widget.drawerIsOpen?.call(true);
        } catch (_) {}
      }

      iconAnimationController?.animateTo(
        0.0,
        duration: const Duration(milliseconds: 0),
        curve: Curves.fastOutSlowIn,
      );
    } else if (scrollController!.offset > 0 &&
        scrollController!.offset < widget.drawerWidth.floor()) {
      iconAnimationController?.animateTo(
        (scrollController!.offset * 100 / widget.drawerWidth) / 100,
        duration: const Duration(milliseconds: 0),
        curve: Curves.fastOutSlowIn,
      );
    } else {
      if (scrollOffset != 0.0) {
        setState(() {
          scrollOffset = 0.0;
        });

        try {
          widget.drawerIsOpen?.call(false);
        } catch (_) {}
      }

      iconAnimationController?.animateTo(
        1.0,
        duration: const Duration(milliseconds: 0),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  Future<bool> getInitState() async {
    scrollController?.jumpTo(widget.drawerWidth);
    return true;
  }

  @override
  void dispose() {
    scrollController?.removeListener(drawerScrollListener);
    scrollController?.dispose();
    iconAnimationController?.dispose();
    animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (BuildContext context, ThemeMode mode, Widget? child) {
        final bool isLightMode = mode == ThemeMode.light;

        return Scaffold(
          backgroundColor: isLightMode ? AppTheme.white : AppTheme.nearlyBlack,
          body: SingleChildScrollView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            physics: const PageScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width + widget.drawerWidth,
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: widget.drawerWidth,
                    height: MediaQuery.of(context).size.height,
                    child: AnimatedBuilder(
                      animation: iconAnimationController!,
                      builder: (BuildContext context, Widget? child) {
                        return Transform(
                          transform: Matrix4.translationValues(
                            scrollController!.offset,
                            0.0,
                            0.0,
                          ),
                          child: HomeDrawer(
                            screenIndex: widget.screenIndex ?? DrawerIndex.HOME,
                            iconAnimationController: iconAnimationController,
                            callBackIndex: (DrawerIndex indexType) {
                              onDrawerClick();

                              try {
                                widget.onDrawerCall?.call(indexType);
                              } catch (_) {}
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                        isLightMode ? AppTheme.white : AppTheme.nearlyBlack,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: isLightMode
                                ? AppTheme.grey.withOpacity(0.45)
                                : Colors.black.withOpacity(0.65),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: <Widget>[
                          IgnorePointer(
                            ignoring: scrollOffset == 1.0,
                            child: widget.screenView ?? const SizedBox(),
                          ),
                          if (scrollOffset == 1.0)
                            InkWell(
                              onTap: onDrawerClick,
                            ),
                          buildMenuButton(isLightMode),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildMenuButton(bool isLightMode) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
      ),
      child: SizedBox(
        width: AppBar().preferredSize.height - 8,
        height: AppBar().preferredSize.height - 8,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(
              AppBar().preferredSize.height,
            ),
            onTap: () {
              FocusScope.of(context).requestFocus(FocusNode());
              onDrawerClick();
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLightMode
                    ? Colors.white.withOpacity(0.95)
                    : Colors.white.withOpacity(0.08),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: isLightMode
                        ? Colors.black.withOpacity(0.10)
                        : Colors.black.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: widget.menuView != null
                    ? widget.menuView
                    : AnimatedIcon(
                  color: isLightMode ? Colors.black87 : Colors.white,
                  icon:
                  widget.animatedIconData ?? AnimatedIcons.arrow_menu,
                  progress: iconAnimationController!,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void onDrawerClick() {
    if (scrollController == null) {
      return;
    }

    if (scrollController!.offset != 0.0) {
      scrollController?.animateTo(
        0.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
      );
    } else {
      scrollController?.animateTo(
        widget.drawerWidth,
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
      );
    }
  }
}