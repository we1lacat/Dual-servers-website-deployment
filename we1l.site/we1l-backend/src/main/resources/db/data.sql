-- ============================================================
-- we1l.site 种子数据（幂等：每行 INSERT 带 WHERE NOT EXISTS 守卫）
--
-- 改造说明（P1）：
--   原脚本为「DELETE 全表 + 重灌」，容器化/重启会静默清空后台维护的数据。
--   现改为逐行 INSERT ... SELECT ... WHERE NOT EXISTS，用各表自然唯一键守卫：
--     - 首次（全新空库）：所有行缺失 → 全部种入（与旧行为一致）
--     - 重启（已有数据）：所有行已存在 → 全部跳过，不丢数据、不重复
--   依赖 schema.sql 已建表（spring.sql.init.mode=always 时保证）。
-- ============================================================

-- 站点档案（单主键 id=1）------------------------------------
-- ⚠️ site_slogan 的值与 SiteProfileService.DEFAULT_SLOGAN 保持一致：
--    前者是「全新库的首行数据」，后者是「行缺失时的兜底」，两处路径不同故都保留。
INSERT INTO site_profile (id, site_name, site_slogan, owner_name, owner_title, owner_avatar,
                          email, icp_no, icp_url, footer_note, updated_at)
SELECT 1, 'we1l.site', '个人主页 · 数据看板 · 笔记与作品存档', 'we1l', '全栈方向 · 持续折腾中', '',
       'hi@we1l.site', '赣ICP备2026021347号-1', 'https://beian.miit.gov.cn/', '',
       '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM site_profile WHERE id = 1);

-- 首页趋势（守卫 stat_label）-----------------------------------
INSERT INTO site_trend (stat_label, stat_value, sort_order, remark, updated_at)
SELECT '1月', 12, 1, '站点上线', '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM site_trend WHERE stat_label = '1月');

INSERT INTO site_trend (stat_label, stat_value, sort_order, remark, updated_at)
SELECT '2月', 19, 2, '', '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM site_trend WHERE stat_label = '2月');

INSERT INTO site_trend (stat_label, stat_value, sort_order, remark, updated_at)
SELECT '3月', 15, 3, '', '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM site_trend WHERE stat_label = '3月');

INSERT INTO site_trend (stat_label, stat_value, sort_order, remark, updated_at)
SELECT '4月', 27, 4, '', '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM site_trend WHERE stat_label = '4月');

INSERT INTO site_trend (stat_label, stat_value, sort_order, remark, updated_at)
SELECT '5月', 22, 5, '', '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM site_trend WHERE stat_label = '5月');

INSERT INTO site_trend (stat_label, stat_value, sort_order, remark, updated_at)
SELECT '6月', 34, 6, '', '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM site_trend WHERE stat_label = '6月');

INSERT INTO site_trend (stat_label, stat_value, sort_order, remark, updated_at)
SELECT '7月', 30, 7, '', '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM site_trend WHERE stat_label = '7月');

INSERT INTO site_trend (stat_label, stat_value, sort_order, remark, updated_at)
SELECT '8月', 41, 8, '峰值', '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM site_trend WHERE stat_label = '8月');

-- 正在学习（守卫 title）-----------------------------------------
INSERT INTO learning_item (title, description, icon, sort_order, status, updated_at)
SELECT 'Python 桌面开发', 'PyQt5 / Tkinter，桌面宠物项目持续迭代中', 'desktop', 1, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM learning_item WHERE title = 'Python 桌面开发');

INSERT INTO learning_item (title, description, icon, sort_order, status, updated_at)
SELECT 'Web 前端', 'HTML / CSS / JavaScript，从静态页到交互组件', 'web', 2, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM learning_item WHERE title = 'Web 前端');

INSERT INTO learning_item (title, description, icon, sort_order, status, updated_at)
SELECT 'AI 应用开发', '大模型 API 集成、提示词工程与流式对话', 'ai', 3, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM learning_item WHERE title = 'AI 应用开发');

INSERT INTO learning_item (title, description, icon, sort_order, status, updated_at)
SELECT '数据库', 'MySQL 基础，为站点数据接口做准备', 'database', 4, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM learning_item WHERE title = '数据库');

-- 技能：进度条（守卫 skill_type + skill_name）------------------
INSERT INTO skill (skill_type, skill_name, percent_value, color_key, sort_order, status, updated_at)
SELECT 'BAR', 'Python',           85, 'blue',   1, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM skill WHERE skill_type = 'BAR' AND skill_name = 'Python');

INSERT INTO skill (skill_type, skill_name, percent_value, color_key, sort_order, status, updated_at)
SELECT 'BAR', 'PyQt5 / 桌面开发', 75, 'blue',   2, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM skill WHERE skill_type = 'BAR' AND skill_name = 'PyQt5 / 桌面开发');

