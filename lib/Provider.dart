import 'package:flutter/foundation.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/async.dart';
import 'dart:async';
import "package:rxdart/rxdart.dart";

//订阅者回调签名
// typedef void EventCallback<T>(T arg);

class Event {
  Map<String, ObserverList> _emap = Map<String, ObserverList>();

  ///添加订阅者
  void on<T>(String eventName, void Function(T arg) f) {
    if (eventName == null || f == null) return;
    _emap[eventName] ??= ObserverList();
    _emap[eventName].add(f);
  }

  ///移除订阅者
  void off<T>(String eventName, [void Function(T arg) f]) {
    if (eventName == null || _emap[eventName] == null) return;
    if (f == null) {
      _emap.remove(eventName);
    } else {
      _emap[eventName].remove(f);
      if (_emap[eventName].length == 0) {
        _emap.remove(eventName);
      }
    }
  }

  ///触发事件
  void emit<T>(String eventName, [T arg]) {
    if (eventName == null || _emap[eventName] == null) return;
    final List<void Function(T arg)> localListeners =
        List<void Function(T arg)>.from(_emap[eventName]);
    for (final void Function(T arg) listener in localListeners) {
      try {
        if (_emap[eventName].contains(listener)) listener(arg);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: "foundation library",
            context: ErrorDescription(
                "while dispatching notifications for $runtimeType"),
            informationCollector: () sync* {
              yield DiagnosticsProperty<Event>(
                "The $runtimeType sending notification was",
                this,
                style: DiagnosticsTreeStyle.errorProperty,
              );
            }));
      }
    }
  }

  bool _debugAssertNotDisposed() {
    assert(() {
      if (_emap == null) {
        throw FlutterError('A $runtimeType was used after being disposed.\n'
            'Once you have called dispose() on a $runtimeType, it can no longer be used.');
      }
      return true;
    }());
    return true;
  }

  void dispose() {
    // assert(_debugAssertNotDisposed());
    _emap = null;
  }
}

class MultDom {
  Map<String, SingleDataLine> _domList = Map();

  void setData<T>(String key, T data) {
    if (_domList != null && key.isNotEmpty && _domList[key] != null) {
      _domList[key].setData = data;
    }
  }

  void disDom([String key]) {
    if (_domList != null) {
      if (key == null || key.isEmpty) {
        _domList.removeWhere((key, value) {
          value.dispose();
          return true;
        });
        _domList = null;
      } else if (_domList[key] != null) {
        _domList[key].dispose();
        _domList.remove(key);
      }
    }
  }

  Widget builder<T>(String key,
      Widget Function(BuildContext context, AsyncSnapshot<T> data) observer,
      [T initData]) {
    if (_domList != null && key.isNotEmpty) {
      _domList[key] ??= SingleDataLine<T>(observer, initData);
      _domList[key].setData = initData;
      return _domList[key].getWidget;
    }
    return null;
  }

  Widget getDom(String key) {
    if (_domList != null && key.isNotEmpty) {
      return _domList[key].getWidget;
    }
    return null;
  }
}

// class SingleDataLine<T> {
//   StreamController<T> _stream;
//   Widget _dom;
//   T _currentData;

//   SingleDataLine(
//       Widget Function(BuildContext context, AsyncSnapshot<T> data) observer,
//       [T initData]) {
//     _stream = StreamController<T>.broadcast();
//     _dom = StreamBuilder(
//       stream: _stream.stream,
//       initialData: initData,
//       builder: observer,
//     );
//     _currentData = initData;
//   }
//   Widget get getWidget => _dom;
//   set setData(T data) {
//     if (_currentData != data) {
//       _stream.add(data);
//     }
//   }

//   void dispose() {
//     _stream.close();
//   }
// }

class SingleDataLine<T> {
  BehaviorSubject<T> _stream;
  Widget _dom;
  T _currentData;

  SingleDataLine(
      Widget Function(BuildContext context, AsyncSnapshot<T> data) observer,
      [T initData]) {
    _stream = BehaviorSubject<T>();
    _dom = StreamBuilder(
      stream: _stream.stream,
      initialData: initData,
      builder: observer,
    );
    _currentData = initData;
  }
  Widget get getWidget => _dom;
  set setData(T data) {
    if (_currentData != data) {
      _stream.add(data);
    }
  }

  void dispose() {
    _stream.close();
  }
}
