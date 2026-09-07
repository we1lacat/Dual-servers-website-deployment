package site.we1l.service;

import org.springframework.stereotype.Service;
import site.we1l.entity.SiteTrend;
import site.we1l.mapper.SiteTrendMapper;

import java.util.List;

/**
 * 首页趋势数据服务。
 */
@Service
public class SiteTrendService extends BaseService<SiteTrendMapper, SiteTrend> {

    /** 前台：按排序号返回全部数据点 */
    public List<SiteTrend> listForFront() {
        return lambdaQuery()
                .orderByAsc(SiteTrend::getSortOrder)
                .orderByAsc(SiteTrend::getId)
                .list();
    }
}
