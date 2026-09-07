package site.we1l.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 首页趋势折线图数据点。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("site_trend")
public class SiteTrend extends BaseEntity {

    @NotBlank(message = "月份标签不能为空")
    private String statLabel;

    @NotNull(message = "数值不能为空")
    private Integer statValue;

    private Integer sortOrder;

    private String remark;
}
