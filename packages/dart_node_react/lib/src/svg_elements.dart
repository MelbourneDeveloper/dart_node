/// SVG element factory functions for React.
///
/// These functions create React elements for SVG tags. Each function
/// takes an optional props map, optional children list, and returns a
/// ReactElement.
library;

import 'dart:js_interop';

import 'package:dart_node_react/src/react.dart';

// =============================================================================
// Generic SVG Element Factory
// =============================================================================

/// Creates a React element for the given SVG tag name.
ReactElement svgElement(
  String tagName, [
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => (children != null && children.isNotEmpty)
    ? createElementWithChildren(
        tagName.toJS,
        props != null ? createProps(props) : null,
        children,
      )
    : createElement(tagName.toJS, props != null ? createProps(props) : null);

// =============================================================================
// Container Elements
// =============================================================================

/// Creates an `<svg>` element.
ReactElement svg([Map<String, Object?>? props, List<ReactElement>? children]) =>
    svgElement('svg', props, children);

/// Creates a `<g>` element (group).
ReactElement g([Map<String, Object?>? props, List<ReactElement>? children]) =>
    svgElement('g', props, children);

/// Creates a `<defs>` element.
ReactElement defs([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('defs', props, children);

/// Creates a `<symbol>` element.
ReactElement symbol([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('symbol', props, children);

/// Creates a `<use>` element.
ReactElement use([Map<String, Object?>? props]) =>
    createElement('use'.toJS, props != null ? createProps(props) : null);

// =============================================================================
// Shape Elements
// =============================================================================

/// Creates a `<circle>` element.
ReactElement circle([Map<String, Object?>? props]) =>
    createElement('circle'.toJS, props != null ? createProps(props) : null);

/// Creates an `<ellipse>` element.
ReactElement ellipse([Map<String, Object?>? props]) =>
    createElement('ellipse'.toJS, props != null ? createProps(props) : null);

/// Creates a `<line>` element.
ReactElement line([Map<String, Object?>? props]) =>
    createElement('line'.toJS, props != null ? createProps(props) : null);

/// Creates a `<path>` element.
ReactElement path([Map<String, Object?>? props]) =>
    createElement('path'.toJS, props != null ? createProps(props) : null);

/// Creates a `<polygon>` element.
ReactElement polygon([Map<String, Object?>? props]) =>
    createElement('polygon'.toJS, props != null ? createProps(props) : null);

/// Creates a `<polyline>` element.
ReactElement polyline([Map<String, Object?>? props]) =>
    createElement('polyline'.toJS, props != null ? createProps(props) : null);

/// Creates a `<rect>` element.
ReactElement rect([Map<String, Object?>? props]) =>
    createElement('rect'.toJS, props != null ? createProps(props) : null);

// =============================================================================
// Text Elements
// =============================================================================

/// Creates a `<text>` element.
ReactElement textSvg([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('text', props, children);

/// Creates a `<tspan>` element.
ReactElement tspan([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('tspan', props, children);

/// Creates a `<textPath>` element.
ReactElement textPath([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('textPath', props, children);

// =============================================================================
// Gradient Elements
// =============================================================================

/// Creates a `<linearGradient>` element.
ReactElement linearGradient([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('linearGradient', props, children);

/// Creates a `<radialGradient>` element.
ReactElement radialGradient([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('radialGradient', props, children);

/// Creates a `<stop>` element.
ReactElement stop([Map<String, Object?>? props]) =>
    createElement('stop'.toJS, props != null ? createProps(props) : null);

// =============================================================================
// Filter Elements
// =============================================================================

/// Creates a `<filter>` element.
ReactElement filter([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('filter', props, children);

/// Creates a `<feBlend>` element.
ReactElement feBlend([Map<String, Object?>? props]) =>
    createElement('feBlend'.toJS, props != null ? createProps(props) : null);

/// Creates a `<feColorMatrix>` element.
ReactElement feColorMatrix([Map<String, Object?>? props]) => createElement(
  'feColorMatrix'.toJS,
  props != null ? createProps(props) : null,
);

/// Creates a `<feComponentTransfer>` element.
ReactElement feComponentTransfer([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('feComponentTransfer', props, children);

/// Creates a `<feComposite>` element.
ReactElement feComposite([Map<String, Object?>? props]) => createElement(
  'feComposite'.toJS,
  props != null ? createProps(props) : null,
);

/// Creates a `<feConvolveMatrix>` element.
ReactElement feConvolveMatrix([Map<String, Object?>? props]) => createElement(
  'feConvolveMatrix'.toJS,
  props != null ? createProps(props) : null,
);

/// Creates a `<feDiffuseLighting>` element.
ReactElement feDiffuseLighting([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('feDiffuseLighting', props, children);

/// Creates a `<feDisplacementMap>` element.
ReactElement feDisplacementMap([Map<String, Object?>? props]) => createElement(
  'feDisplacementMap'.toJS,
  props != null ? createProps(props) : null,
);

/// Creates a `<feDistantLight>` element.
ReactElement feDistantLight([Map<String, Object?>? props]) => createElement(
  'feDistantLight'.toJS,
  props != null ? createProps(props) : null,
);

/// Creates a `<feDropShadow>` element.
ReactElement feDropShadow([Map<String, Object?>? props]) => createElement(
  'feDropShadow'.toJS,
  props != null ? createProps(props) : null,
);

/// Creates a `<feFlood>` element.
ReactElement feFlood([Map<String, Object?>? props]) =>
    createElement('feFlood'.toJS, props != null ? createProps(props) : null);

/// Creates a `<feFuncA>` element.
ReactElement feFuncA([Map<String, Object?>? props]) =>
    createElement('feFuncA'.toJS, props != null ? createProps(props) : null);

/// Creates a `<feFuncB>` element.
ReactElement feFuncB([Map<String, Object?>? props]) =>
    createElement('feFuncB'.toJS, props != null ? createProps(props) : null);

/// Creates a `<feFuncG>` element.
ReactElement feFuncG([Map<String, Object?>? props]) =>
    createElement('feFuncG'.toJS, props != null ? createProps(props) : null);

/// Creates a `<feFuncR>` element.
ReactElement feFuncR([Map<String, Object?>? props]) =>
    createElement('feFuncR'.toJS, props != null ? createProps(props) : null);

/// Creates a `<feGaussianBlur>` element.
ReactElement feGaussianBlur([Map<String, Object?>? props]) => createElement(
  'feGaussianBlur'.toJS,
  props != null ? createProps(props) : null,
);

/// Creates a `<feImage>` element.
ReactElement feImage([Map<String, Object?>? props]) =>
    createElement('feImage'.toJS, props != null ? createProps(props) : null);

/// Creates a `<feMerge>` element.
ReactElement feMerge([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('feMerge', props, children);

/// Creates a `<feMergeNode>` element.
ReactElement feMergeNode([Map<String, Object?>? props]) => createElement(
  'feMergeNode'.toJS,
  props != null ? createProps(props) : null,
);

/// Creates a `<feMorphology>` element.
ReactElement feMorphology([Map<String, Object?>? props]) => createElement(
  'feMorphology'.toJS,
  props != null ? createProps(props) : null,
);

/// Creates a `<feOffset>` element.
ReactElement feOffset([Map<String, Object?>? props]) =>
    createElement('feOffset'.toJS, props != null ? createProps(props) : null);

/// Creates a `<fePointLight>` element.
ReactElement fePointLight([Map<String, Object?>? props]) => createElement(
  'fePointLight'.toJS,
  props != null ? createProps(props) : null,
);

/// Creates a `<feSpecularLighting>` element.
ReactElement feSpecularLighting([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('feSpecularLighting', props, children);

/// Creates a `<feSpotLight>` element.
ReactElement feSpotLight([Map<String, Object?>? props]) => createElement(
  'feSpotLight'.toJS,
  props != null ? createProps(props) : null,
);

/// Creates a `<feTile>` element.
ReactElement feTile([Map<String, Object?>? props]) =>
    createElement('feTile'.toJS, props != null ? createProps(props) : null);

/// Creates a `<feTurbulence>` element.
ReactElement feTurbulence([Map<String, Object?>? props]) => createElement(
  'feTurbulence'.toJS,
  props != null ? createProps(props) : null,
);

// =============================================================================
// Clipping and Masking
// =============================================================================

/// Creates a `<clipPath>` element.
ReactElement clipPath([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('clipPath', props, children);

/// Creates a `<mask>` element.
ReactElement mask([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('mask', props, children);

// =============================================================================
// Markers
// =============================================================================

/// Creates a `<marker>` element.
ReactElement marker([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('marker', props, children);

// =============================================================================
// Patterns
// =============================================================================

/// Creates a `<pattern>` element.
ReactElement patternSvg([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('pattern', props, children);

// =============================================================================
// Descriptive Elements
// =============================================================================

/// Creates a `<desc>` element.
ReactElement desc([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('desc', props, children);

/// Creates a `<metadata>` element.
ReactElement metadata([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('metadata', props, children);

/// Creates a `<title>` element (SVG).
ReactElement titleSvg([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('title', props, children);

// =============================================================================
// Other Elements
// =============================================================================

/// Creates a `<foreignObject>` element.
ReactElement foreignObject([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('foreignObject', props, children);

/// Creates an `<image>` element (SVG).
ReactElement imageSvg([Map<String, Object?>? props]) =>
    createElement('image'.toJS, props != null ? createProps(props) : null);

/// Creates a `<switch>` element (SVG).
ReactElement svgSwitch([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('switch', props, children);

/// Creates a `<view>` element.
ReactElement view([Map<String, Object?>? props]) =>
    createElement('view'.toJS, props != null ? createProps(props) : null);

// =============================================================================
// Animation Elements
// =============================================================================

/// Creates an `<animate>` element.
ReactElement animate([Map<String, Object?>? props]) =>
    createElement('animate'.toJS, props != null ? createProps(props) : null);

/// Creates an `<animateMotion>` element.
ReactElement animateMotion([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('animateMotion', props, children);

/// Creates an `<animateTransform>` element.
ReactElement animateTransform([Map<String, Object?>? props]) => createElement(
  'animateTransform'.toJS,
  props != null ? createProps(props) : null,
);

/// Creates a `<mpath>` element.
ReactElement mpath([Map<String, Object?>? props]) =>
    createElement('mpath'.toJS, props != null ? createProps(props) : null);

/// Creates a `<set>` element (SVG).
ReactElement svgSet([Map<String, Object?>? props]) =>
    createElement('set'.toJS, props != null ? createProps(props) : null);

// =============================================================================
// Deprecated/Legacy SVG Elements (for compatibility with react-dart)
// =============================================================================

/// Creates an `<altGlyph>` element (deprecated SVG).
ReactElement altGlyph([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('altGlyph', props, children);

/// Creates an `<altGlyphDef>` element (deprecated SVG).
ReactElement altGlyphDef([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('altGlyphDef', props, children);

/// Creates an `<altGlyphItem>` element (deprecated SVG).
ReactElement altGlyphItem([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('altGlyphItem', props, children);

/// Creates an `<animateColor>` element (deprecated SVG).
ReactElement animateColor([Map<String, Object?>? props]) => createElement(
  'animateColor'.toJS,
  props != null ? createProps(props) : null,
);

/// Creates a `<color-profile>` element (deprecated SVG).
ReactElement colorProfile([Map<String, Object?>? props]) => createElement(
  'color-profile'.toJS,
  props != null ? createProps(props) : null,
);

/// Creates a `<cursor>` element (deprecated SVG).
ReactElement cursor([Map<String, Object?>? props]) =>
    createElement('cursor'.toJS, props != null ? createProps(props) : null);

/// Creates a `<discard>` element.
ReactElement discard([Map<String, Object?>? props]) =>
    createElement('discard'.toJS, props != null ? createProps(props) : null);

/// Creates a `<font>` element (deprecated SVG).
ReactElement font([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('font', props, children);

/// Creates a `<font-face>` element (deprecated SVG).
ReactElement fontFace([Map<String, Object?>? props]) =>
    createElement('font-face'.toJS, props != null ? createProps(props) : null);

/// Creates a `<font-face-format>` element (deprecated SVG).
ReactElement fontFaceFormat([Map<String, Object?>? props]) => createElement(
  'font-face-format'.toJS,
  props != null ? createProps(props) : null,
);

/// Creates a `<font-face-name>` element (deprecated SVG).
ReactElement fontFaceName([Map<String, Object?>? props]) => createElement(
  'font-face-name'.toJS,
  props != null ? createProps(props) : null,
);

/// Creates a `<font-face-src>` element (deprecated SVG).
ReactElement fontFaceSrc([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('font-face-src', props, children);

/// Creates a `<font-face-uri>` element (deprecated SVG).
ReactElement fontFaceUri([Map<String, Object?>? props]) => createElement(
  'font-face-uri'.toJS,
  props != null ? createProps(props) : null,
);

/// Creates a `<glyph>` element (deprecated SVG).
ReactElement glyph([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('glyph', props, children);

/// Creates a `<glyphRef>` element (deprecated SVG).
ReactElement glyphRef([Map<String, Object?>? props]) =>
    createElement('glyphRef'.toJS, props != null ? createProps(props) : null);

/// Creates a `<hatch>` element.
ReactElement hatch([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('hatch', props, children);

/// Creates a `<hatchpath>` element.
ReactElement hatchpath([Map<String, Object?>? props]) =>
    createElement('hatchpath'.toJS, props != null ? createProps(props) : null);

/// Creates a `<hkern>` element (deprecated SVG).
ReactElement hkern([Map<String, Object?>? props]) =>
    createElement('hkern'.toJS, props != null ? createProps(props) : null);

/// Creates a `<mesh>` element.
ReactElement mesh([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('mesh', props, children);

/// Creates a `<meshgradient>` element.
ReactElement meshgradient([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('meshgradient', props, children);

/// Creates a `<meshpatch>` element.
ReactElement meshpatch([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('meshpatch', props, children);

/// Creates a `<meshrow>` element.
ReactElement meshrow([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('meshrow', props, children);

/// Creates a `<missing-glyph>` element (deprecated SVG).
ReactElement missingGlyph([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('missing-glyph', props, children);

/// Creates a `<solidcolor>` element.
ReactElement solidcolor([Map<String, Object?>? props]) =>
    createElement('solidcolor'.toJS, props != null ? createProps(props) : null);

/// Creates a `<tref>` element (deprecated SVG).
ReactElement tref([Map<String, Object?>? props]) =>
    createElement('tref'.toJS, props != null ? createProps(props) : null);

/// Creates an `<unknown>` element.
ReactElement unknown([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => svgElement('unknown', props, children);

/// Creates a `<vkern>` element (deprecated SVG).
ReactElement vkern([Map<String, Object?>? props]) =>
    createElement('vkern'.toJS, props != null ? createProps(props) : null);
