import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

class HtmlToDeltaHelper {
  static List<dynamic> htmlToDelta(String htmlContent) {
    if (htmlContent.trim().isEmpty) {
      return [{'insert': '\n'}];
    }
    
    final document = html_parser.parse(htmlContent);
    final List<Map<String, dynamic>> ops = [];
    
    void traverse(dom.Node node, Map<String, dynamic> currentAttributes) {
      if (node.nodeType == dom.Node.TEXT_NODE) {
        final text = node.text;
        if (text != null && text.isNotEmpty) {
          ops.add({
            'insert': text,
            if (currentAttributes.isNotEmpty) 'attributes': Map<String, dynamic>.from(currentAttributes),
          });
        }
      } else if (node.nodeType == dom.Node.ELEMENT_NODE) {
        final element = node as dom.Element;
        final newAttributes = Map<String, dynamic>.from(currentAttributes);
        
        switch (element.localName) {
          case 'strong':
          case 'b':
            newAttributes['bold'] = true;
            break;
          case 'em':
          case 'i':
            newAttributes['italic'] = true;
            break;
          case 'u':
            newAttributes['underline'] = true;
            break;
          case 'del':
          case 's':
          case 'strike':
            newAttributes['strike'] = true;
            break;
          case 'code':
            newAttributes['code'] = true;
            break;
          case 'a':
            newAttributes['link'] = element.attributes['href'];
            break;
        }
        
        for (final child in element.nodes) {
          traverse(child, newAttributes);
        }
        
        // Block formatting or newlines
        if (element.localName == 'p' || 
            element.localName == 'div' || 
            element.localName == 'h1' || 
            element.localName == 'h2' || 
            element.localName == 'h3' || 
            element.localName == 'br') {
          
          final blockAttributes = <String, dynamic>{};
          if (element.localName == 'h1') blockAttributes['header'] = 1;
          if (element.localName == 'h2') blockAttributes['header'] = 2;
          if (element.localName == 'h3') blockAttributes['header'] = 3;

          ops.add({
            'insert': '\n',
            if (blockAttributes.isNotEmpty) 'attributes': blockAttributes,
          });
        } else if (element.localName == 'li') {
          final parent = element.parent;
          final isOrdered = parent?.localName == 'ol';
          ops.add({
            'insert': '\n',
            'attributes': {
              'list': isOrdered ? 'ordered' : 'bullet',
            },
          });
        }
      }
    }
    
    for (final node in document.body?.nodes ?? []) {
      traverse(node, {});
    }
    
    // Ensure the delta ends with a newline if it doesn't already
    if (ops.isEmpty || !(ops.last['insert'] as String).endsWith('\n')) {
      ops.add({'insert': '\n'});
    }
    
    return ops;
  }
}
