package site.we1l.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 「笔记 / 服务」— 作品展示条目。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("work_item")
public class WorkItem extends BaseEntity {

    @NotBlank(message = "作品标题不能为空")
    private String title;

    /** 技术栈说明，如「PyQt5 · MVC 架构 · AI 对话」 */
    private String techMeta;

    private String cover;

    private String link;

    private String category;

    private Integer sortOrder;

    private Integer status;
}
