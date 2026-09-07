package site.we1l.service;

import org.springframework.stereotype.Service;
import site.we1l.entity.LearningItem;
import site.we1l.mapper.LearningItemMapper;

import java.util.List;

/**
 * 「正在学习」服务。
 */
@Service
public class LearningItemService extends BaseService<LearningItemMapper, LearningItem> {

    public List<LearningItem> listEnabled() {
        return lambdaQuery()
                .eq(LearningItem::getStatus, 1)
                .orderByAsc(LearningItem::getSortOrder)
                .orderByAsc(LearningItem::getId)
                .list();
    }
}
