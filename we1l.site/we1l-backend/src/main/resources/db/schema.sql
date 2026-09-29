-- ============================================================
-- we1l.site 建表脚本（SQLite 方言）
--
-- 适用：
--   - 默认部署（jdbc:sqlite:<DB_PATH>）
--   - 字段类型使用 SQLite 标准（INTEGER/TEXT/REAL），BIGINT→INTEGER，TINYINT→INTEGER 0-1
--   - AUTOINCREMENT 走 INTEGER PRIMARY KEY AUTOINCREMENT
--   - 数据库启动时由 SiteDialectSqliteRunner 开启 PRAGMA journal_mode=WAL
-- ============================================================

-- 站点档案（单行配置：站点名、简介、备案号、联系邮箱）
CREATE TABLE IF NOT EXISTS site_profile (
    id           INTEGER     PRIMARY KEY AUTOINCREMENT,
    site_name    TEXT        NOT NULL,
    site_slogan  TEXT        NOT NULL,
    owner_name   TEXT        NOT NULL,
    owner_title  TEXT        NOT NULL,
    owner_avatar TEXT        NOT NULL,
    email        TEXT        NOT NULL,
    icp_no       TEXT        NOT NULL,
    icp_url      TEXT        NOT NULL,
    footer_note  TEXT        NOT NULL,
    updated_at   TEXT        NULL
);

-- 首页趋势折线图数据
CREATE TABLE IF NOT EXISTS site_trend (
    id          INTEGER     PRIMARY KEY AUTOINCREMENT,
    stat_label  TEXT        NOT NULL,
    stat_value  INTEGER     NOT NULL DEFAULT 0,
    sort_order  INTEGER     NOT NULL DEFAULT 0,
    remark      TEXT        NOT NULL,
    updated_at  TEXT        NULL
);

-- 「关于我」— 正在学习
CREATE TABLE IF NOT EXISTS learning_item (
    id          INTEGER     PRIMARY KEY AUTOINCREMENT,
    title       TEXT        NOT NULL,
    description TEXT        NOT NULL,
    icon        TEXT        NOT NULL,
    sort_order  INTEGER     NOT NULL DEFAULT 0,
    status      INTEGER     NOT NULL DEFAULT 1,
    updated_at  TEXT        NULL
);

-- 「关于我」— 技能（skill_type: BAR=进度条 / RADAR=雷达图维度）
CREATE TABLE IF NOT EXISTS skill (
    id            INTEGER     PRIMARY KEY AUTOINCREMENT,
    skill_type    TEXT        NOT NULL,
    skill_name    TEXT        NOT NULL,
    percent_value INTEGER     NOT NULL DEFAULT 0,
    color_key     TEXT        NOT NULL,
    sort_order    INTEGER     NOT NULL DEFAULT 0,
    status        INTEGER     NOT NULL DEFAULT 1,
    updated_at    TEXT        NULL
);

-- 「关于我」— 社交媒体矩阵
CREATE TABLE IF NOT EXISTS social_link (
    id         INTEGER     PRIMARY KEY AUTOINCREMENT,
    platform   TEXT        NOT NULL,
    handle     TEXT        NOT NULL,
    url        TEXT        NOT NULL,
    icon       TEXT        NOT NULL,
    sort_order INTEGER     NOT NULL DEFAULT 0,
    status     INTEGER     NOT NULL DEFAULT 1,
    updated_at TEXT        NULL
);

-- 「服务」— 作品展示
-- 表名用 work_item 而非 work：WORK 在部分数据库中属于保留字
CREATE TABLE IF NOT EXISTS work_item (
    id         INTEGER     PRIMARY KEY AUTOINCREMENT,
    title      TEXT        NOT NULL,
    tech_meta  TEXT        NOT NULL,
    cover      TEXT        NOT NULL,
    link       TEXT        NOT NULL,
    category   TEXT        NOT NULL,
    sort_order INTEGER     NOT NULL DEFAULT 0,
    status     INTEGER     NOT NULL DEFAULT 1,
    updated_at TEXT        NULL
);

-- 「服务」— 学习笔记
CREATE TABLE IF NOT EXISTS note (
    id           INTEGER     PRIMARY KEY AUTOINCREMENT,
    title        TEXT        NOT NULL,
    category     TEXT        NOT NULL,
    summary      TEXT        NOT NULL,
    content      TEXT        NULL,
    cover        TEXT        NOT NULL,
    author       TEXT        NOT NULL,
    views        INTEGER     NOT NULL DEFAULT 0,
    published_at TEXT        NOT NULL,
    status       INTEGER     NOT NULL DEFAULT 1,
    updated_at   TEXT        NULL
);

-- 「服务」— 简历模板
CREATE TABLE IF NOT EXISTS resume_template (
    id         INTEGER     PRIMARY KEY AUTOINCREMENT,
    title      TEXT        NOT NULL,
    file_type  TEXT        NOT NULL,
    file_size  TEXT        NOT NULL,
    file_url   TEXT        NOT NULL,
    sort_order INTEGER     NOT NULL DEFAULT 0,
    status     INTEGER     NOT NULL DEFAULT 1,
    updated_at TEXT        NULL
);

-- 管理员账号（Phase 2 引入，与 site 表同库）
CREATE TABLE IF NOT EXISTS admin_user (
    id            INTEGER     PRIMARY KEY AUTOINCREMENT,
    username      TEXT        NOT NULL UNIQUE,
    password_hash TEXT        NOT NULL,
    display_name  TEXT        NOT NULL,
    role          TEXT        NOT NULL DEFAULT 'ADMIN',
    status        INTEGER     NOT NULL DEFAULT 1,
    last_login_at TEXT        NULL,
    created_at    TEXT        NOT NULL,
    updated_at    TEXT        NULL
);
