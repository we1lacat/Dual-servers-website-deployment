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
        p.setSiteSlogan("个人主页 · 数据看板 · 笔记与作品存档");
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
