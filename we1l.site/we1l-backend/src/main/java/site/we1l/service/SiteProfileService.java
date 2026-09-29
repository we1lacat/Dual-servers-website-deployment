package site.we1l.service;

import org.springframework.stereotype.Service;
import site.we1l.common.BusinessException;
import site.we1l.entity.SiteProfile;
import site.we1l.mapper.SiteProfileMapper;

/**
 * 站点档案服务：全站配置只维护 id = 1 的一行。
 */
@Service
public class SiteProfileService extends BaseService<SiteProfileMapper, SiteProfile> {

    private static final Long PROFILE_ID = 1L;

    /**
     * 站点标语默认值（数据库无档案行时使用）。
     * ⚠️ 该值同时出现在 db/data.sql 的站点档案种子里；两处需保持一致 ——
     *    data.sql 负责「全新库的首行数据」，本常量负责「行缺失时的兜底」，路径不同故都保留。
     */
    public static final String DEFAULT_SLOGAN = "个人主页 · 数据看板 · 笔记与作品存档";

    /** 前台：读取站点档案；若数据库为空则返回带默认值的对象，避免页面白屏 */
    public SiteProfile getProfile() {
        SiteProfile profile = getById(PROFILE_ID);
        if (profile == null) {
            profile = defaults();
        }
        return profile;
    }

    /** 后台：保存（只允许更新 id = 1 这一行） */
    public SiteProfile saveProfile(SiteProfile form) {
        SiteProfile entity = getById(PROFILE_ID);
        if (entity == null) {
            entity = new SiteProfile();
            entity.setId(PROFILE_ID);
        }
        entity.setSiteName(form.getSiteName());
        entity.setSiteSlogan(form.getSiteSlogan());
        entity.setOwnerName(form.getOwnerName());
        entity.setOwnerTitle(form.getOwnerTitle());
        entity.setOwnerAvatar(form.getOwnerAvatar());
        entity.setEmail(form.getEmail());
        entity.setIcpNo(form.getIcpNo());
        entity.setIcpUrl(form.getIcpUrl());
        entity.setFooterNote(form.getFooterNote());
        entity.setUpdatedAt(now());
        saveOrUpdate(entity);
        return entity;
    }

    @Override
    public boolean removeChecked(Long id) {
        throw new BusinessException(400, "站点档案不支持删除，只能编辑");
    }

    private SiteProfile defaults() {
        SiteProfile p = new SiteProfile();
        p.setId(PROFILE_ID);
        p.setSiteName("we1l.site");
        p.setSiteSlogan(DEFAULT_SLOGAN);
        p.setOwnerName("we1l");
        p.setOwnerTitle("全栈方向 · 持续折腾中");
        p.setEmail("hi@we1l.site");
        p.setIcpNo("赣ICP备2026021347号-1");
        p.setIcpUrl("https://beian.miit.gov.cn/");
        p.setFooterNote("");
        p.setOwnerAvatar("");
        return p;
    }
}
