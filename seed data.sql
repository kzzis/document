-- ============================================================
-- PartsDepot サンプルデータベース: 投入データ
-- ============================================================

-- カテゴリ（1-8はルート、9-12は子カテゴリで階層構造を作る）
INSERT INTO categories (category_id, category_name, parent_category_id) VALUES
(1, 'ブレーキ部品', NULL),
(2, 'エンジン部品', NULL),
(3, '電装品', NULL),
(4, 'サスペンション', NULL),
(5, 'フィルター類', NULL),
(6, 'トランスミッション部品', NULL),
(7, '冷却系部品', NULL),
(8, '排気系部品', NULL),
(9, 'ブレーキパッド', 1),
(10, 'ブレーキローター', 1),
(11, 'エンジンオイル関連', 2),
(12, '点火系', 2);
SELECT setval('categories_category_id_seq', 12);

-- 仕入先
INSERT INTO suppliers (supplier_id, supplier_name, country, contact_email) VALUES
(1, '山田精工株式会社', '日本', 'info@yamada-seiko.example'),
(2, '東海部品工業株式会社', '日本', 'sales@tokai-parts.example'),
(3, '関東オートパーツ株式会社', '日本', 'contact@kanto-autoparts.example'),
(4, '富士ベアリング工業', '日本', 'info@fuji-bearing.example'),
(5, '中央電装株式会社', '日本', 'sales@chuo-densou.example'),
(6, '北陸鋳造工業', '日本', 'info@hokuriku-chuzo.example'),
(7, '大連精密機械有限公司', '中国', 'contact@dalian-precision.example');
SELECT setval('suppliers_supplier_id_seq', 7);

-- 部品マスタ
INSERT INTO parts (part_id, part_number, part_name, category_id, supplier_id, unit_price, weight_kg, specs, tags) VALUES
(1, 'BRK-1001', 'フロントブレーキパッド(セラミック)', 9, 1, 4800, 1.2, '{"material":"ceramic","position":"front"}', '{brake,pad,ceramic}'),
(2, 'BRK-1002', 'リアブレーキパッド(セラミック)', 9, 1, 3900, 1.0, '{"material":"ceramic","position":"rear"}', '{brake,pad,ceramic}'),
(3, 'BRK-1003', 'フロントブレーキパッド(メタル)', 9, 3, 3200, 1.3, '{"material":"metallic","position":"front"}', '{brake,pad,metallic}'),
(4, 'BRK-2001', 'ブレーキローター(前輪)', 10, 1, 8600, 6.5, '{"diameter_mm":296,"position":"front"}', '{brake,rotor}'),
(5, 'BRK-2002', 'ブレーキローター(後輪)', 10, 1, 7200, 5.2, '{"diameter_mm":280,"position":"rear"}', '{brake,rotor}'),
(6, 'BRK-3001', 'ブレーキキャリパー', 1, 3, 15800, 3.1, '{"pistons":2}', '{brake,caliper}'),
(7, 'ENG-1001', 'エンジンオイルフィルター', 11, 2, 980, 0.3, '{"thread":"3/4-16"}', '{engine,filter,oil}'),
(8, 'ENG-1002', 'エンジンオイル 5W-30 (4L)', 11, 2, 3600, 3.8, '{"viscosity":"5W-30","volume_l":4}', '{engine,oil}'),
(9, 'ENG-2001', 'タイミングベルトキット', 2, 2, 12400, 1.8, '{"kit_items":5}', '{engine,belt}'),
(10, 'ENG-2002', 'ウォーターポンプ', 2, 2, 9800, 2.4, '{}', '{engine,cooling}'),
(11, 'ENG-3001', '点火プラグ(イリジウム)', 12, 5, 1450, 0.05, '{"type":"iridium","gap_mm":1.1}', '{engine,spark_plug}'),
(12, 'ENG-3002', 'イグニッションコイル', 12, 5, 6200, 0.4, '{}', '{engine,ignition}'),
(13, 'ELE-1001', 'バッテリー(55B24L)', 3, 5, 11800, 13.5, '{"capacity_ah":48,"voltage":12}', '{electrical,battery}'),
(14, 'ELE-1002', 'オルタネーター', 3, 5, 24800, 5.6, '{"output_a":90}', '{electrical,alternator}'),
(15, 'ELE-1003', 'スターターモーター', 3, 5, 19800, 4.2, '{}', '{electrical,starter}'),
(16, 'ELE-2001', 'ヘッドライトバルブ(LED)', 3, 5, 5400, 0.15, '{"lumens":6000}', '{electrical,lighting,led}'),
(17, 'SUS-1001', 'フロントショックアブソーバー', 4, 4, 13200, 4.8, '{}', '{suspension,shock}'),
(18, 'SUS-1002', 'リアショックアブソーバー', 4, 4, 11600, 4.1, '{}', '{suspension,shock}'),
(19, 'SUS-2001', 'スタビライザーリンク', 4, 4, 2800, 0.6, '{}', '{suspension,link}'),
(20, 'SUS-2002', 'ロアアーム', 4, 4, 9600, 3.9, '{}', '{suspension,arm}'),
(21, 'FLT-1001', 'エアフィルター', 5, 2, 1800, 0.4, '{}', '{filter,air}'),
(22, 'FLT-1002', '燃料フィルター', 5, 2, 2200, 0.3, '{}', '{filter,fuel}'),
(23, 'FLT-1003', 'キャビンエアフィルター(花粉対応)', 5, 2, 2600, 0.35, '{"pollen":true}', '{filter,cabin}'),
(24, 'TRN-1001', 'CVTフルード', 6, 6, 2400, 0.9, '{"volume_l":1}', '{transmission,fluid}'),
(25, 'TRN-1002', 'クラッチキット', 6, 6, 28600, 6.2, '{}', '{transmission,clutch}'),
(26, 'TRN-1003', 'ドライブシャフトブーツ', 6, 6, 3400, 0.5, '{}', '{transmission,boot}'),
(27, 'COL-1001', 'ラジエーター', 7, 6, 18400, 5.8, '{}', '{cooling,radiator}'),
(28, 'COL-1002', 'クーラント(LLC)', 7, 6, 1600, 2.0, '{"volume_l":2}', '{cooling,coolant}'),
(29, 'COL-1003', 'サーモスタット', 7, 2, 2100, 0.2, '{}', '{cooling,thermostat}'),
(30, 'EXH-1001', 'マフラー(純正相当)', 8, 7, 22400, 8.9, '{}', '{exhaust,muffler}'),
(31, 'EXH-1002', '触媒コンバーター', 8, 7, 34800, 4.5, '{}', '{exhaust,catalytic}'),
(32, 'EXH-1003', '排気ガスケットセット', 8, 7, 1200, 0.1, '{}', '{exhaust,gasket}');
SELECT setval('parts_part_id_seq', 32);

