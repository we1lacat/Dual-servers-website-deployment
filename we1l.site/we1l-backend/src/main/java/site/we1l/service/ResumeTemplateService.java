package site.we1l.service;

import org.springframework.stereotype.Service;
import site.we1l.entity.ResumeTemplate;
import site.we1l.mapper.ResumeTemplateMapper;

import java.util.List;

/**
 * 简历模板服务。
 */
@Service
public class ResumeTemplateService extends BaseService<ResumeTemplateMapper, ResumeTemplate> {

    public List<ResumeTemplate> listEnabled() {
        return lambdaQuery()
                .eq(ResumeTemplate::getStatus, 1)
                .orderByAsc(ResumeTemplate::getSortOrder)
                .orderByAsc(ResumeTemplate::getId)
                .list();
    }
}
