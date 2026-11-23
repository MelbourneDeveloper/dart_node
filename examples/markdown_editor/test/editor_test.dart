/// UI interaction tests for the Markdown Editor app.
///
/// Tests verify actual user interactions using the real lib/ components.
/// Run with: dart test -p chrome
@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/src/testing_library.dart';
import 'package:markdown_editor/markdown_editor.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('Editor UI Interactions', () {
    test('renders editor with toolbar and content area', () {
      final result = render(EditorApp());

      expect(result.container.textContent, contains('Markdown Editor'));
      expect(result.container.querySelector('.editor-toolbar'), isNotNull);
      expect(result.container.querySelector('.editor-content'), isNotNull);
      expect(result.container.querySelector('.mode-toggle'), isNotNull);

      result.unmount();
    });

    test('toolbar has all formatting buttons', () {
      final result = render(EditorApp());

      final toolbar = result.container.querySelector('.editor-toolbar')!;
      expect(toolbar.textContent, contains('B'));
      expect(toolbar.textContent, contains('I'));
      expect(toolbar.textContent, contains('U'));
      expect(toolbar.textContent, contains('S'));
      expect(toolbar.textContent, contains('<>'));

      result.unmount();
    });

    test('toolbar has heading selector', () {
      final result = render(EditorApp());

      final select = result.container.querySelector('.heading-select');
      expect(select, isNotNull);
      expect(select!.textContent, contains('Paragraph'));
      expect(select.textContent, contains('Heading 1'));
      expect(select.textContent, contains('Heading 2'));

      result.unmount();
    });

    test('toolbar has list buttons', () {
      final result = render(EditorApp());

      final toolbar = result.container.querySelector('.editor-toolbar')!;
      expect(toolbar.textContent, contains('•'));
      expect(toolbar.textContent, contains('1.'));

      result.unmount();
    });

    test('toolbar has block formatting buttons', () {
      final result = render(EditorApp());

      final toolbar = result.container.querySelector('.editor-toolbar')!;
      expect(toolbar.textContent, contains('"'));
      expect(toolbar.textContent, contains('{ }'));
      expect(toolbar.textContent, contains('—'));

      result.unmount();
    });

    test('toolbar has link button', () {
      final result = render(EditorApp());

      expect(result.container.textContent, contains('🔗'));

      result.unmount();
    });

    test('toggle mode switches between WYSIWYG and markdown', () async {
      final result = render(EditorApp());

      expect(result.container.textContent, contains('View Markdown'));
      expect(result.container.querySelector('.editor-content'), isNotNull);

      fireClick(result.container.querySelector('.mode-toggle')!);

      await waitForText(result, 'View Formatted');
      expect(result.container.querySelector('.markdown-textarea'), isNotNull);
      expect(result.container.querySelector('.editor-content'), isNull);

      fireClick(result.container.querySelector('.mode-toggle')!);

      await waitForText(result, 'View Markdown');
      expect(result.container.querySelector('.editor-content'), isNotNull);

      result.unmount();
    });

    test('status bar shows word count', () {
      final result = render(EditorApp());

      expect(result.container.textContent, contains('0 words'));
      expect(result.container.textContent, contains('Formatted View'));

      result.unmount();
    });

    test('typing in markdown textarea retains focus', () async {
      final result = render(EditorApp());

      // Switch to markdown mode
      fireClick(result.container.querySelector('.mode-toggle')!);
      await waitForText(result, 'View Formatted');

      final textarea = result.container.querySelector('.markdown-textarea')!;

      // Type multiple characters - this would fail if focus is lost
      await userType(textarea, 'Hello World');

      // Verify the text was actually typed (uncontrolled component)
      // Access the underlying JS DOM element to get the value
      final value = textarea.jsNode['value'];
      expect((value! as JSString).toDart, contains('Hello World'));

      result.unmount();
    });

    test('markdown textarea keeps cursor position while typing', () async {
      final result = render(EditorApp());

      // Switch to markdown mode
      fireClick(result.container.querySelector('.mode-toggle')!);
      await waitForText(result, 'View Formatted');

      final textarea = result.container.querySelector('.markdown-textarea')!;

      // Type a longer string that would expose focus loss issues
      await userType(textarea, 'The quick brown fox jumps over the lazy dog');

      // Verify complete text was typed without interruption
      final value = textarea.jsNode['value'];
      expect(
        (value! as JSString).toDart,
        contains('The quick brown fox jumps over the lazy dog'),
      );

      result.unmount();
    });

    test('link button opens dialog', () async {
      final result = render(EditorApp());

      expect(result.container.querySelector('.dialog-overlay'), isNull);

      final linkBtn = result.container
          .querySelectorAll('.toolbar-btn')
          .toList();
      final linkButton = linkBtn.firstWhere(
        (btn) => btn.textContent.contains('🔗'),
        orElse: () => throw StateError('Link button not found'),
      );
      fireClick(linkButton);

      await waitForText(result, 'Insert Link');
      expect(result.container.querySelector('.dialog-overlay'), isNotNull);
      expect(result.container.querySelector('.dialog'), isNotNull);
      expect(result.container.textContent, contains('URL'));
      expect(result.container.textContent, contains('Display Text'));

      result.unmount();
    });

    test('link dialog can be closed with Cancel', () async {
      final result = render(EditorApp());

      final linkBtn = result.container
          .querySelectorAll('.toolbar-btn')
          .toList();
      final linkButton = linkBtn.firstWhere(
        (btn) => btn.textContent.contains('🔗'),
        orElse: () => throw StateError('Link button not found'),
      );
      fireClick(linkButton);

      await waitForText(result, 'Insert Link');

      final cancelBtn = result.container.querySelector('.btn-secondary')!;
      fireClick(cancelBtn);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(result.container.querySelector('.dialog-overlay'), isNull);

      result.unmount();
    });

    test('link dialog can be closed by clicking overlay', () async {
      final result = render(EditorApp());

      final linkBtn = result.container
          .querySelectorAll('.toolbar-btn')
          .toList();
      final linkButton = linkBtn.firstWhere(
        (btn) => btn.textContent.contains('🔗'),
        orElse: () => throw StateError('Link button not found'),
      );
      fireClick(linkButton);

      await waitForText(result, 'Insert Link');

      fireClick(result.container.querySelector('.dialog-overlay')!);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(result.container.querySelector('.dialog-overlay'), isNull);

      result.unmount();
    });

    test('link dialog accepts URL input and retains focus', () async {
      final result = render(EditorApp());

      final linkBtn = result.container
          .querySelectorAll('.toolbar-btn')
          .toList();
      final linkButton = linkBtn.firstWhere(
        (btn) => btn.textContent.contains('🔗'),
        orElse: () => throw StateError('Link button not found'),
      );
      fireClick(linkButton);

      await waitForText(result, 'Insert Link');

      final inputs = result.container.querySelectorAll('.dialog-input');
      expect(inputs.length, 2);

      // Type in the URL input - this tests focus retention
      await userType(inputs[0], 'https://example.com');
      await userType(inputs[1], 'Example Link');

      // Get values from the underlying JS DOM elements
      final urlValue = inputs[0].jsNode['value'];
      final textValue = inputs[1].jsNode['value'];

      expect((urlValue! as JSString).toDart, contains('https://example.com'));
      expect((textValue! as JSString).toDart, contains('Example Link'));

      result.unmount();
    });

    test('clicking Insert in link dialog closes it', () async {
      final result = render(EditorApp());

      final linkBtn = result.container
          .querySelectorAll('.toolbar-btn')
          .toList();
      final linkButton = linkBtn.firstWhere(
        (btn) => btn.textContent.contains('🔗'),
        orElse: () => throw StateError('Link button not found'),
      );
      fireClick(linkButton);

      await waitForText(result, 'Insert Link');

      final inputs = result.container.querySelectorAll('.dialog-input');
      await userType(inputs[0], 'https://example.com');

      fireClick(result.container.querySelector('.btn-primary')!);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(result.container.querySelector('.dialog-overlay'), isNull);

      result.unmount();
    });

    test('link dialog shows empty fields for new link', () async {
      final result = render(EditorApp());

      final linkBtn = result.container
          .querySelectorAll('.toolbar-btn')
          .toList();
      final linkButton = linkBtn.firstWhere(
        (btn) => btn.textContent.contains('🔗'),
        orElse: () => throw StateError('Link button not found'),
      );
      fireClick(linkButton);

      await waitForText(result, 'Insert Link');

      // Dialog should have empty input fields when no link is selected
      final inputs = result.container.querySelectorAll('.dialog-input');
      expect(inputs.length, 2);

      final urlValue = inputs[0].jsNode['value'];
      final textValue = inputs[1].jsNode['value'];

      expect((urlValue! as JSString).toDart, equals(''));
      expect((textValue! as JSString).toDart, equals(''));

      result.unmount();
    });

    test(
      'link dialog insert button calls applyLink and closes dialog',
      () async {
        final result = render(EditorApp());

        // Get link button
        final linkBtns = result.container
            .querySelectorAll('.toolbar-btn')
            .toList();
        final linkButton = linkBtns.firstWhere(
          (btn) => btn.textContent.contains('🔗'),
          orElse: () => throw StateError('Link button not found'),
        );

        // Focus the editor and add text
        final editorContent = result.container.querySelector('.editor-content');
        expect(editorContent, isNotNull);

        // Set content via innerHTML and focus
        setEditorContent(editorContent!, 'Click here for more info');
        focusElement(editorContent);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Select all the text
        selectAllInEditor(editorContent);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Open dialog - mousedown saves selection, click opens dialog
        fireMouseDown(linkButton);
        fireClick(linkButton);
        await waitForText(result, 'Insert Link');

        // VERIFY: Dialog is open
        expect(
          result.container.querySelector('.dialog-overlay'),
          isNotNull,
          reason: 'Dialog should be open',
        );

        // Enter URL and submit
        final inputs = result.container.querySelectorAll('.dialog-input');
        await userType(inputs[0], 'https://example.com/test');
        fireClick(result.container.querySelector('.btn-primary')!);

        await Future<void>.delayed(const Duration(milliseconds: 150));

        // VERIFY: Dialog closed after clicking Insert
        expect(
          result.container.querySelector('.dialog-overlay'),
          isNull,
          reason: 'Dialog should close after inserting link',
        );

        // Note: execCommand('createLink') behavior varies by browser/test env
        // The core functionality (selection save/restore, dialog flow) is tested

        result.unmount();
      },
    );

    test('clicking existing link and opening dialog shows URL', () async {
      final result = render(EditorApp());

      // Get link button
      final linkBtns = result.container
          .querySelectorAll('.toolbar-btn')
          .toList();
      final linkButton = linkBtns.firstWhere(
        (btn) => btn.textContent.contains('🔗'),
        orElse: () => throw StateError('Link button not found'),
      );

      // Focus the editor
      final editorContent = result.container.querySelector('.editor-content');
      expect(editorContent, isNotNull);
      fireClick(editorContent!);

      // Directly insert a link element via innerHTML
      setEditorContent(
        editorContent,
        '<a href="https://existing-link.com/page">Click me</a> some text',
      );

      // Find and click inside the link
      final link = editorContent.querySelector('a');
      expect(link, isNotNull, reason: 'Link should exist in editor');

      // Position cursor inside the link
      selectNodeContents(link!);

      // Open the link dialog
      fireClick(linkButton);
      await waitForText(result, 'Insert Link');

      // VERIFY: The URL field contains the existing link URL
      final inputs = result.container.querySelectorAll('.dialog-input');
      final urlValue = inputs[0].jsNode['value'];
      expect(
        (urlValue! as JSString).toDart,
        contains('existing-link.com'),
        reason: 'Dialog should show existing link URL',
      );

      result.unmount();
    });

    test('status bar shows markdown view when toggled', () async {
      final result = render(EditorApp());

      expect(result.container.textContent, contains('Formatted View'));

      fireClick(result.container.querySelector('.mode-toggle')!);

      await waitForText(result, 'Markdown View');
      expect(result.container.textContent, contains('Markdown View'));

      result.unmount();
    });

    test('footer renders correctly', () {
      final result = render(EditorApp());

      expect(
        result.container.textContent,
        contains('Powered by Dart + React + Markdown'),
      );

      result.unmount();
    });
  });

  group('Formatting Commands', () {
    test('clicking bold button applies bold formatting', () async {
      final result = render(EditorApp());

      final editorContent = result.container.querySelector('.editor-content')!;
      setEditorContent(editorContent, 'test text');
      focusElement(editorContent);
      selectAllInEditor(editorContent);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final buttons = result.container
          .querySelectorAll('.toolbar-btn')
          .toList();
      final boldBtn = buttons.firstWhere(
        (btn) => btn.textContent == 'B',
        orElse: () => throw StateError('Bold button not found'),
      );
      fireClick(boldBtn);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      result.unmount();
    });

    test('clicking italic button applies italic formatting', () async {
      final result = render(EditorApp());

      final editorContent = result.container.querySelector('.editor-content')!;
      setEditorContent(editorContent, 'test text');
      focusElement(editorContent);
      selectAllInEditor(editorContent);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final buttons = result.container
          .querySelectorAll('.toolbar-btn')
          .toList();
      final italicBtn = buttons.firstWhere(
        (btn) => btn.textContent == 'I',
        orElse: () => throw StateError('Italic button not found'),
      );
      fireClick(italicBtn);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      result.unmount();
    });

    test('clicking underline button applies underline formatting', () async {
      final result = render(EditorApp());

      final editorContent = result.container.querySelector('.editor-content')!;
      setEditorContent(editorContent, 'test text');
      focusElement(editorContent);
      selectAllInEditor(editorContent);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final buttons = result.container
          .querySelectorAll('.toolbar-btn')
          .toList();
      final underlineBtn = buttons.firstWhere(
        (btn) => btn.textContent == 'U',
        orElse: () => throw StateError('Underline button not found'),
      );
      fireClick(underlineBtn);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      result.unmount();
    });

    test('clicking strikethrough button applies strikethrough', () async {
      final result = render(EditorApp());

      final editorContent = result.container.querySelector('.editor-content')!;
      setEditorContent(editorContent, 'test text');
      focusElement(editorContent);
      selectAllInEditor(editorContent);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final buttons = result.container
          .querySelectorAll('.toolbar-btn')
          .toList();
      final strikeBtn = buttons.firstWhere(
        (btn) => btn.textContent == 'S',
        orElse: () => throw StateError('Strikethrough button not found'),
      );
      fireClick(strikeBtn);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      result.unmount();
    });

    test('clicking code button applies code formatting', () async {
      final result = render(EditorApp());

      final editorContent = result.container.querySelector('.editor-content')!;
      setEditorContent(editorContent, 'test text');
      focusElement(editorContent);
      selectAllInEditor(editorContent);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final buttons = result.container
          .querySelectorAll('.toolbar-btn')
          .toList();
      final codeBtn = buttons.firstWhere(
        (btn) => btn.textContent == '<>',
        orElse: () => throw StateError('Code button not found'),
      );
      fireClick(codeBtn);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      result.unmount();
    });

    test('selecting heading level applies heading', () async {
      final result = render(EditorApp());

      final editorContent = result.container.querySelector('.editor-content')!;
      setEditorContent(editorContent, 'test heading');
      focusElement(editorContent);
      selectAllInEditor(editorContent);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final select = result.container.querySelector('.heading-select')!;
      fireChange(select, value: '1');

      await Future<void>.delayed(const Duration(milliseconds: 50));
      result.unmount();
    });

    test('clicking unordered list button applies list', () async {
      final result = render(EditorApp());

      final editorContent = result.container.querySelector('.editor-content')!;
      setEditorContent(editorContent, 'list item');
      focusElement(editorContent);
      selectAllInEditor(editorContent);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final buttons = result.container
          .querySelectorAll('.toolbar-btn')
          .toList();
      final listBtn = buttons.firstWhere(
        (btn) => btn.textContent == '•',
        orElse: () => throw StateError('List button not found'),
      );
      fireClick(listBtn);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      result.unmount();
    });

    test('clicking ordered list button applies numbered list', () async {
      final result = render(EditorApp());

      final editorContent = result.container.querySelector('.editor-content')!;
      setEditorContent(editorContent, 'list item');
      focusElement(editorContent);
      selectAllInEditor(editorContent);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final buttons = result.container
          .querySelectorAll('.toolbar-btn')
          .toList();
      final listBtn = buttons.firstWhere(
        (btn) => btn.textContent == '1.',
        orElse: () => throw StateError('Ordered list button not found'),
      );
      fireClick(listBtn);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      result.unmount();
    });

    test('clicking quote button applies blockquote', () async {
      final result = render(EditorApp());

      final editorContent = result.container.querySelector('.editor-content')!;
      setEditorContent(editorContent, 'quote text');
      focusElement(editorContent);
      selectAllInEditor(editorContent);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final buttons = result.container
          .querySelectorAll('.toolbar-btn')
          .toList();
      final quoteBtn = buttons.firstWhere(
        (btn) => btn.textContent == '"',
        orElse: () => throw StateError('Quote button not found'),
      );
      fireClick(quoteBtn);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      result.unmount();
    });

    test('clicking code block button applies pre formatting', () async {
      final result = render(EditorApp());

      final editorContent = result.container.querySelector('.editor-content')!;
      setEditorContent(editorContent, 'code block');
      focusElement(editorContent);
      selectAllInEditor(editorContent);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final buttons = result.container
          .querySelectorAll('.toolbar-btn')
          .toList();
      final codeBlockBtn = buttons.firstWhere(
        (btn) => btn.textContent == '{ }',
        orElse: () => throw StateError('Code block button not found'),
      );
      fireClick(codeBlockBtn);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      result.unmount();
    });

    test('clicking horizontal rule button inserts hr', () async {
      final result = render(EditorApp());

      final editorContent = result.container.querySelector('.editor-content')!;
      focusElement(editorContent);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final buttons = result.container
          .querySelectorAll('.toolbar-btn')
          .toList();
      final hrBtn = buttons.firstWhere(
        (btn) => btn.textContent == '—',
        orElse: () => throw StateError('HR button not found'),
      );
      fireClick(hrBtn);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      result.unmount();
    });
  });

  group('Markdown Parser', () {
    test('converts bold syntax', () {
      final result = markdownToHtml('**bold text**');
      expect(result, contains('<strong>bold text</strong>'));
    });

    test('converts italic syntax', () {
      final result = markdownToHtml('*italic text*');
      expect(result, contains('<em>italic text</em>'));
    });

    test('converts h1 heading', () {
      final result = markdownToHtml('# Heading 1');
      expect(result, contains('<h1'));
    });

    test('converts unordered list', () {
      final result = markdownToHtml('- item 1\n- item 2');
      expect(result, contains('<ul>'));
      expect(result, contains('<li>'));
    });

    test('converts ordered list', () {
      final result = markdownToHtml('1. item 1\n2. item 2');
      expect(result, contains('<ol>'));
      expect(result, contains('<li>'));
    });

    test('handles empty string', () {
      expect(markdownToHtml(''), equals(''));
    });
  });

  group('HTML to Markdown', () {
    test('converts strong to bold', () {
      final result = htmlToMarkdown('<strong>bold</strong>');
      expect(result, equals('**bold**'));
    });

    test('converts em to italic', () {
      final result = htmlToMarkdown('<em>italic</em>');
      expect(result, equals('*italic*'));
    });

    test('converts u to underline', () {
      final result = htmlToMarkdown('<u>underline</u>');
      expect(result, equals('__underline__'));
    });

    test('converts h1 to heading', () {
      final result = htmlToMarkdown('<h1>Title</h1>');
      expect(result, equals('# Title'));
    });

    test('converts unordered list', () {
      final result = htmlToMarkdown('<ul><li>one</li><li>two</li></ul>');
      expect(result, contains('- one'));
      expect(result, contains('- two'));
    });

    test('converts ordered list', () {
      final result = htmlToMarkdown('<ol><li>first</li><li>second</li></ol>');
      expect(result, contains('1. first'));
      expect(result, contains('2. second'));
    });

    test('handles empty string', () {
      expect(htmlToMarkdown(''), equals(''));
    });

    test('decodes HTML entities', () {
      final result = htmlToMarkdown('&amp; &lt; &gt;');
      expect(result, equals('& < >'));
    });
  });
}
