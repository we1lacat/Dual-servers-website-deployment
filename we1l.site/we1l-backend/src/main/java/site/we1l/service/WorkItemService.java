package site.we1l.service;

import org.springframework.stereotype.Service;
import site.we1l.entity.WorkItem;
import site.we1l.mapper.WorkItemMapper;

import java.util.List;

/**
 * 作品展示服务。
 */
@Service
public class WorkItemService extends BaseService<WorkItemMapper, WorkItem> {

    public List<WorkItem> listEnabled() {
        return lambdaQuery()
                .eq(WorkItem::getStatus, 1)
                .orderByAsc(WorkItem::getSortOrder)
                .orderByAsc(WorkItem::getId)
                .list();
    }
}
