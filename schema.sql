-- ============================================================
-- ระบบตรวจรถก่อนใช้งาน (Vehicle Pre-Trip Inspection) - Phase 1
-- รันไฟล์นี้ใน Supabase > SQL Editor ทั้งไฟล์ครั้งเดียว
-- ============================================================

-- ---------- 1) ตารางพนักงาน (ผูกกับ LINE userId) ----------
create table if not exists employees (
  id            uuid primary key default gen_random_uuid(),
  line_user_id  text unique not null,
  first_name    text not null,
  last_name     text not null,
  display_name  text,
  picture_url   text,
  phone         text,
  active        boolean default true,
  created_at    timestamptz default now()
);

-- ---------- 2) รายการตรวจ (แก้ไข/เพิ่ม/ปิดใช้งานได้ภายหลัง) ----------
create table if not exists checklist_items (
  id           serial primary key,
  section      smallint not null,          -- 1,2,3
  section_name text not null,              -- ชื่อหมวด
  code         text not null,              -- 1.1, 2.3 ...
  label        text not null,              -- ข้อความรายการตรวจ
  critical     boolean default false,      -- (กรณีไม่ผ่านให้แก้ไขทันที)
  sort_order   int not null,
  active       boolean default true
);

-- ---------- 3) ใบตรวจ 1 ใบ = 1 คัน 1 ครั้ง ----------
create table if not exists inspections (
  id             uuid primary key default gen_random_uuid(),
  employee_id    uuid references employees(id),
  line_user_id   text,
  inspector_name text,                     -- เก็บชื่อ ณ เวลาที่ตรวจ
  vehicle_number text not null,            -- เบอร์รถ 3 หลัก
  inspected_at   timestamptz default now(),
  inspect_date   date default ((now() at time zone 'Asia/Bangkok')::date),
  total_items    int default 0,
  fail_count     int default 0,
  status         text default 'pass',      -- pass | fail
  other_note     text,                     -- ความผิดปกติอื่น ๆ
  repair_requested boolean default false,  -- เฟส 2 (แจ้งซ่อม)
  created_at     timestamptz default now()
);

-- ---------- 4) ผลรายข้อ (เก็บ label ซ้ำไว้ เพื่อให้ประวัติย้อนหลังไม่เพี้ยนถ้าแก้รายการตรวจ) ----------
create table if not exists inspection_results (
  id            uuid primary key default gen_random_uuid(),
  inspection_id uuid references inspections(id) on delete cascade,
  item_id       int references checklist_items(id),
  item_code     text,
  item_label    text,
  section_name  text,
  sort_order    int,
  result        text not null check (result in ('pass','fail')),
  detail        text,                      -- รายละเอียดที่พบ
  created_at    timestamptz default now()
);

-- ---------- 5) รูปแนบของข้อที่ไม่ผ่าน ----------
create table if not exists inspection_photos (
  id            uuid primary key default gen_random_uuid(),
  result_id     uuid references inspection_results(id) on delete cascade,
  inspection_id uuid references inspections(id) on delete cascade,
  path          text not null,
  url           text not null,
  created_at    timestamptz default now()
);

-- ---------- index ----------
create index if not exists idx_insp_date    on inspections(inspect_date desc);
create index if not exists idx_insp_vehicle on inspections(vehicle_number);
create index if not exists idx_insp_status  on inspections(status);
create index if not exists idx_res_insp     on inspection_results(inspection_id);
create index if not exists idx_res_item     on inspection_results(item_id, result);
create index if not exists idx_photo_res    on inspection_photos(result_id);

-- ---------- RLS (เปิดใช้ + อนุญาต anon ตามแบบระบบเดิม) ----------
alter table employees          enable row level security;
alter table checklist_items    enable row level security;
alter table inspections        enable row level security;
alter table inspection_results enable row level security;
alter table inspection_photos  enable row level security;

do $$
declare t text;
begin
  foreach t in array array['employees','checklist_items','inspections','inspection_results','inspection_photos']
  loop
    execute format('drop policy if exists "anon_all_%1$s" on %1$I', t);
    execute format('create policy "anon_all_%1$s" on %1$I for all to anon using (true) with check (true)', t);
  end loop;
end $$;

-- ---------- Storage bucket สำหรับรูป ----------
insert into storage.buckets (id, name, public)
values ('inspection-photos','inspection-photos', true)
on conflict (id) do update set public = true;

