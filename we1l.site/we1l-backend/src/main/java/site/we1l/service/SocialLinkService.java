package site.we1l.service;

import org.springframework.stereotype.Service;
import site.we1l.entity.SocialLink;
import site.we1l.mapper.SocialLinkMapper;

import java.util.List;

/**
 * 社交媒体矩阵服务。
 */
@Service
public class SocialLinkService extends BaseService<SocialLinkMapper, SocialLink> {

    public List<SocialLink> listEnabled() {
        return lambdaQuery()
                .eq(SocialLink::getStatus, 1)
                .orderByAsc(SocialLink::getSortOrder)
                .orderByAsc(SocialLink::getId)
                .list();
    }
}
