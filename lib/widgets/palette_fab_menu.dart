import 'dart:math';
import 'dart:ui';

import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

typedef OnColourChanged = void Function(Color);
typedef OnColourChangeEnd = void Function(Color);
typedef OnImageOpacityChanged = void Function(double);
typedef OnImageOpacityChangeEnd = void Function(double);

class PaletteFabMenu extends StatefulWidget {
  final Color colourValue;
  final ValueNotifier<double> opacityFactor;
  final OnColourChanged onColourChanged;
  final OnColourChangeEnd onColourChangeEnd;
  final OnImageOpacityChanged onImageOpacityChanged;
  final OnImageOpacityChangeEnd onImageOpacityChangeEnd;

  PaletteFabMenu(this.colourValue, this.opacityFactor,
      {this.onColourChanged,
      this.onColourChangeEnd,
      this.onImageOpacityChanged,
      this.onImageOpacityChangeEnd});

  @override
  _PaletteFabMenuState createState() => _PaletteFabMenuState();
}

class _PaletteFabMenuState extends State<PaletteFabMenu>
    with WidgetsBindingObserver {
  final GlobalKey<FabCircularMenuState> _fabKey = new GlobalKey();
  GlobalKey _fabOpacityKey = new GlobalKey();
  final GlobalKey _fabColourKey = new GlobalKey();

  OverlayEntry _colourOverlay;
  OverlayEntry _opacityOverlay;
  Color _originalColour;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _originalColour = widget.colourValue;
  }

  // The slider widget coordinates don't update when orientation is changed.
  // After fiddling with it all day and not being able to close, then re-open
  // the sliders, I gave up. This solution works, but leaves any open
  // sliders closed after rotating.
  // This method requires WidgetsBindingObserver, which must be disposed of
  // when finished.
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    closeSliders();
  }

  OverlayEntry _createOpacityOverlay() {
    var size = _getSize(_fabOpacityKey);
    if (size == null) {
      print('SIZE IS NULL!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      return null;
    }
    var position = _getPosition(_fabOpacityKey);
    final double maxWidth = position.dx - 23;
    final double preferredWidth = 450;
    final double width = min(maxWidth, preferredWidth);
    final double devWidth = MediaQuery.of(context).size.width;
    final double right = devWidth - position.dx + 23;

    return OverlayEntry(
        builder: (overlayContext) => Positioned(
            right: right,
            width: width,
            top: position.dy + 10,
            height: size.height - 20,
            child: Material(
              elevation: 4.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text('Opacity'),
                  ),
                  _createOpacitySlider(width - 58), // to avoid overflow
                ],
              ),
            )));
  }

  Widget _createOpacitySlider(double width) {
    return ValueListenableBuilder<double>(
        valueListenable: widget.opacityFactor,
        builder: (context, value, child) {
          return SizedBox(
            width: width,
            child: Slider(
              value: widget.opacityFactor.value,
              min: 0.2,
              max: 1.0,
              onChanged: widget.onImageOpacityChanged,
              onChangeEnd: widget.onImageOpacityChangeEnd,
            ),
          );
        });
  }

  OverlayEntry _createColourOverlay() {
    var size = _getSize(_fabColourKey);
    if (size == null) {
      return null;
    }
    var position = _getPosition(_fabColourKey);
    double height = 130.0;
    double width = 550.0;
    double left = position.dx - 23 - width;
    if (left < 0) {
      width += left;
      left = 0;
    }

    return OverlayEntry(
        builder: (context) => Positioned(
            left: left,
            width: width,
            height: height,
            top: position.dy - 58,
            child: Material(
              elevation: 4.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: ColorPicker(
                      pickerColor: widget.colourValue,
                      onColorChanged: widget.onColourChanged,
                      colorPickerWidth: width,
                      pickerAreaHeightPercent: 0.1,
                      enableAlpha: false,
                      displayThumbColor: false,
                      showLabel: false,
                      paletteType: PaletteType.hsv,
                      pickerAreaBorderRadius: const BorderRadius.only(
                        topLeft: const Radius.circular(2.0),
                        topRight: const Radius.circular(2.0),
                      ),
                    ),
                  ),
                ],
              ),
            )));
  }

  Offset _getPosition(GlobalKey key) {
    final RenderBox renderBox = key.currentContext.findRenderObject();
    return renderBox.localToGlobal(Offset.zero);
  }

  Size _getSize(GlobalKey key) {
    final RenderBox renderBox = key.currentContext?.findRenderObject();
    return renderBox?.size;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Builder(
        builder: (context) => FabCircularMenu(
          key: _fabKey,
          // Cannot be `Alignment.center`
          alignment: Alignment.bottomRight,
          ringColor: Colors.white.withAlpha(25),
          ringDiameter: 600.0,
          ringWidth: 100.0,
          fabSize: 60.0,
          fabElevation: 8.0,

          // Also can use specific color based on whether
          // the menu is open or not:
          // fabOpenColor: Colors.white
          // fabCloseColor: Colors.white
          // These properties take precedence over fabColor
          fabColor: Colors.indigo,
          fabOpenIcon: Icon(Icons.menu, color: primaryColor),
          fabCloseIcon: Icon(Icons.close, color: primaryColor),
          fabMargin: const EdgeInsets.all(8.0),
          animationDuration: const Duration(milliseconds: 800),
          animationCurve: Curves.easeInOutCirc,
          onDisplayChange: (fabIsOpen) {
            print('The fab menu is ${fabIsOpen ? "open" : "closed"}');

            if (!fabIsOpen) {
              if ((widget.colourValue.value != _originalColour.value) &&
                  (widget.onColourChangeEnd != null)) {
                print(
                    'Colour $_originalColour changed to ${widget.colourValue}. Calling onColourChangeEnd');
                widget.onColourChangeEnd(widget.colourValue);
              }
              closeSliders();
            }
          },
          children: <Widget>[
            Container(
              child: Tooltip(
                message: 'Opacity',
                child: RawMaterialButton(
                  key: _fabOpacityKey,
                  onPressed: () {
                    setState(() {
                      if (_opacityOverlay == null) {
                        _opacityOverlay = _createOpacityOverlay();
                        Overlay.of(context).insert(_opacityOverlay);
                      } else {
                        _opacityOverlay.remove();
                        _opacityOverlay = null;
                      }
                    });

//              fabKey.currentState.close();
                  },
                  shape: CircleBorder(),
                  splashColor: Colors.red,
                  fillColor: Colors.blueAccent,
                  padding: const EdgeInsets.all(24.0),
                  child: Icon(Icons.opacity, color: Colors.white, size: 30.0),
                ),
              ),
            ),
            Container(
              child: Tooltip(
                message: 'Background colour',
                child: RawMaterialButton(
                  key: _fabColourKey,
                  onPressed: () {
                    if (_colourOverlay == null) {
                      _colourOverlay = _createColourOverlay();
                      Overlay.of(context).insert(_colourOverlay);
                    } else {
                      _colourOverlay.remove();
                      _colourOverlay = null;
                    }
                  },
                  shape: CircleBorder(),
                  splashColor: Colors.red,
                  fillColor: Colors.green,
                  padding: const EdgeInsets.all(24.0),
                  child: Icon(Icons.colorize, color: Colors.white, size: 30.0),
                ),
              ),
            ),
            Container(
              child: Tooltip(
                message: 'Edges',
                child: RawMaterialButton(
                  onPressed: () {
                    print("Toggle show edge pieces");
                    _fabKey.currentState.close();
                  },
                  shape: CircleBorder(),
                  splashColor: Colors.red,
                  fillColor: Colors.orange,
                  padding: const EdgeInsets.all(24.0),
                  child: Icon(Icons.extension, color: Colors.white, size: 30.0),
                ),
              ),
            ),
            Container(
              child: Tooltip(
                message: 'Preview',
                child: RawMaterialButton(
                  onPressed: () {
                    print("Toggle show preview");
                  },
                  shape: CircleBorder(),
                  splashColor: Colors.red,
                  fillColor: Colors.yellowAccent,
                  padding: const EdgeInsets.all(24.0),
                  child: Icon(Icons.all_out, color: Colors.black, size: 30.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  closeSliders() {
    if (_opacityOverlay != null) {
      if (widget.onImageOpacityChangeEnd != null)
        widget.onImageOpacityChangeEnd;
      _opacityOverlay.remove();
      _opacityOverlay = null;
    }
    if (_colourOverlay != null) {
      if (widget.onColourChangeEnd != null)
        widget.onImageOpacityChangeEnd;
      _colourOverlay.remove();
      _colourOverlay = null;
    }
  }

  Future<bool> _onWillPop() {
    closeSliders();
    Navigator.pop(context);
    return Future.value(false);
  }
}
