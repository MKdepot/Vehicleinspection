// ============ ตั้งค่าระบบตรวจรถ ============
// แก้ 3 ค่านี้ให้ครบก่อนใช้งานจริง
window.CONFIG = {
  SUPABASE_URL: 'https://zxoabjknkdckshjiuvit.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp4b2Fiamtua2Rja3Noaml1dml0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk2MDQxNTksImV4cCI6MjEwNTE4MDE1OX0.cT3e_QeghIxj3UFk4L9-9lnijTT9pqvDzLrBaCnJYig',

  // LIFF ID จาก LINE Developers (เว้นว่างไว้ = โหมดทดสอบบนเบราว์เซอร์ปกติ)
  LIFF_ID: '1660796030-hQllf4RI',

  // รหัสเข้าหน้าแอดมิน
  ADMIN_PIN: '1101',

  
  // ชื่อ bucket เก็บรูป (ตรงกับ schema.sql)
  BUCKET: 'inspection-photos',
 
  // แจ้งเตือนเข้ากลุ่ม LINE เมื่อตรวจไม่ผ่าน (ต้อง deploy Edge Function "notify-fail" ก่อน)
  NOTIFY_ENABLED: true
};
