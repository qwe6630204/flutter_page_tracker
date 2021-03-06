import 'package:flutter/material.dart';
import 'dart:async';

import 'page_tracker_aware.dart';
import 'page_view_wrapper.dart';

mixin PageViewListenerMixin<T extends StatefulWidget> on State<T>, PageTrackerAware {

  StreamSubscription<PageTrackerEvent> sb;
  bool isPageView = false;
  // 向列表中的列表转发页面事件
  Set<PageTrackerAware> subscribers;

  @override
  void initState() {
    super.initState();

    subscribers = Set<PageTrackerAware>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (sb == null && pageViewIndex!= null) {

      Stream<PageTrackerEvent> stream = PageViewWrapper.of(context, pageViewIndex);
      // 如果外围没有包裹PageViewWrapper，那么stream为null
      if (stream != null) {
        sb = stream.listen(_onPageTrackerEvent);
      }
    }
  }

  void _onPageTrackerEvent(PageTrackerEvent event) {
    if (event == PageTrackerEvent.PageView) {
      if (!isPageView) {
        didPageView();
        isPageView = true;
      }
    } else {
      if (isPageView) {
        didPageExit();
        isPageView = false;
      }
    }
  }

  int get pageViewIndex => null;

  @override
  void didPageView() {
    super.didPageView();

    subscribers.forEach((subscriber) {
      subscriber.didPageView();
    });
  }

  @override
  void didPageExit() {
    super.didPageExit();

    subscribers.forEach((subscriber) {
      subscriber.didPageExit();
    });
  }

  // 子列表页面订阅页面事件
  void subscribe(PageTrackerAware pageTrackerAware) {
    subscribers.add(pageTrackerAware);
  }

  void unsubscribe(PageTrackerAware pageTrackerAware) {
    subscribers.remove(pageTrackerAware);
  }

  @override
  void dispose() {
    if (isPageView)
      didPageExit();
    sb?.cancel();
    super.dispose();
  }

  static PageViewListenerWrapperState of(BuildContext context) {
    return context.ancestorStateOfType(TypeMatcher<PageViewListenerWrapperState>());
  }
}


// 列表项中还可以再次嵌套列表，所以[PageViewListenerWrapper]需要把
class PageViewListenerWrapper extends StatefulWidget {

  final int index;
  final Widget child;
  final VoidCallback onPageView;
  final VoidCallback onPageExit;

  const PageViewListenerWrapper(this.index, {
    Key key,
    this.child,
    this.onPageView,
    this.onPageExit,
  }): super(key: key);

  @override
  PageViewListenerWrapperState createState() {
    return PageViewListenerWrapperState();
  }

}

class PageViewListenerWrapperState extends State<PageViewListenerWrapper> with PageTrackerAware, PageViewListenerMixin {

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }


  @override
  int get pageViewIndex => widget.index;

  @override
  void didPageView() {
    super.didPageView();
    if (widget.onPageView != null) {
      widget.onPageView();
    }
  }

  @override
  void didPageExit() {
    super.didPageExit();
    if (widget.onPageExit != null) {
      widget.onPageExit();
    }
  }
}