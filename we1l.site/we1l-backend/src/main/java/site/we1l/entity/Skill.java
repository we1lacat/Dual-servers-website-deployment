package site.we1l.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 「关于我」— 技能。
 * 进度条与雷达图共用一张表，通过 skillType 区分：
 * <ul>
 *   <li>BAR：进度条，percentValue 取 0-100</li>
 *   <li>RADAR：雷达图维度，percentValue 取 0-100</li>
 * </ul>
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("skill")
public class Skill extends BaseEntity {

    @NotBlank(message = "技能类型不能为空")
    private String skillType;

    @NotBlank(message = "技能名称不能为空")
    private String skillName;

    @NotNull(message = "百分比不能为空")
    @Min(value = 0, message = "百分比不能小于 0")
    @Max(value = 100, message = "百分比不能大于 100")
    private Integer percentValue;

    /** 进度条配色：blue / green / orange / purple */
    private String colorKey;

    private Integer sortOrder;

    private Integer status;
}