-- 倉庫
INSERT INTO warehouses (warehouse_id, warehouse_name, location) VALUES
(1, '東京第一倉庫', '東京都江東区'),
(2, '大阪倉庫', '大阪府大阪市'),
(3, '名古屋倉庫', '愛知県名古屋市'),
(4, '福岡倉庫', '福岡県福岡市');
SELECT setval('warehouses_warehouse_id_seq', 4);

-- 在庫（一部の部品×倉庫の組み合わせはあえて欠番にし、LEFT JOIN等の練習素材にする）
INSERT INTO inventory (part_id, warehouse_id, quantity)
SELECT p.part_id, w.warehouse_id,
       ((p.part_id * 13 + w.warehouse_id * 7) % 80) + 5
FROM parts p CROSS JOIN warehouses w
WHERE (p.part_id + w.warehouse_id) % 5 <> 0;

-- 顧客（法人ディーラーと個人客が混在）
INSERT INTO customers (customer_id, customer_name, customer_type, email, phone) VALUES
(1, 'トヨシステムモーターズ株式会社', 'dealer', 'info@toyo-system-motors.example', '03-1234-5601'),
(2, '関東カーサービス株式会社', 'dealer', 'contact@kanto-carservice.example', '03-1234-5602'),
(3, '中部オート販売株式会社', 'dealer', 'sales@chubu-auto.example', '052-123-5603'),
(4, '佐藤健一', 'retail', 'k.sato.example@example.com', '090-1111-2201'),
(5, '鈴木美咲', 'retail', 'm.suzuki.example@example.com', '090-1111-2202'),
(6, '九州モータース株式会社', 'dealer', 'info@kyushu-motors.example', '092-123-5604'),
(7, '高橋大輔', 'retail', 'd.takahashi.example@example.com', '090-1111-2203'),
(8, '東北カーパーツ株式会社', 'dealer', 'sales@tohoku-carparts.example', '022-123-5605'),
(9, '田中陽子', 'retail', 'y.tanaka.example@example.com', '090-1111-2204'),
(10, '北海道オートグループ株式会社', 'dealer', 'info@hokkaido-auto.example', '011-123-5606'),
(11, '伊藤誠', 'retail', 'm.ito.example@example.com', '090-1111-2205'),
(12, '四国モビリティ株式会社', 'dealer', 'contact@shikoku-mobility.example', '087-123-5607');
SELECT setval('customers_customer_id_seq', 12);

-- 従業員（自己参照で3階層の上司-部下関係）
INSERT INTO employees (employee_id, employee_name, department, manager_id, hire_date) VALUES
(1, '山本一郎', '営業', NULL, '2010-04-01'),
(2, '中村修', '営業', 1, '2014-04-01'),
(3, '小林直樹', '営業', 2, '2019-04-01'),
(4, '加藤さくら', '営業', 2, '2021-04-01'),
(5, '渡辺隆', '購買', 1, '2013-04-01'),
(6, '木村拓真', '購買', 5, '2020-04-01'),
(7, '斎藤恵', '物流', 1, '2016-04-01');
SELECT setval('employees_employee_id_seq', 7);

