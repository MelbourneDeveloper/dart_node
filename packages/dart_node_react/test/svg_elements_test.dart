/// Tests for SVG elements.
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('svg container element renders', () {
    final component = registerFunctionComponent(
      (props) => div(
        children: [
          svg(
            {'data-testid': 'svg', 'viewBox': '0 0 100 100'},
            [
              circle({'cx': 50, 'cy': 50, 'r': 40}),
            ],
          ),
        ],
      ),
    );

    final result = render(fc(component));
    final svgEl = result.getByTestId('svg');
    expect(svgEl, isNotNull);
    expect(svgEl.getAttribute('viewBox'), equals('0 0 100 100'));
    result.unmount();
  });

  test('g group element renders with children', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          g(
            {'data-testid': 'group', 'transform': 'translate(10,10)'},
            [
              rect({'x': 0, 'y': 0, 'width': 50, 'height': 50}),
            ],
          ),
        ],
      ),
    );

    final result = render(fc(component));
    final groupEl = result.getByTestId('group');
    expect(groupEl, isNotNull);
    expect(groupEl.getAttribute('transform'), equals('translate(10,10)'));
    result.unmount();
  });

  test('shape elements render with props', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          circle({'data-testid': 'circle', 'cx': 50, 'cy': 50, 'r': 25}),
          rect({
            'data-testid': 'rect',
            'x': 10,
            'y': 10,
            'width': 80,
            'height': 40,
          }),
          ellipse({
            'data-testid': 'ellipse',
            'cx': 50,
            'cy': 50,
            'rx': 30,
            'ry': 20,
          }),
          line({'data-testid': 'line', 'x1': 0, 'y1': 0, 'x2': 100, 'y2': 100}),
        ],
      ),
    );

    final result = render(fc(component));

    expect(result.getByTestId('circle').getAttribute('r'), equals('25'));
    expect(result.getByTestId('rect').getAttribute('width'), equals('80'));
    expect(result.getByTestId('ellipse').getAttribute('rx'), equals('30'));
    expect(result.getByTestId('line').getAttribute('x2'), equals('100'));

    result.unmount();
  });

  test('path element renders with d attribute', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          path({'data-testid': 'path', 'd': 'M10 10 H 90 V 90 H 10 Z'}),
        ],
      ),
    );

    final result = render(fc(component));
    expect(
      result.getByTestId('path').getAttribute('d'),
      equals('M10 10 H 90 V 90 H 10 Z'),
    );
    result.unmount();
  });

  test('polygon and polyline elements render', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          polygon({'data-testid': 'polygon', 'points': '50,0 100,100 0,100'}),
          polyline({'data-testid': 'polyline', 'points': '0,0 50,50 100,0'}),
        ],
      ),
    );

    final result = render(fc(component));
    expect(
      result.getByTestId('polygon').getAttribute('points'),
      equals('50,0 100,100 0,100'),
    );
    expect(
      result.getByTestId('polyline').getAttribute('points'),
      equals('0,0 50,50 100,0'),
    );
    result.unmount();
  });

  test('text elements render with content', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          textSvg(
            {'data-testid': 'text', 'x': 10, 'y': 20},
            [
              tspan({'data-testid': 'tspan'}, []),
            ],
          ),
        ],
      ),
    );

    final result = render(fc(component));
    expect(result.getByTestId('text').getAttribute('x'), equals('10'));
    expect(result.getByTestId('tspan'), isNotNull);
    result.unmount();
  });

  test('gradient elements render', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          defs(null, [
            linearGradient(
              {'data-testid': 'linearGrad', 'id': 'grad1'},
              [
                stop({'offset': '0%', 'stop-color': 'red'}),
                stop({'offset': '100%', 'stop-color': 'blue'}),
              ],
            ),
            radialGradient(
              {'data-testid': 'radialGrad', 'id': 'grad2'},
              [
                stop({'offset': '0%', 'stop-color': 'white'}),
                stop({'offset': '100%', 'stop-color': 'black'}),
              ],
            ),
          ]),
        ],
      ),
    );

    final result = render(fc(component));
    expect(
      result.getByTestId('linearGrad').getAttribute('id'),
      equals('grad1'),
    );
    expect(
      result.getByTestId('radialGrad').getAttribute('id'),
      equals('grad2'),
    );
    result.unmount();
  });

  test('filter elements render', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          defs(null, [
            filter(
              {'data-testid': 'filter', 'id': 'blur'},
              [
                feGaussianBlur({'stdDeviation': 5}),
              ],
            ),
          ]),
        ],
      ),
    );

    final result = render(fc(component));
    expect(result.getByTestId('filter').getAttribute('id'), equals('blur'));
    result.unmount();
  });

  test('clipPath and mask elements render', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          defs(null, [
            clipPath(
              {'data-testid': 'clip', 'id': 'myClip'},
              [
                rect({'x': 0, 'y': 0, 'width': 100, 'height': 100}),
              ],
            ),
            mask(
              {'data-testid': 'mask', 'id': 'myMask'},
              [
                rect({
                  'x': 0,
                  'y': 0,
                  'width': 100,
                  'height': 100,
                  'fill': 'white',
                }),
              ],
            ),
          ]),
        ],
      ),
    );

    final result = render(fc(component));
    expect(result.getByTestId('clip').getAttribute('id'), equals('myClip'));
    expect(result.getByTestId('mask').getAttribute('id'), equals('myMask'));
    result.unmount();
  });

  test('symbol and use elements render', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          defs(null, [
            symbol(
              {'data-testid': 'symbol', 'id': 'mySymbol'},
              [
                circle({'cx': 50, 'cy': 50, 'r': 40}),
              ],
            ),
          ]),
          use({'data-testid': 'use', 'href': '#mySymbol'}),
        ],
      ),
    );

    final result = render(fc(component));
    expect(result.getByTestId('symbol').getAttribute('id'), equals('mySymbol'));
    expect(result.getByTestId('use').getAttribute('href'), equals('#mySymbol'));
    result.unmount();
  });

  test('marker element renders', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          defs(null, [
            marker(
              {
                'data-testid': 'marker',
                'id': 'arrow',
                'markerWidth': 10,
                'markerHeight': 10,
              },
              [
                path({'d': 'M0,0 L10,5 L0,10 Z'}),
              ],
            ),
          ]),
        ],
      ),
    );

    final result = render(fc(component));
    expect(result.getByTestId('marker').getAttribute('id'), equals('arrow'));
    result.unmount();
  });

  test('pattern element renders', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          defs(null, [
            patternSvg(
              {
                'data-testid': 'pattern',
                'id': 'dots',
                'patternUnits': 'userSpaceOnUse',
                'width': 10,
                'height': 10,
              },
              [
                circle({'cx': 5, 'cy': 5, 'r': 2}),
              ],
            ),
          ]),
        ],
      ),
    );

    final result = render(fc(component));
    expect(result.getByTestId('pattern').getAttribute('id'), equals('dots'));
    result.unmount();
  });

  test('descriptive elements render', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          titleSvg({'data-testid': 'title'}, []),
          desc({'data-testid': 'desc'}, []),
          metadata({'data-testid': 'metadata'}, []),
        ],
      ),
    );

    final result = render(fc(component));
    expect(result.getByTestId('title'), isNotNull);
    expect(result.getByTestId('desc'), isNotNull);
    expect(result.getByTestId('metadata'), isNotNull);
    result.unmount();
  });

  test('foreignObject element renders', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          foreignObject({
            'data-testid': 'foreign',
            'x': 10,
            'y': 10,
            'width': 100,
            'height': 50,
          }, []),
        ],
      ),
    );

    final result = render(fc(component));
    expect(result.getByTestId('foreign').getAttribute('width'), equals('100'));
    result.unmount();
  });

  test('animation elements render', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          rect({
            'data-testid': 'rect',
            'x': 10,
            'y': 10,
            'width': 50,
            'height': 50,
          }),
          animate({
            'data-testid': 'animate',
            'attributeName': 'x',
            'from': 10,
            'to': 100,
            'dur': '1s',
          }),
          animateTransform({
            'data-testid': 'animateTransform',
            'attributeName': 'transform',
            'type': 'rotate',
          }),
        ],
      ),
    );

    final result = render(fc(component));
    expect(
      result.getByTestId('animate').getAttribute('attributeName'),
      equals('x'),
    );
    expect(
      result.getByTestId('animateTransform').getAttribute('type'),
      equals('rotate'),
    );
    result.unmount();
  });

  test('svgElement generic factory works', () {
    final component = registerFunctionComponent(
      (props) => svgElement(
        'svg',
        {'data-testid': 'custom-svg'},
        [
          svgElement('custom-element', {'data-testid': 'custom'}),
        ],
      ),
    );

    final result = render(fc(component));
    expect(result.getByTestId('custom-svg'), isNotNull);
    expect(result.getByTestId('custom'), isNotNull);
    result.unmount();
  });

  test('filter primitive elements render', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          defs(null, [
            filter(
              {'id': 'effects'},
              [
                feBlend({'data-testid': 'feBlend', 'mode': 'multiply'}),
                feColorMatrix({
                  'data-testid': 'feColorMatrix',
                  'type': 'saturate',
                }),
                feComposite({'data-testid': 'feComposite', 'operator': 'over'}),
                feFlood({'data-testid': 'feFlood', 'flood-color': 'red'}),
                feOffset({'data-testid': 'feOffset', 'dx': 5, 'dy': 5}),
                feMerge(null, [
                  feMergeNode({'in': 'SourceGraphic'}),
                ]),
              ],
            ),
          ]),
        ],
      ),
    );

    final result = render(fc(component));
    expect(
      result.getByTestId('feBlend').getAttribute('mode'),
      equals('multiply'),
    );
    expect(
      result.getByTestId('feColorMatrix').getAttribute('type'),
      equals('saturate'),
    );
    expect(
      result.getByTestId('feComposite').getAttribute('operator'),
      equals('over'),
    );
    expect(
      result.getByTestId('feFlood').getAttribute('flood-color'),
      equals('red'),
    );
    expect(result.getByTestId('feOffset').getAttribute('dx'), equals('5'));
    result.unmount();
  });

  test('image and view elements render', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          imageSvg({
            'data-testid': 'image',
            'href': 'test.png',
            'width': 100,
            'height': 100,
          }),
          view({'data-testid': 'view', 'viewBox': '0 0 50 50'}),
        ],
      ),
    );

    final result = render(fc(component));
    expect(
      result.getByTestId('image').getAttribute('href'),
      equals('test.png'),
    );
    expect(
      result.getByTestId('view').getAttribute('viewBox'),
      equals('0 0 50 50'),
    );
    result.unmount();
  });

  test('textPath element renders', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          defs(null, [
            path({'id': 'textPath', 'd': 'M10 80 Q 95 10 180 80'}),
          ]),
          textSvg(null, [
            textPath({'data-testid': 'textPath', 'href': '#textPath'}, []),
          ]),
        ],
      ),
    );

    final result = render(fc(component));
    expect(
      result.getByTestId('textPath').getAttribute('href'),
      equals('#textPath'),
    );
    result.unmount();
  });

  test('svgSwitch element renders', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          svgSwitch(
            {'data-testid': 'switch'},
            [
              textSvg({'systemLanguage': 'en'}, []),
            ],
          ),
        ],
      ),
    );

    final result = render(fc(component));
    expect(result.getByTestId('switch'), isNotNull);
    result.unmount();
  });

  test('animateMotion with mpath renders', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          defs(null, [
            path({'id': 'motionPath', 'd': 'M20,50 C20,-50 180,150 180,50'}),
          ]),
          circle({'r': 5}),
          animateMotion(
            {'data-testid': 'animateMotion', 'dur': '5s'},
            [
              mpath({'href': '#motionPath'}),
            ],
          ),
        ],
      ),
    );

    final result = render(fc(component));
    expect(
      result.getByTestId('animateMotion').getAttribute('dur'),
      equals('5s'),
    );
    result.unmount();
  });

  test('additional filter elements render', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          defs(null, [
            filter(
              {'id': 'moreFilters'},
              [
                feConvolveMatrix({
                  'data-testid': 'feConvolve',
                  'kernelMatrix': '1 0 0 0 1 0 0 0 1',
                }),
                feDisplacementMap({'data-testid': 'feDisplace', 'scale': 10}),
                feDropShadow({'data-testid': 'feShadow', 'dx': 3, 'dy': 3}),
                feImage({'data-testid': 'feImage', 'href': 'image.png'}),
                feMorphology({
                  'data-testid': 'feMorph',
                  'operator': 'dilate',
                  'radius': 2,
                }),
                feTile({'data-testid': 'feTile'}),
                feTurbulence({'data-testid': 'feTurb', 'type': 'fractalNoise'}),
              ],
            ),
          ]),
        ],
      ),
    );

    final result = render(fc(component));
    expect(result.getByTestId('feConvolve'), isNotNull);
    expect(
      result.getByTestId('feDisplace').getAttribute('scale'),
      equals('10'),
    );
    expect(result.getByTestId('feShadow').getAttribute('dx'), equals('3'));
    expect(
      result.getByTestId('feImage').getAttribute('href'),
      equals('image.png'),
    );
    expect(
      result.getByTestId('feMorph').getAttribute('operator'),
      equals('dilate'),
    );
    expect(result.getByTestId('feTile'), isNotNull);
    expect(
      result.getByTestId('feTurb').getAttribute('type'),
      equals('fractalNoise'),
    );
    result.unmount();
  });

  test('lighting filter elements render', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          defs(null, [
            filter(
              {'id': 'lighting'},
              [
                feDiffuseLighting(
                  {'data-testid': 'feDiffuse', 'lighting-color': 'white'},
                  [
                    feDistantLight({'data-testid': 'feDistant', 'azimuth': 45}),
                  ],
                ),
                feSpecularLighting(
                  {'data-testid': 'feSpecular', 'specularExponent': 20},
                  [
                    fePointLight({
                      'data-testid': 'fePoint',
                      'x': 50,
                      'y': 50,
                      'z': 100,
                    }),
                  ],
                ),
                feSpotLight({
                  'data-testid': 'feSpot',
                  'x': 50,
                  'y': 50,
                  'z': 200,
                }),
              ],
            ),
          ]),
        ],
      ),
    );

    final result = render(fc(component));
    expect(
      result.getByTestId('feDiffuse').getAttribute('lighting-color'),
      equals('white'),
    );
    expect(
      result.getByTestId('feDistant').getAttribute('azimuth'),
      equals('45'),
    );
    expect(
      result.getByTestId('feSpecular').getAttribute('specularExponent'),
      equals('20'),
    );
    expect(result.getByTestId('fePoint').getAttribute('z'), equals('100'));
    expect(result.getByTestId('feSpot').getAttribute('z'), equals('200'));
    result.unmount();
  });

  test('feComponentTransfer with func elements render', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          defs(null, [
            filter(
              {'id': 'component'},
              [
                feComponentTransfer(
                  {'data-testid': 'feComponent'},
                  [
                    feFuncR({
                      'data-testid': 'funcR',
                      'type': 'linear',
                      'slope': 0.5,
                    }),
                    feFuncG({
                      'data-testid': 'funcG',
                      'type': 'linear',
                      'slope': 0.5,
                    }),
                    feFuncB({
                      'data-testid': 'funcB',
                      'type': 'linear',
                      'slope': 0.5,
                    }),
                    feFuncA({'data-testid': 'funcA', 'type': 'identity'}),
                  ],
                ),
              ],
            ),
          ]),
        ],
      ),
    );

    final result = render(fc(component));
    expect(result.getByTestId('feComponent'), isNotNull);
    expect(result.getByTestId('funcR').getAttribute('type'), equals('linear'));
    expect(result.getByTestId('funcG').getAttribute('slope'), equals('0.5'));
    expect(result.getByTestId('funcB'), isNotNull);
    expect(
      result.getByTestId('funcA').getAttribute('type'),
      equals('identity'),
    );
    result.unmount();
  });

  test('svgSet element renders', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          rect({'id': 'myRect'}),
          svgSet({
            'data-testid': 'set',
            'attributeName': 'fill',
            'to': 'red',
            'begin': '1s',
          }),
        ],
      ),
    );

    final result = render(fc(component));
    expect(
      result.getByTestId('set').getAttribute('attributeName'),
      equals('fill'),
    );
    expect(result.getByTestId('set').getAttribute('to'), equals('red'));
    result.unmount();
  });

  test('mesh elements render', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          defs(null, [
            meshgradient(
              {'data-testid': 'meshgrad', 'id': 'mesh1'},
              [
                meshrow(
                  {'data-testid': 'meshrow'},
                  [
                    meshpatch({'data-testid': 'meshpatch'}, []),
                  ],
                ),
              ],
            ),
          ]),
          mesh({'data-testid': 'mesh'}, []),
        ],
      ),
    );

    final result = render(fc(component));
    expect(result.getByTestId('meshgrad').getAttribute('id'), equals('mesh1'));
    expect(result.getByTestId('meshrow'), isNotNull);
    expect(result.getByTestId('meshpatch'), isNotNull);
    expect(result.getByTestId('mesh'), isNotNull);
    result.unmount();
  });

  test('hatch elements render', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          defs(null, [
            hatch(
              {'data-testid': 'hatch', 'id': 'hatch1'},
              [
                hatchpath({'data-testid': 'hatchpath', 'd': 'M0,0 l10,10'}),
              ],
            ),
          ]),
        ],
      ),
    );

    final result = render(fc(component));
    expect(result.getByTestId('hatch').getAttribute('id'), equals('hatch1'));
    expect(
      result.getByTestId('hatchpath').getAttribute('d'),
      equals('M0,0 l10,10'),
    );
    result.unmount();
  });

  test('deprecated/legacy elements render', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          defs(null, [
            font(
              {'data-testid': 'font'},
              [
                glyph({'data-testid': 'glyph'}, []),
                missingGlyph({'data-testid': 'missing-glyph'}, []),
              ],
            ),
            altGlyph({'data-testid': 'altGlyph'}, []),
            altGlyphDef(
              {'data-testid': 'altGlyphDef'},
              [
                altGlyphItem({'data-testid': 'altGlyphItem'}, []),
              ],
            ),
          ]),
          glyphRef({'data-testid': 'glyphRef'}),
          tref({'data-testid': 'tref'}),
          colorProfile({'data-testid': 'colorProfile'}),
          cursor({'data-testid': 'cursor'}),
          fontFace({'data-testid': 'fontFace'}),
          fontFaceFormat({'data-testid': 'fontFaceFormat'}),
          fontFaceName({'data-testid': 'fontFaceName'}),
          fontFaceSrc(
            {'data-testid': 'fontFaceSrc'},
            [
              fontFaceUri({'data-testid': 'fontFaceUri'}),
            ],
          ),
          hkern({'data-testid': 'hkern'}),
          vkern({'data-testid': 'vkern'}),
          animateColor({'data-testid': 'animateColor'}),
        ],
      ),
    );

    final result = render(fc(component));
    expect(result.getByTestId('font'), isNotNull);
    expect(result.getByTestId('glyph'), isNotNull);
    expect(result.getByTestId('missing-glyph'), isNotNull);
    expect(result.getByTestId('altGlyph'), isNotNull);
    expect(result.getByTestId('altGlyphDef'), isNotNull);
    expect(result.getByTestId('altGlyphItem'), isNotNull);
    expect(result.getByTestId('glyphRef'), isNotNull);
    expect(result.getByTestId('tref'), isNotNull);
    expect(result.getByTestId('colorProfile'), isNotNull);
    expect(result.getByTestId('cursor'), isNotNull);
    expect(result.getByTestId('fontFace'), isNotNull);
    expect(result.getByTestId('fontFaceFormat'), isNotNull);
    expect(result.getByTestId('fontFaceName'), isNotNull);
    expect(result.getByTestId('fontFaceSrc'), isNotNull);
    expect(result.getByTestId('fontFaceUri'), isNotNull);
    expect(result.getByTestId('hkern'), isNotNull);
    expect(result.getByTestId('vkern'), isNotNull);
    expect(result.getByTestId('animateColor'), isNotNull);
    result.unmount();
  });

  test('solidcolor and discard elements render', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          defs(null, [
            solidcolor({'data-testid': 'solidcolor', 'solid-color': 'blue'}),
          ]),
          discard({'data-testid': 'discard', 'begin': '5s'}),
        ],
      ),
    );

    final result = render(fc(component));
    expect(
      result.getByTestId('solidcolor').getAttribute('solid-color'),
      equals('blue'),
    );
    expect(result.getByTestId('discard').getAttribute('begin'), equals('5s'));
    result.unmount();
  });

  test('unknown element renders', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          unknown({'data-testid': 'unknown'}, []),
        ],
      ),
    );

    final result = render(fc(component));
    expect(result.getByTestId('unknown'), isNotNull);
    result.unmount();
  });

  test('elements render without props', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          g(null, [
            circle(),
            rect(),
            ellipse(),
            line(),
            path(),
            polygon(),
            polyline(),
          ]),
        ],
      ),
    );

    final result = render(fc(component));
    expect(result.getByTestId('svg'), isNotNull);
    result.unmount();
  });

  test('elements render with no arguments', () {
    final component = registerFunctionComponent(
      (props) => svg(
        {'data-testid': 'svg'},
        [
          defs(),
          g(),
          symbol(),
          linearGradient(),
          radialGradient(),
          filter(),
          clipPath(),
          mask(),
          marker(),
          patternSvg(),
        ],
      ),
    );

    final result = render(fc(component));
    expect(result.getByTestId('svg'), isNotNull);
    result.unmount();
  });
}
