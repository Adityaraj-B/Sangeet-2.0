import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class FilterEvent extends Equatable {
  const FilterEvent();
  @override
  List<Object?> get props => [];
}

class FilterSelected extends FilterEvent {
  final String filter;
  const FilterSelected(this.filter);
  @override
  List<Object?> get props => [filter];
}

// Aliases for HomeBloc naming convention
typedef HomeEvent = FilterEvent;
typedef HomeFilterSelected = FilterSelected;

// ─── State ───────────────────────────────────────────────────────────────────

class FilterState extends Equatable {
  final String selectedFilter;
  final List<String> filters;

  const FilterState({
    this.selectedFilter = 'All',
    this.filters = const [
      'All',
      'Bollywood Nostalgia',
      'Hindustani Classical',
      'Sufi & Ghazal',
      'Semi-Classical',
    ],
  });

  FilterState copyWith({String? selectedFilter}) => FilterState(
        selectedFilter: selectedFilter ?? this.selectedFilter,
        filters: filters,
      );

  @override
  List<Object?> get props => [selectedFilter, filters];
}

// Alias for HomeState
typedef HomeState = FilterState;

// ─── BLoC ────────────────────────────────────────────────────────────────────

class FilterBloc extends Bloc<FilterEvent, FilterState> {
  FilterBloc() : super(const FilterState()) {
    on<FilterSelected>((event, emit) {
      emit(state.copyWith(selectedFilter: event.filter));
    });
  }
}

// Alias for HomeBloc
typedef HomeBloc = FilterBloc;