INSERT INTO skill (skill_type, skill_name, percent_value, color_key, sort_order, status, updated_at)
SELECT 'BAR', 'HTML / CSS',       70, 'green',  3, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM skill WHERE skill_type = 'BAR' AND skill_name = 'HTML / CSS');

INSERT INTO skill (skill_type, skill_name, percent_value, color_key, sort_order, status, updated_at)
SELECT 'BAR', 'JavaScript',       60, 'orange', 4, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM skill WHERE skill_type = 'BAR' AND skill_name = 'JavaScript');

INSERT INTO skill (skill_type, skill_name, percent_value, color_key, sort_order, status, updated_at)
SELECT 'BAR', 'MySQL / 数据库',   50, 'purple', 5, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM skill WHERE skill_type = 'BAR' AND skill_name = 'MySQL / 数据库');

-- 技能：雷达图维度（守卫 skill_type + skill_name）--------------
INSERT INTO skill (skill_type, skill_name, percent_value, color_key, sort_order, status, updated_at)
SELECT 'RADAR', '前端',   75, 'blue', 1, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM skill WHERE skill_type = 'RADAR' AND skill_name = '前端');

INSERT INTO skill (skill_type, skill_name, percent_value, color_key, sort_order, status, updated_at)
SELECT 'RADAR', '后端',   68, 'blue', 2, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM skill WHERE skill_type = 'RADAR' AND skill_name = '后端');

INSERT INTO skill (skill_type, skill_name, percent_value, color_key, sort_order, status, updated_at)
SELECT 'RADAR', '数据库', 55, 'blue', 3, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM skill WHERE skill_type = 'RADAR' AND skill_name = '数据库');

INSERT INTO skill (skill_type, skill_name, percent_value, color_key, sort_order, status, updated_at)
SELECT 'RADAR', '算法',   60, 'blue', 4, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM skill WHERE skill_type = 'RADAR' AND skill_name = '算法');

INSERT INTO skill (skill_type, skill_name, percent_value, color_key, sort_order, status, updated_at)
SELECT 'RADAR', '运维',   45, 'blue', 5, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM skill WHERE skill_type = 'RADAR' AND skill_name = '运维');

INSERT INTO skill (skill_type, skill_name, percent_value, color_key, sort_order, status, updated_at)
SELECT 'RADAR', '设计',   62, 'blue', 6, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM skill WHERE skill_type = 'RADAR' AND skill_name = '设计');

-- 社交矩阵（守卫 platform）-------------------------------------
INSERT INTO social_link (platform, handle, url, icon, sort_order, status, updated_at)
SELECT 'GitHub',     '@we1l',            'https://github.com/logCat1024',                 'github',   1, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM social_link WHERE platform = 'GitHub');

INSERT INTO social_link (platform, handle, url, icon, sort_order, status, updated_at)
SELECT '哔哩哔哩',   '@we1l',            'https://space.bilibili.com/669455819',          'bilibili', 2, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM social_link WHERE platform = '哔哩哔哩');

INSERT INTO social_link (platform, handle, url, icon, sort_order, status, updated_at)
SELECT '微信公众号', 'we1l 的折腾记录',  '',                                              'wechat',   3, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM social_link WHERE platform = '微信公众号');

INSERT INTO social_link (platform, handle, url, icon, sort_order, status, updated_at)
SELECT '邮箱',       'hi@we1l.site',     'mailto:hi@we1l.site',                           'mail',     4, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM social_link WHERE platform = '邮箱');

INSERT INTO social_link (platform, handle, url, icon, sort_order, status, updated_at)
SELECT '抖音',       '@we1l',            '',                                              'douyin',   5, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM social_link WHERE platform = '抖音');

INSERT INTO social_link (platform, handle, url, icon, sort_order, status, updated_at)
SELECT '小红书',     '@we1l',            '',                                              'xiaohongshu', 6, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM social_link WHERE platform = '小红书');

-- 作品展示（守卫 title）----------------------------------------
INSERT INTO work_item (title, tech_meta, cover, link, category, sort_order, status, updated_at)
SELECT '桌面宠物 Desktop Pet',      'PyQt5 · MVC 架构 · AI 对话',   '', '', '桌面应用', 1, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM work_item WHERE title = '桌面宠物 Desktop Pet');

INSERT INTO work_item (title, tech_meta, cover, link, category, sort_order, status, updated_at)
SELECT 'we1l.site 个人网站',        'Spring Boot · Vue 3 · MySQL',  '', '', 'Web',     2, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM work_item WHERE title = 'we1l.site 个人网站');

INSERT INTO work_item (title, tech_meta, cover, link, category, sort_order, status, updated_at)
SELECT '数据可视化看板',            'ECharts · 动态图表',           '', '', '数据',     3, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM work_item WHERE title = '数据可视化看板');

