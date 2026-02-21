# Model Assets

Letakkan file-file model YOLOv10 di folder ini:

## Required Files:

1. **best.tflite**
   - Model YOLOv10 (14.6 MB) yang sudah dikonversi ke format TensorFlow Lite
   - Input: `[1, 640, 640, 3]` (RGB image 640×640)
   - Output: `[1, 300, 6]` (format: [x1, y1, x2, y2, confidence, class_id])
   - Proses konversi: PyTorch → ONNX → TFLite

2. **labels.txt**
   - File berisi label class (satu label per baris)
   - Format:
     ```
     bleaching
     ```

## Cara Konversi Model (Reference):

### 1. PyTorch to ONNX

```python
import torch

model = torch.load('yolov10_coral.pt')
dummy_input = torch.randn(1, 3, 640, 640)
torch.onnx.export(model, dummy_input, "yolov10_coral.onnx")
```

### 2. ONNX to TensorFlow

```bash
pip install onnx-tf
onnx-tf convert -i yolov10_coral.onnx -o yolov10_coral_tf
```

### 3. TensorFlow to TFLite

```python
import tensorflow as tf

converter = tf.lite.TFLiteConverter.from_saved_model('yolov10_coral_tf')
tflite_model = converter.convert()

with open('best.tflite', 'wb') as f:
    f.write(tflite_model)
```

## Note:

- Pastikan ukuran input model adalah 640x640 pixels sesuai dengan konfigurasi di `AppConstants`
- Model output format: `[x1, y1, x2, y2, confidence, class_id]` (normalized 0-1)
- Confidence threshold: 0.5 (dapat dikonfigurasi)
