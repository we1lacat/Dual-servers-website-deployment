package site.we1l.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import site.we1l.common.BusinessException;
import site.we1l.entity.BaseEntity;

import java.time.LocalDateTime;

/**
 * Service 层公共基类：
 * <ul>
 *   <li>统一写入 updatedAt，不依赖数据库的 ON UPDATE 语法（MySQL / H2 通用）</li>
 *   <li>统一「记录不存在」的异常文案</li>
 * </ul>
 *
 * @param <M> Mapper 类型
 * @param <T> 实体类型
 */
public abstract class BaseService<M extends BaseMapper<T>, T extends BaseEntity> extends ServiceImpl<M, T> {

    protected LocalDateTime now() {
        return LocalDateTime.now();
    }

    /** 新增并写入更新时间 */
    public boolean create(T entity) {
        entity.setId(null);
        entity.setUpdatedAt(now());
        return save(entity);
    }

    /** 更新并写入更新时间 */
    public boolean modify(T entity) {
        requireExists(entity.getId());
        entity.setUpdatedAt(now());
        return updateById(entity);
    }

    /** 删除前校验存在性 */
    public boolean removeChecked(Long id) {
        requireExists(id);
        return removeById(id);
    }

    protected void requireExists(Long id) {
        if (id == null || getById(id) == null) {
            throw new BusinessException(404, "记录不存在或已被删除");
        }
    }
}