INSERT INTO work_item (title, tech_meta, cover, link, category, sort_order, status, updated_at)
SELECT '效率小工具集',              'Python · 脚本自动化',          '', '', '工具',     4, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM work_item WHERE title = '效率小工具集');

INSERT INTO work_item (title, tech_meta, cover, link, category, sort_order, status, updated_at)
SELECT '课程设计合集',              'C / C++ / 数据结构',           '', '', '课设',     5, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM work_item WHERE title = '课程设计合集');

INSERT INTO work_item (title, tech_meta, cover, link, category, sort_order, status, updated_at)
SELECT '实验性项目',                '持续折腾中…',                  '', '', '实验',     6, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM work_item WHERE title = '实验性项目');

-- 学习笔记（守卫 title）----------------------------------------
INSERT INTO note (title, category, summary, content, cover, author, views, published_at, status, updated_at)
SELECT 'Python 进阶：装饰器与异步编程', 'Python',
       '梳理装饰器的执行时机、functools.wraps 的作用，以及 async/await 在 IO 密集场景下的收益边界。',
       '装饰器本质上是「接收函数、返回函数」的高阶函数。\n\n1. 不带参数的装饰器：wrapper 在模块导入时即完成替换；\n2. 带参数的装饰器：多一层闭包，用于接收配置；\n3. functools.wraps 用于保留原函数的 __name__ / __doc__。\n\n异步部分：asyncio 适合 IO 密集，CPU 密集仍需多进程。',
       '', 'we1l', 128, '2026-08', 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM note WHERE title = 'Python 进阶：装饰器与异步编程');

INSERT INTO note (title, category, summary, content, cover, author, views, published_at, status, updated_at)
SELECT '前端三件套：从语义化到 Flex/Grid 布局', '前端',
       '语义化标签对可访问性的实际影响，Flex 一维与 Grid 二维布局的选型判断。',
       '语义化不只是「好看」：nav / main / section / article 让屏幕阅读器能正确导航。\n\nFlex 适合单行或单列的内容流；Grid 适合整体页面骨架与二维对齐。',
       '', 'we1l', 96, '2026-07', 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM note WHERE title = '前端三件套：从语义化到 Flex/Grid 布局');

INSERT INTO note (title, category, summary, content, cover, author, views, published_at, status, updated_at)
SELECT 'MySQL 基础与索引优化笔记', '数据库',
       'B+ 树索引结构、最左前缀原则、覆盖索引与回表，以及 EXPLAIN 的关键字段。',
       'InnoDB 使用 B+ 树聚簇索引，主键即数据行。\n\n联合索引遵循最左前缀；能用覆盖索引就避免回表。\n\nEXPLAIN 关注 type、key、rows、Extra（Using index / Using filesort）。',
       '', 'we1l', 154, '2026-06', 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM note WHERE title = 'MySQL 基础与索引优化笔记');

INSERT INTO note (title, category, summary, content, cover, author, views, published_at, status, updated_at)
SELECT 'DeepSeek API 接入与对话流式输出实践', 'AI 应用',
       'SSE 流式返回的前后端协作方式，以及在桌面应用中渲染增量文本。',
       '流式输出用 SSE 或 chunked 响应；前端逐块 append，注意处理不完整的 UTF-8 字符。',
       '', 'we1l', 203, '2026-05', 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM note WHERE title = 'DeepSeek API 接入与对话流式输出实践');

INSERT INTO note (title, category, summary, content, cover, author, views, published_at, status, updated_at)
SELECT 'PyQt5 桌宠开发：GIF 渲染与无边框窗口', '桌面开发',
       'QMovie 播放 GIF、无边框置顶窗口、拖拽跟随与全局输入监听。',
       'QLabel + QMovie 播放 GIF；setWindowFlags(Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint) 实现置顶无边框。\n\npynput 做全局输入监听，注意在子线程中回调 UI 需切回主线程。',
       '', 'we1l', 176, '2026-04', 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM note WHERE title = 'PyQt5 桌宠开发：GIF 渲染与无边框窗口');

-- 简历模板（守卫 title）----------------------------------------
INSERT INTO resume_template (title, file_type, file_size, file_url, sort_order, status, updated_at)
SELECT '通用简历模板（一页版）', 'PDF',  '约 120KB', '', 1, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM resume_template WHERE title = '通用简历模板（一页版）');

INSERT INTO resume_template (title, file_type, file_size, file_url, sort_order, status, updated_at)
SELECT '技术岗位简历模板',       'PDF',  '约 150KB', '', 2, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM resume_template WHERE title = '技术岗位简历模板');

INSERT INTO resume_template (title, file_type, file_size, file_url, sort_order, status, updated_at)
SELECT '简约风简历模板',         'DOCX', '可编辑',   '', 3, 1, '2026-09-01 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM resume_template WHERE title = '简约风简历模板');
