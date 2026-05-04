# Reflection — Anti-pattern dễ vướng nhất (slide §5)

**Anti-pattern: Small-file problem từ streaming ingestion**

Trong use case LLM observability, mỗi API call sinh ra một event và thường
được ghi vào Bronze theo micro-batch (1 batch/vài giây để giảm latency).
Sau vài giờ vận hành, Bronze tích lũy hàng chục nghìn file Parquet nhỏ —
đúng kịch bản NB2 mô phỏng với 200 batch × 5 000 rows.

**Vì sao team dễ vướng:** Khi hệ thống mới ra mắt, traffic còn thấp nên
query vẫn nhanh — không ai nhận ra vấn đề. Đến khi traffic tăng (launch
tính năng mới, A/B test mô hình), số file đã lên đến hàng trăm nghìn; mỗi
query phải mở metadata từng file, latency tăng phi tuyến. Đây là "silent
degradation": hệ thống không báo lỗi, chỉ ngày càng chậm hơn.

**Cách phòng:** Chạy `OPTIMIZE` + `VACUUM` theo lịch (mỗi giờ trên Bronze/
Silver hot), kết hợp Z-order theo `model` và `date`. Như NB2 đã chứng minh,
bước này giảm 200 xuống còn 55 file và cải thiện query **8.9×** — hoàn toàn
có thể tự động hóa mà không tốn thêm chi phí lưu trữ đáng kể.
