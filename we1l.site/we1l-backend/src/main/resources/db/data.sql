-- ============================================================
-- we1l.site 种子数据（幂等：每次执行先清空再写入）
-- 内容全部来自原静态站点，重构后改为由后台维护
-- ============================================================

DELETE FROM site_profile;
DELETE FROM site_trend;
DELETE FROM learning_item;
DELETE FROM skill;
DELETE FROM social_link;
DELETE FROM work_item;
DELETE FROM note;
DELETE FROM resume_template;

-- 站点档案 ----------------------------------------------------
INSERT INTO site_profile (id, site_name, site_slogan, owner_name, owner_title, owner_avatar,
                          email, icp_no, icp_url, footer_note, updated_at)
VALUES (1, 'we1l.site', '个人主页 · 数据看板 · 笔记与作品存档', 'we1l', '全栈方向 · 持续折腾中', '',
        'hi@we1l.site', '赣ICP备2026021347号-1', 'https://beian.miit.gov.cn/', '',
        '2026-09-01 10:00:00');

-- 首页趋势 ----------------------------------------------------
INSERT INTO site_trend (stat_label, stat_value, sort_order, remark, updated_at) VALUES
    ('1月', 12, 1, '站点上线', '2026-09-01 10:00:00'),
    ('2月', 19, 2, '', '2026-09-01 10:00:00'),
    ('3月', 15, 3, '', '2026-09-01 10:00:00'),
    ('4月', 27, 4, '', '2026-09-01 10:00:00'),
    ('5月', 22, 5, '', '2026-09-01 10:00:00'),
    ('6月', 34, 6, '', '2026-09-01 10:00:00'),
    ('7月', 30, 7, '', '2026-09-01 10:00:00'),
    ('8月', 41, 8, '峰值', '2026-09-01 10:00:00');

-- 正在学习 ----------------------------------------------------
INSERT INTO learning_item (title, description, icon, sort_order, status, updated_at) VALUES
    ('Python 桌面开发', 'PyQt5 / Tkinter，桌面宠物项目持续迭代中', 'desktop', 1, 1, '2026-09-01 10:00:00'),
    ('Web 前端', 'HTML / CSS / JavaScript，从静态页到交互组件', 'web', 2, 1, '2026-09-01 10:00:00'),
    ('AI 应用开发', '大模型 API 集成、提示词工程与流式对话', 'ai', 3, 1, '2026-09-01 10:00:00'),
    ('数据库', 'MySQL 基础，为站点数据接口做准备', 'database', 4, 1, '2026-09-01 10:00:00');

-- 技能：进度条 ------------------------------------------------
INSERT INTO skill (skill_type, skill_name, percent_value, color_key, sort_order, status, updated_at) VALUES
    ('BAR', 'Python',           85, 'blue',   1, 1, '2026-09-01 10:00:00'),
    ('BAR', 'PyQt5 / 桌面开发', 75, 'blue',   2, 1, '2026-09-01 10:00:00'),
    ('BAR', 'HTML / CSS',       70, 'green',  3, 1, '2026-09-01 10:00:00'),
    ('BAR', 'JavaScript',       60, 'orange', 4, 1, '2026-09-01 10:00:00'),
    ('BAR', 'MySQL / 数据库',   50, 'purple', 5, 1, '2026-09-01 10:00:00');

-- 技能：雷达图维度 --------------------------------------------
INSERT INTO skill (skill_type, skill_name, percent_value, color_key, sort_order, status, updated_at) VALUES
    ('RADAR', '前端',   75, 'blue', 1, 1, '2026-09-01 10:00:00'),
    ('RADAR', '后端',   68, 'blue', 2, 1, '2026-09-01 10:00:00'),
    ('RADAR', '数据库', 55, 'blue', 3, 1, '2026-09-01 10:00:00'),
    ('RADAR', '算法',   60, 'blue', 4, 1, '2026-09-01 10:00:00'),
    ('RADAR', '运维',   45, 'blue', 5, 1, '2026-09-01 10:00:00'),
    ('RADAR', '设计',   62, 'blue', 6, 1, '2026-09-01 10:00:00');

-- 社交矩阵 ----------------------------------------------------
INSERT INTO social_link (platform, handle, url, icon, sort_order, status, updated_at) VALUES
    ('GitHub',     '@we1l',            'https://github.com/logCat1024',                 'github',   1, 1, '2026-09-01 10:00:00'),
    ('哔哩哔哩',   '@we1l',            'https://space.bilibili.com/669455819',          'bilibili', 2, 1, '2026-09-01 10:00:00'),
    ('微信公众号', 'we1l 的折腾记录',  '',                                              'wechat',   3, 1, '2026-09-01 10:00:00'),
    ('邮箱',       'hi@we1l.site',     'mailto:hi@we1l.site',                           'mail',     4, 1, '2026-09-01 10:00:00'),
    ('抖音',       '@we1l',            '',                                              'douyin',   5, 1, '2026-09-01 10:00:00'),
    ('小红书',     '@we1l',            '',                                              'xiaohongshu', 6, 1, '2026-09-01 10:00:00');

