// ============ ตั้งค่าระบบตรวจรถ ============
// แก้ 3 ค่านี้ให้ครบก่อนใช้งานจริง
window.CONFIG = {
  SUPABASE_URL: 'https://xxxxxxxxxxxx.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOi...ใส่ anon key ที่นี่...',

  // LIFF ID จาก LINE Developers (เว้นว่างไว้ = โหมดทดสอบบนเบราว์เซอร์ปกติ)
  LIFF_ID: '',

  // รหัสเข้าหน้าแอดมิน
  ADMIN_PIN: '1234',

  // ชื่อ bucket เก็บรูป (ตรงกับ schema.sql)
  BUCKET: 'inspection-photos'
};
