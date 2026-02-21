class InputContainer {
  final List<_Touch> _touches = List.generate(30, (_) => _Touch(0));

  int touchDown(int serial) {
    return _findFirstAvailable(null, (i, touch) {
      touch.enable = true;
      touch.serial = serial;
      return i;
    });
  }

  int touchMove(int serial) {
    return _findFirstAvailable(serial, (i, touch) {
      return i;
    });
  }

  int touchUp(int serial) {
    return _findFirstAvailable(serial, (i, touch) {
      touch.enable = false;
      return i;
    });
  }

  int _findFirstAvailable(int? serial, Function(int index, _Touch touch) fun) {
    for (final (i, touch) in _touches.indexed) {
      if (serial != null
          ? (touch.enable && touch.serial == serial)
          : !touch.enable) {
        return fun(i, touch);
      }
    }
    return -1;
  }
}

class _Touch {
  bool enable = false;
  int serial;

  _Touch(this.serial);
}
