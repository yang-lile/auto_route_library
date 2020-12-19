import 'package:auto_route/src/route/page_route_info.dart';
import 'package:auto_route/src/router/controller/routing_controller.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../auto_route.dart';
import '../controller/routing_controller.dart';

typedef AnimatedIndexedStackBuilder = Widget Function(
    BuildContext context, Widget child, Animation<double> animation);

class AutoTabsRouter extends StatefulWidget {
  final AnimatedIndexedStackBuilder builder;
  final List<PageRouteInfo> routes;
  final Duration duration;
  final Curve curve;

  const AutoTabsRouter({
    Key key,
    @required this.routes,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.ease,
    this.builder,
  }) : super(key: key);

  @override
  AutoTabsRouterState createState() => AutoTabsRouterState();

  static TabsRouter of(BuildContext context) {
    var scope = TabsRouterScope.of(context);
    assert(() {
      if (scope == null) {
        throw FlutterError(
            'AutoTabsRouter operation requested with a context that does not include an AutoTabsRouter.\n'
            'The context used to retrieve the AutoTabsRouter must be that of a widget that '
            'is a descendant of an AutoTabsRouter widget.');
      }
      return true;
    }());
    return scope.controller;
  }
}

class AutoTabsRouterState extends State<AutoTabsRouter>
    with SingleTickerProviderStateMixin {
  TabsRouter _controller;
  AnimationController _animationController;
  Animation<double> _animation;
  int _index = 0;

  TabsRouter get controller => _controller;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: widget.curve,
      ),
    );
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      final parentCtrl = RoutingControllerScope.of(context).controller;
      assert(parentCtrl != null);
      final parentData = RouteData.of(context);
      assert(parentData != null);
      _controller = parentCtrl.innerRouterOfRoute(parentData.route);
      _resetController();
    }
  }

  void _resetController() {
    assert(_controller != null);
    _controller.setupRoutes(widget.routes);
    _index = _controller.activeIndex;
    _animationController.value = 1.0;
    var rootDelegate = RootRouterDelegate.of(context);
    _controller.addListener(() {
      if (_controller.activeIndex != _index) {
        rootDelegate.notify();
        setState(() {
          _index = _controller.activeIndex;
        });
        _animationController.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AutoTabsRouter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!ListEquality().equals(widget.routes, oldWidget.routes)) {
      // _resetController();
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(_controller != null);
    final stack = _controller.stack;
    final builder = widget.builder ?? _defaultBuilder;
    return RoutingControllerScope(
      controller: _controller,
      child: TabsRouterScope(
          controller: _controller,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) => builder(context, child, _animation),
            child: stack.isEmpty
                ? Container(color: Theme.of(context).scaffoldBackgroundColor)
                : IndexedStack(
                    index: _index,
                    children: stack
                        .map(
                          (page) => page.wrappedChild(context),
                        )
                        .toList(growable: false),
                  ),
          )),
    );
  }

  Widget _defaultBuilder(_, child, animation) {
    return FadeTransition(opacity: animation, child: child);
  }
}