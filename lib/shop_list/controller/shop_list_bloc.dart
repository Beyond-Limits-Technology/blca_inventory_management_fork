import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_management_with_sql/core/db/interface/database_crud.dart';
import 'package:inventory_management_with_sql/core/db/utils/dep.dart';
import 'package:inventory_management_with_sql/repo/shop_repo/shop_repo.dart';
import 'package:inventory_management_with_sql/shop_list/controller/shop_list_event.dart';
import 'package:inventory_management_with_sql/shop_list/controller/shop_list_state.dart';

class ShopListBloc extends Bloc<ShopListEvent, ShopListState> {
  StreamSubscription? onChangeSubscription;

  int currentOffset = 0;

  final ShopRepo shop;
  ShopListBloc(
    super.initialState,
    this.shop,
  ) {
    //on action
    onChangeSubscription = shop.onAction.listen(_shopRepOnActionListener);

    ///Get Event
    on<ShopListGetEvent>(_shopListGetEventListener);

    ///Create Event
    on<ShopListCreatedEvent>(_shopListCreatedEventListener);

    ///Update Event
    on<ShopListUpdatedEvent>(_shopListUpdatedEventListener);

    ///Delete Event
    on<ShopListDeletedEvent>(_shopListDeletedEventListener);

    add(ShopListGetEvent());
  }

  void _shopRepOnActionListener(event) {
    if (event.action == DatabaseCrudAction.create) {
      add(ShopListCreatedEvent(event.model));
      return;
    }
    if (event.action == DatabaseCrudAction.update) {
      add(ShopListUpdatedEvent(event.model));
      return;
    }
    add(ShopListDeletedEvent(event.model));
  }

  FutureOr<void> _shopListDeletedEventListener(event, emit) {
    final list = state.list.toList();
    list.remove(event.shop);
    emit(ShopListReceiveState(list));
  }

  FutureOr<void> _shopListUpdatedEventListener(event, emit) {
    final list = state.list.toList();
    final index = list.indexOf(event.shop);
    list[index] = event.shop;
    emit(ShopListReceiveState(list));
  }

  FutureOr<void> _shopListCreatedEventListener(event, emit) {
    final list = state.list.toList();

    list.add(event.shop);
    emit(ShopListReceiveState(list));
  }

  FutureOr<void> _shopListGetEventListener(_, emit) async {
    final list = state.list.toList();
    if (list.isEmpty) {
      emit(ShopListLoadingState(list));
    } else {
      emit(ShopListSoftLoadingState(list));
    }
    final result = await shop.findModels(offset: currentOffset);

    logger.i("ShopListGetEvent Result: $result");
    if (result.hasError) {
      logger.e(
          "ShopListGetEvent Error: ${result.exception?.message} ${result.exception?.stackTrace}");
      emit(ShopListErrorState(
        list,
        result.toString(),
      ));
      return;
    }

    final incommingList = result.result ?? [];
    if (incommingList.isEmpty) {
      emit(ShopListReceiveState(list));
      return;
    }
    list.addAll(incommingList);
    currentOffset += incommingList.length;
    emit(ShopListReceiveState(list));
  }

  @override
  Future<void> close() async {
    await onChangeSubscription?.cancel();
    return super.close();
  }
}
