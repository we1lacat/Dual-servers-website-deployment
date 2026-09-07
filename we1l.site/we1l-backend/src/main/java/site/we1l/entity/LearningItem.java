package site.we1l.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 「关于我」— 正在学习的方向。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("learning_item")
public class LearningItem extends BaseEntity {

    @NotBlank(message = "标题不能为空")
    private String title;

    private String description;

    private String icon;

    private Integer sortOrder;

    /** 1 启用 / 0 停用 */
    private Integer status;
}
