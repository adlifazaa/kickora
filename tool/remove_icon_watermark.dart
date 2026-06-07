import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Reconstructs bottom-right watermark pixels from neighboring background.
void main(List<String> args) {
  final sourcePath = args.isNotEmpty
      ? args[0]
      : r'C:\Users\user\.cursor\projects\c-Users-user-Desktop-Apps-Cursor-Apps-Kickora-Arabic-kickora\assets\c__Users_user_AppData_Roaming_Cursor_User_workspaceStorage_empty-window_images_Gemini_Generated_Image_uiez3quiez3quiez-cb2d6c2d-049e-4eae-8ecc-ec2b57354ff8.png';
  final appIconPath = args.length > 1
      ? args[1]
      : r'C:\Users\user\Desktop\Apps\Cursor Apps\Kickora Arabic\kickora\assets\icon\app_icon.png';
  final storeIconPath = args.length > 2
      ? args[2]
      : r'C:\Users\user\Desktop\Apps\Cursor Apps\Kickora Arabic\kickora\assets\icon\play_store_icon_512.png';

  final sourceBytes = File(sourcePath).readAsBytesSync();
  final decoded = img.decodeImage(sourceBytes);
  if (decoded == null) {
    stderr.writeln('Failed to decode source image.');
    exit(1);
  }

  final repaired = _repairWatermark(decoded);
  File(appIconPath).writeAsBytesSync(img.encodePng(repaired));

  final store = img.copyResize(
    repaired,
    width: 512,
    height: 512,
    interpolation: img.Interpolation.cubic,
  );
  File(storeIconPath).writeAsBytesSync(img.encodePng(store));

  stdout.writeln('Saved $appIconPath (${repaired.width}x${repaired.height})');
  stdout.writeln('Saved $storeIconPath (512x512)');
}

img.Image _repairWatermark(img.Image source) {
  final image = img.Image.from(source);
  final w = image.width;
  final h = image.height;

  // Extreme bottom-right corner only (background, not ball/trophy).
  final cornerX = (w * 0.90).floor();
  final cornerY = (h * 0.90).floor();
  final mask = List.generate(h, (_) => List<bool>.filled(w, false));

  for (var y = cornerY; y < h; y++) {
    for (var x = cornerX; x < w; x++) {
      if (_isWatermarkPixel(image.getPixel(x, y), x, y, w, h)) {
        mask[y][x] = true;
      }
    }
  }

  // Include faint glow around detected sparkle pixels.
  for (var pass = 0; pass < 4; pass++) {
    final next = mask.map((row) => List<bool>.from(row)).toList();
    for (var y = cornerY; y < h; y++) {
      for (var x = cornerX; x < w; x++) {
        if (!mask[y][x]) continue;
        for (var dy = -2; dy <= 2; dy++) {
          for (var dx = -2; dx <= 2; dx++) {
            final ny = y + dy;
            final nx = x + dx;
            if (ny >= cornerY && ny < h && nx >= cornerX && nx < w) {
              next[ny][nx] = true;
            }
          }
        }
      }
    }
    for (var y = cornerY; y < h; y++) {
      for (var x = cornerX; x < w; x++) {
        mask[y][x] = next[y][x];
      }
    }
  }

  // Propagate background from nearest clean neighbors (pattern-preserving).
  for (var iteration = 0; iteration < 6000; iteration++) {
    var filled = 0;
    for (var y = cornerY; y < h; y++) {
      for (var x = cornerX; x < w; x++) {
        if (!mask[y][x]) continue;

        var sumR = 0.0;
        var sumG = 0.0;
        var sumB = 0.0;
        var weight = 0.0;

        for (var dy = -4; dy <= 4; dy++) {
          for (var dx = -4; dx <= 4; dx++) {
            if (dx == 0 && dy == 0) continue;
            final ny = y + dy;
            final nx = x + dx;
            if (ny < 0 || ny >= h || nx < 0 || nx >= w) continue;
            if (mask[ny][nx]) continue;

            final dist = math.sqrt(dx * dx + dy * dy);
            final wgt = 1.0 / dist;
            final p = image.getPixel(nx, ny);
            sumR += p.r * wgt;
            sumG += p.g * wgt;
            sumB += p.b * wgt;
            weight += wgt;
          }
        }

        if (weight > 0) {
          image.setPixelRgba(
            x,
            y,
            sumR ~/ weight,
            sumG ~/ weight,
            sumB ~/ weight,
            255,
          );
          mask[y][x] = false;
          filled++;
        }
      }
    }
    if (filled == 0) break;
  }

  // Fallback: copy same-row pixels from clean strip immediately to the left.
  for (var y = cornerY; y < h; y++) {
    for (var x = cornerX; x < w; x++) {
      if (!mask[y][x]) continue;
      final shift = (w * 0.06).ceil();
      final srcX = x - shift;
      if (srcX >= 0 && !mask[y][srcX]) {
        image.setPixel(x, y, image.getPixel(srcX, y));
        mask[y][x] = false;
      }
    }
  }

  return image;
}

bool _isWatermarkPixel(img.Pixel p, int x, int y, int w, int h) {
  final r = p.r.toDouble();
  final g = p.g.toDouble();
  final b = p.b.toDouble();
  final lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;

  final distCorner = math.sqrt((w - x) * (w - x) + (h - y) * (h - y));
  final maxDist = math.min(w, h) * 0.11;
  if (distCorner > maxDist) return false;

  if (lum > 160) return true;
  if (r > 145 && g > 145 && b > 145 && lum > 115) return true;
  return false;
}
