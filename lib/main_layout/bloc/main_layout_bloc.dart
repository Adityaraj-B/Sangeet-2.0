import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── Tab Enum ────────────────────────────────────────────────────────────────

enum NavTab { listen, library, browse, profile }

typedef MainLayoutTab = NavTab;

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();
  @override
  List<Object?> get props => [];
}

class NavigationTabChanged extends NavigationEvent {
  final NavTab tab;
  const NavigationTabChanged(this.tab);
  @override
  List<Object?> get props => [tab];
}

typedef MainLayoutEvent = NavigationEvent;
typedef MainLayoutTabChanged = NavigationTabChanged;

// ─── State ───────────────────────────────────────────────────────────────────

class NavigationState extends Equatable {
  final NavTab activeTab;
  const NavigationState({this.activeTab = NavTab.listen});

  NavigationState copyWith({NavTab? activeTab}) =>
      NavigationState(activeTab: activeTab ?? this.activeTab);

  @override
  List<Object?> get props => [activeTab];
}

typedef MainLayoutState = NavigationState;

// ─── BLoC ────────────────────────────────────────────────────────────────────

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(const NavigationState()) {
    on<NavigationTabChanged>((event, emit) {
      emit(state.copyWith(activeTab: event.tab));
    });
  }
}

typedef MainLayoutBloc = NavigationBloc;