-- 受注ヘッダ
INSERT INTO orders (order_id, customer_id, employee_id, order_date, status) VALUES
(1, 1, 3, '2026-01-08 10:15', 'completed'),
(2, 4, 4, '2026-01-10 14:20', 'completed'),
(3, 2, 2, '2026-01-15 09:05', 'completed'),
(4, 6, 3, '2026-01-20 11:40', 'completed'),
(5, 5, 4, '2026-01-22 16:10', 'completed'),
(6, 1, 3, '2026-02-03 10:30', 'completed'),
(7, 8, 2, '2026-02-05 13:15', 'completed'),
(8, 7, 4, '2026-02-10 09:50', 'cancelled'),
(9, 3, 3, '2026-02-18 15:00', 'completed'),
(10, 10, 2, '2026-02-25 11:20', 'completed'),
(11, 1, 3, '2026-03-02 10:00', 'completed'),
(12, 9, 4, '2026-03-05 14:45', 'completed'),
(13, 6, 3, '2026-03-12 09:30', 'shipped'),
(14, 2, 2, '2026-03-20 16:00', 'completed'),
(15, 12, 2, '2026-03-28 10:10', 'completed'),
(16, 4, 4, '2026-04-02 13:30', 'completed'),
(17, 1, 3, '2026-04-09 09:15', 'completed'),
(18, 11, 4, '2026-04-15 15:20', 'completed'),
(19, 8, 2, '2026-04-22 11:00', 'shipped'),
(20, 6, 3, '2026-05-01 10:45', 'completed'),
(21, 1, 3, '2026-05-10 09:00', 'completed'),
(22, 10, 2, '2026-05-18 14:00', 'completed'),
(23, 5, 4, '2026-06-02 11:30', 'pending'),
(24, 1, 3, '2026-06-15 10:20', 'completed');
SELECT setval('orders_order_id_seq', 24);

-- 受注明細
INSERT INTO order_items (order_id, part_id, quantity, unit_price) VALUES
(1, 1, 10, 4800), (1, 4, 4, 8600), (1, 21, 20, 1800),
(2, 7, 2, 980), (2, 8, 1, 3600),
(3, 13, 3, 11800), (3, 14, 2, 24800),
(4, 17, 4, 13200), (4, 18, 4, 11600),
(5, 11, 4, 1450),
(6, 1, 8, 4800), (6, 2, 8, 3900), (6, 30, 2, 22400),
(7, 25, 2, 28600), (7, 26, 6, 3400),
(8, 9, 1, 12400),
(9, 27, 2, 18400), (9, 28, 10, 1600), (9, 29, 5, 2100),
(10, 13, 5, 11800), (10, 16, 8, 5400),
(11, 21, 15, 1800), (11, 22, 15, 2200), (11, 23, 15, 2600),
(12, 7, 3, 980),
(13, 4, 6, 8600), (13, 5, 6, 7200),
(14, 14, 1, 24800), (14, 15, 1, 19800),
(15, 1, 12, 4800), (15, 6, 4, 15800),
(16, 11, 2, 1450), (16, 8, 1, 3600),
(17, 1, 10, 4800), (17, 21, 20, 1800), (17, 22, 20, 2200),
(18, 9, 1, 12400), (18, 10, 1, 9800),
(19, 30, 3, 22400), (19, 31, 1, 34800),
(20, 17, 6, 13200), (20, 19, 10, 2800),
(21, 1, 9, 4800), (21, 2, 9, 3900),
(22, 13, 4, 11800), (22, 16, 6, 5400),
(23, 11, 3, 1450),
(24, 21, 25, 1800), (24, 22, 25, 2200), (24, 23, 25, 2600), (24, 1, 5, 4800);

-- 価格改定履歴（値上がり傾向のデータ。ウィンドウ関数の練習用）
INSERT INTO price_history (part_id, price, effective_date) VALUES
(1, 4100, '2025-01-15'), (1, 4500, '2025-07-15'), (1, 4800, '2026-01-15'),
(4, 7300, '2025-01-15'), (4, 8000, '2025-07-15'), (4, 8600, '2026-01-15'),
(7, 830, '2025-01-15'), (7, 910, '2025-07-15'), (7, 980, '2026-01-15'),
(8, 3050, '2025-01-15'), (8, 3350, '2025-07-15'), (8, 3600, '2026-01-15'),
(11, 1230, '2025-01-15'), (11, 1350, '2025-07-15'), (11, 1450, '2026-01-15'),
(13, 10000, '2025-01-15'), (13, 11000, '2025-07-15'), (13, 11800, '2026-01-15'),
(14, 21000, '2025-01-15'), (14, 23000, '2025-07-15'), (14, 24800, '2026-01-15'),
(17, 11200, '2025-01-15'), (17, 12300, '2025-07-15'), (17, 13200, '2026-01-15'),
(21, 1530, '2025-01-15'), (21, 1670, '2025-07-15'), (21, 1800, '2026-01-15'),
(25, 24300, '2025-01-15'), (25, 26600, '2025-07-15'), (25, 28600, '2026-01-15'),
(27, 15600, '2025-01-15'), (27, 17100, '2025-07-15'), (27, 18400, '2026-01-15'),
(30, 19000, '2025-01-15'), (30, 20800, '2025-07-15'), (30, 22400, '2026-01-15');