-- 作品展示 ----------------------------------------------------
INSERT INTO work_item (title, tech_meta, cover, link, category, sort_order, status, updated_at) VALUES
    ('桌面宠物 Desktop Pet',      'PyQt5 · MVC 架构 · AI 对话',   '', '', '桌面应用', 1, 1, '2026-09-01 10:00:00'),
    ('we1l.site 个人网站',        'Spring Boot · Vue 3 · MySQL',  '', '', 'Web',     2, 1, '2026-09-01 10:00:00'),
    ('数据可视化看板',            'ECharts · 动态图表',           '', '', '数据',     3, 1, '2026-09-01 10:00:00'),
    ('效率小工具集',              'Python · 脚本自动化',          '', '', '工具',     4, 1, '2026-09-01 10:00:00'),
    ('课程设计合集',              'C / C++ / 数据结构',           '', '', '课设',     5, 1, '2026-09-01 10:00:00'),
    ('实验性项目',                '持续折腾中…',                  '', '', '实验',     6, 1, '2026-09-01 10:00:00');

-- 学习笔记 ----------------------------------------------------
INSERT INTO note (title, category, summary, content, cover, author, views, published_at, status, updated_at) VALUES
    ('Python 进阶：装饰器与异步编程', 'Python',
     '梳理装饰器的执行时机、functools.wraps 的作用，以及 async/await 在 IO 密集场景下的收益边界。',
     '装饰器本质上是「接收函数、返回函数」的高阶函数。\n\n1. 不带参数的装饰器：wrapper 在模块导入时即完成替换；\n2. 带参数的装饰器：多一层闭包，用于接收配置；\n3. functools.wraps 用于保留原函数的 __name__ / __doc__。\n\n异步部分：asyncio 适合 IO 密集，CPU 密集仍需多进程。',
     '', 'we1l', 128, '2026-08', 1, '2026-09-01 10:00:00'),
    ('前端三件套：从语义化到 Flex/Grid 布局', '前端',
     '语义化标签对可访问性的实际影响，Flex 一维与 Grid 二维布局的选型判断。',
     '语义化不只是「好看」：nav / main / section / article 让屏幕阅读器能正确导航。\n\nFlex 适合单行或单列的内容流；Grid 适合整体页面骨架与二维对齐。',
     '', 'we1l', 96, '2026-07', 1, '2026-09-01 10:00:00'),
    ('MySQL 基础与索引优化笔记', '数据库',
     'B+ 树索引结构、最左前缀原则、覆盖索引与回表，以及 EXPLAIN 的关键字段。',
     'InnoDB 使用 B+ 树聚簇索引，主键即数据行。\n\n联合索引遵循最左前缀；能用覆盖索引就避免回表。\n\nEXPLAIN 关注 type、key、rows、Extra（Using index / Using filesort）。',
     '', 'we1l', 154, '2026-06', 1, '2026-09-01 10:00:00'),
    ('DeepSeek API 接入与对话流式输出实践', 'AI 应用',
     'SSE 流式返回的前后端协作方式，以及在桌面应用中渲染增量文本。',
     '流式输出用 SSE 或 chunked 响应；前端逐块 append，注意处理不完整的 UTF-8 字符。',
     '', 'we1l', 203, '2026-05', 1, '2026-09-01 10:00:00'),
    ('PyQt5 桌宠开发：GIF 渲染与无边框窗口', '桌面开发',
     'QMovie 播放 GIF、无边框置顶窗口、拖拽跟随与全局输入监听。',
     'QLabel + QMovie 播放 GIF；setWindowFlags(Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint) 实现置顶无边框。\n\npynput 做全局输入监听，注意在子线程中回调 UI 需切回主线程。',
     '', 'we1l', 176, '2026-04', 1, '2026-09-01 10:00:00');

-- 简历模板 ----------------------------------------------------
INSERT INTO resume_template (title, file_type, file_size, file_url, sort_order, status, updated_at) VALUES
    ('通用简历模板（一页版）', 'PDF',  '约 120KB', '', 1, 1, '2026-09-01 10:00:00'),
    ('技术岗位简历模板',       'PDF',  '约 150KB', '', 2, 1, '2026-09-01 10:00:00'),
    ('简约风简历模板',         'DOCX', '可编辑',   '', 3, 1, '2026-09-01 10:00:00');
