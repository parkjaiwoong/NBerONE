# 원클릭 쇼핑몰 (NBerONE)

## 로컬 테스트

1. `.env.example`을 복사해 `.env` 생성 후 API 키 설정
   ```
   cp .env.example .env
   # .env 에 NAVER_CLIENT_ID, NAVER_CLIENT_SECRET 입력
   ```

2. 로컬 쇼핑몰 데이터 사용 (GitHub fetch 없이 `shop_data.dart` 사용)
   - `.env`에 `USE_LOCAL_SHOPS=true` 추가

3. 실행
   ```bash
   flutter run
   # 또는 에뮬레이터/기기 연결 후
   flutter run -d <device_id>
   ```

## Release 빌드

```bash
flutter build apk --release
flutter build appbundle --release
```
