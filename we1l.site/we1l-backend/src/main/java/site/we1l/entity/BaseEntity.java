package site.we1l.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 实体基类：主键 + 更新时间。
 * 所有表的主键均为数据库自增，更新时间由 Service 层显式写入，避免依赖数据库方言。
 */
@Data
public abstract class BaseEntity {

    @TableId(type = IdType.AUTO)
    private Long id;

    private LocalDateTime updatedAt;
}
