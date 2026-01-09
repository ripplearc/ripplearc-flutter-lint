import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'models.dart';
import 'patterns.dart';
import 'context_checker.dart';

class TypeChecker {
  static bool isExcludedBySubtype(InstanceCreationExpression node) {
    try {
      final element = node.constructorName.staticElement;
      if (element == null) return false;
      final typeElement = element.returnType.element;
      if (typeElement is! ClassElement) return false;

      final classElement = typeElement;

      final excludedTypes = [
        ExcludedType('Widget', 'package:flutter/src/widgets/framework.dart'),
        ExcludedType('State', 'package:flutter/src/widgets/framework.dart'),
        ExcludedType('Equatable', 'package:equatable/equatable.dart'),
        ExcludedType('Event', 'package:bloc/bloc.dart'),
        ExcludedType('Exception', 'dart:core'),
        ExcludedType('Error', 'dart:core'),
        ExcludedType('StreamController', 'dart:async'),
        ExcludedType('TextEditingController', 'package:flutter/src/widgets/editable_text.dart'),
        ExcludedType('FocusNode', 'package:flutter/src/widgets/focus_manager.dart'),
        ExcludedType('Module', 'package:flutter_modular/flutter_modular.dart'),
        ExcludedType('Locale', 'package:flutter/src/localizations.dart'),
        ExcludedType('RegExp', 'dart:core'),
        ExcludedType('NumberFormat', 'package:intl/intl.dart'),
        ExcludedType('DateFormat', 'package:intl/intl.dart'),
        ExcludedType('Uri', 'dart:core'),
      ];

      for (final supertype in classElement.allSupertypes) {
        final supertypeElement = supertype.element;
        if (supertypeElement is! ClassElement) continue;

        if (supertypeElement.name == 'Object') continue;

        if (supertypeElement.name == 'Either') return true;
        if (supertypeElement.name.endsWith('State')) return true;

        final libraryUri = supertypeElement.library.source.uri.toString();

        for (final excludedType in excludedTypes) {
          if (supertypeElement.name == excludedType.name &&
              DirectInstantiationPatterns.matchesPackage(libraryUri, excludedType.package)) {
            return true;
          }
        }
      }

      for (final interface in classElement.interfaces) {
        final interfaceElement = interface.element;
        if (interfaceElement is! ClassElement) continue;

        final libraryUri = interfaceElement.library.source.uri.toString();
        if ((interfaceElement.name == 'Exception' || interfaceElement.name == 'Error') &&
            libraryUri == 'dart:core') {
          return true;
        }
      }

      final libraryUri = classElement.library.source.uri.toString();
      if (classElement.name == 'Either') return true;
      if (DirectInstantiationPatterns.isDomainEntity(libraryUri)) return true;

      for (final excludedType in excludedTypes) {
        if (classElement.name == excludedType.name &&
            DirectInstantiationPatterns.matchesPackage(libraryUri, excludedType.package)) {
          return true;
        }
      }

      if (DirectInstantiationPatterns.isExcludedByPackage(libraryUri)) return true;

      return false;
    } catch (e) {
      return false;
    }
  }

  static bool isSealedClass(InstanceCreationExpression node) {
    try {
      final element = node.constructorName.staticElement;
      if (element == null) return false;
      final typeElement = element.returnType.element;
      if (typeElement is! ClassElement) return false;

      final classDecl = ContextChecker.findClassDeclaration(typeElement.name, node);
      if (classDecl != null) {
        final source = classDecl.toSource();
        if (source.contains('sealed class') || source.startsWith('sealed ')) return true;
      }

      for (final supertype in typeElement.allSupertypes) {
        if (supertype.element.name == 'Object') continue;
        if (supertype.element.name.endsWith('Event')) return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}

