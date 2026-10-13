import 'dart:ui';

import '../data/models/detection.dart';

/// Tracks detections across sampled video frames and counts unique objects.
class VideoDetectionTracker {
  VideoDetectionTracker({this.iouThreshold = 0.2, this.maxMissedFrames = 2});

  final double iouThreshold;
  final int maxMissedFrames;
  final List<_DetectionTrack> _tracks = [];
  int _nextTrackId = 0;
  int _uniqueObjectCount = 0;

  int get uniqueObjectCount => _uniqueObjectCount;

  /// Updates active tracks and returns how many new objects were found.
  int update(List<Detection> detections) {
    for (final track in _tracks) {
      track.missedFrames++;
    }

    final unmatchedTrackIndexes = <int>{
      for (var index = 0; index < _tracks.length; index++) index,
    };
    final newDetections = <Detection>[];

    for (final detection in detections) {
      var bestTrackIndex = -1;
      var bestIoU = iouThreshold;

      for (final trackIndex in unmatchedTrackIndexes) {
        final track = _tracks[trackIndex];
        if (track.detection.classId != detection.classId) continue;

        final overlap = _intersectionOverUnion(
          track.detection.boundingBox,
          detection.boundingBox,
        );
        if (overlap >= bestIoU) {
          bestIoU = overlap;
          bestTrackIndex = trackIndex;
        }
      }

      if (bestTrackIndex == -1) {
        newDetections.add(detection);
        continue;
      }

      final matchedTrack = _tracks[bestTrackIndex];
      matchedTrack.detection = detection;
      matchedTrack.missedFrames = 0;
      unmatchedTrackIndexes.remove(bestTrackIndex);
    }

    for (final detection in newDetections) {
      _tracks.add(_DetectionTrack(id: _nextTrackId++, detection: detection));
    }

    _tracks.removeWhere((track) => track.missedFrames > maxMissedFrames);

    _uniqueObjectCount += newDetections.length;
    return newDetections.length;
  }

  void reset() {
    _tracks.clear();
    _nextTrackId = 0;
    _uniqueObjectCount = 0;
  }

  double _intersectionOverUnion(Rect first, Rect second) {
    final intersection = first.intersect(second);
    if (intersection.isEmpty) return 0.0;

    final intersectionArea = intersection.width * intersection.height;
    final unionArea =
        first.width * first.height +
        second.width * second.height -
        intersectionArea;
    if (unionArea <= 0) return 0.0;
    return intersectionArea / unionArea;
  }
}

class _DetectionTrack {
  _DetectionTrack({required this.id, required this.detection});

  final int id;
  Detection detection;
  int missedFrames = 0;
}
