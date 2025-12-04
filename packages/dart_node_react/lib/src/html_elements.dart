/// HTML element factory functions for React.
///
/// These functions create React elements for standard HTML tags. Each function
/// takes an optional props map, optional children list, and returns a
/// ReactElement.
library;

import 'dart:js_interop';

import 'package:dart_node_react/src/react.dart';

// =============================================================================
// Generic DOM Element Factory
// =============================================================================

/// Creates a React element for the given HTML tag name.
///
/// This is a low-level function. Prefer using the specific element functions
/// like `div`, `span`, `p`, etc.
ReactElement domElement(
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
// Document Metadata
// =============================================================================

/// Creates a `<base>` element.
ReactElement base([Map<String, Object?>? props]) =>
    createElement('base'.toJS, props != null ? createProps(props) : null);

/// Creates a `<head>` element.
ReactElement head([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('head', props, children);

/// Creates an `<html>` element.
ReactElement htmlEl([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('html', props, children);

/// Creates a `<link>` element.
ReactElement link([Map<String, Object?>? props]) =>
    createElement('link'.toJS, props != null ? createProps(props) : null);

/// Creates a `<meta>` element.
ReactElement meta([Map<String, Object?>? props]) =>
    createElement('meta'.toJS, props != null ? createProps(props) : null);

/// Creates a `<style>` element.
ReactElement styleEl([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('style', props, children);

/// Creates a `<title>` element.
ReactElement titleEl([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('title', props, children);

// =============================================================================
// Content Sectioning
// =============================================================================

/// Creates an `<address>` element.
ReactElement address([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('address', props, children);

/// Creates an `<article>` element.
ReactElement article([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('article', props, children);

/// Creates an `<aside>` element.
ReactElement aside([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('aside', props, children);

/// Creates a `<body>` element.
ReactElement body([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('body', props, children);

/// Creates a `<hgroup>` element.
ReactElement hgroup([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('hgroup', props, children);

/// Creates a `<nav>` element.
ReactElement nav([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('nav', props, children);

/// Creates a `<search>` element.
ReactElement search([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('search', props, children);

/// Creates a `<section>` element.
ReactElement section([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('section', props, children);

// =============================================================================
// Text Content
// =============================================================================

/// Creates a `<blockquote>` element.
ReactElement blockquote([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('blockquote', props, children);

/// Creates a `<dd>` element.
ReactElement dd([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('dd', props, children);

/// Creates a `<dl>` element.
ReactElement dl([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('dl', props, children);

/// Creates a `<dt>` element.
ReactElement dt([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('dt', props, children);

/// Creates a `<figcaption>` element.
ReactElement figcaption([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('figcaption', props, children);

/// Creates a `<figure>` element.
ReactElement figure([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('figure', props, children);

/// Creates an `<hr>` element.
ReactElement hr([Map<String, Object?>? props]) =>
    createElement('hr'.toJS, props != null ? createProps(props) : null);

/// Creates a `<menu>` element.
ReactElement menu([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('menu', props, children);

/// Creates an `<ol>` element.
ReactElement ol([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('ol', props, children);

/// Creates a `<pre>` element.
ReactElement pre([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('pre', props, children);

// =============================================================================
// Inline Text Semantics
// =============================================================================

/// Creates an `<a>` element.
ReactElement aEl([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('a', props, children);

/// Creates an `<abbr>` element.
ReactElement abbr([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('abbr', props, children);

/// Creates a `<b>` element.
ReactElement b([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('b', props, children);

/// Creates a `<bdi>` element.
ReactElement bdi([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('bdi', props, children);

/// Creates a `<bdo>` element.
ReactElement bdo([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('bdo', props, children);

/// Creates a `<br>` element.
ReactElement br([Map<String, Object?>? props]) =>
    createElement('br'.toJS, props != null ? createProps(props) : null);

/// Creates a `<cite>` element.
ReactElement cite([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('cite', props, children);

/// Creates a `<code>` element.
ReactElement code([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('code', props, children);

/// Creates a `<data>` element.
ReactElement dataEl([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('data', props, children);

/// Creates a `<dfn>` element.
ReactElement dfn([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('dfn', props, children);

/// Creates an `<em>` element.
ReactElement em([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('em', props, children);

/// Creates an `<i>` element.
ReactElement i([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('i', props, children);

/// Creates a `<kbd>` element.
ReactElement kbd([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('kbd', props, children);

/// Creates a `<mark>` element.
ReactElement mark([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('mark', props, children);

/// Creates a `<q>` element.
ReactElement q([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('q', props, children);

/// Creates an `<rp>` element.
ReactElement rp([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('rp', props, children);

/// Creates an `<rt>` element.
ReactElement rt([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('rt', props, children);

/// Creates a `<ruby>` element.
ReactElement ruby([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('ruby', props, children);

/// Creates an `<s>` element.
ReactElement s([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('s', props, children);

/// Creates a `<samp>` element.
ReactElement samp([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('samp', props, children);

/// Creates a `<small>` element.
ReactElement small([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('small', props, children);

/// Creates a `<strong>` element.
ReactElement strong([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('strong', props, children);

/// Creates a `<sub>` element.
ReactElement sub([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('sub', props, children);

/// Creates a `<sup>` element.
ReactElement sup([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('sup', props, children);

/// Creates a `<time>` element.
ReactElement time([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('time', props, children);

/// Creates a `<u>` element.
ReactElement u([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('u', props, children);

/// Creates a `<var>` element.
ReactElement variable([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('var', props, children);

/// Creates a `<wbr>` element.
ReactElement wbr([Map<String, Object?>? props]) =>
    createElement('wbr'.toJS, props != null ? createProps(props) : null);

// =============================================================================
// Image and Multimedia
// =============================================================================

/// Creates an `<area>` element.
ReactElement area([Map<String, Object?>? props]) =>
    createElement('area'.toJS, props != null ? createProps(props) : null);

/// Creates an `<audio>` element.
ReactElement audio([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('audio', props, children);

/// Creates a `<map>` element.
ReactElement mapEl([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('map', props, children);

/// Creates a `<track>` element.
ReactElement track([Map<String, Object?>? props]) =>
    createElement('track'.toJS, props != null ? createProps(props) : null);

/// Creates a `<video>` element.
ReactElement video([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('video', props, children);

// =============================================================================
// Embedded Content
// =============================================================================

/// Creates an `<embed>` element.
ReactElement embed([Map<String, Object?>? props]) =>
    createElement('embed'.toJS, props != null ? createProps(props) : null);

/// Creates an `<iframe>` element.
ReactElement iframe([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('iframe', props, children);

/// Creates an `<object>` element.
ReactElement objectEl([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('object', props, children);

/// Creates a `<picture>` element.
ReactElement picture([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('picture', props, children);

/// Creates a `<portal>` element.
ReactElement portal([Map<String, Object?>? props]) =>
    createElement('portal'.toJS, props != null ? createProps(props) : null);

/// Creates a `<source>` element.
ReactElement source([Map<String, Object?>? props]) =>
    createElement('source'.toJS, props != null ? createProps(props) : null);

// =============================================================================
// Scripting
// =============================================================================

/// Creates a `<canvas>` element.
ReactElement canvas([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('canvas', props, children);

/// Creates a `<noscript>` element.
ReactElement noscript([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('noscript', props, children);

/// Creates a `<script>` element.
ReactElement script([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('script', props, children);

// =============================================================================
// Demarcating Edits
// =============================================================================

/// Creates a `<del>` element.
ReactElement del([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('del', props, children);

/// Creates an `<ins>` element.
ReactElement ins([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('ins', props, children);

// =============================================================================
// Table Content
// =============================================================================

/// Creates a `<caption>` element.
ReactElement caption([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('caption', props, children);

/// Creates a `<col>` element.
ReactElement col([Map<String, Object?>? props]) =>
    createElement('col'.toJS, props != null ? createProps(props) : null);

/// Creates a `<colgroup>` element.
ReactElement colgroup([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('colgroup', props, children);

/// Creates a `<table>` element.
ReactElement table([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('table', props, children);

/// Creates a `<tbody>` element.
ReactElement tbody([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('tbody', props, children);

/// Creates a `<td>` element.
ReactElement td([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('td', props, children);

/// Creates a `<tfoot>` element.
ReactElement tfoot([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('tfoot', props, children);

/// Creates a `<th>` element.
ReactElement th([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('th', props, children);

/// Creates a `<thead>` element.
ReactElement thead([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('thead', props, children);

/// Creates a `<tr>` element.
ReactElement tr([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('tr', props, children);

// =============================================================================
// Forms
// =============================================================================

/// Creates a `<datalist>` element.
ReactElement datalist([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('datalist', props, children);

/// Creates a `<fieldset>` element.
ReactElement fieldset([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('fieldset', props, children);

/// Creates a `<form>` element.
ReactElement form([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('form', props, children);

/// Creates a `<label>` element.
ReactElement label([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('label', props, children);

/// Creates a `<legend>` element.
ReactElement legend([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('legend', props, children);

/// Creates a `<meter>` element.
ReactElement meter([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('meter', props, children);

/// Creates an `<optgroup>` element.
ReactElement optgroup([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('optgroup', props, children);

/// Creates an `<option>` element.
ReactElement option([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('option', props, children);

/// Creates an `<output>` element.
ReactElement output([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('output', props, children);

/// Creates a `<progress>` element.
ReactElement progress([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('progress', props, children);

/// Creates a `<select>` element.
ReactElement select([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('select', props, children);

/// Creates a `<textarea>` element.
ReactElement textarea([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('textarea', props, children);

// =============================================================================
// Interactive Elements
// =============================================================================

/// Creates a `<details>` element.
ReactElement details([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('details', props, children);

/// Creates a `<dialog>` element.
ReactElement dialog([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('dialog', props, children);

/// Creates a `<summary>` element.
ReactElement summaryEl([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('summary', props, children);

// =============================================================================
// Web Components
// =============================================================================

/// Creates a `<slot>` element.
ReactElement slot([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('slot', props, children);

/// Creates a `<template>` element.
ReactElement templateEl([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('template', props, children);

// =============================================================================
// Headings (h3-h6 not in main elements.dart)
// =============================================================================

/// Creates an `<h3>` element.
ReactElement h3([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('h3', props, children);

/// Creates an `<h4>` element.
ReactElement h4([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('h4', props, children);

/// Creates an `<h5>` element.
ReactElement h5([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('h5', props, children);

/// Creates an `<h6>` element.
ReactElement h6([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('h6', props, children);

// =============================================================================
// Deprecated/Legacy (for compatibility with react-dart)
// =============================================================================

/// Creates a `<big>` element (deprecated HTML).
ReactElement big([Map<String, Object?>? props, List<ReactElement>? children]) =>
    domElement('big', props, children);

/// Creates a `<keygen>` element (deprecated HTML).
ReactElement keygen([Map<String, Object?>? props]) =>
    createElement('keygen'.toJS, props != null ? createProps(props) : null);

/// Creates a `<menuitem>` element (deprecated HTML).
ReactElement menuitem([
  Map<String, Object?>? props,
  List<ReactElement>? children,
]) => domElement('menuitem', props, children);

/// Creates a `<param>` element.
ReactElement param([Map<String, Object?>? props]) =>
    createElement('param'.toJS, props != null ? createProps(props) : null);