drop policy if exists "photos_read"   on storage.objects;
drop policy if exists "photos_write"  on storage.objects;
create policy "photos_read"  on storage.objects for select to anon, authenticated
  using (bucket_id = 'inspection-photos');
create policy "photos_write" on storage.objects for insert to anon, authenticated
  with check (bucket_id = 'inspection-photos');

-- ---------- Seed รายการตรวจตามแบบฟอร์ม ----------
truncate checklist_items restart identity cascade;
insert into checklist_items (section, section_name, code, label, critical, sort_order) values
(1,'ภายในห้องโดยสาร','1.1','เข็มขัดนิรภัย ทั้ง พขร. และผู้โดยสาร', true, 101),
(1,'ภายในห้องโดยสาร','1.2','ระบบไฟสัญญาณภายในห้องโดยสาร', true, 102),
(1,'ภายในห้องโดยสาร','1.3','ระบบ GPS / กล้อง / เครื่องรูดบัตร / เสียงเตือนความเร็ว พร้อมใช้งาน', false, 103),
(1,'ภายในห้องโดยสาร','1.4','กล่องอุปกรณ์ฉุกเฉิน', false, 104),
(1,'ภายในห้องโดยสาร','1.5','เบรคมือ', true, 105),
(1,'ภายในห้องโดยสาร','1.6','เครื่องฉีดน้ำล้างกระจกหน้า (สภาพยางปัดน้ำฝนและน้ำฉีด)', true, 106),
(1,'ภายในห้องโดยสาร','1.7','ถังดับเพลิง ขนาด 5 ปอนด์ จำนวน 1 ถัง', false, 107),
(2,'ภายนอกตัวรถ','2.1','ไฟส่องสว่าง (ไฟหน้า สูง-ต่ำ)', true, 201),
(2,'ภายนอกตัวรถ','2.2','ไฟเบรค, ไฟถอย, ไฟเลี้ยว, ไฟฉุกเฉิน', true, 202),
(2,'ภายนอกตัวรถ','2.3','ระบบไฟราวข้างรอบตัวรถ และไฟป้ายทะเบียน', true, 203),
(2,'ภายนอกตัวรถ','2.4','สัญญาณเสียงเตือนรถถอยหลัง', false, 204),
(2,'ภายนอกตัวรถ','2.5','สภาพยางรถ (ดอกยางไม่ต่ำกว่า 3 มม. / แก้มยางไม่มีรอยแตก)', true, 205),
(2,'ภายนอกตัวรถ','2.6','ถังดับเพลิง ขนาด 20 ปอนด์ (เทรลเลอร์ 4 ถัง, สิบล้อ 2 ถัง)', false, 206),
(2,'ภายนอกตัวรถ','2.7','กรวยจราจร จำนวน 4 ใบ', false, 207),
(2,'ภายนอกตัวรถ','2.8','หมอนหนุนล้อ 2 อัน', false, 208),
(3,'ห้องเครื่องยนต์','3.1','น้ำมันเครื่อง / น้ำมันเบรค / น้ำมันเกียร์', true, 301),
(3,'ห้องเครื่องยนต์','3.2','น้ำในหม้อน้ำ และน้ำหม้อพัก', true, 302),
(3,'ห้องเครื่องยนต์','3.3','น้ำกลั่นแบตเตอรี่', true, 303),
(3,'ห้องเครื่องยนต์','3.4','สายกราวด์ สายลงน้ำมัน อุปกรณ์การลงน้ำมัน', true, 304),
(3,'ห้องเครื่องยนต์','3.5','กระจกกันลมหน้า/หลัง ไม่แตกร้าว กระจกมองหลัง/มองข้างพร้อมใช้งาน', true, 305);

-- ---------- View สำหรับ export ----------
create or replace view v_inspection_detail as
select i.inspect_date, i.inspected_at, i.vehicle_number, i.inspector_name,
       i.status as overall_status, i.fail_count, i.other_note,
       r.section_name, r.item_code, r.item_label, r.result, r.detail,
       (select count(*) from inspection_photos p where p.result_id = r.id) as photo_count,
       i.id as inspection_id, r.id as result_id
from inspections i
join inspection_results r on r.inspection_id = i.id
order by i.inspected_at desc, r.sort_order;
