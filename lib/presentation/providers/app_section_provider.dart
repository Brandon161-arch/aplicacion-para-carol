import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppSection { design, create, explore }

class AppSectionController extends Notifier<AppSection> {
  @override
  AppSection build() => AppSection.design;

  void select(AppSection section) => state = section;
}

final appSectionProvider = NotifierProvider<AppSectionController, AppSection>(
  AppSectionController.new,
);
