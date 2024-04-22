import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventory_management_with_sql/create_new_shop/controller/create_new_shop_event.dart';
import 'package:inventory_management_with_sql/create_new_shop/controller/create_new_shop_state.dart';
import 'package:inventory_management_with_sql/repo/shop_repo/shop_entity.dart';
import 'package:inventory_management_with_sql/repo/shop_repo/shop_repo.dart';

class CreateNewShopBloc extends Bloc<CreateNewShopEvent, CreateNewShopState> {
  final TextEditingController controller;
  final ImagePicker imagePicker;
  final ShopRepo shopRepo;
  CreateNewShopBloc(super.initialState, this.shopRepo, this.imagePicker)
      : controller = TextEditingController() {
    on<CreateNewShopPickCoverPhotoEvent>(
        _createNewShopPickCoverPhotoEventListener);

    on<CreateNewShopCreateShopEvent>((event, emit) async {
      assert(state.coverPhotoPath != null);
      final result = await shopRepo.create(
        ShopParam.toCreate(
          name: controller.text,
          coverPhoto: state.coverPhotoPath!,
        ),
      );
    });
  }

  FutureOr<void> _createNewShopPickCoverPhotoEventListener(_, emit) async {
    final file = await imagePicker.pickImage(source: ImageSource.gallery);

    emit(CreateNewShopCoverPhotoSelectedState(coverPhotoPath: file?.path));
  }

  @override
  Future<void> close() {
    controller.dispose();
    return super.close();
  }
}