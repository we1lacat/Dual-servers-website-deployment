package site.we1l.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import site.we1l.entity.WorkItem;

@Mapper
public interface WorkItemMapper extends BaseMapper<WorkItem> {
}
