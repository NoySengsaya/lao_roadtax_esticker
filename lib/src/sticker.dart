import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import 'const.dart';
import 'data/road_tax_model.dart';
import 'drawer/drawer.dart';
import 'utils.dart';

///  lao load tax sticker
abstract class LaoRoadTaxSticker {
  /// create sticker
  ///
  /// return byte of created sticker
  Future<ByteData?> createSticker(RoadTaxData data);
}

class CreateLaoRoadTaxSticker extends LaoRoadTaxSticker {
  /// road tax template path for draw over this template image
  final ByteData? roadTaxTemplateImage;

  /// create sticker
  ///
  /// [roadTaxTemplateImage] is road tax template image
  CreateLaoRoadTaxSticker({this.roadTaxTemplateImage});

  @override
  Future<ByteData?> createSticker(RoadTaxData data) async {
    try {
      var imageWidth = baseTemplateImageWidth;
      var imageHight = baseTemplateImageHight;

      if (roadTaxTemplateImage != null) {
        final buffer = await ui.ImmutableBuffer.fromUint8List(
          roadTaxTemplateImage!.buffer.asUint8List(),
        );
        final descriptor = await ui.ImageDescriptor.encoded(buffer);

        imageWidth = descriptor.width.toDouble();
        imageHight = descriptor.height.toDouble();
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromPoints(
          const Offset(0.0, 0.0),
          Offset(
            imageWidth,
            imageHight,
          ),
        ),
      );

      // draw sticker
      final RoadTaxDrawer drawSticker = DrawRoadTaxSticker(
        canvas: canvas,
        refactor: calRefactor(width: imageWidth, hight: imageHight),
      );

      // draw background image
      await drawSticker.drawBackgroundImage(roadTaxTemplateImage);

      // ------- column 1 ------- //
      drawSticker.drawVehicleName(data.vehicleName);
      drawSticker.drawLicensePlate(
        licenseNumber: data.licensePlateNumber,
        provinceName: data.province,
      );
      drawSticker.drawLicenseType(data.licenseTypeName);
      drawSticker.drawTxDate(data.time);
      drawSticker.drawAmount(data.amount);

      // ------- column 2 ------- //
      drawSticker.drawYear(data.year);
      drawSticker.drawVehicleIcon(data.vehicleCode);
      drawSticker.drawEngineDisplacement(data.engineDisplacement);
      drawSticker.drawChassisNumber(data.chassisNumber);

      // ------- column 3 ------- //
      await drawSticker.drawQRcode(data.barcode);
      await drawSticker.drawBarcode(data.barcode);

      // convert to image
      final picture = recorder.endRecording();
      final imgP =
          await picture.toImage(imageWidth.toInt(), imageHight.toInt());
      final pngBytes = await imgP.toByteData(format: ui.ImageByteFormat.png);
      return pngBytes;
    } catch (e) {
      rethrow;
    }
  }
}
