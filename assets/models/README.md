# Model Assets

Letakkan file-file model YOLOv10 di folder ini:

## Required Files:

1. **yolov10_coral_bleaching.tflite**
   - Model YOLOv10 yang sudah dikonversi ke format TensorFlow Lite
   - Proses konversi: PyTorch → ONNX → TFLite
   - Sudah di-quantize untuk optimasi performa

2. **labels.txt**
   - File berisi label class (satu label per baris)
   - Format:
     ```
     healthy_coral
     bleached_coral
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

### 3. TensorFlow to TFLite dengan Quantization

```python
import tensorflow as tf

converter = tf.lite.TFLiteConverter.from_saved_model('yolov10_coral_tf')
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

with open('yolov10_coral_bleaching.tflite', 'wb') as f:
    f.write(tflite_model)
```

## Note:

Pastikan ukuran input model adalah 640x640 pixels sesuai dengan konfigurasi di `AppConstants`.
